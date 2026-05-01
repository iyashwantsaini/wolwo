import 'package:dio/dio.dart';

import '../../core/config/api_keys.dart';
import '../../core/config/app_config.dart';
import '../../core/network/dio_factory.dart';
import '../models/feed_query.dart';
import '../models/wallpaper.dart';
import 'wallpaper_source.dart';

/// Pixabay — clean license, great category and color filters.
/// Docs: https://pixabay.com/api/docs/
///
/// Note: full-resolution `imageURL` is only returned when your key is approved
/// for `response_group=high_resolution` (email Pixabay support to enable).
/// Without it, `largeImageURL` (~1280px) is the best you'll get.
class PixabaySource extends WallpaperSource {
  PixabaySource();

  Dio? _dio;
  Future<Dio> _getDio() async => _dio ??=
      await DioFactory.create(baseUrl: 'https://pixabay.com/api');

  @override
  String get id => 'pixabay';
  @override
  String get displayName => 'Pixabay';
  @override
  String get description =>
      'Royalty-free images. Commercial use allowed. Great for category and color browsing.';
  @override
  String get licenseSummary =>
      'Pixabay Content License: free for commercial use, no attribution required (but appreciated).';
  @override
  Uri get licenseUrl => Uri.parse('https://pixabay.com/service/license-summary/');
  @override
  Uri? get privacyUrl => Uri.parse('https://pixabay.com/service/privacy/');

  @override
  @override
  bool get enabledByDefault => false; // off by default — stock-photo bias often surfaces objects, not wallpapers

  @override
  Set<SourceCapability> get capabilities => const {
        SourceCapability.search,
        SourceCapability.categories,
        // Pixabay's `colors=` filter is a pure histogram match — it returns
        // every photo where that hue dominates regardless of subject, so
        // colour searches surface stock cutouts (snowmen, bottles, single
        // flowers on white) that look nothing like wallpapers. Wallhaven's
        // colour search is wallpaper-only by design, so we route every
        // colour query through Wallhaven exclusively.
        SourceCapability.curated,
      };

  @override
  List<AppCategory> get supportedCategories => const [
        AppCategory.nature,
        AppCategory.minimal,
        AppCategory.city,
        AppCategory.animals,
        AppCategory.textures,
      ];

  String _categoryName(AppCategory c) {
    // Pixabay categories: backgrounds, fashion, nature, science, education,
    // feelings, health, people, religion, places, animals, industry, computer,
    // food, sports, transportation, travel, buildings, business, music.
    switch (c) {
      case AppCategory.nature:
        return 'nature';
      case AppCategory.city:
        return 'places';
      case AppCategory.animals:
        return 'animals';
      case AppCategory.textures:
        return 'backgrounds';
      case AppCategory.minimal:
        return 'backgrounds';
      default:
        return '';
    }
  }

  String _colorName(String hex) {
    // Pixabay accepts named colors only.
    final h = hex.replaceFirst('#', '').toLowerCase();
    const map = <String, String>{
      'ff0000': 'red',
      'ffa500': 'orange',
      'ffff00': 'yellow',
      '00ff00': 'green',
      '40e0d0': 'turquoise',
      '0000ff': 'blue',
      'c8a2c8': 'lilac',
      'ffc0cb': 'pink',
      'ffffff': 'white',
      '808080': 'gray',
      '000000': 'black',
      'a52a2a': 'brown',
    };
    return map[h] ?? 'transparent';
  }

  @override
  Future<PagedResult> fetch(FeedQuery query, {int page = 1}) async {
    if (!ApiKeys.hasPixabay) {
      return const PagedResult(items: [], page: 1, hasMore: false);
    }
    final dio = await _getDio();
    // Rotate the starting page using the per-session seed so curated/trending
    // feeds don't surface the exact same first-page hits on every reload.
    final pageOffset = query.seed == null
        ? 0
        : (query.seed!.hashCode.abs() % 8); // 0..7
    final dataPage = page + pageOffset;
    final params = <String, dynamic>{
      'key': ApiKeys.pixabay(),
      'image_type': 'photo',
      'orientation': 'vertical',
      'safesearch': query.sfwOnly ? 'true' : 'false',
      'per_page': AppConfig.defaultPageSize,
      'page': dataPage,
      // Phone-friendly floor \u2014 Pixabay returns plenty of small images by
      // default. Demand at least 1080x1920 so the grid only shows usable
      // wallpapers.
      'min_width': 1080,
      'min_height': 1920,
    };

    switch (query.kind) {
      case FeedKind.curated:
        // Editor's Choice = hand-picked by Pixabay, much higher quality bar.
        params['editors_choice'] = 'true';
        params['order'] = 'popular';
      case FeedKind.trending:
        params['order'] = 'popular';
      case FeedKind.fourK:
        params['min_width'] = 2160;
        params['min_height'] = 3840;
        params['order'] = 'popular';
      case FeedKind.search:
        params['q'] = query.text ?? '';
      case FeedKind.category:
        final c = AppCategory.values
            .firstWhere((e) => e.name == query.category, orElse: () => AppCategory.nature);
        final native = _categoryName(c);
        if (native.isNotEmpty) params['category'] = native;
      case FeedKind.color:
        if (query.colorHex != null) params['colors'] = _colorName(query.colorHex!);
        // Without a `q=` term Pixabay's `colors=` filter returns every
        // photo where that hue dominates — including isolated stock
        // cutouts (bunnies on white, food on black, emoji), which look
        // nothing like wallpapers in the grid. Anchoring on the
        // `backgrounds` category + a wallpaper-ish query keeps us in
        // landscape/abstract territory where colour-driven phone
        // wallpapers actually live.
        params['q'] = 'wallpaper background';
        params['category'] = 'backgrounds';
        params['order'] = 'popular';
      case FeedKind.random:
        params['order'] = 'latest';
    }

    final res = await dio.get('/', queryParameters: params);
    final hits = (res.data['hits'] as List).cast<Map<String, dynamic>>();
    final total = (res.data['totalHits'] as num?)?.toInt() ?? 0;

    var items = hits.map(_parse).toList();
    // Drop anything that isn't unmistakably portrait wallpaper shape.
    // Pixabay's `orientation=vertical` is lenient (anything taller than
    // wide qualifies) so we still see square-ish stock cutouts; this
    // pushes the bar to a real phone-wallpaper ratio (≥ 1.3).
    items = items
        .where((w) => w.height >= w.width * 1.3 && w.width >= 1080)
        .toList();
    final loadedSoFar = (page - 1) * AppConfig.defaultPageSize + items.length;
    return PagedResult(
      items: items,
      page: page,
      hasMore: loadedSoFar < total && items.isNotEmpty,
    );
  }

  Wallpaper _parse(Map<String, dynamic> j) {
    final width = (j['imageWidth'] as num).toInt();
    final height = (j['imageHeight'] as num).toInt();
    return Wallpaper(
      id: j['id'].toString(),
      sourceId: id,
      thumbUrl: j['previewURL'] as String,
      // Use the largest free rendition (`largeImageURL` ≈ 1280px) for the
      // grid preview layer instead of the small `webformatURL`. The full
      // `imageURL` requires API approval and isn't generally available.
      previewUrl:
          (j['largeImageURL'] ?? j['fullHDURL'] ?? j['webformatURL']) as String?,
      // Prefer fullHD/large; fall back to webformat.
      fullUrl: (j['fullHDURL'] ?? j['largeImageURL'] ?? j['webformatURL']) as String,
      width: width,
      height: height,
      tags: ((j['tags'] as String?) ?? '')
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      author: j['user'] as String?,
      authorUrl: 'https://pixabay.com/users/${j['user']}-${j['user_id']}/',
      sourcePageUrl: j['pageURL'] as String?,
      license: 'Pixabay Content License',
    );
  }
}
