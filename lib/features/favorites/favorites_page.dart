import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:wolwoloom/wolwoloom.dart';

import '../../app/providers.dart';
import '../../core/theme/design_tokens.dart';
import '../common/wallpaper_tile.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesProvider);
    final n = favs.items.length;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WlmPageHeader(
            eyebrow: 'collection',
            title: 'Saved',
            subtitle: n == 0
                ? 'Bookmarks live here.'
                : '$n wallpaper${n == 1 ? '' : 's'}',
          ),
          Expanded(
            child: favs.items.isEmpty
                ? Center(
                    child: WlmEmptyState(
                      eyebrow: 'nothing saved yet',
                      title: 'Save a favourite',
                      icon: Icons.bookmark_outline_rounded,
                      body:
                          'Tap the heart on any wallpaper to save it here.',
                      action: WlmSecondaryButton(
                        label: 'Browse wallpapers',
                        uppercase: false,
                        onPressed: () => context.go('/'),
                      ),
                    ),
                  )
                : MasonryGridView.count(
                    padding: const EdgeInsets.fromLTRB(
                        Tk.md, Tk.sm, Tk.md, Tk.lg,),
                    crossAxisCount: 2,
                    mainAxisSpacing: Tk.sm + 2,
                    crossAxisSpacing: Tk.sm + 2,
                    itemCount: favs.items.length,
                    itemBuilder: (_, i) {
                      final w = favs.items[i];
                      return WallpaperTile(
                        wallpaper: w,
                        onTap: () => context
                            .push('/detail', extra: {'wallpaper': w}),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
