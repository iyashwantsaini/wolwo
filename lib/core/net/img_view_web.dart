// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/widgets.dart';

const _viewType = 'wolwo-html-img';
bool _registered = false;

void _registerOnce() {
  if (_registered) return;
  _registered = true;
  ui_web.platformViewRegistry.registerViewFactory(
    _viewType,
    (int viewId, {Object? params}) {
      final p = (params as Map?) ?? const {};
      final url = (p['url'] as String?) ?? '';
      final fit = (p['fit'] as String?) ?? 'cover';
      final objPos = (p['objectPosition'] as String?) ?? 'center center';
      final img = html.ImageElement()
        ..src = url
        ..alt = ''
        ..style.objectFit = fit
        ..style.objectPosition = objPos
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..style.border = '0'
        // Let Flutter receive taps on top of this element. Without this, the
        // native <img> swallows clicks and `GestureDetector` never fires.
        ..style.pointerEvents = 'none'
        // Don't ask the browser to perform a CORS preflight — we don't need
        // to read pixels back, we only need to display the image. This is
        // exactly what makes the native `<img>` tag work where CanvasKit
        // doesn't.
        ..setAttribute('referrerpolicy', 'no-referrer')
        ..setAttribute('loading', 'eager')
        ..setAttribute('decoding', 'async');
      // When the source 404s/CORS-blocks, browsers paint a tiny broken-image
      // glyph in the top-left of the element. Hide the element on error so
      // the Flutter fallback (skeleton/blank) is what the user sees instead
      // of that ugly icon. Also hide the alt-text since alt='' already keeps
      // it empty for screen readers when decorative.
      img.onError.listen((_) {
        img.style.visibility = 'hidden';
      });
      return img;
    },
  );
}

Widget buildHtmlImg(String url, BoxFit fit, Alignment alignment) {
  _registerOnce();
  final fitName = switch (fit) {
    BoxFit.cover => 'cover',
    BoxFit.contain => 'contain',
    BoxFit.fill => 'fill',
    BoxFit.fitWidth => 'cover',
    BoxFit.fitHeight => 'cover',
    BoxFit.none => 'none',
    BoxFit.scaleDown => 'scale-down',
  };
  // Map Alignment(-1..1) to CSS object-position percentages (0%..100%).
  final xPct = ((alignment.x + 1) / 2 * 100).clamp(0, 100).toStringAsFixed(2);
  final yPct = ((alignment.y + 1) / 2 * 100).clamp(0, 100).toStringAsFixed(2);
  return HtmlElementView(
    viewType: _viewType,
    creationParams: {
      'url': url,
      'fit': fitName,
      'objectPosition': '$xPct% $yPct%',
    },
  );
}
