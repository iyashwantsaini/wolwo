import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../core/theme/design_tokens.dart';
import '../common/page_header.dart';
import '../common/wallpaper_tile.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final favs = ref.watch(favoritesProvider);
    final n = favs.items.length;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            eyebrow: 'collection',
            title: 'Saved',
            subtitle: n == 0
                ? 'Bookmarks live here.'
                : '$n wallpaper${n == 1 ? '' : 's'}',
          ),
          Expanded(
            child: favs.items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Tk.xxl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bookmark_outline_rounded,
                              size: 36, color: scheme.outline,),
                          const SizedBox(height: Tk.md),
                          Text('NOTHING SAVED YET',
                              style: Tk.label(scheme.outline),),
                          const SizedBox(height: Tk.sm),
                          Text(
                            'Tap the heart on any wallpaper to save it here.',
                            textAlign: TextAlign.center,
                            style: Tk.bodySmall(scheme.outline),
                          ),
                          const SizedBox(height: Tk.lg),
                          FilledButton.tonal(
                            onPressed: () => context.go('/'),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  scheme.surfaceContainerHighest,
                              foregroundColor: scheme.onSurface,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(Tk.radMd),
                                side: BorderSide(
                                  color: scheme.outlineVariant
                                      .withValues(alpha: 0.30),
                                ),
                              ),
                            ),
                            child: Text('Browse wallpapers',
                                style: Tk.bodySmall(scheme.onSurface),),
                          ),
                        ],
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
