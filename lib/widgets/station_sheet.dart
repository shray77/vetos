import 'package:flutter/material.dart';

import '../models/meteo.dart';
import '../theme/ds.dart';

/// Быстрый выбор станции метео-тайла: тёмный нижний шит с поиском.
/// Станции = районы Ростовской обл. (Таганрог, Новочеркасск, …).
Future<MeteoStation?> showStationSheet(
  BuildContext context, {
  required List<MeteoStation> stations,
  required String currentId,
}) {
  return showModalBottomSheet<MeteoStation>(
    context: context,
    backgroundColor: Ds.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Ds.radius)),
    ),
    isScrollControlled: true,
    builder: (_) => StationSheet(stations: stations, currentId: currentId),
  );
}

class StationSheet extends StatefulWidget {
  final List<MeteoStation> stations;
  final String currentId;

  const StationSheet({
    super.key,
    required this.stations,
    required this.currentId,
  });

  @override
  State<StationSheet> createState() => _StationSheetState();
}

class _StationSheetState extends State<StationSheet> {
  String _query = '';

  List<MeteoStation> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.stations;
    return widget.stations
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.id.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final ts = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Ds.borderStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 12, 18, 4),
              child: _SheetHeader(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'поиск: таганрог, новочеркасск…',
                  prefixIcon: Icon(Icons.search, color: Ds.faint),
                  fillColor: Ds.bg,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text('ничего не нашлось',
                          style: ts.bodyMedium!
                              .copyWith(color: Ds.faint)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 18),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final s = list[i];
                        final status =
                            s.thi == null ? null : ThiStatus.of(s.thi!);
                        final isCurrent = s.id == widget.currentId;
                        return ListTile(
                          dense: true,
                          leading: Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: status?.color ?? Ds.border,
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(
                            s.name,
                            style: ts.titleMedium!.copyWith(
                              color: isCurrent ? Ds.accent : null,
                              fontWeight: isCurrent ? FontWeight.w700 : null,
                            ),
                          ),
                          trailing: Text(
                            [
                              s.thi == null ? null : 'THI ${s.thi!.toStringAsFixed(1)}',
                              s.cci == null
                                  ? null
                                  : 'CCI ${s.cci! > 0 ? '+' : ''}${s.cci!.toStringAsFixed(0)}°',
                            ].where((t) => t != null).join(' · '),
                            style: ts.titleSmall!
                                .copyWith(color: status?.color ?? Ds.faint),
                          ),
                          onTap: () => Navigator.of(context).pop(s),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Шапка шита: капс-оверлайн + счётчик.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    final ts = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          'СТАНЦИЯ МЕТЕО-ТАЛА',
          style: ts.labelMedium!.copyWith(color: Ds.text),
        ),
        const Spacer(),
        Text('районы РО · 49', style: ts.bodySmall),
      ],
    );
  }
}
