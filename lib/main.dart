import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ru_RU');
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
  ));
  // Лимит кэша изображений: по умолчанию Flutter держит 100 МБ / 1000 картинок.
  // На Helio G35 (4 ГБ ОЗУ) это давит на GC и зря жрёт память. Срезы ленты
  // + 6 плиток проектов — это ~15 картинок максимум, 30 МБ / 30 шт. за глаза.
  PaintingBinding.instance.imageCache.maximumSize = 30;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 30 << 20;
  runApp(const VetOsApp());
}

class VetOsApp extends StatelessWidget {
  const VetOsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VetOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0F14),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2DD4A7),
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
