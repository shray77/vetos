import 'dart:async';

import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_two(_now.hour)}:${_two(_now.minute)}',
          style: widget.timeStyle ??
              const TextStyle(
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
          style: widget.dateStyle ??
              TextStyle(
                fontSize: 12,
                letterSpacing: 1.5,
                color: Colors.teal.shade200,
              ),
        ),
      ],
    );
  }
}
