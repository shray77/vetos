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
              child: Row(
                children: [
                  Text(
                    'СТАНЦИЯ МЕТЕО-ТАЛА',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.5,
                      color: Ds.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'районы РО · 49',
                    style: TextStyle(fontSize: 11, color: Ds.faint),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: Ds.text),
                decoration: InputDecoration(
                  hintText: 'поиск: таганрог, новочеркасск…',
                  hintStyle: const TextStyle(color: Ds.faint),
                  prefixIcon: const Icon(Icons.search, color: Ds.faint),
                  filled: true,
                  fillColor: Ds.bg,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Ds.radius),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text('ничего не нашлось',
                          style: const TextStyle(
                              color: Ds.faint, fontSize: 13)),
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
                            style: TextStyle(
                              color: isCurrent ? Ds.accent : Ds.text,
                              fontSize: 14.5,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          trailing: Text(
                            [
                              s.thi == null ? null : 'THI ${s.thi!.toStringAsFixed(1)}',
                              s.cci == null
                                  ? null
                                  : 'CCI ${s.cci! > 0 ? '+' : ''}${s.cci!.toStringAsFixed(0)}°',
                            ].where((t) => t != null).join(' · '),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: status?.color ?? Ds.faint,
                              fontWeight: FontWeight.w600,
                            ),
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
