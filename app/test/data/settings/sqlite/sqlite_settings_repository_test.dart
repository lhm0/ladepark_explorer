import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/data/settings/sqlite/sqlite_settings_repository.dart';
import 'package:ladepark_explorer/features/settings/domain/app_settings.dart';

// Persistence contract for FR-I18N-001 and FR-NAV-001.
void main() {
  test('persists language and navigation preference', () async {
    final directory = await Directory.systemTemp.createTemp(
      'ladepark-settings',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/settings.sqlite3';

    var repository = await SqliteSettingsRepository.open(path);
    expect((await repository.load()).language, AppLanguage.system);
    await repository.save(
      const AppSettings(
        language: AppLanguage.english,
        navigationPreference: NavigationPreference.googleMaps,
      ),
    );
    await repository.close();

    repository = await SqliteSettingsRepository.open(path);
    addTearDown(repository.close);
    final restored = await repository.load();
    expect(restored.language, AppLanguage.english);
    expect(restored.navigationPreference, NavigationPreference.googleMaps);
  });
}
