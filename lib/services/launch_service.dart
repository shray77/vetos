import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/project.dart';

/// Приложение из системного списка (нативный мост vetos/apps).
class AppEntry {
  final String packageName;
  final String name;
  final bool system;
  final Uint8List? icon;

  AppEntry({
    required this.packageName,
    required this.name,
    required this.system,
    this.icon,
  });

  static AppEntry fromMap(Map m) => AppEntry(
        packageName: (m['package'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        system: (m['system'] ?? false) as bool,
        icon: m['icon'] is List
            ? Uint8List.fromList(
                (m['icon'] as List).cast<int>(),
              )
            : null,
      );
}

/// Запуск проектов экосистемы и внешних приложений.
/// Нативные операции — через собственный MethodChannel (vetos/apps),
/// без сторонних плагинов: совместимость с любым AGP/Gradle.
class LaunchService {
  static const _ch = MethodChannel('vetos/apps');

  /// Открывает проект: приложение — по package, веб — Custom Tabs/браузером.
  /// Если APK не установлен — мягкий фолбэк на веб-страницу проекта.
  static Future<void> openProject(Project p) async {
    if (p.kind == ProjectKind.app && p.package != null) {
      final installed = await isInstalled(p.package!);
      if (installed) {
        final launched = await launchPackage(p.package!);
        if (launched) return;
      }
      // Не установлен или не запустился — открываем веб.
      await openUrl(p.url);
      return;
    }
    await openUrl(p.url);
  }

  /// Проверяет, установлено ли приложение.
  static Future<bool> isInstalled(String package) async {
    try {
      return await _ch.invokeMethod('isInstalled', {'package': package})
              as bool? ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Запускает приложение по package name.
  static Future<bool> launchPackage(String package) async {
    try {
      return await _ch.invokeMethod('launch', {'package': package})
              as bool? ??
          false;
    } catch (_) {
      return false;
    }
  }

  /// Список запускаемых приложений (для дровера).
  static Future<List<AppEntry>> listApps() async {
    try {
      final list =
          await _ch.invokeListMethod<Map>('listApps', {'includeSystem': true});
      if (list == null) return const [];
      return list.map((m) => AppEntry.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Открывает URL: platformDefault даёт Chrome Custom Tabs, если доступно.
  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
        return;
      }
    } catch (_) {
      // попробуем форс-режим ниже
    }
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Совсем никак — тихо игнорируем: лаунчер не должен падать.
    }
  }
}
