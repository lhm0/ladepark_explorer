import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_query.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/explorer_filters.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_bounds.dart';

void main() {
  const germany = GeoBounds(south: 47.2, west: 5.8, north: 55.1, east: 15.1);

  test('uses the agreed default filters and result limit', () {
    const query = ChargingGroupQuery(bounds: germany);

    expect(query.diameterM, 50);
    expect(query.minimumEvseCount, 20);
    expect(query.minimumPowerKw, 100);
    expect(query.favoriteAnchorStationIds, isEmpty);
    expect(query.amenityAnchorStationIds, isEmpty);
    expect(query.amenitiesOnly, isFalse);
    expect(query.alwaysOpenOnly, isFalse);
    expect(query.favoritesOnly, isFalse);
    expect(query.limit, 500);
  });

  test('rejects a map result limit above 500', () {
    expect(
      () => ChargingGroupQuery(bounds: germany, limit: 501),
      throwsA(isA<AssertionError>()),
    );
  });

  test('distance limit is part of filter equality and can be cleared', () {
    const filters = ExplorerFilters(nearbyRadiusKm: 25);

    expect(filters.isDefault, isFalse);
    expect(filters.copyWith(clearNearbyRadius: true), ExplorerFilters.defaults);
  });
}
