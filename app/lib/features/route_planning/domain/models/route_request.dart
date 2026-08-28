import 'package:ladepark_explorer/features/route_planning/domain/models/route_waypoint.dart';

/// Input for [RoutePlanningService]: an origin, a destination and an ordered
/// list of intermediate waypoints. Implements FR-ROUTE-001 and FR-ROUTE-002.
class RouteRequest {
  const RouteRequest({
    required this.origin,
    required this.destination,
    this.intermediateWaypoints = const <RouteWaypoint>[],
    this.includeAlternatives = true,
  });

  final RouteWaypoint origin;
  final RouteWaypoint destination;
  final List<RouteWaypoint> intermediateWaypoints;
  final bool includeAlternatives;

  /// Origin, intermediate waypoints and destination in travel order.
  List<RouteWaypoint> get orderedWaypoints => <RouteWaypoint>[
    origin,
    ...intermediateWaypoints,
    destination,
  ];
}
