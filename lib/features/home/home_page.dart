import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/models/feed_query.dart';
import '../../data/sources/wallpaper_source.dart';
import '../common/page_header.dart';
import '../common/source_filter_sheet.dart';
import '../common/wallpaper_grid.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  // Three curated entry points into the catalog. We deliberately collapsed
  // the older 4-tab layout (Curated/Trending/4K/Surprise) into these three
  // because in practice Curated and Trending overlap heavily for every
  // source, which made the choice feel arbitrary. The mapping below picks
  // the highest-signal FeedKind for each label:
  //   • AMOLED    → dark/amoled category (default — most-requested look)
  //   • Trending  → each source's editorial / toplist feed (`curated`)
  //   • Surprise  → randomised pull (`random`)
  //   • High-Res  → 4K-only filter (`fourK`)
  //
  // Tabs are (FeedKind, optional category, label). The category slot is
  // only used when kind == FeedKind.category.
  static const _kinds = <_HomeTab>[
    _HomeTab(FeedKind.curated, null, 'Trending'),
    _HomeTab(FeedKind.category, 'amoled', 'AMOLED'),
    _HomeTab(FeedKind.random, null, 'Surprise'),
    _HomeTab(FeedKind.fourK, null, 'High-Res'),
  ];

  // Default landing tab \u2014 Trending (each source's editorial / toplist).
  _HomeTab _tab = _kinds.first;
  // Subset of source IDs to include in the grid. `null` = use every source
  // the user has globally enabled in Settings (the default — "all sources").
  // Non-null restricts to that explicit set, allowing the user to mix and
  // match (e.g. "Wallhaven + Pixabay only, hide Reddit") without touching
  // their global Settings.
  Set<String>? _sourceFilter;
  // Bumped whenever the user explicitly asks for a refresh (button tap or
  // pull-to-refresh re-trigger). Folded into the grid's ValueKey so a fresh
  // PagingController is created with a new random seed.
  int _refreshNonce = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final sources = ref.watch(sourcesProvider);
    final enabled =
        sources.where((s) => settings.enabledSources.contains(s.id)).toList();

    if (enabled.isEmpty) {
      return _EmptyNoSources(onOpenSettings: () => context.go('/settings'));
    }

    if (_sourceFilter != null) {
      // Drop any IDs no longer in the enabled set so the filter stays valid
      // when sources are toggled in Settings.
      final enabledIds = enabled.map((s) => s.id).toSet();
      final pruned = _sourceFilter!.intersection(enabledIds);
      if (pruned.isEmpty || pruned.length == enabled.length) {
        _sourceFilter = null;
      } else if (pruned.length != _sourceFilter!.length) {
        _sourceFilter = pruned;
      }
    }

    final activeSourceLabel = _sourceFilter == null
        ? '${enabled.length} sources · merged'
        : _sourceFilter!.length == 1
            ? enabled.firstWhere((s) => s.id == _sourceFilter!.first).displayName
            : '${_sourceFilter!.length} sources · merged';

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            eyebrow: 'wallpapers',
            title: 'wolwo',
            subtitle: activeSourceLabel,
            actions: [
              HeaderIconBtn(
                icon: Icons.refresh_rounded,
                tooltip: 'Refresh',
                onTap: () {
                  // Drop the warm cache for the active feed query so the
                  // grid re-fetches from the network instead of replaying
                  // the same cached page after the nonce bump.
                  ref.read(repositoryProvider).clearCache();
                  setState(() => _refreshNonce++);
                },
              ),
              if (enabled.length > 1)
                HeaderIconBtn(
                  icon: Icons.filter_list_rounded,
                  tooltip: 'Choose sources',
                  badge: _sourceFilter != null,
                  onTap: () => _openSourceSheet(context, enabled),
                ),
              HeaderIconBtn(
                icon: Icons.info_outline_rounded,
                tooltip: 'About',
                onTap: () => context.push('/about'),
              ),
            ],
          ),
          _KindBar(
            kinds: _kinds,
            selected: _tab,
            onChanged: (t) => setState(() => _tab = t),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: Tk.lg),
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.20),
          ),
          Expanded(
            child: WallpaperGrid(
              key: ValueKey(
                  '${_tab.kind.name}-${_tab.category ?? "-"}-${_sourceFilter == null ? "all" : (_sourceFilter!.toList()..sort()).join(",")}-${settings.sfwOnly}-$_refreshNonce',),
              sourceFilter: _sourceFilter,
              query: FeedQuery(
                kind: _tab.kind,
                category: _tab.category,
                sfwOnly: settings.sfwOnly,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSourceSheet(
      BuildContext context, List<WallpaperSource> enabled,) async {
    final result = await showSourceFilterSheet(
      context: context,
      enabled: enabled,
      current: _sourceFilter,
    );
    if (!mounted || result == null) return;
    setState(() {
      _sourceFilter =
          result.length == enabled.length ? null : result;
    });
  }
}

class _KindBar extends StatelessWidget {
  const _KindBar({
    required this.kinds,
    required this.selected,
    required this.onChanged,
  });
  final List<_HomeTab> kinds;
  final _HomeTab selected;
  final ValueChanged<_HomeTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding:
          const EdgeInsets.fromLTRB(Tk.lg, Tk.sm, Tk.lg, Tk.sm),
      child: Row(
        children: [
          for (final k in kinds)
            Padding(
              padding: const EdgeInsets.only(right: Tk.xs + 2),
              child: _KindPill(
                label: k.label,
                selected: selected == k,
                onTap: () => onChanged(k),
                accent: scheme.primary,
              ),
            ),
        ],
      ),
    );
  }
}

class _KindPill extends StatelessWidget {
  const _KindPill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accent,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tk.radMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
            horizontal: Tk.md, vertical: Tk.sm,),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(Tk.radMd),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.65)
                : scheme.outlineVariant.withValues(alpha: 0.25),
            width: Tk.hairline,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: Tk.tiny(selected ? scheme.onSurface : scheme.outline)
                  .copyWith(
                fontSize: 11,
                letterSpacing: 1.0,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const SizedBox(height: Tk.xs),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: selected ? 16 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One row in the home page's tab bar. Holds the FeedKind plus, for the
/// AMOLED tab, the category slug used when kind == FeedKind.category.
@immutable
class _HomeTab {
  const _HomeTab(this.kind, this.category, this.label);
  final FeedKind kind;
  final String? category;
  final String label;
}

class _EmptyNoSources extends StatelessWidget {
  const _EmptyNoSources({required this.onOpenSettings});
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(Tk.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.layers_clear_outlined,
                  size: 36, color: scheme.outline,),
              const SizedBox(height: Tk.md),
              Text('NO SOURCES ENABLED', style: Tk.label(scheme.outline)),
              const SizedBox(height: Tk.sm),
              Text(
                'Turn on at least one wallpaper source in Settings to see images here.',
                textAlign: TextAlign.center,
                style: Tk.bodySmall(scheme.outline),
              ),
              const SizedBox(height: Tk.lg),
              FilledButton.tonal(
                onPressed: onOpenSettings,
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.surfaceContainerHighest,
                  foregroundColor: scheme.onSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Tk.radMd),
                    side: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: 0.30),
                    ),
                  ),
                ),
                child: Text('Open Settings',
                    style: Tk.bodySmall(scheme.onSurface),),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
