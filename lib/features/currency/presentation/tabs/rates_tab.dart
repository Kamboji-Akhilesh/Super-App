import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/currency.dart';
import '../../providers.dart';
import '../widgets/error_retry.dart';
import '../widgets/offline_banner.dart';

/// Lists the value of 1 unit of the selected base currency in every other
/// supported currency. Offline-aware with pull-to-refresh.
class RatesTab extends ConsumerWidget {
  const RatesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final base = ref.watch(ratesBaseProvider);
    final ratesAsync = ref.watch(ratesProvider);

    return ratesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorRetry(
        message: '$error',
        onRetry: () => ref.invalidate(ratesProvider),
      ),
      data: (cached) {
        final currencies = cached.data;
        return RefreshIndicator(
          onRefresh: () async => ref.refresh(ratesProvider.future),
          child: Column(
            children: [
              if (cached.isStale) OfflineBanner(fetchedAt: cached.fetchedAt),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Value of 1 '),
                    _BasePicker(
                      base: base,
                      currencies: currencies,
                      onChanged: (value) =>
                          ref.read(ratesBaseProvider.notifier).state = value,
                    ),
                    const Text(' in other currencies'),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: currencies.length,
                  itemBuilder: (context, index) {
                    final c = currencies[index];
                    return ListTile(
                      title: Text(c.name),
                      subtitle: Text(c.symbol),
                      trailing: Text(
                        '${_fmt.format(c.rate)} $base',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

final NumberFormat _fmt = NumberFormat('#,##0.####');

class _BasePicker extends StatelessWidget {
  const _BasePicker({
    required this.base,
    required this.currencies,
    required this.onChanged,
  });

  final String base;
  final List<Currency> currencies;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    // The base itself isn't part of the rate list (the API omits it), so add it.
    final symbols = {base, ...currencies.map((c) => c.symbol)}.toList()..sort();
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: base,
        icon: const Icon(Icons.keyboard_arrow_down),
        style: TextStyle(
          fontSize: 24,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        items: [
          for (final s in symbols)
            DropdownMenuItem(value: s, child: Text(s)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
