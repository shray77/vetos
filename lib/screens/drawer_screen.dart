import 'package:flutter/material.dart';

import '../services/launch_service.dart';
import '../theme/ds.dart';

/// Дровер всех установленных приложений с поиском.
class DrawerScreen extends StatefulWidget {
  const DrawerScreen({super.key});

  @override
  State<DrawerScreen> createState() => _DrawerScreenState();
}

class _DrawerScreenState extends State<DrawerScreen> {
  List<AppEntry>? _apps;
  String _query = '';
  bool _showSystem = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final apps = await LaunchService.listApps();
    apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (mounted) setState(() => _apps = apps);
  }

  /// Запуск с честным тостом DS при фейле: раньше тишина, теперь прибор
  /// говорит, что не получилось.
  Future<void> _launch(String package) async {
    final ok = await LaunchService.launchPackage(package);
    if (!ok && mounted) {
      Ds.snack(context, 'не удалось открыть приложение ($package)');
    }
  }

  List<AppEntry> get _filtered {
    final apps = _apps;
    if (apps == null) return [];
    final q = _query.trim().toLowerCase();
    return apps.where((a) {
      if (!_showSystem && a.system) return false;
      if (q.isEmpty) return true;
      return a.name.toLowerCase().contains(q) ||
          a.packageName.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final apps = _filtered;
    final ts = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Ds.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.home_outlined, color: Ds.accent),
                  ),
                  Expanded(
                    child: Text(
                      'ПРИЛОЖЕНИЯ · ${apps.length}',
                      style:
                          ts.labelLarge!.copyWith(letterSpacing: 1.4),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _showSystem = !_showSystem),
                    child: Text(
                      _showSystem ? 'без системных' : 'с системными',
                      style: ts.labelMedium,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'поиск…',
                  prefixIcon: Icon(Icons.search, color: Ds.faint),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Expanded(
              child: _apps == null
                  ? const Center(
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                      itemCount: apps.length,
                      itemBuilder: (_, i) {
                        final a = apps[i];
                        final icon = a.icon;
                        return ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          leading: (icon != null && icon.isNotEmpty)
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(Ds.radius),
                                  child: Image.memory(
                                    icon,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Ds.surface2,
                                  child: Text(
                                    a.name.isEmpty
                                        ? '?'
                                        // characters.first — не substring(0, 1):
                                        // имя, начинающееся с эмодзи/суррогатной
                                        // пары, не даст битый глиф в кружке.
                                        // (Расширение реэкспортируется
                                        // Flutter'ом через material.dart —
                                        // отдельный импорт package:characters
                                        // не нужен.)
                                        : a.name.characters.first.toUpperCase(),
                                    style: ts.labelLarge!
                                        .copyWith(color: Ds.accent),
                                  ),
                                ),
                          title: Text(
                            a.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ts.titleMedium,
                          ),
                          subtitle: Text(
                            a.packageName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ts.bodySmall,
                          ),
                          onTap: () => _launch(a.packageName),
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
