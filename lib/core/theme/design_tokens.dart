import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens used across all screens.
///
/// Tight, opinionated system so wolwo feels like a
/// cohesive, terminal-flavored, mono-typed surface throughout.
class Tk {
  Tk._();

  // ── Spacing scale ────────────────────────────────────────────────
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  // ── Radii ────────────────────────────────────────────────────────
  static const radSm = 6.0;
  static const radMd = 12.0;
  static const radLg = 16.0;
  static const radXl = 20.0;

  // ── Border widths ────────────────────────────────────────────────
  static const hairline = 1.0;

  // ── Typography (all monospaced) ──
  static TextStyle mono({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double letterSpacing = 0,
    double? height,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  /// Hero number / display.
  static TextStyle display(Color c) =>
      mono(size: 22, weight: FontWeight.w200, color: c, letterSpacing: -0.5);

  /// Page title.
  static TextStyle h1(Color c) =>
      mono(size: 24, weight: FontWeight.w300, color: c, letterSpacing: -0.5);

  /// Section title.
  static TextStyle h2(Color c) =>
      mono(size: 16, weight: FontWeight.w400, color: c, letterSpacing: -0.2);

  /// Sub section / list title.
  static TextStyle h3(Color c) =>
      mono(size: 13, weight: FontWeight.w400, color: c, letterSpacing: -0.2);

  static TextStyle body(Color c) =>
      mono(size: 14, weight: FontWeight.w400, color: c);

  static TextStyle bodySmall(Color c) =>
      mono(size: 13, weight: FontWeight.w400, color: c);

  /// Signature ALL-CAPS label (sparse, very small).
  static TextStyle label(Color c) =>
      mono(size: 10, weight: FontWeight.w400, color: c, letterSpacing: 1.2);

  /// Caption / metadata under content.
  static TextStyle meta(Color c) =>
      mono(size: 10, weight: FontWeight.w300, color: c);

  /// Tiny mono caption (chips, focus indicators).
  static TextStyle tiny(Color c) =>
      mono(size: 9, weight: FontWeight.w400, color: c, letterSpacing: 0.4);
}

/// Reusable helpers shared by every screen.
class TkUI {
  TkUI._();

  /// Hairline border used on every surface.
  static BoxBorder hairline(ColorScheme s, {double opacity = 0.30}) =>
      Border.all(
        color: s.outlineVariant.withValues(alpha: opacity),
        width: Tk.hairline,
      );

  /// Solid surface card with hairline border (NOT glassmorphism).
  static BoxDecoration card(ColorScheme s, {double radius = Tk.radLg}) =>
      BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(radius),
        border: hairline(s),
      );

  /// Slightly elevated card variant for nested content.
  static BoxDecoration cardElev(ColorScheme s, {double radius = Tk.radMd}) =>
      BoxDecoration(
        color: s.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
        border: hairline(s, opacity: 0.20),
      );
}
