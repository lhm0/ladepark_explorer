import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_segment.dart';
import 'package:ladepark_explorer/features/route_planning/domain/route_corridor.dart';

// Segment model for FR-ROUTE-006 / ADR-0020.
void main() {
  const polyline = <GeoCoordinate>[
    GeoCoordinate(latitude: 52.0, longitude: 13.0),
    GeoCoordinate(latitude: 51.5, longitude: 13.0),
    GeoCoordinate(latitude: 50.0, longitude: 13.0),
  ];

  test('builds one segment per polyline pair with matching distances', () {
    final path = buildRoutePath(
      polyline,
      totalTravelTime: const Duration(hours: 2),
    );

    expect(path, hasLength(2));
    expect(
      path[0].distanceKm,
      closeTo(haversineKm(polyline[0], polyline[1]), 0.001),
    );
    final totalKm = path.fold<double>(0, (sum, s) => sum + s.distanceKm);
    expect(
      totalKm,
      closeTo(
        haversineKm(polyline[0], polyline[1]) +
            haversineKm(polyline[1], polyline[2]),
        0.001,
      ),
    );
    expect(path.every((s) => s.roadClass == null && s.grade == null), isTrue);
  });

  test('distributes travel time in proportion to segment length', () {
    final path = buildRoutePath(
      polyline,
      totalTravelTime: const Duration(minutes: 120),
    );
    final totalSeconds = path.fold<int>(
      0,
      (sum, s) => sum + s.travelTime.inSeconds,
    );
    expect(totalSeconds, closeTo(120 * 60, 2));
    expect(path[1].travelTime > path[0].travelTime, isTrue);
  });

  test('returns no segments for a degenerate polyline', () {
    expect(
      buildRoutePath(const <GeoCoordinate>[
        GeoCoordinate(latitude: 52, longitude: 13),
      ], totalTravelTime: Duration.zero),
      isEmpty,
    );
  });
}
