import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_app/home.dart';
import 'package:super_app/theme/dark_color_scheme.dart';
import 'package:super_app/theme/light_color_scheme.dart';

import 'currency_converter/converter_home.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super App',
      debugShowCheckedModeBanner: false,
      theme:
          ThemeData(colorScheme: lightColorScheme(context), useMaterial3: true),
      darkTheme:
          ThemeData(colorScheme: darkColorScheme(context), useMaterial3: true),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      initialRoute: '/',
      routes: {
        '/': (context) => const Home(),
        '/currency-converter': (context) => const CurrencyHome()
      },
    );
  }
}
