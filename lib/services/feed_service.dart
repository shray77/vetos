import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/feeds.dart';

/// «Живая лента экосистемы»: тянет компактные срезы данных проектов
/// из git-репозиториев (raw.githubusercontent) — тот же принцип, что
/// у метео-тайла: git как бекенд, без серверов и личных кабинетов.
///
/// Каждый фид грузится независимо: упал один — остальные живут.
class FeedService extends ChangeNotifier {
  static const _base =
      'https://raw.githubusercontent.com/shray77/vet-meteo/main';

  OutlookSlice? outlook;
  OutbreaksSlice? outbreaks;
  VerifySlice? verify;
  WeeklySlice? weekly;

  bool loading = false;
  DateTime? fetchedAt;

  /// Имена фидов, которые не ответили (для мягкой деградации).
  List<String> failed = const [];

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
    } else {
      missed.add('прогноз 7 дней');
    }
    if (results[1] != null) {
      outbreaks = OutbreaksSlice.fromJson(results[1]!);
    } else {
      missed.add('вспышки');
    }
    if (results[2] != null) {
      verify = VerifySlice.fromJson(results[2]!);
    } else {
      missed.add('верификация');
    }
    if (results[3] != null) {
      weekly = WeeklySlice.fromJson(results[3]!);
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
        final r = await http
            .get(Uri.parse(url), headers: {'Cache-Control': 'no-cache'})
            .timeout(const Duration(seconds: 20));
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
}
