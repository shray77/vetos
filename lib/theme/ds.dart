import 'package:flutter/material.dart';

/// Перевод vet-ds v2.3.4 в Material-слой VetOS: голос C «Прибор» (тёмный).
///
/// Источник токенов — vet-ds/vet-ds.css, блок [data-theme="instrument"].
///
/// v2.3.4 (Task 176): синхрон с ядром через scripts/ds_gate.py — гейт парсит
/// этот файл против design/tokens.json (срез ядра из vet-ds). Поймал и закрыл
/// дрейф border-strong v2.3.2 (рамки инпутов были 1.5–1.7:1 — §1.4.11).
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
///
/// Шрифтовая шкала (v0.6.0, Task 171) — Material textTheme поверх токенов
/// --ds-text-* из vet-ds.css: xs=11, s=12.5, m=14, l=17, xl=24.
/// Дисплей — Prata (serif-дисплей DS, «цифры приборов»), текст — Roboto.
/// Веб-моно оверлайнов заменён капсом с трекингом 1.4: ttf-моно в бандл
/// не везём (вес APK; прецедент Task 166 — трекинг-капс уже принят VLM-QA).
abstract final class Ds {
  // -- Поверхности (графит) ------------------------------------------------
  static const Color bg = Color(0xFF14161A);
  static const Color surface = Color(0xFF1A1D22);
  static const Color surface2 = Color(0xFF20242B);
  static const Color border = Color(0xFF262A31);
  static const Color borderStrong = Color(0xFF6A7590);
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
  // blueSoft — осознанный локальный алиас синего dark-темы (vet-ds.css:210):
  // в срезе instrument (design/tokens.json) этого ключа нет, ds_gate ключи
  // не сверяет (scripts/ds_gate.py смотрит только токены темы). Контраст
  // ~7.3:1 на графите — проверен аудитом 183, менять значение = golden-риск.
  // Кандидат: завести blue-soft в ядре DS v2.4.2 и синхронизировать срез.
  static const Color blueSoft = Color(0xFF82A9CC);
  static const Color violet = Color(0xFFA78BFA);

  // -- Акцент: приборная бирюза ----------------------------------------------
  static const Color accent = Color(0xFF35C29A);
  static const Color accentStrong = Color(0xFF4AD4AC);
  static const Color accentInk = Color(0xFF0C1210);

  // -- Семейства шкалы: текст Roboto, дисплей Prata (serif DS) --------------
  static const String sans = 'Roboto';
  static const String display = 'Prata';

  // -- Радиусы (периодика: сдержанные) --------------------------------------
  static const double radiusS = 4;
  static const double radius = 8;

  // -- Движение: 160 мс, cubic-bezier(.2, 0, 0, 1) ---------------------------
  static const Duration dur = Duration(milliseconds: 160);
  static const Curve ease = Curves.fastOutSlowIn;

  // -- Шрифтовая шкала DS (vet-ds.css --ds-text-*) ---------------------------
  static const double textXs = 11; // подписи, футеры карточек, оверлайны
  static const double textS = 12.5; // вторичные строки
  static const double textM = 14; // основной текст, инпуты, заголовки списков
  static const double textL = 17; // вердикты, тайлы, шапки экранов
  static const double textXl = 24; // большие секции

  /// TextTheme DS: шкала --ds-text-* + Prata-дисплей + Roboto-текст.
  ///
  /// Цвета заданы явно (не полагаемся на мерж colorScheme): faint/muted
  /// — вторичные роли по DS, остальные — ink. Трекинг-капс 1.4 — конвенция
  /// оверлайнов-«мастхедов»; шапки экранов (titleLarge) в этом приложении
  /// всегда капсом, поэтому трекинг зашит в роль.
  static TextTheme get textTheme => TextTheme(
        // Дисплей: Prata — «цифры приборов» (аналог .ds-stat__value serif).
        displayLarge: TextStyle(
            fontFamily: display,
            fontSize: 56,
            height: 1.05,
            letterSpacing: 1,
            color: text), // часы-мастхед
        displayMedium: TextStyle(
            fontFamily: display, fontSize: 52, height: 1.0, color: text), // THI
        displaySmall: TextStyle(
            fontFamily: display,
            fontSize: 34,
            height: 1.0,
            color: text), // статы карточек ленты
        // Заголовки: xl/l шкалы.
        headlineMedium: TextStyle(
            fontFamily: sans,
            fontSize: textXl,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: -0.3,
            color: text),
        headlineSmall: TextStyle(
            fontFamily: sans,
            fontSize: textL,
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.2,
            color: text), // вердикты, заголовки тайлов
        // Шапки экранов — капс-конвенция приложения, трекинг в роли.
        titleLarge: TextStyle(
            fontFamily: sans,
            fontSize: textL,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: text),
        titleMedium: TextStyle(
            fontFamily: sans,
            fontSize: textM,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: text), // заголовки списков/строк
        titleSmall: TextStyle(
            fontFamily: sans,
            fontSize: textS,
            fontWeight: FontWeight.w600,
            color: text), // акцентные значения строк
        // Текст.
        bodyLarge: TextStyle(
            fontFamily: sans,
            fontSize: textM, height: 1.35, color: text), // основной + инпуты
        bodyMedium: TextStyle(
            fontFamily: sans,
            fontSize: textS, height: 1.3, color: muted), // вторичные строки
        bodySmall: TextStyle(
            fontFamily: sans,
            fontSize: textXs, height: 1.35, color: faint), // подписи, футеры
        // Лейблы: кнопки/чипы/оверлайны.
        labelLarge: TextStyle(
            fontFamily: sans,
            fontSize: textM, fontWeight: FontWeight.w600, color: text),
        labelMedium: TextStyle(
            fontFamily: sans,
            fontSize: textS, fontWeight: FontWeight.w600, color: text),
        labelSmall: TextStyle(
            fontFamily: sans,
            fontSize: textXs,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
            color: muted), // оверлайны (капс)
      );

  /// Тост DS: графитовая карточка на волоске границы, без тени,
  /// действие — приборная бирюза. Одна строка из любого места UI.
  /// Отступ снизу — с учётом gesture-бара: флоатинг-снек сам safe area
  /// не уважает (VLM-ревью Task 171).
  static void snack(
    BuildContext context,
    String text, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(milliseconds: 3200),
          margin: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
          action: (actionLabel != null)
              ? SnackBarAction(
                  label: actionLabel,
                  onPressed: onAction ?? () {},
                )
              : null,
        ),
      );
  }

  /// Общие форма и рамка DS: панель на surface2 с волоском borderStrong.
  static RoundedRectangleBorder get panelShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: const BorderSide(color: borderStrong),
      );

  /// ThemeData VetOS: DS-токены поверх M3 dark.
  static ThemeData theme() => ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Roboto',
        textTheme: textTheme,
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
        dividerTheme: const DividerThemeData(color: border, thickness: 1),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: accent,
          linearTrackColor: Colors.transparent,
        ),
        iconTheme: const IconThemeData(color: muted),
        // Тосты (Task 171): плоская панель на surface2 + волосок границы —
        // «бумага на вечернем столе» не поднимает теней. Стили — от ролей
        // textTheme (иначе fontFamily не мержится и текст падает мимо Roboto).
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: surface2,
          elevation: 0,
          shape: panelShape,
          contentTextStyle: textTheme.bodyLarge,
          actionTextColor: accent,
        ),
        // Диалоги (Task 171): та же панель, текст — шкалой DS.
        dialogTheme: DialogThemeData(
          backgroundColor: surface2,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: panelShape,
          titleTextStyle: textTheme.headlineSmall!
              .copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
          contentTextStyle:
              textTheme.bodyLarge!.copyWith(color: muted, height: 1.4),
          actionsPadding:
              const EdgeInsets.fromLTRB(24, 6, 24, 16),
        ),
        // Инпуты (Task 171): форма DS — заливка surface, без рамки в покое.
        inputDecorationTheme: InputDecorationTheme(
          hintStyle: const TextStyle(color: faint),
          filled: true,
          fillColor: surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(radius),
            borderSide: BorderSide.none,
          ),
        ),
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
