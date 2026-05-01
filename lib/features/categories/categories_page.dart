import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../app/providers.dart';
import '../../core/net/network_image_with_fallback.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/models/feed_query.dart';
import '../../data/models/wallpaper.dart';
import '../../data/sources/wallpaper_source.dart';
import '../common/page_header.dart';
import '../common/source_filter_sheet.dart';
import '../common/wallpaper_grid.dart';

/// Fetches a single representative wallpaper for the given category so the
/// Browse cards can render with a real preview image instead of an empty
/// placeholder.
///
/// Two-tier caching:
///   1. **Persisted disk cache** (`AppSettings.cachedCategoryCover`): the
///      cover URL is stashed to SharedPreferences with a timestamp so the
///      page paints immediately on open with the same image the user saw
///      last time, instead of always going to the network and showing
///      shimmer for a few seconds. Cached entries live for 15 minutes.
///   2. **Riverpod family cache**: keyed by (category, seed) so within a
///      single session refreshes can bust the disk cache by bumping the
///      seed without affecting the cached entry of any other tile.
///
/// On pull-to-refresh the page bumps the seed AND clears the persisted
/// covers so every tile re-fetches from upstream.
final _categoryPreviewProvider =
    FutureProvider.family<Wallpaper?, (AppCategory, int)>((ref, args) async {
  final cat = args.$1;
  final seed = args.$2;
  final repo = ref.watch(repositoryProvider);
  final settings = ref.watch(settingsProvider);

  // Disk cache hit: return a synthetic Wallpaper that's only used to
  // render the Browse card thumbnail. The user never opens this
  // wallpaper directly \u2014 tapping the card pushes a category feed \u2014
  // so we can stub out width/height/id with safe defaults.
  if (seed == 0) {
    final cached = settings.cachedCategoryCover(cat.name);
    if (cached != null) {
      return Wallpaper(
        id: 'cover:${cat.name}',
        sourceId: 'cover',
        thumbUrl: cached.thumbUrl,
        fullUrl: cached.fullUrl,
        width: 0,
        height: 0,
      );
    }
  }

  final result = await repo.fetchMerged(
    enabledSourceIds: settings.enabledSources,
    query: FeedQuery(
      kind: FeedKind.category,
      category: cat.name,
      sfwOnly: settings.sfwOnly,
      seed: 'browse-$seed',
    ),
    page: 1,
    // Always force a fresh fetch when the seed changes, otherwise the
    // repository would happily return the same cached page back to us.
    forceRefresh: true,
  );
  if (result.items.isEmpty) return null;
  // Pick a random item from the first page rather than always items[0],
  // so neighbouring categories don't all show the very first hit from
  // the merged feed.
  final rand = Random(args.hashCode ^ seed);
  final picked = result.items[rand.nextInt(result.items.length)];

  // Persist the fresh pick so the next visit to Browse renders this
  // image instantly (CachedNetworkImage will already have it on disk).
  unawaited(settings.setCachedCategoryCover(
    cat.name,
    thumbUrl: picked.thumbUrl,
    fullUrl: picked.fullUrl,
  ));
  return picked;
});

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  // Bumped on every refresh so each `_categoryPreviewProvider` family entry
  // re-fetches with a fresh seed instead of returning the same hero image.
  int _previewSeed = 0;

  Future<void> _refresh() async {
    // Drop the entire warm cache so every Browse card and any open feed
    // pages will go back to the network on next read. Also wipe the
    // persisted cover thumbnails so the bumped seed actually fetches
    // (otherwise the disk-cache check in `_categoryPreviewProvider`
    // would short-circuit before the network call).
    ref.read(repositoryProvider).clearCache();
    await ref.read(settingsProvider).clearCategoryCovers();
    if (!mounted) return;
    setState(() => _previewSeed++);
    // Re-evaluate every per-category preview thumbnail (old keys).
    for (final c in AppCategory.values) {
      ref.invalidate(_categoryPreviewProvider((c, _previewSeed - 1)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final scheme = Theme.of(context).colorScheme;
    final categories = AppCategory.values;
    // Hex values are taken directly from Wallhaven's fixed 28-colour
    // palette so taps map 1:1 to a colour bucket on the backend (no nearest
    // -neighbour snapping needed). Picked one representative per hue so
    // the row reads as a clean spectrum rather than 28 micro-variations.
    final colors = const [
      ('#000000', 'Black'),
      ('#ffffff', 'White'),
      ('#cc0000', 'Red'),
      ('#ff9900', 'Orange'),
      ('#ffff00', 'Yellow'),
      ('#669900', 'Green'),
      ('#66cccc', 'Teal'),
      ('#0066cc', 'Blue'),
      ('#993399', 'Lilac'),
      ('#ea4c88', 'Pink'),
    ];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          children: [
            PageHeader(
              eyebrow: 'discover',
              title: 'Browse',
              subtitle: 'Curated buckets across all enabled sources.',
              actions: [
                HeaderIconBtn(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh',
                  onTap: _refresh,
                ),
              ],
            ),
            const SectionLabel('Categories'),
            Padding(
              padding: const EdgeInsets.fromLTRB(Tk.lg, 0, Tk.lg, Tk.lg),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: Tk.md,
                crossAxisSpacing: Tk.md,
                childAspectRatio: 16 / 9,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final c in categories)
                    _CategoryCard(
                      category: c,
                      previewSeed: _previewSeed,
                      label: c.label,
                      onTap: () {
                        // Read settings synchronously at tap-time so the
                        // route builder closure doesn't call `ref.read`
                        // during transitions — ref may belong to a
                        // deactivated widget by the time the builder is
                        // re-invoked on pop/push animations.
                        final sfw = ref.read(settingsProvider).sfwOnly;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _FeedPage(
                              title: c.label,
                              query: FeedQuery(
                                kind: FeedKind.category,
                                category: c.name,
                                sfwOnly: sfw,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SectionLabel('Colors'),
            Padding(
              padding: const EdgeInsets.fromLTRB(Tk.lg, 0, Tk.lg, Tk.xl),
              child: GridView.count(
                crossAxisCount: 5,
                mainAxisSpacing: Tk.md,
                crossAxisSpacing: Tk.md,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 0.78,
                children: [
                  for (final c in colors)
                    _ColorSwatch(
                      color: Color(int.parse(c.$1.replaceFirst('#', '0xFF'))),
                      label: c.$2,
                      onTap: () {
                        final sfw = ref.read(settingsProvider).sfwOnly;
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _FeedPage(
                              title: c.$2,
                              query: FeedQuery(
                                kind: FeedKind.color,
                                colorHex: c.$1,
                                sfwOnly: sfw,
                              ),
                            ),
                          ),
                        );
                      },
                      scheme: scheme,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({
    required this.category,
    required this.previewSeed,
    required this.label,
    required this.onTap,
  });
  final AppCategory category;
  final int previewSeed;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final preview = ref.watch(_categoryPreviewProvider((category, previewSeed)));
    final wp = preview.asData?.value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tk.radLg),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Tk.radLg),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.30),
              width: Tk.hairline,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Subtle shimmer placeholder while the preview thumbnail
              // resolves \u2014 makes the empty state feel intentional rather
              // than broken when sources are slow.
              if (wp == null && preview.isLoading)
                Shimmer.fromColors(
                  baseColor: scheme.surfaceContainerHighest,
                  highlightColor: scheme.surfaceContainerHighest
                      .withValues(alpha: 0.55),
                  child: Container(color: scheme.surfaceContainerHighest),
                ),
              if (wp != null)
                NetworkImageWithFallback(
                  url: wp.thumbUrl,
                  fit: BoxFit.cover,
                ),
              // Bottom-up gradient anchors the label text against any photo.
              if (wp != null)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x00000000),
                        Color(0x33000000),
                        Color(0xCC000000),
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(Tk.md),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    label,
                    style: Tk.h2(
                        wp != null ? Colors.white : scheme.onSurface),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aesthetic color swatch used in the Browse → Colors section.
///
/// A rounded-square chip with the colour filling the body, a subtle white
/// inner highlight (top-left) for depth, a hairline outer border tuned to
/// the swatch's luminance, plus a small all-caps label underneath. The
/// rounded-square shape rhymes with the Category cards above so the page
/// feels like one coherent grid rather than a row of mismatched dots.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.color,
    required this.label,
    required this.onTap,
    required this.scheme,
  });
  final Color color;
  final String label;
  final VoidCallback onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final lum = color.computeLuminance();
    final isLight = lum > 0.6;
    final isVeryDark = lum < 0.05;
    final borderColor = isLight
        ? Colors.black.withValues(alpha: 0.18)
        : isVeryDark
            ? scheme.outlineVariant.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.18);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tk.radMd),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Tk.radMd),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(color, Colors.white, 0.10) ?? color,
                    color,
                    Color.lerp(color, Colors.black, 0.18) ?? color,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: isVeryDark
                    ? null
                    : [
                        BoxShadow(
                          color: color.withValues(alpha: 0.28),
                          blurRadius: 14,
                          spreadRadius: -4,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              // Tiny inner highlight to give the chip a hint of glassy
              // depth without making it look like a 3D button.
              child: Align(
                alignment: const Alignment(-0.55, -0.55),
                child: FractionallySizedBox(
                  widthFactor: 0.45,
                  heightFactor: 0.18,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(
                              alpha: isLight ? 0.35 : 0.18),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Tk.xs + 2),
          Text(
            label.toUpperCase(),
            style: Tk.tiny(scheme.outline).copyWith(letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }
}

class _FeedPage extends ConsumerStatefulWidget {
  const _FeedPage({required this.title, required this.query});
  final String title;
  final FeedQuery query;

  @override
  ConsumerState<_FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<_FeedPage> {
  // Bumped on every refresh tap; used to (a) re-seed the FeedQuery so
  // sources that randomise on `seed` surface fresh results and (b) force
  // the WallpaperGrid to rebuild from page one via its ValueKey.
  int _nonce = 0;
  // Optional per-feed source narrowing. Same contract as Home/Search:
  // `null` means "use every source the user has globally enabled".
  Set<String>? _sourceFilter;

  void _refresh() {
    ref.read(repositoryProvider).clearCacheFor(widget.query);
    setState(() => _nonce++);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing\u2026'),
        duration: Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final sources = ref.watch(sourcesProvider);
    final enabled = sources
        .where((s) => settings.enabledSources.contains(s.id))
        .toList();
    if (_sourceFilter != null) {
      final ids = enabled.map((s) => s.id).toSet();
      final pruned = _sourceFilter!.intersection(ids);
      if (pruned.isEmpty || pruned.length == enabled.length) {
        _sourceFilter = null;
      } else if (pruned.length != _sourceFilter!.length) {
        _sourceFilter = pruned;
      }
    }

    final q = _nonce == 0
        ? widget.query
        : widget.query.copyWith(seed: 'feed-${widget.query.cacheKey}-$_nonce');
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(widget.title.toUpperCase(),
            style: Tk.label(scheme.onSurface).copyWith(fontSize: 11)),
        actions: [
          if (enabled.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: Tk.sm),
              child: HeaderIconBtn(
                icon: Icons.filter_list_rounded,
                tooltip: 'Choose sources',
                badge: _sourceFilter != null,
                onTap: () async {
                  final result = await showSourceFilterSheet(
                    context: context,
                    enabled: enabled,
                    current: _sourceFilter,
                  );
                  if (!mounted || result == null) return;
                  setState(() {
                    _sourceFilter = result.length == enabled.length
                        ? null
                        : result;
                  });
                },
              ),
            ),
          // Hairline refresh chip \u2014 same control style used on
          // Browse and Home headers so the affordance reads as consistent
          // across the app.
          Padding(
            padding: const EdgeInsets.only(right: Tk.md),
            child: HeaderIconBtn(
              icon: Icons.refresh_rounded,
              onTap: _refresh,
            ),
          ),
        ],
      ),
      body: WallpaperGrid(
        key: ValueKey(
            'feed-${widget.query.cacheKey}-${_sourceFilter == null ? "all" : (_sourceFilter!.toList()..sort()).join(",")}-$_nonce'),
        sourceFilter: _sourceFilter,
        query: q,
      ),
    );
  }
}
