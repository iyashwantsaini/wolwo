import 'package:flutter/foundation.dart';

/// Web-only image URL proxy with fallback chain.
///
/// Several wallpaper image hosts (w.wallhaven.cc, th.wallhaven.cc, i.redd.it,
/// preview.redd.it) do not send `Access-Control-Allow-Origin` response
/// headers. Flutter web's CanvasKit fetches images with
/// `crossOrigin=anonymous` and therefore cannot decode them.
///
/// We try multiple free proxies in order and only fall back to the direct
/// URL last (which will only work on native builds or if the host is
/// CORS-friendly).
class ImageProxy {
  static const _badHosts = {
    'w.wallhaven.cc',
    'th.wallhaven.cc',
    'i.redd.it',
    'preview.redd.it',
    'external-preview.redd.it',
    // NASA's CDN serves 200 OK but with `Cross-Origin-Resource-Policy:
    // same-origin` on most assets, which Chrome blocks from being
    // composited into CanvasKit canvas surfaces (the image downloads
    // fine but never paints, leaving blank tiles). Public proxies
    // (weserv/wsrv/corsproxy) work in curl but get rate-limited or
    // CORB-blocked under real-page conditions. The native `<img>`
    // element ignores CORP entirely \u2014 same path Wallhaven and Reddit
    // use, and proven reliable in this app.
    'images-assets.nasa.gov',
    // Pixabay's CDN allows hot-linking but Chrome's CanvasKit decode
    // path frequently stalls on its larger renditions, leaving tiles
    // stuck on the shimmer placeholder. Routing Pixabay through the
    // native <img> element (same trick used for NASA / Reddit) makes
    // them paint immediately just like the rest of the grid.
    'pixabay.com',
    'cdn.pixabay.com',
  };

  /// Reserved for future hosts where the proxy chain is preferable to
  /// the native `<img>` last-resort. Currently empty — NASA was moved
  /// out after blank-tile reports.
  static const _proxyOnlyHosts = <String>{};

  /// Returns true if [url]'s host is known to refuse CORS so callers can
  /// short-circuit to a native `<img>` element on web instead of paying
  /// for the CanvasKit → proxy chain round-trip.
  static bool isBadHost(String url) {
    if (!kIsWeb || url.isEmpty) return false;
    try {
      return _badHosts.contains(Uri.parse(url).host);
    } catch (_) {
      return false;
    }
  }

  /// Returns the first URL to attempt. Kept for back-compat with callers
  /// that don't yet handle a fallback chain.
  static String wrap(String url) {
    final list = candidates(url);
    return list.isEmpty ? url : list.first;
  }

  /// Returns an ordered list of URLs to try. The caller should attempt them
  /// in order and only show a failure once every entry has errored.
  static List<String> candidates(String url) {
    if (url.isEmpty) return const [];
    if (!kIsWeb) return [url];

    Uri u;
    try {
      u = Uri.parse(url);
    } catch (_) {
      return [url];
    }
    if (!_badHosts.contains(u.host) && !_proxyOnlyHosts.contains(u.host)) {
      return [url];
    }

    final stripped = url.replaceFirst(RegExp(r'^https?://'), '');
    final encoded = Uri.encodeComponent(stripped);
    final encodedFull = Uri.encodeComponent(url);
    // Proxy-only hosts (NASA): omit the trailing direct URL — it's
    // guaranteed to fail CanvasKit's CORS check, so attempting it would
    // just delay the user-visible error widget for nothing.
    final isProxyOnly = _proxyOnlyHosts.contains(u.host);
    return [
      'https://images.weserv.nl/?url=$encoded',
      'https://wsrv.nl/?url=$encoded',
      'https://corsproxy.io/?url=$encodedFull',
      if (!isProxyOnly) url, // last-ditch direct attempt
    ];
  }
}
