import 'package:ladepark_explorer/features/route_planning/domain/models/route_option.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_request.dart';

/// Platform-neutral port for computing a car route between waypoints
/// (FR-ROUTE-001, FR-ROUTE-002). The MapKit implementation lives in
/// `platform/route/`; see ADR-0019.
///
/// Implementations translate technical failures into
/// [RoutePlanningException] with a stable [RoutePlanningError].
abstract interface class RoutePlanningService {
  /// Returns one or more routes for [request], best first. Throws
  /// [RoutePlanningException] on failure.
  Future<List<RouteOption>> planRoute(RouteRequest request);
}
