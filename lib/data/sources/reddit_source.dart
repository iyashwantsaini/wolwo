import 'package:dio/dio.dart';

import '../../core/config/api_keys.dart';
import '../../core/config/app_config.dart';
import '../../core/network/dio_factory.dart';
import '../models/feed_query.dart';
import '../models/wallpaper.dart';
import 'wallpaper_source.dart';

/// Reddit — community-curated, daily-fresh wallpapers via public JSON.
/// No API key required; just a custom User-Agent string per Reddit ToS.
///
/// IMPORTANT: Content is user-submitted. Many images may be copyrighted.
/// We surface this clearly in the UI ("from r/<subreddit>", "Report" button).
class RedditSource extends WallpaperSource {
  RedditSource();

  Dio? _dio;
  Future<Dio> _getDio() async {
    if (_dio != null) return _dio!;
    final dio = await DioFactory.create(
      baseUrl: 'https://www.reddit.com',
    );
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        options.headers['User-Agent'] = ApiKeys.redditUserAgent();
        handler.next(options);
      },
    ));
    _dio = dio;
    return dio;
  }

  @override
  String get id => 'reddit';
  @override
  String get displayName => 'Reddit';
  @override
  String get description =>
      'Daily fresh wallpapers curated by the Reddit community. Content is user-submitted.';
  @override
  String get licenseSummary =>
      'Posts are submitted by Reddit users. Original copyright belongs to the creator. '
      'For personal use only — please respect each creator\'s rights.';
  @override
  Uri get licenseUrl =>
      Uri.parse('https://www.redditinc.com/policies/user-agreement');
  @override
  Uri? get privacyUrl =>
      Uri.parse('https://www.reddit.com/policies/privacy-policy');

  @override
  bool get enabledByDefault => true; // r/MobileWallpaper, r/Amoledbackgrounds — real phone wallpapers

  @override
  Set<SourceCapability> get capabilities => const {
        SourceCapability.search,
        SourceCapability.categories,
        SourceCapability.curated,
        SourceCapability.trending,
        SourceCapability.fourK,
      };

  @override
  List<AppCategory> get supportedCategories => const [
        AppCategory.nature,
        AppCategory.space,
        AppCategory.minimal,
        AppCategory.amoled,
        AppCategory.anime,
        AppCategory.city,
      ];

  String _subForCategory(AppCategory c) {
    // Prefer mobile-first subs so results are already portrait-shaped.
    switch (c) {
      case AppCategory.nature:
        return 'NatureIsBeautiful';
      case AppCategory.space:
        return 'spaceporn';
      case AppCategory.minimal:
        return 'MinimalWallpaper';
      case AppCategory.amoled:
        return 'Amoledbackgrounds';
      case AppCategory.anime:
        return 'Animewallpaper';
      case AppCategory.city:
        return 'CityPorn';
      default:
        return 'MobileWallpaper';
    }
  }

  /// Multireddit-style path that pulls from several mobile-wallpaper subs at
  /// once. Reddit accepts `/r/sub1+sub2+sub3/...` natively.
  static const _mobileMulti =
      'MobileWallpaper+iWallpaper+iphonewallpapers+Amoledbackgrounds+WidescreenWallpaper';

  /// Wider multi used for trending so we have enough posts to survive the
  /// portrait + min-resolution filter and still fill the grid.
  static const _trendingMulti =
      'MobileWallpaper+iWallpaper+iphonewallpapers+Amoledbackgrounds+'
      'WallpapersMobile+wallpaper+wallpapers+Verticalwallpapers+'
      'AndroidWallpapers';

  @override
  Future<PagedResult> fetch(FeedQuery query, {int page = 1}) async {
    final dio = await _getDio();

    // Reddit's `after` token must look like `t3_<id>`. The repository
    // hands us its random per-mount session seed on page 1 (used purely
    // to rotate sort/window below). Passing that random string as
    // `after` would make Reddit silently 404-then-empty, so we only
    // forward seeds that look like real `after` tokens.
    final after = (query.seed != null && query.seed!.startsWith('t3_'))
        ? query.seed
        : null;

    String path;
    final params = <String, dynamic>{
      // Reddit caps at 100. Always ask for the max so the post-fetch
      // wallpaper-quality filter has a healthy pool to whittle down from.
      'limit': 100,
      'raw_json': 1,
      if (after != null) 'after': after,
    };

    // Stable rotation key so curated/trending pick a different
    // sort+window on each fresh mount of the grid (the random seed
    // changes per mount), but stay consistent within a paginated session.
    final rot = (query.seed?.hashCode ?? 0).abs();

    switch (query.kind) {
      case FeedKind.search:
        path = '/r/$_mobileMulti/search.json';
        params['q'] = query.text ?? '';
        params['restrict_sr'] = 'on';
        // Rotate sort so a re-search of the same term doesn't lock to
        // the same dozen "top" posts forever.
        const sorts = ['top', 'relevance', 'new'];
        params['sort'] = sorts[rot % sorts.length];
        if (params['sort'] == 'top') params['t'] = 'year';
      case FeedKind.category:
        final c = AppCategory.values
            .firstWhere((e) => e.name == query.category, orElse: () => AppCategory.nature);
        // Rotate sort+window per mount so reopening a category surfaces
        // a different slice instead of the same week-top stack.
        const variants = [
          ('top', 'week'),
          ('top', 'month'),
          ('top', 'year'),
          ('hot', null),
          ('rising', null),
        ];
        final v = variants[rot % variants.length];
        path = '/r/${_subForCategory(c)}/${v.$1}.json';
        if (v.$2 != null) params['t'] = v.$2;
      case FeedKind.curated:
        // Rotate sort + window so the home grid doesn't show the same
        // week-top posts on every reload.
        const variants = [
          ('top', 'day'),
          ('top', 'week'),
          ('top', 'month'),
          ('hot', null),
          ('rising', null),
        ];
        final v = variants[rot % variants.length];
        path = '/r/$_mobileMulti/${v.$1}.json';
        if (v.$2 != null) params['t'] = v.$2;
      case FeedKind.trending:
        // Use a wider multi and rotate sort/window per session so trending
        // doesn't show the exact same dozen wallpapers every visit. Reddit
        // caps `limit` at 100, so ask for the max and let the post-filter
        // keep what fits the grid.
        const variants = [
          ('top', 'day'),
          ('top', 'week'),
          ('hot', null),
          ('rising', null),
        ];
        final v = variants[rot % variants.length];
        path = '/r/$_trendingMulti/${v.$1}.json';
        if (v.$2 != null) params['t'] = v.$2;
      case FeedKind.fourK:
        path = '/r/$_mobileMulti/top.json';
        params['t'] = 'month';
      case FeedKind.color:
      case FeedKind.random:
        path = '/r/$_mobileMulti/random.json';
    }

    final res = await dio.get(path, queryParameters: params);
    final data = res.data is List ? res.data.first : res.data;
    final children =
        (((data as Map)['data'] as Map)['children'] as List).cast<Map<String, dynamic>>();
    final nextAfter = ((data['data'] as Map)['after']) as String?;

    // Quality filters are stricter for the home feeds (where the user
    // expects polished phone wallpapers) and looser for category browsing
    // (where the topical subs are landscape-heavy and would otherwise
    // return zero results). Search/random keep the lighter filter too.
    final strict = query.kind == FeedKind.curated ||
        query.kind == FeedKind.trending ||
        query.kind == FeedKind.fourK;

    final items = children
        .map((c) => c['data'] as Map<String, dynamic>)
        .map(_parse)
        .whereType<Wallpaper>()
        .where((w) {
          if (strict) {
            // Wallpaper-grade: portrait, ≥1080px wide, sane aspect.
            return w.height >= w.width * 1.1 &&
                w.width >= 1080 &&
                w.height <= w.width * 2.6;
          }
          // Categories / search / random: still require phone-shaped
          // (portrait) and HD-wide. Reddit's wallpaper-adjacent subs
          // happily return square posts, screenshots, memes, comic
          // panels and avatars otherwise \u2014 anything with `post_hint:
          // image` slips through the earlier check.
          return w.width >= 720 &&
              w.height >= w.width * 1.05 &&
              w.height <= w.width * 2.6;
        })
        .toList();

    return PagedResult(
      items: items,
      page: page,
      hasMore: nextAfter != null && nextAfter.isNotEmpty,
      seed: nextAfter,
    );
  }

  Wallpaper? _parse(Map<String, dynamic> p) {
    if (p['over_18'] == true) return null;
    if (p['post_hint'] != 'image' && (p['url_overridden_by_dest'] == null)) {
      return null;
    }
    final url = (p['url_overridden_by_dest'] ?? p['url']) as String?;
    if (url == null) return null;
    if (!url.endsWith('.jpg') &&
        !url.endsWith('.jpeg') &&
        !url.endsWith('.png') &&
        !url.endsWith('.webp')) {
      return null;
    }

    // Title-based noise filter. r/Amoledbackgrounds and friends post a lot
    // of "OLED test pattern", "burn-in test", "true black", "calibration
    // chart" type images that look like dead-pixel TV static when shown
    // at full size. They're technically wallpapers but useless to almost
    // every user. We drop anything whose title looks like a calibration
    // / utility post.
    final title = (p['title'] as String? ?? '').toLowerCase();
    const noiseMarkers = [
      'test pattern',
      'burn-in',
      'burn in test',
      'pixel test',
      'dead pixel',
      'calibration',
      'oled test',
      'amoled test',
      'screen test',
      'alignment grid',
      'noise pattern',
      'static pattern',
    ];
    for (final m in noiseMarkers) {
      if (title.contains(m)) return null;
    }

    final preview = (p['preview'] as Map?)?.cast<String, dynamic>();
    final source = (preview?['images'] as List?)?.cast<Map<String, dynamic>>().firstOrNull;
    final src = (source?['source'] as Map?)?.cast<String, dynamic>();
    final width = (src?['width'] as num?)?.toInt() ?? 0;
    final height = (src?['height'] as num?)?.toInt() ?? 0;
    final resolutions =
        (source?['resolutions'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    // Reddit pre-renders multiple resolutions sorted small → large. Use a
    // mid-size for the thumb (decode-cheap placeholder) and the largest
    // available rendition (≤1080p typically) for the preview layer so the
    // grid shows sharp imagery without paying the full ‘url’ download cost
    // on every tile. The detail screen still loads the original `url`.
    final thumb = resolutions.length >= 3
        ? resolutions[(resolutions.length ~/ 2)]['url'] as String
        : (resolutions.isNotEmpty
            ? resolutions.first['url'] as String
            : url);
    final largePreview = resolutions.isNotEmpty
        ? resolutions.last['url'] as String
        : url;

    return Wallpaper(
      id: p['id'] as String,
      sourceId: id,
      thumbUrl: thumb,
      previewUrl: largePreview,
      fullUrl: url,
      width: width,
      height: height,
      author: p['author'] as String?,
      authorUrl: 'https://www.reddit.com/user/${p['author']}',
      sourcePageUrl: 'https://www.reddit.com${p['permalink']}',
      license: 'Reddit user submission — copyright belongs to original creator',
    );
  }
}
