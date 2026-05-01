import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/network/dio_factory.dart';
import '../models/feed_query.dart';
import '../models/wallpaper.dart';
import 'wallpaper_source.dart';

/// NASA Image and Video Library — public domain space photography.
/// Docs: https://images.nasa.gov/docs/images.nasa.gov_api_docs.pdf
class NasaSource extends WallpaperSource {
  NasaSource();

  Dio? _dio;
  Future<Dio> _getDio() async =>
      _dio ??= await DioFactory.create(baseUrl: 'https://images-api.nasa.gov');

  @override
  String get id => 'nasa';
  @override
  String get displayName => 'NASA';
  // Off by default: NASA's catalogue is gorgeous space *photography*, but
  // it's not designed as phone-wallpaper material — most images are
  // landscape, frequently include text/labels/instrument framing, and
  // look out of place mixed into a general Trending grid. Users who
  // want it can flip it on in Settings (it shines for the Space and
  // AMOLED categories).
  @override
  bool get enabledByDefault => false;
  @override
  String get description =>
      'Public-domain space, planetary and astronomy photography from NASA.';
  @override
  String get licenseSummary =>
      'Public Domain — NASA imagery is generally free to use. Credit "NASA" where possible.';
  @override
  Uri get licenseUrl =>
      Uri.parse('https://www.nasa.gov/nasa-brand-center/images-and-media/');

  @override
  Set<SourceCapability> get capabilities => const {
        SourceCapability.search,
        SourceCapability.categories,
        SourceCapability.curated,
      };

  @override
  List<AppCategory> get supportedCategories => const [AppCategory.space];

  String _categoryQuery(AppCategory c) {
    switch (c) {
      case AppCategory.space:
        // Hubble has the deepest catalogue (~4,700 hits across ~195 pages)
        // — gives the seed-offset randomisation room to actually breathe.
        // The previous "galaxy nebula" only had 75 hits = 4 pages, so most
        // randomised refreshes silently returned empty.
        return 'hubble';
      case AppCategory.nature:
        return 'earth landscape';
      case AppCategory.amoled:
        // Pure-black backgrounds galore in deep-space photography — maps
        // perfectly to the AMOLED look.
        return 'deep space';
      case AppCategory.minimal:
        return 'horizon';
      default:
        // NASA's catalog is mostly space/earth, so any unrelated category
        // (cars, anime, textures...) just falls back to a clean space
        // query rather than returning zero results and confusing the
        // merged grid.
        return 'hubble';
    }
  }

  @override
  Future<PagedResult> fetch(FeedQuery query, {int page = 1}) async {
    try {
      return await _fetchInner(query, page: page);
    } catch (_) {
      // Never let NASA take down the merged grid — a single source error
      // shouldn't block Wallhaven/Pixabay/Reddit results from showing.
      return PagedResult(items: const [], page: page, hasMore: false);
    }
  }

  Future<PagedResult> _fetchInner(FeedQuery query, {int page = 1}) async {
    final dio = await _getDio();
    // NASA's search has no `random` sort and no seed parameter — every call
    // for the same query returns the same page. To stop the merged feed
    // from repeating identical NASA imagery on every refresh, we apply a
    // page offset derived from the per-session seed.
    //
    // CRITICAL: the offset MUST be clamped by `total_hits` for the actual
    // query, otherwise narrow queries (e.g. "galaxy nebula" → 75 hits = 4
    // pages) silently return 0 results on most refreshes. We do this by
    // first asking page-1 for `metadata.total_hits`, then re-issuing the
    // request at a randomised page within the valid range. The first call
    // is cheap (small JSON, no images) so the extra round-trip is fine.
    final params = <String, dynamic>{
      'media_type': 'image',
      'page_size': AppConfig.defaultPageSize,
    };

    switch (query.kind) {
      case FeedKind.search:
        params['q'] = query.text ?? 'space';
      case FeedKind.category:
        final c = AppCategory.values
            .firstWhere((e) => e.name == query.category, orElse: () => AppCategory.space);
        params['q'] = _categoryQuery(c);
      case FeedKind.curated:
      case FeedKind.trending:
        // Hubble has the deepest catalogue (4k+ hits) and curated/trending
        // wants visual punch — anchor on Hubble + recent Webb imagery.
        params['q'] = 'hubble';
        params['year_start'] = '2010';
      case FeedKind.fourK:
        params['q'] = 'hubble';
      case FeedKind.color:
      case FeedKind.random:
        params['q'] = 'galaxy';
    }
    // NOTE: do NOT pass `api_key` to /search. NASA's image search endpoint
    // is fully open and explicitly rejects api_key with `400 Bad Request:
    // "Unacceptable search parameter: api_key"`. The key is only accepted
    // on /asset and /metadata endpoints (used by `resolveFullUrl`).

    // Step 1: probe metadata to know how many pages this query has.
    final probe = await dio.get('/search', queryParameters: {
      ...params,
      'page': 1,
    },);
    final probeCollection = probe.data['collection'] as Map<String, dynamic>;
    final probeMeta =
        (probeCollection['metadata'] as Map?)?.cast<String, dynamic>();
    final totalHits = (probeMeta?['total_hits'] as num?)?.toInt() ?? 0;
    final maxPage = totalHits == 0
        ? 1
        : ((totalHits + AppConfig.defaultPageSize - 1) ~/
                AppConfig.defaultPageSize)
            .clamp(1, 100); // NASA caps at 100 pages anyway

    final seedOffset = query.seed == null
        ? 0
        : (query.seed!.hashCode.abs() % maxPage);
    // Stride pagination through the available range, wrapping around so
    // infinite scroll keeps producing fresh items rather than dead-ending.
    final effectivePage = (((page - 1) + seedOffset) % maxPage) + 1;

    // Reuse the probe response when we'd hit page 1 anyway — saves a round trip.
    final res = effectivePage == 1
        ? probe
        : await dio.get('/search',
            queryParameters: {...params, 'page': effectivePage},);
    final collection = res.data['collection'] as Map<String, dynamic>;
    final items = (collection['items'] as List).cast<Map<String, dynamic>>();

    final wallpapers = items.map(_parse).whereType<Wallpaper>().toList();

    // We control hasMore ourselves now: keep paginating as long as the
    // user hasn't walked the entire (clamped) range.
    final hasMore = page < maxPage;

    return PagedResult(items: wallpapers, page: page, hasMore: hasMore);
  }

  Wallpaper? _parse(Map<String, dynamic> item) {
    try {
      final data = (item['data'] as List?)?.cast<Map<String, dynamic>>();
      if (data == null || data.isEmpty) return null;
      final meta = data.first;
      final links = (item['links'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      if (links.isEmpty) return null;

      final rawThumb = links.firstWhere(
        (l) => l['rel'] == 'preview',
        orElse: () => links.first,
      )['href'] as String?;
      if (rawThumb == null || rawThumb.isEmpty) return null;

      final nasaId = meta['nasa_id'] as String?;
      if (nasaId == null || nasaId.isEmpty) return null;

      // NASA's CDN is finicky: only `~thumb`, `~small`, `~medium` and
      // `~orig` are reliably present \u2014 `~large` 403s on most assets, and
      // even `~medium` is missing for some collections (GSFC archive).
      // The URL the search API hands back is always live (the API wouldn't
      // return it otherwise), so we anchor on that for the thumb and
      // jump straight to `~orig` (typically 200\u2013800KB JPEGs) for the
      // preview + full image. No middle rendition guessing, no 403 storms.
      final ext = rawThumb.toLowerCase().endsWith('.png') ? '.png' : '.jpg';
      final stripped = rawThumb.replaceAll(RegExp(r'~[a-z]+\.(jpg|png)$'), '');
      final orig = '$stripped~orig$ext';

      return Wallpaper(
        id: nasaId,
        sourceId: id,
        thumbUrl: rawThumb,
        // Use the API-returned thumb URL (`~small` or `~medium`, ~50–200KB)
        // as the preview layer too. It's always live, decodes fast via
        // the native `<img>` element, and is sharp enough for a 2-column
        // grid cell. The `~orig` rendition (500KB–1MB) is reserved for
        // the detail screen where the user actually wants full quality.
        previewUrl: rawThumb,
        fullUrl: orig,
        // NASA doesn't return image dimensions in search; use a sensible default
        // (the detail screen will measure the real image when loaded).
        width: 3840,
        height: 2160,
        tags: ((meta['keywords'] as List?)?.cast<String>()) ?? const [],
        author: (meta['secondary_creator'] ?? meta['photographer']) as String?,
        sourcePageUrl: 'https://images.nasa.gov/details/$nasaId',
        license: 'NASA — Public Domain',
      );
    } catch (_) {
      // Skip malformed entries silently rather than failing the whole page.
      return null;
    }
  }

  /// Resolves the highest-resolution image URL for a NASA asset by hitting
  /// the asset manifest endpoint. The manifest returns an ordered list of
  /// available renditions; we pick the one that ends in `~orig.*` (or the
  /// largest available image).
  ///
  /// Use this on the detail screen right before applying / saving. Cheap:
  /// one extra HTTP call, response is small JSON.
  Future<String?> resolveFullUrl(String nasaId) async {
    try {
      final dio = await _getDio();
      final res = await dio.get('/asset/$nasaId');
      final items = (res.data['collection']?['items'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          const [];
      // Prefer ~orig.*; otherwise the first image rendition.
      String? orig;
      String? firstImage;
      for (final i in items) {
        final href = i['href'] as String?;
        if (href == null) continue;
        if (firstImage == null &&
            (href.endsWith('.jpg') ||
                href.endsWith('.jpeg') ||
                href.endsWith('.png'))) {
          firstImage = href;
        }
        if (href.contains('~orig.')) {
          orig = href;
          break;
        }
      }
      return orig ?? firstImage;
    } catch (_) {
      return null;
    }
  }
}
