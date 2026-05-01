import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../core/config/app_config.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(sourcesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'wolwo',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1.5,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            AppConfig.appTagline,
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 8),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (_, snap) => Text(
              snap.hasData ? 'v${snap.data!.version} (${snap.data!.buildNumber})' : '',
              style: TextStyle(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Image sources',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'wolwo aggregates wallpapers from multiple public APIs. Each '
            'image stays the property of its original creator. Tap a source '
            'below to read its license and privacy terms.',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
          const SizedBox(height: 16),
          for (final s in sources) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.displayName,
                        style: Theme.of(context).textTheme.titleMedium,),
                    const SizedBox(height: 4),
                    Text(s.description,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,),),
                    const SizedBox(height: 12),
                    Text(s.licenseSummary,
                        style: Theme.of(context).textTheme.bodySmall,),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.gavel_outlined, size: 16),
                          label: const Text('License'),
                          onPressed: () => launchUrl(s.licenseUrl,
                              mode: LaunchMode.externalApplication,),
                        ),
                        if (s.privacyUrl != null)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.policy_outlined, size: 16),
                            label: const Text('Privacy'),
                            onPressed: () => launchUrl(s.privacyUrl!,
                                mode: LaunchMode.externalApplication,),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          Text(
            'How attribution works',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Whenever a source returns the photographer or uploader, wolwo '
            'shows their name on the wallpaper detail screen with a link back '
            'to their profile or the original page. If you believe an image '
            'infringes your rights, use the "Report" button on the wallpaper '
            'screen and we will remove it from caching and recommendations.',
            style: TextStyle(color: Theme.of(context).colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
