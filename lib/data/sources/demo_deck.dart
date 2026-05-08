import '../models/wallpaper.dart';

/// Process-wide flag: when true, the wallpaper repository ignores all
/// configured network sources and serves a fixed bundled deck instead.
///
/// Toggled by [AppSettings.setDemoMode] / read on boot. The flag is a
/// plain global so the repository (which is plumbed through Riverpod
/// before the settings object exists) can branch on it without taking a
/// new dependency.
class DemoMode {
  DemoMode._();
  static bool enabled = false;
}

/// A small, self-contained demo deck used for marketing screenshots and
/// offline development. Every entry points at a JPG bundled under
/// `assets/screenshots/demo/` via the custom `asset:` URL scheme that
/// `NetworkImageWithFallback` recognises.
class DemoDeck {
  DemoDeck._();

  static const List<String> _names = [
    'wall_01.jpg', 'wall_02.jpg', 'wall_03.jpg', 'wall_04.jpg',
    'wall_05.jpg', 'wall_06.jpg', 'wall_07.jpg', 'wall_08.jpg',
    'wall_09.jpg', 'wall_10.jpg', 'wall_11.jpg', 'wall_12.jpg',
  ];

  static const List<List<String>> _meta = [
    ['Cobalt rise',    '#1F3B57', 'gradient,blue,minimal'],
    ['Charcoal',       '#16191D', 'dark,minimal,grey'],
    ['Amber dawn',     '#FF5C39', 'orange,sunset,warm'],
    ['Mossy green',    '#1B5E2A', 'green,nature,forest'],
    ['Violet drift',   '#7C5BFF', 'purple,space,dreamy'],
    ['Rose glass',     '#FF7AA2', 'pink,abstract,soft'],
    ['True black',     '#000000', 'amoled,black,minimal'],
    ['Teal mint',      '#3FCFB0', 'teal,fresh,abstract'],
    ['Desert dune',    '#E1A85F', 'desert,sand,warm'],
    ['Neon sakura',    '#FF3D6E', 'pink,neon,city'],
    ['Mustard noir',   '#F4D35E', 'yellow,minimal,bold'],
    ['Code ink',       '#58A6FF', 'blue,minimal,dev'],
  ];

  static List<Wallpaper> all() {
    final out = <Wallpaper>[];
    for (var i = 0; i < _names.length; i++) {
      final m = _meta[i];
      final url = 'asset:///screenshots/demo/${_names[i]}';
      out.add(Wallpaper(
        id: 'demo-${i + 1}',
        sourceId: 'demo',
        thumbUrl: url,
        previewUrl: url,
        fullUrl: url,
        width: 1440,
        height: 2560,
        colorHex: m[1],
        tags: m[2].split(','),
        author: 'wolwo demo',
        license: 'Bundled placeholder',
      ),);
    }
    return out;
  }

  /// Slice + rotate the deck so different routes show different rows
  /// without us shipping more art. [seed] should be stable per route /
  /// query so screenshots are reproducible.
  static List<Wallpaper> page(int seed, {int count = 12}) {
    final deck = all();
    final start = seed.abs() % deck.length;
    return List.generate(count, (i) => deck[(start + i) % deck.length]);
  }
}
