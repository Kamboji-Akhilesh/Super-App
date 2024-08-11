import 'package:flutter/material.dart';
import 'package:super_app/currency_converter/rates.dart';

import '../custom_painters/triangle.dart';
import './converter.dart';

class CurrencyHome extends StatelessWidget {
  const CurrencyHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          foregroundColor: Theme.of(context).colorScheme.background,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.surface
                ],
              ),
            ),
          ),
          bottom: TabBar(
            indicatorColor: Theme.of(context).colorScheme.background,
            labelColor: Theme.of(context).colorScheme.background,
            unselectedLabelColor: Theme.of(context).colorScheme.background,
            indicator: TriangleTabIndicator(
                color: Theme.of(context).colorScheme.background),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.normal),
            tabs: const [
              Tab(text: "Converter"),
              Tab(text: "Rates"),
              Tab(text: "Info"),
            ],
          ),
          title: const Text("Currency Converter"),
        ),
        body: const TabBarView(
          children: [
            Converter(),
            Rates(),
            Icon(Icons.directions_bike),
          ],
        ),
      ),
    );
  }
}
