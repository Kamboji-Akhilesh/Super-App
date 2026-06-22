import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers.dart';
import '../../providers.dart';

/// Static information about the data source and the app's offline behaviour.
class InfoTab extends ConsumerWidget {
  const InfoTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(connectivityStatusProvider).value ?? true;
    final lastUpdated = ref.watch(ratesProvider).valueOrNull?.fetchedAt;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Row(
          icon: online ? Icons.cloud_done : Icons.cloud_off,
          title: 'Connection',
          subtitle: online ? 'Online – fetching live rates' : 'Offline – showing saved rates',
        ),
        if (lastUpdated != null)
          _Row(
            icon: Icons.update,
            title: 'Rates last updated',
            subtitle: DateFormat('d MMM yyyy, HH:mm').format(lastUpdated.toLocal()),
          ),
        const _Row(
          icon: Icons.dataset,
          title: 'Data source',
          subtitle: 'Frankfurter API (European Central Bank reference rates)',
        ),
        const _Row(
          icon: Icons.save,
          title: 'Offline storage',
          subtitle:
              'Every response is saved on-device. Without internet, the most '
              'recently saved data is shown automatically.',
        ),
        const _Row(
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'Rates are indicative and provided for reference only.',
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
