import 'package:flutter/material.dart';

import '../models/project.dart';

/// Каталог «Все проекты» (v0.4.0): поиск + разделы + список.
///
/// Домашний экран держит чистоту лаунчера — там только ядро из 6 плиток;
/// здесь живёт вся экосистема. Логика открытия — та же, что у плиток
/// домашнего экрана (APK по пакету → фолбэк на веб, веб — браузером плиток).
class ProjectsScreen extends StatefulWidget {
  /// Как открыть проект (общая логика с домашним экраном).
  final Future<void> Function(Project) onOpen;

  /// package → установлен ли (для статус-точек APK-проектов).
  final Map<String, bool> installed;

  const ProjectsScreen({
    super.key,
    required this.onOpen,
    required this.installed,
  });

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  String _query = '';
  ProjectCategory? _cat;

  @override
  void dispose() {
    // Контроллер поиска не заводим отдельно — TextField без контроллера
    // живёт в состоянии экрана, чистить нечего. Оставлено на будущее.
    super.dispose();
  }

  List<Project> get _filtered {
    final q = _query.trim().toLowerCase();
    return kProjects.where((p) {
      if (_cat != null && p.category != _cat) return false;
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q) ||
          p.subtitle.toLowerCase().contains(q) ||
          p.category.label.toLowerCase().contains(q);
    }).toList();
  }

  int _countCategory(ProjectCategory? cat) => cat == null
      ? kProjects.length
      : kProjects.where((p) => p.category == cat).length;

  @override
  Widget build(BuildContext context) {
    final list = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Шапка.
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 18, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon:
                        const Icon(Icons.arrow_back, color: Color(0xFF2DD4A7)),
                  ),
                  const Expanded(
                    child: Text(
                      'ВСЕ ПРОЕКТЫ',
                      style: TextStyle(
                        fontSize: 16,
                        letterSpacing: 1.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${list.length} из ${kProjects.length}',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            // Поиск.
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'поиск: название, раздел…',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(Icons.search,
                      color: Colors.grey.shade500, size: 22),
                  filled: true,
                  fillColor: const Color(0xFF111827),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // Разделы.
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _chip(null, 'Все'),
                  for (final c in ProjectCategory.values) _chip(c, c.label),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Список.
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Text(
                        'ничего не нашлось по «$_query»',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 14),
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _tile(list[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(ProjectCategory? cat, String label) {
    final selected = _cat == cat;
    return ChoiceChip(
      label: Text('$label ${_countCategory(cat)}'),
      selected: selected,
      selectedColor: const Color(0xFF2DD4A7),
      backgroundColor: const Color(0xFF111827),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF0B0F14) : Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      onSelected: (_) => setState(() => _cat = cat),
    );
  }

  Widget _tile(Project p) {
    final isApp = p.kind == ProjectKind.app;
    final installed = widget.installed[p.package] ?? false;
    return InkWell(
      onTap: () => widget.onOpen(p),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            // Иконка-кружок проекта.
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child:
                  Text(p.icon, style: const TextStyle(fontSize: 24)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          p.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          p.category.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      if (p.home) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2DD4A7)
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'на экране',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF2DD4A7),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isApp && !installed
                        ? 'не установлен · веб-версия'
                        : p.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isApp
                  ? (installed
                      ? Icons.check_circle
                      : Icons.circle_outlined)
                  : Icons.language,
              size: 17,
              color: isApp && installed
                  ? const Color(0xFF2DD4A7)
                  : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}
