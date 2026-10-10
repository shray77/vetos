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
