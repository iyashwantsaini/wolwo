import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/design_tokens.dart';

/// Full-page loader.
///
/// A monochrome, mono-typed indicator that matches the rest of the app:
/// a square hairline frame containing a continuously rotating tick mark,
/// with an optional ALL-CAPS mono caption underneath. Designed to be
/// drop-in for any "we're fetching something heavy" moment (the
/// wallpaper detail page's first paint, an initial source-only fetch,
/// the splash → home transition, etc.).
class AppLoader extends StatefulWidget {
  const AppLoader({
    super.key,
    this.label = 'LOADING',
    this.compact = false,
  });

  final String label;

  /// When true, renders a smaller (28px) frame suited for inline use
  /// (page headers, bottom-of-list, etc.). Otherwise renders the
  /// 56px hero size used for full-page fallbacks.
  final bool compact;

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = widget.compact ? 28.0 : 56.0;

    // Inline / icon-sized usage: no label, compact mode. Skip the
    // Column + SizedBox so we honour whatever tiny box the parent
    // gives us (e.g. the 14×14 slot inside the LOADING HI-RES pill).
    if (widget.compact && widget.label.isEmpty) {
      return AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => CustomPaint(
          painter: _SquareLoaderPainter(
            progress: _ctrl.value,
            ink: scheme.onSurface,
            hairline: scheme.outlineVariant.withValues(alpha: 0.40),
            accent: scheme.primary,
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => CustomPaint(
                painter: _SquareLoaderPainter(
                  progress: _ctrl.value,
                  ink: scheme.onSurface,
                  hairline: scheme.outlineVariant.withValues(alpha: 0.40),
                  accent: scheme.primary,
                ),
              ),
            ),
          ),
          if (!widget.compact) ...[
            const SizedBox(height: Tk.lg),
            // Three-dot mono cursor that ticks left→right with the
            // rotation. Tiny, but it tells the user the UI is alive even
            // if the network round-trip stalls.
            AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                final step = (_ctrl.value * 3).floor() % 3;
                final dots = List.generate(3, (i) => i == step ? '\u25A0' : '\u25A1')
                    .join(' ');
                return Text(
                  '${widget.label.toUpperCase()}  $dots',
                  style: Tk.label(scheme.outline).copyWith(letterSpacing: 1.6),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// A 1px hairline square frame with a small accent tick that orbits
/// around the perimeter. Cheap to draw and matches the rest of the app
/// (geometric, monochrome, no Material primary spinner).
class _SquareLoaderPainter extends CustomPainter {
  _SquareLoaderPainter({
    required this.progress,
    required this.ink,
    required this.hairline,
    required this.accent,
  });

  final double progress;
  final Color ink;
  final Color hairline;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1);

    // Outer hairline frame.
    canvas.drawRect(
      rect,
      Paint()
        ..color = hairline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Compute a point on the perimeter for the accent tick. We walk the
    // four edges in sequence, each consuming 25% of `progress`.
    final p = progress % 1.0;
    final perimeter = (size.width + size.height) * 2;
    final dist = p * perimeter;
    Offset pos;
    if (dist < size.width) {
      pos = Offset(dist, 0);
    } else if (dist < size.width + size.height) {
      pos = Offset(size.width, dist - size.width);
    } else if (dist < size.width * 2 + size.height) {
      pos = Offset(size.width * 2 + size.height - dist, size.height);
    } else {
      pos = Offset(0, perimeter - dist);
    }

    // Short trailing segment along the perimeter for a "scanning" look.
    final tailLen = math.max(8.0, size.width * 0.25);
    final tailPaint = Paint()
      ..color = accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final tailEndDist = (dist - tailLen).clamp(0.0, perimeter);
    final endPos = _pointOnPerimeter(tailEndDist, size);
    canvas.drawLine(endPos, pos, tailPaint);

    // Tiny ink dot at the head so users see the leading edge clearly
    // even on busy backgrounds.
    canvas.drawRect(
      Rect.fromCenter(center: pos, width: 4, height: 4),
      Paint()..color = ink,
    );
  }

  Offset _pointOnPerimeter(double dist, Size size) {
    if (dist < size.width) {
      return Offset(dist, 0);
    } else if (dist < size.width + size.height) {
      return Offset(size.width, dist - size.width);
    } else if (dist < size.width * 2 + size.height) {
      return Offset(size.width * 2 + size.height - dist, size.height);
    } else {
      final perimeter = (size.width + size.height) * 2;
      return Offset(0, perimeter - dist);
    }
  }

  @override
  bool shouldRepaint(covariant _SquareLoaderPainter old) =>
      old.progress != progress ||
      old.ink != ink ||
      old.hairline != hairline ||
      old.accent != accent;
}

/// Shimmering masonry skeleton that mirrors the wallpaper grid layout
/// while data is loading. We render staggered tile heights so the
/// placeholder reads as "phone wallpapers loading" rather than a
/// generic spinner. Shimmer base/highlight follow the current scheme so
/// it works in light and dark themes without a flash of wrong colour.
class GridSkeleton extends StatelessWidget {
  const GridSkeleton({super.key, this.crossAxisCount = 2, this.itemCount = 8});

  final int crossAxisCount;
  final int itemCount;

  // Pseudo-random but deterministic heights so the layout is identical
  // across rebuilds (no skeleton shimmer flicker on pagination retries).
  static const _heights = <double>[
    220, 280, 200, 320, 240, 300, 260, 220, 340, 200, 280, 240,
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.04),
      base,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(Tk.md, Tk.md, Tk.md, Tk.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tiny mono header so the loading state stays on-brand
          // — not just an empty wall of grey.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLoader(label: 'FETCHING WALLPAPERS', compact: true),
              const SizedBox(width: Tk.md),
              Text(
                'FETCHING WALLPAPERS',
                style: Tk.label(scheme.outline).copyWith(letterSpacing: 1.4),
              ),
            ],
          ),
          const SizedBox(height: Tk.lg),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: base,
              highlightColor: highlight,
              period: const Duration(milliseconds: 1500),
              child: _MasonrySkeleton(
                crossAxisCount: crossAxisCount,
                itemCount: itemCount,
                heights: _heights,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MasonrySkeleton extends StatelessWidget {
  const _MasonrySkeleton({
    required this.crossAxisCount,
    required this.itemCount,
    required this.heights,
  });
  final int crossAxisCount;
  final int itemCount;
  final List<double> heights;

  @override
  Widget build(BuildContext context) {
    // Distribute fixed-height blocks across N columns by lowest-current-
    // total height \u2014 same approach the real masonry view uses, so the
    // skeleton matches the eventual layout shape.
    final colHeights = List<double>.filled(crossAxisCount, 0);
    final colChildren = List.generate(crossAxisCount, (_) => <Widget>[]);

    for (var i = 0; i < itemCount; i++) {
      var minIdx = 0;
      for (var c = 1; c < crossAxisCount; c++) {
        if (colHeights[c] < colHeights[minIdx]) minIdx = c;
      }
      final h = heights[i % heights.length];
      colChildren[minIdx].add(
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: h,
            decoration: BoxDecoration(
              color: Colors.white, // recoloured by Shimmer
              borderRadius: BorderRadius.circular(Tk.radLg),
            ),
          ),
        ),
      );
      colHeights[minIdx] += h + 10;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var c = 0; c < crossAxisCount; c++) ...[
          if (c > 0) const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: colChildren[c],
            ),
          ),
        ],
      ],
    );
  }
}

/// Footer indicator shown by the grid while paginating to a new page.
/// A tiny mono "scanning" bar under a label \u2014 quieter than the hero
/// loader so it doesn't fight the visible wallpapers above it.
class GridPageFooter extends StatefulWidget {
  const GridPageFooter({super.key, this.label = 'LOADING MORE'});
  final String label;

  @override
  State<GridPageFooter> createState() => _GridPageFooterState();
}

class _GridPageFooterState extends State<GridPageFooter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Tk.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label.toUpperCase(),
            style: Tk.label(scheme.outline).copyWith(letterSpacing: 1.6),
          ),
          const SizedBox(height: Tk.sm + 2),
          SizedBox(
            width: 96,
            height: 2,
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => CustomPaint(
                painter: _ScanBarPainter(
                  progress: _ctrl.value,
                  track: scheme.outlineVariant.withValues(alpha: 0.30),
                  head: scheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanBarPainter extends CustomPainter {
  _ScanBarPainter({
    required this.progress,
    required this.track,
    required this.head,
  });
  final double progress;
  final Color track;
  final Color head;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      Paint()
        ..color = track
        ..strokeWidth = 1,
    );
    final headWidth = 24.0;
    // Bounce: ease in/out across the bar.
    final t = (math.sin(progress * 2 * math.pi) + 1) / 2;
    final x = (size.width - headWidth) * t;
    canvas.drawRect(
      Rect.fromLTWH(x, 0, headWidth, size.height),
      Paint()..color = head,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanBarPainter old) =>
      old.progress != progress;
}
