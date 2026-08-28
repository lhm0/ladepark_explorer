import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/application/corridor_providers.dart';
import 'package:ladepark_explorer/features/route_planning/application/route_planning_state.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_request.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_stop.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_waypoint.dart';
import 'package:ladepark_explorer/features/route_planning/domain/route_corridor.dart';
import 'package:ladepark_explorer/features/route_planning/domain/route_planning_exception.dart';
import 'package:ladepark_explorer/features/route_planning/domain/route_planning_service.dart';
import 'package:ladepark_explorer/platform/route/mkdirections_route_planning_service.dart';

final routePlanningServiceProvider = Provider<RoutePlanningService>(
  (ref) => const MkDirectionsRoutePlanningService(),
);

final routePlanningControllerProvider =
    NotifierProvider<RoutePlanningController, RoutePlanningState>(
      RoutePlanningController.new,
    );

/// Coordinates route calculation, alternative selection and the manually
/// chosen charging stops (FR-ROUTE-001, FR-ROUTE-002, FR-ROUTE-004,
/// NFR-ROUTE-OFFLINE-001). The selected route is drawn natively on the map by
/// the map screen.
final class RoutePlanningController extends Notifier<RoutePlanningState> {
  @override
  RoutePlanningState build() => const RoutePlanningState();

  Future<void> planRoute(RouteRequest request) async {
    state = state.copyWith(
      isCalculating: true,
      clearError: true,
      origin: request.origin,
      destination: request.destination,
      stops: const <RouteStop>[],
    );
    ref.read(corridorControllerProvider.notifier).clear();
    await _run(request);
  }

  Future<void> retry() async {
    if (!state.canRecalculate) return;
    state = state.copyWith(isCalculating: true, clearError: true);
    await _run(_currentRequest());
  }

  Future<void> addStop({
    required String groupId,
    required GeoCoordinate coordinate,
    String? name,
  }) async {
    if (!state.canRecalculate || state.containsStop(groupId)) return;
    final polyline = state.selectedOption?.polyline ?? const <GeoCoordinate>[];
    final stop = RouteStop(
      groupId: groupId,
      coordinate: coordinate,
      positionKm: positionAlongPolylineKm(polyline, coordinate),
      name: name,
    );
    final previousStops = state.stops;
    final stops = <RouteStop>[...previousStops, stop]
      ..sort((a, b) => a.positionKm.compareTo(b.positionKm));
    state = state.copyWith(stops: stops, isCalculating: true, clearError: true);
    await _run(_currentRequest());
    if (state.error != null) {
      state = state.copyWith(stops: previousStops);
    }
  }

  Future<void> removeStop(String groupId) async {
    if (!state.canRecalculate || !state.containsStop(groupId)) return;
    state = state.copyWith(
      stops: state.stops
          .where((stop) => stop.groupId != groupId)
          .toList(growable: false),
      isCalculating: true,
      clearError: true,
    );
    await _run(_currentRequest());
  }

  void selectAlternative(int index) {
    if (index < 0 ||
        index >= state.options.length ||
        index == state.selectedIndex) {
      return;
    }
    state = state.copyWith(selectedIndex: index);
  }

  void clear() {
    state = const RoutePlanningState();
    ref.read(corridorControllerProvider.notifier).clear();
  }

  RouteRequest _currentRequest() => RouteRequest(
    origin: state.origin!,
    destination: state.destination!,
    intermediateWaypoints: state.stops
        .map(
          (stop) =>
              RouteWaypoint(coordinate: stop.coordinate, label: stop.name),
        )
        .toList(growable: false),
    includeAlternatives: state.stops.isEmpty,
  );

  Future<void> _run(RouteRequest request) async {
    try {
      final options = await ref
          .read(routePlanningServiceProvider)
          .planRoute(request);
      if (options.isEmpty) {
        state = state.copyWith(
          isCalculating: false,
          error: RoutePlanningError.noRouteFound,
        );
        return;
      }
      state = state.copyWith(
        options: options,
        selectedIndex: 0,
        isCalculating: false,
        clearError: true,
      );
    } on RoutePlanningException catch (exception) {
      state = state.copyWith(isCalculating: false, error: exception.error);
    } on Object {
      state = state.copyWith(
        isCalculating: false,
        error: RoutePlanningError.serviceFailed,
      );
    }
  }
}
