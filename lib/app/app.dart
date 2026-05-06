import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wolwoloom/wolwoloom.dart';

import 'providers.dart';
import 'router.dart';

class WolwoApp extends ConsumerStatefulWidget {
  const WolwoApp({super.key});

  @override
  ConsumerState<WolwoApp> createState() => _WolwoAppState();
}

class _WolwoAppState extends ConsumerState<WolwoApp> {
  late final _router = buildRouter(
    // Re-read on every navigation so the redirect picks up the user's
    // onboarding completion mid-session.
    getOnboardingDone: () => ref.read(settingsProvider).onboardingDone,
  );

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    // Settings just changed (theme / onboarding flag / etc). Refresh the
    // router so its `redirect` thunk re-runs against the new state.
    _router.refresh();
    return MaterialApp.router(
      title: 'wolwo',
      debugShowCheckedModeBanner: false,
      // Adopt the wolwoloom design system. The package is the externalised
      // version of the bespoke `AppTheme` that used to live in core/theme —
      // same JetBrains-Mono / hairline / periwinkle language, but versioned
      // and shared, so swapping individual widgets for their Wlm* peers
      // (WlmCard, WlmAppBar, WlmListTile, WlmPrimaryButton, ...) just works
      // without a separate styling pass.
      theme: WlmTheme.light(),
      darkTheme: WlmTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: _router,
    );
  }
}
