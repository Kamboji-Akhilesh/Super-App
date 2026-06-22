import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/latest_rates.dart';
import '../../providers.dart';
import '../widgets/currency_dropdown.dart';
import '../widgets/error_retry.dart';
import '../widgets/offline_banner.dart';

final NumberFormat _money = NumberFormat('#,##0.##');
final NumberFormat _rate = NumberFormat('#,##0.####');

/// Live currency converter: amount + from/to selectors with a real-time result
/// and a historical chart driven by the Frankfurter time-series endpoint.
class ConverterTab extends ConsumerStatefulWidget {
  const ConverterTab({super.key});

  @override
  ConsumerState<ConverterTab> createState() => _ConverterTabState();
}

class _ConverterTabState extends ConsumerState<ConverterTab> {
  late final TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    final amount = ref.read(converterControllerProvider).amount;
    _amountController =
        TextEditingController(text: _money.format(amount));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(converterControllerProvider);
    final controller = ref.read(converterControllerProvider.notifier);

    // Currency codes for the dropdowns (falls back to current pair while the
    // currency list is loading or unavailable offline).
    final symbols = ref.watch(availableCurrenciesProvider).maybeWhen(
          data: (cached) => cached.data.map((c) => c.symbol).toList(),
          orElse: () => <String>[state.from, state.to],
        );

    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xffc9c9c9)),
              ),
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[0-9.]'),
                          ),
                        ],
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (value) => controller
                            .setAmount(double.tryParse(value) ?? 0),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        state.from,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CurrencyDropdown(
                  value: state.from,
                  symbols: symbols,
                  onChanged: controller.setFrom,
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text('to'),
                    IconButton(
                      tooltip: 'Swap currencies',
                      iconSize: 48,
                      color: scheme.primary,
                      icon: const Icon(Icons.repeat),
                      onPressed: controller.swap,
                    ),
                  ],
                ),
                CurrencyDropdown(
                  value: state.to,
                  symbols: symbols,
                  onChanged: controller.setTo,
                ),
                ElevatedButton(
                  onPressed: () => FocusScope.of(context).unfocus(),
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                    backgroundColor: scheme.secondary,
                    foregroundColor: scheme.onSecondary,
                    elevation: 20,
                    shadowColor: scheme.secondary,
                    textStyle: const TextStyle(fontSize: 24),
                  ),
                  child: const Text('GO'),
                ),
              ],
            ),
          ),
          _ConversionResultView(amount: state.amount, from: state.from, to: state.to),
          const Padding(
            padding: EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Text(
              'Historical Data',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (final range in HistoryRange.values)
                  _RangeRadio(
                    label: range.label,
                    selected: state.range == range,
                    onTap: () => controller.setRange(range),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
            child: Text(
              'Value of 1 ${state.from} in ${state.to} '
              'for the past ${state.range.days} days',
              style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
          const _HistoryChart(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Computes and shows the converted value from cached rates (no per-keystroke
/// network call — the rates future is keyed by `from`).
class _ConversionResultView extends ConsumerWidget {
  const _ConversionResultView({
    required this.amount,
    required this.from,
    required this.to,
  });

  final double amount;
  final String from;
  final String to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratesAsync = ref.watch(latestRatesProvider(from));
    return ratesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.fromLTRB(32, 32, 32, 0),
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
        child: ErrorRetry(
          message: '$error',
          onRetry: () => ref.invalidate(latestRatesProvider(from)),
        ),
      ),
      data: (cached) {
        final LatestRates rates = cached.data;
        final rate = rates.rateFor(to);
        if (rate == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Text('$from → $to is not supported.'),
          );
        }
        return Column(
          children: [
            if (cached.isStale)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: OfflineBanner(fetchedAt: cached.fetchedAt),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 0),
              child: Column(
                children: [
                  Text(
                    '${_money.format(amount * rate)} $to',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '1 $from = ${_rate.format(rate)} $to',
                      style: const TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryChart extends ConsumerWidget {
  const _HistoryChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final quote = ref.watch(converterControllerProvider.select((s) => s.to));
    final seriesAsync = ref.watch(timeSeriesProvider);

    return seriesAsync.when(
      loading: () => const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => SizedBox(
        height: 220,
        child: ErrorRetry(
          message: '$error',
          onRetry: () => ref.invalidate(timeSeriesProvider),
        ),
      ),
      data: (cached) {
        final points = cached.data;
        if (points.length < 2) {
          return const SizedBox(
            height: 220,
            child: Center(child: Text('Not enough historical data.')),
          );
        }
        final spots = <FlSpot>[
          for (var i = 0; i < points.length; i++)
            FlSpot(i.toDouble(), points[i].rate),
        ];
        return Column(
          children: [
            if (cached.isStale) OfflineBanner(fetchedAt: cached.fetchedAt),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 32, 0),
              child: AspectRatio(
                aspectRatio: 1.5,
                child: LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        show: true,
                        spots: spots,
                        gradient: LinearGradient(
                          colors: [
                            scheme.error,
                            scheme.secondary,
                            scheme.primary,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                        ),
                        isCurved: true,
                        barWidth: 6,
                        curveSmoothness: 0.35,
                        preventCurveOverShooting: true,
                        dotData: const FlDotData(show: false),
                        isStrokeCapRound: true,
                      ),
                    ],
                    gridData: const FlGridData(
                      drawHorizontalLine: true,
                      drawVerticalLine: false,
                    ),
                    borderData: FlBorderData(
                      border: const Border.symmetric(
                        horizontal: BorderSide(color: Colors.grey),
                        vertical: BorderSide.none,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(),
                      rightTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        axisNameSize: 20,
                        axisNameWidget: Text('Currency in $quote'),
                        sideTitles: const SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          interval: ((points.length - 1) / 3)
                              .clamp(1, double.infinity)
                              .floorToDouble(),
                          getTitlesWidget: (value, meta) {
                            final i = value.round();
                            if (i < 0 || i >= points.length) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 4,
                              child: Text(
                                DateFormat('d MMM').format(points[i].date),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: const LineTouchData(
                      touchTooltipData: LineTouchTooltipData(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Custom radio-style range selector matching the original visual design.
class _RangeRadio extends StatelessWidget {
  const _RangeRadio({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              width: selected ? 24 : 18,
              height: selected ? 24 : 18,
              margin: selected ? null : const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: selected
                    ? Border.all(width: 6, color: scheme.secondary)
                    : Border.all(width: 2, color: Colors.grey),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          spreadRadius: 0.25,
                          blurRadius: 25,
                          color: scheme.secondary,
                          blurStyle: BlurStyle.outer,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: selected ? scheme.onSurface : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
