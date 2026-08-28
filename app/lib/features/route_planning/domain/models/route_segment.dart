import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/domain/route_corridor.dart'
    show haversineKm;

/// One short section of a route between two consecutive polyline points.
///
/// The optional attributes stay null in version 1.1 (ADR-0020); a later,
/// "intelligent" [EnergyModel] fills them in.
class RouteSegment {
  const RouteSegment({
    required this.start,
    required this.end,
    required this.distanceKm,
    required this.travelTime,
    this.roadClass,
    this.grade,
    this.elevationDeltaM,
  });

  final GeoCoordinate start;
  final GeoCoordinate end;
  final double distanceKm;
  final Duration travelTime;
  final String? roadClass;
  final double? grade;
  final double? elevationDeltaM;
}

/// An ordered list of [RouteSegment], from route start to destination.
typedef RoutePath = List<RouteSegment>;

/// Builds a [RoutePath] from a decimated polyline, distributing [totalTravelTime]
/// across the segments in proportion to their length.
RoutePath buildRoutePath(
  List<GeoCoordinate> polyline, {
  required Duration totalTravelTime,
}) {
  if (polyline.length < 2) return const <RouteSegment>[];
  final distances = <double>[
    for (var i = 1; i < polyline.length; i++)
      haversineKm(polyline[i - 1], polyline[i]),
  ];
  final totalKm = distances.fold<double>(0, (sum, value) => sum + value);
  final totalSeconds = totalTravelTime.inSeconds;
  return <RouteSegment>[
    for (var i = 0; i < distances.length; i++)
      RouteSegment(
        start: polyline[i],
        end: polyline[i + 1],
        distanceKm: distances[i],
        travelTime: totalKm == 0
            ? Duration.zero
            : Duration(
                seconds: (totalSeconds * distances[i] / totalKm).round(),
              ),
      ),
  ];
}
