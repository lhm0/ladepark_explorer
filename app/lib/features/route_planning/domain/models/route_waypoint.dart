import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';

/// A named point a route passes through: origin, destination or an
/// intermediate stop. See FR-ROUTE-001 and FR-ROUTE-002.
class RouteWaypoint {
  const RouteWaypoint({required this.coordinate, this.label});

  final GeoCoordinate coordinate;
  final String? label;

  @override
  bool operator ==(Object other) =>
      other is RouteWaypoint &&
      coordinate == other.coordinate &&
      label == other.label;

  @override
  int get hashCode => Object.hash(coordinate, label);
}
