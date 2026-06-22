import 'dart:convert';

import 'package:intl/intl.dart';

import '../../core/cached.dart';
import '../../core/constants.dart';
import '../../core/exceptions.dart';
import '../../core/services/api_client.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/connectivity_service.dart';
import 'models/conversion_result.dart';
import 'models/currency.dart';
import 'models/latest_rates.dart';
import 'models/rate_point.dart';

/// Offline-first data source for currency data.
///
/// Strategy for every request:
///   1. If online, fetch from the network, **persist the raw response**, and
///      return fresh data.
///   2. If offline (or the request fails), return the last saved copy from
///      device storage, flagged as stale.
///   3. If there is neither connectivity nor a cached copy, throw
///      [CacheMissException].
class CurrencyRepository {
  CurrencyRepository({
    required ApiClient api,
    required CacheService cache,
    required ConnectivityService connectivity,
  })  : _api = api,
        _cache = cache,
        _connectivity = connectivity;

  final ApiClient _api;
  final CacheService _cache;
  final ConnectivityService _connectivity;

  static final DateFormat _ymd = DateFormat('yyyy-MM-dd');

  /// Currency code -> display name (e.g. `USD` -> `United States Dollar`).
  Future<Cached<Map<String, String>>> getCurrencyNames() {
    return _fetch(
      cacheKey: CacheKeys.currencyNames,
      uri: ApiConfig.currencies(),
      parse: (decoded) => (decoded as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as String)),
    );
  }

  /// Latest rates for the given [base] currency.
  Future<Cached<LatestRates>> getLatestRates({required String base}) {
    return _fetch(
      cacheKey: CacheKeys.latestRates(base),
      uri: ApiConfig.latest(base: base),
      parse: (decoded) =>
          LatestRates.fromJson(decoded as Map<String, dynamic>),
    );
  }

  /// Combined list of currencies with their rate relative to [base], sorted by
  /// name. Merges the rates and the human-readable names; staleness is `true`
  /// if either source was served from cache.
  Future<Cached<List<Currency>>> getRatesWithNames({
    required String base,
  }) async {
    final rates = await getLatestRates(base: base);
    final names = await getCurrencyNames();

    final list = rates.data.rates.entries
        .map((e) => Currency(
              symbol: e.key,
              name: names.data[e.key] ?? e.key,
              rate: e.value,
            ))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return Cached(
      data: list,
      fetchedAt: rates.fetchedAt,
      isStale: rates.isStale || names.isStale,
    );
  }

  /// Converts [amount] of [from] into [to] using the latest available rate.
  Future<Cached<ConversionResult>> convert({
    required String from,
    required String to,
    required double amount,
  }) async {
    final latest = await getLatestRates(base: from);
    final rate = latest.data.rateFor(to);
    if (rate == null) {
      throw ApiException('Conversion $from → $to is not supported.');
    }
    return latest.map(
      (data) => ConversionResult(
        from: from,
        to: to,
        amount: amount,
        rate: rate,
        date: data.date,
      ),
    );
  }

  /// Historical [base] -> [quote] rates for the last [days] days.
  Future<Cached<List<RatePoint>>> getTimeSeries({
    required String base,
    required String quote,
    required int days,
  }) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    return _fetch(
      cacheKey: CacheKeys.timeSeries(base, quote, days),
      uri: ApiConfig.timeSeries(
        start: _ymd.format(start),
        end: _ymd.format(now),
        base: base,
        quote: quote,
      ),
      parse: (decoded) {
        final rates = (decoded as Map<String, dynamic>)['rates']
                as Map<String, dynamic>? ??
            const {};
        final points = rates.entries
            .map((e) => RatePoint(
                  date: DateTime.parse(e.key),
                  rate: ((e.value as Map<String, dynamic>)[quote] as num)
                      .toDouble(),
                ))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        return points;
      },
    );
  }

  // ---------------------------------------------------------------------------

  /// Core offline-first routine shared by every endpoint.
  Future<Cached<T>> _fetch<T>({
    required String cacheKey,
    required Uri uri,
    required T Function(dynamic decoded) parse,
  }) async {
    Cached<T> fromCache() {
      final raw = _cache.read(cacheKey);
      if (raw == null) {
        throw const CacheMissException(
          'No internet connection and no saved data yet. '
          'Connect to the internet and try again.',
        );
      }
      return Cached(
        data: parse(jsonDecode(raw)),
        fetchedAt: _cache.timestamp(cacheKey),
        isStale: true,
      );
    }

    // Offline: go straight to stored data without waiting on a doomed request.
    if (!await _connectivity.isOnline) {
      return fromCache();
    }

    try {
      final body = await _api.getRaw(uri);
      // Persist after every successful response so storage mirrors the latest.
      await _cache.write(cacheKey, body);
      return Cached(
        data: parse(jsonDecode(body)),
        fetchedAt: DateTime.now(),
        isStale: false,
      );
    } on AppException {
      // We believed we were online but the request failed — serve stale data
      // if we have any, otherwise surface the error.
      if (_cache.has(cacheKey)) return fromCache();
      rethrow;
    }
  }
}
