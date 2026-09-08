
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/meteo.dart';

/// Живой метео-тайл: THI станции по умолчанию + мини-прогноз на 24 ч.
class MeteoCard extends StatelessWidget {
  final MeteoStation? station;
  final ForecastStation? forecastStation;
  final String h0;
  final bool loading;
  final String? error;
  final int fetchedAgoMin;
  final VoidCallback onTap;
  final VoidCallback onRetry;

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
  });

  String _fmt(double? v, [String suffix = '']) =>
      v == null ? '—' : v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    final s = station;
    final thi = s?.thi;
    final status = thi == null ? null : ThiStatus.of(thi);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF111827),
              Color.lerp(
                const Color(0xFF111827),
                status?.color ?? const Color(0xFF1F2937),
                0.35,
              )!,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: (status?.color ?? const Color(0xFF374151))
                .withValues(alpha: 0.35),
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
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.2,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            thi == null ? (loading ? '…' : '—') : _fmt(thi),
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w700,
                              color: status?.color ?? Colors.grey,
                              height: 1.0,
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
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: status.color,
                                ),
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
                    icon: Icon(Icons.refresh,
                        color: Colors.grey.shade400, size: 20),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _metric('${_fmt(s?.t)}°', 'темп'),
                _metric('${s?.rh ?? '—'}%', 'влажн'),
                _metric('${_fmt(s?.wind, ' ')} м/с', 'ветер ${s?.windDirLabel ?? ''}'),
                _metric(_fmt(s?.thiAdj), 'THIadj'),
              ],
            ),
            const SizedBox(height: 12),
            if (error != null && s == null)
              Row(
                children: [
                  Icon(Icons.cloud_off, size: 14, color: Colors.red.shade300),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      error!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.red.shade300),
                    ),
                  ),
                  TextButton(onPressed: onRetry, child: const Text('повтор')),
                ],
              )
            else
              _Sparkline(
                values: forecastStation?.thi ?? const [],
                accent: status?.color ?? const Color(0xFF2DD4A7),
              ),
            const SizedBox(height: 8),
            Text(
              s == null
                  ? 'метео-радар · загрузка…'
                  : '${s.name} · срез $fetchedAgoMin мин назад'
                    '${forecastStation != null ? ' · прогноз от $h0 МСК' : ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
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
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
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
          ..color = (th >= 72 ? Colors.orange : Colors.yellow)
              .withValues(alpha: 0.35)
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
