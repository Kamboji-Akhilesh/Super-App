import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cached.dart';
import '../../core/providers.dart';
import 'currency_repository.dart';
import 'models/currency.dart';
import 'models/latest_rates.dart';
import 'models/rate_point.dart';

final currencyRepositoryProvider = Provider<CurrencyRepository>(
  (ref) => CurrencyRepository(
    api: ref.watch(apiClientProvider),
    cache: ref.watch(cacheServiceProvider),
    connectivity: ref.watch(connectivityServiceProvider),
  ),
);

// ---------------------------------------------------------------------------
// Rates tab
// ---------------------------------------------------------------------------

/// Base currency selected on the Rates tab.
final ratesBaseProvider = StateProvider<String>((ref) => 'INR');

/// Rates for [ratesBaseProvider], fetched once per base (no re-fetch on every
/// rebuild — that was a bug in the original `FutureBuilder` implementation).
final ratesProvider =
    FutureProvider.autoDispose<Cached<List<Currency>>>((ref) {
  final base = ref.watch(ratesBaseProvider);
  return ref.watch(currencyRepositoryProvider).getRatesWithNames(base: base);
});

/// All supported currencies (code + name), used to populate dropdowns.
final availableCurrenciesProvider =
    FutureProvider<Cached<List<Currency>>>((ref) async {
  final names = await ref.watch(currencyRepositoryProvider).getCurrencyNames();
  return names.map(
    (map) {
      final list = map.entries
          .map((e) => Currency(symbol: e.key, name: e.value, rate: 0))
          .toList()
        ..sort((a, b) => a.symbol.compareTo(b.symbol));
      return list;
    },
  );
});

// ---------------------------------------------------------------------------
// Converter tab
// ---------------------------------------------------------------------------

enum HistoryRange {
  thirty(30, '30 days'),
  sixty(60, '60 days'),
  ninety(90, '90 days');

  const HistoryRange(this.days, this.label);
  final int days;
  final String label;
}

@immutable
class ConverterState {
  const ConverterState({
    required this.amount,
    required this.from,
    required this.to,
    required this.range,
  });

  final double amount;
  final String from;
  final String to;
  final HistoryRange range;

  ConverterState copyWith({
    double? amount,
    String? from,
    String? to,
    HistoryRange? range,
  }) =>
      ConverterState(
        amount: amount ?? this.amount,
        from: from ?? this.from,
        to: to ?? this.to,
        range: range ?? this.range,
      );
}

class ConverterController extends Notifier<ConverterState> {
  @override
  ConverterState build() => const ConverterState(
        amount: 250,
        from: 'USD',
        to: 'EUR',
        range: HistoryRange.thirty,
      );

  void setAmount(double amount) =>
      state = state.copyWith(amount: amount.isNaN ? 0 : amount);

  void setFrom(String from) => state = state.copyWith(from: from);

  void setTo(String to) => state = state.copyWith(to: to);

  void setRange(HistoryRange range) => state = state.copyWith(range: range);

  /// Swaps the two currencies.
  void swap() => state = state.copyWith(from: state.to, to: state.from);
}

final converterControllerProvider =
    NotifierProvider<ConverterController, ConverterState>(
  ConverterController.new,
);

/// Latest rates keyed by base currency. Family-scoped so it only refetches
/// when the *base* changes — typing a new amount reuses the cached rates and
/// the conversion is recomputed locally (no network call per keystroke).
final latestRatesProvider =
    FutureProvider.autoDispose.family<Cached<LatestRates>, String>((ref, base) {
  return ref.watch(currencyRepositoryProvider).getLatestRates(base: base);
});

/// Historical series for the current from/to pair and selected range.
/// Uses `select` so the chart is unaffected by amount changes.
final timeSeriesProvider =
    FutureProvider.autoDispose<Cached<List<RatePoint>>>((ref) {
  final (from, to, range) = ref.watch(
    converterControllerProvider.select((s) => (s.from, s.to, s.range)),
  );
  return ref.watch(currencyRepositoryProvider).getTimeSeries(
        base: from,
        quote: to,
        days: range.days,
      );
});
