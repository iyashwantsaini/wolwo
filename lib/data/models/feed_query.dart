import 'package:flutter/foundation.dart';

/// What kind of listing the UI is asking a source for.
enum FeedKind { curated, trending, search, category, color, fourK, random }

/// A normalized query the UI sends to all sources.
/// Sources translate the parts they support and ignore the rest.
@immutable
class FeedQuery {
  const FeedQuery({
    required this.kind,
    this.text,
    this.category,
    this.colorHex,
    this.sfwOnly = true,
    this.minWidth,
    this.minHeight,
    this.seed,
  });

  final FeedKind kind;
  final String? text;
  final String? category;
  final String? colorHex;
  final bool sfwOnly;
  final int? minWidth;
  final int? minHeight;
  final String? seed;

  FeedQuery copyWith({String? seed}) => FeedQuery(
        kind: kind,
        text: text,
        category: category,
        colorHex: colorHex,
        sfwOnly: sfwOnly,
        minWidth: minWidth,
        minHeight: minHeight,
        seed: seed ?? this.seed,
      );

  String get cacheKey =>
      '${kind.name}|${text ?? ''}|${category ?? ''}|${colorHex ?? ''}|'
      '$sfwOnly|${minWidth ?? 0}|${minHeight ?? 0}|${seed ?? ''}';
}
