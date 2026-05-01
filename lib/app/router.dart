import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/models/wallpaper.dart';
import '../features/about/about_page.dart';
import '../features/categories/categories_page.dart';
import '../features/detail/wallpaper_detail_page.dart';
import '../features/favorites/favorites_page.dart';
import '../features/home/home_page.dart';
import '../features/onboarding/onboarding_page.dart';
import '../features/search/search_page.dart';
import '../features/settings/settings_page.dart';
import '../features/shell/app_shell.dart';

/// Build the app router. Takes a `getOnboardingDone` thunk so that the
/// redirect re-evaluates on every navigation \u2014 this lets `OnboardingPage`
/// flip the flag to true and call `context.go('/')` without the redirect
/// kicking the user back to /welcome.
GoRouter buildRouter({required bool Function() getOnboardingDone}) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final done = getOnboardingDone();
      final atWelcome = state.matchedLocation == '/welcome';
      if (!done && !atWelcome) return '/welcome';
      if (done && atWelcome) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/welcome',
        pageBuilder: (c, s) => const NoTransitionPage(child: OnboardingPage()),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (c, s) => const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (c, s) {
              // Optional ?q= seeds the search field on arrival, so tag
              // chips on the detail page can deep-link straight into a
              // query without round-tripping through the home tab.
              final q = s.uri.queryParameters['q']?.trim();
              return NoTransitionPage(
                child: SearchPage(initialQuery: q?.isEmpty ?? true ? null : q),
              );
            },
          ),
          GoRoute(
            path: '/categories',
            pageBuilder: (c, s) =>
                const NoTransitionPage(child: CategoriesPage()),
          ),
          GoRoute(
            path: '/favorites',
            pageBuilder: (c, s) => const NoTransitionPage(child: FavoritesPage()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (c, s) => const NoTransitionPage(child: SettingsPage()),
          ),
        ],
      ),
      GoRoute(
        path: '/detail',
        pageBuilder: (c, s) {
          // `extra` survives in-process navigation but is lost on a
          // browser refresh / hot restart (GoRouter has nothing to
          // rehydrate it from). It can also come back as a plain JSON
          // map if the framework round-trips it through history state.
          // Handle all three shapes; fall back to home if there's
          // nothing usable rather than crashing with a type error.
          final extra = s.extra;
          Wallpaper? w;
          if (extra is Map) {
            final raw = extra['wallpaper'];
            if (raw is Wallpaper) {
              w = raw;
            } else if (raw is Map) {
              try {
                w = Wallpaper.fromJson(Map<String, dynamic>.from(raw));
              } catch (_) {
                w = null;
              }
            }
          }
          if (w == null) {
            return const NoTransitionPage(child: AppShell(child: HomePage()));
          }
          return MaterialPage(
            fullscreenDialog: true,
            child: WallpaperDetailPage(wallpaper: w),
          );
        },
      ),
      GoRoute(
        path: '/about',
        builder: (c, s) => const AboutPage(),
      ),
    ],
  );
}
