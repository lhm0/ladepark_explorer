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

  Future<void> dispose();
}
