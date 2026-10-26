import 'dart:async';

import 'package:flutter/material.dart';

import '../models/project.dart';
import '../services/feed_service.dart';
import '../services/launch_service.dart';
import '../services/meteo_service.dart';
import '../services/prefs_service.dart';
import '../widgets/clock_widget.dart';
import '../widgets/feed_cards.dart';
import '../widgets/meteo_card.dart';
import '../widgets/project_tile.dart';
import '../widgets/station_sheet.dart';
import 'browser_screen.dart';
import 'drawer_screen.dart';
import 'projects_screen.dart';
import 'settings_screen.dart';
import '../theme/ds.dart';

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
  Timer? _meteoTimer;
  String _stationId = 'rostov';
  int _intervalMin = 20;
  final Map<String, bool> _installed = {};

  /// Видимость карточек ленты (id → включена).
  final Map<String, bool> _feedOn = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    _stationId = await PrefsService.stationId();
    _intervalMin = await PrefsService.intervalMin();
    _feedOn['outlook'] = await PrefsService.feedEnabled('outlook');
    _feedOn['outbreaks'] = await PrefsService.feedEnabled('outbreaks');
    _feedOn['verify'] = await PrefsService.feedEnabled('verify');
    _feedOn['weekly'] = await PrefsService.feedEnabled('weekly');
    _feedOn['tspulse'] = await PrefsService.feedEnabled('tspulse');
    _feedOn['digest'] = await PrefsService.feedEnabled('digest');
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
    _meteoTimer?.cancel();
    _meteo.dispose();
    _feeds.dispose();
    super.dispose();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(DsRoute(
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
    for (final id in const [
      'outlook', 'outbreaks', 'verify', 'weekly', 'tspulse', 'digest'
    ]) {
      _feedOn[id] = await PrefsService.feedEnabled(id);
    }
    if (mounted) setState(() {});
  }

  /// Открывает проект: APK — по пакету (фолбэк на веб), веб — браузером плиток.
  /// Фейл запуска APK больше не тишина: тост DS говорит, что идёт фолбэк.
  Future<void> _openProject(Project p) async {
    if (p.kind == ProjectKind.app && p.package != null) {
      final installed = await LaunchService.isInstalled(p.package!);
      if (installed && await LaunchService.launchPackage(p.package!)) {
        return;
      }
      if (installed && mounted) {
        Ds.snack(context, '«${p.title}» не открылся — пробуем веб-версию');
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
      await Navigator.of(context).push(DsRoute(
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
      if (_feedOn['tspulse'] == true && _feeds.tspulse != null)
        TspulseCard(
          slice: _feeds.tspulse!,
          onTap: () =>
              _openProject(kProjects.firstWhere((p) => p.id == 'pilots')),
        ),
      if (_feedOn['digest'] == true && _feeds.digest != null)
        DigestCard(
          slice: _feeds.digest!,
          onTap: () => _openProject(
              kProjects.firstWhere((p) => p.id == 'digest-audio')),
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
              colors: [Ds.bg, Ds.bg, Ds.surface],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Часы (собственный StatefulWidget — тайлер 1с НЕ дёргает
                  // весь HomeScreen) + кнопка настроек.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(child: ClockWidget()),
                      IconButton(
                        onPressed: _openSettings,
                        icon: const Icon(Icons.tune,
                            color: Ds.muted, size: 26),
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
                        // На домашнем — только ядро экосистемы (home: true);
                        // остальные проекты — в каталоге «Все проекты» (v0.4.0).
                        GridView.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.18,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            for (final p in kProjects.where((p) => p.home))
                              ProjectTile(
                                project: p,
                                installed: _installed[p.package] ?? false,
                                onTap: () => _openProject(p),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Каталог всех проектов: поиск + разделы.
                        // DS-иерархия: экосистема — акцент, система — нейтрально.
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              DsRoute(
                                builder: (_) => ProjectsScreen(
                                  onOpen: _openProject,
                                  installed: _installed,
                                ),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                  color: Ds.accent.withValues(alpha: 0.4)),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(Ds.radius)),
                            ),
                            icon: const Icon(Icons.dashboard_outlined,
                                color: Ds.accent),
                            label: Text(
                              'ВСЕ ПРОЕКТЫ · ${kProjects.length}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge!
                                  .copyWith(letterSpacing: 1.4),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Дровер всех приложений.
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              DsRoute(
                                  builder: (_) => const DrawerScreen()),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                  color: Ds.borderStrong
                                      .withValues(alpha: 0.6)),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(Ds.radius)),
                            ),
                            icon: const Icon(
                                Icons.apps, color: Ds.muted),
                            label: Text(
                              'ВСЕ ПРИЛОЖЕНИЯ',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge!
                                  .copyWith(letterSpacing: 1.4),
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
