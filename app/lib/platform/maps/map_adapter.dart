import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_summary.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_bounds.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';

abstract interface class MapAdapter {
  Stream<GeoBounds> get visibleBounds;

  Stream<String> get selectedGroupIds;

  Future<void> showGroups(List<ChargingGroupSummary> groups);

  Future<GeoCoordinate> focusUserLocation({required double radiusKm});

  Future<void> focusCoordinate(
    GeoCoordinate coordinate, {
    required double radiusKm,
  });

  Future<void> showGermanyOverview();

  /// Draws [polyline] as a native route overlay and fits it into view
  /// (FR-ROUTE-001, ADR-0019). Replaces any previously shown route.
  Future<void> showRoute(List<GeoCoordinate> polyline);

  /// Marks the chosen charging stops along the route (FR-ROUTE-004), numbered
  /// in the given order. Replaces any previously shown stops.
  Future<void> showRouteStops(List<GeoCoordinate> stops);

  /// Removes the native route overlay and any route stop markers.
  Future<void> clearRoute();

  Future<void> dispose();
}
