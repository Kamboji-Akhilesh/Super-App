/// App-wide constants: API endpoints and cache keys.
///
/// The app talks directly to the free, key-less Frankfurter API
/// (https://www.frankfurter.app) — there is no custom backend.
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = 'https://api.frankfurter.app';

  static Uri latest({required String base}) =>
      Uri.parse('$baseUrl/latest?from=$base');

  static Uri currencies() => Uri.parse('$baseUrl/currencies');

  /// Historical time-series between [start] and [end] (yyyy-MM-dd) for a
  /// single [base] -> [quote] pair.
  static Uri timeSeries({
    required String start,
    required String end,
    required String base,
    required String quote,
  }) =>
      Uri.parse('$baseUrl/$start..$end?from=$base&to=$quote');

  /// How long a network request may run before we fall back to cache.
  static const Duration networkTimeout = Duration(seconds: 12);
}

/// Keys used to persist API responses in device storage.
class CacheKeys {
  CacheKeys._();

  static const String currencyNames = 'cache.currency_names';

  static String latestRates(String base) => 'cache.latest.$base';

  static String timeSeries(String base, String quote, int days) =>
      'cache.series.$base.$quote.$days';
}
