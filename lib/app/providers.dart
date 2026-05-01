import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/local/app_settings.dart';
import '../data/local/favorites_store.dart';
import '../data/repositories/wallpaper_repository.dart';
import '../data/sources/nasa_source.dart';
import '../data/sources/pixabay_source.dart';
import '../data/sources/reddit_source.dart';
import '../data/sources/wallhaven_source.dart';
import '../data/sources/wallpaper_source.dart';

/// Set in main() once SharedPreferences is loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in ProviderScope'),
);

/// Singleton AppSettings created in main() so we have one instance shared by
/// both the ApiKeys resolver and the UI provider below.
final appSettingsInstanceProvider = Provider<AppSettings>(
  (ref) => throw UnimplementedError('Override in ProviderScope'),
);

final sourcesProvider = Provider<List<WallpaperSource>>((ref) {
  return [
    WallhavenSource(),
    PixabaySource(),
    NasaSource(),
    RedditSource(),
  ];
});

final repositoryProvider = Provider<WallpaperRepository>((ref) {
  return WallpaperRepository(ref.watch(sourcesProvider));
});

final settingsProvider = ChangeNotifierProvider<AppSettings>((ref) {
  final settings = ref.watch(appSettingsInstanceProvider);
  // Seed defaults on first run.
  final defaults = ref
      .read(sourcesProvider)
      .where((s) => s.enabledByDefault)
      .map((s) => s.id);
  settings.initDefaultsIfEmptySync(defaults);
  return settings;
});

final favoritesProvider = ChangeNotifierProvider<FavoritesStore>((ref) {
  return FavoritesStore(ref.watch(sharedPreferencesProvider));
});
