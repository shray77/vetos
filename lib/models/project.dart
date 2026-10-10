import 'package:flutter/material.dart';

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

/// Один проект экосистемы: плитка на домашнем экране VetOS.
class Project {
  final String id;
  final String title;
  final String subtitle;
  /// Эмодзи как иконка плитки (без ассетов, отчётливо на тёмном фоне).
  final String icon;
  final Color color;
  final ProjectKind kind;
  /// Веб-адрес (GitHub Pages / репозиторий) — открывается браузером/Custom Tabs.
  final String url;
  /// applicationId, если проект — Android-приложение.
  final String? package;

  /// Какой браузер использовать для веб-части этой плитки.
  final TileBrowser browser;

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
  });
}

/// Реестр шести проектов экосистемы (вет-контур shray77).
const kProjects = <Project>[
  Project(
    id: 'meteo',
    title: 'Метео-Радар',
    subtitle: 'THI · 49 станций Ростовской обл.',
    icon: '🐄',
    color: Color(0xFF2DD4A7),
    kind: ProjectKind.web,
    url: 'https://shray77.github.io/vet-meteo/',
  ),
  Project(
    id: 'heatmap',
    title: 'ВетКарта',
    subtitle: 'Эпизоотическая обстановка · вспышки',
    icon: '🗺️',
    color: Color(0xFFF59E0B),
    kind: ProjectKind.web,
    url: 'https://shray77.github.io/vet-heatmap/',
  ),
  Project(
    id: 'insilico',
    title: 'VetInSilico',
    subtitle: '17 браузерных in-silico инструментов',
    icon: '🧬',
    color: Color(0xFF818CF8),
    kind: ProjectKind.web,
    url: 'https://shray77.github.io/vet-insilico/',
  ),
  Project(
    id: 'learn',
    title: 'VetLearn AI',
    subtitle: 'LMS · AI-репетитор · треки',
    icon: '🎓',
    color: Color(0xFF38BDF8),
    kind: ProjectKind.web,
    // VetLearn теперь хостится на space-z.ai — открывается как другие
    // веб-плитки: встроенный браузер по умолчанию (без Chrome-полосы).
    // Старый URL https://gitlab.com/shray77/vetlearn-web оставлен комментарием
    // на случай отката (если потребуются GitLab-логины/куки).
    url: 'https://t1h1h8e10p40-d.space-z.ai/',
    browser: TileBrowser.auto,
  ),
  Project(
    id: 'voice',
    title: 'VetVoice',
    subtitle: 'Дозировки голосом · vosk',
    icon: '🎙️',
    color: Color(0xFFEF4444),
    kind: ProjectKind.app,
    url: 'https://github.com/shray77/vetvoice',
    package: 'com.vetvoice.vetvoice',
  ),
  Project(
    id: 'eco',
    title: 'VetEco',
    subtitle: 'Диктовка → медкарта · AI-RAG',
    icon: '🧠',
    color: Color(0xFFF472B6),
    kind: ProjectKind.app,
    url: 'https://github.com/shray77/vetvoice-rag',
    package: 'com.veteco.app',
  ),
];
