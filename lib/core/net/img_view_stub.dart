import 'package:flutter/widgets.dart';

/// Non-web stub: native platforms never need the HTML element fallback,
/// because CORS only affects browser canvas reads. Returning an empty
/// widget here ensures callers can use [HtmlImg] unconditionally.
Widget buildHtmlImg(String url, BoxFit fit, Alignment alignment) =>
    const SizedBox.shrink();
