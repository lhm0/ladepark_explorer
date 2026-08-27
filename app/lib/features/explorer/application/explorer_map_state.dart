import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_summary.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/explorer_filters.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_bounds.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/explorer/domain/repositories/charging_repository_exception.dart';

class ExplorerMapState {
  const ExplorerMapState({
    this.bounds,
    this.groups = const <ChargingGroupSummary>[],
    this.isQuerying = false,
    this.error,
    this.filters = ExplorerFilters.defaults,
    this.nearbyCenter,
    this.favoriteAnchorStationIds = const <String>[],
    this.amenityAnchorStationIds = const <String>[],
  });

  final GeoBounds? bounds;
  final List<ChargingGroupSummary> groups;
  final bool isQuerying;
  final ChargingRepositoryError? error;
  final ExplorerFilters filters;
  final GeoCoordinate? nearbyCenter;
  final List<String> favoriteAnchorStationIds;
  final List<String> amenityAnchorStationIds;

  ExplorerMapState copyWith({
    GeoBounds? bounds,
    List<ChargingGroupSummary>? groups,
    bool? isQuerying,
    ChargingRepositoryError? error,
    bool clearError = false,
    ExplorerFilters? filters,
    GeoCoordinate? nearbyCenter,
    bool clearNearby = false,
    List<String>? favoriteAnchorStationIds,
    List<String>? amenityAnchorStationIds,
  }) {
    return ExplorerMapState(
      bounds: bounds ?? this.bounds,
      groups: groups ?? this.groups,
      isQuerying: isQuerying ?? this.isQuerying,
      error: clearError ? null : error ?? this.error,
      filters: filters ?? this.filters,
      nearbyCenter: clearNearby ? null : nearbyCenter ?? this.nearbyCenter,
      favoriteAnchorStationIds:
          favoriteAnchorStationIds ?? this.favoriteAnchorStationIds,
      amenityAnchorStationIds:
          amenityAnchorStationIds ?? this.amenityAnchorStationIds,
    );
  }
}
