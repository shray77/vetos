import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_screen.dart';
import 'theme/ds.dart';

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
      // Дизайн-система vet-ds v2.3, голос C «Прибор»: токены в Material-слое.
      theme: Ds.theme(),
      home: const HomeScreen(),
    );
  }
}
