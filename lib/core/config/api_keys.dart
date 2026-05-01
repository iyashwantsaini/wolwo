/// API keys for wallpaper sources.
///
/// Keys are read from the build environment via `--dart-define`.
/// **Never commit real keys to source control.**
///
/// ## Local development
/// Create a file `.env.dart-define` (already in `.gitignore`) with:
/// ```
/// --dart-define=WALLHAVEN_API_KEY=your_key_here
/// --dart-define=PIXABAY_API_KEY=your_key_here
/// --dart-define=NASA_API_KEY=DEMO_KEY
/// --dart-define=REDDIT_USER_AGENT=wolwo:com.wolwo.app:v2.0.0 (by /u/yourname)
/// ```
/// Then run:
/// ```
/// flutter run $(Get-Content .env.dart-define -Raw)
/// ```
///
/// ## Production (CI / Play Store builds)
/// Pass via GitHub Actions secrets / Codemagic env vars:
/// ```
/// flutter build appbundle \
///   --dart-define=WALLHAVEN_API_KEY=$WALLHAVEN_API_KEY \
///   --dart-define=PIXABAY_API_KEY=$PIXABAY_API_KEY \
///   --dart-define=NASA_API_KEY=$NASA_API_KEY \
///   --dart-define=REDDIT_USER_AGENT="$REDDIT_USER_AGENT"
/// ```
///
/// ## Where to get keys
/// - Wallhaven: https://wallhaven.cc/settings/account (free, instant)
///   - Optional. SFW search works without it. Only required for NSFW or user data.
/// - Pixabay: https://pixabay.com/api/docs/ (free, instant; email for high-res)
/// - NASA:    https://api.nasa.gov (free, instant; `DEMO_KEY` works for light testing)
/// - Reddit:  no key needed for public JSON; just a custom User-Agent string.
class ApiKeys {
  const ApiKeys._();

  // Build-time defaults from `--dart-define-from-file=.env.dart-define`.
  // These are ONLY used when the user has not entered their own key in
  // Settings. See [ApiKeysResolver] in `app/providers.dart` for the
  // runtime layer that prefers user-supplied overrides.
  static const String _wallhavenDefault = String.fromEnvironment(
    'WALLHAVEN_KEY',
    defaultValue: '',
  );

  static const String _pixabayDefault = String.fromEnvironment(
    'PIXABAY_KEY',
    defaultValue: '',
  );

  static const String _nasaDefault = String.fromEnvironment(
    'NASA_KEY',
    defaultValue: 'DEMO_KEY',
  );

  static const String _redditUaDefault = String.fromEnvironment(
    'REDDIT_USER_AGENT',
    defaultValue: 'wolwo:com.wolwo.app:v2.0.0 (open-source)',
  );

  // Mutable resolver — set in main() before runApp.
  static String Function() wallhaven = () => _wallhavenDefault;
  static String Function() pixabay = () => _pixabayDefault;
  static String Function() nasa = () => _nasaDefault.isEmpty ? 'DEMO_KEY' : _nasaDefault;
  static String Function() redditUserAgent = () => _redditUaDefault;

  static bool get hasWallhaven => wallhaven().isNotEmpty;
  static bool get hasPixabay => pixabay().isNotEmpty;
}
