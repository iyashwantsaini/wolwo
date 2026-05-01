import 'package:flutter/foundation.dart';

import '../models/feed_query.dart';
import '../models/wallpaper.dart';

/// Capabilities a source advertises so the UI can hide unsupported options.
enum SourceCapability {
  search,
  categories,
  colors,
  curated,
  trending,
  fourK,
  random,
}

/// Categories normalized across sources. Each source maps these to its own
/// native concepts (tag query, subreddit, NASA keyword, etc.).
enum AppCategory {
  nature('Nature'),
  space('Space'),
  abstractArt('Abstract'),
  minimal('Minimal'),
  city('City'),
  anime('Anime'),
  cars('Cars'),
  animals('Animals'),
  amoled('AMOLED'),
  textures('Textures');

  const AppCategory(this.label);
  final String label;
}

@immutable
abstract class WallpaperSource {
  const WallpaperSource();

  /// Stable identifier: 'wallhaven', 'pixabay', 'nasa', 'reddit'.
  String get id;

  /// Display name shown in the UI.
  String get displayName;

  /// One-line description shown in the About + Settings screens.
  String get description;

  /// Human-readable license summary shown alongside every wallpaper.
  String get licenseSummary;

  /// Where users can read the full license / ToS.
  Uri get licenseUrl;

  /// Where users can read the source site's privacy policy.
  Uri? get privacyUrl => null;

  Set<SourceCapability> get capabilities;

  /// Native categories this source advertises. Used to populate the category grid.
  List<AppCategory> get supportedCategories;

  /// Whether this source is enabled by default on a fresh install.
  bool get enabledByDefault => true;

  Future<PagedResult> fetch(FeedQuery query, {int page = 1});

  bool supports(FeedKind kind) {
    switch (kind) {
      case FeedKind.search:
        return capabilities.contains(SourceCapability.search);
      case FeedKind.category:
        return capabilities.contains(SourceCapability.categories);
      case FeedKind.color:
        return capabilities.contains(SourceCapability.colors);
      case FeedKind.curated:
        return capabilities.contains(SourceCapability.curated);
      case FeedKind.trending:
        return capabilities.contains(SourceCapability.trending);
      case FeedKind.fourK:
        return capabilities.contains(SourceCapability.fourK);
      case FeedKind.random:
        return capabilities.contains(SourceCapability.random);
    }
  }
}
