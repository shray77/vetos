import 'package:shared_preferences/shared_preferences.dart';

/// Настройки VetOS (хранятся локально): станция метрики, интервал обновления,
/// браузер веб-плиток, карточки живой ленты.
class PrefsService {
  static const _kStation = 'vetos.station';
  static const _kInterval = 'vetos.interval_min';
  static const _kBuiltinBrowser = 'vetos.browser.builtin';
  static const _kFeedPrefix = 'vetos.feed.';

  /// id станции для метео-тайла (по умолчанию — Ростов-на-Дону).
  static Future<String> stationId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kStation) ?? 'rostov';
  }

  static Future<void> setStationId(String id) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kStation, id);
  }

  /// Интервал автообновления метео, минуты (по умолчанию 20 — как срез CI).
  static Future<int> intervalMin() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kInterval) ?? 20;
  }

  static Future<void> setIntervalMin(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kInterval, v);
  }

  /// Веб-плитки: true — встроенный браузер (без полосы Chrome), false — Custom Tabs.
  static Future<bool> builtinBrowser() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kBuiltinBrowser) ?? true;
  }

  static Future<void> setBuiltinBrowser(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kBuiltinBrowser, v);
  }

  /// Видимость карточек живой ленты (id: outlook / outbreaks / verify / weekly).
  /// Outlook включён всегда по умолчанию, вспышки и верификация — тоже;
  /// недельный дайджест по умолчанию выключен (пока покрытие архива тонкое).
  static Future<bool> feedEnabled(String id) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool('$_kFeedPrefix$id') ?? _feedDefault(id);
  }

  static bool _feedDefault(String id) => id == 'weekly' ? false : true;

  static Future<void> setFeedEnabled(String id, bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('$_kFeedPrefix$id', v);
  }
}
