class AppConfig {
  const AppConfig._();

  static const String appName = 'wolwo';
  static const String appTagline = 'Free 4K wallpapers';
  static const String repoUrl = 'https://github.com/iyashwantsaini/wolwo';
  static const String privacyPolicyUrl =
      'https://github.com/iyashwantsaini/wolwo/blob/main/PRIVACY.md';

  /// Maximum on-disk image cache size.
  static const int imageCacheBytes = 500 * 1024 * 1024; // 500 MB

  /// Per-source HTTP cache lifetime.
  /// Pixabay's ToS *requires* caching results for at least 24h.
  static const Duration httpCacheTtl = Duration(hours: 24);

  /// Default page size for grids.
  static const int defaultPageSize = 24;
}
