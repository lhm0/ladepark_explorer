import 'dart:convert';
import 'dart:io';

import 'package:ladepark_explorer/features/explorer/domain/models/explorer_filters.dart';
import 'package:ladepark_explorer/features/explorer/domain/repositories/explorer_filters_repository.dart';
import 'package:ladepark_explorer/features/park_info/domain/models/park_information.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/vehicle_profile.dart';
import 'package:ladepark_explorer/features/route_planning/domain/repositories/vehicle_profile_repository.dart';
import 'package:ladepark_explorer/features/settings/domain/app_settings.dart';
import 'package:ladepark_explorer/features/settings/domain/settings_repository.dart';
import 'package:sqlite3/sqlite3.dart';

const _profileId = 'default';
const _explorerFiltersKey = 'explorer_filters';

final class SqliteSettingsRepository
    implements
        SettingsRepository,
        VehicleProfileRepository,
        ExplorerFiltersRepository {
  SqliteSettingsRepository._(this._database);

  final Database _database;
  bool _closed = false;

  static Future<SqliteSettingsRepository> open(String databasePath) async {
    final file = File(databasePath);
    await file.parent.create(recursive: true);
    final database = sqlite3.open(databasePath);
    database.execute('PRAGMA journal_mode = WAL');
    if (database.userVersion == 0) {
      database.execute('''
        CREATE TABLE app_setting (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        ) WITHOUT ROWID
      ''');
      database.userVersion = 1;
    }
    if (database.userVersion == 1) {
      database.execute('''
        CREATE TABLE vehicle_profiles (
          id TEXT PRIMARY KEY,
          usable_battery_kwh REAL NOT NULL,
          consumption_kwh_per_100km REAL NOT NULL,
          max_charge_power_kw REAL NOT NULL,
          reserve_soc_percent INTEGER NOT NULL,
          target_arrival_soc_percent INTEGER NOT NULL,
          default_start_soc_percent INTEGER NOT NULL,
          connector_types TEXT NOT NULL
        ) WITHOUT ROWID
      ''');
      database.userVersion = 2;
    }
    if (database.userVersion != 2) {
      database.close();
      throw StateError('Unsupported settings database version.');
    }
    return SqliteSettingsRepository._(database);
  }

  void _ensureOpen() {
    if (_closed) throw StateError('Settings repository is closed.');
  }

  @override
  Future<AppSettings> load() async {
    _ensureOpen();
    final values = <String, String>{
      for (final row in _database.select('SELECT key, value FROM app_setting'))
        row['key']! as String: row['value']! as String,
    };
    return AppSettings(
      language: AppLanguage.values.firstWhere(
        (value) => value.name == values['language'],
        orElse: () => AppLanguage.system,
      ),
      navigationPreference: NavigationPreference.values.firstWhere(
        (value) => value.name == values['navigation_preference'],
        orElse: () => NavigationPreference.askEveryTime,
      ),
      automaticDatasetChecks: values['automatic_dataset_checks'] != 'false',
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    _ensureOpen();
    final statement = _database.prepare('''
      INSERT INTO app_setting (key, value) VALUES (?, ?)
      ON CONFLICT(key) DO UPDATE SET value = excluded.value
    ''');
    try {
      statement.execute(<Object?>['language', settings.language.name]);
      statement.execute(<Object?>[
        'navigation_preference',
        settings.navigationPreference.name,
      ]);
      statement.execute(<Object?>[
        'automatic_dataset_checks',
        settings.automaticDatasetChecks.toString(),
      ]);
    } finally {
      statement.close();
    }
  }

  @override
  Future<VehicleProfile?> loadVehicleProfile() async {
    _ensureOpen();
    final rows = _database.select(
      'SELECT * FROM vehicle_profiles WHERE id = ?',
      <Object?>[_profileId],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    final connectors = (row['connector_types'] as String?) ?? '';
    return VehicleProfile(
      usableBatteryKwh: (row['usable_battery_kwh'] as num).toDouble(),
      consumptionKwhPer100Km: (row['consumption_kwh_per_100km'] as num)
          .toDouble(),
      maxChargePowerKw: (row['max_charge_power_kw'] as num).toDouble(),
      reserveSocPercent: (row['reserve_soc_percent'] as num).toInt(),
      targetArrivalSocPercent: (row['target_arrival_soc_percent'] as num)
          .toInt(),
      defaultStartSocPercent: (row['default_start_soc_percent'] as num).toInt(),
      connectorTypes: connectors.isEmpty
          ? const <String>[]
          : connectors.split('|'),
    );
  }

  @override
  Future<void> saveVehicleProfile(VehicleProfile profile) async {
    _ensureOpen();
    final statement = _database.prepare('''
      INSERT INTO vehicle_profiles (
        id, usable_battery_kwh, consumption_kwh_per_100km, max_charge_power_kw,
        reserve_soc_percent, target_arrival_soc_percent,
        default_start_soc_percent, connector_types
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      ON CONFLICT(id) DO UPDATE SET
        usable_battery_kwh = excluded.usable_battery_kwh,
        consumption_kwh_per_100km = excluded.consumption_kwh_per_100km,
        max_charge_power_kw = excluded.max_charge_power_kw,
        reserve_soc_percent = excluded.reserve_soc_percent,
        target_arrival_soc_percent = excluded.target_arrival_soc_percent,
        default_start_soc_percent = excluded.default_start_soc_percent,
        connector_types = excluded.connector_types
    ''');
    try {
      statement.execute(<Object?>[
        _profileId,
        profile.usableBatteryKwh,
        profile.consumptionKwhPer100Km,
        profile.maxChargePowerKw,
        profile.reserveSocPercent,
        profile.targetArrivalSocPercent,
        profile.defaultStartSocPercent,
        profile.connectorTypes.join('|'),
      ]);
    } finally {
      statement.close();
    }
  }

  @override
  Future<void> clearVehicleProfile() async {
    _ensureOpen();
    _database.execute('DELETE FROM vehicle_profiles WHERE id = ?', <Object?>[
      _profileId,
    ]);
  }

  @override
  Future<ExplorerFilters?> loadFilters() async {
    _ensureOpen();
    final rows = _database.select(
      'SELECT value FROM app_setting WHERE key = ?',
      <Object?>[_explorerFiltersKey],
    );
    if (rows.isEmpty) return null;
    try {
      final map = jsonDecode(rows.first['value']! as String);
      if (map is! Map<String, dynamic>) return null;
      return _filtersFromJson(map);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> saveFilters(ExplorerFilters filters) async {
    _ensureOpen();
    final statement = _database.prepare('''
      INSERT INTO app_setting (key, value) VALUES (?, ?)
      ON CONFLICT(key) DO UPDATE SET value = excluded.value
    ''');
    try {
      statement.execute(<Object?>[
        _explorerFiltersKey,
        jsonEncode(_filtersToJson(filters)),
      ]);
    } finally {
      statement.close();
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _database.close();
  }
}

/// Serialises the persisted filter fields. The transient `nearbyRadiusKm` is
/// intentionally omitted: it needs a live location fix and is not restored.
Map<String, Object?> _filtersToJson(ExplorerFilters filters) =>
    <String, Object?>{
      'diameterM': filters.diameterM,
      'minimumEvseCount': filters.minimumEvseCount,
      'minimumPowerKw': filters.minimumPowerKw,
      'operatorNames': filters.operatorNames,
      'operatorIds': filters.operatorIds,
      'connectorTypes': filters.connectorTypes,
      'requiredAmenities': filters.requiredAmenities
          .map((amenity) => amenity.name)
          .toList(growable: false),
      'alwaysOpenOnly': filters.alwaysOpenOnly,
      'favoritesOnly': filters.favoritesOnly,
    };

ExplorerFilters _filtersFromJson(Map<String, dynamic> map) {
  const defaults = ExplorerFilters.defaults;
  List<String> strings(String key) =>
      (map[key] as List<dynamic>?)?.whereType<String>().toList(
        growable: false,
      ) ??
      const <String>[];
  final amenityByName = <String, AmenityType>{
    for (final amenity in AmenityType.values) amenity.name: amenity,
  };
  return ExplorerFilters(
    diameterM: (map['diameterM'] as num?)?.toInt() ?? defaults.diameterM,
    minimumEvseCount:
        (map['minimumEvseCount'] as num?)?.toInt() ?? defaults.minimumEvseCount,
    minimumPowerKw:
        (map['minimumPowerKw'] as num?)?.toInt() ?? defaults.minimumPowerKw,
    operatorNames: strings('operatorNames'),
    operatorIds: strings('operatorIds'),
    connectorTypes: strings('connectorTypes'),
    requiredAmenities: <AmenityType>[
      for (final name in strings('requiredAmenities')) ?amenityByName[name],
    ],
    alwaysOpenOnly: map['alwaysOpenOnly'] as bool? ?? defaults.alwaysOpenOnly,
    favoritesOnly: map['favoritesOnly'] as bool? ?? defaults.favoritesOnly,
  );
}
