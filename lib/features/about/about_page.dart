import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wolwoloom/wolwoloom.dart';

import '../../app/providers.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/design_tokens.dart';

/// "About" screen — sources, attribution, version.
///
/// Migrated to wolwoloom: top bar is a `WlmAppBar` with a `WlmIconButton`
/// leading, source cards are `WlmCard`, action chips are
/// `WlmGhostButton`s, headings use `WlmType` styles via `Tk.h*` helpers.
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(sourcesProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: WlmAppBar(
        title: 'About',
        leading: WlmIconButton(
          icon: Icons.arrow_back_rounded,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Tk.lg, Tk.sm, Tk.lg, Tk.xl),
        children: [
          Text('wolwo', style: Tk.display(scheme.onSurface)),
          const SizedBox(height: 4),
          Text(
            AppConfig.appTagline,
            style: Tk.bodySmall(scheme.outline).copyWith(height: 1.4),
          ),
          const SizedBox(height: Tk.sm),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (_, snap) => Text(
              snap.hasData
                  ? 'v${snap.data!.version} (${snap.data!.buildNumber})'
                  : '',
              style: Tk.meta(scheme.outline),
            ),
          ),
          const SizedBox(height: Tk.xl),
          Text('Image sources', style: Tk.h2(scheme.onSurface)),
          const SizedBox(height: Tk.sm),
          Text(
            'wolwo aggregates wallpapers from multiple public APIs. Each '
            'image stays the property of its original creator. Tap a source '
            'below to read its license and privacy terms.',
            style: Tk.bodySmall(scheme.outline).copyWith(height: 1.5),
          ),
          const SizedBox(height: Tk.lg),
          for (final s in sources) ...[
            WlmCard(
              elevated: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.displayName, style: Tk.h3(scheme.onSurface)),
                  const SizedBox(height: 4),
                  Text(s.description,
                      style: Tk.bodySmall(scheme.outline)
                          .copyWith(height: 1.4),),
                  const SizedBox(height: Tk.md),
                  Text(s.licenseSummary,
                      style: Tk.meta(scheme.outline).copyWith(height: 1.5),),
                  const SizedBox(height: Tk.md),
                  Wrap(
                    spacing: Tk.sm,
                    runSpacing: Tk.sm,
                    children: [
                      WlmGhostButton(
                        label: 'License',
                        icon: Icons.gavel_outlined,
                        uppercase: false,
                        onPressed: () => launchUrl(s.licenseUrl,
                            mode: LaunchMode.externalApplication,),
                      ),
                      if (s.privacyUrl != null)
                        WlmGhostButton(
                          label: 'Privacy',
                          icon: Icons.policy_outlined,
                          uppercase: false,
                          onPressed: () => launchUrl(s.privacyUrl!,
                              mode: LaunchMode.externalApplication,),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: Tk.sm),
          ],
          const SizedBox(height: Tk.lg),
          Text('How attribution works', style: Tk.h2(scheme.onSurface)),
          const SizedBox(height: Tk.sm),
          Text(
            'Whenever a source returns the photographer or uploader, wolwo '
            'shows their name on the wallpaper detail screen with a link back '
            'to their profile or the original page. If you believe an image '
            'infringes your rights, use the "Report" button on the wallpaper '
            'screen and we will remove it from caching and recommendations.',
            style: Tk.bodySmall(scheme.outline).copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
