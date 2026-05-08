import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wolwoloom/wolwoloom.dart';

import '../../app/providers.dart';
import '../../core/config/api_keys.dart';
import '../../core/theme/design_tokens.dart';

/// First-run setup wizard.
///
/// Shown once on a fresh install (gated by `AppSettings.onboardingDone`).
/// Walks the user through:
///   1. Welcome — what wolwo is, what data it touches.
///   2. Sources — pick which providers to enable.
///   3. Keys — optional API key entry for Wallhaven / Pixabay / NASA.
///   4. Permissions — request photos so "Apply / Save" works.
///
/// Migrated to wolwoloom: step dots are `WlmStepDots`, key fields are
/// `WlmKeyField`, source toggles are `WlmSwitchTile` with `WlmBadge`,
/// spec rows are `WlmSpecRow`, and the action bar uses
/// `WlmGhostButton` + `WlmPrimaryButton`.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _step = 0;

  void _next() {
    if (_step < 3) {
      setState(() => _step += 1);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final settings = ref.read(settingsProvider);
    await settings.setOnboardingDone(true);
    if (!mounted) return;
    context.go('/');
  }

  Future<void> _skip() async {
    // Skipping still marks onboarding complete so the user doesn't get
    // re-pestered every launch — the defaults already give a working
    // app (Wallhaven + Reddit on, NASA + Pixabay off).
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final stepLabels = const ['WELCOME', 'SOURCES', 'KEYS', 'PERMISSIONS'];
    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Tk.lg, Tk.lg, Tk.lg, Tk.md,),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: scheme.onSurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        'W',
                        style: Tk.tiny(scheme.surface).copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Tk.sm + 2),
                  Text('WOLWO  ::  SETUP',
                      style: Tk.label(scheme.onSurface)
                          .copyWith(letterSpacing: 1.6),),
                  const Spacer(),
                  Text(
                    '0${_step + 1} / 04 \u00b7 ${stepLabels[_step]}',
                    style: Tk.tiny(scheme.outline)
                        .copyWith(letterSpacing: 1.2, fontSize: 10),
                  ),
                ],
              ),
            ),
            WlmStepDots(total: 4, index: _step),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.04),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                          parent: anim, curve: Curves.easeOutCubic,),
                    ),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: switch (_step) {
                    0 => const _WelcomeStep(),
                    1 => const _SourcesStep(),
                    2 => const _KeysStep(),
                    _ => const _PermissionsStep(),
                  },
                ),
              ),
            ),
            Container(
              height: Tk.hairline,
              color: scheme.outlineVariant.withValues(alpha: 0.30),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Tk.lg, Tk.md, Tk.lg, Tk.lg,),
              child: Row(
                children: [
                  if (_step > 0)
                    WlmGhostButton(
                      label: 'Back',
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => setState(() => _step -= 1),
                    )
                  else
                    WlmGhostButton(
                      label: 'Skip',
                      icon: Icons.close_rounded,
                      onPressed: _skip,
                    ),
                  const Spacer(),
                  WlmPrimaryButton(
                    label: _step == 3 ? 'Get started' : 'Continue',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _open(String url) {
  // ignore: discarded_futures
  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

// ────────────────────────────────────────────────────────────────────
// Step 1: Welcome
// ────────────────────────────────────────────────────────────────────

class _WelcomeStep extends StatelessWidget {
  const _WelcomeStep();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Tk.lg, Tk.xl, Tk.lg, Tk.xl),
      children: [
        Text('A QUIET WALLPAPER BROWSER',
            style: Tk.label(scheme.outline).copyWith(letterSpacing: 1.6),),
        const SizedBox(height: Tk.md),
        Text(
          'wolwo',
          style: Tk.h1(scheme.onSurface).copyWith(
            fontSize: 56,
            fontWeight: FontWeight.w300,
            letterSpacing: -1.5,
            height: 1.0,
          ),
        ),
        const SizedBox(height: Tk.lg),
        Text(
          'Phone-shaped, high-resolution wallpapers from a few '
          'community libraries. No accounts, no analytics, '
          'everything local.',
          style: Tk.body(scheme.onSurface).copyWith(height: 1.6),
        ),
        const SizedBox(height: Tk.xl),
        Container(
          height: Tk.hairline,
          color: scheme.outlineVariant.withValues(alpha: 0.30),
        ),
        const SizedBox(height: Tk.lg),
        const WlmSpecRow(
          label: 'SOURCES',
          value: 'WALLHAVEN \u00b7 REDDIT \u00b7 NASA \u00b7 PIXABAY',
        ),
        const WlmSpecRow(
          label: 'NETWORK',
          value: 'ONLY THE PROVIDERS YOU ENABLE',
        ),
        const WlmSpecRow(
          label: 'STORAGE',
          value: 'SETTINGS + FAVOURITES, ON DEVICE',
        ),
        const WlmSpecRow(label: 'TRACKING', value: 'NONE'),
        const SizedBox(height: Tk.lg),
        Text(
          'Tap CONTINUE to pick which providers wolwo should ping.',
          style: Tk.bodySmall(scheme.outline).copyWith(height: 1.5),
        ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Step 2: Sources
// ────────────────────────────────────────────────────────────────────

class _SourcesStep extends ConsumerWidget {
  const _SourcesStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final settings = ref.watch(settingsProvider);
    final sources = ref.watch(sourcesProvider);
    return ListView(
      padding: const EdgeInsets.fromLTRB(Tk.lg, Tk.lg, Tk.lg, Tk.xl),
      children: [
        Text('STEP 2 OF 4', style: Tk.label(scheme.outline)),
        const SizedBox(height: Tk.sm),
        Text('Pick your sources', style: Tk.h1(scheme.onSurface)),
        const SizedBox(height: Tk.sm),
        Text(
          "Wallhaven and Reddit are recommended \u2014 they're fastest, "
          'free, and built around real phone wallpapers. NASA and '
          'Pixabay are optional and can be enabled later.',
          style: Tk.bodySmall(scheme.outline).copyWith(height: 1.5),
        ),
        const SizedBox(height: Tk.lg),
        for (final s in sources)
          WlmSwitchTile(
            title: s.displayName,
            subtitle: s.description,
            value: settings.enabledSources.contains(s.id),
            trailingBadge: (s.id == 'wallhaven' || s.id == 'reddit')
                ? WlmBadge(label: 'recommended', color: scheme.onSurface)
                : null,
            onChanged: (v) => settings.setSourceEnabled(s.id, v),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Step 3: API keys
// ────────────────────────────────────────────────────────────────────

class _KeysStep extends ConsumerStatefulWidget {
  const _KeysStep();

  @override
  ConsumerState<_KeysStep> createState() => _KeysStepState();
}

class _KeysStepState extends ConsumerState<_KeysStep> {
  late final Map<String, TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _ctrls = {
      'wallhaven': TextEditingController(text: s.userWallhavenKey()),
      'pixabay': TextEditingController(text: s.userPixabayKey()),
      'nasa': TextEditingController(text: s.userNasaKey()),
    };
  }

  @override
  void dispose() {
    for (final c in _ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Tk.lg, Tk.xl, Tk.lg, Tk.xl),
      children: [
        Text('OPTIONAL API KEYS',
            style: Tk.label(scheme.outline).copyWith(letterSpacing: 1.6),),
        const SizedBox(height: Tk.md),
        Text('Bring your own keys',
            style: Tk.h1(scheme.onSurface).copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.5,
            ),),
        const SizedBox(height: Tk.sm + 2),
        Text(
          'wolwo ships with shared default keys so the app works out of '
          'the box. Pasting your own key here gives you higher rate '
          'limits and stops you from sharing a quota with everyone else. '
          'You can leave these blank and add them later.',
          style: Tk.bodySmall(scheme.outline).copyWith(height: 1.5),
        ),
        const SizedBox(height: Tk.lg),
        WlmKeyField(
          label: 'Wallhaven',
          hintText: 'Optional \u2014 unlocks NSFW + higher rate limits',
          controller: _ctrls['wallhaven'],
          getKeyUrl: 'https://wallhaven.cc/settings/account',
          onGetKey: () => _open('https://wallhaven.cc/settings/account'),
          onChanged: (v) =>
              ref.read(settingsProvider).setUserKey('wallhaven', v),
        ),
        const SizedBox(height: Tk.md),
        WlmKeyField(
          label: 'Pixabay',
          hintText: ApiKeys.hasPixabay
              ? 'A default key is bundled \u2014 yours overrides it'
              : 'Required to enable Pixabay',
          controller: _ctrls['pixabay'],
          getKeyUrl: 'https://pixabay.com/api/docs/',
          onGetKey: () => _open('https://pixabay.com/api/docs/'),
          onChanged: (v) =>
              ref.read(settingsProvider).setUserKey('pixabay', v),
        ),
        const SizedBox(height: Tk.md),
        WlmKeyField(
          label: 'NASA',
          hintText: 'Optional \u2014 the shared DEMO_KEY is rate-limited',
          controller: _ctrls['nasa'],
          getKeyUrl: 'https://api.nasa.gov/',
          onGetKey: () => _open('https://api.nasa.gov/'),
          onChanged: (v) =>
              ref.read(settingsProvider).setUserKey('nasa', v),
        ),
        const SizedBox(height: Tk.md),
        Text(
            'Reddit needs no key \u2014 wolwo just sends a polite User-Agent.',
            style: Tk.meta(scheme.outline),),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────
// Step 4: Permissions
// ────────────────────────────────────────────────────────────────────

class _PermissionsStep extends StatefulWidget {
  const _PermissionsStep();

  @override
  State<_PermissionsStep> createState() => _PermissionsStepState();
}

class _PermissionsStepState extends State<_PermissionsStep> {
  PermissionStatus? _photos;

  Future<void> _request() async {
    // photos = Android 13+ READ_MEDIA_IMAGES / iOS Photos.
    // storage = legacy Android <13. Both are no-ops on web.
    final p = await Permission.photos.request();
    await Permission.storage.request();
    if (!mounted) return;
    setState(() {
      _photos = p;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Tk.lg, Tk.xl, Tk.lg, Tk.xl),
      children: [
        Text('PERMISSIONS',
            style: Tk.label(scheme.outline).copyWith(letterSpacing: 1.6),),
        const SizedBox(height: Tk.md),
        Text('Last thing',
            style: Tk.h1(scheme.onSurface).copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.5,
            ),),
        const SizedBox(height: Tk.sm + 2),
        Text(
          'wolwo needs gallery access to save wallpapers you download. '
          'Setting them as your home / lock screen uses an in-app '
          'system dialog \u2014 no extra permission required.',
          style: Tk.bodySmall(scheme.outline).copyWith(height: 1.5),
        ),
        const SizedBox(height: Tk.lg),
        WlmCard(
          elevated: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 20, color: scheme.onSurface,),
                  const SizedBox(width: Tk.sm),
                  Text('Photos / gallery',
                      style: Tk.h3(scheme.onSurface)
                          .copyWith(fontSize: 14),),
                  const Spacer(),
                  if (_photos != null)
                    WlmBadge(
                      label: _photos!.isGranted ? 'granted' : 'denied',
                      color: _photos!.isGranted
                          ? scheme.primary
                          : scheme.error,
                    ),
                ],
              ),
              const SizedBox(height: Tk.sm),
              Text(
                'Required to save downloaded wallpapers to your gallery.',
                style: Tk.bodySmall(scheme.outline).copyWith(height: 1.4),
              ),
              const SizedBox(height: Tk.md),
              WlmSecondaryButton(
                label: _photos == null ? 'Grant access' : 'Re-request',
                onPressed: _request,
              ),
            ],
          ),
        ),
        const SizedBox(height: Tk.md),
        Text(
          'You can skip this step \u2014 wolwo will ask again the first '
          'time you download a wallpaper.',
          style: Tk.meta(scheme.outline),
        ),
      ],
    );
  }
}
