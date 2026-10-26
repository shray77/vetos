import 'package:flutter/material.dart';

import '../models/project.dart';
import '../theme/ds.dart';

/// Плитка проекта на домашнем экране.
class ProjectTile extends StatelessWidget {
  final Project project;
  final bool installed; // для kind == app: установлено ли APK
  final VoidCallback onTap;

  const ProjectTile({
    super.key,
    required this.project,
    required this.installed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isApp = project.kind == ProjectKind.app;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Ds.radius),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Ds.surface,
          borderRadius: BorderRadius.circular(Ds.radius),
          border: Border.all(
            color: project.color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(project.icon, size: 28, color: project.color),
                _statusDot(isApp),
              ],
            ),
            const Spacer(),
            Text(
              project.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Ds.text,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              isApp && !installed ? 'не установлен · веб' : project.subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Ds.faint,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusDot(bool isApp) {
    if (!isApp) {
      return const Icon(Icons.language, size: 16, color: Ds.faint);
    }
    return Icon(
      installed ? Icons.check_circle : Icons.circle_outlined,
      size: 16,
      color: installed ? Ds.accent : Ds.faint,
    );
  }
}
