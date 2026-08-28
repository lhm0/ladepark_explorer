// Pure geometry for the route corridor search (FR-ROUTE-003, ADR-0022).
//
// The corridor is not a real query yet: sample points are taken along the
// decimated route polyline and the existing radius query is run at each one.

import 'dart:math' as math;

import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';

/// Resamples [polyline] into points spaced roughly [spacingKm] apart, always
/// including the first and last point.
List<GeoCoordinate> sampleAlongPolyline(
  List<GeoCoordinate> polyline, {
  required double spacingKm,
}) {
  if (polyline.length < 2 || spacingKm <= 0) {
    return List<GeoCoordinate>.of(polyline);
  }
  final samples = <GeoCoordinate>[polyline.first];
  var carry = 0.0;
  for (var i = 1; i < polyline.length; i++) {
    var start = polyline[i - 1];
    final end = polyline[i];
    var remaining = haversineKm(start, end);
    while (carry + remaining >= spacingKm) {
      final step = spacingKm - carry;
      final fraction = remaining == 0 ? 0.0 : step / remaining;
      final point = _lerp(start, end, fraction);
      samples.add(point);
      start = point;
      remaining = haversineKm(start, end);
      carry = 0.0;
    }
    carry += remaining;
  }
  if (samples.last != polyline.last) {
    samples.add(polyline.last);
  }
  return samples;
}

/// Distance in kilometres from the start of [polyline] to the polyline vertex
/// closest to [point]. Used to order corridor parks by travel progress.
double positionAlongPolylineKm(
  List<GeoCoordinate> polyline,
  GeoCoordinate point,
) {
  if (polyline.isEmpty) return 0;
  var bestDistance = double.infinity;
  var bestIndex = 0;
  for (var i = 0; i < polyline.length; i++) {
    final distance = haversineKm(polyline[i], point);
    if (distance < bestDistance) {
      bestDistance = distance;
      bestIndex = i;
    }
  }
  var cumulative = 0.0;
  for (var i = 1; i <= bestIndex; i++) {
    cumulative += haversineKm(polyline[i - 1], polyline[i]);
  }
  return cumulative;
}

/// Rough there-and-back detour for leaving the route to reach [point]:
/// twice the distance to the nearest polyline vertex.
double estimateDetourKm(List<GeoCoordinate> polyline, GeoCoordinate point) {
  var bestDistance = double.infinity;
  for (final vertex in polyline) {
    final distance = haversineKm(vertex, point);
    if (distance < bestDistance) bestDistance = distance;
  }
  return bestDistance.isFinite ? bestDistance * 2 : 0;
}

GeoCoordinate _lerp(GeoCoordinate a, GeoCoordinate b, double fraction) =>
    GeoCoordinate(
      latitude: a.latitude + (b.latitude - a.latitude) * fraction,
      longitude: a.longitude + (b.longitude - a.longitude) * fraction,
    );

double haversineKm(GeoCoordinate a, GeoCoordinate b) {
  const earthRadiusKm = 6371.0088;
  final dLat = _radians(b.latitude - a.latitude);
  final dLon = _radians(b.longitude - a.longitude);
  final h =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_radians(a.latitude)) *
          math.cos(_radians(b.latitude)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return earthRadiusKm * 2 * math.asin(math.sqrt(h.clamp(0, 1)));
}

double _radians(double degrees) => degrees * math.pi / 180;
