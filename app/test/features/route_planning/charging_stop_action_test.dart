import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/application/explorer_providers.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_detail.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_bounds.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/explorer/presentation/map_screen.dart';
import 'package:ladepark_explorer/features/route_planning/application/route_planning_providers.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_leg.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_option.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_request.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_waypoint.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';

import '../../support/fake_charging_repository.dart';
import '../../support/fake_explorer_filters_repository.dart';
import '../../support/fake_route_planning_service.dart';

// FR-ROUTE-004: the park detail can add the park as a charging stop.
void main() {
  const detail = ChargingGroupDetail(
    groupId: 'corridor-park',
    anchorStationId: 'station-9',
    stationIds: <String>['station-9'],
    name: 'Rasthof Mitte',
    street: 'A9',
    houseNumber: '1',
    postalCode: '07381',
    city: 'Mittelstadt',
    latitude: 50.7,
    longitude: 11.9,
    stationCount: 2,
    evseCount: 12,
    maxPowerKw: 300,
    actualDiameterM: 40,
    operators: <ChargingOperatorDetail>[],
    connectorTypes: <String>['CCS'],
    powerBandCounts: <int, int>{300: 12},
    openingHours: null,
    datasetVersion: '2026.07.0-test',
    datasetCreatedAt: '2026-08-23T00:00:00Z',
    sourceName: 'Bundesnetzagentur',
    sourceVersion: '2026-07-07',
  );

  const request = RouteRequest(
    origin: RouteWaypoint(
      coordinate: GeoCoordinate(latitude: 52.5, longitude: 13.4),
    ),
    destination: RouteWaypoint(
      coordinate: GeoCoordinate(latitude: 48.1, longitude: 11.6),
    ),
  );

  final option = RouteOption(
    totalDistanceKm: 585,
    totalTravelTime: const Duration(hours: 5),
    boundingBox: const GeoBounds(south: 48, west: 11, north: 53, east: 14),
    polyline: const <GeoCoordinate>[
      GeoCoordinate(latitude: 52.5, longitude: 13.4),
      GeoCoordinate(latitude: 48.1, longitude: 11.6),
    ],
    legs: const <RouteLeg>[],
  );

  testWidgets('inserts the park as a charging stop and returns', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        explorerFiltersRepositoryProvider.overrideWith(
          (ref) async => FakeExplorerFiltersRepository(),
        ),
        chargingRepositoryProvider.overrideWith(
          (ref) async => FakeChargingRepository(detail: detail),
        ),
        routePlanningServiceProvider.overrideWithValue(
          FakeRoutePlanningService(options: <RouteOption>[option]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(explorerMapControllerProvider.future);
    await container
        .read(routePlanningControllerProvider.notifier)
        .planRoute(request);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                key: const ValueKey('open-detail'),
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => GroupDetailPage(
                      future: Future<ChargingGroupDetail?>.value(detail),
                      enableFavoriteAction: false,
                      showChargingStopAction: true,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-detail')));
    await tester.pumpAndSettle();

    expect(find.text('Ladestop einfügen'), findsOneWidget);
    await tester.tap(find.text('Ladestop einfügen'));
    await tester.pumpAndSettle();

    final state = container.read(routePlanningControllerProvider);
    expect(state.containsStop('corridor-park'), isTrue);
    expect(find.byType(GroupDetailPage), findsNothing);
  });
}
