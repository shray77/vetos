import 'package:flutter/material.dart';

import '../models/meteo.dart';
import '../services/launch_service.dart';
import '../services/meteo_service.dart';
import '../services/prefs_service.dart';
import '../theme/ds.dart';


/// Настройки: станция метео-тайла, живая лента, интервал, браузер плиток.
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

  /// Тумблеры живой ленты: outlook / outbreaks / verify / weekly / tspulse / digest.
  final Map<String, bool> _feed = {
    'outlook': true,
    'outbreaks': true,
    'verify': true,
    'weekly': false,
    'tspulse': true,
    'digest': true,
  };

  static const _intervals = [10, 20, 30, 60];

  static const _feedTitles = {
    'outlook': 'Прогноз 7 дней · THI',
    'outbreaks': 'Вспышки · ВетКарта',
    'verify': 'Прогноз vs факт',
    'weekly': 'Недельный дайджест',
    'tspulse': 'Аномалия · TSPulse',
    'digest': 'Дайджест · LLM',
  };

  static const _feedSubs = {
    'outlook': 'outlook.json · по выбранной станции',
    'outbreaks': 'outbreaks.json · Ростовская обл., с 2019',
    'verify': 'verify.json · ретро-проверка, MAE THI',
    'weekly': 'weekly.json · дайджест по архиву радара',
    'tspulse': 'tspulse/latest.json · пилот аномалий, вет-пилоты',
    'digest': 'llm_digest.json · сводка недели + аудио (Piper)',
  };

  @override
  void initState() {
    super.initState();
    _stationId = widget.stationId;
    _intervalMin = widget.intervalMin;
    PrefsService.builtinBrowser()
        .then((v) { if (mounted) setState(() => _builtin = v); });
    for (final id in _feed.keys) {
      PrefsService.feedEnabled(id)
          .then((v) { if (mounted) setState(() => _feed[id] = v); });
    }
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
    final ts = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Ds.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, color: Ds.accent),
                ),
                // Шапка экрана — роль titleLarge (капс + трекинг из темы).
                Text('НАСТРОЙКИ', style: ts.titleLarge),
              ],
            ),
            _section('Станция метео-тайла'),
            if (stations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'список станций подгрузится, когда метео-радар ответит',
                  style: ts.bodyMedium!.copyWith(color: Ds.faint),
                ),
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Ds.surface,
                  borderRadius: BorderRadius.circular(Ds.radius),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: stations.any((s) => s.id == _stationId)
                        ? _stationId
                        : stations.first.id,
                    isExpanded: true,
                    dropdownColor: Ds.surface2,
                    style: ts.bodyLarge,
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
                  selectedColor: Ds.accent,
                  backgroundColor: Ds.surface,
                  labelStyle: ts.labelLarge!
                      .copyWith(color: _builtin ? Ds.accentInk : Ds.text),
                  onSelected: (_) => _setBrowser(true),
                ),
                ChoiceChip(
                  label: const Text('Chrome (полоса)'),
                  selected: !_builtin,
                  selectedColor: Ds.accent,
                  backgroundColor: Ds.surface,
                  labelStyle: ts.labelLarge!
                      .copyWith(color: !_builtin ? Ds.accentInk : Ds.text),
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
                style: ts.bodySmall,
              ),
            ),
            _section('Живая лента экосистемы'),
            for (final id in _feed.keys)
              SwitchListTile(
                value: _feed[id] ?? true,
                onChanged: (v) {
                  setState(() => _feed[id] = v);
                  PrefsService.setFeedEnabled(id, v);
                },
                activeThumbColor: Ds.accent,
                dense: true,
                title: Text(_feedTitles[id] ?? id, style: ts.titleMedium),
                subtitle: Text(_feedSubs[id] ?? '', style: ts.bodySmall),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'карточки тянутся из git-репозиториев проектов '
                '(raw.githubusercontent), как метео-тайл — без серверов и кабинетов',
                style: ts.bodySmall,
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
                    selectedColor: Ds.accent,
                    backgroundColor: Ds.surface,
                    labelStyle: ts.labelLarge!.copyWith(
                      color: _intervalMin == m ? Ds.accentInk : Ds.text,
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
              style: ts.bodyMedium,
            ),
            _section('О VetOS'),
            _aboutTile(
              'VetOS 0.6.0 · ru.shray77.vetos',
              'лаунчер-хаб вет-экосистемы: 16 проектов, живой метео-тайл, лента данных, встроенный браузер',
            ),
            _aboutTile(
              'Источник метео',
              'CI-бот vet-meteo: срезы каждые ~20 мин (метроном Actions)',
              onTap: () => LaunchService.openUrl(
                  'https://github.com/shray77/vet-meteo'),
            ),
            _aboutTile(
              'Конвенция ленты',
              'как любой проект экосистемы может отдать данные лаунчеру: docs/vetos-feeds.md',
              onTap: () => LaunchService.openUrl(
                  'https://github.com/shray77/vetos/blob/main/docs/vetos-feeds.md'),
            ),
            _aboutTile(
              'Сделать домашним экраном',
              'тап — пошаговая инструкция',
              onTap: _showHomeScreenDialog,
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

  /// Диалог «домашний экран» — первая боевая роль dialogTheme DS:
  /// плоская панель surface2 на волоске границы, текст шкалой темы.
  Future<void> _showHomeScreenDialog() => showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Домашний экран VetOS'),
          content: const Text(
            'Настройки Android → Приложения по умолчанию → '
            'Домашнее приложение → VetOS.\n\n'
            'После этого кнопка «домой» будет возвращать на экран часов, '
            'метео-тайла и живой ленты экосистемы.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('понял'),
            ),
          ],
        ),
      );

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context)
              .textTheme
              .labelSmall!
              .copyWith(color: Ds.accent),
        ),
      );

  Widget _aboutTile(String title, String sub, {VoidCallback? onTap}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Ds.surface,
          borderRadius: BorderRadius.circular(Ds.radius),
        ),
        child: ListTile(
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(sub, style: Theme.of(context).textTheme.bodySmall),
          onTap: onTap,
        ),
      );
}
