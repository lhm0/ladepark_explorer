import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/data/charging/bundled_charging_database.dart';
import 'package:ladepark_explorer/data/charging/sqlite/sqlite_charging_repository.dart';
import 'package:ladepark_explorer/features/explorer/application/explorer_map_state.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_detail.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_query.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_summary.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/explorer_filters.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_bounds.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/location_search_target.dart';
import 'package:ladepark_explorer/features/explorer/domain/repositories/charging_repository.dart';
import 'package:ladepark_explorer/features/explorer/domain/repositories/charging_repository_exception.dart';

final chargingRepositoryProvider = FutureProvider<ChargingRepository>((
  ref,
) async {
  final databasePath = await const BundledChargingDatabase().resolve();
  final repository = await SqliteChargingRepository.open(databasePath);
  ref.onDispose(() => unawaited(repository.close()));
  return repository;
});

final explorerMapControllerProvider =
    AsyncNotifierProvider<ExplorerMapController, ExplorerMapState>(
      ExplorerMapController.new,
    );

final class ExplorerMapController extends AsyncNotifier<ExplorerMapState> {
  Timer? _queryTimer;
  GeoBounds? _lastAcceptedBounds;
  GeoBounds? _pendingBounds;
  int _queryRevision = 0;
  bool _pendingBoundsAreReady = false;
  bool _queryInFlight = false;
  bool _disposed = false;

  @override
  Future<ExplorerMapState> build() async {
    await ref.watch(chargingRepositoryProvider.future);
    ref.onDispose(() {
      _disposed = true;
      _queryRevision++;
      _queryTimer?.cancel();
      _pendingBounds = null;
    });
    return const ExplorerMapState();
  }

  void visibleBoundsChanged(GeoBounds bounds) {
    if (_disposed ||
        (_lastAcceptedBounds != null &&
            _nearlySameBounds(_lastAcceptedBounds!, bounds))) {
      return;
    }
    _lastAcceptedBounds = bounds;
    _pendingBounds = bounds;
    _pendingBoundsAreReady = false;
    _queryRevision++;
    _queryTimer?.cancel();
    _queryTimer = Timer(const Duration(milliseconds: 300), () {
      _pendingBoundsAreReady = true;
      unawaited(_runLatestPendingQuery());
    });
  }

  Future<ChargingGroupDetail?> loadGroupDetail(String groupId) async {
    final repository = await ref.read(chargingRepositoryProvider.future);
    return repository.getGroupDetail(groupId);
  }

  Future<ChargingGroupDetail?> loadGroupContainingStation(
    String stationId, {
    int? diameterM,
  }) async {
    final repository = await ref.read(chargingRepositoryProvider.future);
    return repository.getGroupDetailContainingStation(
      stationId,
      diameterM ?? state.requireValue.filters.diameterM,
    );
  }

  Future<ChargingFilterOptions> loadFilterOptions() async {
    final repository = await ref.read(chargingRepositoryProvider.future);
    return repository.getFilterOptions();
  }

  Future<List<OperatorFilterOption>> loadPopularOperators() async {
    final repository = await ref.read(chargingRepositoryProvider.future);
    return repository.getPopularOperators();
  }

  Future<List<OperatorFilterOption>> searchOperators(String text) async {
    final repository = await ref.read(chargingRepositoryProvider.future);
    return repository.searchOperators(text);
  }

  Future<List<ChargingGroupSummary>> searchGroups(String text) async {
    final current = state.requireValue;
    final repository = await ref.read(chargingRepositoryProvider.future);
    return repository.findGroups(
      _queryFor(
        const GeoBounds(south: 47, west: 5, north: 55.2, east: 15.5),
        current.filters,
        favoriteAnchorStationIds: current.favoriteAnchorStationIds,
        amenityAnchorStationIds: current.amenityAnchorStationIds,
        searchText: text,
        limit: 50,
      ),
    );
  }

  /// Groups within [radiusKm] of [center] under the current filters and
  /// favorite/amenity anchors. Used by the route corridor search (FR-ROUTE-003).
  Future<List<ChargingGroupSummary>> findGroupsNear(
    GeoCoordinate center, {
    required double radiusKm,
  }) async {
    final current = state.requireValue;
    final repository = await ref.read(chargingRepositoryProvider.future);
    return repository.findGroups(
      _queryFor(
        _boundsForRadius(center, radiusKm),
        current.filters,
        favoriteAnchorStationIds: current.favoriteAnchorStationIds,
        amenityAnchorStationIds: current.amenityAnchorStationIds,
        center: center,
        radiusKm: radiusKm,
      ),
    );
  }

  Future<LocationSearchTarget?> findNearestPark(GeoCoordinate center) async {
    final current = state.requireValue;
    final repository = await ref.read(chargingRepositoryProvider.future);
    for (final radiusKm in const <double>[5, 10, 25, 50, 100, 200]) {
      final groups = await repository.findGroups(
        _queryFor(
          _boundsForRadius(center, radiusKm),
          current.filters,
          favoriteAnchorStationIds: current.favoriteAnchorStationIds,
          amenityAnchorStationIds: current.amenityAnchorStationIds,
          center: center,
          radiusKm: radiusKm,
          limit: 50,
        ),
      );
      if (groups.isEmpty) continue;
      final nearest = groups.first;
      final distanceKm = _haversineKm(
        center,
        GeoCoordinate(latitude: nearest.latitude, longitude: nearest.longitude),
      );
      return LocationSearchTarget(
        center: center,
        radiusKm: math.max(5, distanceKm * 1.3),
        nearestGroup: nearest,
      );
    }
    return null;
  }

  void showNearby(GeoCoordinate center, double radiusKm) {
    final current = state.value;
    if (_disposed || current == null) return;
    state = AsyncData(
      current.copyWith(
        filters: current.filters.copyWith(nearbyRadiusKm: radiusKm.toInt()),
        nearbyCenter: center,
        clearError: true,
      ),
    );
    _pendingBounds = _boundsForRadius(center, radiusKm);
    _pendingBoundsAreReady = true;
    _queryRevision++;
    _queryTimer?.cancel();
    unawaited(_runLatestPendingQuery());
  }

  void clearNearby() {
    final current = state.value;
    if (_disposed || current == null) return;
    state = AsyncData(
      current.copyWith(
        filters: current.filters.copyWith(clearNearbyRadius: true),
        clearNearby: true,
        clearError: true,
      ),
    );
    final bounds = current.bounds ?? _lastAcceptedBounds;
    if (bounds == null) return;
    _pendingBounds = bounds;
    _pendingBoundsAreReady = true;
    _queryRevision++;
    _queryTimer?.cancel();
    unawaited(_runLatestPendingQuery());
  }

  void filtersChanged(
    ExplorerFilters filters, {
    List<String> favoriteAnchorStationIds = const <String>[],
    List<String> amenityAnchorStationIds = const <String>[],
    GeoCoordinate? nearbyCenter,
    bool clearNearby = false,
  }) {
    final current = state.value;
    if (_disposed || current == null) return;
    state = AsyncData(
      current.copyWith(
        filters: filters,
        favoriteAnchorStationIds: favoriteAnchorStationIds,
        amenityAnchorStationIds: amenityAnchorStationIds,
        nearbyCenter: nearbyCenter,
        clearNearby: clearNearby,
        clearError: true,
      ),
    );
    final bounds = current.bounds ?? _lastAcceptedBounds;
    if (bounds == null) return;
    _pendingBounds = bounds;
    _pendingBoundsAreReady = true;
    _queryRevision++;
    _queryTimer?.cancel();
    unawaited(_runLatestPendingQuery());
  }

  void favoriteAnchorsChanged(List<String> favoriteAnchorStationIds) {
    final current = state.value;
    if (_disposed || current == null) return;
    state = AsyncData(
      current.copyWith(favoriteAnchorStationIds: favoriteAnchorStationIds),
    );
    final bounds = current.bounds ?? _lastAcceptedBounds;
    if (bounds == null) return;
    _pendingBounds = bounds;
    _pendingBoundsAreReady = true;
    _queryRevision++;
    _queryTimer?.cancel();
    unawaited(_runLatestPendingQuery());
  }

  Future<void> _runLatestPendingQuery() async {
    if (_disposed || _queryInFlight || !_pendingBoundsAreReady) {
      return;
    }
    final visibleBounds = _pendingBounds;
    final current = state.value;
    if (visibleBounds == null || current == null) {
      return;
    }
    final revision = _queryRevision;
    _pendingBounds = null;
    _pendingBoundsAreReady = false;
    _queryInFlight = true;
    final stopwatch = Stopwatch()..start();
    state = AsyncData(
      current.copyWith(
        bounds: visibleBounds,
        isQuerying: true,
        clearError: true,
      ),
    );
    try {
      final repository = await ref.read(chargingRepositoryProvider.future);
      final filters = current.filters;
      final groups = await repository.findGroups(
        _queryFor(
          _withQueryMargin(visibleBounds),
          filters,
          favoriteAnchorStationIds: current.favoriteAnchorStationIds,
          amenityAnchorStationIds: current.amenityAnchorStationIds,
          center: filters.nearbyRadiusKm == null ? null : current.nearbyCenter,
          radiusKm: filters.nearbyRadiusKm?.toDouble(),
        ),
      );
      if (_disposed || revision != _queryRevision) {
        return;
      }
      state = AsyncData(
        state.requireValue.copyWith(groups: groups, isQuerying: false),
      );
    } on Object catch (error) {
      if (_disposed || revision != _queryRevision) {
        return;
      }
      final category = error is ChargingRepositoryException
          ? error.error
          : ChargingRepositoryError.queryFailed;
      state = AsyncData(
        state.requireValue.copyWith(isQuerying: false, error: category),
      );
    } finally {
      stopwatch.stop();
      _queryInFlight = false;
      if (kDebugMode) {
        debugPrint(
          '[LadeparkMap] query revision=$revision '
          'elapsedMs=${stopwatch.elapsedMilliseconds} '
          'pending=${_pendingBounds != null}',
        );
      }
      if (_pendingBoundsAreReady) {
        unawaited(_runLatestPendingQuery());
      }
    }
  }
}

ChargingGroupQuery _queryFor(
  GeoBounds bounds,
  ExplorerFilters filters, {
  String? searchText,
  GeoCoordinate? center,
  double? radiusKm,
  int limit = 500,
  List<String> favoriteAnchorStationIds = const <String>[],
  List<String> amenityAnchorStationIds = const <String>[],
}) => ChargingGroupQuery(
  bounds: bounds,
  diameterM: filters.diameterM,
  minimumEvseCount: filters.minimumEvseCount,
  minimumPowerKw: filters.minimumPowerKw,
  operatorNames: filters.operatorNames,
  operatorIds: filters.operatorIds,
  connectorTypes: filters.connectorTypes,
  favoriteAnchorStationIds: favoriteAnchorStationIds,
  amenityAnchorStationIds: amenityAnchorStationIds,
  amenitiesOnly: filters.requiredAmenities.isNotEmpty,
  alwaysOpenOnly: filters.alwaysOpenOnly,
  favoritesOnly: filters.favoritesOnly,
  searchText: searchText,
  center: center,
  radiusKm: radiusKm,
  limit: limit,
);

GeoBounds _boundsForRadius(GeoCoordinate center, double radiusKm) {
  final latitudeDelta = radiusKm / 111.32;
  final longitudeScale =
      111.32 * _cosineForLatitude(center.latitude).clamp(0.01, 1.0);
  final longitudeDelta = radiusKm / longitudeScale;
  return GeoBounds(
    south: (center.latitude - latitudeDelta).clamp(-90, 90),
    west: _normalizeLongitude(center.longitude - longitudeDelta),
    north: (center.latitude + latitudeDelta).clamp(-90, 90),
    east: _normalizeLongitude(center.longitude + longitudeDelta),
  );
}

double _cosineForLatitude(double latitude) {
  const values = <double>[
    1,
    .996,
    .985,
    .966,
    .94,
    .906,
    .866,
    .819,
    .766,
    .707,
    .643,
    .574,
  ];
  final index = (latitude.abs() / 5).round().clamp(0, values.length - 1);
  return values[index];
}

bool _nearlySameBounds(GeoBounds first, GeoBounds second) {
  final latitudeTolerance = ((first.north - first.south).abs() * 0.005).clamp(
    0.0001,
    1.0,
  );
  final longitudeSpan = first.west <= first.east
      ? first.east - first.west
      : 360 - first.west + first.east;
  final longitudeTolerance = (longitudeSpan.abs() * 0.005).clamp(0.0001, 1.0);
  return (first.south - second.south).abs() <= latitudeTolerance &&
      (first.north - second.north).abs() <= latitudeTolerance &&
      (first.west - second.west).abs() <= longitudeTolerance &&
      (first.east - second.east).abs() <= longitudeTolerance;
}

GeoBounds _withQueryMargin(GeoBounds bounds) {
  const margin = 0.15;
  final latitudePadding = (bounds.north - bounds.south) * margin / 2;
  final longitudeSpan = bounds.west <= bounds.east
      ? bounds.east - bounds.west
      : 360 - bounds.west + bounds.east;
  final longitudePadding = longitudeSpan * margin / 2;
  return GeoBounds(
    south: (bounds.south - latitudePadding).clamp(-90, 90),
    west: _normalizeLongitude(bounds.west - longitudePadding),
    north: (bounds.north + latitudePadding).clamp(-90, 90),
    east: _normalizeLongitude(bounds.east + longitudePadding),
  );
}

double _normalizeLongitude(double longitude) {
  var result = longitude;
  while (result < -180) {
    result += 360;
  }
  while (result > 180) {
    result -= 360;
  }
  return result;
}

double _haversineKm(GeoCoordinate first, GeoCoordinate second) {
  const earthRadiusKm = 6371.0088;
  final latitudeDelta = _radians(second.latitude - first.latitude);
  final longitudeDelta = _radians(second.longitude - first.longitude);
  final firstLatitude = _radians(first.latitude);
  final secondLatitude = _radians(second.latitude);
  final haversine =
      math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
      math.cos(firstLatitude) *
          math.cos(secondLatitude) *
          math.sin(longitudeDelta / 2) *
          math.sin(longitudeDelta / 2);
  return earthRadiusKm * 2 * math.asin(math.sqrt(haversine.clamp(0, 1)));
}

double _radians(double degrees) => degrees * math.pi / 180;
