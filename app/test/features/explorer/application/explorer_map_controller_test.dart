import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/application/explorer_providers.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_detail.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_summary.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/explorer_filters.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_bounds.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/park_info/domain/models/park_information.dart';

import '../../../support/fake_charging_repository.dart';

// State integration for FR-MAP-001, FR-FILTER-002, FR-FILTER-003, FR-DETAIL-001,
// NFR-OFFLINE-001, and NFR-PERF-001.
void main() {
  test('debounces bounds and adds the specified map-query margin', () async {
    const group = ChargingGroupSummary(
      groupId: 'group-1',
      latitude: 52.5,
      longitude: 13.4,
      stationCount: 1,
      evseCount: 2,
      hpcEvseCount: 2,
      maxPowerKw: 300,
      city: 'Berlin',
    );
    final repository = FakeChargingRepository(
      groups: const <ChargingGroupSummary>[group],
    );
    final container = ProviderContainer(
      overrides: [
        chargingRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(explorerMapControllerProvider.future);
    final controller = container.read(explorerMapControllerProvider.notifier);

    controller.visibleBoundsChanged(
      const GeoBounds(south: 50, west: 10, north: 52, east: 14),
    );
    controller.visibleBoundsChanged(
      const GeoBounds(south: 51, west: 11, north: 53, east: 15),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));

    expect(repository.queries, hasLength(1));
    final query = repository.queries.single;
    expect(query.bounds.south, closeTo(50.85, 0.000001));
    expect(query.bounds.north, closeTo(53.15, 0.000001));
    expect(query.bounds.west, closeTo(10.7, 0.000001));
    expect(query.bounds.east, closeTo(15.3, 0.000001));
    expect(query.minimumPowerKw, 100);
    expect(
      container.read(explorerMapControllerProvider).value!.groups,
      <ChargingGroupSummary>[group],
    );
  });

  test('loads details only after a group is selected', () async {
    const detail = ChargingGroupDetail(
      groupId: 'group-1',
      anchorStationId: 'station-1',
      stationIds: <String>['station-1'],
      name: 'Example Park',
      street: 'Example Street',
      houseNumber: '1',
      postalCode: '10115',
      city: 'Berlin',
      latitude: 52.5,
      longitude: 13.4,
      stationCount: 1,
      evseCount: 2,
      maxPowerKw: 300,
      actualDiameterM: 0,
      operators: <ChargingOperatorDetail>[
        ChargingOperatorDetail(
          name: 'Example Energy',
          connectorCountsByPowerBand: <int, Map<String, int>>{
            5: <String, int>{'ccs': 2},
          },
        ),
      ],
      connectorTypes: <String>['ccs'],
      powerBandCounts: <int, int>{100: 2},
      openingHours: '24/7',
      datasetVersion: 'test',
      datasetCreatedAt: '2026-08-23T00:00:00Z',
      sourceName: 'Example source',
      sourceVersion: '2026-08-01',
    );
    final repository = FakeChargingRepository(detail: detail);
    final container = ProviderContainer(
      overrides: [
        chargingRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(explorerMapControllerProvider.future);

    final result = await container
        .read(explorerMapControllerProvider.notifier)
        .loadGroupDetail('group-1');

    expect(result, same(detail));
  });

  test('searches Germany locally with the active filters', () async {
    final repository = FakeChargingRepository();
    final container = ProviderContainer(
      overrides: [
        chargingRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(explorerMapControllerProvider.future);

    await container
        .read(explorerMapControllerProvider.notifier)
        .searchGroups('Hamburg');

    final query = repository.queries.single;
    expect(query.searchText, 'Hamburg');
    expect(query.minimumEvseCount, 20);
    expect(query.minimumPowerKw, 100);
    expect(query.limit, 50);
  });

  test('uses an exact-radius query for nearby charging parks', () async {
    final repository = FakeChargingRepository();
    final container = ProviderContainer(
      overrides: [
        chargingRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(explorerMapControllerProvider.future);
    final controller = container.read(explorerMapControllerProvider.notifier);

    controller.showNearby(
      const GeoCoordinate(latitude: 53.5511, longitude: 9.9937),
      25,
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    final query = repository.queries.single;
    expect(
      query.center,
      const GeoCoordinate(latitude: 53.5511, longitude: 9.9937),
    );
    expect(query.radiusKm, 25);
    expect(query.bounds.south, lessThan(53.5511));
    expect(query.bounds.north, greaterThan(53.5511));
    expect(
      container
          .read(explorerMapControllerProvider)
          .value!
          .filters
          .nearbyRadiusKm,
      25,
    );

    controller.clearNearby();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(
      container
          .read(explorerMapControllerProvider)
          .value!
          .filters
          .nearbyRadiusKm,
      isNull,
    );
    expect(repository.queries.last.radiusKm, isNull);
  });

  test('expands around a place until it finds the nearest park', () async {
    const group = ChargingGroupSummary(
      groupId: 'nearest',
      latitude: 53.65,
      longitude: 10,
      stationCount: 1,
      evseCount: 20,
      hpcEvseCount: 20,
      maxPowerKw: 300,
      city: 'Norderstedt',
    );
    final repository = FakeChargingRepository(
      findGroupsHandler: (query) async => query.radiusKm! < 25
          ? const <ChargingGroupSummary>[]
          : const <ChargingGroupSummary>[group],
    );
    final container = ProviderContainer(
      overrides: [
        chargingRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(explorerMapControllerProvider.future);

    final target = await container
        .read(explorerMapControllerProvider.notifier)
        .findNearestPark(
          const GeoCoordinate(latitude: 53.5511, longitude: 9.9937),
        );

    expect(repository.queries.map((query) => query.radiusKm), <double>[
      5,
      10,
      25,
    ]);
    expect(
      target?.center,
      const GeoCoordinate(latitude: 53.5511, longitude: 9.9937),
    );
    expect(target?.nearestGroup, same(group));
    expect(target!.radiusKm, greaterThan(5));
  });

  test('applies changed filters immediately to the current bounds', () async {
    final repository = FakeChargingRepository();
    final container = ProviderContainer(
      overrides: [
        chargingRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(explorerMapControllerProvider.future);
    final controller = container.read(explorerMapControllerProvider.notifier);
    controller.visibleBoundsChanged(
      const GeoBounds(south: 50, west: 10, north: 52, east: 14),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));

    controller.filtersChanged(
      const ExplorerFilters(
        diameterM: 100,
        minimumEvseCount: 4,
        minimumPowerKw: 150,
        operatorNames: <String>['Example Energy'],
        operatorIds: <String>['canonical-example-energy'],
        connectorTypes: <String>['ccs'],
        requiredAmenities: <AmenityType>[AmenityType.toilet],
        alwaysOpenOnly: true,
        favoritesOnly: true,
      ),
      favoriteAnchorStationIds: const <String>['favorite-station'],
      amenityAnchorStationIds: const <String>['amenity-station'],
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(repository.queries, hasLength(2));
    final query = repository.queries.last;
    expect(query.diameterM, 100);
    expect(query.minimumEvseCount, 4);
    expect(query.minimumPowerKw, 150);
    expect(query.operatorNames, <String>['Example Energy']);
    expect(query.operatorIds, <String>['canonical-example-energy']);
    expect(query.connectorTypes, <String>['ccs']);
    expect(query.favoriteAnchorStationIds, <String>['favorite-station']);
    expect(query.amenityAnchorStationIds, <String>['amenity-station']);
    expect(query.amenitiesOnly, isTrue);
    expect(query.alwaysOpenOnly, isTrue);
  });

  test('refreshes normal map markers when favorite anchors change', () async {
    final repository = FakeChargingRepository();
    final container = ProviderContainer(
      overrides: [
        chargingRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(explorerMapControllerProvider.future);
    final controller = container.read(explorerMapControllerProvider.notifier);
    controller.visibleBoundsChanged(
      const GeoBounds(south: 50, west: 10, north: 52, east: 14),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));

    controller.favoriteAnchorsChanged(const <String>['favorite-station']);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(repository.queries, hasLength(2));
    expect(repository.queries.last.favoriteAnchorStationIds, <String>[
      'favorite-station',
    ]);
    expect(repository.queries.last.favoritesOnly, isFalse);
  });

  test('coalesces rapid bounds while a query is running', () async {
    const oldGroup = ChargingGroupSummary(
      groupId: 'old',
      latitude: 52,
      longitude: 13,
      stationCount: 1,
      evseCount: 1,
      hpcEvseCount: 1,
      maxPowerKw: 150,
      city: 'Berlin',
    );
    const latestGroup = ChargingGroupSummary(
      groupId: 'latest',
      latitude: 48,
      longitude: 11,
      stationCount: 1,
      evseCount: 2,
      hpcEvseCount: 2,
      maxPowerKw: 300,
      city: 'München',
    );
    final pendingQueries = <Completer<List<ChargingGroupSummary>>>[];
    final repository = FakeChargingRepository(
      findGroupsHandler: (query) {
        final completer = Completer<List<ChargingGroupSummary>>();
        pendingQueries.add(completer);
        return completer.future;
      },
    );
    final container = ProviderContainer(
      overrides: [
        chargingRepositoryProvider.overrideWith((ref) async => repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(explorerMapControllerProvider.future);
    final controller = container.read(explorerMapControllerProvider.notifier);

    controller.visibleBoundsChanged(
      const GeoBounds(south: 51, west: 12, north: 53, east: 14),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(pendingQueries, hasLength(1));

    controller.visibleBoundsChanged(
      const GeoBounds(south: 49, west: 10, north: 51, east: 12),
    );
    controller.visibleBoundsChanged(
      const GeoBounds(south: 47, west: 9, north: 49, east: 13),
    );
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(pendingQueries, hasLength(1));

    pendingQueries.first.complete(const <ChargingGroupSummary>[oldGroup]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(pendingQueries, hasLength(2));
    expect(
      container.read(explorerMapControllerProvider).value!.groups,
      isEmpty,
    );

    pendingQueries.last.complete(const <ChargingGroupSummary>[latestGroup]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(repository.queries, hasLength(2));
    expect(repository.queries.last.bounds.south, closeTo(46.85, 0.000001));
    expect(
      container.read(explorerMapControllerProvider).value!.groups,
      const <ChargingGroupSummary>[latestGroup],
    );
  });
}
