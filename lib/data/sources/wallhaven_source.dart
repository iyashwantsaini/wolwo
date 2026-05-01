import 'package:dio/dio.dart';

import '../../core/config/api_keys.dart';
import '../../core/network/dio_factory.dart';
import '../models/feed_query.dart';
import '../models/wallpaper.dart';
import 'wallpaper_source.dart';

/// Wallhaven — primary source for native 4K wallpapers.
/// Docs: https://wallhaven.cc/help/api
class WallhavenSource extends WallpaperSource {
  WallhavenSource();

  Dio? _dio;
  Future<Dio> _getDio() async {
    if (_dio != null) return _dio!;
    final dio = await DioFactory.create(
      baseUrl: 'https://wallhaven.cc/api/v1',
    );
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final key = ApiKeys.wallhaven();
        if (key.isNotEmpty) {
          options.headers['X-API-Key'] = key;
        } else {
          options.headers.remove('X-API-Key');
        }
        handler.next(options);
      },
    ),);
    _dio = dio;
    return dio;
  }

  @override
  String get id => 'wallhaven';
  @override
  String get displayName => 'Wallhaven';
  @override
  String get description =>
      'A massive community-curated wallpaper library with native 4K, 5K and 8K images.';
  @override
  String get licenseSummary =>
      'Images remain the property of their original owners. For personal use; please respect each uploader\'s rights.';
  @override
  Uri get licenseUrl => Uri.parse('https://wallhaven.cc/about#Copyright');
  @override
  Uri? get privacyUrl => Uri.parse('https://wallhaven.cc/privacy-policy');

  @override
  Set<SourceCapability> get capabilities => const {
        SourceCapability.search,
        SourceCapability.categories,
        SourceCapability.colors,
        SourceCapability.curated,
        SourceCapability.trending,
        SourceCapability.fourK,
        SourceCapability.random,
      };

  @override
  List<AppCategory> get supportedCategories => const [
        AppCategory.nature,
        AppCategory.space,
        AppCategory.abstractArt,
        AppCategory.minimal,
        AppCategory.city,
        AppCategory.anime,
        AppCategory.cars,
        AppCategory.animals,
        AppCategory.amoled,
        AppCategory.textures,
      ];

  String _categoryQuery(AppCategory c) {
    switch (c) {
      case AppCategory.nature:
        return 'nature';
      case AppCategory.space:
        return 'space';
      case AppCategory.abstractArt:
        return 'abstract';
      case AppCategory.minimal:
        return 'minimalism';
      case AppCategory.city:
        return 'cityscape';
      case AppCategory.anime:
        return 'anime';
      case AppCategory.cars:
        return 'cars';
      case AppCategory.animals:
        return 'animals';
      case AppCategory.amoled:
        return 'dark amoled';
      case AppCategory.textures:
        return 'texture';
    }
  }

  @override
  Future<PagedResult> fetch(FeedQuery query, {int page = 1}) async {
    final dio = await _getDio();
    final params = <String, dynamic>{
      'page': page,
      // SFW only by default. Wallhaven uses 100/110/111 bitmask.
      'purity': query.sfwOnly ? '100' : '110',
      'categories': _categoriesBitmask(query),
      // Phone-friendly defaults: portrait ratios + 1080x1920 floor so we never
      // surface low-res or landscape junk on a phone home grid.
      'ratios': '9x16,9x18,9x19,9x20,9x21,10x16',
      'atleast': '1080x1920',
      // Bias toward higher-quality images by demanding a minimum view count
      // is not exposed by the API, but `sorting=toplist` already filters well.
    };

    switch (query.kind) {
      case FeedKind.curated:
        // Use random sort with the per-session seed so the home grid shows
        // a different slice of the high-quality pool on every cold start /
        // pull-to-refresh, instead of the same toplist every time.
        params['sorting'] = 'random';
        if (query.seed != null) params['seed'] = query.seed;
      case FeedKind.trending:
        params['sorting'] = 'hot';
      case FeedKind.fourK:
        params['atleast'] = '2160x3840'; // portrait 4K
        params['sorting'] = 'random';
        if (query.seed != null) params['seed'] = query.seed;
      case FeedKind.random:
        params['sorting'] = 'random';
        if (query.seed != null) params['seed'] = query.seed;
      case FeedKind.search:
        params['q'] = query.text ?? '';
      case FeedKind.category:
        final c = AppCategory.values
            .firstWhere((e) => e.name == query.category, orElse: () => AppCategory.nature);
        params['q'] = _categoryQuery(c);
        // Inherit the portrait + 1080x1920 floor from the base params \u2014 the
        // category sort uses 'random' so each visit surfaces a different
        // slice of the high-quality pool instead of always the same toplist.
        params['sorting'] = 'random';
        if (query.seed != null) params['seed'] = query.seed;
      case FeedKind.color:
        // Wallhaven only accepts hex values from a fixed 28-colour palette
        // — anything else (e.g. iOS-style #FF3B30) returns zero results.
        // Snap whatever UI hex we got to the nearest palette entry by RGB
        // distance so every swatch the user taps actually returns hits.
        if (query.colorHex != null) {
          params['colors'] = _nearestWallhavenColor(query.colorHex!);
        }
        // IMPORTANT: drop the global portrait `ratios` filter and the
        // 1080x1920 `atleast` floor for colour queries — combined with
        // `colors=` they zero out the result set (verified via the API:
        // `colors=cc0000` → 5,517 hits, the same query + portrait ratios
        // + atleast=1080x1920 → 0 hits). Keep only a landscape-friendly
        // 1920x1080 floor so we still avoid tiny thumbnails.
        params.remove('ratios');
        params['atleast'] = '1920x1080';
        // `sorting=toplist` also nukes the result set (it requires a
        // minimum rating most colour-tagged uploads don't meet — 22 vs
        // 5,517 in our tests). Use random+seed so each visit reshuffles
        // the colour pool and pagination still works through the full set.
        params['sorting'] = 'random';
        if (query.seed != null) params['seed'] = query.seed;
    }

    final res = await dio.get('/search', queryParameters: params);
    final data = (res.data['data'] as List).cast<Map<String, dynamic>>();
    final meta = res.data['meta'] as Map<String, dynamic>?;

    final items = data.map(_parse).toList();
    final last = (meta?['last_page'] as int?) ?? page;

    return PagedResult(
      items: items,
      page: page,
      hasMore: page < last,
      seed: meta?['seed'] as String?,
    );
  }

  String _categoriesBitmask(FeedQuery q) {
    // general/anime/people bitmask. We bias toward `general` only by default
    // because anime + people categories are noisier and lean toward portraits
    // of faces — not what most people want on their home screen.
    return '100';
  }

  /// Wallhaven only honours hex values from a fixed 28-colour palette —
  /// any other hex returns zero results. Map an arbitrary input hex to
  /// the perceptually nearest palette entry by squared-RGB distance.
  static const _wallhavenPalette = <String>[
    '660000', '990000', 'cc0000', 'cc3333', 'ea4c88',
    '993399', '663399', '333399', '0066cc', '0099cc',
    '66cccc', '77cc33', '669900', '336600', '666600',
    '999900', 'cccc33', 'ffff00', 'ffcc33', 'ff9900',
    'ff6600', 'cc6633', '996633', '663300', '000000',
    '999999', 'cccccc', 'ffffff', '424153',
  ];

  String _nearestWallhavenColor(String hex) {
    final clean = hex.replaceFirst('#', '').toLowerCase();
    if (_wallhavenPalette.contains(clean)) return clean;
    int parse(String h, int s) => int.parse(h.substring(s, s + 2), radix: 16);
    int r, g, b;
    try {
      r = parse(clean, 0);
      g = parse(clean, 2);
      b = parse(clean, 4);
    } catch (_) {
      return '000000';
    }
    String best = _wallhavenPalette.first;
    var bestDist = 1 << 30;
    for (final p in _wallhavenPalette) {
      final pr = parse(p, 0), pg = parse(p, 2), pb = parse(p, 4);
      final dr = pr - r, dg = pg - g, db = pb - b;
      final dist = dr * dr + dg * dg + db * db;
      if (dist < bestDist) {
        bestDist = dist;
        best = p;
      }
    }
    return best;
  }

  Wallpaper _parse(Map<String, dynamic> j) {
    final thumbs = (j['thumbs'] as Map?)?.cast<String, dynamic>() ?? const {};
    final colors = (j['colors'] as List?)?.cast<String>() ?? const [];
    return Wallpaper(
      id: j['id'] as String,
      sourceId: id,
      thumbUrl: thumbs['small'] as String? ?? thumbs['large'] as String? ?? j['path'] as String,
      // The Wallhaven `large` thumb is only ~300px wide — it looks blurry
      // in our 2-column grid. Use the original `path` URL as the preview
      // layer so each tile shows the actual high-res wallpaper. The tile
      // still keeps the small thumb underneath as an instant placeholder.
      previewUrl: j['path'] as String,
      fullUrl: j['path'] as String,
      width: (j['dimension_x'] as num).toInt(),
      height: (j['dimension_y'] as num).toInt(),
      colorHex: colors.isNotEmpty ? colors.first : null,
      tags: const [],
      sourcePageUrl: j['url'] as String?,
      license: 'Wallhaven — © original uploaders',
      fileSizeBytes: (j['file_size'] as num?)?.toInt(),
    );
  }
}
