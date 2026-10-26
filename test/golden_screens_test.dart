// Golden-рендер экранов VetOS (голос C «Прибор», тёмный) для визуального
// аудита темы DS. По прецеденту ветэко/ветвойс (Task 176, идея №8).
// Обновление базы (создание/обновление PNG):
//   flutter test --update-goldens test/golden_screens_test.dart
//
// ОСОБЕННОСТИ VETOS (vs ветэко/ветвойс):
//  - голос C — единственная тема Ds.theme() (тёмный «Прибор»);
//  - живые данные (метео/лента) тянутся HTTP с таймаутами 12–15 с —
//    сеть в тестах ОТКЛЮЧАЕНА HttpOverrides (в песочнице GitHub достижим —
//    реальные ответы прилетали в fake-зону и делали кадр
//    недетерминированным: диффы 0.16–0.46% от «обновлено HH:MM»);
//    кадры снимаются с ЧЕСТНЫМ офлайн-состоянием (роадмап vetos —
//    «офлайн-устойчивость»), таймауты прогоняются фейк-пампом ~55 с;
//  - BrowserScreen — WebView, в widget-тестах не рендерится → вне базы;
//  - LaunchService.isInstalled — MethodChannel, но try/catch → false.
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vetos/screens/drawer_screen.dart';
import 'package:vetos/screens/home_screen.dart';
import 'package:vetos/screens/projects_screen.dart';
import 'package:vetos/screens/settings_screen.dart';
import 'package:vetos/services/meteo_service.dart';
import 'package:vetos/theme/ds.dart';

/// Сеть выключена: golden-кадры не должны зависеть от того, успел ли
/// реальный GitHub ответить внутри fake-пампинга (ловили диффы 0.2–0.5%
/// от живых меток «обновлено HH:MM»). Офлайн — детерминированный сценарий.
/// Клиент «мёртв»: конструируется нормально (сервисы зовут new Client()
/// прямо в полях стейта — синхронный throw ронял бы билд), а ЗАПРОСЫ
/// падают асинхронно → сервисы уходят в честные catch/timeout-ветки.
class _DeadClient implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      Future.error(const SocketException('golden-тесты: сеть отключена'));

  @override
  void close({bool force = false}) {}   // dispose сервисов зовёт close(force: true)

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _DeadClient();
}

Widget _wrap(Widget screen) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: Ds.theme(),
    home: screen,
  );
}

Future<void> _render(WidgetTester tester, Widget screen, String name,
    {Size? logical}) async {
  final dpr = 2.0;
  logical ??= const Size(390, 844);
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = Size(logical.width * dpr, logical.height * dpr);
  addTearDown(tester.view.reset);

  await tester.pumpWidget(_wrap(screen));
  // Метео/лента: HTTP не отвечает — таймауты 12–15 с (+ретраи) прогоняем
  // фейковым временем, чтобы кадр снялся с устоявшимся офлайн-состоянием,
  // а не с мигающим «загрузка…».
  for (int i = 0; i < 110; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  await tester.pump(const Duration(milliseconds: 300));
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('golden/$name.png'),
  );
}

Future<void> _loadRealFonts() async {
  // Текст VetOS — Roboto (default), дисплей — Prata (бандл), иконки —
  // MaterialIcons из SDK-кеша; NotoColorEmoji — на всякий ✓-знак.
  // ГРАБЛЯ CI (Task 176): жёсткий путь песочницы не существует у раннера —
  // шрифты молча не грузились, текст рендерился тофу (диффы 25–42%).
  // Кандидаты: FLUTTER_ROOT (ставит subosito/flutter-action) + песочница.
  final fr = Platform.environment['FLUTTER_ROOT'] ?? '';
  final sdkFonts = <String>[
    if (fr.isNotEmpty) '$fr/bin/cache/artifacts/material_fonts',
    '/home/z/flutter/bin/cache/artifacts/material_fonts',
  ];
  String? resolve(String name) {
    for (final d in sdkFonts) {
      final f = File('$d/$name');
      if (f.existsSync()) return f.path;
    }
    return null;
  }

  final families = <String, List<String?>>{
    'Prata': ['assets/fonts/Prata-Regular.ttf'],
    'Roboto': [
      resolve('Roboto-Regular.ttf'),
      resolve('Roboto-Medium.ttf'),
      resolve('Roboto-Bold.ttf'),
      '/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf',
    ],
    'MaterialIcons': [resolve('MaterialIcons-Regular.otf')],
  };
  for (final e in families.entries) {
    final loader = FontLoader(e.key);
    for (final path in e.value) {
      if (path == null) {
        // ignore: avoid_print
        print('FONT MISSING: ${e.key} (нет ни одного пути)');
        continue;
      }
      final f = File(path);
      if (f.existsSync()) {
        loader.addFont(
            Future.value(ByteData.view(f.readAsBytesSync().buffer)));
      } else {
        // ignore: avoid_print
        print('FONT MISSING: $path');
      }
    }
    await loader.load();
  }
}

/// Часы фиксированы: ClockWidget рендерит время — без фиксации кадр зависит
/// от минуты прогона (поймано stability-прогонами: 3-й ран пересекал минуту).
/// clock 1.1.x не имеет сеттера — оверрайд зоной withClock.
final _fixedTime = Clock.fixed(DateTime(2026, 10, 27, 12, 34));

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    HttpOverrides.global = _NoNetwork();
    SharedPreferences.setMockInitialValues({});
    await _loadRealFonts();
  });

  testWidgets('golden: 01_home', (tester) async {
    await withClock(_fixedTime, () => _render(tester, const HomeScreen(), '01_home'));
  });

  testWidgets('golden: 02_home_small', (tester) async {
    await withClock(_fixedTime, () => _render(tester, const HomeScreen(),
        '02_home_small', logical: const Size(320, 568)));
  });

  testWidgets('golden: 03_projects', (tester) async {
    await withClock(_fixedTime, () => _render(
        tester,
        ProjectsScreen(
          onOpen: (_) async {},
          installed: const {},
        ),
        '03_projects'));
  });

  testWidgets('golden: 04_settings', (tester) async {
    await withClock(_fixedTime, () => _render(
        tester,
        SettingsScreen(
          meteo: MeteoService(),
          stationId: '37',
          intervalMin: 30,
          onChanged: (_, _) {},
        ),
        '04_settings'));
  });

  testWidgets('golden: 05_drawer', (tester) async {
    await withClock(_fixedTime, () => _render(tester, const DrawerScreen(), '05_drawer'));
  });

  testWidgets('golden: 06_home_statusbar', (tester) async {
    // edge-to-edge: SafeArea от статус-бара (44 логических px сверху),
    // как на реальном устройстве — проверяет, что THI-шапка не залезает
    // под системные часы.
    tester.view.devicePixelRatio = 2.0;
    tester.view.physicalSize = const Size(780, 1688);
    final sb = FakeViewPadding(top: 44, left: 0, right: 0, bottom: 24);
    tester.view.viewPadding = sb;
    tester.view.padding = sb;
    addTearDown(tester.view.reset);
    await withClock(_fixedTime, () async {
      await tester.pumpWidget(_wrap(const HomeScreen()));
      for (int i = 0; i < 110; i++) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      await tester.pump(const Duration(milliseconds: 300));
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('golden/06_home_statusbar.png'),
      );
    });
  });
}
