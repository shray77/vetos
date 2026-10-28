import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/meteo.dart';
import '../theme/ds.dart';

/// Живой метео-тайл: THI станции по умолчанию + CCI (комфорт, °C) + мини-прогноз на 24 ч.
class MeteoCard extends StatelessWidget {
  final MeteoStation? station;
  final ForecastStation? forecastStation;
  final String h0;
  final bool loading;
  final String? error;
  final int fetchedAgoMin;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  /// Долгий тап — открыть полный метео-радар (в браузере плиток).
  final VoidCallback? onLongPress;

  const MeteoCard({
    super.key,
    required this.station,
    required this.forecastStation,
    required this.h0,
    required this.loading,
    required this.error,
    required this.fetchedAgoMin,
    required this.onTap,
    required this.onRetry,
    this.onLongPress,
  });

  String _fmt(double? v) =>
      v == null ? '—' : v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    final s = station;
    final thi = s?.thi;
    final status = thi == null ? null : ThiStatus.of(thi);
    final ts = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Ds.surface,
              Color.lerp(
                Ds.surface,
                status?.color ?? Ds.surface2,
                0.35,
              )!,
            ],
          ),
          borderRadius: BorderRadius.circular(Ds.radius),
          border: Border.all(
            color: (status?.color ?? Ds.border).withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ТЕПЛОВОЙ СТРЕСС · THI',
                        style: ts.labelSmall,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            thi == null ? (loading ? '…' : '—') : _fmt(thi),
                            // Приборная цифра: Prata-дисплей DS (displayMedium).
                            style: ts.displayMedium!.copyWith(
                              color: status?.color ?? Ds.faint,
                            ),
                          ),
                          const SizedBox(width: 10),
                          if (status != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: status.color.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                status.label.toUpperCase(),
                                style: ts.labelMedium!
                                    .copyWith(color: status.color),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  IconButton(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh,
                        color: Ds.muted, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _metric('${_fmt(s?.t)}°', 'темп', ts.titleMedium, ts.bodySmall),
                _metric('${s?.rh ?? '—'}%', 'влажн', ts.titleMedium, ts.bodySmall),
                _metric('${_fmt(s?.wind)} м/с', 'ветер ${s?.windDirLabel ?? ''}',
                    ts.titleMedium, ts.bodySmall),
                _metric(_fmt(s?.thiAdj), 'THIadj', ts.titleMedium, ts.bodySmall),
                _metric(
                  s?.cci == null ? '—' : '${_fmt(s?.cci)}°',
                  'CCI${s?.cci != null ? ' · ${CciStatus.of(s!.cci!).label}' : ''}',
                  ts.titleMedium,
                  ts.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (error != null && s == null)
              Row(
                children: [
                  Icon(Icons.cloud_off, size: 14, color: Ds.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      error!,
                      style: ts.bodySmall!.copyWith(color: Ds.red),
                    ),
                  ),
                  TextButton(onPressed: onRetry, child: const Text('повтор')),
                ],
              )
            else
              _Sparkline(
                values: forecastStation?.thi ?? const [],
                accent: status?.color ?? Ds.accent,
              ),
            const SizedBox(height: 8),
            Text(
              s == null
                  ? 'метео-радар · загрузка…'
                  : '${s.name} · срез $fetchedAgoMin мин назад · тап — станция'
                    '${forecastStation != null ? ' · прогноз от $h0 МСК' : ''}',
              style: ts.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String value, String label, TextStyle? valueStyle,
      TextStyle? labelStyle) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: valueStyle),
          Text(label, style: labelStyle),
        ],
      ),
    );
  }
}

/// Спарк-лайн THI на 24 ч с порогами 68/72.
class _Sparkline extends StatelessWidget {
  final List<double> values;
  final Color accent;

  const _Sparkline({required this.values, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(
        height: 44,
        child: Center(
          child: Text('прогноз: —',
              style: Theme.of(context).textTheme.bodySmall),
        ),
      );
    }
    return SizedBox(
      height: 44,
      child: CustomPaint(
        size: const Size(double.infinity, 44),
        painter: _SparkPainter(values: values.take(24).toList(), accent: accent),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final List<double> values;
  final Color accent;

  _SparkPainter({required this.values, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n < 2) return;
    var minV = values.reduce(math.min);
    var maxV = values.reduce(math.max);
    minV = math.min(minV, 66);
    maxV = math.max(maxV, 74);
    final span = (maxV - minV).clamp(1.0, double.infinity);

    // Пороговые линии 68 и 72.
    for (final th in const [68.0, 72.0]) {
      if (th >= minV && th <= maxV) {
        final y = size.height * (1 - (th - minV) / span);
        final paint = Paint()
          ..color = (th >= 72 ? Ds.orange : Ds.amber).withValues(alpha: 0.35)
          ..strokeWidth = 1;
        canvas.drawLine(
            Offset(0, y), Offset(size.width, y), paint);
      }
    }

    final path = Path();
    final fill = Path();
    for (var i = 0; i < n; i++) {
      final x = size.width * i / (n - 1);
      final y = size.height * (1 - (values[i] - minV) / span);
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [accent.withValues(alpha: 0.25), accent.withValues(alpha: 0.02)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(fill, fillPaint);

    final linePaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Пик.
    var maxI = 0;
    for (var i = 1; i < n; i++) {
      if (values[i] > values[maxI]) maxI = i;
    }
    final px = size.width * maxI / (n - 1);
    final py = size.height * (1 - (values[maxI] - minV) / span);
    canvas.drawCircle(
        Offset(px, py), 3.5, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.values != values || old.accent != accent;
}
