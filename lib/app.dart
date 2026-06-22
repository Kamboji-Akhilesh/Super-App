import 'package:flutter/material.dart';
import 'package:super_app/l10n/app_localizations.dart';

import 'features/currency/presentation/currency_home_page.dart';
import 'home/home_page.dart';
import 'theme/app_theme.dart';

class SuperApp extends StatelessWidget {
  const SuperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      initialRoute: HomePage.route,
      routes: {
        HomePage.route: (_) => const HomePage(),
        CurrencyHomePage.route: (_) => const CurrencyHomePage(),
      },
    );
  }
}
