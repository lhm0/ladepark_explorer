import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/features/settings/application/settings_providers.dart';
import 'package:ladepark_explorer/features/settings/domain/app_settings.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';
import 'package:ladepark_explorer/platform/navigation/navigation_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final googleAvailable =
        ref.watch(googleMapsAvailableProvider).value ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(strings.settingsUnavailable)),
        data: (value) => ListView(
          children: [
            _SectionTitle(strings.language),
            RadioGroup<AppLanguage>(
              groupValue: value.language,
              onChanged: (choice) => _setLanguage(ref, choice),
              child: Column(
                children: [
                  RadioListTile<AppLanguage>(
                    title: Text(strings.systemLanguage),
                    value: AppLanguage.system,
                  ),
                  RadioListTile<AppLanguage>(
                    title: Text(strings.german),
                    value: AppLanguage.german,
                  ),
                  RadioListTile<AppLanguage>(
                    title: Text(strings.english),
                    value: AppLanguage.english,
                  ),
                ],
              ),
            ),
            const Divider(),
            _SectionTitle(strings.navigationApp),
            RadioGroup<NavigationPreference>(
              groupValue: value.navigationPreference,
              onChanged: (choice) => _setNavigation(ref, choice),
              child: Column(
                children: [
                  RadioListTile<NavigationPreference>(
                    title: Text(strings.askEveryTime),
                    value: NavigationPreference.askEveryTime,
                  ),
                  const RadioListTile<NavigationPreference>(
                    title: Text('Apple Maps'),
                    value: NavigationPreference.appleMaps,
                  ),
                  RadioListTile<NavigationPreference>(
                    title: const Text('Google Maps'),
                    subtitle: googleAvailable
                        ? null
                        : Text(strings.notInstalled),
                    value: NavigationPreference.googleMaps,
                    enabled: googleAvailable,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setLanguage(WidgetRef ref, AppLanguage? choice) {
    if (choice != null) {
      ref.read(settingsControllerProvider.notifier).setLanguage(choice);
    }
  }

  void _setNavigation(WidgetRef ref, NavigationPreference? choice) {
    if (choice != null) {
      ref
          .read(settingsControllerProvider.notifier)
          .setNavigationPreference(choice);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}
