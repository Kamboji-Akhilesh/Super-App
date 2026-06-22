import 'package:flutter/foundation.dart';

/// Parsed `/latest` response: 1 unit of [base] expressed in each currency.
@immutable
class LatestRates {
  const LatestRates({
    required this.base,
    required this.date,
    required this.rates,
  });

  final String base;
  final String date;
  final Map<String, double> rates;

  factory LatestRates.fromJson(Map<String, dynamic> json) {
    final rawRates = (json['rates'] as Map<String, dynamic>? ?? const {});
    return LatestRates(
      base: json['base'] as String? ?? '',
      date: json['date'] as String? ?? '',
      rates: rawRates.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
    );
  }

  /// Rate from [base] to [quote]. Returns 1 when [quote] equals [base]
  /// (the API omits the base from its own rate list).
  double? rateFor(String quote) {
    if (quote == base) return 1;
    return rates[quote];
  }
}
