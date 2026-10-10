import 'package:flutter/material.dart';

import '../services/launch_service.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.home_outlined,
                        color: Color(0xFF2DD4A7)),
                  ),
                  Expanded(
                    child: Text(
                      'ПРИЛОЖЕНИЯ · ${apps.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        letterSpacing: 1.5,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _showSystem = !_showSystem),
                    child: Text(
                      _showSystem ? 'без системных' : 'с системными',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'поиск…',
                  hintStyle: TextStyle(color: Colors.grey.shade600),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  filled: true,
                  fillColor: const Color(0xFF111827),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
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
                                  borderRadius: BorderRadius.circular(12),
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
                                  backgroundColor: const Color(0xFF1F2937),
                                  child: Text(
                                    a.name.isEmpty
                                        ? '?'
                                        : a.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                        color: Color(0xFF2DD4A7)),
                                  ),
                                ),
                          title: Text(
                            a.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            a.packageName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600),
                          ),
                          onTap: () =>
                              LaunchService.launchPackage(a.packageName),
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
