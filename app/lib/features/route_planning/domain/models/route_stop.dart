import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';

/// A charging park the user picked as a stop on the route (FR-ROUTE-004).
///
/// Stops are ordered by [positionKm] and passed to [RoutePlanningService] as
/// intermediate waypoints so the legs are recomputed through them.
class RouteStop {
  const RouteStop({
    required this.groupId,
    required this.coordinate,
    required this.positionKm,
    this.name,
  });

  final String groupId;
  final GeoCoordinate coordinate;
  final double positionKm;
  final String? name;

  RouteStop copyWith({double? positionKm}) => RouteStop(
    groupId: groupId,
    coordinate: coordinate,
    positionKm: positionKm ?? this.positionKm,
    name: name,
  );
}
