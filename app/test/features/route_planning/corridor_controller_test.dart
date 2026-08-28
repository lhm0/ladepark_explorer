import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/application/explorer_providers.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_summary.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/application/corridor_providers.dart';

import '../../support/fake_charging_repository.dart';

// Corridor search integration for FR-ROUTE-003 / ADR-0022.
void main() {
  const polyline = <GeoCoordinate>[
    GeoCoordinate(latitude: 52.5, longitude: 13.4),
    GeoCoordinate(latitude: 51.5, longitude: 12.4),
    GeoCoordinate(latitude: 50.1, longitude: 8.7),
    GeoCoordinate(latitude: 48.1, longitude: 11.6),
  ];

  ChargingGroupSummary group(String id, double lat, double lon) =>
      ChargingGroupSummary(
        groupId: id,
        latitude: lat,
        longitude: lon,
        stationCount: 1,
        evseCount: 8,
        hpcEvseCount: 4,
        maxPowerKw: 300,
        city: id,
      );

  Future<ProviderContainer> containerWith(FakeChargingRepository repo) async {
    final container = ProviderContainer(
      overrides: [chargingRepositoryProvider.overrideWith((ref) async => repo)],
    );
    addTearDown(container.dispose);
    await container.read(explorerMapControllerProvider.future);
    return container;
  }

  test('dedupes hits from overlapping sample queries', () async {
    final a = group('park-a', 52.3, 13.2);
    final b = group('park-b', 48.3, 11.4);
    final repo = FakeChargingRepository(
      // Every sample returns both parks; each must appear once.
      findGroupsHandler: (_) async => <ChargingGroupSummary>[b, a, a],
    );
    final container = await containerWith(repo);

    await container.read(corridorControllerProvider.notifier).search(polyline);
    final state = container.read(corridorControllerProvider);

    expect(state.isSearching, isFalse);
    expect(state.hasSearched, isTrue);
    expect(state.done, state.total);
    expect(state.parks.map((park) => park.groupId), <String>[
      'park-a',
      'park-b',
    ]);
    expect(repo.queries.length, state.total);
  });

  test('flags that a sample query hit the result cap', () async {
    final many = List<ChargingGroupSummary>.generate(
      500,
      (index) => group('g$index', 51 + index / 1000, 12),
    );
    final repo = FakeChargingRepository(findGroupsHandler: (_) async => many);
    final container = await containerWith(repo);

    await container.read(corridorControllerProvider.notifier).search(polyline);

    expect(container.read(corridorControllerProvider).limitReached, isTrue);
  });

  test('reports a failure when a sample query throws', () async {
    final repo = FakeChargingRepository(
      findGroupsHandler: (_) async => throw StateError('offline'),
    );
    final container = await containerWith(repo);

    await container.read(corridorControllerProvider.notifier).search(polyline);
    final state = container.read(corridorControllerProvider);

    expect(state.failed, isTrue);
    expect(state.parks, isEmpty);
    expect(state.hasSearched, isTrue);
  });

  test('corridor width steps by 10 km and is clamped to the range', () async {
    final repo = FakeChargingRepository(
      findGroupsHandler: (_) async => const <ChargingGroupSummary>[],
    );
    final container = await containerWith(repo);
    final controller = container.read(corridorControllerProvider.notifier);

    expect(container.read(corridorControllerProvider).widthKm, 20);

    controller.setWidthKm(34);
    expect(container.read(corridorControllerProvider).widthKm, 30);

    controller.setWidthKm(1000);
    expect(container.read(corridorControllerProvider).widthKm, 60);

    controller.setWidthKm(0);
    expect(container.read(corridorControllerProvider).widthKm, 20);
  });

  test('the width sets the query radius and outlives a clear', () async {
    final repo = FakeChargingRepository(
      findGroupsHandler: (_) async => const <ChargingGroupSummary>[],
    );
    final container = await containerWith(repo);
    final controller = container.read(corridorControllerProvider.notifier);

    controller.setWidthKm(60);
    await controller.search(polyline);
    // The radius queried around each sample is half the corridor width.
    expect(repo.queries.first.radiusKm, 30);

    controller.clear();
    // The chosen width is a session preference and outlives a clear.
    expect(container.read(corridorControllerProvider).widthKm, 60);

    controller.setWidthKm(20);
    repo.queries.clear();
    await controller.search(polyline);
    expect(repo.queries.first.radiusKm, 10);
  });
}
