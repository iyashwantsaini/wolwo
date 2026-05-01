import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
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
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: settings.themeMode,
      routerConfig: _router,
    );
  }
}
