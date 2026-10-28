import 'package:flutter/material.dart';

import '../theme/ds.dart';

/// Тип проекта экосистемы VetOS.
enum ProjectKind { web, app }

/// Как открывать веб-часть проекта (плитки без «полосы Chrome»).
enum TileBrowser {
  /// Следовать настройке «Браузер плиток» (по умолчанию — встроенный).
  auto,

  /// Всегда встроенный WebView-браузер VetOS: без тулбара, свой минимальный хром.
  builtin,

  /// Всегда Chrome Custom Tabs: логины/куки Chrome (GitLab и т.п.).
  chrome,
}

/// Раздел каталога «Все проекты» (экран каталога с поиском).
enum ProjectCategory {
  monitor('Мониторинг'),
  tools('Инструменты'),
  data('Данные'),
  lab('Лаборатория');

  final String label;
  const ProjectCategory(this.label);
}

/// Один проект экосистемы: плитка на домашнем экране VetOS.
class Project {
  final String id;
  final String title;
  final String subtitle;
  /// Иконка плитки — Material-глиф монохромом (правило DS: эмодзи в UI запрещены).
  final IconData icon;
  final Color color;
  final ProjectKind kind;
  /// Веб-адрес (GitHub Pages / репозиторий) — открывается браузером/Custom Tabs.
  final String url;
  /// applicationId, если проект — Android-приложение.
  final String? package;

  /// Какой браузер использовать для веб-части этой плитки.
  final TileBrowser browser;

  /// Раздел каталога «Все проекты».
  final ProjectCategory category;

  /// Ядро экосистемы — показывается плиткой на домашнем экране;
  /// остальные проекты живут в каталоге «Все проекты» (v0.4.0).
  final bool home;

  const Project({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.kind,
    required this.url,
    this.package,
    this.browser = TileBrowser.auto,
    this.category = ProjectCategory.tools,
    this.home = false,
  });
}

/// Реестр проектов вет-экосистемы shray77 (v0.4.0: 16 проектов, Task 183: +ФЭКРТ
/// и ВетПетри — 18).
///
/// Первые шесть — ядро (home: true): их плитки стоят на домашнем экране.
/// Остальные открываются из каталога «Все проекты» — там поиск и разделы.
/// Ссылки/пакеты меняются в одном месте — здесь.
const kProjects = <Project>[
  // ─── Ядро экосистемы (домашний экран) ───────────────────────────────
  Project(
    id: 'meteo',
    title: 'Метео-Радар',
    subtitle: 'THI · 49 станций Ростовской обл.',
    icon: Icons.thermostat,
    color: Ds.accent,
    kind: ProjectKind.web,
    url: 'https://shray77.github.io/vet-meteo/',
    category: ProjectCategory.monitor,
    home: true,
  ),
  Project(
    id: 'heatmap',
    title: 'ВетКарта',
    subtitle: 'Эпизоотическая обстановка · вспышки',
    icon: Icons.map,
    color: Color(0xFFF59E0B),
    kind: ProjectKind.web,
    url: 'https://shray77.github.io/vet-heatmap/',
    category: ProjectCategory.monitor,
    home: true,
  ),
  Project(
    id: 'insilico',
    title: 'VetInSilico',
    subtitle: '17 браузерных in-silico инструментов',
    icon: Icons.biotech,
    color: Color(0xFF818CF8),
    kind: ProjectKind.web,
    url: 'https://shray77.github.io/vet-insilico/',
    category: ProjectCategory.tools,
    home: true,
  ),
  Project(
    id: 'learn',
    title: 'VetLearn AI',
    subtitle: 'LMS · AI-репетитор · треки',
    icon: Icons.school,
    color: Color(0xFF38BDF8),
    kind: ProjectKind.web,
    // Стабильное зеркало на GitHub Pages (офлайн-версия с резервным
    // контентом) — прежний URL space-z.ai был эфемерным превью-инстансом
    // и мог исчезнуть; GitLab-оригинал требует логинов, для плитки
    // не нужен. Полная версия — по ссылке «Код» из каталога.
    url: 'https://shray77.github.io/vetlearn-web/',
    browser: TileBrowser.auto,
    category: ProjectCategory.tools,
    home: true,
  ),
  Project(
    id: 'voice',
    title: 'VetVoice',
    subtitle: 'Дозировки голосом · vosk + gigaam',
    icon: Icons.mic,
    color: Color(0xFFEF4444),
    kind: ProjectKind.app,
    url: 'https://github.com/shray77/vetvoice',
    package: 'com.vetvoice.vetvoice',
    category: ProjectCategory.tools,
    home: true,
  ),
  Project(
    id: 'eco',
    title: 'VetEco',
    subtitle: 'Диктовка → медкарта · AI-RAG',
    icon: Icons.psychology,
    color: Color(0xFFF472B6),
    kind: ProjectKind.app,
    url: 'https://github.com/shray77/vetvoice-rag',
    package: 'com.veteco.app',
    category: ProjectCategory.tools,
    home: true,
  ),

  // ─── Мониторинг ─────────────────────────────────────────────────────
  Project(
    id: 'biothreat',
    title: 'BioThreat Watch',
    subtitle: 'Мировые сигналы биоугроз · ИИ-вердикты',
    icon: Icons.coronavirus,
    color: Color(0xFFA78BFA),
    kind: ProjectKind.web,
    url: 'https://shray77.github.io/biothreat-site/',
    category: ProjectCategory.monitor,
  ),
  Project(
    id: 'vetflu-fc',
    title: 'VetFlu Forecast',
    subtitle: 'Риск гриппа по флайвеям · R-индекс',
    icon: Icons.air,
    color: Color(0xFF34D399),
    kind: ProjectKind.web,
    url: 'https://shray77.github.io/vetflu-forecast/',
    category: ProjectCategory.monitor,
  ),
  Project(
    id: 'vetrecall',
    title: 'VetRecall',
    subtitle: 'Отзывы препаратов и сигналы',
    icon: Icons.campaign,
    color: Color(0xFFFB923C),
    kind: ProjectKind.web,
    url: 'https://shray77.github.io/vetrecall-site/',
    category: ProjectCategory.monitor,
  ),
  Project(
    id: 'vetfecrt',
    title: 'ФЭКРТ',
    subtitle: 'Резистентность к антигельминтикам · WAAVP-2023',
    icon: Icons.grain,
    color: Color(0xFF6D4FC4),
    kind: ProjectKind.web,
    url: 'https://shray77.github.io/vetfecrt-site/',
    category: ProjectCategory.monitor,
  ),

  // ─── Инструменты ────────────────────────────────────────────────────
  Project(
    id: 'vettools',
    title: 'VetTools',
    subtitle: 'Клинические мини-калькуляторы',
    icon: Icons.calculate,
    color: Color(0xFFFBBF24),
    kind: ProjectKind.web,
    url: 'https://shray77.github.io/vettools/',
    category: ProjectCategory.tools,
  ),

  // ─── Данные ─────────────────────────────────────────────────────────
  Project(
    id: 'hub',
    title: 'ВетХаб',
    subtitle: 'Все дашборды в одном окне',
    icon: Icons.hub,
    color: Color(0xFF60A5FA),
    kind: ProjectKind.web,
    url: 'https://shray77.github.io/vet-hub/',
    category: ProjectCategory.data,
  ),
  Project(
    id: 'digest',
    title: 'Вет-Дайджест',
    subtitle: 'Сводка недели · сигналы и вспышки',
    icon: Icons.newspaper,
    color: Color(0xFF4ADE80),
    kind: ProjectKind.web,
    url: 'https://shray77.github.io/vetdigest-site/',
    category: ProjectCategory.data,
  ),
  Project(
    id: 'digest-audio',
    title: 'Аудио-дайджест',
    subtitle: 'Озвучка недели · Piper TTS',
    icon: Icons.headphones,
    color: Color(0xFF22D3EE),
    kind: ProjectKind.web,
    url: 'https://shray77.github.io/vet-digest-llm/',
    category: ProjectCategory.data,
  ),
  Project(
    id: 'rss',
    title: 'RSS-конвейер',
    subtitle: 'Источники → D1 → продукты',
    icon: Icons.rss_feed,
    color: Color(0xFF94A3B8),
    kind: ProjectKind.web,
    url: 'https://shray77.github.io/rss-core-site/',
    category: ProjectCategory.data,
  ),

  // ─── Лаборатория ────────────────────────────────────────────────────
  Project(
    id: 'pilots',
    title: 'Вет-Пилоты',
    subtitle: 'TSPulse · Piper · GigaAM',
    icon: Icons.science,
    color: Color(0xFFC084FC),
    kind: ProjectKind.web,
    url: 'https://github.com/shray77/vet-pilots',
    category: ProjectCategory.lab,
  ),
  Project(
    id: 'vetflu-site',
    title: 'VetFlu · витрина',
    subtitle: 'Сайт проекта · карта флайвеев',
    icon: Icons.flight,
    color: Color(0xFF5EEAD4),
    kind: ProjectKind.web,
    url: 'https://shray77.github.io/vetflu-site/',
    category: ProjectCategory.lab,
  ),
  Project(
    id: 'vetpetri',
    title: 'ВетПетри',
    subtitle: 'Научная песочница чашки Петри · микробиология',
    icon: Icons.adjust,
    color: Color(0xFFA3E635),
    kind: ProjectKind.web,
    url: 'https://shray77.github.io/vetpetri/',
    category: ProjectCategory.lab,
  ),
];
