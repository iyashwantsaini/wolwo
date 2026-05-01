import 'package:flutter/widgets.dart';

import 'img_view_stub.dart' if (dart.library.html) 'img_view_web.dart'
    as impl;

/// Native-`<img>`-element renderer for web.
///
/// Flutter web's CanvasKit decodes images by uploading them as WebGL
/// textures, which requires `Access-Control-Allow-Origin` headers. Some
/// wallpaper hosts (Wallhaven, Reddit) don't send those headers, so the
/// image \u2014 even though the browser can fetch it fine \u2014 shows up blank
/// inside Flutter.
///
/// A native `<img>` element rendered through `HtmlElementView` has no such
/// limitation: the browser paints the image directly, no canvas upload
/// involved. We use this as a robust fallback for those hosts on web.
///
/// On non-web platforms this widget returns nothing \u2014 callers should
/// continue to use [Image] / `cached_network_image` there.
class HtmlImg extends StatelessWidget {
  const HtmlImg({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final String url;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) =>
      impl.buildHtmlImg(url, fit, alignment);
}
