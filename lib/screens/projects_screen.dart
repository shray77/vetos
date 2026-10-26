import 'package:flutter/material.dart';

import '../models/project.dart';
import '../theme/ds.dart';

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
    final ts = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Ds.bg,
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
                    icon: const Icon(Icons.arrow_back, color: Ds.accent),
                  ),
                  Expanded(
                    child: Text(
                      'ВСЕ ПРОЕКТЫ',
                      style: ts.titleLarge,
                    ),
                  ),
                  Text(
                    '${list.length} из ${kProjects.length}',
                    style: ts.bodySmall,
                  ),
                ],
              ),
            ),
            // Поиск.
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'поиск: название, раздел…',
                  prefixIcon:
                      Icon(Icons.search, color: Ds.faint, size: 22),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10),
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
                        style: ts.bodyMedium,
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
      selectedColor: Ds.accent,
      backgroundColor: Ds.surface,
      labelStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
        color: selected ? Ds.accentInk : Ds.text,
      ),
      onSelected: (_) => setState(() => _cat = cat),
    );
  }

  Widget _tile(Project p) {
    final isApp = p.kind == ProjectKind.app;
    final installed = widget.installed[p.package] ?? false;
    final ts = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => widget.onOpen(p),
      borderRadius: BorderRadius.circular(Ds.radius),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Ds.surface,
          borderRadius: BorderRadius.circular(Ds.radius),
          border: Border.all(color: p.color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            // Иконка-кружок проекта: монохромный глиф с тинтом цвета.
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(Ds.radius),
              ),
              child: Icon(p.icon, size: 24, color: p.color),
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
                          style: ts.titleMedium,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Ds.text.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          p.category.label,
                          style: ts.labelSmall!
                              .copyWith(color: Ds.muted, fontSize: 10.5),
                        ),
                      ),
                      if (p.home) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Ds.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'на экране',
                            style: ts.labelSmall!
                                .copyWith(color: Ds.accent, fontSize: 10.5),
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
                    style: ts.bodySmall,
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
              color: isApp && installed ? Ds.accent : Ds.faint,
            ),
          ],
        ),
      ),
    );
  }
}
