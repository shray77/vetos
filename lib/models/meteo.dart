import 'package:flutter/material.dart';

import '../theme/ds.dart';

/// Статус THI (шкала стресса КРС, как в метео-радаре).
/// Цвета — семантика vet-ds v2.3 (тёмные значения, AA на графите).
class ThiStatus {
  final String label;
  final Color color;
  const ThiStatus(this.label, this.color);

  static ThiStatus of(double thi) {
    if (thi >= 80) return const ThiStatus('экстрим', Ds.red);
    if (thi >= 72) return const ThiStatus('стресс', Ds.orange);
    if (thi >= 68) return const ThiStatus('внимание', Ds.amber);
    return const ThiStatus('норма', Ds.green);
  }
}

/// Статус CCI (Comprehensive Climate Index, Mader 2010 err. 2011) — комфорт в °C.
/// Пороги OK Mesonet 2016: -10..30 термонейтрально, >=30 жара-осторожно,
/// >=40 опасная жара, <=-10 холод-осторожно, <=-30 опасный холод.
class CciStatus {
  final String label;
  final Color color;
  const CciStatus(this.label, this.color);

  static CciStatus of(double cci) {
    if (cci >= 40) return const CciStatus('жара·экстрим', Ds.red);
    if (cci >= 30) return const CciStatus('жара·остор.', Ds.orange);
    if (cci <= -30) return const CciStatus('холод·экстрим', Ds.blue);
    if (cci <= -10) return const CciStatus('холод·остор.', Ds.blueSoft);
    return const CciStatus('комфорт', Ds.green);
  }
}

/// Станция из data/latest.json (срез метео-радара).
class MeteoStation {
  final String id;
  final String name;
  final double? t; // °C
  final int? rh; // %
  final double? wind; // м/с
  final int? wdir; // градусы
  final double? thi;
  final double? thiAdj;
  final double? thiMaxToday;
  final double? thiMax7;
  final double? cci; // Comprehensive Climate Index, °C (vet-api)
  final int? brd;

  MeteoStation({
    required this.id,
    required this.name,
    this.t,
    this.rh,
    this.wind,
    this.wdir,
    this.thi,
    this.thiAdj,
    this.thiMaxToday,
    this.thiMax7,
    this.cci,
    this.brd,
  });

  static double? _d(dynamic v) => v is num ? v.toDouble() : null;
  static int? _i(dynamic v) => v is num ? v.toInt() : null;

  factory MeteoStation.fromJson(Map<String, dynamic> j) => MeteoStation(
        id: (j['id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        t: _d(j['t']),
        rh: _i(j['rh']),
        wind: _d(j['wind']),
        wdir: _i(j['wdir']),
        thi: _d(j['thi']),
        thiAdj: _d(j['thiAdj']),
        thiMaxToday: _d(j['thiMaxToday']),
        thiMax7: _d(j['thiMax7']),
        cci: _d(j['cci']),
        brd: _i(j['brd']),
      );

  /// Направление ветра в румбах.
  String get windDirLabel {
    const labels = ['С', 'СВ', 'В', 'ЮВ', 'Ю', 'ЮЗ', 'З', 'СЗ'];
    if (wdir == null) return '—';
    return labels[((wdir! % 360) / 45).floor() % 8];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        't': t,
        'rh': rh,
        'wind': wind,
        'wdir': wdir,
        'thi': thi,
        'thiAdj': thiAdj,
        'thiMaxToday': thiMaxToday,
        'thiMax7': thiMax7,
        'cci': cci,
        'brd': brd,
      };
}

/// Срез data/latest.json целиком.
class MeteoSlice {
  final DateTime generatedAt;
  final List<MeteoStation> stations;

  MeteoSlice({required this.generatedAt, required this.stations});

  factory MeteoSlice.fromJson(Map<String, dynamic> j) => MeteoSlice(
        generatedAt: DateTime.tryParse((j['generatedAt'] ?? '') as String) ??
            DateTime.now(),
        stations: ((j['stations'] ?? []) as List)
            .map((e) => MeteoStation.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  MeteoStation? byId(String id) {
    for (final s in stations) {
      if (s.id == id) return s;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toIso8601String(),
        'stations': stations.map((s) => s.toJson()).toList(),
      };
}

/// Станция из data/forecast.json (массивы по часам на 48 ч).
class ForecastStation {
  final String id;
  final String name;
  final List<double> thi;
  final List<double> adj;
  final List<double> cci;
  final List<double> t;
  final List<double> wind;
  final List<double> pr; // осадки, мм/ч

  ForecastStation({
    required this.id,
    required this.name,
    required this.thi,
    required this.adj,
    required this.cci,
    required this.t,
    required this.wind,
    required this.pr,
  });

  static List<double> _arr(dynamic v) => v is List
      ? v.map((e) => (e is num ? e.toDouble() : 0.0)).toList()
      : <double>[];

  factory ForecastStation.fromJson(Map<String, dynamic> j) => ForecastStation(
        id: (j['id'] ?? '') as String,
        name: (j['name'] ?? '') as String,
        thi: _arr(j['thi']),
        adj: _arr(j['adj']),
        cci: _arr(j['cci']),
        t: _arr(j['t']),
        wind: _arr(j['wind']),
        pr: _arr(j['pr']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'thi': thi,
        'adj': adj,
        'cci': cci,
        't': t,
        'wind': wind,
        'pr': pr,
      };
}

/// data/forecast.json целиком.
class Forecast {
  final DateTime generatedAt;
  final String h0; // час выпуска, МСК
  final int hours;
  final List<ForecastStation> stations;

  Forecast({
    required this.generatedAt,
    required this.h0,
    required this.hours,
    required this.stations,
  });

  factory Forecast.fromJson(Map<String, dynamic> j) => Forecast(
        generatedAt: DateTime.tryParse((j['generatedAt'] ?? '') as String) ??
            DateTime.now(),
        h0: (j['h0'] ?? '') as String,
        hours: (j['hours'] ?? 0) as int,
        stations: ((j['stations'] ?? []) as List)
            .map((e) => ForecastStation.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  ForecastStation? byId(String id) {
    for (final s in stations) {
      if (s.id == id) return s;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toIso8601String(),
        'h0': h0,
        'hours': hours,
        'stations': stations.map((s) => s.toJson()).toList(),
      };
}
