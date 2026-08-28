import 'package:ladepark_explorer/features/explorer/domain/models/geo_bounds.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_leg.dart';

/// One computed route for a [RouteRequest].
///
/// The [polyline] is a decimated approximation of the native route geometry
/// (ADR-0019). It is precise enough for display and for the corridor search in
/// a later milestone, but it is not the exact provider polyline.
class RouteOption {
  const RouteOption({
    required this.totalDistanceKm,
    required this.totalTravelTime,
    required this.boundingBox,
    required this.polyline,
    required this.legs,
  });

  final double totalDistanceKm;
  final Duration totalTravelTime;
  final GeoBounds boundingBox;
  final List<GeoCoordinate> polyline;
  final List<RouteLeg> legs;
}
