import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/application/explorer_providers.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_summary.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_bounds.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/application/corridor_providers.dart';
import 'package:ladepark_explorer/features/route_planning/application/route_planning_providers.dart';
import 'package:ladepark_explorer/features/route_planning/application/vehicle_profile_providers.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_leg.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_option.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_request.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_waypoint.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/vehicle_profile.dart';
import 'package:ladepark_explorer/features/route_planning/presentation/route_preview_page.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';

import '../../support/fake_charging_repository.dart';
import '../../support/fake_explorer_filters_repository.dart';
import '../../support/fake_route_planning_service.dart';
import '../../support/fake_vehicle_profile_repository.dart';

// UI regression for FR-ROUTE-001 and the ADR-0011 constraint: route map and the
// alternative selector are non-overlapping siblings, not a Flutter overlay.
void main() {
  RouteOption option(double kilometres) => RouteOption(
    totalDistanceKm: kilometres,
    totalTravelTime: const Duration(hours: 5, minutes: 30),
    boundingBox: const GeoBounds(south: 48, west: 11, north: 53, east: 14),
    polyline: const <GeoCoordinate>[
      GeoCoordinate(latitude: 52.52, longitude: 13.40),
      GeoCoordinate(latitude: 48.14, longitude: 11.58),
    ],
    legs: const <RouteLeg>[],
  );

  const request = RouteRequest(
    origin: RouteWaypoint(
      coordinate: GeoCoordinate(latitude: 52.52, longitude: 13.40),
    ),
    destination: RouteWaypoint(
      coordinate: GeoCoordinate(latitude: 48.14, longitude: 11.58),
    ),
  );

  Future<ProviderContainer> containerWithRoute(
    List<RouteOption> options,
  ) async {
    final container = ProviderContainer(
      overrides: [
        explorerFiltersRepositoryProvider.overrideWith(
          (ref) async => FakeExplorerFiltersRepository(),
        ),
        routePlanningServiceProvider.overrideWithValue(
          FakeRoutePlanningService(options: options),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(routePlanningControllerProvider.notifier)
        .planRoute(request);
    return container;
  }

  Future<void> pumpPreview(
    WidgetTester tester,
    ProviderContainer container,
  ) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
                key: const ValueKey('open-preview'),
                onPressed: () => Navigator.push<RoutePreviewResult>(
                  context,
                  MaterialPageRoute<RoutePreviewResult>(
                    builder: (_) =>
                        RoutePreviewPage(onOpenDetail: (_) async {}),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open-preview')));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the map and the selector side by side', (tester) async {
    final container = await containerWithRoute(<RouteOption>[
      option(585),
      option(602),
    ]);
    await pumpPreview(tester, container);

    expect(find.text('Alternativen'), findsOneWidget);
    expect(find.text('Auf Karte anzeigen'), findsOneWidget);
    expect(find.textContaining('585 km'), findsWidgets);
  });

  testWidgets('selecting an alternative keeps the page open', (tester) async {
    final container = await containerWithRoute(<RouteOption>[
      option(585),
      option(602),
    ]);
    await pumpPreview(tester, container);

    await tester.tap(find.byKey(const ValueKey('route-alternative-1')));
    await tester.pumpAndSettle();

    expect(container.read(routePlanningControllerProvider).selectedIndex, 1);
    expect(find.text('Auf Karte anzeigen'), findsOneWidget);
  });

  testWidgets('clearing the route leaves the page', (tester) async {
    final container = await containerWithRoute(<RouteOption>[option(585)]);
    await pumpPreview(tester, container);

    await tester.tap(find.byTooltip('Route beenden'));
    await tester.pumpAndSettle();

    expect(container.read(routePlanningControllerProvider).hasRoute, isFalse);
    expect(find.text('Auf Karte anzeigen'), findsNothing);
  });

  testWidgets('runs the corridor search and reports the count', (tester) async {
    final park = ChargingGroupSummary(
      groupId: 'corridor-1',
      latitude: 50.2,
      longitude: 12.4,
      stationCount: 1,
      evseCount: 10,
      hpcEvseCount: 6,
      maxPowerKw: 300,
      city: 'Mitte',
    );
    final container = ProviderContainer(
      overrides: [
        explorerFiltersRepositoryProvider.overrideWith(
          (ref) async => FakeExplorerFiltersRepository(),
        ),
        routePlanningServiceProvider.overrideWithValue(
          FakeRoutePlanningService(options: <RouteOption>[option(585)]),
        ),
        chargingRepositoryProvider.overrideWith(
          (ref) async =>
              FakeChargingRepository(groups: <ChargingGroupSummary>[park]),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(explorerMapControllerProvider.future);
    await container
        .read(routePlanningControllerProvider.notifier)
        .planRoute(request);
    await pumpPreview(tester, container);

    await tester.tap(find.text('Ladeparks entlang der Route'));
    await tester.pumpAndSettle();

    expect(find.text('1 Ladepark im Korridor'), findsOneWidget);
  });

  testWidgets('shows the start-SoC control and range warning', (tester) async {
    const profile = VehicleProfile(
      usableBatteryKwh: 40,
      consumptionKwhPer100Km: 20,
      maxChargePowerKw: 100,
    );
    final container = ProviderContainer(
      overrides: [
        explorerFiltersRepositoryProvider.overrideWith(
          (ref) async => FakeExplorerFiltersRepository(),
        ),
        routePlanningServiceProvider.overrideWithValue(
          FakeRoutePlanningService(options: <RouteOption>[option(585)]),
        ),
        vehicleProfileRepositoryProvider.overrideWith(
          (ref) async => FakeVehicleProfileRepository(profile),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(vehicleProfileControllerProvider.future);
    await container
        .read(routePlanningControllerProvider.notifier)
        .planRoute(request);
    await pumpPreview(tester, container);

    expect(find.text('Start-Ladezustand'), findsOneWidget);
    expect(find.text('Ladeziel am Stopp'), findsOneWidget);
    expect(find.text('90 %'), findsOneWidget);
    expect(find.text('80 %'), findsOneWidget);
    expect(find.textContaining('Reichweite reicht nur bis'), findsOneWidget);
    expect(find.textContaining('Start 90 %'), findsOneWidget);

    Future<void> tapStepper(String stepperKey, IconData icon) async {
      final button = find.descendant(
        of: find.byKey(ValueKey<String>(stepperKey)),
        matching: find.byIcon(icon),
      );
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
    }

    await tapStepper('stepper-start-soc', Icons.remove_circle_outline);
    expect(
      container.read(routePlanningControllerProvider).tripStartSocPercent,
      85,
    );

    await tapStepper('stepper-charge-target', Icons.add_circle_outline);
    expect(
      container
          .read(routePlanningControllerProvider)
          .tripChargeTargetSocPercent,
      85,
    );
  });

  testWidgets('adjusts the corridor width in 10 km steps', (tester) async {
    final container = await containerWithRoute(<RouteOption>[option(585)]);
    await pumpPreview(tester, container);

    expect(find.text('Korridorbreite'), findsOneWidget);
    expect(find.text('20 km'), findsOneWidget);

    final plus = find.descendant(
      of: find.byKey(const ValueKey<String>('stepper-corridor-width')),
      matching: find.byIcon(Icons.add_circle_outline),
    );
    await tester.ensureVisible(plus);
    await tester.tap(plus);
    await tester.pumpAndSettle();

    expect(container.read(corridorControllerProvider).widthKm, 30);
  });
}
