import 'package:flutter/material.dart';

/// Перевод vet-ds v2.3 в Material-слой VetOS: голос C «Прибор» (тёмный).
///
/// Источник токенов — vet-ds/vet-ds.css, блок [data-theme="instrument"].
/// VetOS — приборный хаб экосистемы (метео, лента данных, дашборды),
/// поэтому из пяти тем DS выбрана C: графит + приборная бирюза.
///
/// Правила экосистемы (шапка vet-ds.css) действуют и здесь:
///  - эмодзи в UI запрещены — иконки Material, монохром с тинтом;
///  - текст >= AA (4.5:1) — значения DS проверены contrast_v2.py;
///  - радиусы сдержанные: 4 — кнопки/чипы/инпуты, 8 — карточки/панели
///    (радиус больше 10px — бан-лист DS);
///  - движение: 160 мс, кривая cubic-bezier(.2, 0, 0, 1);
///  - категориальные цвета проектов и датавиз DS не подчиняются.
abstract final class Ds {
  // -- Поверхности (графит) ------------------------------------------------
  static const Color bg = Color(0xFF14161A);
  static const Color surface = Color(0xFF1A1D22);
  static const Color surface2 = Color(0xFF20242B);
  static const Color border = Color(0xFF262A31);
  static const Color borderStrong = Color(0xFF353B44);
  static const Color rule = Color(0xFF5A6472);

  // -- Текст ---------------------------------------------------------------
  static const Color text = Color(0xFFE8EAED);
  static const Color muted = Color(0xFFAAB5C0);
  static const Color faint = Color(0xFF939EA9);

  // -- Семантика статусов (тёмные значения DS, единые по темам) -------------
  static const Color red = Color(0xFFE46655);
  static const Color green = Color(0xFF57B87B);
  static const Color amber = Color(0xFFE0A438);
  static const Color orange = Color(0xFFE08A4F);
  static const Color blue = Color(0xFF6FA8DC);
  static const Color blueSoft = Color(0xFF82A9CC);
  static const Color violet = Color(0xFFA78BFA);

  // -- Акцент: приборная бирюза ----------------------------------------------
  static const Color accent = Color(0xFF35C29A);
  static const Color accentStrong = Color(0xFF4AD4AC);
  static const Color accentInk = Color(0xFF0C1210);

  // -- Радиусы (периодика: сдержанные) --------------------------------------
  static const double radiusS = 4;
  static const double radius = 8;

  // -- Движение: 160 мс, cubic-bezier(.2, 0, 0, 1) ---------------------------
  static const Duration dur = Duration(milliseconds: 160);
  static const Curve ease = Curves.fastOutSlowIn;

  /// ThemeData VetOS: DS-токены поверх M3 dark.
  static ThemeData theme() => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme:
            ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark)
                .copyWith(
          primary: accent,
          onPrimary: accentInk,
          secondary: accentStrong,
          onSecondary: accentInk,
          tertiary: violet,
          error: red,
          outline: borderStrong,
          outlineVariant: border,
          surface: surface,
          onSurface: text,
          onSurfaceVariant: muted,
        ),
        scaffoldBackgroundColor: bg,
        fontFamily: 'Roboto',
        dividerTheme: const DividerThemeData(color: border, thickness: 1),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: accent,
          linearTrackColor: Colors.transparent,
        ),
        iconTheme: const IconThemeData(color: muted),
      );
}

/// Переход экрана — аналог платформенной View Transition DS (блок 26):
/// кроссфейд 160 мс с лёгким зумом 0.98 -> 1.0 на кривой DS.
/// Отключённые анимации системы (prefers-reduced-motion) -> мгновенно.
class DsRoute<T> extends PageRouteBuilder<T> {
  DsRoute({required WidgetBuilder builder})
      : super(
          pageBuilder: (context, _, _) => builder(context),
          transitionDuration: Ds.dur,
          reverseTransitionDuration: Ds.dur,
          transitionsBuilder: (context, animation, _, child) {
            if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
              return child;
            }
            final curved = CurvedAnimation(
              parent: animation,
              curve: Ds.ease,
              reverseCurve: Ds.ease.flipped,
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: _zoom.animate(curved),
                child: child,
              ),
            );
          },
        );

  static final Tween<double> _zoom = Tween<double>(begin: 0.98, end: 1.0);
}
