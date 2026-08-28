import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';

/// One drivable section of a route between two consecutive waypoints.
///
/// In version 1.1 a leg only carries distance and travel time. ADR-0020 adds
/// a finer segment model with optional road-class, gradient and elevation
/// fields in a later milestone.
class RouteLeg {
  const RouteLeg({
    required this.start,
    required this.end,
    required this.distanceKm,
    required this.travelTime,
  });

  final GeoCoordinate start;
  final GeoCoordinate end;
  final double distanceKm;
  final Duration travelTime;
}
