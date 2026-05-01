import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/config/api_keys.dart';
import '../../core/theme/design_tokens.dart';
import '../../data/sources/wallpaper_source.dart';

/// First-run setup wizard.
///
/// Shown once on a fresh install (gated by `AppSettings.onboardingDone`).
/// Walks the user through:
///   1. Welcome — what wolwo is, what it does, what data it touches.
///   2. Sources — pick which providers to enable. Toggles persist
///      immediately to SharedPreferences via `setSourceEnabled`.
///   3. Keys — optional API key entry for Wallhaven / Pixabay / NASA.
///      A user-supplied key takes precedence over the build-time
///      `--dart-define` defaults via the override wired in `main.dart`.
///   4. Permissions — request storage / photos so "Apply / Save" works.
///      Skippable; we re-prompt on first use anyway.
///
/// At the end we flip `setOnboardingDone(true)` so the router stops
/// redirecting here. All other settings the user picked during the
/// wizard are already persisted by their individual setters \u2014 nothing
/// to commit at the finish line.
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
    // re-pestered every launch \u2014 the defaults already give a working
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
            // ── Top header bar: brand mark + step counter + skip ──
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Tk.lg, Tk.lg, Tk.lg, Tk.md),
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
                          .copyWith(letterSpacing: 1.6)),
                  const Spacer(),
                  Text(
                    '0${_step + 1} / 04 · ${stepLabels[_step]}',
                    style: Tk.tiny(scheme.outline)
                        .copyWith(letterSpacing: 1.2, fontSize: 10),
                  ),
                ],
              ),
            ),
            _StepDots(total: 4, index: _step),
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
                          parent: anim, curve: Curves.easeOutCubic),
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
            // ── Hairline separator above the action bar so the primary
            //    CTA reads as a docked footer instead of a floating button.
            Container(
              height: Tk.hairline,
              color: scheme.outlineVariant.withValues(alpha: 0.30),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  Tk.lg, Tk.md, Tk.lg, Tk.lg),
              child: Row(
                children: [
                  if (_step > 0)
                    _GhostBtn(
                      label: 'BACK',
                      icon: Icons.arrow_back_rounded,
                      onTap: () => setState(() => _step -= 1),
                    )
                  else
                    _GhostBtn(
                      label: 'SKIP',
                      icon: Icons.close_rounded,
                      onTap: _skip,
                    ),
                  const Spacer(),
                  _PrimaryBtn(
                    label: _step == 3 ? 'GET STARTED' : 'CONTINUE',
                    onTap: _next,
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
        // Hero block: huge wordmark + tagline. Echoes the
        // splash-style typographic intros (large mono title, tiny
        // ALL-CAPS eyebrow, hairline divider underneath).
        Text('A QUIET WALLPAPER BROWSER',
            style: Tk.label(scheme.outline).copyWith(letterSpacing: 1.6)),
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
        const _SpecRow(
          k: 'SOURCES',
          v: 'WALLHAVEN \u00b7 REDDIT \u00b7 NASA \u00b7 PIXABAY',
        ),
        const _SpecRow(k: 'NETWORK', v: 'ONLY THE PROVIDERS YOU ENABLE'),
        const _SpecRow(k: 'STORAGE', v: 'SETTINGS + FAVOURITES, ON DEVICE'),
        const _SpecRow(k: 'TRACKING', v: 'NONE'),
        const SizedBox(height: Tk.lg),
        Text(
          'Tap CONTINUE to pick which providers wolwo should ping.',
          style: Tk.bodySmall(scheme.outline).copyWith(height: 1.5),
        ),
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.k, required this.v});
  final String k;
  final String v;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Tk.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(k,
                style: Tk.label(scheme.outline)
                    .copyWith(letterSpacing: 1.4)),
          ),
          Expanded(
            child: Text(v,
                style: Tk.tiny(scheme.onSurface)
                    .copyWith(letterSpacing: 0.8, fontSize: 11)),
          ),
        ],
      ),
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
          'Wallhaven and Reddit are recommended \u2014 they\'re fastest, '
          'free, and built around real phone wallpapers. NASA and '
          'Pixabay are optional and can be enabled later.',
          style: Tk.bodySmall(scheme.outline).copyWith(height: 1.5),
        ),
        const SizedBox(height: Tk.lg),
        for (final s in sources)
          _OnboardSourceTile(
            source: s,
            enabled: settings.enabledSources.contains(s.id),
            onChanged: (v) => settings.setSourceEnabled(s.id, v),
            recommended: s.id == 'wallhaven' || s.id == 'reddit',
          ),
      ],
    );
  }
}

class _OnboardSourceTile extends StatelessWidget {
  const _OnboardSourceTile({
    required this.source,
    required this.enabled,
    required this.onChanged,
    required this.recommended,
  });

  final WallpaperSource source;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final bool recommended;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: Tk.sm),
      decoration: TkUI.card(scheme),
      child: SwitchListTile.adaptive(
        contentPadding:
            const EdgeInsets.fromLTRB(Tk.lg, Tk.xs, Tk.sm, Tk.xs),
        value: enabled,
        onChanged: onChanged,
        title: Row(
          children: [
            Text(source.displayName,
                style: Tk.h3(scheme.onSurface)
                    .copyWith(fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(width: Tk.sm),
            if (recommended)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: Tk.sm, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.onSurface, width: 1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('RECOMMENDED',
                    style: Tk.tiny(scheme.onSurface)
                        .copyWith(letterSpacing: 1)),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(source.description,
              style: Tk.bodySmall(scheme.outline).copyWith(height: 1.4)),
        ),
      ),
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
    for (final c in _ctrls.values) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Tk.lg, Tk.xl, Tk.lg, Tk.xl),
      children: [
        Text('OPTIONAL API KEYS',
            style: Tk.label(scheme.outline).copyWith(letterSpacing: 1.6)),
        const SizedBox(height: Tk.md),
        Text('Bring your own keys',
            style: Tk.h1(scheme.onSurface).copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.5,
            )),
        const SizedBox(height: Tk.sm + 2),
        Text(
          'wolwo ships with shared default keys so the app works out of '
          'the box. Pasting your own key here gives you higher rate '
          'limits and stops you from sharing a quota with everyone else. '
          'You can leave these blank and add them later.',
          style: Tk.bodySmall(scheme.outline).copyWith(height: 1.5),
        ),
        const SizedBox(height: Tk.lg),
        _KeyField(
          label: 'Wallhaven',
          hint: 'Optional \u2014 unlocks NSFW + higher rate limits',
          controller: _ctrls['wallhaven']!,
          getKeyUrl: 'https://wallhaven.cc/settings/account',
          onChanged: (v) =>
              ref.read(settingsProvider).setUserKey('wallhaven', v),
        ),
        _KeyField(
          label: 'Pixabay',
          hint: ApiKeys.hasPixabay
              ? 'A default key is bundled \u2014 yours overrides it'
              : 'Required to enable Pixabay',
          controller: _ctrls['pixabay']!,
          getKeyUrl: 'https://pixabay.com/api/docs/',
          onChanged: (v) =>
              ref.read(settingsProvider).setUserKey('pixabay', v),
        ),
        _KeyField(
          label: 'NASA',
          hint: 'Optional \u2014 the shared DEMO_KEY is rate-limited',
          controller: _ctrls['nasa']!,
          getKeyUrl: 'https://api.nasa.gov/',
          onChanged: (v) =>
              ref.read(settingsProvider).setUserKey('nasa', v),
        ),
        const SizedBox(height: Tk.md),
        Text('Reddit needs no key \u2014 wolwo just sends a polite User-Agent.',
            style: Tk.meta(scheme.outline)),
      ],
    );
  }
}

class _KeyField extends StatelessWidget {
  const _KeyField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.getKeyUrl,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String getKeyUrl;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: Tk.md),
      padding: const EdgeInsets.fromLTRB(Tk.lg, Tk.md, Tk.lg, Tk.md),
      decoration: TkUI.card(scheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: Tk.h3(scheme.onSurface).copyWith(fontSize: 14)),
              ),
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(getKeyUrl),
                    mode: LaunchMode.externalApplication),
                child: Text('GET KEY \u2192',
                    style: Tk.label(scheme.onSurface)),
              ),
            ],
          ),
          const SizedBox(height: Tk.sm),
          TextField(
            controller: controller,
            onChanged: onChanged,
            style: Tk.body(scheme.onSurface),
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: Tk.bodySmall(scheme.outline),
              filled: true,
              fillColor: scheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: Tk.md, vertical: Tk.md),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Tk.radMd),
                borderSide:
                    BorderSide(color: scheme.outlineVariant, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Tk.radMd),
                borderSide:
                    BorderSide(color: scheme.outlineVariant, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Tk.radMd),
                borderSide: BorderSide(color: scheme.onSurface, width: 1),
              ),
            ),
          ),
        ],
      ),
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
  PermissionStatus? _storage;

  Future<void> _request() async {
    // photos = Android 13+ READ_MEDIA_IMAGES / iOS Photos.
    // storage = legacy Android <13. Both are no-ops on web.
    final p = await Permission.photos.request();
    final s = await Permission.storage.request();
    if (!mounted) return;
    setState(() {
      _photos = p;
      _storage = s;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Tk.lg, Tk.xl, Tk.lg, Tk.xl),
      children: [
        Text('PERMISSIONS',
            style: Tk.label(scheme.outline).copyWith(letterSpacing: 1.6)),
        const SizedBox(height: Tk.md),
        Text('Last thing',
            style: Tk.h1(scheme.onSurface).copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w400,
              letterSpacing: -0.5,
            )),
        const SizedBox(height: Tk.sm + 2),
        Text(
          'wolwo needs gallery access to save wallpapers you download. '
          'Setting them as your home / lock screen uses an in-app '
          'system dialog \u2014 no extra permission required.',
          style: Tk.bodySmall(scheme.outline).copyWith(height: 1.5),
        ),
        const SizedBox(height: Tk.lg),
        Container(
          padding: const EdgeInsets.all(Tk.lg),
          decoration: TkUI.card(scheme),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 20, color: scheme.onSurface),
                  const SizedBox(width: Tk.sm),
                  Text('Photos / gallery',
                      style: Tk.h3(scheme.onSurface)
                          .copyWith(fontSize: 14)),
                  const Spacer(),
                  if (_photos != null)
                    Text(_photos!.isGranted ? 'GRANTED' : 'DENIED',
                        style: Tk.label(_photos!.isGranted
                            ? scheme.onSurface
                            : scheme.outline)),
                ],
              ),
              const SizedBox(height: Tk.sm),
              Text(
                'Required to save downloaded wallpapers to your gallery.',
                style: Tk.bodySmall(scheme.outline).copyWith(height: 1.4),
              ),
              const SizedBox(height: Tk.md),
              _SecondaryBtn(
                label: _photos == null ? 'GRANT ACCESS' : 'RE-REQUEST',
                onTap: _request,
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

// ────────────────────────────────────────────────────────────────────
// Tiny shared widgets
// ────────────────────────────────────────────────────────────────────

class _StepDots extends StatelessWidget {
  const _StepDots({required this.total, required this.index});
  final int total;
  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Tk.lg, 0, Tk.lg, 0),
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            // Each cell is a 3-segment indicator: the leading number,
            // a hairline track that fills with ink as you progress,
            // and a tiny trailing tick when complete. Echoes the
            // step indicator which uses ALL-CAPS step number + bar.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '0${i + 1}',
                    style: Tk.tiny(
                      i <= index ? scheme.onSurface : scheme.outline,
                    ).copyWith(letterSpacing: 0.6, fontSize: 10),
                  ),
                  const SizedBox(height: 6),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    height: 2,
                    color: i <= index
                        ? scheme.onSurface
                        : scheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                ],
              ),
            ),
            if (i < total - 1) const SizedBox(width: Tk.sm + 2),
          ],
        ],
      ),
    );
  }
}

class _GhostBtn extends StatelessWidget {
  const _GhostBtn({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Tk.radMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Tk.md, vertical: Tk.sm + 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: scheme.outline),
            const SizedBox(width: Tk.xs + 2),
            Text(label,
                style: Tk.label(scheme.outline)
                    .copyWith(letterSpacing: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  const _PrimaryBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.onSurface,
      borderRadius: BorderRadius.circular(Tk.radMd),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Tk.radMd),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: Tk.xl, vertical: Tk.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: Tk.label(scheme.surface).copyWith(letterSpacing: 1.4)),
              const SizedBox(width: Tk.sm),
              Icon(Icons.arrow_forward_rounded,
                  size: 16, color: scheme.surface),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  const _SecondaryBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.onSurface, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tk.radMd),
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: Tk.lg, vertical: Tk.sm),
      ),
      child: Text(label,
          style: Tk.label(scheme.onSurface).copyWith(letterSpacing: 1.2)),
    );
  }
}
