import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';

/// Shared page header.
///
/// Layout:
///   ┌────────────────────────────────────────────────────┐
///   │  TINY · LABEL                            [actions]  │
///   │  Big page title in mono                             │
///   │  Optional subtitle in muted mono                    │
///   └────────────────────────────────────────────────────┘
///
/// Used across screens (HomeScreen,
/// ChatsListScreen, ProjectsScreen) — small all-caps eyebrow above a calm
/// h1, optional trailing icons, no shadow / no big bold sans-serif.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Tk.lg, Tk.md, Tk.sm, Tk.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow.toUpperCase(),
                    style: Tk.label(scheme.outline)),
                const SizedBox(height: Tk.xs),
                Text(title, style: Tk.h1(scheme.onSurface)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: Tk.meta(scheme.outline)),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: Tk.sm),
              child: Row(mainAxisSize: MainAxisSize.min, children: actions),
            ),
        ],
      ),
    );
  }
}

/// Icon button: surface-tinted square with hairline border.
class HeaderIconBtn extends StatelessWidget {
  const HeaderIconBtn({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget btn = Material(
      color: scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Tk.radMd),
        side: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.30),
          width: Tk.hairline,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(Tk.radMd),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: scheme.onSurface, size: 18),
              if (badge)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (tooltip != null) btn = Tooltip(message: tooltip!, child: btn);
    return Padding(
      padding: const EdgeInsets.only(left: Tk.xs + 2),
      child: btn,
    );
  }
}

/// All-caps section header (used inside lists).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.padding});
  final String text;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding ??
          const EdgeInsets.fromLTRB(Tk.lg, Tk.lg, Tk.lg, Tk.sm),
      child: Text(text.toUpperCase(), style: Tk.label(scheme.outline)),
    );
  }
}

/// Status pill — small mono caps tag with hairline border.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.text, this.accent = false});
  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = accent ? scheme.primary : scheme.outline;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: Tk.sm, vertical: Tk.xs - 1),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Tk.radSm),
        border: Border.all(
          color: accent
              ? scheme.primary.withValues(alpha: 0.5)
              : scheme.outlineVariant.withValues(alpha: 0.30),
          width: Tk.hairline,
        ),
      ),
      child: Text(text.toUpperCase(),
          style: Tk.tiny(fg).copyWith(letterSpacing: 1.0)),
    );
  }
}
