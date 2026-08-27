import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/data/charging/sqlite/sqlite_charging_repository.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_query.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_bounds.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/explorer/domain/repositories/charging_repository_exception.dart';
import 'package:sqlite3/sqlite3.dart';

// Contract tests for FR-MAP-001, FR-GROUP-001, FR-SEARCH-001,
// FR-FILTER-001, FR-FILTER-002, FR-FILTER-003, FR-DETAIL-001, FR-DATA-001,
// NFR-DATA-001, NFR-PERF-001, and NFR-PORT-001.
void main() {
  const contractDatabase = '../contracts/charging_dataset/v2/fixture.sqlite3';
  const germany = GeoBounds(south: 47, west: 5, north: 55, east: 16);

  test(
    'returns the shared contract results for all versioned queries',
    () async {
      final repository = await SqliteChargingRepository.open(contractDatabase);
      addTearDown(repository.close);
      final contract =
          jsonDecode(
                File(
                  '../contracts/charging_dataset/v2/expectations.json',
                ).readAsStringSync(),
              )!
              as Map<String, Object?>;
      final queries = contract['queries']! as List<Object?>;

      for (final contractQuery in queries.cast<Map<String, Object?>>()) {
        final parameters = contractQuery['parameters']! as Map<String, Object?>;
        final expectedIds =
            (contractQuery['expected_group_ids']! as List<Object?>)
                .cast<String>();
        final groups = await repository.findGroups(
          ChargingGroupQuery(
            bounds: germany,
            diameterM: parameters['diameter_m']! as int,
            minimumEvseCount: parameters['minimum_evse_count']! as int,
            minimumPowerKw: parameters['minimum_power_kw']! as int,
            alwaysOpenOnly: parameters['always_open_only'] as bool? ?? false,
            limit: parameters['limit']! as int,
          ),
        );

        expect(
          groups.map((group) => group.groupId),
          expectedIds,
          reason: contractQuery['name']! as String,
        );
      }
    },
  );

  test('maps compact summaries and filters in the database isolate', () async {
    final repository = await SqliteChargingRepository.open(contractDatabase);
    addTearDown(repository.close);

    final groups = await repository.findGroups(
      const ChargingGroupQuery(
        bounds: germany,
        minimumEvseCount: 1,
        minimumPowerKw: 0,
        operatorNames: <String>['Andere Laden GmbH'],
        connectorTypes: <String>['type_2'],
        searchText: 'Münch',
      ),
    );

    expect(groups, hasLength(1));
    final group = groups.single;
    expect(group.groupId, '92c3e75c-2623-5f8c-ae28-1c8f18ee9ee4');
    expect(group.city, 'München');
    expect(group.stationCount, 1);
    expect(group.evseCount, 1);
    expect(group.hpcEvseCount, 0);
    expect(group.maxPowerKw, 22);
  });

  test('filters groups by the requested geodetic radius', () async {
    final repository = await SqliteChargingRepository.open(contractDatabase);
    addTearDown(repository.close);

    final groups = await repository.findGroups(
      const ChargingGroupQuery(
        bounds: germany,
        minimumEvseCount: 1,
        minimumPowerKw: 0,
        center: GeoCoordinate(latitude: 52.52, longitude: 13.405),
        radiusKm: 1,
      ),
    );

    expect(groups, hasLength(1));
    expect(groups.single.city, 'Berlin');
  });

  test('couples always-open access to the charging offer', () async {
    final repository = await SqliteChargingRepository.open(contractDatabase);
    addTearDown(repository.close);

    final groups = await repository.findGroups(
      const ChargingGroupQuery(
        bounds: germany,
        minimumEvseCount: 1,
        minimumPowerKw: 100,
        alwaysOpenOnly: true,
      ),
    );

    expect(groups, hasLength(1));
    expect(groups.single.city, 'Berlin');
  });

  test('filters groups by favorite station anchors', () async {
    final repository = await SqliteChargingRepository.open(contractDatabase);
    addTearDown(repository.close);

    final groups = await repository.findGroups(
      const ChargingGroupQuery(
        bounds: germany,
        minimumEvseCount: 1,
        minimumPowerKw: 0,
        favoriteAnchorStationIds: <String>[
          'fff955ec-a4d7-52ee-9250-46c4d6d53840',
        ],
        favoritesOnly: true,
      ),
    );
    final noGroups = await repository.findGroups(
      const ChargingGroupQuery(
        bounds: germany,
        minimumEvseCount: 1,
        minimumPowerKw: 0,
        favoriteAnchorStationIds: <String>[],
        favoritesOnly: true,
      ),
    );
    final annotatedGroups = await repository.findGroups(
      const ChargingGroupQuery(
        bounds: germany,
        minimumEvseCount: 1,
        minimumPowerKw: 0,
        favoriteAnchorStationIds: <String>[
          'fff955ec-a4d7-52ee-9250-46c4d6d53840',
        ],
      ),
    );

    expect(groups, hasLength(1));
    expect(groups.single.city, 'Berlin');
    expect(groups.single.isFavorite, isTrue);
    expect(noGroups, isEmpty);
    expect(annotatedGroups, hasLength(2));
    expect(
      annotatedGroups.where((group) => group.isFavorite).single.city,
      'Berlin',
    );
  });

  test('filters dynamic groups by editorial amenity anchors', () async {
    final repository = await SqliteChargingRepository.open(contractDatabase);
    addTearDown(repository.close);

    final groups = await repository.findGroups(
      const ChargingGroupQuery(
        bounds: germany,
        minimumEvseCount: 1,
        minimumPowerKw: 0,
        amenityAnchorStationIds: <String>[
          'fff955ec-a4d7-52ee-9250-46c4d6d53840',
        ],
        amenitiesOnly: true,
      ),
    );
    final noGroups = await repository.findGroups(
      const ChargingGroupQuery(
        bounds: germany,
        minimumEvseCount: 1,
        minimumPowerKw: 0,
        amenitiesOnly: true,
      ),
    );

    expect(groups, hasLength(1));
    expect(groups.single.city, 'Berlin');
    expect(noGroups, isEmpty);
  });

  test(
    'loads popular operators, searchable raw names, and connectors',
    () async {
      final repository = await SqliteChargingRepository.open(contractDatabase);
      addTearDown(repository.close);
      final options = await repository.getFilterOptions();
      final popular = await repository.getPopularOperators();
      final searched = await repository.searchOperators('Andere');

      expect(options.connectorTypes, containsAll(<String>['ccs', 'type_2']));
      expect(popular, hasLength(1));
      expect(popular.single.displayName, 'Beispiel Energie');
      expect(popular.single.evseCount, 2);
      expect(popular.single.isCanonical, isTrue);
      final canonicalGroups = await repository.findGroups(
        ChargingGroupQuery(
          bounds: germany,
          minimumEvseCount: 1,
          minimumPowerKw: 0,
          operatorIds: <String>[popular.single.value],
        ),
      );
      expect(canonicalGroups, hasLength(1));
      expect(canonicalGroups.single.city, 'Berlin');
      expect(searched, hasLength(1));
      expect(searched.single.displayName, 'Andere Laden GmbH');
      expect(searched.single.evseCount, 1);
      expect(searched.single.isCanonical, isFalse);
    },
  );

  test('maps group details and returns null for an unknown group', () async {
    final repository = await SqliteChargingRepository.open(contractDatabase);
    addTearDown(repository.close);

    final detail = await repository.getGroupDetail(
      'c151d733-0cd6-5303-b6ef-945d3d5902b5',
    );

    expect(detail, isNotNull);
    expect(detail!.stationCount, 1);
    expect(detail.anchorStationId, 'fff955ec-a4d7-52ee-9250-46c4d6d53840');
    expect(detail.evseCount, 2);
    expect(detail.name, 'Testpark Nord');
    expect(detail.city, 'Berlin');
    expect(detail.latitude, 52.52);
    expect(detail.longitude, 13.405);
    expect(detail.maxPowerKw, 300);
    expect(detail.openingHours, '24/7');
    expect(detail.powerBandCounts[100], 2);
    expect(detail.datasetVersion, '2026.07.0-contract');
    expect(detail.sourceName, 'Liste der Ladesäulen');
    expect(detail.sourceVersion, '2026-07-07-contract');
    expect(detail.operators, hasLength(1));
    expect(detail.operators.single.name, 'Beispiel Energie');
    expect(
      detail.operators.single.connectorCountsByPowerBand,
      <int, Map<String, int>>{
        5: <String, int>{'ccs': 2},
      },
    );
    expect(detail.connectorTypes, <String>['ccs']);
    expect(await repository.getGroupDetail('missing'), isNull);
    final resolved = await repository.getGroupDetailContainingStation(
      detail.anchorStationId,
      100,
    );
    expect(resolved?.groupId, 'f288894a-0748-5488-992b-31c719f6fb7e');
    expect(
      await repository.getGroupDetailContainingStation('missing', 50),
      isNull,
    );
  });

  test('keeps the shared database unchanged', () async {
    final file = File(contractDatabase);
    final bytesBefore = file.readAsBytesSync();
    final repository = await SqliteChargingRepository.open(contractDatabase);
    await repository.findGroups(const ChargingGroupQuery(bounds: germany));
    await repository.close();

    expect(file.readAsBytesSync(), bytesBefore);
  });

  test('resolves a favorite through an explicit station alias', () async {
    final directory = Directory.systemTemp.createTempSync(
      'ladepark-alias-test-',
    );
    addTearDown(() => directory.deleteSync(recursive: true));
    final copy = File('${directory.path}/charging.sqlite3');
    File(contractDatabase).copySync(copy.path);
    final database = sqlite3.open(copy.path);
    database.execute(
      '''INSERT INTO station_id_alias(old_station_id, current_station_id, reason)
         VALUES (?, ?, ?)''',
      <Object?>[
        'former-station-id',
        'fff955ec-a4d7-52ee-9250-46c4d6d53840',
        'test',
      ],
    );
    database.close();

    final repository = await SqliteChargingRepository.open(copy.path);
    addTearDown(repository.close);
    final detail = await repository.getGroupDetailContainingStation(
      'former-station-id',
      50,
    );

    expect(detail?.groupId, 'c151d733-0cd6-5303-b6ef-945d3d5902b5');
  });

  test('translates missing and unsupported databases', () async {
    await expectLater(
      SqliteChargingRepository.open('/path/that/does/not/exist.sqlite3'),
      throwsA(
        isA<ChargingRepositoryException>().having(
          (error) => error.error,
          'error',
          ChargingRepositoryError.databaseNotFound,
        ),
      ),
    );

    final temporaryDirectory = Directory.systemTemp.createTempSync(
      'ladepark-m2-test-',
    );
    addTearDown(() => temporaryDirectory.deleteSync(recursive: true));
    final incompatible = File(
      '${temporaryDirectory.path}/incompatible.sqlite3',
    );
    File(contractDatabase).copySync(incompatible.path);
    final database = sqlite3.open(incompatible.path);
    database.userVersion = 3;
    database.close();

    await expectLater(
      SqliteChargingRepository.open(incompatible.path),
      throwsA(
        isA<ChargingRepositoryException>().having(
          (error) => error.error,
          'error',
          ChargingRepositoryError.unsupportedSchema,
        ),
      ),
    );

    final incomplete = File('${temporaryDirectory.path}/incomplete.sqlite3');
    final incompleteDatabase = sqlite3.open(incomplete.path);
    incompleteDatabase.userVersion = 2;
    incompleteDatabase.close();
    await expectLater(
      SqliteChargingRepository.open(incomplete.path),
      throwsA(
        isA<ChargingRepositoryException>().having(
          (error) => error.error,
          'error',
          ChargingRepositoryError.unsupportedSchema,
        ),
      ),
    );
  });

  test('rejects invalid queries and use after close', () async {
    final repository = await SqliteChargingRepository.open(contractDatabase);
    await expectLater(
      repository.findGroups(
        const ChargingGroupQuery(bounds: germany, searchText: '   '),
      ),
      throwsA(
        isA<ChargingRepositoryException>().having(
          (error) => error.error,
          'error',
          ChargingRepositoryError.invalidQuery,
        ),
      ),
    );
    await repository.close();

    await expectLater(
      repository.findGroups(const ChargingGroupQuery(bounds: germany)),
      throwsA(
        isA<ChargingRepositoryException>().having(
          (error) => error.error,
          'error',
          ChargingRepositoryError.repositoryClosed,
        ),
      ),
    );
  });
}
