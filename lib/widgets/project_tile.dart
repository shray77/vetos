import 'package:flutter/material.dart';

import '../models/project.dart';

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
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: project.color.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(project.icon, style: const TextStyle(fontSize: 30)),
                _statusDot(isApp),
              ],
            ),
            const Spacer(),
            Text(
              project.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            Text(
              isApp && !installed ? 'не установлен · веб' : project.subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
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
      return Icon(Icons.language,
          size: 16, color: Colors.grey.shade600);
    }
    return Icon(
      installed ? Icons.check_circle : Icons.circle_outlined,
      size: 16,
      color: installed ? const Color(0xFF2DD4A7) : Colors.grey.shade600,
    );
  }
}
