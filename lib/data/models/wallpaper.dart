import 'package:flutter/foundation.dart';

/// A wallpaper from any source, normalized to a single shape.
@immutable
class Wallpaper {
  const Wallpaper({
    required this.id,
    required this.sourceId,
    required this.thumbUrl,
    required this.fullUrl,
    required this.width,
    required this.height,
    this.previewUrl,
    this.colorHex,
    this.tags = const [],
    this.author,
    this.authorUrl,
    this.sourcePageUrl,
    this.license,
    this.fileSizeBytes,
  });

  /// Source-native id (Wallhaven hash, Pixabay int, Reddit fullname, NASA nasa_id).
  final String id;

  /// Identifier of the [WallpaperSource] this came from. Used for de-dup and routing.
  final String sourceId;

  /// Small image used in grids.
  final String thumbUrl;

  /// Large preview shown on detail screen (load before full-res).
  final String? previewUrl;

  /// Original full-resolution image. Used for "Set as wallpaper" / download.
  final String fullUrl;

  final int width;
  final int height;

  /// Average / dominant color hex string, e.g. `#AABBCC`. Used as placeholder.
  final String? colorHex;

  final List<String> tags;

  /// Photographer / uploader name.
  final String? author;

  /// Link to the author's profile on the source site (for attribution).
  final String? authorUrl;

  /// Canonical page on the source site.
  final String? sourcePageUrl;

  /// Human-readable license string ("Pixabay Content License", "Public Domain", etc.).
  final String? license;

  final int? fileSizeBytes;

  String get resolution => '${width}x$height';
  double get aspectRatio => height == 0 ? 1 : width / height;
  bool get is4k => width >= 3840 || height >= 2160;

  Wallpaper copyWith({String? colorHex}) => Wallpaper(
        id: id,
        sourceId: sourceId,
        thumbUrl: thumbUrl,
        previewUrl: previewUrl,
        fullUrl: fullUrl,
        width: width,
        height: height,
        colorHex: colorHex ?? this.colorHex,
        tags: tags,
        author: author,
        authorUrl: authorUrl,
        sourcePageUrl: sourcePageUrl,
        license: license,
        fileSizeBytes: fileSizeBytes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceId': sourceId,
        'thumbUrl': thumbUrl,
        'previewUrl': previewUrl,
        'fullUrl': fullUrl,
        'width': width,
        'height': height,
        'colorHex': colorHex,
        'tags': tags,
        'author': author,
        'authorUrl': authorUrl,
        'sourcePageUrl': sourcePageUrl,
        'license': license,
        'fileSizeBytes': fileSizeBytes,
      };

  factory Wallpaper.fromJson(Map<String, dynamic> j) => Wallpaper(
        id: j['id'] as String,
        sourceId: j['sourceId'] as String,
        thumbUrl: j['thumbUrl'] as String,
        previewUrl: j['previewUrl'] as String?,
        fullUrl: j['fullUrl'] as String,
        width: j['width'] as int,
        height: j['height'] as int,
        colorHex: j['colorHex'] as String?,
        tags: (j['tags'] as List?)?.cast<String>() ?? const [],
        author: j['author'] as String?,
        authorUrl: j['authorUrl'] as String?,
        sourcePageUrl: j['sourcePageUrl'] as String?,
        license: j['license'] as String?,
        fileSizeBytes: j['fileSizeBytes'] as int?,
      );

  String get globalKey => '$sourceId:$id';

  @override
  bool operator ==(Object other) =>
      other is Wallpaper && other.globalKey == globalKey;

  @override
  int get hashCode => globalKey.hashCode;
}

/// One page of results returned from a [WallpaperSource].
@immutable
class PagedResult {
  const PagedResult({
    required this.items,
    required this.page,
    this.hasMore = true,
    this.seed,
  });

  final List<Wallpaper> items;
  final int page;
  final bool hasMore;

  /// Some sources (Wallhaven random, Reddit) return a seed/cursor that must be
  /// passed to subsequent pages to keep ordering stable.
  final String? seed;
}
