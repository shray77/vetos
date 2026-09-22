# CHANGES — VetOS v0.3.1

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
