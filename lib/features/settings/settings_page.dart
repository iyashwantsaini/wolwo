import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wolwoloom/wolwoloom.dart';

import '../../app/providers.dart';
import '../../core/config/api_keys.dart';
import '../../core/config/app_config.dart';
import '../../core/net/image_cache_manager.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/sources/wallpaper_source.dart';

/// Settings tab.
///
/// Migrated to the wolwoloom design system: list rows are
/// `WlmListTile`, switches are `WlmSwitchTile`, the theme picker is a
/// `WlmSegmentedControl`, status badges are `WlmBadge`, and the API
/// key editors use `WlmTextField` + `WlmPrimary/SecondaryButton`.
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
          const WlmPageHeader(
            eyebrow: 'preferences',
            title: 'Settings',
          ),
          const WlmSectionLabel('Sources'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tk.lg),
            child: Column(
              children: [
                for (final s in sources) _SourceTile(source: s),
              ],
            ),
          ),
          const WlmSectionLabel('Content'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Tk.lg),
            child: Column(
              children: [
                WlmSwitchTile(
                  title: 'SFW only',
                  subtitle: 'Filter out adult and suggestive content.',
                  value: settings.sfwOnly,
                  onChanged: settings.setSfwOnly,
                ),
                WlmSwitchTile(
                  title: 'Prefer 4K',
                  subtitle:
                      'Bias results toward 3840×2160 and above (uses more data).',
                  value: settings.preferFourK,
                  onChanged: settings.setPreferFourK,
                ),
                WlmSwitchTile(
                  title: 'Demo mode',
                  subtitle:
                      'Replace live feeds with a bundled showcase deck. Useful for offline previews and screenshots.',
                  value: settings.demoMode,
                  onChanged: (v) async {
                    await settings.setDemoMode(v);
                    ref.read(repositoryProvider).clearCache();
                  },
                ),
              ],
            ),
          ),
          const WlmSectionLabel('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Tk.lg, vertical: Tk.xs,),
            child: WlmSegmentedControl<ThemeMode>(
              expand: true,
              segments: const [
                WlmSegment(
                  value: ThemeMode.system,
                  label: 'AUTO',
                  icon: Icons.brightness_auto_outlined,
                ),
                WlmSegment(
                  value: ThemeMode.light,
                  label: 'LIGHT',
                  icon: Icons.light_mode_outlined,
                ),
                WlmSegment(
                  value: ThemeMode.dark,
                  label: 'DARK',
                  icon: Icons.dark_mode_outlined,
                ),
              ],
              value: settings.themeMode,
              onChanged: settings.setThemeMode,
            ),
          ),
          const WlmSectionLabel('Storage'),
          WlmListTile(
            leading: Icon(Icons.cleaning_services_outlined,
                color: scheme.onSurface, size: 18,),
            title: 'Clear image cache',
            subtitle:
                'Frees disk space. Wallpapers will re-download as needed.',
            trailing: Icon(Icons.chevron_right_rounded,
                color: scheme.outline, size: 18,),
            onTap: () async {
              // 1. Empty the on-disk store backing every CachedNetworkImage
              //    in the app (we route everything through this single
              //    manager — see WolwoImageCacheManager).
              //    On web this throws MissingPluginException because
              //    flutter_cache_manager depends on path_provider; swallow
              //    so the in-memory + repo wipes still run and the user
              //    still gets the confirmation snackbar.
              try {
                await WolwoImageCacheManager.instance.emptyCache();
              } catch (_) {}
              // 2. Drop Flutter's in-memory decoded image cache so already
              //    visible tiles release their bytes and re-decode from
              //    the network on next paint.
              PaintingBinding.instance.imageCache.clear();
              PaintingBinding.instance.imageCache.clearLiveImages();
              // 3. Wipe the merged-feed in-memory cache in the wallpaper
              //    repository so the next grid hit refetches from sources.
              ref.read(repositoryProvider).clearCache();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Image cache cleared')),
                );
              }
            },
          ),
          WlmListTile(
            leading: Icon(Icons.history_rounded,
                color: scheme.onSurface, size: 18,),
            title: 'Clear search history',
            subtitle: 'Remove all your recent search queries.',
            trailing: Icon(Icons.chevron_right_rounded,
                color: scheme.outline, size: 18,),
            onTap: () async {
              await settings.clearSearchHistory();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search history cleared')),
                );
              }
            },
          ),
          WlmListTile(
            leading: Icon(Icons.restart_alt_rounded,
                color: scheme.onSurface, size: 18,),
            title: 'Restart setup wizard',
            subtitle:
                'Walk through source selection, API keys and permissions again.',
            trailing: Icon(Icons.chevron_right_rounded,
                color: scheme.outline, size: 18,),
            onTap: () async {
              await settings.setOnboardingDone(false);
              if (context.mounted) context.go('/welcome');
            },
          ),
          const WlmSectionLabel('About'),
          WlmListTile(
            leading: Icon(Icons.info_outline_rounded,
                color: scheme.onSurface, size: 18,),
            title: 'About wolwo',
            subtitle: 'Sources, licenses, privacy.',
            trailing: Icon(Icons.chevron_right_rounded,
                color: scheme.outline, size: 18,),
            onTap: () => context.push('/about'),
          ),
          WlmListTile(
            leading: Icon(Icons.policy_outlined,
                color: scheme.onSurface, size: 18,),
            title: 'Privacy policy',
            trailing: Icon(Icons.chevron_right_rounded,
                color: scheme.outline, size: 18,),
            onTap: () => launchUrl(
              Uri.parse(AppConfig.privacyPolicyUrl),
              mode: LaunchMode.externalApplication,
            ),
          ),
          WlmListTile(
            leading: Icon(Icons.code_rounded,
                color: scheme.onSurface, size: 18,),
            title: 'Open-source licenses',
            trailing: Icon(Icons.chevron_right_rounded,
                color: scheme.outline, size: 18,),
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
                  style: Tk.tiny(scheme.outline)
                      .copyWith(letterSpacing: 1.5),),
            ),
            const SizedBox(height: Tk.lg),
          ],
        ],
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
    switch (id) {
      case 'wallhaven':
        return ApiKeys.wallhaven().isNotEmpty &&
            _userKeyFor('wallhaven').isEmpty;
      case 'pixabay':
        return ApiKeys.pixabay().isNotEmpty && _userKeyFor('pixabay').isEmpty;
      case 'nasa':
        return _userKeyFor('nasa').isEmpty;
      case 'reddit':
        return _userKeyFor('reddit').isEmpty;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final scheme = Theme.of(context).colorScheme;
    final s = widget.source;
    final enabled = settings.enabledSources.contains(s.id);
    final userKey = _userKeyFor(s.id);
    final usingDefault = _hasDefaultBaked(s.id);
    final missingPixabayKey = s.id == 'pixabay' && !ApiKeys.hasPixabay;

    Widget? badge;
    if (s.id == 'reddit') {
      badge = WlmBadge(label: 'no key needed', color: scheme.outline);
    } else if (userKey.isNotEmpty) {
      badge = WlmBadge(label: 'your key', color: scheme.primary);
    } else if (missingPixabayKey) {
      badge = WlmBadge(label: 'needs key', color: scheme.error);
    } else if (usingDefault) {
      badge = WlmBadge(label: 'shared', color: scheme.outline);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: WlmCard(
        elevated: true,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            WlmSwitchTile(
              title: s.displayName,
              subtitle: s.description,
              value: enabled,
              trailingBadge: badge,
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
                      color: scheme.outline,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _expanded
                          ? 'Hide'
                          : (s.id == 'reddit'
                              ? 'Customize User-Agent'
                              : 'Use my own key'),
                      style: TextStyle(
                        color: scheme.outline,
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
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WlmTextField(
          controller: _ctrl,
          label: widget.meta.label,
          hintText: widget.meta.hint,
          obscureText: widget.sourceId != 'reddit',
        ),
        const SizedBox(height: Tk.sm),
        Text(
          widget.meta.help,
          style: TextStyle(fontSize: 12, color: scheme.outline),
        ),
        const SizedBox(height: Tk.md),
        Row(
          children: [
            WlmSecondaryButton(
              label: 'Save',
              uppercase: false,
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
            ),
            const SizedBox(width: Tk.sm),
            WlmGhostButton(
              label: 'Clear',
              uppercase: false,
              onPressed: () async {
                _ctrl.clear();
                await ref
                    .read(settingsProvider)
                    .setUserKey(widget.sourceId, '');
              },
            ),
            const Spacer(),
            WlmGhostButton(
              label: 'Get key',
              icon: Icons.open_in_new_rounded,
              uppercase: false,
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
