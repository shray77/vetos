import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/meteo.dart';

/// Тянет срезы метео-радара прямо из git-репозитория (raw.githubusercontent),
/// тот же источник, что и дашборд сайта. Кэш CDN ~5 мин — для лаунчера норм.
///
/// Оптимизации под слабые устройства (Helio G35 / 4 ГБ ОЗУ, Oppo A18):
///  - общий [Client] с keep-alive и connection-poolом (HTTP/1.1): не создаём
///    новый сокет на каждый запрос — экономим ~150 мс на TCP/TLS handshake;
///  - таймаут 15 с вместо 25 с: при плохой сети лаунчер быстрее откатывается
///    к кэшированному срезу и не висит «крутилкой»;
///  - без `Cache-Control: no-cache`: CDN raw.githubusercontent обновляется
///    раз в ~5 мин, смысла обходить кэш нет — зато экономим батарею и трафик;
///  - persist последнего успешного среза в SharedPreferences: на холодном
///    старте лаунчер сразу рисует метео из кэша, фоновый рефреш поднимает
///    свежие данные без UI-блокировки.
class MeteoService extends ChangeNotifier {
  static const _base =
      'https://raw.githubusercontent.com/shray77/vet-meteo/main/data';
  static const _kCacheLatest = 'vetos.cache.meteo.latest';
  static const _kCacheForecast = 'vetos.cache.meteo.forecast';

  /// Клиент сервиса — keep-alive, connection-pool. Экземплярный (НЕ static):
  /// static-клиент, закрываемый в dispose, оставлял бы мёртвый сокет всем
  /// последующим экземплярам сервиса (мина при пересоздании экрана).
  final Client _http = Client();

  MeteoSlice? latest;
  Forecast? forecast;
  String? error;
  bool loading = false;
  DateTime? fetchedAt;

  MeteoService() {
    _loadCached();
  }

  /// Подгружает последний срез из SharedPreferences — мгновенный UI на старте.
  Future<void> _loadCached() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final l = sp.getString(_kCacheLatest);
      final f = sp.getString(_kCacheForecast);
      if (l != null) {
        latest = MeteoSlice.fromJson(jsonDecode(l) as Map<String, dynamic>);
      }
      if (f != null) {
        forecast = Forecast.fromJson(jsonDecode(f) as Map<String, dynamic>);
      }
      if (latest != null) notifyListeners();
    } catch (_) {
      // кэш побился — не беда, пойдём в сеть
    }
  }

  /// Сохраняет свежий срез в SharedPreferences (fire-and-forget, не блокируем UI).
  Future<void> _saveCached() async {
    try {
      final sp = await SharedPreferences.getInstance();
      if (latest != null) {
        await sp.setString(_kCacheLatest, jsonEncode(latest!.toJson()));
      }
      if (forecast != null) {
        await sp.setString(_kCacheForecast, jsonEncode(forecast!.toJson()));
      }
    } catch (_) {
      // переполнение хранилища / битый json — не критично
    }
  }

  /// Параллельно качает latest + forecast; при ошибке одного — деградирует мягко.
  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>([
        _getJson('$_base/latest.json'),
        _tryJson('$_base/forecast.json'),
      ]);
      latest = MeteoSlice.fromJson(results[0] as Map<String, dynamic>);
      final f = results[1] as Map<String, dynamic>?;
      if (f == null) {
        error = 'прогноз не подгрузился';
      } else {
        forecast = Forecast.fromJson(f);
      }
      fetchedAt = DateTime.now();
      _saveCached();
    } catch (_) {
      // Упал latest — он уже израсходовал свои 3 попытки внутри _getJson,
      // повторно не тянем (старый catch-ретрай растягивал «крутилку» до
      // ~100 с: 15 с таймаут + 2 с пауза × 6). Сразу честное error-состояние.
      error = 'метео недоступно';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Прогноз — второй по важности: если не дожались, latest всё равно
  /// рисуем (мягкая деградация), поэтому его ошибки глотаем в null.
  Future<Map<String, dynamic>?> _tryJson(String url) async {
    try {
      return await _getJson(url);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _getJson(String url) async {
    Response? last;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final r = await _http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 15),
        );
        if (r.statusCode == 200) {
          return jsonDecode(r.body) as Map<String, dynamic>;
        }
        last = r;
      } catch (_) {
        // сеть моргнула — пробуем ещё раз
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    throw Exception('не удалось загрузить $url: ${last?.statusCode}');
  }

  @override
  void dispose() {
    _http.close();
    super.dispose();
  }
}
