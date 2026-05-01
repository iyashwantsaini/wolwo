import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Custom cache manager for wallpapers.
///
/// `cached_network_image` defaults to [DefaultCacheManager] which keeps up
/// to **200 files for 30 days** with no byte-size cap. Wallpapers are
/// 5–15 MB each, so on a real device the on-disk cache balloons to
/// ~1–3 GB within a few browsing sessions.
///
/// We replace it with a tighter policy:
///   * Keep at most **80** images on disk (≈ a few hundred MB worst-case).
///     The library prunes lazily on a ~30s timer + on each new write,
///     so the actual count fluctuates briefly above 80 between sweeps.
///   * Drop anything older than **7 days**.
///
/// Pass [WolwoImageCacheManager.instance] as the `cacheManager:` arg of
/// every `CachedNetworkImage` / `CachedNetworkImageProvider` so they
/// share a single store instead of falling back to the unbounded
/// default.
class WolwoImageCacheManager {
  static const _key = 'wolwoImageCache';

  static final CacheManager instance = CacheManager(
    Config(
      _key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 80,
      repo: JsonCacheInfoRepository(databaseName: _key),
      fileService: HttpFileService(),
    ),
  );
}
