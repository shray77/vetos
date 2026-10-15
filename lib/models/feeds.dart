/// Модели «живой ленты экосистемы» — компактные срезы данных проектов,
/// публикуемые в git-репозиториях (raw.githubusercontent), как у метео.
///
/// Конвенция VetOS Feed v1: любой проект кладёт рядом со своими данными
/// небольшой JSON (≤16 КБ) со стабильной схемой и полем
/// `generatedAt`/`updated`. Лаунчер тянет и рендерит нативно —
/// без личных кабинетов, без серверов, просто git.
///
/// Подключено в v0.3.0:
///  - data/outlook.json        — 7-дневный outlook THI (метео-радар)
///  - docs/data/outbreaks.json — вспышки, курация ВетКарты
///  - data/verify.json         — качество прогноза (прогноз vs факт)
///  - data/weekly.json         — недельный дайджест
library;

/// Станция из data/outlook.json (агрегат на 7 дней).
class OutlookStation {
  final String id;
  final String name;
  final double? thiMax7; // максимум THI за горизонт
  final int? days72; // дней с THI > 72
  final int? days80; // дней с THI > 80
  final double? precip7; // осадки за 7 дней, мм
  final List<double> perDay; // THI по дням

  OutlookStation({
    required this.id,
    required this.name,
    this.thiMax7,
    this.days72,
    this.days80,
    this.precip7,
    this.perDay = const [],
  });

  static double? _d(dynamic v) => v is num ? v.toDouble() : null;
  static int? _i(dynamic v) => v is num ? v.toInt() : null;
  static List<double> _arr(dynamic v) => v is List
      ? v.map((e) => (e is num ? e.toDouble() : 0.0)).toList()
      : <double>[];

  factory OutlookStation.fromJson(Map<String, dynamic> j) => OutlookStation(
        id: (j['id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        thiMax7: _d(j['thiMax7']),
        days72: _i(j['days72']),
        days80: _i(j['days80']),
        precip7: _d(j['precip7']),
        perDay: _arr(j['perDay']),
      );
}

/// data/outlook.json целиком.
class OutlookSlice {
  final DateTime generatedAt;
  final String horizon; // «7 дней»
  final List<OutlookStation> stations;
  final List<String> digest; // строки-выводы по региону

  OutlookSlice({
    required this.generatedAt,
    required this.horizon,
    required this.stations,
    required this.digest,
  });

  factory OutlookSlice.fromJson(Map<String, dynamic> j) => OutlookSlice(
        generatedAt:
            DateTime.tryParse((j['generatedAt'] ?? '') as String) ??
                DateTime.now(),
        horizon: (j['horizon'] ?? '') as String,
        stations: ((j['stations'] ?? []) as List)
            .map((e) => OutlookStation.fromJson(e as Map<String, dynamic>))
            .toList(),
        digest: ((j['digest'] ?? []) as List)
            .map((e) => e.toString())
            .toList(),
      );

  OutlookStation? byId(String id) {
    for (final s in stations) {
      if (s.id == id) return s;
    }
    return null;
  }
}

/// Одна вспышка из docs/data/outbreaks.json (курация ВетКарты).
class Outbreak {
  final String key; // k: машинный ключ
  final String name; // n: болезнь
  final DateTime? date; // dt
  final String region; // r

  Outbreak({
    required this.key,
    required this.name,
    this.date,
    this.region = '',
  });

  factory Outbreak.fromJson(Map<String, dynamic> j) => Outbreak(
        key: (j['k'] ?? '') as String,
        name: (j['n'] ?? '') as String,
        date: DateTime.tryParse((j['dt'] ?? '') as String),
        region: (j['r'] ?? '') as String,
      );

  /// «24.06» — для компактной карточки.
  String get dateLabel {
    final d = date;
    if (d == null) return '—';
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$day.$m';
  }
}

/// docs/data/outbreaks.json целиком.
class OutbreaksSlice {
  final DateTime? updated;
  final int total; // записей в базе (с 2019 г.)
  final List<Outbreak> outbreaks;

  OutbreaksSlice({
    required this.updated,
    required this.total,
    required this.outbreaks,
  });

  factory OutbreaksSlice.fromJson(Map<String, dynamic> j) {
    final all = ((j['outbreaks'] ?? []) as List)
        .map((e) => Outbreak.fromJson(e as Map<String, dynamic>))
        .toList();
    return OutbreaksSlice(
      updated: DateTime.tryParse((j['updated'] ?? '') as String),
      total: (j['total'] ?? 0) as int,
      outbreaks: all,
    );
  }

  /// Свежие вспышки: сначала новые, затем старые.
  List<Outbreak> recent([int n = 3]) {
    final sorted = [...outbreaks]
      ..sort((a, b) => (b.date ?? DateTime(1970))
          .compareTo(a.date ?? DateTime(1970)));
    return sorted.take(n).toList();
  }

  /// «06.09» для подписи «обновлено».
  String get updatedLabel {
    final u = updated;
    if (u == null) return '—';
    final m = u.month.toString().padLeft(2, '0');
    final d = u.day.toString().padLeft(2, '0');
    return '$d.$m';
  }
}

/// data/verify.json — ретро-проверка прогноза (прогноз vs факт).
class VerifySlice {
  final DateTime generatedAt;
  final String verdict; // «малые» / «заметные» / …
  final double? thiMae; // MAE THI, единицы
  final int? days; // окно проверки
  final int? stations;

  VerifySlice({
    required this.generatedAt,
    required this.verdict,
    this.thiMae,
    this.days,
    this.stations,
  });

  static double? _d(dynamic v) => v is num ? v.toDouble() : null;
  static int? _i(dynamic v) => v is num ? v.toInt() : null;

  factory VerifySlice.fromJson(Map<String, dynamic> j) {
    final model = j['model'];
    final mae = model is Map<String, dynamic> ? model['mae'] : null;
    return VerifySlice(
      generatedAt:
          DateTime.tryParse((j['generatedAt'] ?? '') as String) ??
              DateTime.now(),
      verdict: (j['verdict'] ?? '—') as String,
      thiMae: mae is Map<String, dynamic> ? _d(mae['thi']) : _d(j['thi']),
      days: model is Map<String, dynamic> ? _i(model['days']) : null,
      stations: model is Map<String, dynamic> ? _i(model['stations']) : null,
    );
  }
}

/// data/weekly.json — недельный дайджест по региону.
class WeeklySlice {
  final DateTime generatedAt;
  final String from; // дата от
  final String to; // дата до
  final List<String> digest;

  WeeklySlice({
    required this.generatedAt,
    required this.from,
    required this.to,
    required this.digest,
  });

  factory WeeklySlice.fromJson(Map<String, dynamic> j) => WeeklySlice(
        generatedAt:
            DateTime.tryParse((j['generatedAt'] ?? '') as String) ??
                DateTime.now(),
        from: (j['from'] ?? '') as String,
        to: (j['to'] ?? '') as String,
        digest: ((j['digest'] ?? []) as List)
            .map((e) => e.toString())
            .toList(),
      );
}

/// tspulse/latest.json (вет-пилоты, v0.4.0) — аномалия недели:
/// Granite-TSPulse считает скор вспышечной активности против истории.
///
/// Схема толерантная: отсутствующее поле = «—», а не падение.
class TspulseSlice {
  final DateTime generatedAt;
  final String verdict; // «повышенный фон» / «норма»…
  final String note; // человеческое пояснение
  final double? meanScore;
  final double? maxScore;
  final double? percentileMean;
  final double? percentileMax;
  final double? threshold; // порог аномалии (0.6)
  final int? daysOver; // days_over_threshold
  final String windowFrom; // week.window[0] «2026-10-09»
  final String windowTo; // week.window[1] «2026-10-15»
  final Map<String, int> diseases; // week_diseases: болезнь → записей

  TspulseSlice({
    required this.generatedAt,
    required this.verdict,
    required this.note,
    this.meanScore,
    this.maxScore,
    this.percentileMean,
    this.percentileMax,
    this.threshold,
    this.daysOver,
    this.windowFrom = '',
    this.windowTo = '',
    this.diseases = const {},
  });

  static double? _d(dynamic v) => v is num ? v.toDouble() : null;
  static int? _i(dynamic v) => v is num ? v.toInt() : null;

  factory TspulseSlice.fromJson(Map<String, dynamic> j) {
    final week = j['week'] is Map<String, dynamic>
        ? j['week'] as Map<String, dynamic>
        : <String, dynamic>{};
    final window = week['window'] is List && (week['window'] as List).length >= 2
        ? (week['window'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final rawDiseases = j['week_diseases'];
    final diseases = <String, int>{};
    if (rawDiseases is Map) {
      rawDiseases.forEach((k, v) {
        final n = v is num ? v.toInt() : null;
        if (n != null) diseases[k.toString()] = n;
      });
    }
    return TspulseSlice(
      generatedAt:
          DateTime.tryParse((j['generated_at'] ?? j['generatedAt'] ?? '')
              as String) ??
              DateTime.now(),
      verdict: (week['verdict'] ?? '—') as String,
      note: (week['note'] ?? '') as String,
      meanScore: _d(week['mean_score']),
      maxScore: _d(week['max_score']),
      percentileMean: _d(week['percentile_mean']),
      percentileMax: _d(week['percentile_max']),
      threshold: _d(week['threshold']),
      daysOver: _i(week['days_over_threshold']),
      windowFrom: window.isNotEmpty ? window[0] : '',
      windowTo: window.length >= 2 ? window[1] : '',
      diseases: diseases,
    );
  }

  /// «09.10–15.10» — окно недели для карточки.
  String get windowLabel {
    String fmt(String iso) {
      final d = DateTime.tryParse(iso);
      if (d == null) return '—';
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';
    }

    if (windowFrom.isEmpty && windowTo.isEmpty) return '—';
    return '${fmt(windowFrom)}–${fmt(windowTo)}';
  }

  /// «Бешенство 18 · Лейкоз КРС 9 · …» — топ-3 болезни недели.
  String get diseasesTop3 {
    final sorted = diseases.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted
        .take(3)
        .map((e) => '${e.key} ${e.value}')
        .join(' · ');
  }
}

/// data/llm_digest.json (вет-дайджест, v0.4.0) — LLM-сводка недели:
/// малая модель (Qwen3-1.7B на Actions) пишет дайджест по сигналам
/// экосистемы; рядом лежит аудио-версия (Piper) на Pages.
class DigestSlice {
  final DateTime generatedAt;
  final String weekKey; // «2026-W41»
  final String headline; // главный вывод
  final String summary; // развёрнутая сводка
  final List<String> bullets; // тезисы по блокам
  final String practical; // практический смысл
  final String sourcesOk; // «18/22» — источники ок
  final int events; // событий в срезе
  final String disclaimer;

  DigestSlice({
    required this.generatedAt,
    required this.weekKey,
    required this.headline,
    required this.summary,
    required this.bullets,
    required this.practical,
    required this.sourcesOk,
    required this.events,
    required this.disclaimer,
  });

  factory DigestSlice.fromJson(Map<String, dynamic> j) {
    final stats = j['stats'] is Map<String, dynamic>
        ? j['stats'] as Map<String, dynamic>
        : <String, dynamic>{};
    return DigestSlice(
      generatedAt:
          DateTime.tryParse((j['generated_at'] ?? j['generatedAt'] ?? '')
              as String) ??
              DateTime.now(),
      weekKey: (j['week_key'] ?? '—') as String,
      headline: (j['headline'] ?? '') as String,
      summary: (j['summary'] ?? '') as String,
      bullets: ((j['bullets'] ?? []) as List)
          .map((e) => e.toString())
          .toList(),
      practical: (j['practical'] ?? '') as String,
      sourcesOk: (stats['sources_ok'] ?? '—') as String,
      events: stats['events'] is num ? (stats['events'] as num).toInt() : 0,
      disclaimer: (j['disclaimer'] ?? '') as String,
    );
  }
}
