import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/meteo.dart';

/// Тянет срезы метео-радара прямо из git-репозитория (raw.githubusercontent),
/// тот же источник, что и дашборд сайта. Кэш CDN ~5 мин — для лаунчера норм.
class MeteoService extends ChangeNotifier {
  static const _base =
      'https://raw.githubusercontent.com/shray77/vet-meteo/main/data';

  MeteoSlice? latest;
  Forecast? forecast;
  String? error;
  bool loading = false;
  DateTime? fetchedAt;

  /// Параллельно качает latest + forecast; при ошибке одного — деградирует мягко.
  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait<dynamic>([
        _getJson('$_base/latest.json'),
        _getJson('$_base/forecast.json'),
      ]);
      latest = MeteoSlice.fromJson(results[0] as Map<String, dynamic>);
      forecast = Forecast.fromJson(results[1] as Map<String, dynamic>);
      fetchedAt = DateTime.now();
    } catch (e) {
      // Один из ответов мог не прийти: пробуем latest отдельно.
      try {
        latest = MeteoSlice.fromJson(await _getJson('$_base/latest.json'));
        fetchedAt = DateTime.now();
        error = 'прогноз не подгрузился';
      } catch (_) {
        error = 'метео недоступно';
      }
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> _getJson(String url) async {
    http.Response? last;
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final r = await http
            .get(Uri.parse(url), headers: {'Cache-Control': 'no-cache'})
            .timeout(const Duration(seconds: 25));
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
}
