import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/application/explorer_providers.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_summary.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_bounds.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/application/route_planning_providers.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_leg.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_option.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_request.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_waypoint.dart';
import 'package:ladepark_explorer/features/route_planning/presentation/route_corridor_page.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';

import '../../support/fake_charging_repository.dart';
import '../../support/fake_route_planning_service.dart';

// UI regression for FR-ROUTE-003 and FR-ROUTE-004.
void main() {
  const request = RouteRequest(
    origin: RouteWaypoint(
      coordinate: GeoCoordinate(latitude: 52.5, longitude: 13.4),
    ),
    destination: RouteWaypoint(
      coordinate: GeoCoordinate(latitude: 48.1, longitude: 11.6),
    ),
  );

  RouteOption option() => const RouteOption(
    totalDistanceKm: 585,
    totalTravelTime: Duration(hours: 5, minutes: 30),
    boundingBox: GeoBounds(south: 48, west: 11, north: 53, east: 14),
    polyline: <GeoCoordinate>[
      GeoCoordinate(latitude: 52.5, longitude: 13.4),
      GeoCoordinate(latitude: 50.1, longitude: 12.0),
      GeoCoordinate(latitude: 48.1, longitude: 11.6),
    ],
    legs: <RouteLeg>[],
  );

  final park = ChargingGroupSummary(
    groupId: 'corridor-park',
    latitude: 50.2,
    longitude: 12.1,
    stationCount: 2,
    evseCount: 12,
    hpcEvseCount: 8,
    maxPowerKw: 300,
    city: 'Mittelstadt',
    name: 'Rasthof Mitte',
  );

  Future<ProviderContainer> planned() async {
    final container = ProviderContainer(
      overrides: [
        chargingRepositoryProvider.overrideWith(
          (ref) async =>
              FakeChargingRepository(groups: <ChargingGroupSummary>[park]),
        ),
        routePlanningServiceProvider.overrideWithValue(
          FakeRoutePlanningService(options: <RouteOption>[option()]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(explorerMapControllerProvider.future);
    await container
        .read(routePlanningControllerProvider.notifier)
        .planRoute(request);
    return container;
  }

  Future<void> pumpCorridor(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
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
                key: const ValueKey('open-corridor'),
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => RouteCorridorPage(onOpenDetail: (_) {}),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-corridor')));
    await tester.pumpAndSettle();
  }

  testWidgets('lists corridor parks and toggles one into a stop', (
    tester,
  ) async {
    final container = await planned();
    await pumpCorridor(tester, container);

    expect(find.text('Rasthof Mitte'), findsOneWidget);
    expect(find.textContaining('bei km'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final state = container.read(routePlanningControllerProvider);
    expect(state.containsStop('corridor-park'), isTrue);
    expect(state.stops.single.name, 'Rasthof Mitte');
  });
}
