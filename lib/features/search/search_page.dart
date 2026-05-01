import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/models/feed_query.dart';
import '../common/page_header.dart';
import '../common/source_filter_sheet.dart';
import '../common/wallpaper_grid.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key, this.initialQuery});

  /// When non-null, the search field is seeded with this string and a
  /// search runs immediately. Used by tag chips on the detail page.
  final String? initialQuery;

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  String _query = '';
  Timer? _debounce;
  // Same source-filter contract as HomePage: `null` means "merge all
  // globally-enabled sources"; non-null restricts to the chosen subset.
  Set<String>? _sourceFilter;
  // Bumped on refresh tap; folded into the WallpaperGrid ValueKey so
  // the grid throws away its PagingController and starts a fresh
  // request with a new seed.
  int _refreshNonce = 0;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onTextChanged);
    final seed = widget.initialQuery?.trim();
    if (seed != null && seed.isNotEmpty) {
      _ctrl.text = seed;
      _query = seed;
      // Persist so it shows up in the recent-queries strip too.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(settingsProvider).pushSearchQuery(seed);
      });
    }
  }

  void _onTextChanged() {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      final next = _ctrl.text.trim();
      if (next != _query) {
        setState(() => _query = next);
        if (next.isNotEmpty) {
          // Persist on every committed query (debounce already gates this
          // to avoid storing every keystroke). Cheap fire-and-forget.
          ref.read(settingsProvider).pushSearchQuery(next);
        }
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.removeListener(_onTextChanged);
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final sources = ref.watch(sourcesProvider);
    final enabled =
        sources.where((s) => settings.enabledSources.contains(s.id)).toList();

    // Drop stale IDs if the user toggled sources in Settings.
    if (_sourceFilter != null) {
      final ids = enabled.map((s) => s.id).toSet();
      final pruned = _sourceFilter!.intersection(ids);
      if (pruned.isEmpty || pruned.length == enabled.length) {
        _sourceFilter = null;
      } else if (pruned.length != _sourceFilter!.length) {
        _sourceFilter = pruned;
      }
    }

    final activeSourceLabel = _sourceFilter == null
        ? '${enabled.length} sources \u00b7 merged'
        : _sourceFilter!.length == 1
            ? enabled
                .firstWhere((s) => s.id == _sourceFilter!.first)
                .displayName
            : '${_sourceFilter!.length} sources \u00b7 merged';

    return SafeArea(
      child: Column(
        children: [
          PageHeader(
            eyebrow: 'find',
            title: 'Search',
            subtitle: activeSourceLabel,
            actions: [
              if (_query.isNotEmpty)
                HeaderIconBtn(
                  icon: Icons.refresh_rounded,
                  tooltip: 'Refresh',
                  onTap: () {
                    ref.read(repositoryProvider).clearCache();
                    setState(() => _refreshNonce++);
                  },
                ),
              if (enabled.length > 1)
                HeaderIconBtn(
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
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Tk.lg, Tk.sm, Tk.lg, Tk.sm),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Tk.radMd),
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: 0.30),
                  width: Tk.hairline,
                ),
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Tk.md, 0, Tk.sm, 0),
                    child: Icon(Icons.search_rounded,
                        color: scheme.outline, size: 18),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      style: Tk.body(scheme.onSurface),
                      cursorColor: scheme.primary,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: Tk.md),
                        border: InputBorder.none,
                        hintText: 'Search wallpapers',
                        hintStyle: Tk.body(scheme.outline),
                      ),
                      onSubmitted: (v) {
                        _debounce?.cancel();
                        final t = v.trim();
                        setState(() => _query = t);
                        if (t.isNotEmpty) {
                          ref.read(settingsProvider).pushSearchQuery(t);
                        }
                      },
                    ),
                  ),
                  if (_ctrl.text.isNotEmpty)
                    InkWell(
                      onTap: () {
                        _ctrl.clear();
                        setState(() => _query = '');
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(Tk.sm + 2),
                        child: Icon(Icons.close_rounded,
                            color: scheme.outline, size: 16),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _query.isEmpty
                ? _SearchEmpty(
                    history: settings.searchHistory,
                    onPick: (s) {
                      _ctrl.text = s;
                      _debounce?.cancel();
                      setState(() => _query = s);
                      ref.read(settingsProvider).pushSearchQuery(s);
                    },
                    onClearHistory: () =>
                        ref.read(settingsProvider).clearSearchHistory(),
                  )
                : WallpaperGrid(
                    key: ValueKey(
                        '$_query-${_sourceFilter == null ? "all" : (_sourceFilter!.toList()..sort()).join(",")}-$_refreshNonce'),
                    sourceFilter: _sourceFilter,
                    query: FeedQuery(
                      kind: FeedKind.search,
                      text: _query,
                      sfwOnly: settings.sfwOnly,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchEmpty extends StatelessWidget {
  const _SearchEmpty({
    required this.history,
    required this.onPick,
    required this.onClearHistory,
  });
  final List<String> history;
  final ValueChanged<String> onPick;
  final VoidCallback onClearHistory;

  static const _suggestions = [
    'Nature', 'Mountains', 'Ocean', 'Forest',
    'Galaxy', 'Nebula', 'Minimal', 'Dark',
    'Cyberpunk', 'Anime', 'Cars', 'Abstract',
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Tk.lg, Tk.md, Tk.lg, Tk.lg),
      children: [
        if (history.isNotEmpty) ...[
          Row(
            children: [
              Text('RECENT', style: Tk.label(scheme.outline)),
              const Spacer(),
              GestureDetector(
                onTap: onClearHistory,
                child: Text('CLEAR', style: Tk.label(scheme.outline)),
              ),
            ],
          ),
          const SizedBox(height: Tk.md),
          Wrap(
            spacing: Tk.sm,
            runSpacing: Tk.sm,
            children: [
              for (final s in history)
                _Chip(label: s, onTap: () => onPick(s), filled: true),
            ],
          ),
          const SizedBox(height: Tk.xl),
        ],
        Text('TRY', style: Tk.label(scheme.outline)),
        const SizedBox(height: Tk.md),
        Wrap(
          spacing: Tk.sm,
          runSpacing: Tk.sm,
          children: [
            for (final s in _suggestions)
              _Chip(label: s, onTap: () => onPick(s), filled: false),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.onTap,
    required this.filled,
  });
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tk.radMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: Tk.md, vertical: Tk.sm),
        decoration: BoxDecoration(
          color: filled
              ? scheme.surfaceContainerHighest
              : Colors.transparent,
          borderRadius: BorderRadius.circular(Tk.radMd),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.30),
            width: Tk.hairline,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: Tk.tiny(scheme.onSurfaceVariant)
              .copyWith(fontSize: 11, letterSpacing: 1.0),
        ),
      ),
    );
  }
}
