import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/config/api_keys.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/sources/wallpaper_source.dart';
import '../common/page_header.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _version = '${info.version}+${info.buildNumber}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final sources = ref.watch(sourcesProvider);

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const PageHeader(
            eyebrow: 'preferences',
            title: 'Settings',
          ),
          const SectionLabel('Sources'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tk.lg),
            child: Column(
              children: [
                for (final s in sources) _SourceTile(source: s),
              ],
            ),
          ),
          const SectionLabel('Content'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tk.lg),
            child: Column(
              children: [
                _SettingSwitch(
                  title: 'SFW only',
                  subtitle: 'Filter out adult and suggestive content.',
                  value: settings.sfwOnly,
                  onChanged: settings.setSfwOnly,
                ),
                _SettingSwitch(
                  title: 'Prefer 4K',
                  subtitle:
                      'Bias results toward 3840×2160 and above (uses more data).',
                  value: settings.preferFourK,
                  onChanged: settings.setPreferFourK,
                ),
              ],
            ),
          ),
          const SectionLabel('Appearance'),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: Tk.lg, vertical: Tk.xs),
            child: SegmentedButton<ThemeMode>(
              style: SegmentedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Tk.radMd),
                ),
              ),
              segments: [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(Icons.brightness_auto_outlined, size: 16),
                  label: Text('AUTO',
                      style: Tk.tiny(scheme.onSurface)
                          .copyWith(fontSize: 11, letterSpacing: 1.0),),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(Icons.light_mode_outlined, size: 16),
                  label: Text('LIGHT',
                      style: Tk.tiny(scheme.onSurface)
                          .copyWith(fontSize: 11, letterSpacing: 1.0),),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(Icons.dark_mode_outlined, size: 16),
                  label: Text('DARK',
                      style: Tk.tiny(scheme.onSurface)
                          .copyWith(fontSize: 11, letterSpacing: 1.0),),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (s) => settings.setThemeMode(s.first),
            ),
          ),
          const SectionLabel('Storage'),
          _SettingRow(
            icon: Icons.cleaning_services_outlined,
            title: 'Clear image cache',
            subtitle:
                'Frees disk space. Wallpapers will re-download as needed.',
            onTap: () async {
              await CachedNetworkImage.evictFromCache('');
              await DefaultCacheManager().emptyCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image cache cleared')),
                );
              }
            },
          ),
          _SettingRow(
            icon: Icons.history_rounded,
            title: 'Clear search history',
            subtitle: 'Remove all your recent search queries.',
            onTap: () async {
              await settings.clearSearchHistory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search history cleared')),
                );
              }
            },
          ),
          _SettingRow(
            icon: Icons.restart_alt_rounded,
            title: 'Restart setup wizard',
            subtitle:
                'Walk through source selection, API keys and permissions again.',
            onTap: () async {
              await settings.setOnboardingDone(false);
              if (context.mounted) context.go('/welcome');
            },
          ),
          const SectionLabel('About'),
          _SettingRow(
            icon: Icons.info_outline_rounded,
            title: 'About wolwo',
            subtitle: 'Sources, licenses, privacy.',
            onTap: () => context.push('/about'),
          ),
          _SettingRow(
            icon: Icons.policy_outlined,
            title: 'Privacy policy',
            onTap: () => launchUrl(
              Uri.parse(AppConfig.privacyPolicyUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          _SettingRow(
            icon: Icons.code_rounded,
            title: 'Open-source licenses',
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'wolwo',
              applicationVersion: _version,
            ),
          ),
          if (_version.isNotEmpty) ...[
            const SizedBox(height: Tk.md),
            Center(
              child: Text('WOLWO  ::  v$_version',
                  style: Tk.tiny(scheme.outline).copyWith(letterSpacing: 1.5),),
            ),
            const SizedBox(height: Tk.lg),
          ],
        ],
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Tk.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Tk.body(scheme.onSurface)),
                const SizedBox(height: 2),
                Text(subtitle, style: Tk.meta(scheme.outline)),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Tk.lg, vertical: Tk.md,),
        child: Row(
          children: [
            Icon(icon, color: scheme.onSurface, size: 18),
            const SizedBox(width: Tk.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Tk.body(scheme.onSurface)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: Tk.meta(scheme.outline)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: scheme.outline, size: 18,),
          ],
        ),
      ),
    );
  }
}

class _SourceTile extends ConsumerStatefulWidget {
  const _SourceTile({required this.source});
  final WallpaperSource source;

  @override
  ConsumerState<_SourceTile> createState() => _SourceTileState();
}

class _SourceTileState extends ConsumerState<_SourceTile> {
  bool _expanded = false;

  // Per-source key metadata: label + helper + getter for live default + url.
  ({String label, String hint, String help, String url, String current})
      _meta(String currentUserKey) {
    switch (widget.source.id) {
      case 'wallhaven':
        return (
          label: 'API key',
          hint: 'Optional — paste your Wallhaven API key',
          help:
              'Unlocks NSFW search and higher rate limits. Get one at wallhaven.cc/settings/account.',
          url: 'https://wallhaven.cc/settings/account',
          current: currentUserKey,
        );
      case 'pixabay':
        return (
          label: 'API key',
          hint: 'Required — paste your Pixabay API key',
          help:
              'Pixabay needs an API key. Free at pixabay.com/api/docs (instant signup).',
          url: 'https://pixabay.com/api/docs/',
          current: currentUserKey,
        );
      case 'nasa':
        return (
          label: 'API key',
          hint: 'Optional — paste your api.nasa.gov key',
          help:
              'Default DEMO_KEY is shared and rate-limited (~30 req/hr). Get your own free key at api.nasa.gov.',
          url: 'https://api.nasa.gov/',
          current: currentUserKey,
        );
      case 'reddit':
        return (
          label: 'Custom User-Agent (optional)',
          hint: 'e.g. wolwo:v2 (by /u/your_handle)',
          help:
              'Reddit’s public JSON endpoints don’t need an API key — wolwo just sends a User-Agent string. Setting your own slightly improves rate limits and is polite per Reddit’s API rules.',
          url: 'https://github.com/reddit-archive/reddit/wiki/API',
          current: currentUserKey,
        );
      default:
        return (label: '', hint: '', help: '', url: '', current: '');
    }
  }

  String _userKeyFor(String id) {
    final s = ref.read(settingsProvider);
    return switch (id) {
      'wallhaven' => s.userWallhavenKey(),
      'pixabay' => s.userPixabayKey(),
      'nasa' => s.userNasaKey(),
      'reddit' => s.userRedditUserAgent(),
      _ => '',
    };
  }

  bool _hasDefaultBaked(String id) {
    // Returns true if the build-time --dart-define provided something usable.
    switch (id) {
      case 'wallhaven':
        return ApiKeys.wallhaven().isNotEmpty &&
            _userKeyFor('wallhaven').isEmpty;
      case 'pixabay':
        return ApiKeys.pixabay().isNotEmpty && _userKeyFor('pixabay').isEmpty;
      case 'nasa':
        return _userKeyFor('nasa').isEmpty; // always has DEMO_KEY default
      case 'reddit':
        return _userKeyFor('reddit').isEmpty;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final s = widget.source;
    final enabled = settings.enabledSources.contains(s.id);
    final userKey = _userKeyFor(s.id);
    final usingDefault = _hasDefaultBaked(s.id);
    final missingPixabayKey = s.id == 'pixabay' && !ApiKeys.hasPixabay;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
            title: Row(
              children: [
                Text(s.displayName),
                const SizedBox(width: 8),
                if (s.id == 'reddit')
                  _Pill(
                    text: 'no key needed',
                    color: Theme.of(context).colorScheme.outline,
                  )
                else if (userKey.isNotEmpty)
                  _Pill(
                    text: 'your key',
                    color: Theme.of(context).colorScheme.primary,
                  )
                else if (missingPixabayKey)
                  _Pill(
                    text: 'needs key',
                    color: Theme.of(context).colorScheme.error,
                  )
                else if (usingDefault)
                  _Pill(
                    text: 'shared',
                    color: Theme.of(context).colorScheme.outline,
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                s.description,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.outline),
              ),
            ),
            value: enabled,
            onChanged: (v) => settings.setSourceEnabled(s.id, v),
          ),
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _expanded
                        ? 'Hide'
                        : (s.id == 'reddit'
                            ? 'Customize User-Agent'
                            : 'Use my own key'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.outline,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _KeyEditor(
                sourceId: s.id,
                meta: _meta(userKey),
              ),
            ),
        ],
      ),
    );
  }
}

class _KeyEditor extends ConsumerStatefulWidget {
  const _KeyEditor({required this.sourceId, required this.meta});
  final String sourceId;
  final ({String label, String hint, String help, String url, String current})
      meta;

  @override
  ConsumerState<_KeyEditor> createState() => _KeyEditorState();
}

class _KeyEditorState extends ConsumerState<_KeyEditor> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.meta.current);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            labelText: widget.meta.label,
            hintText: widget.meta.hint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          obscureText: widget.sourceId != 'reddit',
        ),
        const SizedBox(height: 8),
        Text(
          widget.meta.help,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton.tonal(
              onPressed: () async {
                await ref
                    .read(settingsProvider)
                    .setUserKey(widget.sourceId, _ctrl.text);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Key saved')),
                  );
                }
              },
              child: const Text('Save'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () async {
                _ctrl.clear();
                await ref
                    .read(settingsProvider)
                    .setUserKey(widget.sourceId, '');
              },
              child: const Text('Clear'),
            ),
            const Spacer(),
            TextButton.icon(
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Get key'),
              onPressed: () => launchUrl(
                Uri.parse(widget.meta.url),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
