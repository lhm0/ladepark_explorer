import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_bounds.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/application/route_planning_providers.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_leg.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_option.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_request.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_waypoint.dart';
import 'package:ladepark_explorer/features/route_planning/presentation/route_preview_page.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';

import '../../support/fake_route_planning_service.dart';

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
                    builder: (_) => const RoutePreviewPage(),
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
}
