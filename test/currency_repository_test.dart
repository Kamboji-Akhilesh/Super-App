import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_app/core/exceptions.dart';
import 'package:super_app/core/services/api_client.dart';
import 'package:super_app/core/services/cache_service.dart';
import 'package:super_app/core/services/connectivity_service.dart';
import 'package:super_app/features/currency/currency_repository.dart';

/// Connectivity stub whose online state can be toggled per test.
class _FakeConnectivity extends ConnectivityService {
  _FakeConnectivity(this.online);
  bool online;

  @override
  Future<bool> get isOnline async => online;
}

const _freshBody =
    '{"amount":1,"base":"USD","date":"2024-01-02","rates":{"EUR":0.9}}';
const _cachedBody =
    '{"amount":1,"base":"USD","date":"2023-12-01","rates":{"EUR":0.8}}';

Future<CacheService> _cache([Map<String, Object> seed = const {}]) async {
  SharedPreferences.setMockInitialValues(seed);
  return CacheService(await SharedPreferences.getInstance());
}

CurrencyRepository _repo({
  required bool online,
  required CacheService cache,
  required http.Client client,
}) =>
    CurrencyRepository(
      api: ApiClient(client),
      cache: cache,
      connectivity: _FakeConnectivity(online),
    );

void main() {
  test('online: returns fresh data and persists it', () async {
    final cache = await _cache();
    final repo = _repo(
      online: true,
      cache: cache,
      client: MockClient((_) async => http.Response(_freshBody, 200)),
    );

    final result = await repo.getLatestRates(base: 'USD');

    expect(result.isStale, isFalse);
    expect(result.data.rateFor('EUR'), 0.9);
    // Response was written to storage for offline use.
    expect(cache.has('cache.latest.USD'), isTrue);
  });

  test('offline with cached data: returns stale data', () async {
    final cache = await _cache({'cache.latest.USD': _cachedBody});
    final repo = _repo(
      online: false,
      cache: cache,
      client: MockClient((_) async => throw Exception('should not be called')),
    );

    final result = await repo.getLatestRates(base: 'USD');

    expect(result.isStale, isTrue);
    expect(result.data.rateFor('EUR'), 0.8);
  });

  test('offline with no cache: throws CacheMissException', () async {
    final cache = await _cache();
    final repo = _repo(
      online: false,
      cache: cache,
      client: MockClient((_) async => http.Response(_freshBody, 200)),
    );

    expect(
      () => repo.getLatestRates(base: 'USD'),
      throwsA(isA<CacheMissException>()),
    );
  });

  test('online but request fails: falls back to stale cache', () async {
    final cache = await _cache({'cache.latest.USD': _cachedBody});
    final repo = _repo(
      online: true,
      cache: cache,
      client: MockClient((_) async => http.Response('error', 500)),
    );

    final result = await repo.getLatestRates(base: 'USD');

    expect(result.isStale, isTrue);
    expect(result.data.rateFor('EUR'), 0.8);
  });
}
