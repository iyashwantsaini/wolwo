import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/models/wallpaper.dart';

/// Quick-action bottom sheet shown on long-press of a [WallpaperTile].
///
/// Keeps the heavy flows (download / set as / NASA full-resolution
/// manifest lookup) on the detail page where they belong, but exposes
/// the cheap actions inline so the user doesn't have to push and pop a
/// full screen for things like favouriting or copying a link.
Future<void> showWallpaperQuickActions(
  BuildContext context,
  WidgetRef ref,
  Wallpaper w,
) {
  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: scheme.surface,
    showDragHandle: true,
    isScrollControlled: false,
    builder: (ctx) {
      return _QuickActions(wallpaper: w);
    },
  );
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions({required this.wallpaper});
  final Wallpaper wallpaper;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final favs = ref.watch(favoritesProvider);
    final isFav = favs.isFavorite(wallpaper);
    final src = ref.read(repositoryProvider).sourceById(wallpaper.sourceId);

    void close() => Navigator.of(context).pop();
    void snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(milliseconds: 1400),
          ),
        );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Tk.lg, 0, Tk.lg, Tk.sm),
            child: Row(
              children: [
                Text(
                  (src?.displayName ?? wallpaper.sourceId).toUpperCase(),
                  style: Tk.label(scheme.outline),
                ),
                const Spacer(),
                Text(
                  '${wallpaper.width}\u00d7${wallpaper.height}',
                  style: Tk.tiny(scheme.outline),
                ),
              ],
            ),
          ),
          _ActionRow(
            icon: isFav
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            label: isFav ? 'Remove from favorites' : 'Add to favorites',
            onTap: () async {
              await favs.toggle(wallpaper);
              if (!context.mounted) return;
              close();
              snack(isFav ? 'Removed from favorites' : 'Added to favorites');
            },
          ),
          _ActionRow(
            icon: Icons.open_in_new_rounded,
            label: 'Open details',
            onTap: () {
              close();
              context.push('/detail', extra: {'wallpaper': wallpaper});
            },
          ),
          _ActionRow(
            icon: Icons.share_outlined,
            label: 'Share link',
            onTap: () async {
              close();
              final url = wallpaper.sourcePageUrl ?? wallpaper.fullUrl;
              await Share.share(url);
            },
          ),
          _ActionRow(
            icon: Icons.link_rounded,
            label: 'Copy image URL',
            onTap: () async {
              await Clipboard.setData(
                  ClipboardData(text: wallpaper.fullUrl),);
              if (!context.mounted) return;
              close();
              snack('Image URL copied');
            },
          ),
          if (wallpaper.sourcePageUrl != null)
            _ActionRow(
              icon: Icons.public_rounded,
              label: 'View on ${src?.displayName ?? "source"}',
              onTap: () async {
                close();
                await launchUrl(Uri.parse(wallpaper.sourcePageUrl!),
                    mode: LaunchMode.externalApplication,);
              },
            ),
          const SizedBox(height: Tk.sm),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Tk.lg, vertical: Tk.md,),
        child: Row(
          children: [
            Icon(icon, size: 20, color: scheme.onSurface),
            const SizedBox(width: Tk.lg),
            Expanded(
              child: Text(label, style: Tk.body(scheme.onSurface)),
            ),
          ],
        ),
      ),
    );
  }
}
