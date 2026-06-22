import 'package:shared_preferences/shared_preferences.dart';

/// Persists raw JSON API responses on the device using [SharedPreferences].
///
/// Each entry stores the raw response body plus a timestamp, so the repository
/// can serve stale data offline and tell the UI how old it is.
class CacheService {
  CacheService(this._prefs);

  final SharedPreferences _prefs;

  static const String _tsSuffix = '::ts';

  /// Saves [rawJson] under [key] and records the current time.
  /// Called after every successful API response so storage always mirrors the
  /// latest data we have seen.
  Future<void> write(String key, String rawJson) async {
    await _prefs.setString(key, rawJson);
    await _prefs.setInt(
      '$key$_tsSuffix',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Returns the raw JSON body previously stored under [key], or `null`.
  String? read(String key) => _prefs.getString(key);

  /// When the value under [key] was last written, or `null` if never.
  DateTime? timestamp(String key) {
    final ms = _prefs.getInt('$key$_tsSuffix');
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  bool has(String key) => _prefs.containsKey(key);
}
