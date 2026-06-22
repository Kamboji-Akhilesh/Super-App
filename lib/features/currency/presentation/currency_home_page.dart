import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../custom_painters/triangle.dart';
import '../providers.dart';
import 'tabs/converter_tab.dart';
import 'tabs/info_tab.dart';
import 'tabs/rates_tab.dart';

class CurrencyHomePage extends ConsumerWidget {
  const CurrencyHomePage({super.key});

  static const String route = '/currency-converter';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    // When connectivity is regained, drop the cached futures so the tabs
    // refetch fresh data automatically.
    ref.listen(connectivityStatusProvider, (prev, next) {
      final reconnected = (prev?.value ?? false) == false && next.value == true;
      if (reconnected) {
        ref.invalidate(ratesProvider);
        ref.invalidate(latestRatesProvider);
        ref.invalidate(timeSeriesProvider);
        ref.invalidate(availableCurrenciesProvider);
      }
    });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: scheme.surface,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.tertiary],
              ),
            ),
          ),
          bottom: TabBar(
            indicatorColor: scheme.surface,
            labelColor: scheme.surface,
            unselectedLabelColor: scheme.surface,
            indicator: TriangleTabIndicator(color: scheme.surface),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.normal),
            tabs: const [
              Tab(text: 'Converter'),
              Tab(text: 'Rates'),
              Tab(text: 'Info'),
            ],
          ),
          title: const Text('Currency Converter'),
        ),
        body: const TabBarView(
          children: [
            ConverterTab(),
            RatesTab(),
            InfoTab(),
          ],
        ),
      ),
    );
  }
}
