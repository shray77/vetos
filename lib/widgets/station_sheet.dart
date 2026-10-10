import 'package:flutter/material.dart';

import '../models/meteo.dart';

/// Быстрый выбор станции метео-тайла: тёмный нижний шит с поиском.
/// Станции = районы Ростовской обл. (Таганрог, Новочеркасск, …).
Future<MeteoStation?> showStationSheet(
  BuildContext context, {
  required List<MeteoStation> stations,
  required String currentId,
}) {
  return showModalBottomSheet<MeteoStation>(
    context: context,
    backgroundColor: const Color(0xFF111827),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                color: Colors.grey.shade700,
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
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'районы РО · 49',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
              child: TextField(
                autofocus: false,
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'поиск: таганрог, новочеркасск…',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.grey.shade500),
                  filled: true,
                  fillColor: const Color(0xFF0B0F14),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text('ничего не нашлось',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 13)),
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
                              color: status?.color ??
                                  const Color(0xFF374151),
                              shape: BoxShape.circle,
                            ),
                          ),
                          title: Text(
                            s.name,
                            style: TextStyle(
                              color: isCurrent
                                  ? const Color(0xFF2DD4A7)
                                  : Colors.white,
                              fontSize: 14.5,
                              fontWeight: isCurrent
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          trailing: Text(
                            s.thi == null
                                ? '—'
                                : 'THI ${s.thi!.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: status?.color ?? Colors.grey.shade500,
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
