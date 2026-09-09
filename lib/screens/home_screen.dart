import 'dart:async';

import 'package:flutter/material.dart';

import '../models/project.dart';
import '../services/feed_service.dart';
import '../services/launch_service.dart';
import '../services/meteo_service.dart';
import '../services/prefs_service.dart';
import '../widgets/feed_cards.dart';
import '../widgets/meteo_card.dart';
import '../widgets/project_tile.dart';
import '../widgets/station_sheet.dart';
import 'browser_screen.dart';
import 'drawer_screen.dart';
import 'settings_screen.dart';

/// Домашний экран VetOS: часы, метео-тайл, сетка проектов, вход в дровер.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  final _meteo = MeteoService();
  final _feeds = FeedService();
  Timer? _clockTimer;
  Timer? _meteoTimer;
  DateTime _now = DateTime.now();
  String _stationId = 'rostov';
  int _intervalMin = 20;
  final Map<String, bool> _installed = {};

  /// Видимость карточек ленты (id → включена).
  final Map<String, bool> _feedOn = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
    _init();
  }

  Future<void> _init() async {
    _stationId = await PrefsService.stationId();
    _intervalMin = await PrefsService.intervalMin();
    _feedOn['outlook'] = await PrefsService.feedEnabled('outlook');
    _feedOn['outbreaks'] = await PrefsService.feedEnabled('outbreaks');
    _feedOn['verify'] = await PrefsService.feedEnabled('verify');
    _feedOn['weekly'] = await PrefsService.feedEnabled('weekly');
    if (mounted) setState(() {});
    await Future.wait([_meteo.refresh(), _feeds.refresh()]);
    _scheduleMeteo();
    await _checkInstalled();
  }

  void _scheduleMeteo() {
    _meteoTimer?.cancel();
    _meteoTimer = Timer.periodic(Duration(minutes: _intervalMin), (_) {
      _meteo.refresh();
      _feeds.refresh();
    });
  }

  Future<void> _checkInstalled() async {
    for (final p in kProjects) {
      if (p.kind == ProjectKind.app && p.package != null) {
        final ok = await LaunchService.isInstalled(p.package!);
        if (mounted) setState(() => _installed[p.package!] = ok);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Вернулись на домашний экран — подтянуть свежий срез, если протух.
    if (state == AppLifecycleState.resumed) {
      final f = _meteo.fetchedAt;
      if (f == null ||
          DateTime.now().difference(f).inMinutes >= _intervalMin) {
        _meteo.refresh();
        _feeds.refresh();
      }
      _checkInstalled();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _meteoTimer?.cancel();
    _meteo.dispose();
    _feeds.dispose();
    super.dispose();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SettingsScreen(
        meteo: _meteo,
        stationId: _stationId,
        intervalMin: _intervalMin,
        onChanged: (stationId, intervalMin) {
          setState(() {
            _stationId = stationId;
            _intervalMin = intervalMin;
          });
          _scheduleMeteo();
        },
      ),
    ));
    await _reloadFeedToggles();
    _checkInstalled();
  }

  /// После настроек — перечитать тумблеры ленты (могли переключить).
  Future<void> _reloadFeedToggles() async {
    for (final id in const ['outlook', 'outbreaks', 'verify', 'weekly']) {
      _feedOn[id] = await PrefsService.feedEnabled(id);
    }
    if (mounted) setState(() {});
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  /// Открывает проект: APK — по пакету (фолбэк на веб), веб — браузером плиток.
  Future<void> _openProject(Project p) async {
    if (p.kind == ProjectKind.app && p.package != null) {
      if (await LaunchService.isInstalled(p.package!) &&
          await LaunchService.launchPackage(p.package!)) {
        return;
      }
    }
    await _openWeb(p.url, p.title, mode: p.browser);
  }

  /// Веб-адрес: встроенный браузер (без полосы Chrome) или Custom Tabs.
  /// Настройку читаем при каждом тапе — смена в настройках действует сразу.
  Future<void> _openWeb(String url, String title,
      {TileBrowser mode = TileBrowser.auto}) async {
    final useBuiltin = mode == TileBrowser.builtin ||
        (mode == TileBrowser.auto && await PrefsService.builtinBrowser());
    if (!mounted) return;
    if (useBuiltin) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => BrowserScreen(url: url, title: title),
      ));
      return;
    }
    await LaunchService.openUrl(url);
  }

  /// Тап по метео-карточке — быстрый выбор станции (Таганрог, Новочеркасск…).
  Future<void> _pickStation() async {
    final stations = _meteo.latest?.stations;
    if (stations == null || stations.isEmpty) {
      // Радар молчит — хотя бы откроем сайт.
      await _openWeb('https://shray77.github.io/vet-meteo/', 'Метео-Радар');
      return;
    }
    final picked = await showStationSheet(
      context,
      stations: stations,
      currentId: _stationId,
    );
    if (picked != null && picked.id != _stationId) {
      await PrefsService.setStationId(picked.id);
      if (mounted) setState(() => _stationId = picked.id);
    }
  }

  String _dateLabel() {
    const months = [
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    const weekdays = [
      'понедельник', 'вторник', 'среда', 'четверг',
      'пятница', 'суббота', 'воскресенье'
    ];
    final w = weekdays[_now.weekday - 1];
    return '$w, ${_now.day} ${months[_now.month - 1]}';
  }

  /// Горизонтальная лента живых карточек (null — если всё выключено/пусто).
  Widget? _feedStrip(String stationId) {
    final children = <Widget>[
      if (_feedOn['outlook'] == true && _feeds.outlook != null)
        OutlookCard(
          slice: _feeds.outlook!,
          stationId: stationId,
          onTap: () =>
              _openProject(kProjects.firstWhere((p) => p.id == 'meteo')),
        ),
      if (_feedOn['outbreaks'] == true && _feeds.outbreaks != null)
        OutbreaksCard(
          slice: _feeds.outbreaks!,
          onTap: () =>
              _openProject(kProjects.firstWhere((p) => p.id == 'heatmap')),
        ),
      if (_feedOn['verify'] == true && _feeds.verify != null)
        VerifyCard(
          slice: _feeds.verify!,
          onTap: () =>
              _openProject(kProjects.firstWhere((p) => p.id == 'meteo')),
        ),
      if (_feedOn['weekly'] == true && _feeds.weekly != null)
        WeeklyCard(
          slice: _feeds.weekly!,
          onTap: () =>
              _openProject(kProjects.firstWhere((p) => p.id == 'meteo')),
        ),
    ];
    if (children.isEmpty) return null;
    return SizedBox(
      height: 158,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 6),
        itemCount: children.length,
        itemBuilder: (_, i) => children[i],
        separatorBuilder: (_, _) => const SizedBox(width: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final st = _meteo.latest?.byId(_stationId) ??
        _meteo.latest?.stations.firstOrNull;
    final fc = _meteo.forecast?.byId(st?.id ?? _stationId);
    final fetchedAgo = _meteo.fetchedAt == null
        ? 0
        : DateTime.now().difference(_meteo.fetchedAt!).inMinutes;
    final strip = _feedStrip(st?.id ?? _stationId);

    return PopScope(
      canPop: false, // лаунчер не закрывается кнопкой «назад»
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0B0F14), Color(0xFF0B0F14), Color(0xFF101820)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Часы + настройки (закреплены сверху).
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_two(_now.hour)}:${_two(_now.minute)}',
                              style: const TextStyle(
                                fontSize: 56,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                height: 1.0,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _dateLabel().toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 1.5,
                                color: Colors.teal.shade200,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _openSettings,
                        icon: Icon(Icons.tune,
                            color: Colors.grey.shade400, size: 26),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Хаб скроллится целиком: метео → лента → плитки → дровер.
                  Expanded(
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 8),
                      children: [
                        MeteoCard(
                          station: st,
                          forecastStation: fc,
                          h0: _meteo.forecast?.h0 ?? '',
                          loading: _meteo.loading,
                          error: _meteo.error,
                          fetchedAgoMin: fetchedAgo,
                          onTap: _pickStation,
                          onLongPress: () => _openProject(
                              kProjects.firstWhere((p) => p.id == 'meteo')),
                          onRetry: () {
                            _meteo.refresh();
                            _feeds.refresh();
                          },
                        ),
                        if (strip != null) ...[
                          const SizedBox(height: 14),
                          strip,
                        ],
                        const SizedBox(height: 14),
                        GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.18,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            for (final p in kProjects)
                              ProjectTile(
                                project: p,
                                installed: _installed[p.package] ?? false,
                                onTap: () => _openProject(p),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        // Дровер всех приложений.
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const DrawerScreen()),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                  color: Colors.teal.withValues(alpha: 0.4)),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                            icon: const Icon(
                                Icons.apps, color: Color(0xFF2DD4A7)),
                            label: const Text(
                              'ВСЕ ПРИЛОЖЕНИЯ',
                              style: TextStyle(
                                  letterSpacing: 1.5,
                                  color: Colors.white,
                                  fontSize: 13),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
