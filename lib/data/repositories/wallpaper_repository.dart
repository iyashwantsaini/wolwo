import '../models/feed_query.dart';
import '../models/wallpaper.dart';
import '../sources/wallpaper_source.dart';

/// Aggregates results from multiple [WallpaperSource]s. The UI talks to this,
/// not to individual sources.
class WallpaperRepository {
  WallpaperRepository(this._sources);

  final List<WallpaperSource> _sources;

  /// In-memory page cache. Keeps each fetched page for [_cacheTtl] so that
  /// flipping between tabs / categories / pages doesn't re-hit the upstream
  /// APIs every time. Cleared on pull-to-refresh and on the explicit
  /// refresh buttons in the header.
  static const Duration _cacheTtl = Duration(minutes: 3);
  final Map<String, _CacheEntry> _pageCache = {};

  /// Per-source pagination cursors, keyed by `sourceId|query.cacheKey`.
  /// We can't share a single global cursor across sources because each
  /// API has its own opaque token shape (Reddit `t3_xxx`, Pixabay int
  /// page, Wallhaven seed string). Without this map, calling
  /// [fetchMerged] for page 2 would re-send page 1's random seed to every
  /// source — Reddit (which treats `seed` as `after`) silently ignores
  /// invalid tokens and returns the same first page, so the same posts
  /// land in the same grid slots forever.
  final Map<String, String?> _cursorBySource = {};

  /// Sources that have signalled `hasMore=false` for a given query. We
  /// stop polling them on later pages so we don't burn API calls (and
  /// don't waste a round-robin slot on an empty result that would leave
  /// gaps in the merged grid).
  final Map<String, Set<String>> _depletedBySource = {};

  /// Recently-shown wallpaper keys, capped FIFO. Suppresses cross-feed
  /// repeats within a single session (e.g. Home → Trending → Categories
  /// often hit overlapping subreddits and would re-show the same posts
  /// 30 seconds apart, which feels broken even though it's technically
  /// correct). Cleared on `clearCache`.
  static const int _recentLruCap = 240;
  final List<String> _recentlyShownOrder = [];
  final Set<String> _recentlyShown = {};

  void _markShown(Iterable<Wallpaper> items) {
    for (final w in items) {
      final k = w.globalKey;
      if (_recentlyShown.add(k)) {
        _recentlyShownOrder.add(k);
        if (_recentlyShownOrder.length > _recentLruCap) {
          final drop = _recentlyShownOrder.removeAt(0);
          _recentlyShown.remove(drop);
        }
      }
    }
  }

  String _cursorKey(String sourceId, FeedQuery q) =>
      '$sourceId|${q.cacheKey}';

  String _cacheKey({
    required String scope,
    required FeedQuery query,
    required int page,
    Iterable<String>? sources,
  }) {
    final src = sources == null
        ? ''
        : (sources.toList()..sort()).join(',');
    return '$scope|src=$src|p=$page|${query.cacheKey}';
  }

  _CacheEntry? _hit(String key) {
    final e = _pageCache[key];
    if (e == null) return null;
    if (DateTime.now().difference(e.at) > _cacheTtl) {
      _pageCache.remove(key);
      return null;
    }
    return e;
  }

  /// Drop every cached page. Called on header refresh / pull-to-refresh
  /// when we want totally fresh results.
  void clearCache() {
    _pageCache.clear();
    _cursorBySource.clear();
    _depletedBySource.clear();
    _recentlyShownOrder.clear();
    _recentlyShown.clear();
  }

  /// Drop only entries matching a query tag (e.g. one category) so other
  /// tabs keep their warm cache.
  void clearCacheFor(FeedQuery query) {
    final tag = query.cacheKey;
    _pageCache.removeWhere((k, _) => k.contains(tag));
    _cursorBySource.removeWhere((k, _) => k.contains(tag));
    _depletedBySource.remove(tag);
  }

  List<WallpaperSource> get allSources => List.unmodifiable(_sources);

  WallpaperSource? sourceById(String id) {
    for (final s in _sources) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Fetch a page from a single named source. Used when the user filters by source.
  Future<PagedResult> fetchFromSource({
    required String sourceId,
    required FeedQuery query,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final src = sourceById(sourceId);
    if (src == null) {
      return const PagedResult(items: [], page: 1, hasMore: false);
    }
    if (!src.supports(query.kind)) {
      return PagedResult(items: const [], page: page, hasMore: false);
    }
    final key = _cacheKey(
      scope: 'one:$sourceId',
      query: query,
      page: page,
    );
    if (!forceRefresh) {
      final hit = _hit(key);
      if (hit != null) return hit.result;
    }
    try {
      final r = await src.fetch(query, page: page);
      _pageCache[key] = _CacheEntry(r, DateTime.now());
      return r;
    } catch (_) {
      // A single-source pin shouldn't dump the user on a generic
      // "Could not load" \u2014 returning an empty page lets the grid show its
      // friendlier "No wallpapers found" empty state instead.
      return PagedResult(items: const [], page: page, hasMore: false);
    }
  }

  /// Fetch a page from every enabled source in parallel and round-robin merge.
  /// Pagination across multiple sources uses a single page index applied to each.
  Future<PagedResult> fetchMerged({
    required Iterable<String> enabledSourceIds,
    required FeedQuery query,
    int page = 1,
    bool forceRefresh = false,
  }) async {
    final activeAll = _sources
        .where((s) => enabledSourceIds.contains(s.id) && s.supports(query.kind))
        .toList();
    if (activeAll.isEmpty) {
      return const PagedResult(items: [], page: 1, hasMore: false);
    }

    // Drop sources that have already exhausted their feed for this query.
    // Without this, every later page wastes round-robin slots on an empty
    // result, leaving visible gaps in the merged grid.
    final depleted = _depletedBySource[query.cacheKey] ?? const <String>{};
    final active = activeAll.where((s) => !depleted.contains(s.id)).toList();
    if (active.isEmpty) {
      // Everyone's done. Return an empty terminal page so the grid
      // shows its "you've reached the end" footer instead of looping.
      return PagedResult(items: const [], page: page, hasMore: false);
    }

    final key = _cacheKey(
      scope: 'merged',
      query: query,
      page: page,
      sources: active.map((s) => s.id),
    );
    if (!forceRefresh) {
      final hit = _hit(key);
      if (hit != null) {
        _markShown(hit.result.items);
        return hit.result;
      }
    }

    final results = await Future.wait(
      active.map((s) {
        // Each source paginates with its own remembered cursor. On page 1
        // we honour whatever seed the caller passed (used by single-source
        // sort rotation in Reddit/Wallhaven). On later pages we replace
        // that with the per-source `after` token we stashed on the
        // previous round so each API actually advances instead of
        // re-serving page 1.
        final cursorKey = _cursorKey(s.id, query);
        final perSourceQuery = page == 1
            ? query
            : query.copyWith(seed: _cursorBySource[cursorKey] ?? query.seed);
        return s.fetch(perSourceQuery, page: page).catchError((_) {
          return const PagedResult(items: [], page: 1, hasMore: false);
        });
      }),
    );

    // Stash each source's next cursor for the following page request,
    // and remember which sources are now depleted so future page calls
    // skip them entirely.
    final depletedSet =
        _depletedBySource.putIfAbsent(query.cacheKey, () => <String>{});
    for (var i = 0; i < active.length; i++) {
      _cursorBySource[_cursorKey(active[i].id, query)] = results[i].seed;
      if (!results[i].hasMore) depletedSet.add(active[i].id);
    }

    // Apply a global wallpaper-grade quality gate after every source
    // returns. Each source already filters internally, but this is a
    // safety net so nothing landscape / tiny / square ever leaks into
    // the home grid even if a source forgets a filter or upstream API
    // changes shape. Strict in curated/trending/4K, loose in
    // category/search/random where users want maximum coverage.
    final strict = query.kind == FeedKind.curated ||
        query.kind == FeedKind.trending ||
        query.kind == FeedKind.fourK;

    // Pre-score each source's items and sort high \u2192 low so the best
    // tiles surface first within each round-robin pass. Front-loading
    // quality matters a lot more than tail quality on infinite-scroll
    // feeds \u2014 the user judges the app on the first 12 tiles.
    final perSourceItems = <List<Wallpaper>>[];
    for (final r in results) {
      final filtered = r.items
          .where((w) => _passesQualityGate(w, strict))
          .where((w) => !_recentlyShown.contains(w.globalKey))
          .toList()
        ..sort((a, b) => _qualityScore(b).compareTo(_qualityScore(a)));
      perSourceItems.add(filtered);
    }

    final merged = <Wallpaper>[];
    final seen = <String>{};
    var anyHasMore = false;
    for (final r in results) {
      if (r.hasMore) anyHasMore = true;
    }

    // Per-source weight: how many items to take from each source per
    // round-robin pass. Most sources contribute 1; under-represented but
    // visually distinctive sources (NASA, with only ~25 hits per query)
    // get a small boost so they're actually visible in the grid instead
    // of getting buried 1-in-every-4 tiles.
    int weightFor(WallpaperSource s) => switch (s.id) {
          'nasa' => 2,
          _ => 1,
        };

    // Round-robin always lands the same source at the same merged-grid
    // index (e.g. Reddit at 1, 3, 5...). To keep the visual mix lively
    // across refreshes we rotate the source-iteration starting offset by
    // the per-fetch seed. Same page \u2192 same order (stable for pagination
    // dedup); different seed \u2192 different mix.
    final rotation =
        ((query.seed?.hashCode ?? page.hashCode).abs()) % active.length;
    final order = List<int>.generate(
        active.length, (i) => (i + rotation) % active.length);

    // Anti-clump interleave: instead of taking `weightFor` items from
    // one source back-to-back (which puts two NASAs in adjacent grid
    // slots), spread the extra picks across rounds. Round 0 takes 1
    // from each source; round 1 takes 1 from each source AND a 2nd
    // from any source whose weight > 1; etc. This guarantees the
    // weighted source still gets its share but never lands two-in-a-row.
    final cursors = List<int>.filled(active.length, 0);
    while (true) {
      var addedThisRound = false;
      // Primary pass: one from each source, in rotated order.
      for (final i in order) {
        final list = perSourceItems[i];
        if (cursors[i] < list.length) {
          final wp = list[cursors[i]++];
          if (seen.add(wp.globalKey)) {
            merged.add(wp);
            addedThisRound = true;
          }
        }
      }
      // Bonus pass: pick up the extra weight for boosted sources, but
      // only after every primary slot has been filled in this round.
      for (final i in order) {
        final extra = weightFor(active[i]) - 1;
        if (extra <= 0) continue;
        final list = perSourceItems[i];
        for (var k = 0; k < extra && cursors[i] < list.length; k++) {
          final wp = list[cursors[i]++];
          if (seen.add(wp.globalKey)) {
            merged.add(wp);
            addedThisRound = true;
          }
        }
      }
      if (!addedThisRound) break;
    }

    final out = PagedResult(items: merged, page: page, hasMore: anyHasMore);
    _pageCache[key] = _CacheEntry(out, DateTime.now());
    _markShown(merged);
    return out;
  }
}

class _CacheEntry {
  _CacheEntry(this.result, this.at);
  final PagedResult result;
  final DateTime at;
}

/// Wallpaper-grade quality gate. Centralised here so every source benefits
/// from the same rejection rules and the home grid stays consistent even
/// when a new source is added.
///
/// `strict` is used for curated/trending/4K feeds where the user expects
/// polished phone wallpapers. The looser branch is used for category /
/// search / random feeds where coverage matters more than perfection
/// (some categories have very few portrait results).
bool _passesQualityGate(Wallpaper w, bool strict) {
  // Width 0 / height 0 means the source didn't report dimensions \u2014 we
  // can't judge, so let it through (NASA does this; tiles render fine).
  if (w.width == 0 || w.height == 0) return true;
  if (strict) {
    // Phone wallpaper: portrait, at least 1080px wide, aspect 1.3\u20132.6.
    if (w.width < 1080) return false;
    final r = w.height / w.width;
    if (r < 1.3 || r > 2.6) return false;
    return true;
  }
  // Loose: anything HD-wide that isn't extreme landscape.
  if (w.width < 720) return false;
  if (w.width > w.height * 2) return false;
  return true;
}

/// Soft quality score (higher == better). Used to sort items inside each
/// source before round-robin merge so the strongest tiles surface first.
/// Pure heuristic \u2014 no network, no image decode, just metadata we
/// already have.
///
/// Components (each contributes 0..1, summed and normalised):
/// - **aspect**: closeness to common phone ratios (19.5:9 \u2248 2.17, 18:9
///   = 2.0, 16:9 portrait = 1.78). Peak at ~2.0, fall off either side.
/// - **resolution**: rewards 1080p+ width, capped at 4K so absurdly
///   large files don't dominate.
/// - **attribution**: small bonus for posts with an author + source
///   page \u2014 weak proxy for "real photography vs. random repost".
/// - **license**: bonus when we know the license string (Wallhaven,
///   Pixabay, NASA all populate this; Reddit submissions don't).
double _qualityScore(Wallpaper w) {
  // Aspect: gaussian-ish peak at 2.0.
  double aspectScore;
  if (w.width == 0 || w.height == 0) {
    aspectScore = 0.5;
  } else {
    final r = w.height / w.width;
    final delta = (r - 2.0).abs();
    aspectScore = (1.0 - (delta / 1.0)).clamp(0.0, 1.0);
  }

  // Resolution: 1080 \u2192 0.5, 1440 \u2192 0.75, 2160+ \u2192 1.0.
  double resScore;
  if (w.width == 0) {
    resScore = 0.5;
  } else if (w.width >= 2160) {
    resScore = 1.0;
  } else if (w.width >= 1440) {
    resScore = 0.75;
  } else if (w.width >= 1080) {
    resScore = 0.55;
  } else if (w.width >= 720) {
    resScore = 0.30;
  } else {
    resScore = 0.10;
  }

  final attribScore = (w.author != null && w.author!.isNotEmpty) ? 1.0 : 0.0;
  final licenseScore = (w.license != null && w.license!.isNotEmpty) ? 1.0 : 0.0;

  // Weights: aspect dominates because a wrong-aspect wallpaper is
  // unusable; resolution second; attribution / license are tie-breakers.
  return (aspectScore * 0.55) +
      (resScore * 0.30) +
      (attribScore * 0.08) +
      (licenseScore * 0.07);
}

