import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/data/settings/sqlite/sqlite_settings_repository.dart';
import 'package:ladepark_explorer/features/settings/domain/app_settings.dart';
import 'package:ladepark_explorer/features/settings/domain/settings_repository.dart';
import 'package:path_provider/path_provider.dart';

final settingsRepositoryProvider = FutureProvider<SettingsRepository>((
  ref,
) async {
  final directory = await getApplicationSupportDirectory();
  final repository = await SqliteSettingsRepository.open(
    '${directory.path}/settings.sqlite3',
  );
  ref.onDispose(() => unawaited(repository.close()));
  return repository;
});

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );

final class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async =>
      (await ref.watch(settingsRepositoryProvider.future)).load();

  Future<void> setLanguage(AppLanguage language) async {
    await _save(state.requireValue.copyWith(language: language));
  }

  Future<void> setNavigationPreference(
    NavigationPreference navigationPreference,
  ) async {
    await _save(
      state.requireValue.copyWith(navigationPreference: navigationPreference),
    );
  }

  Future<void> setAutomaticDatasetChecks(bool enabled) async {
    await _save(state.requireValue.copyWith(automaticDatasetChecks: enabled));
  }

  Future<void> _save(AppSettings settings) async {
    await (await ref.read(settingsRepositoryProvider.future)).save(settings);
    state = AsyncData(settings);
  }
}
