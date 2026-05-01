// Smoke test — just builds the app and pumps a frame.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wolwo/app/app.dart';
import 'package:wolwo/app/providers.dart';

void main() {
  testWidgets('App boots without exceptions', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const WolwoApp(),
      ),
    );
    await tester.pump();
  });
}
