import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'image_proxy.dart';
import 'img.dart';

/// Network image that walks an [ImageProxy.candidates] fallback chain.
///
/// On web some image hosts (Wallhaven, Reddit) refuse CORS, so we route
/// them through public proxy mirrors. Any single mirror can rate-limit or
/// 404 a specific URL, so we try them in order.
///
/// As an absolute last resort on web we render the **direct** URL through
/// a native `<img>` element ([HtmlImg]). The browser paints `<img>` tags
/// without requiring CORS headers (only canvas readbacks do), so this
/// almost always succeeds even when every CanvasKit attempt failed.
class NetworkImageWithFallback extends StatefulWidget {
  const NetworkImageWithFallback({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholder,
    this.fadeIn = const Duration(milliseconds: 180),
    this.onAllFailed,
  });

  final String url;
  final BoxFit fit;
  final Alignment alignment;
  final WidgetBuilder? placeholder;
  final Duration fadeIn;
  final VoidCallback? onAllFailed;

  @override
  State<NetworkImageWithFallback> createState() =>
      _NetworkImageWithFallbackState();
}

class _NetworkImageWithFallbackState extends State<NetworkImageWithFallback> {
  late List<String> _chain;
  int _idx = 0;
  bool _useHtmlImg = false;

  @override
  void initState() {
    super.initState();
    _chain = ImageProxy.candidates(widget.url);
    // For known CORS-blocked / CORP-restricted hosts (Wallhaven, Reddit,
    // NASA images bucket) on web, skip the proxy chain entirely and
    // render through a native <img> from the start. The proxies *do*
    // work in curl, but under real-page conditions they get rate-limited
    // or CORB-blocked and leave tiles blank. The native `<img>` element
    // ignores both CORS and CORP, so it's both faster and more reliable.
    if (ImageProxy.isBadHost(widget.url)) _useHtmlImg = true;
  }

  @override
  void didUpdateWidget(covariant NetworkImageWithFallback old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _chain = ImageProxy.candidates(widget.url);
      _idx = 0;
      _useHtmlImg = ImageProxy.isBadHost(widget.url);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Last-resort: native <img> via platform view. Always succeeds for
    // hosts that allow hot-linking (which Wallhaven and Reddit do).
    if (_useHtmlImg) {
      if (kIsWeb) {
        return HtmlImg(
          url: widget.url,
          fit: widget.fit,
          alignment: widget.alignment,
        );
      }
      _notifyAllFailed();
      return widget.placeholder?.call(context) ?? const SizedBox.shrink();
    }

    if (_chain.isEmpty) {
      _notifyAllFailed();
      return widget.placeholder?.call(context) ?? const SizedBox.shrink();
    }

    final current = _chain[_idx];
    return CachedNetworkImage(
      // Cache key is stable across proxy mirrors so the image is only
      // decoded once even if we had to retry.
      cacheKey: widget.url,
      imageUrl: current,
      fit: widget.fit,
      alignment: widget.alignment,
      fadeInDuration: widget.fadeIn,
      placeholder: (ctx, _) =>
          widget.placeholder?.call(ctx) ?? const SizedBox.shrink(),
      errorWidget: (_, __, ___) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_idx + 1 < _chain.length) {
            setState(() => _idx += 1);
          } else if (kIsWeb && !_useHtmlImg) {
            // Every CanvasKit attempt failed \u2014 fall back to the native
            // <img> element which doesn't need CORS to display.
            setState(() => _useHtmlImg = true);
          } else {
            _notifyAllFailed();
          }
        });
        return widget.placeholder?.call(context) ?? const SizedBox.shrink();
      },
    );
  }

  /// Notify the parent on the next frame to avoid `setState` during build.
  void _notifyAllFailed() {
    if (widget.onAllFailed == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onAllFailed?.call();
    });
  }
}
