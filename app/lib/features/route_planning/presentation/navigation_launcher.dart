import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/features/settings/application/settings_providers.dart';
import 'package:ladepark_explorer/features/settings/domain/app_settings.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';
import 'package:ladepark_explorer/platform/navigation/navigation_adapter.dart';
import 'package:ladepark_explorer/platform/navigation/navigation_providers.dart';

/// Resolves which navigation app to use, honouring the saved preference,
/// whether Google Maps is installed and the ask / fallback dialogs
/// (FR-NAV-001, ADR-0016). Returns null if the user cancelled.
Future<NavigationAdapter?> resolveNavigationAdapter(
  BuildContext context,
  WidgetRef ref,
) async {
  final strings = AppLocalizations.of(context);
  final preference =
      ref.read(settingsControllerProvider).value?.navigationPreference ??
      NavigationPreference.askEveryTime;
  final google = ref.read(googleMapsNavigationAdapterProvider);
  final apple = ref.read(appleMapsNavigationAdapterProvider);
  final googleAvailable = await google.isAvailable();
  if (!context.mounted) return null;

  var choice = preference;
  if (preference == NavigationPreference.askEveryTime && googleAvailable) {
    choice =
        await showModalBottomSheet<NavigationPreference>(
          context: context,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: const Text('Apple Maps'),
                  onTap: () =>
                      Navigator.pop(context, NavigationPreference.appleMaps),
                ),
                ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: const Text('Google Maps'),
                  onTap: () =>
                      Navigator.pop(context, NavigationPreference.googleMaps),
                ),
              ],
            ),
          ),
        ) ??
        NavigationPreference.askEveryTime;
    if (choice == NavigationPreference.askEveryTime) return null;
  } else if (preference == NavigationPreference.askEveryTime) {
    choice = NavigationPreference.appleMaps;
  }

  if (!context.mounted) return null;
  if (choice == NavigationPreference.googleMaps && !googleAvailable) {
    final useApple = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.googleMapsUnavailable),
        content: Text(strings.googleMapsFallbackExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.useAppleMaps),
          ),
        ],
      ),
    );
    if (!context.mounted || useApple != true) return null;
    choice = NavigationPreference.appleMaps;
  }

  return choice == NavigationPreference.googleMaps ? google : apple;
}

/// Hands the planned route to the chosen navigation app (FR-ROUTE-011) and
/// explains it if that app could not take every charging stop.
Future<void> launchRouteInNavigationApp(
  BuildContext context,
  WidgetRef ref,
  NavigationRoute route,
) async {
  final adapter = await resolveNavigationAdapter(context, ref);
  if (adapter == null || !context.mounted) return;
  final strings = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final handoff = await adapter.openRoute(route);
    if (handoff.truncated) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.routeNavigationTruncated)),
      );
    }
  } on Object {
    messenger.showSnackBar(
      SnackBar(content: Text(strings.navigationUnavailable)),
    );
  }
}
