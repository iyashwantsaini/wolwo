import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:convert';

/// Wallpaper-detail action layout. Cycle order is preserved:
/// `bar` → `dock` → `compact` → `bar`.
enum ViewerLayout { bar, compact }

/// Cached category cover record \u2014 just the URL we actually render in
/// the Browse grid plus a fetch timestamp so the page can decide
/// whether the cover is stale enough to refetch.
class CategoryCoverCache {
  const CategoryCoverCache({
    required this.thumbUrl,
    required this.fullUrl,
    required this.fetchedAtMs,
  });
  final String thumbUrl;
  final String fullUrl;
  final int fetchedAtMs;

  Duration get age => Duration(
        milliseconds:
            DateTime.now().millisecondsSinceEpoch - fetchedAtMs,
      );

  Map<String, dynamic> toJson() => {
        't': thumbUrl,
        'f': fullUrl,
        'ts': fetchedAtMs,
      };

  static CategoryCoverCache? tryFromJson(Map<String, dynamic> j) {
    final t = j['t'];
    final f = j['f'];
    final ts = j['ts'];
    if (t is! String || f is! String || ts is! int) return null;
    return CategoryCoverCache(thumbUrl: t, fullUrl: f, fetchedAtMs: ts);
  }
}

class AppSettings extends ChangeNotifier {
  AppSettings(this._prefs);

  static const _kEnabledSources = 'wolwo.settings.sources';
  static const _kSfwOnly = 'wolwo.settings.sfw';
  static const _kThemeMode = 'wolwo.settings.theme';
  // Wallpaper-detail viewer action layout: 'bar' (default scrolling pill
  // row), 'dock' (primary CTA + secondary icon strip), 'compact'
  // (vertical icon stack pinned to bottom-right).
  static const _kViewerLayout = 'wolwo.settings.viewerLayout';
  static const _kDefaultSource = 'wolwo.settings.defaultSource';
  static const _kPreferFourK = 'wolwo.settings.fourK';
  // Set to true once the user finishes (or skips) the first-run setup flow.
  // Until then the router redirects to /welcome so the user always gets a
  // chance to pick sources and add their own API keys before any network
  // call goes out.
  static const _kOnboardingDone = 'wolwo.settings.onboarded';
  // Most-recent search queries (newest first, capped at 8). Lets the
  // search empty-state offer one-tap re-run of recent searches alongside
  // the canned suggestions.
  static const _kSearchHistory = 'wolwo.settings.searchHistory';
  static const _kSearchHistoryMax = 8;
  // User-supplied API key overrides. When non-empty, take precedence over
  // the build-time --dart-define defaults baked into ApiKeys.
  static const _kKeyWallhaven = 'wolwo.settings.key.wallhaven';
  static const _kKeyPixabay = 'wolwo.settings.key.pixabay';
  static const _kKeyNasa = 'wolwo.settings.key.nasa';
  static const _kKeyRedditUA = 'wolwo.settings.key.redditUa';
  // JSON map: { categoryName: { t: thumbUrl, f: fullUrl, ts: epochMs } }.
  // Lets the Browse page render real cover thumbnails immediately on
  // open instead of always going to the network and showing blank
  // shimmer placeholders for a few seconds. Refreshed lazily when the
  // entry is older than `_categoryCoverTtl` or on explicit pull-to-refresh.
  static const _kCategoryCovers = 'wolwo.settings.categoryCovers';
  static const Duration _categoryCoverTtl = Duration(minutes: 15);

  final SharedPreferences _prefs;

  Set<String> get enabledSources =>
      (_prefs.getStringList(_kEnabledSources) ?? const []).toSet();

  Future<void> setSourceEnabled(String id, bool enabled) async {
    final current = enabledSources;
    if (enabled) {
      current.add(id);
    } else {
      current.remove(id);
    }
    await _prefs.setStringList(_kEnabledSources, current.toList());
    notifyListeners();
  }

  Future<void> initDefaultsIfEmpty(Iterable<String> defaults) async {
    if (_prefs.getStringList(_kEnabledSources) == null) {
      await _prefs.setStringList(_kEnabledSources, defaults.toList());
      notifyListeners();
    }
  }

  /// Synchronous variant used at provider construction so the very first
  /// build sees a populated source list (SharedPreferences caches in-memory).
  void initDefaultsIfEmptySync(Iterable<String> defaults) {
    if (_prefs.getStringList(_kEnabledSources) == null) {
      // Fire-and-forget the disk write; the in-memory cache is updated
      // immediately so subsequent reads return the seeded list.
      _prefs.setStringList(_kEnabledSources, defaults.toList());
    }
  }

  bool get sfwOnly => _prefs.getBool(_kSfwOnly) ?? true;
  Future<void> setSfwOnly(bool v) async {
    await _prefs.setBool(_kSfwOnly, v);
    notifyListeners();
  }

  bool get preferFourK => _prefs.getBool(_kPreferFourK) ?? false;
  Future<void> setPreferFourK(bool v) async {
    await _prefs.setBool(_kPreferFourK, v);
    notifyListeners();
  }

  /// First-run flag. Defaults to `false` so a fresh install lands on the
  /// onboarding screen; flipped to `true` only after the user finishes
  /// (or explicitly skips) the setup wizard.
  bool get onboardingDone => _prefs.getBool(_kOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool v) async {
    await _prefs.setBool(_kOnboardingDone, v);
    notifyListeners();
  }

  // ── Search history ──
  List<String> get searchHistory =>
      _prefs.getStringList(_kSearchHistory) ?? const [];

  Future<void> pushSearchQuery(String q) async {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return;
    final list = [...searchHistory];
    // De-dupe case-insensitively so "Forest" and "forest" don't both stack.
    list.removeWhere((e) => e.toLowerCase() == trimmed.toLowerCase());
    list.insert(0, trimmed);
    if (list.length > _kSearchHistoryMax) {
      list.removeRange(_kSearchHistoryMax, list.length);
    }
    await _prefs.setStringList(_kSearchHistory, list);
    notifyListeners();
  }

  Future<void> clearSearchHistory() async {
    await _prefs.remove(_kSearchHistory);
    notifyListeners();
  }

  ThemeMode get themeMode {
    final v = _prefs.getString(_kThemeMode) ?? 'system';
    return switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setString(_kThemeMode, mode.name);
    notifyListeners();
  }

  /// Detail-page action-row layout. Cycled by the layout button in the
  /// viewer top bar; persisted so the user's pick survives restarts.
  ViewerLayout get viewerLayout {
    final v = _prefs.getString(_kViewerLayout) ?? 'bar';
    return switch (v) {
      'compact' => ViewerLayout.compact,
      _ => ViewerLayout.bar,
    };
  }

  Future<void> setViewerLayout(ViewerLayout l) async {
    await _prefs.setString(_kViewerLayout, l.name);
    notifyListeners();
  }

  Future<void> cycleViewerLayout() async {
    final cur = viewerLayout;
    final next = ViewerLayout
        .values[(cur.index + 1) % ViewerLayout.values.length];
    await setViewerLayout(next);
  }

  // ------ Browse-page category cover cache ------

  Map<String, CategoryCoverCache> _readCategoryCovers() {
    final raw = _prefs.getString(_kCategoryCovers);
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const {};
      final out = <String, CategoryCoverCache>{};
      decoded.forEach((k, v) {
        if (k is String && v is Map) {
          final entry = CategoryCoverCache.tryFromJson(
              Map<String, dynamic>.from(v),);
          if (entry != null) out[k] = entry;
        }
      });
      return out;
    } catch (_) {
      return const {};
    }
  }

  /// Read the persisted Browse cover for `categoryName`. Returns null when
  /// nothing has been cached yet OR the cached entry is older than
  /// [_categoryCoverTtl] \u2014 the page treats both cases the same way and
  /// triggers a fresh fetch.
  CategoryCoverCache? cachedCategoryCover(String categoryName) {
    final entry = _readCategoryCovers()[categoryName];
    if (entry == null) return null;
    if (entry.age > _categoryCoverTtl) return null;
    return entry;
  }

  /// Persist a freshly-fetched cover for `categoryName`. Replaces any
  /// previous entry so the TTL clock restarts.
  Future<void> setCachedCategoryCover(
    String categoryName, {
    required String thumbUrl,
    required String fullUrl,
  }) async {
    final all = Map<String, CategoryCoverCache>.from(_readCategoryCovers());
    all[categoryName] = CategoryCoverCache(
      thumbUrl: thumbUrl,
      fullUrl: fullUrl,
      fetchedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    final out = <String, dynamic>{
      for (final e in all.entries) e.key: e.value.toJson(),
    };
    await _prefs.setString(_kCategoryCovers, jsonEncode(out));
  }

  /// Wipe every persisted cover. Called on Browse pull-to-refresh so the
  /// user can force-refresh the entire grid.
  Future<void> clearCategoryCovers() async {
    await _prefs.remove(_kCategoryCovers);
  }

  String? get defaultSource => _prefs.getString(_kDefaultSource);
  Future<void> setDefaultSource(String? id) async {
    if (id == null) {
      await _prefs.remove(_kDefaultSource);
    } else {
      await _prefs.setString(_kDefaultSource, id);
    }
    notifyListeners();
  }

  // ------ User-supplied API key overrides ------

  String userWallhavenKey() => _prefs.getString(_kKeyWallhaven) ?? '';
  String userPixabayKey() => _prefs.getString(_kKeyPixabay) ?? '';
  String userNasaKey() => _prefs.getString(_kKeyNasa) ?? '';
  String userRedditUserAgent() => _prefs.getString(_kKeyRedditUA) ?? '';

  Future<void> setUserKey(String sourceId, String value) async {
    final key = switch (sourceId) {
      'wallhaven' => _kKeyWallhaven,
      'pixabay' => _kKeyPixabay,
      'nasa' => _kKeyNasa,
      'reddit' => _kKeyRedditUA,
      _ => null,
    };
    if (key == null) return;
    if (value.trim().isEmpty) {
      await _prefs.remove(key);
    } else {
      await _prefs.setString(key, value.trim());
    }
    notifyListeners();
  }
}
