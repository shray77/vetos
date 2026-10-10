import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/feeds.dart';

/// «Живая лента экосистемы»: тянет компактные срезы данных проектов
/// из git-репозиториев (raw.githubusercontent) — тот же принцип, что
/// у метео-тайла: git как бекенд, без серверов и личных кабинетов.
///
/// Каждый фид грузится независимо: упал один — остальные живут.
///
/// Оптимизации под слабые устройства (Helio G35 / 4 ГБ ОЗУ):
///  - общий [Client] с keep-alive: 4 параллельных запроса к одному хосту
///    переиспользуют TCP/TLS-соединение (экономия ~150 мс на каждый);
///  - таймаут 12 с вместо 20 с: лента не критична, лучше быстро откатиться
///    к кэшу, чем держать пользователя на «крутилке»;
///  - без `Cache-Control: no-cache`: CDN обновляется ~5 мин, обходить кэш
///    нет смысла — экономим батарею и трафик;
///  - persist последнего успешного среза в SharedPreferences — мгновенный
///    рендер ленты на холодном старте лаунчера.
class FeedService extends ChangeNotifier {
  static const _base =
      'https://raw.githubusercontent.com/shray77/vet-meteo/main';
  static const _kCachePrefix = 'vetos.cache.feed.';

  /// Общий клиент на весь сервис — keep-alive, connection-pool.
  static final Client _http = Client();

  OutlookSlice? outlook;
  OutbreaksSlice? outbreaks;
  VerifySlice? verify;
  WeeklySlice? weekly;

  bool loading = false;
  DateTime? fetchedAt;

  /// Имена фидов, которые не ответили (для мягкой деградации).
  List<String> failed = const [];

  FeedService() {
    _loadCached();
  }

  Future<void> _loadCached() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final o = sp.getString('${_kCachePrefix}outlook');
      final b = sp.getString('${_kCachePrefix}outbreaks');
      final v = sp.getString('${_kCachePrefix}verify');
      final w = sp.getString('${_kCachePrefix}weekly');
      if (o != null) outlook = OutlookSlice.fromJson(jsonDecode(o));
      if (b != null) outbreaks = OutbreaksSlice.fromJson(jsonDecode(b));
      if (v != null) verify = VerifySlice.fromJson(jsonDecode(v));
      if (w != null) weekly = WeeklySlice.fromJson(jsonDecode(w));
      if (outlook != null || outbreaks != null) notifyListeners();
    } catch (_) {
      // кэш побился — не беда
    }
  }

  Future<void> _saveCached(String id, Map<String, dynamic> json) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('$_kCachePrefix$id', jsonEncode(json));
    } catch (_) {
      // не критично
    }
  }

  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    failed = const [];
    notifyListeners();

    final results = await Future.wait<Map<String, dynamic>?>([
      _tryJson('$_base/data/outlook.json'),
      _tryJson('$_base/docs/data/outbreaks.json'),
      _tryJson('$_base/data/verify.json'),
      _tryJson('$_base/data/weekly.json'),
    ]);

    final missed = <String>[];
    if (results[0] != null) {
      outlook = OutlookSlice.fromJson(results[0]!);
      _saveCached('outlook', results[0]!);
    } else {
      missed.add('прогноз 7 дней');
    }
    if (results[1] != null) {
      outbreaks = OutbreaksSlice.fromJson(results[1]!);
      _saveCached('outbreaks', results[1]!);
    } else {
      missed.add('вспышки');
    }
    if (results[2] != null) {
      verify = VerifySlice.fromJson(results[2]!);
      _saveCached('verify', results[2]!);
    } else {
      missed.add('верификация');
    }
    if (results[3] != null) {
      weekly = WeeklySlice.fromJson(results[3]!);
      _saveCached('weekly', results[3]!);
    } else {
      missed.add('дайджест');
    }

    failed = missed;
    if (missed.length < 4) fetchedAt = DateTime.now();
    loading = false;
    notifyListeners();
  }

  /// Один JSON c двумя повторами; null — не дожались.
  Future<Map<String, dynamic>?> _tryJson(String url) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final r = await _http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 12),
        );
        if (r.statusCode == 200) {
          return jsonDecode(r.body) as Map<String, dynamic>;
        }
      } catch (_) {
        // сеть моргнула — пробуем ещё раз
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    return null;
  }

  @override
  void dispose() {
    _http.close();
    super.dispose();
  }
}
