import 'package:flutter/foundation.dart';

/// A single (date, rate) sample from the historical time-series endpoint.
@immutable
class RatePoint {
  const RatePoint({required this.date, required this.rate});

  final DateTime date;
  final double rate;
}
