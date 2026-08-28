import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/domain/route_corridor.dart';

// Pure geometry for FR-ROUTE-003 / ADR-0022.
void main() {
  test('samples a polyline at roughly the given spacing', () {
    const line = <GeoCoordinate>[
      GeoCoordinate(latitude: 52.0, longitude: 13.0),
      GeoCoordinate(latitude: 50.0, longitude: 13.0),
    ];
    final samples = sampleAlongPolyline(line, spacingKm: 20);

    expect(samples.first, line.first);
    expect(samples.last, line.last);
    expect(samples.length, greaterThan(5));
    for (var i = 1; i < samples.length - 1; i++) {
      expect(haversineKm(samples[i - 1], samples[i]), closeTo(20, 1));
    }
  });

  test('returns the endpoints for a degenerate polyline', () {
    const line = <GeoCoordinate>[
      GeoCoordinate(latitude: 52.0, longitude: 13.0),
    ];
    expect(sampleAlongPolyline(line, spacingKm: 20), line);
  });

  test('position along the polyline grows with travel progress', () {
    const line = <GeoCoordinate>[
      GeoCoordinate(latitude: 52.0, longitude: 13.0),
      GeoCoordinate(latitude: 51.0, longitude: 13.0),
      GeoCoordinate(latitude: 50.0, longitude: 13.0),
    ];
    final earlyKm = positionAlongPolylineKm(
      line,
      const GeoCoordinate(latitude: 51.9, longitude: 13.02),
    );
    final lateKm = positionAlongPolylineKm(
      line,
      const GeoCoordinate(latitude: 50.1, longitude: 13.02),
    );
    expect(earlyKm, lessThan(lateKm));
  });
}
