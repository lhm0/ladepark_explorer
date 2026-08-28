import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_summary.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_bounds.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';

/// A charging stop marker: its group id and where it sits.
typedef RouteStopMarker = ({String id, GeoCoordinate coordinate});

abstract interface class MapAdapter {
  Stream<GeoBounds> get visibleBounds;

  Stream<String> get selectedGroupIds;

  /// Group ids of route corridor markers the user tapped (FR-ROUTE-003).
  Stream<String> get selectedCorridorParkIds;

  /// Group ids of route stop markers the user tapped (FR-ROUTE-004).
  Stream<String> get selectedRouteStopIds;

  Future<void> showGroups(List<ChargingGroupSummary> groups);

  Future<GeoCoordinate> focusUserLocation({required double radiusKm});

  Future<void> focusCoordinate(
    GeoCoordinate coordinate, {
    required double radiusKm,
  });

  Future<void> showGermanyOverview();

  /// Draws [polyline] as a native route overlay and fits it into view
  /// (FR-ROUTE-001, ADR-0019). Replaces any previously shown route.
  ///
  /// When [segmentColorsArgb] is given it holds one ARGB colour per polyline
  /// segment (`polyline.length - 1` entries) for the state-of-charge colouring
  /// (FR-ROUTE-006, ADR-0023); otherwise the route is drawn in one colour.
  ///
  /// [fitToRoute] controls whether the view is moved to fit the route. Pass
  /// false for incremental redraws (colour or stop changes) so the map does
  /// not keep re-zooming.
  Future<void> showRoute(
    List<GeoCoordinate> polyline, {
    List<int>? segmentColorsArgb,
    bool fitToRoute = true,
  });

  /// Marks the chosen charging stops along the route (FR-ROUTE-004) as blue
  /// numbered, tappable markers, in the given order. Replaces any previously
  /// shown stops.
  Future<void> showRouteStops(List<RouteStopMarker> stops);

  /// Shows the charging parks found in the route corridor (FR-ROUTE-003) as
  /// tappable markers. Replaces any previously shown corridor parks.
  Future<void> showRouteCorridor(List<ChargingGroupSummary> parks);

  /// Removes the native route overlay, the route stop markers and the corridor
  /// markers.
  Future<void> clearRoute();

  Future<void> dispose();
}
