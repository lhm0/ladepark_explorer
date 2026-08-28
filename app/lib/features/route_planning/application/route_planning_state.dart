import 'package:ladepark_explorer/features/route_planning/domain/models/route_option.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_stop.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_waypoint.dart';
import 'package:ladepark_explorer/features/route_planning/domain/route_planning_exception.dart';

/// UI state of the route planning feature: the computed alternatives, which one
/// is selected, whether a calculation is running, the last error, the fixed
/// endpoints and the manually chosen charging stops.
class RoutePlanningState {
  const RoutePlanningState({
    this.options = const <RouteOption>[],
    this.selectedIndex = 0,
    this.isCalculating = false,
    this.error,
    this.origin,
    this.destination,
    this.stops = const <RouteStop>[],
    this.tripStartSocPercent,
    this.tripChargeTargetSocPercent,
  });

  final List<RouteOption> options;
  final int selectedIndex;
  final bool isCalculating;
  final RoutePlanningError? error;

  /// Fixed start and destination, kept so the route can be recomputed after a
  /// stop change or a retry.
  final RouteWaypoint? origin;
  final RouteWaypoint? destination;

  /// Charging stops picked from the corridor, ordered by position on the route.
  final List<RouteStop> stops;

  /// State of charge at the start of this trip, in percent. Null means "use the
  /// vehicle profile default". Session state, not persisted.
  final int? tripStartSocPercent;

  /// State of charge the plan assumes the car leaves each charging stop with,
  /// in percent. Null means "use the vehicle profile target". Session state,
  /// not persisted.
  final int? tripChargeTargetSocPercent;

  bool get hasRoute => options.isNotEmpty;

  bool get canRecalculate => origin != null && destination != null;

  RouteOption? get selectedOption => options.isEmpty
      ? null
      : options[selectedIndex.clamp(0, options.length - 1)];

  bool containsStop(String groupId) =>
      stops.any((stop) => stop.groupId == groupId);

  RoutePlanningState copyWith({
    List<RouteOption>? options,
    int? selectedIndex,
    bool? isCalculating,
    RoutePlanningError? error,
    bool clearError = false,
    RouteWaypoint? origin,
    RouteWaypoint? destination,
    List<RouteStop>? stops,
    int? tripStartSocPercent,
    bool clearTripStartSoc = false,
    int? tripChargeTargetSocPercent,
    bool clearTripChargeTargetSoc = false,
  }) => RoutePlanningState(
    options: options ?? this.options,
    selectedIndex: selectedIndex ?? this.selectedIndex,
    isCalculating: isCalculating ?? this.isCalculating,
    error: clearError ? null : (error ?? this.error),
    origin: origin ?? this.origin,
    destination: destination ?? this.destination,
    stops: stops ?? this.stops,
    tripStartSocPercent: clearTripStartSoc
        ? null
        : (tripStartSocPercent ?? this.tripStartSocPercent),
    tripChargeTargetSocPercent: clearTripChargeTargetSoc
        ? null
        : (tripChargeTargetSocPercent ?? this.tripChargeTargetSocPercent),
  );
}
