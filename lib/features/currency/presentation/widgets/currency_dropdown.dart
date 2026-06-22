import 'package:flutter/material.dart';

/// Simple currency-code dropdown shared by the converter.
class CurrencyDropdown extends StatelessWidget {
  const CurrencyDropdown({
    super.key,
    required this.value,
    required this.symbols,
    required this.onChanged,
  });

  final String value;
  final List<String> symbols;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    // Guarantee the current value is selectable even if the list is still
    // loading or doesn't contain it.
    final items = {value, ...symbols}.toList()..sort();
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        icon: const Icon(Icons.keyboard_arrow_down),
        style: TextStyle(
          fontSize: 24,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        items: [
          for (final s in items)
            DropdownMenuItem(value: s, child: Text(s)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }
}
