import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_app/controller/currency_controller.dart';

class Rates extends ConsumerStatefulWidget {
  const Rates({super.key});

  @override
  ConsumerState<Rates> createState() => _RatesState();
}

class _RatesState extends ConsumerState<Rates> {
  String _from = "INR";

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 32, 8, 0),
      child: FutureBuilder(
        future: ref
            .watch(currencyControllerProvider)
            .getLatestCurrencyRatesAndNames(from: _from),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data != null) {
            final currencyRatesAndNames = snapshot.data;
            List<DropdownMenuEntry<String?>> dropdownDataItems =
                currencyRatesAndNames!
                    .map((currencyData) => DropdownMenuEntry(
                          value: currencyData.symbol,
                          label: currencyData.name ?? "",
                        ))
                    .toList();
            dropdownDataItems
                .add(DropdownMenuEntry(value: _from, label: _from));
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Value of 1 "),
                      DropdownButtonHideUnderline(
                        child: DropdownMenu(
                          initialSelection: _from,
                          dropdownMenuEntries: dropdownDataItems,
                          trailingIcon: const Icon(Icons.keyboard_arrow_down),
                          textStyle: TextStyle(
                            fontSize: 24,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onSelected: (dynamic value) {
                            setState(() {
                              _from = value;
                            });
                          },
                          inputDecorationTheme: const InputDecorationTheme(
                            border: InputBorder.none,
                          ),
                          width: 100,
                        ),
                      ),
                      const Text("in other currencies"),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: currencyRatesAndNames?.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(currencyRatesAndNames?[index].name ?? ""),
                        subtitle:
                            Text(currencyRatesAndNames?[index].symbol ?? ""),
                        trailing: Text(
                            "${currencyRatesAndNames?[index].valueWrtInr.toString() ?? ""} $_from"),
                      );
                    },
                  ),
                ),
              ],
            );
          } else {
            return const Center(
              child: Text("Try again later."),
            );
          }
        },
      ),
    );
  }
}
