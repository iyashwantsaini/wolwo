import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/design_tokens.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  /// Tabs: outlined inactive icon + filled active icon, with a
  /// hairline-bordered top edge. Labels are mono ALL-CAPS and very small.
  static const _tabs = [
    _Tab('/', Icons.grid_view_outlined, Icons.grid_view_rounded, 'Home'),
    _Tab('/search', Icons.search_outlined, Icons.search_rounded, 'Search'),
    _Tab('/categories', Icons.explore_outlined, Icons.explore_rounded,
        'Browse',),
    _Tab('/favorites', Icons.bookmark_outline_rounded, Icons.bookmark_rounded,
        'Saved',),
    _Tab('/settings', Icons.settings_outlined, Icons.settings_rounded,
        'Settings',),
  ];

  int _indexFor(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i].path) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final loc = GoRouterState.of(context).uri.toString();
    final index = _indexFor(loc);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.30),
              width: Tk.hairline,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _TabItem(
                      tab: _tabs[i],
                      selected: i == index,
                      onTap: () {
                        // Categories drills down via raw
                        // `Navigator.push(MaterialPageRoute)` (so the
                        // CategoriesPage doesn't have to know about
                        // go_router for every sub-feed). Those pushed
                        // routes sit on top of the ShellRoute's
                        // Navigator stack \u2014 if we just call `go(...)`
                        // here, the shell child swaps underneath but the
                        // pushed page stays visible (saved-tab is
                        // highlighted but you still see City). Pop
                        // everything down to the shell root before
                        // navigating so the chosen tab actually shows.
                        final nav = Navigator.of(context);
                        nav.popUntil((r) => r.isFirst);
                        context.go(_tabs[i].path);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });
  final _Tab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = selected ? scheme.onSurface : scheme.outline;
    return InkWell(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: Tk.sm + 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected ? tab.selectedIcon : tab.icon,
                    size: 20, color: fg,),
                const SizedBox(height: Tk.xs),
                Text(
                  tab.label.toUpperCase(),
                  style: Tk.tiny(fg).copyWith(
                    fontSize: 9,
                    letterSpacing: 1.0,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Positioned(
              top: 0,
              child: Container(
                width: 22,
                height: 2,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tab {
  const _Tab(this.path, this.icon, this.selectedIcon, this.label);
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
