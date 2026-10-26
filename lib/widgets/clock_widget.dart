import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/ds.dart';

/// Часы и дата — выделены в отдельный StatefulWidget, чтобы таймер 1с
/// НЕ пересобирал весь HomeScreen (метео-карту, ленту, 6 плиток, дровер).
///
/// Доп. оптимизация под слабые устройства (Helio G35 / 4 ГБ ОЗУ):
/// таймер тикает раз в секунду, но setState вызывается только когда
/// сменилась минута — то есть 1 раз/мин вместо 60 раз/мин.
class ClockWidget extends StatefulWidget {
  final TextStyle? timeStyle;
  final TextStyle? dateStyle;

  const ClockWidget({
    super.key,
    this.timeStyle,
    this.dateStyle,
  });

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  Timer? _t;
  DateTime _now = DateTime.now();

  static const _months = [
    'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
    'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
  ];
  static const _weekdays = [
    'понедельник', 'вторник', 'среда', 'четверг',
    'пятница', 'суббота', 'воскресенье'
  ];

  @override
  void initState() {
    super.initState();
    // Поллинг 1с копеечный (DateTime.now), но setState — только при смене минуты.
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      if (now.minute != _now.minute ||
          now.hour != _now.hour ||
          now.day != _now.day) {
        if (mounted) setState(() => _now = now);
      }
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _dateLabel() {
    final w = _weekdays[_now.weekday - 1];
    return '$w, ${_now.day} ${_months[_now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final ts = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_two(_now.hour)}:${_two(_now.minute)}',
          // Prata-дисплей DS (displayLarge): цифры «мастхеда» домашнего
          // экрана — роль темы, а не локальный литерал.
          style: widget.timeStyle ?? ts.displayLarge,
        ),
        const SizedBox(height: 4),
        Text(
          _dateLabel().toUpperCase(),
          // Оверлайн DS: капс с трекингом, акцентный цвет.
          style: widget.dateStyle ??
              ts.labelMedium!.copyWith(color: Ds.accent),
        ),
      ],
    );
  }
}
