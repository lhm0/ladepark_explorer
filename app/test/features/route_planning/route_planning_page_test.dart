import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_bounds.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/application/route_planning_providers.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_leg.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_option.dart';
import 'package:ladepark_explorer/features/route_planning/presentation/route_planning_page.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';

import '../../support/fake_route_planning_service.dart';

// UI regression for FR-ROUTE-001 and FR-ROUTE-002.
void main() {
  RouteOption option() => const RouteOption(
    totalDistanceKm: 585,
    totalTravelTime: Duration(hours: 5, minutes: 30),
    boundingBox: GeoBounds(south: 48, west: 11, north: 53, east: 14),
    polyline: <GeoCoordinate>[
      GeoCoordinate(latitude: 52.52, longitude: 13.40),
      GeoCoordinate(latitude: 48.14, longitude: 11.58),
    ],
    legs: <RouteLeg>[],
  );

  Future<FakeRoutePlanningService> pumpPage(
    WidgetTester tester, {
    required Future<GeoCoordinate?> Function(String) resolveEndpoint,
  }) async {
    final service = FakeRoutePlanningService(options: <RouteOption>[option()]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [routePlanningServiceProvider.overrideWithValue(service)],
        child: MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                key: const ValueKey('open-route'),
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => RoutePlanningPage(
                      resolveEndpoint: resolveEndpoint,
                      currentLocation: () async => const GeoCoordinate(
                        latitude: 52.52,
                        longitude: 13.40,
                      ),
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
    await tester.tap(find.byKey(const ValueKey('open-route')));
    await tester.pumpAndSettle();
    return service;
  }

  testWidgets('calculates a route and closes on success', (tester) async {
    final service = await pumpPage(
      tester,
      resolveEndpoint: (query) async => GeoCoordinate(
        latitude: query == 'Berlin' ? 52.52 : 48.14,
        longitude: 13.4,
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey('route-start-field')),
      'Berlin',
    );
    await tester.enterText(
      find.byKey(const ValueKey('route-destination-field')),
      'München',
    );
    await tester.tap(find.text('Route berechnen'));
    await tester.pumpAndSettle();

    expect(service.requests, hasLength(1));
    expect(find.byKey(const ValueKey('route-start-field')), findsNothing);
  });

  testWidgets('shows a field error when the destination is not found', (
    tester,
  ) async {
    final service = await pumpPage(
      tester,
      resolveEndpoint: (query) async => query == 'Berlin'
          ? const GeoCoordinate(latitude: 52.52, longitude: 13.4)
          : null,
    );

    await tester.enterText(
      find.byKey(const ValueKey('route-start-field')),
      'Berlin',
    );
    await tester.enterText(
      find.byKey(const ValueKey('route-destination-field')),
      'Nirgendwo',
    );
    await tester.tap(find.text('Route berechnen'));
    await tester.pumpAndSettle();

    expect(service.requests, isEmpty);
    expect(find.text('Das Ziel wurde nicht gefunden.'), findsOneWidget);
    expect(find.byKey(const ValueKey('route-start-field')), findsOneWidget);
  });
}
