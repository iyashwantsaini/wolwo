import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/net/image_proxy.dart';
import '../../core/net/network_image_with_fallback.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/models/wallpaper.dart';

/// A single wallpaper tile used inside the staggered grid.
class WallpaperTile extends StatefulWidget {
  const WallpaperTile({
    super.key,
    required this.wallpaper,
    required this.onTap,
    this.onLongPress,
    this.showSourceBadge = true,
  });

  final Wallpaper wallpaper;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// Tiny mono badge in the bottom-left corner showing the source
  /// (`WH`, `RD`, `NASA`, `PX`). Helps the user spot which providers
  /// surface the good stuff so they can prune in Settings.
  final bool showSourceBadge;

  @override
  State<WallpaperTile> createState() => _WallpaperTileState();
}

class _WallpaperTileState extends State<WallpaperTile> {
  bool _failed = false;
  bool _hiResReady = false;

  /// Hi-res URL to layer on top of the thumb. We deliberately prefer the
  /// `previewUrl` (a mid-to-large rendition, typically 1080p–2K) over the
  /// `fullUrl` here — the full image can be 30–100MB on hosts like NASA,
  /// which would never finish downloading inside a 200px grid cell. The
  /// detail page is responsible for loading the actual full-resolution
  /// image when the user opens a wallpaper.
  String? get _hiResUrl {
    final p = widget.wallpaper.previewUrl;
    if (p != null && p.isNotEmpty && p != widget.wallpaper.thumbUrl) return p;
    final f = widget.wallpaper.fullUrl;
    if (f.isNotEmpty && f != widget.wallpaper.thumbUrl) return f;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = widget.wallpaper.colorHex != null
        ? Color(int.parse(
            widget.wallpaper.colorHex!.replaceFirst('#', '0xFF'),),)
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    // If every fallback proxy failed, hide the tile entirely so the grid
    // doesn't show broken-image icons. The masonry layout will reflow.
    if (_failed) return const SizedBox.shrink();

    final hi = _hiResUrl;
    // Bad-host URLs (NASA, Wallhaven, Reddit on web) render via a native
    // `<img>` inside an HtmlElementView. Platform views in CanvasKit are
    // composited by the browser, not by Flutter — which means Flutter's
    // `Opacity` / `AnimatedOpacity` have no effect on them. If we kept the
    // fade-in path, the preview layer would stay invisible forever and
    // the user would see nothing (NASA's exact bug). For these hosts we
    // skip the fade and reveal the preview immediately at full opacity.
    final hiUsesHtmlImg = hi != null && ImageProxy.isBadHost(hi);

    return Hero(
      tag: 'wp-${widget.wallpaper.globalKey}',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: widget.wallpaper.aspectRatio == 0
              ? 9 / 16
              : widget.wallpaper.aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Layer 1 \u2014 fast, low-res thumb. Always shown so the tile
              // never sits blank while the bigger image streams in.
              ColoredBox(
                color: placeholder,
                child: NetworkImageWithFallback(
                  url: widget.wallpaper.thumbUrl,
                  fit: BoxFit.cover,
                  placeholder: (_) => Shimmer.fromColors(
                    baseColor: placeholder,
                    highlightColor: placeholder.withValues(alpha: 0.6),
                    child: Container(color: placeholder),
                  ),
                  onAllFailed: () {
                    if (mounted && !_failed) {
                      setState(() => _failed = true);
                    }
                  },
                ),
              ),
              // Layer 2 \u2014 hi-res preview, fades in once decoded. This is
              // what gives the grid the "loads blurry then sharpens"
              // progressive feel without paying the full-resolution cost.
              if (hi != null)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: (hiUsesHtmlImg || _hiResReady) ? 1.0 : 0.0,
                  child: NetworkImageWithFallback(
                    url: hi,
                    fit: BoxFit.cover,
                    fadeIn: Duration.zero,
                    placeholder: (_) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && !_hiResReady) {
                          setState(() => _hiResReady = true);
                        }
                      });
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              // Gesture layer ON TOP of the (possibly platform-view) image
              // so taps always reach Flutter, never the native <img>.
              Positioned.fill(
                child: Material(
                  color: const Color(0x00000000),
                  child: InkWell(
                    onTap: widget.onTap,
                    onLongPress: widget.onLongPress,
                    splashColor: Colors.white.withValues(alpha: 0.08),
                    highlightColor: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              if (widget.showSourceBadge)
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: IgnorePointer(
                    child: _SourcePill(sourceId: widget.wallpaper.sourceId),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tiny mono badge identifying which source this wallpaper came from.
/// Sits in the bottom-left corner with a translucent ink chip so it
/// stays legible on both light and dark imagery.
class _SourcePill extends StatelessWidget {
  const _SourcePill({required this.sourceId});
  final String sourceId;

  String get _label {
    switch (sourceId) {
      case 'wallhaven':
        return 'WH';
      case 'reddit':
        return 'RD';
      case 'nasa':
        return 'NASA';
      case 'pixabay':
        return 'PX';
      default:
        return sourceId.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xCC000000),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 0.6,
        ),
      ),
      child: Text(
        _label,
        style: Tk.tiny(Colors.white).copyWith(
          fontSize: 8.5,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
