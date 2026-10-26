// Golden-рендер экранов VetOS (голос C «Прибор», тёмный) для визуального
// аудита темы DS. По прецеденту ветэко/ветвойс (Task 176, идея №8).
// Обновление базы (создание/обновление PNG):
//   flutter test --update-goldens test/golden_screens_test.dart
//
// ОСОБЕННОСТИ VETOS (vs ветэко/ветвойс):
//  - голос C — единственная тема Ds.theme() (тёмный «Прибор»);
//  - живые данные (метео/лента) тянутся HTTP с таймаутами 12–15 с —
//    в тестах сети нет: кадры снимаются с ЧЕСТНЫМ офлайн-состоянием
//    (таймауты прогоняются fake-пампом ~50 с);
//  - BrowserScreen — WebView, в widget-тестах не рендерится → вне базы;
//  - LaunchService.isInstalled — MethodChannel, но try/catch → false.
import 'dart:convert';
import 'dart:io';

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
  final families = <String, List<String>>{
    'Prata': ['assets/fonts/Prata-Regular.ttf'],
    'Roboto': [
      '/home/z/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
      '/home/z/flutter/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf',
      '/home/z/flutter/bin/cache/artifacts/material_fonts/Roboto-Bold.ttf',
      '/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf',
    ],
    'MaterialIcons': [
      '/home/z/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ],
  };
  for (final e in families.entries) {
    final loader = FontLoader(e.key);
    for (final path in e.value) {
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

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await _loadRealFonts();
  });

  testWidgets('golden: 01_home', (tester) async {
    await _render(tester, const HomeScreen(), '01_home');
  });

  testWidgets('golden: 02_home_small', (tester) async {
    await _render(tester, const HomeScreen(), '02_home_small',
        logical: const Size(320, 568));
  });

  testWidgets('golden: 03_projects', (tester) async {
    await _render(
        tester,
        ProjectsScreen(
          onOpen: (_) async {},
          installed: const {},
        ),
        '03_projects');
  });

  testWidgets('golden: 04_settings', (tester) async {
    await _render(
        tester,
        SettingsScreen(
          meteo: MeteoService(),
          stationId: '37',
          intervalMin: 30,
          onChanged: (_, __) {},
        ),
        '04_settings');
  });

  testWidgets('golden: 05_drawer', (tester) async {
    await _render(tester, const DrawerScreen(), '05_drawer');
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
}
