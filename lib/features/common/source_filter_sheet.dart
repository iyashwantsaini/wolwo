import 'package:flutter/material.dart';

import '../../core/theme/design_tokens.dart';
import '../../data/sources/wallpaper_source.dart';
import 'page_header.dart';

/// Bottom sheet that lets the user narrow the active feed to a subset of
/// the sources they have globally enabled in Settings. Returns the chosen
/// subset, or `null` if the user cancelled.
///
/// Returning a set with the same length as [enabled] is treated by callers
/// as "all sources" (they typically store it as `null` to keep the
/// merged-feed defaults). Callers should clamp empty selections away
/// before applying \u2014 the sheet itself disables Apply when empty.
///
/// Reused by Home, Search and the category drill-down page so the source
/// filter affordance reads identically everywhere.
Future<Set<String>?> showSourceFilterSheet({
  required BuildContext context,
  required List<WallpaperSource> enabled,
  required Set<String>? current,
}) async {
  final scheme = Theme.of(context).colorScheme;
  Set<String> draft = current == null
      ? enabled.map((s) => s.id).toSet()
      : Set<String>.from(current);

  return showModalBottomSheet<Set<String>?>(
    context: context,
    backgroundColor: scheme.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setSheetState) {
        final allOn = draft.length == enabled.length;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SectionLabel('Show wallpapers from'),
              _SourceRow(
                label: 'All sources',
                detail: enabled.map((s) => s.displayName).join(' \u00b7 '),
                selected: allOn,
                onTap: () {
                  setSheetState(() {
                    if (allOn) {
                      draft.clear();
                    } else {
                      draft = enabled.map((s) => s.id).toSet();
                    }
                  });
                },
              ),
              for (final s in enabled)
                _SourceRow(
                  label: s.displayName,
                  detail: s.description,
                  selected: draft.contains(s.id),
                  onTap: () => setSheetState(() {
                    if (!draft.add(s.id)) draft.remove(s.id);
                  }),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    Tk.lg, Tk.sm, Tk.lg, Tk.md,),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        draft.isEmpty
                            ? 'Pick at least one source.'
                            : '${draft.length} of ${enabled.length} selected',
                        style: Tk.meta(scheme.outline),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(null),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: Tk.sm),
                    FilledButton(
                      onPressed: draft.isEmpty
                          ? null
                          : () => Navigator.of(ctx).pop(draft),
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },);
    },
  );
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.label,
    required this.detail,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: Tk.lg, vertical: Tk.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 2, right: Tk.md),
              decoration: BoxDecoration(
                color: selected
                    ? scheme.primary.withValues(alpha: 0.18)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: selected
                      ? scheme.primary
                      : scheme.outlineVariant.withValues(alpha: 0.45),
                  width: 1.5,
                ),
              ),
              child: selected
                  ? Icon(Icons.check_rounded, size: 14, color: scheme.primary)
                  : null,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Tk.body(scheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Tk.meta(scheme.outline),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
