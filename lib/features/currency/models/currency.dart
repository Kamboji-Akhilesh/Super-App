import 'package:flutter/foundation.dart';

/// A currency together with its rate relative to the selected base currency.
@immutable
class Currency {
  const Currency({
    required this.symbol,
    required this.name,
    required this.rate,
  });

  /// ISO code, e.g. `USD`.
  final String symbol;

  /// Human-readable name, e.g. `United States Dollar`. Falls back to [symbol]
  /// when the name list does not contain an entry.
  final String name;

  /// Value of 1 unit of the base currency expressed in this currency.
  final double rate;

  @override
  bool operator ==(Object other) =>
      other is Currency &&
      other.symbol == symbol &&
      other.name == name &&
      other.rate == rate;

  @override
  int get hashCode => Object.hash(symbol, name, rate);
}
