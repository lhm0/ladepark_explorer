import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_bounds.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/application/route_planning_providers.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_option.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_request.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_waypoint.dart';
import 'package:ladepark_explorer/features/route_planning/domain/route_planning_exception.dart';

import '../../support/fake_route_planning_service.dart';

// State integration for FR-ROUTE-001, FR-ROUTE-002 and NFR-ROUTE-OFFLINE-001.
void main() {
  RouteRequest request() => const RouteRequest(
    origin: RouteWaypoint(
      coordinate: GeoCoordinate(latitude: 52.52, longitude: 13.40),
    ),
    destination: RouteWaypoint(
      coordinate: GeoCoordinate(latitude: 48.14, longitude: 11.58),
    ),
  );

  RouteOption option(double distanceKm) => RouteOption(
    totalDistanceKm: distanceKm,
    totalTravelTime: const Duration(hours: 5),
    boundingBox: const GeoBounds(south: 48, west: 11, north: 53, east: 14),
    polyline: const <GeoCoordinate>[
      GeoCoordinate(latitude: 52.52, longitude: 13.40),
      GeoCoordinate(latitude: 48.14, longitude: 11.58),
    ],
    legs: const [],
  );

  ProviderContainer containerWith(FakeRoutePlanningService service) {
    final container = ProviderContainer(
      overrides: [routePlanningServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test(
    'exposes the calculated alternatives with the first one selected',
    () async {
      final service = FakeRoutePlanningService(
        options: <RouteOption>[option(585), option(602)],
      );
      final container = containerWith(service);
      final controller = container.read(
        routePlanningControllerProvider.notifier,
      );

      await controller.planRoute(request());
      final state = container.read(routePlanningControllerProvider);

      expect(service.requests, hasLength(1));
      expect(state.isCalculating, isFalse);
      expect(state.error, isNull);
      expect(state.options, hasLength(2));
      expect(state.selectedOption?.totalDistanceKm, 585);
    },
  );

  test('switches to a selected alternative', () async {
    final service = FakeRoutePlanningService(
      options: <RouteOption>[option(585), option(602)],
    );
    final container = containerWith(service);
    final controller = container.read(routePlanningControllerProvider.notifier);

    await controller.planRoute(request());
    controller.selectAlternative(1);

    expect(
      container
          .read(routePlanningControllerProvider)
          .selectedOption
          ?.totalDistanceKm,
      602,
    );
  });

  test(
    'reports the offline error category without losing the request',
    () async {
      final service = FakeRoutePlanningService(
        error: RoutePlanningError.offline,
      );
      final container = containerWith(service);
      final controller = container.read(
        routePlanningControllerProvider.notifier,
      );

      await controller.planRoute(request());
      final state = container.read(routePlanningControllerProvider);

      expect(state.error, RoutePlanningError.offline);
      expect(state.hasRoute, isFalse);
      expect(state.isCalculating, isFalse);
      expect(state.request, isNotNull);
    },
  );

  test('retry re-runs the last request and can recover', () async {
    final service = FakeRoutePlanningService(
      error: RoutePlanningError.throttled,
    );
    final container = containerWith(service);
    final controller = container.read(routePlanningControllerProvider.notifier);

    await controller.planRoute(request());
    service
      ..error = null
      ..options = <RouteOption>[option(585)];
    await controller.retry();

    final state = container.read(routePlanningControllerProvider);
    expect(service.requests, hasLength(2));
    expect(state.error, isNull);
    expect(state.hasRoute, isTrue);
  });

  test('maps an empty result to noRouteFound', () async {
    final service = FakeRoutePlanningService(options: const <RouteOption>[]);
    final container = containerWith(service);
    final controller = container.read(routePlanningControllerProvider.notifier);

    await controller.planRoute(request());

    expect(
      container.read(routePlanningControllerProvider).error,
      RoutePlanningError.noRouteFound,
    );
  });

  test('clear resets the planning state', () async {
    final service = FakeRoutePlanningService(
      options: <RouteOption>[option(585)],
    );
    final container = containerWith(service);
    final controller = container.read(routePlanningControllerProvider.notifier);

    await controller.planRoute(request());
    controller.clear();

    final state = container.read(routePlanningControllerProvider);
    expect(state.hasRoute, isFalse);
    expect(state.request, isNull);
  });
}
