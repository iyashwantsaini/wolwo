import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/providers.dart';
import 'core/config/api_keys.dart';
import 'data/local/app_settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge — required default for Android 15+.
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  final prefs = await SharedPreferences.getInstance();

  // Wire ApiKeys to prefer user-supplied overrides from AppSettings, falling
  // back to the build-time --dart-define defaults. This is initialised once
  // here so all sources see live key updates as the user edits Settings.
  final settings = AppSettings(prefs);
  String orDefault(String user, String fallback) =>
      user.isNotEmpty ? user : fallback;
  final defaultWh = ApiKeys.wallhaven();
  final defaultPx = ApiKeys.pixabay();
  final defaultNasa = ApiKeys.nasa();
  final defaultUa = ApiKeys.redditUserAgent();
  ApiKeys.wallhaven = () => orDefault(settings.userWallhavenKey(), defaultWh);
  ApiKeys.pixabay = () => orDefault(settings.userPixabayKey(), defaultPx);
  ApiKeys.nasa = () => orDefault(settings.userNasaKey(), defaultNasa);
  ApiKeys.redditUserAgent =
      () => orDefault(settings.userRedditUserAgent(), defaultUa);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appSettingsInstanceProvider.overrideWithValue(settings),
      ],
      child: const WolwoApp(),
    ),
  );
}
