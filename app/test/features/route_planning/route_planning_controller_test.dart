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

// State integration for FR-ROUTE-001..004 and NFR-ROUTE-OFFLINE-001.
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
      expect(state.canRecalculate, isTrue);
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
    expect(state.canRecalculate, isFalse);
    expect(state.origin, isNull);
  });

  // The option polyline runs from (52.52, 13.40) to (48.14, 11.58), so a
  // coordinate near the start gets position 0 and one near the end the full
  // length.
  const nearStart = GeoCoordinate(latitude: 52.4, longitude: 13.3);
  const nearEnd = GeoCoordinate(latitude: 48.3, longitude: 11.7);

  test('adds stops as ordered waypoints and recomputes the route', () async {
    final service = FakeRoutePlanningService(
      options: <RouteOption>[option(585), option(602)],
    );
    final container = containerWith(service);
    final controller = container.read(routePlanningControllerProvider.notifier);

    await controller.planRoute(request());
    service.options = <RouteOption>[option(610)];
    await controller.addStop(groupId: 'b', coordinate: nearEnd);
    await controller.addStop(groupId: 'a', coordinate: nearStart);

    final state = container.read(routePlanningControllerProvider);
    expect(state.stops.map((s) => s.groupId), <String>['a', 'b']);
    expect(state.selectedOption?.totalDistanceKm, 610);
    final lastRequest = service.requests.last;
    expect(lastRequest.intermediateWaypoints, hasLength(2));
    expect(lastRequest.includeAlternatives, isFalse);
  });

  test('removing a stop recomputes and can restore alternatives', () async {
    final service = FakeRoutePlanningService(
      options: <RouteOption>[option(585)],
    );
    final container = containerWith(service);
    final controller = container.read(routePlanningControllerProvider.notifier);

    await controller.planRoute(request());
    await controller.addStop(groupId: 'a', coordinate: nearStart);
    await controller.removeStop('a');

    final state = container.read(routePlanningControllerProvider);
    expect(state.stops, isEmpty);
    expect(service.requests.last.intermediateWaypoints, isEmpty);
    expect(service.requests.last.includeAlternatives, isTrue);
  });

  test(
    'a failed recompute keeps the added stop and reports the error',
    () async {
      final service = FakeRoutePlanningService(
        options: <RouteOption>[option(585)],
      );
      final container = containerWith(service);
      final controller = container.read(
        routePlanningControllerProvider.notifier,
      );

      await controller.planRoute(request());
      service.error = RoutePlanningError.offline;
      await controller.addStop(groupId: 'a', coordinate: nearStart);

      // The stop stays so the range estimate can restart the colouring from it;
      // the failed re-route is surfaced for a retry (FR-ROUTE-006).
      final state = container.read(routePlanningControllerProvider);
      expect(state.stops.map((s) => s.groupId), <String>['a']);
      expect(state.error, RoutePlanningError.offline);
    },
  );

  test('a per-stop charge target overrides the profile target', () async {
    final service = FakeRoutePlanningService(
      options: <RouteOption>[option(585)],
    );
    final container = containerWith(service);
    final controller = container.read(routePlanningControllerProvider.notifier);

    await controller.planRoute(request());
    controller.setTripChargeTargetSoc(70);
    expect(
      container
          .read(routePlanningControllerProvider)
          .tripChargeTargetSocPercent,
      70,
    );

    controller.setTripChargeTargetSoc(null);
    expect(
      container
          .read(routePlanningControllerProvider)
          .tripChargeTargetSocPercent,
      isNull,
    );
  });
}
