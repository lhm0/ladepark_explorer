import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/data/settings/sqlite/sqlite_settings_repository.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/vehicle_profile.dart';
import 'package:ladepark_explorer/features/settings/domain/app_settings.dart';
import 'package:sqlite3/sqlite3.dart';

// Persistence contract for FR-I18N-001, FR-NAV-001 and FR-ROUTE-005.
void main() {
  test('persists language, navigation, and automatic update checks', () async {
    final directory = await Directory.systemTemp.createTemp(
      'ladepark-settings',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/settings.sqlite3';

    var repository = await SqliteSettingsRepository.open(path);
    final defaults = await repository.load();
    expect(defaults.language, AppLanguage.system);
    expect(defaults.automaticDatasetChecks, isTrue);
    await repository.save(
      const AppSettings(
        language: AppLanguage.english,
        navigationPreference: NavigationPreference.googleMaps,
        automaticDatasetChecks: false,
      ),
    );
    await repository.close();

    repository = await SqliteSettingsRepository.open(path);
    addTearDown(repository.close);
    final restored = await repository.load();
    expect(restored.language, AppLanguage.english);
    expect(restored.navigationPreference, NavigationPreference.googleMaps);
    expect(restored.automaticDatasetChecks, isFalse);
  });

  test('persists, updates and clears the vehicle profile', () async {
    final directory = await Directory.systemTemp.createTemp('ladepark-vehicle');
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}/settings.sqlite3';

    var repository = await SqliteSettingsRepository.open(path);
    expect(await repository.loadVehicleProfile(), isNull);

    const profile = VehicleProfile(
      usableBatteryKwh: 58.5,
      consumptionKwhPer100Km: 17.2,
      maxChargePowerKw: 150,
      reserveSocPercent: 12,
      targetArrivalSocPercent: 80,
      defaultStartSocPercent: 90,
      connectorTypes: <String>['ccs', 'type_2'],
    );
    await repository.saveVehicleProfile(profile);
    await repository.close();

    repository = await SqliteSettingsRepository.open(path);
    addTearDown(repository.close);
    expect(await repository.loadVehicleProfile(), profile);

    await repository.saveVehicleProfile(
      profile.copyWith(consumptionKwhPer100Km: 19),
    );
    expect((await repository.loadVehicleProfile())?.consumptionKwhPer100Km, 19);

    await repository.clearVehicleProfile();
    expect(await repository.loadVehicleProfile(), isNull);
  });

  test(
    'migrates a version 1 database by adding the vehicle profile table',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'ladepark-migrate',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = '${directory.path}/settings.sqlite3';

      // An existing version-1 settings database without the new table.
      final legacy = sqlite3.open(path);
      legacy.execute('''
      CREATE TABLE app_setting (key TEXT PRIMARY KEY, value TEXT NOT NULL)
      WITHOUT ROWID
    ''');
      legacy.execute(
        "INSERT INTO app_setting (key, value) VALUES ('language', 'german')",
      );
      legacy.userVersion = 1;
      legacy.close();

      final repository = await SqliteSettingsRepository.open(path);
      addTearDown(repository.close);

      expect((await repository.load()).language, AppLanguage.german);
      expect(await repository.loadVehicleProfile(), isNull);
      await repository.saveVehicleProfile(
        const VehicleProfile(
          usableBatteryKwh: 40,
          consumptionKwhPer100Km: 15,
          maxChargePowerKw: 100,
        ),
      );
      expect(await repository.loadVehicleProfile(), isNotNull);
    },
  );
}
