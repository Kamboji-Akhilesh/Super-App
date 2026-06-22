import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Slim banner shown when the data on screen came from device storage rather
/// than a fresh network response.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, this.fetchedAt});

  final DateTime? fetchedAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final when = fetchedAt == null
        ? ''
        : ' · updated ${DateFormat('d MMM, HH:mm').format(fetchedAt!.toLocal())}';
    return Container(
      width: double.infinity,
      color: scheme.tertiary.withValues(alpha: 0.25),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 16, color: scheme.onSurface),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Offline – showing saved data$when',
              style: TextStyle(fontSize: 12, color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
