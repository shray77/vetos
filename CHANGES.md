# CHANGES — VetOS v0.6.0

### Шрифтовая шкала textTheme DS + тосты и диалоги (Task 171)

- `lib/theme/ds.dart`: типографика переехала из ~118 per-widget стилей в
  Material-роли — `Ds.textTheme` по шкале `--ds-text-*` ядра
  (xs=11 / s=12.5 / m=14 / l=17 / xl=24), Prata-дисплей для «цифр
  приборов» (THI-52, статы карточек ленты — паттерн `.ds-stat__value`
  веба), трекинг-капс 1.4 для оверлайнов; `fontFamily` зашит в роли —
  ThemeData мержит семейство только в textTheme-параметр.
- Впервые тосты и диалоги в голосе DS: плоские панели surface2 на
  волоске границы, без теней (`snackBarTheme` / `dialogTheme`, хелпер
  `Ds.snack` с safe-area). Фейл запуска установленного APK больше не
  молчит — тост «не открылся — пробуем веб-версию» (дом + дровер).
  Диалог «сделать домашним экраном» в настройках.
- Инпуты — глобальная форма DS (`inputDecorationTheme`: заливка
  surface, без рамки в покое).
- README: честное имя ассета релиза (`VetOS-0.6.0-arm64-v8a.apk`) и
  размер по факту сборки (~21 МБ).
- QA: analyze 0, тесты 9/9, контраст AA 4.69–12.9 (PIL-замер),
  VLM-арт-директ 2 прогона. Версия: 0.6.0+9.

### Golden-сьюта и ds-gate v2 (Task 176)

- `scripts/ds_gate.py` v2: гейт ПАРИТ `lib/theme/ds.dart` против
  `design/tokens.json` (срез ядра, обновлён до v2.4). Поймал живой дрейф
  border-strong (#353B44 v2.3.2 ≠ #6A7590) — рамки были 1.38–1.60:1
  (§1.4.11), синхронизирован. CI `build.yml`: ds-gate job до Flutter.
- `test/golden_screens_test.dart` — 6 golden-кадров (дом, compact
  320×568, проекты, настройки, дровер, edge-to-edge статус-бар).
  Детерминизм: сеть отключается HttpOverrides с «мёртвым» клиентом
  (живые ответы GitHub прилетали в fake-зону — диффы 0.16–0.46%);
  часы фиксированы `clock.fixed` (кадр зависел от минуты прогона).
  Гейт поймал реальный баг: `LaunchService.listApps()` при сбое канала
  возвращал `const []` — немодифицируемый, `DrawerScreen._load` делал
  `sort()` → UnsupportedError; фиксирован выращиваемым списком.
- CI: пин flutter 3.47.8 (golden-база привязана к движку) +
  `precache --universal` до тестов (шрифты портабельны: FLUTTER_ROOT,
  не жёсткий /home/z-путь — у раннера его нет, текст рендерился тофу).
- `clock` переведён в прямые зависимости (строгий analyze),
  канонический `clock.now()`. Тесты: 15/15 (9 юнит + 6 golden).

### Гигиена (Task 179)

- `minSdk = 24` запинен явно (flutter.minSdkVersion плавает со сменой
  SDK): Android 4/5/6 получает вежливый отказ установки от всех трёх
  приложений экосистемы, а не краш-обзор.

### Фикс-волна аудита (Task 183)

- **Живой метео-тайл:** домашний экран подписан на сервисы данных —
  `ListenableBuilder(Listenable.merge([_meteo, _feeds]))`. До этого
  `notifyListeners()` падал в пустоту: срезы обновлялись (таймер
  10–60 мин, возврат с resumed), но экран не перестраивался — только
  побочным setState. ПОБОЧНАЯ НАХОДКА: старая golden-база 01/02/06
  запекла устаревший кадр «…» со спиннером — в тестах MethodChannel
  висит, setState из _checkInstalled не приходил, и экран не
  перестраивался после settle сервисов. База перегенерирована: кадры
  показывают честное офлайн-состояние («—», «метео недоступно»,
  «повтор») — как и заявлял комментарий теста.
- **README «Скачать»:** ссылка ведёт на `releases/tag/latest`
  (rolling-релиз). `releases/latest` отдаёт сентябрьский v0.3.0 —
  GitHub исключает prerelease из «последнего стабильного».
- **Каталог 16 → 18 проектов:** +ФЭКРТ (Мониторинг) и +ВетПетри
  (Лаборатория) — живые витрины экосистемы, до этого недостижимые из
  лаунчера. Счётчики README/настроек/pubspec синхронизированы.
- **Сплэш:** фон запуска — графит «Прибора» #14161A
  (`values/colors.xml` + оба `launch_background.xml`) вместо белого:
  тёмное приложение не вспыхивает на холодном старте.
- CHANGES.md: восстановлена эта запись v0.6.0 (до этого верхняя
  запись была v0.5.0, релизные ноты CI ссылались на пустоту).

---

# CHANGES — VetOS v0.5.0

### Дизайн-система vet-ds v2.3 в Material-слое: голос C «Прибор»

Вет-экосистема переезжает на vet-ds v2.3 (Task 164–165 в vet-worklog),
VetOS — её Android-поверхность. Хвост Task 164 («Material-слой, кандидаты —
аналоги платформенных фич») закрыт.

- `lib/theme/ds.dart` (новый): токены DS голоса C «Прибор» — графит
  (#14161A фон, #1A1D22/#20242B поверхности) + приборная бирюза #35C29A,
  семантика статусов (red/green/amber/orange/blue, тёмные значения DS —
  все AA-проверены contrast_v2.py), радиусы 4/8 (бан-лист DS: radius > 10px),
  движение 160 мс на кривой cubic-bezier(.2,0,0,1). Выбор темы: VetOS —
  приборный хаб (метео, лента, дашборды), C — голос ДС для них.
- `main.dart`: ThemeData строится из Ds.theme() — ColorScheme поверх M3 dark
  с DS-полями, прогресс-индикаторы и иконки акцентные.
- **Эмодзи в UI запрещены (правило DS)** — все 16 иконок проектов
  (плитки, каталог, лента) переведены с эмодзи на монохромные Material-глифы
  с тинтом категориального цвета проекта (cow → thermostat, map, biotech,
  school, mic, psychology, coronavirus, air, campaign, calculate, hub,
  newspaper, headphones, rss_feed, science, flight).
- THI/CCI-статусы метео — на DS-семантику (единая шкала с веб-радарами);
  пороги спарклайна 68/72 — amber/orange DS.
- **Аналог платформенной View Transition (блок 26 DS)**: `DsRoute` —
  кроссфейд 160 мс + зум 0.98→1.0 на кривой DS, системные
  «отключённые анимации» (prefers-reduced-motion) → мгновенная смена.
  Все 4 навигации (настройки/каталог/дровер/браузер) переведены.
- **Аналог прогресса чтения (блок 28 DS)**: полоса загрузки браузера плиток
  и все спиннеры — акцент DS через progressIndicatorTheme.
- Часы домашнего экрана — **Prata** (дисплейная кириллица DS, 99 КБ,
  бандлится — офлайн-фёрст): цифры «мастхеда» с засечками; дата —
  оверлайн-стиль DS (моно-регистр, трекинг, акцент).
- Радиусы ужаты до DS: карточки/плитки/шиты 24→8, инпуты/чипы 16→8 —
  «периодика», без пузырей Material You.
- Акценты карточек ленты берутся из реестра kProjects (единый источник),
  а не дублированными литералами; метео-плитка = акцент DS.
- Кнопки домашнего: «ВСЕ ПРОЕКТЫ» — акцент (экосистема), «ВСЕ ПРИЛОЖЕНИЯ» —
  нейтральный бордюр (система): иерархия вместо двух разных кричащих цветов.
- Хардкод-зачистка: ~80 литералов (0xFF0B0F14/0xFF111827/grey.shadeX/
  Colors.white/teal) → Ds.bg/surface/surface2/muted/faint/text/accent
  по всем 11 файлам lib/.

**QA:** flutter analyze 0 issues (строгий режим, как в CI); flutter test
9/9; golden-рендер 4 экранов (393×852@2x, настоящие Roboto/MaterialIcons/
Prata): фон/поверхности/акцент совпали с токенами до пикселя, кириллица
Prata в часах, дата целиком, тофу нет, наложений нет; VLM-арт-директ —
settings/шит станции ок; тинты иконок проектов помечены «не монохром» —
трактовка промпта: глифы одноцветные, цвет = категориальный код проекта
(DS-исключение для датавиза), эмодзи не осталось.

# CHANGES — VetOS v0.4.1

### Release-подпись APK: апдейты встают поверх

- Раньше rolling-релизы были подписаны **debug-ключом** (Flutter-фолбэк
  при отсутствии signingConfig), поэтому каждый новый APK требовал
  ручного удаления старой версии: Android не ставит апдейт поверх APK
  с другой подписью.
- Новый RSA-4096 release-keystore (срок 30 лет) хранится в GitHub
  Actions-секретах репы (`KEYSTORE_BASE64` / `KEYSTORE_PASSWORD` /
  `KEY_ALIAS` / `KEY_PASSWORD`) и никогда не попадает в git
  (`.gitignore` защищает от случайного коммита).
- `build.gradle.kts`: `signingConfigs.release` читает env `KEYSTORE_*`;
  локальные сборки без env прозрачно используют debug-ключ, как раньше.
- `build.yml`: шаг «Decode release keystore» перед сборкой + env к
  шагу сборки; чистка deprecated `set-output`.
- ⚠ Разово: **v0.4.1 ставится с удалением** старой версии (смена
  подписи debug → release). Все следующие апдейты встанут поверх.

# CHANGES — VetOS v0.4.0

### Внедрение новых проектов: каталог 16 плиток + 2 новых фида ленты

- `lib/models/project.dart`: реестр 6 → **16 проектов**. Новый enum
  `ProjectCategory` (Мониторинг / Инструменты / Данные / Лаборатория) и
  поля `category` + `home` у проекта. На домашнем экране остаются 6
  плиток ядра (`home: true`) — лаунчер не превращается в бесконечную
  сетку; остальная экосистема живёт в каталоге. Добавлены: BioThreat
  Watch, VetFlu Forecast, VetRecall, VetTools, ВетХаб, Вет-Дайджест,
  Аудио-дайджест, RSS-конвейер, Вет-Пилоты, VetFlu · витрина.
- `lib/screens/projects_screen.dart` (новый): каталог «Все проекты» —
  поиск по названию/подписи/разделу, чипы разделов со счётчиками,
  список с иконками-кружками, бейджем раздела и меткой «на экране»
  у ядра; APK-проекты показывают статус установки. Открытие проектов —
  та же логика, что у плиток (APK по пакету → фолбэк на веб).
- `lib/screens/home_screen.dart`: сетка рисует только ядро
  (`kProjects.where(home)`); под ней кнопка «ВСЕ ПРОЕКТЫ · 16»
  (фиолетовый акцент) → каталог. Тумблеры новых фидов в init/reload.
- Новые фиды живой ленты (конвенция docs/vetos-feeds.md, git = бекенд):
  - **«Аномалия · TSPulse»** — `vet-pilots/tspulse/latest.json`
    (1.5 КБ): вердикт недели, max score / перцентиль, топ-3 болезни,
    окно недели. Цвет карточки = сила сигнала: дни выше порога —
    красный, перцентиль ≥ 80 — янтарный, иначе зелёный. Тап — Вет-Пилоты.
  - **«Дайджест · LLM»** — `vet-digest-llm/data/llm_digest.json`
    (2.8 КБ): headline недели, события, «источники 18/22». Тап — сайт
    дайджеста (полный текст + аудио-версия Piper).
  - Оба фида по умолчанию включены, отключаются в настройках; кэш в
    SharedPreferences, толерантный парс (пустой срез = «—», не падение).
- `lib/widgets/feed_cards.dart`: TspulseCard + DigestCard в общем
  FeedShell; `lib/models/feeds.dart`: TspulseSlice + DigestSlice;
  `lib/services/feed_service.dart`: +2 URL, кэш-ключи, честный
  «сколько фидов не ответило» (6).
- Тесты: +4 (парсинг TSPulse/Digest и деградация пустых срезов).

---

# CHANGES — VetOS v0.3.2 (история)

### CCI в метео-тайле и листе станций

- `lib/models/meteo.dart`: в `MeteoStation` и `ForecastStation` добавлено
  поле `cci` (Comprehensive Climate Index, Mader 2010 err. 2011, °C) —
  парсится из среза `vet-meteo`/`vet-api` (ключ `cci`); новый класс
  `CciStatus` с зонами OK Mesonet 2016: -10..30 комфорт, >=30 жара,
  >=40 экстрим жары, <=-10 холод, <=-30 экстрим холода.
- `lib/widgets/meteo_card.dart`: пятая метрика в ряду — `CCI` со
  текстовой зоной (например «CCI · комфорт»); THI остаётся главным
  числом тайла и спарклайна.
- `lib/widgets/station_sheet.dart`: в списке станций к THI добавлен
  CCI-чип («THI 67.9 · CCI +19°»).
- Обратная совместимость: старые кэшированные срезы без `cci`
  показывают «—», ничего не падает.

---

# CHANGES — VetOS v0.3.1 (история)

Целевое устройство для оптимизации: **Oppo A18 (CPH2591)**
- SoC: MediaTek Helio G35 (8× Cortex-A53 @2.3 ГГц, 12 нм)
- ОЗУ: 4 ГБ (доступно ~2 ГБ под приложениями)
- Экран: 6.56″ HD+ (720×1612), ~270 ppi
- Android: 13 (ColorOS)

## Список изменений

### 1. VetLearn → новый URL

**`lib/models/project.dart`**

Заменён URL плитки VetLearn AI:
- было: `https://gitlab.com/shray77/vetlearn-web` с принудительным
  открытием в Chrome (`TileBrowser.chrome`)
- стало: `https://t1h1h8e10p40-d.space-z.ai/` с дефолтным режимом
  (`TileBrowser.auto`).

Теперь VetLearn открывается так же, как остальные веб-плитки — во
встроенном браузере VetOS без тулбара Chrome. Кнопка «в Chrome»
остаётся в шапке браузера на случай, если понадобится OAuth/куки.

### 2. Оптимизация под Oppo A18 / Helio G35 / 4 ГБ ОЗУ

#### 2.1. `lib/widgets/clock_widget.dart` (новый файл)
- Часы вынесены в отдельный `StatefulWidget` с собственным таймером 1с.
- `setState` вызывается только при смене минуты — было 60 раз/мин,
  стало 1 раз/мин. Это значит, что `HomeScreen.build()` больше НЕ
  пересобирается каждую секунду (а вместе с ним — `MeteoCard` с
  `CustomPaint` спарклайна, 6 `ProjectTile`, лента `feed_cards`).

#### 2.2. `lib/services/meteo_service.dart`
- Общий `http.Client` с keep-alive и connection-poolом: каждый запрос
  переиспользует TCP/TLS-соединение к `raw.githubusercontent.com`
  (экономия ~150 мс на handshake).
- Таймаут 15 с вместо 25 с: при плохой сети лаунчер быстрее
  откатывается к кэшированному срезу.
- Убран `Cache-Control: no-cache` — CDN raw.githubusercontent обновляется
  раз в ~5 мин, обходить кэш нет смысла, зато экономим батарею и трафик.
- **Persist среза в SharedPreferences**: на холодном старте метео
  сразу рисуется из кэша, фоновый рефреш поднимает свежие данные без
  UI-блокировки. Ключи: `vetos.cache.meteo.latest`, `vetos.cache.meteo.forecast`.

#### 2.3. `lib/services/feed_service.dart`
- Аналогично MeteoService: общий `http.Client`, таймаут 12 с, без
  `Cache-Control: no-cache`.
- Persist всех четырёх фидов в SharedPreferences (outlook, outbreaks,
  verify, weekly).

#### 2.4. `lib/models/meteo.dart`
- Добавлены `toJson()` методы в `MeteoStation`, `MeteoSlice`,
  `ForecastStation`, `Forecast` — для persist-кэша.

#### 2.5. `lib/screens/browser_screen.dart`
- Мобильный UA (Oppo A18 / CPH2591): серверы отдают лёгкие мобильные
  версии страниц вместо десктопных.
- `setOnConsoleMessage` заглушен — не пишем лог консоли страницы в
  Flutter-консоль (экономия CPU на Helio G35).

#### 2.6. `android/app/src/main/kotlin/ru/shray77/vetos/MainActivity.kt`
- PNG → **WebP lossy q=80** для иконок дровера: размер ~2-4 КБ вместо
  ~6-10 КБ (для ~200 приложений экономия ~1 МБ в кэше + faster decode).
  Используется `Bitmap.CompressFormat.WEBP_LOSSY` на API≥30,
  fallback на deprecated `WEBP` для старых.
- `ConcurrentHashMap` → `LinkedHashMap` с LRU-семантикой, лимит 96
  записей (`MAX_CACHE_ENTRIES`): на телефонах с 200+ приложениями не
  держим все иконки в памяти. Доступ синхронизирован через
  `iconCacheLock`.

#### 2.7. `android/app/src/main/AndroidManifest.xml`
- `android:largeHeap="true"` — лаунчер с WebView + иконками дровера
  на 4 ГБ ОЗУ регулярно ловил `OutOfMemoryError`. largeHeap даёт
  Android'у право поднять heap-лимит до 512 МБ (вместо 192 МБ).
- Явный `android:hardwareAccelerated="true"` для документации.

#### 2.8. `android/app/build.gradle.kts`
- `splits.abi` включён: только `arm64-v8a` + `armeabi-v7a` (Oppo A18 и
  все современные ARM-смартфоны). `x86_64` выпилен — лаунчер не нужен
  на эмуляторах в проде.
- `abiFilters` в `defaultConfig` — Flutter-плагин тоже соблюдает.
- Универсальный APK теперь не собирается (`isUniversalApk = false`) —
  для sideload это лишнее, split-per-ABI даёт ~25 МБ на arm64-v8a
  вместо ~62 МБ универсального.

#### 2.9. `lib/main.dart`
- `PaintingBinding.instance.imageCache.maximumSize = 30` (вместо 1000).
- `PaintingBinding.instance.imageCache.maximumSizeBytes = 30 << 20`
  (30 МБ вместо 100 МБ по умолчанию).
- Срезы ленты + 6 плиток проектов — это ~15 картинок максимум, 30 МБ
  за глаза. На Helio G35 это радикально снижает давление на GC.

### 3. Версия

- `pubspec.yaml`: `0.3.0+3` → `0.3.1+4`.
- `README.md`: обновлены упоминания версии, ссылка VetLearn, секция
  «Как собрать» под splits-per-ABI.

## Что НЕ менялось

- Архитектура лаунчера (домашний экран, дровер, настройки).
- Реестр проектов `kProjects` — кроме строки VetLearn.
- Источники данных метео и ленты — те же git-срезы.
- Подпись релиза — осталась debug-подпись (для sideload).
- MethodChannel `vetos/apps` — API не менялось, только реализация
  `iconFor` и формата иконок (PNG → WebP, дровер и Flutter-сторона
  прозрачны к формату: `Image.memory(bytes)` декодит и WebP, и PNG).
