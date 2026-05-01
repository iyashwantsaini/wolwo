import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  const AppTheme._();

  // wolwo palette: pure black canvas + cool periwinkle accent.
  // Cool, calm, distinct from the mint/teal common in minimal apps.
  static const Color _ink = Color(0xFF0A0A0A);
  static const Color _surfaceDark = Color(0xFF111114);
  static const Color _surfaceDarkElev = Color(0xFF17171B);
  static const Color _onDark = Color(0xFFEDEEF2);
  static const Color _muted = Color(0xFF7A7A82);
  static const Color _accent = Color(0xFF8FA8FF);

  static const Color _surfaceLight = Color(0xFFF4F4F6);
  static const Color _surfaceLightElev = Color(0xFFFFFFFF);
  static const Color _inkLight = Color(0xFF0E0E14);
  // Light palette: deliberately monochromatic. Primary controls
  // (switches, cursors, focused borders) use ink so the UI reads as
  // editorial / typewriter, not a colourful Material 3 demo. The
  // periwinkle accent is reserved for tiny details (link text, focus
  // rings) — never large filled surfaces.
  static const Color _accentLight = Color(0xFF4A5BD0); // deeper periwinkle
  static const Color _mutedLight = Color(0xFF6B6B73);
  static const Color _hairlineLight = Color(0xFFE3E3E8);

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    // Build the scheme by hand instead of `fromSeed` so we get exactly
    // the ink-on-paper palette we want — `fromSeed` would derive a
    // saturated lavender primary that turns every switch and cursor
    // into a candy-coloured pill against the soft white surfaces.
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: _inkLight,
      onPrimary: _surfaceLightElev,
      secondary: _accentLight,
      onSecondary: _surfaceLightElev,
      error: Color(0xFFB3261E),
      onError: _surfaceLightElev,
      surface: _surfaceLight,
      onSurface: _inkLight,
      surfaceContainerHighest: _surfaceLightElev,
      onSurfaceVariant: _mutedLight,
      outline: _mutedLight,
      outlineVariant: _hairlineLight,
      shadow: Color(0x14000000),
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: _surfaceLight,
      canvasColor: _surfaceLight,
      textTheme: GoogleFonts.jetBrainsMonoTextTheme(base.textTheme).apply(
        bodyColor: _inkLight,
        displayColor: _inkLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: _surfaceLightElev,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _hairlineLight, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _surfaceLightElev,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _inkLight,
        unselectedItemColor: _mutedLight,
      ),
      // Mono switch: ink track when on, hairline outline when off. Reads as
      // a tiny piece of stationery rather than a neon Material toggle.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? _surfaceLightElev
                : _mutedLight,),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? _inkLight : _surfaceLight,),
        trackOutlineColor:
            const WidgetStatePropertyAll(_hairlineLight),
        trackOutlineWidth: const WidgetStatePropertyAll(1),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      // Same hairline language for checkboxes (used in source filter sheet).
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? _inkLight : Colors.transparent,),
        checkColor: const WidgetStatePropertyAll(_surfaceLightElev),
        side: const BorderSide(color: _mutedLight, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      // Focus ring + cursor pick up the small accent so input fields still
      // have a recognisable interaction colour without being loud.
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: _accentLight,
        selectionColor: Color(0x334A5BD0),
        selectionHandleColor: _accentLight,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _ink,
        contentTextStyle: GoogleFonts.jetBrainsMono(
          color: _onDark,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        actionTextColor: _accentLight,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
      dividerColor: _hairlineLight,
      iconTheme: const IconThemeData(color: _inkLight),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    final scheme = ColorScheme.fromSeed(
      seedColor: _accent,
      brightness: Brightness.dark,
      surface: _ink,
    );
    return base.copyWith(
      colorScheme: scheme.copyWith(
        surface: _ink,
        surfaceContainerHighest: _surfaceDarkElev,
        primary: _accent,
        onPrimary: _ink,
        secondary: _accent,
      ),
      scaffoldBackgroundColor: _ink,
      canvasColor: _ink,
      textTheme: GoogleFonts.jetBrainsMonoTextTheme(base.textTheme).apply(
        bodyColor: _onDark,
        displayColor: _onDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: _surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _ink,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _accent,
        unselectedItemColor: _muted,
      ),
      // Toast: dark-ink pill with hairline accent border, mono
      // caption. Floats above the bottom nav so it never obscures the
      // active tab indicator.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _surfaceDarkElev,
        contentTextStyle: GoogleFonts.jetBrainsMono(
          color: _onDark,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        actionTextColor: _accent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _accent.withValues(alpha: 0.35), width: 1),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }
}
