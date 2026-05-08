import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wolwoloom/wolwoloom.dart';

/// Persistent bottom-nav shell that sits underneath every top-level tab
/// (Home, Search, Browse, Saved, Settings).
///
/// The nav bar itself is now `WlmBottomNav` from the wolwoloom design
/// system. Tab geometry and labels stay identical to the previous
/// hand-rolled implementation — it's the same shape (extracted from
/// this app) just sourced from the package.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  static const _routes = <String>[
    '/',
    '/search',
    '/categories',
    '/favorites',
    '/settings',
  ];

  static const _items = <WlmNavItem>[
    WlmNavItem(
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      label: 'Home',
    ),
    WlmNavItem(
      icon: Icons.search_outlined,
      activeIcon: Icons.search_rounded,
      label: 'Search',
    ),
    WlmNavItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore_rounded,
      label: 'Browse',
    ),
    WlmNavItem(
      icon: Icons.bookmark_outline_rounded,
      activeIcon: Icons.bookmark_rounded,
      label: 'Saved',
    ),
    WlmNavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  int _indexFor(String location) {
    for (var i = 0; i < _routes.length; i++) {
      if (location == _routes[i]) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    final index = _indexFor(loc);

    return Scaffold(
      body: child,
      bottomNavigationBar: WlmBottomNav(
        items: _items,
        currentIndex: index,
        onTap: (i) {
          // Categories drills down via raw `Navigator.push(MaterialPageRoute)`
          // (so CategoriesPage doesn't have to know about go_router for
          // every sub-feed). Those pushed routes sit on top of the
          // ShellRoute's Navigator stack — if we just call `go(...)`
          // here, the shell child swaps underneath but the pushed page
          // stays visible. Pop everything down to the shell root before
          // navigating so the chosen tab actually shows.
          final nav = Navigator.of(context);
          nav.popUntil((r) => r.isFirst);
          context.go(_routes[i]);
        },
      ),
    );
  }
}
