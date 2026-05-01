import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../app/providers.dart';
import '../../data/models/feed_query.dart';
import '../../data/models/wallpaper.dart';
import 'app_loader.dart';
import 'quick_actions_sheet.dart';
import 'wallpaper_tile.dart';

/// Reusable infinite-scroll staggered grid for any [FeedQuery].
class WallpaperGrid extends ConsumerStatefulWidget {
  const WallpaperGrid({
    super.key,
    required this.query,
    this.sourceId,
    this.sourceFilter,
    this.padding = const EdgeInsets.fromLTRB(12, 8, 12, 24),
  });

  final FeedQuery query;

  /// Single-source pin. When set, only this source is queried (search page,
  /// per-source category dives). Mutually exclusive with [sourceFilter].
  final String? sourceId;

  /// Restrict merged fetch to this subset of source IDs. Null = all
  /// globally-enabled sources from Settings (the default).
  final Set<String>? sourceFilter;

  final EdgeInsets padding;

  @override
  ConsumerState<WallpaperGrid> createState() => _WallpaperGridState();
}

class _WallpaperGridState extends ConsumerState<WallpaperGrid> {
  late final PagingController<int, Wallpaper> _controller;
  late String _seed;
  // Set just before a manual refresh so the next page request bypasses
  // the repository's TTL cache. Cleared again as soon as page 1 has been
  // re-fetched so subsequent paginated pages still use the warm cache.
  bool _forceNextLoad = false;

  @override
  void initState() {
    super.initState();
    // Each grid mount gets a fresh random seed so the home/curated feed
    // doesn't surface the exact same images on every reload. Sources that
    // honour FeedQuery.seed (Wallhaven random sort, Pixabay/Reddit page
    // rotation) will pick a different starting window.
    _seed = _randomSeed();
    _controller = PagingController(firstPageKey: 1)
      ..addPageRequestListener(_load);
  }

  static String _randomSeed() {
    final r = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(8, (_) => chars[r.nextInt(chars.length)]).join();
  }

  @override
  void didUpdateWidget(covariant WallpaperGrid old) {
    super.didUpdateWidget(old);
    if (old.query.cacheKey != widget.query.cacheKey ||
        old.sourceId != widget.sourceId) {
      _seed = _randomSeed();
      _controller.refresh();
    }
  }

  Future<void> _load(int page) async {
    try {
      final repo = ref.read(repositoryProvider);
      final settings = ref.read(settingsProvider);
      final q = widget.query.copyWith(seed: _seed);
      // Only the very first page after a manual refresh should bust the
      // cache — otherwise normal pagination would re-hit the network on
      // every scroll.
      final force = _forceNextLoad && page == 1;
      if (force) {
        repo.clearCacheFor(q);
        _forceNextLoad = false;
      }

      final result = widget.sourceId != null
          ? await repo.fetchFromSource(
              sourceId: widget.sourceId!,
              query: q,
              page: page,
              forceRefresh: force,
            )
          : await repo.fetchMerged(
              enabledSourceIds: widget.sourceFilter == null
                  ? settings.enabledSources
                  : settings.enabledSources
                      .where(widget.sourceFilter!.contains),
              query: q,
              page: page,
              forceRefresh: force,
            );

      if (!mounted) return;
      _seed = result.seed ?? _seed;
      if (!result.hasMore) {
        _controller.appendLastPage(result.items);
      } else {
        _controller.appendPage(result.items, page + 1);
      }
    } catch (e) {
      if (!mounted) return;
      _controller.error = e;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _seed = _randomSeed();
        _forceNextLoad = true;
        _controller.refresh();
      },
      child: PagedMasonryGridView<int, Wallpaper>.count(
        pagingController: _controller,
        padding: widget.padding,
        // Always allow overscroll so pull-to-refresh fires even when the
        // grid hasn't filled the viewport (empty state, errors, single page).
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        // Only build tiles within roughly one viewport ahead. Combined with
        // CachedNetworkImage's lazy fetching, this means image downloads
        // are tied to scroll position \u2014 nothing fetches until the user
        // scrolls toward it.
        cacheExtent: 600,
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        builderDelegate: PagedChildBuilderDelegate<Wallpaper>(
          itemBuilder: (_, w, __) => WallpaperTile(
            wallpaper: w,
            onTap: () => context.push('/detail', extra: {'wallpaper': w}),
            onLongPress: () => showWallpaperQuickActions(context, ref, w),
          ),
          firstPageProgressIndicatorBuilder: (_) => const GridSkeleton(),
          newPageProgressIndicatorBuilder: (_) => const GridPageFooter(),
          noItemsFoundIndicatorBuilder: (_) => const _Empty(),
          firstPageErrorIndicatorBuilder: (_) =>
              _ErrorView(onRetry: () => _controller.refresh()),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_search_outlined,
                size: 32, color: scheme.outline,),
            const SizedBox(height: 12),
            Text(
              'No wallpapers here yet.',
              style: TextStyle(color: scheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'Try a different category, broaden your search,\n'
              'or enable more sources in Settings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.outline,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined,
                size: 32, color: scheme.outline,),
            const SizedBox(height: 12),
            Text('Could not load wallpapers.',
                style: TextStyle(color: scheme.onSurface),),
            const SizedBox(height: 4),
            Text(
              'Check your connection and try again.',
              style: TextStyle(color: scheme.outline, fontSize: 12),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
                onPressed: onRetry, child: const Text('Retry'),),
          ],
        ),
      ),
    );
  }
}
