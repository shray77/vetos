import 'package:flutter/material.dart';

import '../models/feeds.dart';
import '../models/meteo.dart';

/// Карточки «живой ленты экосистемы» — горизонтальная лента под
/// метео-тайлом. Каждая тянута из своего git-среза данных и
/// открывает соответствующий проект по тапу.
///
/// Высота ленты фиксированная (156), ширина карточки 288.

/// Общая оболочка карточки ленты: тёмный градиент + цвет проекта.
class FeedShell extends StatelessWidget {
  final Color accent;
  final Widget child;
  final VoidCallback onTap;

  const FeedShell({
    super.key,
    required this.accent,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 288,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF111827),
              Color.lerp(const Color(0xFF111827), accent, 0.22)!,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: child,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String right;
  final Color accent;

  const _Header(this.title, this.right, this.accent);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ),
        Text(
          right,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
        ),
      ],
    );
  }
}

String _dmy(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

/// «7 дней» — outlook THI по выбранной станции (наследует станцию метео).
class OutlookCard extends StatelessWidget {
  final OutlookSlice slice;
  final String stationId;
  final VoidCallback onTap;

  const OutlookCard({
    super.key,
    required this.slice,
    required this.stationId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF2DD4A7);
    final st = slice.byId(stationId) ?? slice.stations.firstOrNull;
    final thiMax = st?.thiMax7;
    final status = thiMax == null ? null : ThiStatus.of(thiMax);

    return FeedShell(
      accent: status?.color ?? accent,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header('7 ДНЕЙ · THI', st?.name ?? '', accent),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                thiMax == null ? '—' : thiMax.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                  color: status?.color ?? Colors.grey,
                ),
              ),
              const SizedBox(width: 10),
              _chip(
                'дн >72: ${st?.days72 ?? '—'}',
                (st?.days72 ?? 0) > 0,
                Colors.orange,
              ),
              const SizedBox(width: 6),
              _chip(
                'дн >80: ${st?.days80 ?? '—'}',
                (st?.days80 ?? 0) > 0,
                Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _DayBars(values: st?.perDay ?? const []),
          const Spacer(),
          Text(
            'максимум за ${slice.horizon} · обновлено ${_dmy(slice.generatedAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, bool active, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (active ? color : Colors.grey).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: active ? color : Colors.grey.shade400,
        ),
      ),
    );
  }
}

/// Мини-бары THI по дням с пороговой раскраской.
class _DayBars extends StatelessWidget {
  final List<double> values;

  const _DayBars({required this.values});

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return SizedBox(
        height: 34,
        child: Center(
          child: Text('по дням: —',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ),
      );
    }
    var minV = values.reduce((a, b) => a < b ? a : b);
    var maxV = values.reduce((a, b) => a > b ? a : b);
    minV = (minV - 4).clamp(50, 90);
    maxV = (maxV + 2).clamp(minV + 8, 95);
    final span = maxV - minV;

    return SizedBox(
      height: 34,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: FractionallySizedBox(
                  heightFactor:
                      ((values[i] - minV) / span).clamp(0.12, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: ThiStatus.of(values[i]).color,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Вспышки — живой срез ВетКарты (docs/data/outbreaks.json).
class OutbreaksCard extends StatelessWidget {
  final OutbreaksSlice slice;
  final VoidCallback onTap;

  const OutbreaksCard({
    super.key,
    required this.slice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF59E0B);
    final recent = slice.recent(3);

    return FeedShell(
      accent: accent,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            'ВСПЫШКИ · ВЕТКАРТА',
            '${slice.total} зап · ${slice.updatedLabel}',
            accent,
          ),
          const SizedBox(height: 8),
          for (final o in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                        color: accent, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text(
                      o.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5,
                          color: Colors.white,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    o.dateLabel,
                    style: TextStyle(
                        fontSize: 12.5, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
          const Spacer(),
          Text(
            'Ростовская обл. · с 2019 · тап — карта',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

/// Прогноз vs факт — ретро-проверка качества прогноза.
class VerifyCard extends StatelessWidget {
  final VerifySlice slice;
  final VoidCallback onTap;

  const VerifyCard({super.key, required this.slice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF818CF8);

    return FeedShell(
      accent: accent,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header('ПРОГНОЗ vs ФАКТ', 'ретро-проверка', accent),
          const SizedBox(height: 8),
          Text(
            'расхождения: ${slice.verdict}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'MAE THI ${slice.thiMae?.toStringAsFixed(1) ?? '—'} ед'
            ' · ${slice.days ?? '—'} дн · ${slice.stations ?? '—'} ст',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade300),
          ),
          const Spacer(),
          Text(
            'проверка от ${_dmy(slice.generatedAt)} · тап — радар',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

/// Недельный дайджест радара (data/weekly.json).
class WeeklyCard extends StatelessWidget {
  final WeeklySlice slice;
  final VoidCallback onTap;

  const WeeklyCard({super.key, required this.slice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF38BDF8);
    final lines = slice.digest.take(3).toList();

    return FeedShell(
      accent: accent,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header('НЕДЕЛЬНЫЙ ДАЙДЖЕСТ', slice.to, accent),
          const SizedBox(height: 8),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                l,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 12.5, color: Colors.grey.shade200, height: 1.3),
              ),
            ),
          const Spacer(),
          Text(
            'архив · ${slice.from} … ${slice.to} · тап — радар',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
