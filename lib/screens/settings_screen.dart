import 'package:flutter/material.dart';

import '../models/meteo.dart';
import '../services/launch_service.dart';
import '../services/meteo_service.dart';
import '../services/prefs_service.dart';


/// Настройки: станция метео-тайла, интервал обновления, о VetOS.
class SettingsScreen extends StatefulWidget {
  final MeteoService meteo;
  final String stationId;
  final int intervalMin;
  final void Function(String stationId, int intervalMin) onChanged;

  const SettingsScreen({
    super.key,
    required this.meteo,
    required this.stationId,
    required this.intervalMin,
    required this.onChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _stationId;
  late int _intervalMin;
  bool _builtin = true;

  static const _intervals = [10, 20, 30, 60];

  @override
  void initState() {
    super.initState();
    _stationId = widget.stationId;
    _intervalMin = widget.intervalMin;
    PrefsService.builtinBrowser()
        .then((v) { if (mounted) setState(() => _builtin = v); });
  }

  void _save() {
    PrefsService.setStationId(_stationId);
    PrefsService.setIntervalMin(_intervalMin);
    widget.onChanged(_stationId, _intervalMin);
  }

  @override
  Widget build(BuildContext context) {
    final stations = widget.meteo.latest?.stations ??
        const <MeteoStation>[];
    final forecast = widget.meteo.forecast;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back,
                      color: Color(0xFF2DD4A7)),
                ),
                const Text(
                  'НАСТРОЙКИ',
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: 1.5,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            _section('Станция метео-тайла'),
            if (stations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'список станций подгрузится, когда метео-радар ответит',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: stations.any((s) => s.id == _stationId)
                        ? _stationId
                        : stations.first.id,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF111827),
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    items: [
                      for (final s in stations)
                        DropdownMenuItem(
                          value: s.id,
                          child: Text(
                              '${s.name} · THI ${s.thi?.toStringAsFixed(1) ?? '—'}'),
                        ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _stationId = v);
                      _save();
                    },
                  ),
                ),
              ),
            _section('Браузер веб-плиток'),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('встроенный'),
                  selected: _builtin,
                  selectedColor: const Color(0xFF2DD4A7),
                  backgroundColor: const Color(0xFF111827),
                  labelStyle: TextStyle(
                    color: _builtin
                        ? const Color(0xFF0B0F14)
                        : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => _setBrowser(true),
                ),
                ChoiceChip(
                  label: const Text('Chrome (полоса)'),
                  selected: !_builtin,
                  selectedColor: const Color(0xFF2DD4A7),
                  backgroundColor: const Color(0xFF111827),
                  labelStyle: TextStyle(
                    color: !_builtin
                        ? const Color(0xFF0B0F14)
                        : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => _setBrowser(false),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                _builtin
                    ? 'веб-плитки открываются внутри VetOS — без тулбара Chrome; '
                        'внутри есть кнопка «в Chrome» (VetLearn всегда в Chrome — там логины)'
                    : 'веб-плитки открываются Chrome Custom Tabs — с полосой и куками Chrome',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
            _section('Интервал обновления метео'),
            Wrap(
              spacing: 8,
              children: [
                for (final m in _intervals)
                  ChoiceChip(
                    label: Text('$m мин'),
                    selected: _intervalMin == m,
                    selectedColor: const Color(0xFF2DD4A7),
                    backgroundColor: const Color(0xFF111827),
                    labelStyle: TextStyle(
                      color: _intervalMin == m
                          ? const Color(0xFF0B0F14)
                          : Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) {
                      setState(() => _intervalMin = m);
                      _save();
                    },
                  ),
              ],
            ),
            _section('Срез CI'),
            Text(
              forecast == null
                  ? 'прогноз ещё не загружен'
                  : 'последний срез: ${forecast.h0} МСК · горизонт ${forecast.hours} ч · ${forecast.stations.length} станций',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
            _section('О VetOS'),
            _aboutTile(
              'VetOS 0.2.0 · ru.shray77.vetos',
              'лаунчер-хаб вет-экосистемы: 6 проектов, живой метео-тайл THI, встроенный браузер',
            ),
            _aboutTile(
              'Источник метео',
              'CI-бот vet-meteo: срезы каждые ~20 мин (метроном Actions)',
              onTap: () => LaunchService.openUrl(
                  'https://github.com/shray77/vet-meteo'),
            ),
            _aboutTile(
              'Сделать домашним экраном',
              'Настройки Android → Приложения по умолчанию → Домашнее приложение → VetOS',
            ),
          ],
        ),
      ),
    );
  }

  void _setBrowser(bool v) {
    setState(() => _builtin = v);
    PrefsService.setBuiltinBrowser(v);
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.5,
            color: Colors.teal.shade200,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _aboutTile(String title, String sub, {VoidCallback? onTap}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          title: Text(title,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(sub,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          onTap: onTap,
        ),
      );
}
