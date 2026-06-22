import 'package:flutter/foundation.dart';

/// Outcome of converting [amount] of [from] into [to].
@immutable
class ConversionResult {
  const ConversionResult({
    required this.from,
    required this.to,
    required this.amount,
    required this.rate,
    required this.date,
  });

  final String from;
  final String to;
  final double amount;

  /// 1 [from] = [rate] [to].
  final double rate;

  /// Date the underlying rate refers to (yyyy-MM-dd).
  final String date;

  double get converted => amount * rate;
}
