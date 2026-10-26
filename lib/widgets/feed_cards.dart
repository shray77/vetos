import 'package:flutter/material.dart';

import '../models/feeds.dart';
import '../models/meteo.dart';
import '../models/project.dart';
import '../theme/ds.dart';

/// Карточки «живой ленты экосистемы» — горизонтальная лента под
/// метео-тайлом. Каждая тянута из своего git-среза данных и
/// открывает соответствующий проект по тапу.
///
/// Акцент карточки — цвет проекта, куда она ведёт (реестр kProjects —
/// единый источник), а не дублированный литерал.
///
/// Высота ленты фиксированная (156), ширина карточки 288.

Color _projectColor(String id) =>
    kProjects.firstWhere((p) => p.id == id).color;

/// Общая оболочка карточки ленты: графитовая поверхность + цвет проекта.
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
              Ds.surface,
              Color.lerp(Ds.surface, accent, 0.22)!,
            ],
          ),
          borderRadius: BorderRadius.circular(Ds.radius),
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
          style: const TextStyle(fontSize: 11, color: Ds.faint),
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
    final accent = _projectColor('meteo');
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
                  color: status?.color ?? Ds.faint,
                ),
              ),
              const SizedBox(width: 10),
              _chip(
                'дн >72: ${st?.days72 ?? '—'}',
                (st?.days72 ?? 0) > 0,
                Ds.orange,
              ),
              const SizedBox(width: 6),
              _chip(
                'дн >80: ${st?.days80 ?? '—'}',
                (st?.days80 ?? 0) > 0,
                Ds.red,
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
            style: const TextStyle(fontSize: 11, color: Ds.faint),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, bool active, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (active ? color : Ds.faint).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: active ? color : Ds.muted,
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
              style: const TextStyle(fontSize: 11, color: Ds.faint)),
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
    final accent = _projectColor('heatmap');
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
                    decoration: BoxDecoration(
                        color: accent, shape: BoxShape.circle),
                  ),
                  Expanded(
                    child: Text(
                      o.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5,
                          color: Ds.text,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    o.dateLabel,
                    style: const TextStyle(
                        fontSize: 12.5, color: Ds.muted),
                  ),
                ],
              ),
            ),
          const Spacer(),
          Text(
            'Ростовская обл. · с 2019 · тап — карта',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Ds.faint),
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
    final accent = _projectColor('insilico');

    return FeedShell(
      accent: accent,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header('ПРОГНОЗ vs ФАКТ', 'ретро-проверка', accent),
          const SizedBox(height: 8),
          Text(
            'расхождения: ${slice.verdict}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Ds.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'MAE THI ${slice.thiMae?.toStringAsFixed(1) ?? '—'} ед'
            ' · ${slice.days ?? '—'} дн · ${slice.stations ?? '—'} ст',
            style: const TextStyle(fontSize: 12.5, color: Ds.muted),
          ),
          const Spacer(),
          Text(
            'проверка от ${_dmy(slice.generatedAt)} · тап — радар',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Ds.faint),
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
    final accent = _projectColor('learn');
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
                style: const TextStyle(
                    fontSize: 12.5, color: Ds.muted, height: 1.3),
              ),
            ),
          const Spacer(),
          Text(
            'архив · ${slice.from} … ${slice.to} · тап — радар',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Ds.faint),
          ),
        ],
      ),
    );
  }
}

/// Аномалия недели — пилот TSPulse (tspulse/latest.json, вет-пилоты).
/// Цвет карточки = сила сигнала: выше порога — красный, перцентиль ≥ 80 —
/// янтарный, иначе спокойный зелёный.
class TspulseCard extends StatelessWidget {
  final TspulseSlice slice;
  final VoidCallback onTap;

  const TspulseCard({super.key, required this.slice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Цвет карточки = сила сигнала: выше порога — красный, перцентиль >= 80 —
    // янтарный, иначе спокойный зелёный (семантика DS).
    final signal = (slice.daysOver ?? 0) > 0
        ? Ds.red
        : (slice.percentileMax ?? 0) >= 80
            ? Ds.amber
            : Ds.green;
    final diseases = slice.diseasesTop3;

    return FeedShell(
      accent: signal,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header('АНОМАЛИЯ · TSPULSE', slice.windowLabel, signal),
          const SizedBox(height: 8),
          Text(
            slice.verdict,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Ds.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'max ${slice.maxScore?.toStringAsFixed(2) ?? '—'} · '
            '${slice.percentileMax?.toStringAsFixed(1) ?? '—'} перцентиль',
            style: const TextStyle(fontSize: 12.5, color: Ds.muted),
          ),
          if (diseases.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              diseases,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, color: Ds.muted),
            ),
          ],
          const Spacer(),
          Text(
            'порог ${slice.threshold?.toStringAsFixed(1) ?? '—'} · '
            'выше ${slice.daysOver ?? 0} дн · тап — пилоты',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Ds.faint),
          ),
        ],
      ),
    );
  }
}

/// Дайджест недели от LLM (data/llm_digest.json, вет-дайджест).
/// Тап открывает сайт дайджеста — там полный текст и аудио-версия Piper.
class DigestCard extends StatelessWidget {
  final DigestSlice slice;
  final VoidCallback onTap;

  const DigestCard({super.key, required this.slice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = _projectColor('digest-audio');
    final headline =
        slice.headline.isNotEmpty ? slice.headline : slice.summary;

    return FeedShell(
      accent: accent,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header('ДАЙДЖЕСТ · LLM', slice.weekKey, accent),
          const SizedBox(height: 8),
          Text(
            headline,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: Ds.muted,
              height: 1.35,
            ),
          ),
          const Spacer(),
          Text(
            'события ${slice.events} · источники ${slice.sourcesOk} · '
            'тап — дайджест и аудио',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: Ds.faint),
          ),
        ],
      ),
    );
  }
}
