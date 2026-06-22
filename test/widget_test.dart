import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:super_app/app.dart';
import 'package:super_app/core/providers.dart';

void main() {
  testWidgets('App boots to the Home screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: const SuperApp(),
      ),
    );

    expect(find.text('Super App'), findsOneWidget);
    expect(find.text('Currency Converter'), findsOneWidget);
  });
}
