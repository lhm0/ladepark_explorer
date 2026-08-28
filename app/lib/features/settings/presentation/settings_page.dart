import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/features/dataset_update/application/dataset_update_providers.dart';
import 'package:ladepark_explorer/features/dataset_update/domain/dataset_update_manifest.dart';
import 'package:ladepark_explorer/features/route_planning/application/vehicle_profile_providers.dart';
import 'package:ladepark_explorer/features/settings/application/settings_providers.dart';
import 'package:ladepark_explorer/features/settings/domain/app_settings.dart';
import 'package:ladepark_explorer/features/settings/presentation/privacy_page.dart';
import 'package:ladepark_explorer/features/settings/presentation/vehicle_profile_page.dart';
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
    final update = ref.watch(datasetUpdateControllerProvider);
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
            const Divider(),
            _SectionTitle(strings.datasetUpdates),
            SwitchListTile(
              title: Text(strings.automaticUpdateChecks),
              subtitle: Text(strings.automaticUpdateChecksExplanation),
              value: value.automaticDatasetChecks,
              onChanged: (enabled) => ref
                  .read(settingsControllerProvider.notifier)
                  .setAutomaticDatasetChecks(enabled),
            ),
            _DatasetUpdateTile(update: update),
            const Divider(),
            _SectionTitle(strings.routePlanningTitle),
            const _VehicleProfileTile(),
            const Divider(),
            _SectionTitle(strings.privacy),
            ListTile(
              key: const ValueKey('privacy-and-diagnostics'),
              leading: const Icon(Icons.shield_outlined),
              title: Text(strings.privacyAndDiagnostics),
              subtitle: Text(strings.privacySummary),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => PrivacyPage(
                    automaticDatasetChecks: value.automaticDatasetChecks,
                  ),
                ),
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

class _DatasetUpdateTile extends ConsumerWidget {
  const _DatasetUpdateTile({required this.update});

  final AsyncValue<DatasetUpdateState> update;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    return update.when(
      loading: () => const ListTile(leading: CircularProgressIndicator()),
      error: (_, _) => ListTile(
        title: Text(strings.updateCheckFailed),
        subtitle: Text(strings.installedDatasetRemainsActive),
        trailing: TextButton(
          onPressed: () =>
              ref.read(datasetUpdateControllerProvider.notifier).check(),
          child: Text(strings.tryAgain),
        ),
      ),
      data: (state) {
        final manifest = state.manifest;
        final subtitle = switch (state.phase) {
          DatasetUpdatePhase.idle => strings.updateNotChecked,
          DatasetUpdatePhase.checking => strings.checkingForUpdates,
          DatasetUpdatePhase.upToDate => strings.datasetUpToDate,
          DatasetUpdatePhase.available => strings.updateAvailable(
            manifest!.datasetVersion,
            _megabytes(manifest.artifact.sizeBytes),
          ),
          DatasetUpdatePhase.downloading => strings.downloadingUpdate(
            (state.progress * 100).round(),
          ),
          DatasetUpdatePhase.installed => strings.updateInstalled(
            manifest!.datasetVersion,
          ),
          DatasetUpdatePhase.failed => strings.updateCheckFailed,
        };
        return Column(
          children: [
            ListTile(
              title: Text(strings.chargingDataset),
              subtitle: Text(subtitle),
              trailing: state.phase == DatasetUpdatePhase.available
                  ? FilledButton(
                      onPressed: () => _confirmInstall(context, ref, manifest!),
                      child: Text(strings.downloadUpdate),
                    )
                  : state.phase == DatasetUpdatePhase.checking ||
                        state.phase == DatasetUpdatePhase.downloading
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(),
                    )
                  : TextButton(
                      onPressed: () => ref
                          .read(datasetUpdateControllerProvider.notifier)
                          .check(),
                      child: Text(strings.checkNow),
                    ),
            ),
            if (state.phase == DatasetUpdatePhase.downloading)
              LinearProgressIndicator(value: state.progress),
          ],
        );
      },
    );
  }

  Future<void> _confirmInstall(
    BuildContext context,
    WidgetRef ref,
    DatasetUpdateManifest manifest,
  ) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.downloadUpdate),
        content: Text(
          strings.updateDownloadConfirmation(
            manifest.datasetVersion,
            _megabytes(manifest.artifact.sizeBytes),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.downloadUpdate),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(datasetUpdateControllerProvider.notifier).install();
    }
  }
}

class _VehicleProfileTile extends ConsumerWidget {
  const _VehicleProfileTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final profile = ref.watch(vehicleProfileControllerProvider).value;
    return ListTile(
      key: const ValueKey('vehicle-profile'),
      leading: const Icon(Icons.electric_car_outlined),
      title: Text(strings.vehicleProfileTitle),
      subtitle: Text(
        profile == null
            ? strings.vehicleProfileNotSet
            : strings.vehicleProfileSummary(
                _trimZeros(profile.usableBatteryKwh.toStringAsFixed(1)),
                _trimZeros(profile.consumptionKwhPer100Km.toStringAsFixed(1)),
              ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => VehicleProfilePage(initial: profile),
        ),
      ),
    );
  }
}

String _trimZeros(String value) =>
    value.contains('.') ? value.replaceAll(RegExp(r'\.?0+$'), '') : value;

String _megabytes(int bytes) => (bytes / 1000000).toStringAsFixed(0);

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
}
