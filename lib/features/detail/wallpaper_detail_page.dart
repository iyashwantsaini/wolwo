import 'dart:io';
import 'dart:ui' as ui;

import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/net/image_cache_manager.dart';
import '../../core/net/image_proxy.dart';
import '../../core/net/network_image_with_fallback.dart';
import '../../data/local/app_settings.dart';
import '../../data/models/wallpaper.dart';
import '../../data/sources/nasa_source.dart';
import '../common/app_loader.dart';

// ── Design tokens ────────────────────────────────────────────────────────────
//
// Same opinionated system as the rest of the app:
//   - JetBrains-Mono everywhere (technical, terminal-feel)
//   - Solid surface cards with hairline 1px borders \u2014 NOT glassmorphism
//   - ALL-CAPS micro labels (10px, letter-spacing 1.2) for metadata
//   - Single accent color used sparingly (only on the primary affordance)
//   - 4 / 8 / 12 / 16 / 24 / 32 spacing scale

class _T {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;

  static TextStyle mono({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      );

  /// Signature `LABEL` micro-text \u2014 used for metadata captions.
  static TextStyle metaLabel(Color c) =>
      mono(size: 10, weight: FontWeight.w400, color: c, letterSpacing: 1.2);

  /// Body / value text accompanying a metaLabel.
  static TextStyle metaValue(Color c) =>
      mono(size: 13, weight: FontWeight.w400, color: c);

  /// Tiny caption shown under action-row icons.
  static TextStyle actionLabel(Color c) =>
      mono(size: 8, weight: FontWeight.w400, color: c, letterSpacing: 0.2);
}

/// `async_wallpaper` and `gallery_saver_plus` are Android-only. On web /
/// iOS / desktop we hide or disable those affordances rather than crash.
bool get _canSetWallpaper =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
bool get _canSaveToGallery =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

class WallpaperDetailPage extends ConsumerStatefulWidget {
  const WallpaperDetailPage({super.key, required this.wallpaper});
  final Wallpaper wallpaper;

  @override
  ConsumerState<WallpaperDetailPage> createState() =>
      _WallpaperDetailPageState();
}

class _WallpaperDetailPageState extends ConsumerState<WallpaperDetailPage> {
  bool _busy = false;

  // The image is wrapped in a RepaintBoundary so we can snapshot exactly
  // what the user sees (including zoom + pan) and apply it as wallpaper.
  final GlobalKey _viewportKey = GlobalKey();

  // InteractiveViewer drives pinch-to-zoom and pan. When the user taps the
  // +/− buttons we animate this controller's matrix.
  final TransformationController _txCtl = TransformationController();
  static const double _minScale = 1.0;
  static const double _maxScale = 4.0;

  bool _showHint = true;

  @override
  void dispose() {
    _txCtl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  Future<String> _resolveFullUrl() async {
    if (widget.wallpaper.sourceId == 'nasa') {
      final nasa = ref
          .read(sourcesProvider)
          .firstWhere((s) => s.id == 'nasa') as NasaSource;
      final resolved = await nasa.resolveFullUrl(widget.wallpaper.id);
      if (resolved != null && resolved.isNotEmpty) return resolved;
    }
    return widget.wallpaper.fullUrl;
  }

  Future<void> _setWallpaper(WallpaperTarget target) async {
    setState(() => _busy = true);
    try {
      // Capture exactly what the user sees — including the current zoom
      // and pan from InteractiveViewer — by snapshotting the RepaintBoundary
      // wrapped around the image viewport. This bakes the framing into a
      // PNG that perfectly matches the device's screen aspect ratio, so the
      // wallpaper looks identical to the in-app preview.
      final file = await _captureViewport();
      if (file == null) {
        // Fall back to the raw URL if snapshotting failed for any reason.
        final url = await _resolveFullUrl();
        final result = await AsyncWallpaper.setWallpaper(
          WallpaperRequest(
            target: target,
            sourceType: WallpaperSourceType.url,
            source: url,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              result.isSuccess
                  ? 'Wallpaper applied'
                  : 'Failed: ${result.error?.message ?? 'unknown error'}',
            ),
          ),);
        }
        return;
      }
      final result = await AsyncWallpaper.setWallpaper(
        WallpaperRequest(
          target: target,
          sourceType: WallpaperSourceType.file,
          source: file.path,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            result.isSuccess
                ? 'Wallpaper applied'
                : 'Failed: ${result.error?.message ?? 'unknown error'}',
          ),
        ),);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Snapshots the image viewport (post zoom + pan) into a PNG temp file.
  /// Returns `null` on web (no `dart:io`) or if any step fails.
  Future<File?> _captureViewport() async {
    if (kIsWeb) return null;
    try {
      final ctx = _viewportKey.currentContext;
      if (ctx == null) return null;
      final boundary =
          ctx.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      // 3x pixel ratio gives ~1080p on most phones — good enough for a
      // crisp wallpaper without ballooning the file size.
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (byteData == null) return null;
      final bytes = byteData.buffer.asUint8List();
      // Re-encode as JPEG to keep file size sane (PNGs of full screens are
      // 5–10 MB — too big for the system wallpaper service on some OEMs).
      final decoded = img.decodeImage(bytes);
      final out = decoded == null
          ? bytes
          : Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/wolwo_wallpaper_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(out, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  /// Animate InteractiveViewer's transformation controller toward [target].
  void _animateTo(Matrix4 target) {
    // Simple: just set it. InteractiveViewer doesn't ship with built-in
    // animated zoom and rolling our own AnimationController here is
    // overkill for the small +/− button feedback.
    _txCtl.value = target;
  }

  void _zoomBy(double factor) {
    final current = _txCtl.value.clone();
    final currentScale = current.getMaxScaleOnAxis();
    final newScale =
        (currentScale * factor).clamp(_minScale, _maxScale).toDouble();
    if (newScale == currentScale) return;
    final size = MediaQuery.of(context).size;
    final cx = size.width / 2;
    final cy = size.height / 2;
    // Build a fresh matrix that scales around the screen centre. Resetting
    // from identity each time avoids drift accumulating in the translation.
    final m = Matrix4.identity()
      // ignore: deprecated_member_use
      ..translate(cx, cy)
      // ignore: deprecated_member_use
      ..scale(newScale)
      // ignore: deprecated_member_use
      ..translate(-cx, -cy);
    _animateTo(m);
    if (_showHint) setState(() => _showHint = false);
  }

  void _resetZoom() {
    _animateTo(Matrix4.identity());
  }

  Future<void> _saveToGallery() async {
    setState(() => _busy = true);
    try {
      final url = await _resolveFullUrl();
      if (!_canSaveToGallery) {
        // Web / desktop: open the original so the browser handles saving.
        await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Opened full image — use your browser to save it.'),
          ),);
        }
        return;
      }
      final ok = await GallerySaver.saveImage(url, albumName: 'wolwo');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok == true ? 'Saved to gallery' : 'Save failed'),
        ),);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    final url = widget.wallpaper.sourcePageUrl ?? widget.wallpaper.fullUrl;
    await Share.share(url);
  }

  void _showApplyTargets() {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(_T.lg, 0, _T.lg, _T.sm),
              child: Text('SET WALLPAPER',
                  style: _T.metaLabel(scheme.outline),),
            ),
            _SheetRow(
              icon: Icons.home_outlined,
              label: 'Home screen',
              onTap: () {
                Navigator.pop(context);
                _setWallpaper(WallpaperTarget.home);
              },
            ),
            _SheetRow(
              icon: Icons.lock_outline,
              label: 'Lock screen',
              onTap: () {
                Navigator.pop(context);
                _setWallpaper(WallpaperTarget.lock);
              },
            ),
            _SheetRow(
              icon: Icons.smartphone_outlined,
              label: 'Both',
              onTap: () {
                Navigator.pop(context);
                _setWallpaper(WallpaperTarget.both);
              },
            ),
            const SizedBox(height: _T.sm),
          ],
        ),
      ),
    );
  }

  void _showInfoSheet(Wallpaper w, String sourceName) {
    final scheme = Theme.of(context).colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: scheme.surface,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(_T.lg, 0, _T.lg, _T.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('IMAGE DETAILS',
                  style: _T.metaLabel(scheme.outline),),
              const SizedBox(height: _T.md),
              _DetailRow(label: 'SOURCE', value: sourceName),
              if (w.author != null)
                _DetailRow(
                  label: 'AUTHOR',
                  value: w.author!,
                  onTap: w.authorUrl == null
                      ? null
                      : () => launchUrl(Uri.parse(w.authorUrl!),
                          mode: LaunchMode.externalApplication,),
                ),
              _DetailRow(label: 'RESOLUTION', value: w.resolution),
              if (w.is4k) const _DetailRow(label: 'QUALITY', value: '4K · UHD'),
              if (w.license != null)
                _DetailRow(label: 'LICENSE', value: w.license!),
              const SizedBox(height: _T.md),
              if (w.sourcePageUrl != null)
                _SheetRow(
                  icon: Icons.open_in_new_rounded,
                  label: 'Open original page',
                  onTap: () => launchUrl(Uri.parse(w.sourcePageUrl!),
                      mode: LaunchMode.externalApplication,),
                ),
              _SheetRow(
                icon: Icons.flag_outlined,
                label: 'Report this wallpaper',
                destructive: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _reportDialog(context, w);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.wallpaper;
    final scheme = Theme.of(context).colorScheme;
    final favs = ref.watch(favoritesProvider);
    final isFav = favs.isFavorite(w);
    final source = ref.read(sourcesProvider).firstWhere(
          (s) => s.id == w.sourceId,
          orElse: () => ref.read(sourcesProvider).first,
        );

    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top;
    final bottomInset = mq.padding.bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Progressive image: preview first, full fades in on top ──
          // The image fills the entire screen using BoxFit.cover and is
          // wrapped in an InteractiveViewer so the user can pinch-to-zoom
          // (or tap the +/− buttons) and pan to choose what part of the
          // image lands on their lock/home screen. RepaintBoundary lets us
          // snapshot exactly that view on Apply.
          Positioned.fill(
            child: RepaintBoundary(
              key: _viewportKey,
              child: InteractiveViewer(
                transformationController: _txCtl,
                minScale: _minScale,
                maxScale: _maxScale,
                clipBehavior: Clip.hardEdge,
                // Allow free panning at any zoom level (including 1x) so the
                // user can slide a `BoxFit.cover`-cropped wallpaper around to
                // pick which slice ends up on the lock/home screen.
                boundaryMargin: const EdgeInsets.all(double.infinity),
                onInteractionStart: (_) {
                  if (_showHint) setState(() => _showHint = false);
                },
                child: Hero(
                  tag: 'wp-${w.globalKey}',
                  child: _ProgressiveImage(
                    previewUrl: w.previewUrl,
                    fullUrl: w.fullUrl,
                    outline: scheme.outline,
                  ),
                ),
              ),
            ),
          ),

          // ── Back button: pinned to top-left, hairline-bordered. ─────
          Positioned(
            top: topInset + _T.sm,
            left: _T.md,
            child: _SurfaceCircleBtn(
              icon: Icons.arrow_back_rounded,
              onTap: () => context.pop(),
            ),
          ),

          // ── Layout cycle button: pinned to top-right. Tap cycles
          //    the action arrangement; long-press resets to the
          //    default "bar" layout in case the user got stuck on
          //    one they don't want.
          Positioned(
            top: topInset + _T.sm,
            right: _T.md,
            child: _SurfaceCircleBtn(
              icon: switch (ref.watch(settingsProvider).viewerLayout) {
                ViewerLayout.bar => Icons.view_carousel_outlined,
                ViewerLayout.compact => Icons.view_sidebar_outlined,
              },
              onTap: () async {
                await ref.read(settingsProvider).cycleViewerLayout();
                if (!context.mounted) return;
                final next = ref.read(settingsProvider).viewerLayout;
                final desc = switch (next) {
                  ViewerLayout.bar => 'BAR \u2014 SCROLLING ACTION ROW',
                  ViewerLayout.compact => 'COMPACT \u2014 SIDE ICON STACK',
                };
                _showViewerToast(context, desc);
              },
              onLongPress: () async {
                final s = ref.read(settingsProvider);
                while (s.viewerLayout != ViewerLayout.bar) {
                  await s.cycleViewerLayout();
                }
                if (!context.mounted) return;
                _showViewerToast(context, 'LAYOUT RESET \u2014 BAR');
              },
            ),
          ),

          // ── Zoom controls: pinned to the right edge, vertically centred.
          Positioned(
            right: _T.md,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SurfaceCircleBtn(
                    icon: Icons.add_rounded,
                    onTap: () => _zoomBy(1.5),
                  ),
                  const SizedBox(height: _T.sm),
                  _SurfaceCircleBtn(
                    icon: Icons.remove_rounded,
                    onTap: () => _zoomBy(1 / 1.5),
                  ),
                  const SizedBox(height: _T.sm),
                  _SurfaceCircleBtn(
                    icon: Icons.center_focus_strong_rounded,
                    onTap: _resetZoom,
                  ),
                ],
              ),
            ),
          ),

          // ── "Drag to reposition" hint, fades out on first interaction.
          if (_showHint)
            Positioned(
              top: topInset + _T.sm + 4,
              // Stay clear of the back/layout circle buttons (~44dp + 16dp
              // margin = 60dp on each side). Without this margin the hint
              // pill stretches almost edge-to-edge and visually crowds the
              // corner buttons on narrow phones.
              left: 64,
              right: 64,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 220),
                    opacity: _showHint ? 1.0 : 0.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: _T.md,
                        vertical: _T.sm - 2,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surface.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color:
                              scheme.outlineVariant.withValues(alpha: 0.30),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.swipe_rounded,
                              size: 14, color: scheme.onSurfaceVariant,),
                          const SizedBox(width: _T.xs + 2),
                          Flexible(
                            child: Text(
                              'PINCH · DRAG',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  _T.metaLabel(scheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // ── Tag chips: tap to deep-link into search. ────────────────
          // Only renders if the wallpaper carries tags. Limited to a
          // handful so the row never crowds the action bar.
          if (w.tags.isNotEmpty)
            Positioned(
              left: _T.md,
              right: _T.md,
              bottom: bottomInset + 96 + _T.sm + 34,
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final tag in w.tags.take(6))
                        Padding(
                          padding: const EdgeInsets.only(right: _T.xs + 2),
                          child: _TagChip(
                            text: tag,
                            scheme: scheme,
                            onTap: () {
                              final q = Uri.encodeQueryComponent(tag);
                              context.go('/search?q=$q');
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Tiny caption pinned just above the action row. ──────────
          // Wrapped in a single dark pill so the text remains legible no
          // matter what colours are in the wallpaper behind it.
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + 96 + _T.sm,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: _T.md,
                  vertical: _T.xs + 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.30),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _MetaChip(text: source.displayName.toUpperCase(),
                        scheme: scheme,),
                    if (w.is4k) ...[
                      const SizedBox(width: _T.xs + 2),
                      _MetaChip(text: '4K', scheme: scheme, accent: true),
                    ],
                    const SizedBox(width: _T.sm),
                    Text(
                      w.resolution,
                      style: _T.metaLabel(Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Floating action row \u2014 the layout is user-cycle-able via
          // the top-right button. Three arrangements are available:
          //   bar     \u2014 horizontal scrolling pill row (default)
          //   dock    \u2014 wide primary CTA on bottom, secondary icons in a
          //             tight row above
          //   compact \u2014 vertical icon stack pinned to the bottom-right
          //             corner so the wallpaper itself stays uncovered
          _ViewerActions(
            layout: ref.watch(settingsProvider).viewerLayout,
            bottomInset: bottomInset,
            scheme: scheme,
            isFav: isFav,
            busy: _busy,
            canSetWallpaper: _canSetWallpaper,
            onApply: _busy
                ? null
                : (_canSetWallpaper
                    ? _showApplyTargets
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Apply is Android-only. Use Save to download.',),
                          ),
                        );
                      }),
            onSave: _busy ? null : _saveToGallery,
            onShare: _busy ? null : _share,
            onFavorite: () => favs.toggle(w),
            onInfo: () => _showInfoSheet(w, source.displayName),
          ),
        ],
      ),
    );
  }
}

/// Layout-switching action row for the viewer. The three arrangements
/// share the same callbacks; only the geometry differs.
class _ViewerActions extends StatelessWidget {
  const _ViewerActions({
    required this.layout,
    required this.bottomInset,
    required this.scheme,
    required this.isFav,
    required this.busy,
    required this.canSetWallpaper,
    required this.onApply,
    required this.onSave,
    required this.onShare,
    required this.onFavorite,
    required this.onInfo,
  });

  final ViewerLayout layout;
  final double bottomInset;
  final ColorScheme scheme;
  final bool isFav;
  final bool busy;
  final bool canSetWallpaper;
  final VoidCallback? onApply;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback onFavorite;
  final VoidCallback onInfo;

  @override
  Widget build(BuildContext context) {
    switch (layout) {
      case ViewerLayout.bar:
        // Centered when the row fits, scrolls horizontally when it doesn't.
        // Trick: SingleChildScrollView with a ConstrainedBox forcing the
        // child's minWidth to the viewport, plus a Row centred inside.
        return Positioned(
          left: 0,
          right: 0,
          bottom: bottomInset + _T.lg,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: _T.md),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: constraints.maxWidth - _T.md * 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    _ViewerButton(
                      icon: Icons.wallpaper_rounded,
                      label: 'Apply',
                      primary: true,
                      busy: busy,
                      onTap: onApply,
                      scheme: scheme,
                    ),
                    const SizedBox(width: _T.sm),
                    _ViewerButton(
                      icon: Icons.download_rounded,
                      label: 'Save',
                      onTap: onSave,
                      scheme: scheme,
                    ),
                    const SizedBox(width: _T.sm),
                    _ViewerButton(
                      icon: Icons.share_rounded,
                      label: 'Share',
                      onTap: onShare,
                      scheme: scheme,
                    ),
                    const SizedBox(width: _T.sm),
                    _ViewerButton(
                      icon: isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_outline_rounded,
                      label: isFav ? 'Saved' : 'Favorite',
                      color: isFav ? Colors.redAccent : null,
                      onTap: onFavorite,
                      scheme: scheme,
                    ),
                    const SizedBox(width: _T.sm),
                    _ViewerButton(
                      icon: Icons.info_outline_rounded,
                      label: 'Info',
                      onTap: onInfo,
                      scheme: scheme,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

      case ViewerLayout.compact:
        // Vertical icon stack pinned to bottom-right \u2014 leaves the entire
        // wallpaper unobstructed so users can frame their crop precisely.
        return Positioned(
          right: _T.md,
          bottom: bottomInset + _T.lg,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: _T.xs + 2, vertical: _T.sm,),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(_T.md + 2),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CompactIcon(
                  icon: Icons.wallpaper_rounded,
                  primary: true,
                  busy: busy,
                  onTap: onApply,
                  scheme: scheme,
                ),
                _CompactIcon(
                  icon: Icons.download_rounded,
                  onTap: onSave,
                  scheme: scheme,
                ),
                _CompactIcon(
                  icon: Icons.share_rounded,
                  onTap: onShare,
                  scheme: scheme,
                ),
                _CompactIcon(
                  icon: isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_outline_rounded,
                  iconColor: isFav ? Colors.redAccent : null,
                  onTap: onFavorite,
                  scheme: scheme,
                ),
                _CompactIcon(
                  icon: Icons.info_outline_rounded,
                  onTap: onInfo,
                  scheme: scheme,
                ),
              ],
            ),
          ),
        );
    }
  }
}

class _CompactIcon extends StatelessWidget {
  const _CompactIcon({
    required this.icon,
    required this.onTap,
    required this.scheme,
    this.primary = false,
    this.busy = false,
    this.iconColor,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final ColorScheme scheme;
  final bool primary;
  final bool busy;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final fg = primary
        ? scheme.surface
        : (iconColor ?? scheme.onSurface);
    final bg = primary ? scheme.onSurface : Colors.transparent;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(_T.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(_T.md),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: busy
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  : Icon(icon, size: 20, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Floating viewer button ───────────────────────────────────────────
// Shared layout for the action-row icons:
//   - alignItems center, padding md+2, surface bg, radius md+2
//   - icon 22, mono meta label below
//   - active variant gets a 1px border in primary
class _ViewerButton extends StatelessWidget {
  const _ViewerButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.scheme,
    this.color,
    this.primary = false,
    this.busy = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final ColorScheme scheme;
  final Color? color;
  final bool primary;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? (primary ? scheme.primary : Colors.white);
    // Solid dark pill so the button stays readable against any wallpaper.
    final bg = Colors.black.withValues(alpha: 0.55);
    final border = primary
        ? scheme.primary.withValues(alpha: 0.65)
        : Colors.white.withValues(alpha: 0.18);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(_T.md + 2),
      child: Container(
        // Fixed footprint so swapping the label text (e.g. Favorite ->
        // Saved) doesn't reflow the row or appear to shrink the icon.
        // Slightly wider than tall to give the longest label ("Favorite")
        // a little breathing room from the rounded border.
        width: 64,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: _T.xs),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(_T.md + 2),
          border: Border.all(color: border, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: busy
                  ? CircularProgressIndicator(strokeWidth: 2, color: tint)
                  : Icon(icon, color: tint, size: 18),
            ),
            const SizedBox(height: _T.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _T.actionLabel(tint),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Top-anchored toast: dark pill that never overlaps the bottom action
// stack / source pill the way SnackBar does. Renders just below the
// header buttons via a 1.5s OverlayEntry.
// ─────────────────────────────────────────────────────────────────────
void _showViewerToast(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  final topInset = MediaQuery.of(context).padding.top;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _ViewerToast(
      message: message,
      topPadding: topInset + 56,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
}

class _ViewerToast extends StatefulWidget {
  const _ViewerToast({
    required this.message,
    required this.topPadding,
    required this.onDone,
  });
  final String message;
  final double topPadding;
  final VoidCallback onDone;

  @override
  State<_ViewerToast> createState() => _ViewerToastState();
}

class _ViewerToastState extends State<_ViewerToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(_opacity);
    _ctrl.forward();
    Future<void>.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      await _ctrl.reverse();
      if (!mounted) return;
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.topPadding,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _opacity,
          child: SlideTransition(
            position: _slide,
            child: Center(
              // Material wrapper makes sure the dark fill paints
              // opaquely on top of light wallpapers (a transparent
              // Container blends with whatever's behind it and made
              // the text wash out completely).
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 9,),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'JetBrainsMono',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SurfaceCircleBtn extends StatelessWidget {
  const _SurfaceCircleBtn({
    required this.icon,
    required this.onTap,
    this.onLongPress,
  });
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    // Wrap in an opaque GestureDetector so taps are claimed at the top
    // of the hit chain. Without this, InteractiveViewer's pan/scale
    // recognizer below in the Stack frequently wins the gesture arena
    // on micro-jitter taps and the back / layout buttons require
    // multiple presses to register.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Material(
        color: Colors.black.withValues(alpha: 0.55),
        shape: CircleBorder(
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.text,
    required this.scheme,
    this.accent = false,
  });
  final String text;
  final ColorScheme scheme;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final fg = accent ? scheme.primary : Colors.white.withValues(alpha: 0.85);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: _T.sm, vertical: _T.xs - 1),
      decoration: BoxDecoration(
        color: accent
            ? scheme.primary.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(_T.xs + 2),
        border: Border.all(
          color: accent
              ? scheme.primary.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: _T.mono(
          size: 10,
          weight: FontWeight.w500,
          color: fg,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

/// Small, tappable hashtag pill used on the detail page to deep-link
/// into the search tab pre-seeded with the tag text.
class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.text,
    required this.scheme,
    required this.onTap,
  });
  final String text;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: _T.sm + 2, vertical: _T.xs,),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Text(
            '#${text.toLowerCase()}',
            style: _T.mono(
              size: 10,
              weight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 0.6,
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: _T.sm + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _T.metaLabel(scheme.outline)),
          const SizedBox(height: 2),
          GestureDetector(
            onTap: onTap,
            child: Text(
              value,
              style: _T.metaValue(scheme.onSurface).copyWith(
                decoration: onTap == null
                    ? TextDecoration.none
                    : TextDecoration.underline,
                decorationColor: scheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = destructive ? scheme.error : scheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: _T.lg, vertical: _T.md + 2,),
        child: Row(
          children: [
            Icon(icon, color: fg, size: 20),
            const SizedBox(width: _T.md),
            Text(label, style: _T.metaValue(fg)),
          ],
        ),
      ),
    );
  }
}

void _reportDialog(BuildContext context, Wallpaper w) {
  showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Report this wallpaper'),
      content: const Text(
        'If this image infringes copyright, contains harmful content, or '
        'should not be available, let us know. We will remove it from '
        'recommendations and clear it from cache.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Thanks — report received.')),
            );
          },
          child: const Text('Report'),
        ),
      ],
    ),
  );
}

/// Two-pass progressive image loader.
///
/// Layer 1 (always rendered): the small `previewUrl` thumbnail. Loads fast,
/// so the screen never feels empty.
/// Layer 2 (fades in on top): the full-resolution `fullUrl`. Replaces the
/// preview only after it has fully decoded. If it errors, the preview
/// stays as the visible image \u2014 no broken-icon flash.
class _ProgressiveImage extends StatefulWidget {
  const _ProgressiveImage({
    required this.previewUrl,
    required this.fullUrl,
    required this.outline,
  });

  final String? previewUrl;
  final String fullUrl;
  final Color outline;

  @override
  State<_ProgressiveImage> createState() => _ProgressiveImageState();
}

class _ProgressiveImageState extends State<_ProgressiveImage> {
  bool _fullReady = false;
  bool _fullFailed = false;
  ImageStream? _stream;
  late final ImageStreamListener _listener;
  CachedNetworkImageProvider? _provider;

  @override
  void initState() {
    super.initState();
    _listener = ImageStreamListener(
      (info, _) {
        if (mounted && !_fullReady) {
          setState(() => _fullReady = true);
        }
      },
      onError: (_, __) {
        if (mounted && !_fullFailed) {
          setState(() => _fullFailed = true);
        }
      },
    );
    _attachStream();
  }

  void _attachStream() {
    // For "bad hosts" (Pixabay etc.) NetworkImageWithFallback paints
    // via a native <img> element because CanvasKit's decode path stalls
    // on those CDNs. The CachedNetworkImageProvider stream listener
    // below would also stall \u2014 so the AnimatedOpacity gating the
    // visible layer would stay at 0 forever and the user sees a black
    // screen until they back-and-reopen (which warms the in-memory
    // cache enough for the listener to occasionally fire).
    //
    // For those hosts we skip the listener entirely and just flip
    // `_fullReady` immediately so the <img>-backed layer becomes visible
    // as soon as the browser decodes it natively.
    _stream?.removeListener(_listener);
    _stream = null;
    _provider = null;
    if (ImageProxy.isBadHost(widget.fullUrl)) {
      if (!_fullReady) {
        _fullReady = true;
      }
      return;
    }
    // Listen directly to the full-resolution image stream so we know
    // when the bytes have actually arrived and decoded \u2014 not just when
    // the placeholder builder runs (which fires while loading is still
    // in flight and was making the LOADING HI-RES banner stick around
    // forever).
    _provider = CachedNetworkImageProvider(
      widget.fullUrl,
      cacheKey: widget.fullUrl,
      cacheManager: WolwoImageCacheManager.instance,
    );
    _stream = _provider!.resolve(const ImageConfiguration());
    _stream!.addListener(_listener);
  }

  @override
  void didUpdateWidget(covariant _ProgressiveImage old) {
    super.didUpdateWidget(old);
    if (old.fullUrl != widget.fullUrl) {
      setState(() {
        _fullReady = false;
        _fullFailed = false;
      });
      _attachStream();
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPreview =
        widget.previewUrl != null && widget.previewUrl!.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        // Base layer \u2014 preview (or a soft placeholder if none).
        if (hasPreview)
          NetworkImageWithFallback(
            url: widget.previewUrl!,
            fit: BoxFit.cover,

            fadeIn: const Duration(milliseconds: 80),
            placeholder: (_) => const Center(
              child: AppLoader(label: 'LOADING PREVIEW'),
            ),
          )
        else
          const Center(child: AppLoader(label: 'LOADING WALLPAPER')),

        // Top layer \u2014 full-resolution. Driven by the `_fullReady` flag
        // which is now flipped by an actual ImageStreamListener (see
        // initState), so the fade-in only happens once the bytes are
        // decoded \u2014 not the moment the placeholder renders.
        if (!_fullFailed)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 280),
            opacity: _fullReady ? 1.0 : 0.0,
            child: NetworkImageWithFallback(
              url: widget.fullUrl,
              fit: BoxFit.cover,
              fadeIn: Duration.zero,
              placeholder: (_) => const SizedBox.shrink(),
              onAllFailed: () {
                if (mounted && !_fullFailed) {
                  setState(() => _fullFailed = true);
                }
              },
            ),
          ),

        // Tiny "loading hi-res" hint pinned to the top while the
        // full-resolution image streams in. Disappears the moment the
        // hi-res layer fades in (or fails).
        if (hasPreview && !_fullReady && !_fullFailed)
          Positioned(
            top: 64,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6,),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                          width: 14,
                          height: 14,
                          child: AppLoader(label: '', compact: true),),
                      SizedBox(width: 8),
                      Text(
                        'LOADING HI-RES',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          letterSpacing: 1.4,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
