import 'package:ladepark_explorer/data/charging/sqlite/charging_database_worker.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_detail.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_query.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_summary.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/explorer_filters.dart';
import 'package:ladepark_explorer/features/explorer/domain/repositories/charging_repository.dart';

final class SqliteChargingRepository implements ChargingRepository {
  const SqliteChargingRepository._(this._worker);

  final ChargingDatabaseWorker _worker;

  static Future<SqliteChargingRepository> open(String databasePath) async {
    final worker = await ChargingDatabaseWorker.open(databasePath);
    return SqliteChargingRepository._(worker);
  }

  Future<void> close() => _worker.close();

  @override
  Future<List<ChargingGroupSummary>> findGroups(
    ChargingGroupQuery query,
  ) async {
    final rows = await _worker.findGroups(<String, Object?>{
      'diameter': query.diameterM,
      'minimumEvseCount': query.minimumEvseCount,
      'minimumPowerKw': query.minimumPowerKw,
      'operatorNames': query.operatorNames,
      'operatorIds': query.operatorIds,
      'connectorTypes': query.connectorTypes,
      'favoriteAnchorStationIds': query.favoriteAnchorStationIds,
      'amenityAnchorStationIds': query.amenityAnchorStationIds,
      'amenitiesOnly': query.amenitiesOnly,
      'alwaysOpenOnly': query.alwaysOpenOnly,
      'favoritesOnly': query.favoritesOnly,
      'searchText': query.searchText,
      'centerLatitude': query.center?.latitude,
      'centerLongitude': query.center?.longitude,
      'radiusKm': query.radiusKm,
      'south': query.bounds.south,
      'west': query.bounds.west,
      'north': query.bounds.north,
      'east': query.bounds.east,
      'limit': query.limit,
    });
    return rows.map(_summaryFromRow).toList(growable: false);
  }

  @override
  Future<ChargingGroupDetail?> getGroupDetail(String groupId) async {
    final row = await _worker.getGroupDetail(groupId);
    if (row == null) {
      return null;
    }
    return _detailFromRow(row);
  }

  @override
  Future<ChargingGroupDetail?> getGroupDetailContainingStation(
    String stationId,
    int diameterM,
  ) async {
    final row = await _worker.getGroupDetailContainingStation(
      stationId,
      diameterM,
    );
    if (row == null) return null;
    return _detailFromRow(row);
  }

  @override
  Future<ChargingFilterOptions> getFilterOptions() async {
    final row = await _worker.getFilterOptions();
    return ChargingFilterOptions(
      connectorTypes: _strings(row, 'connectorTypes'),
    );
  }

  @override
  Future<List<OperatorFilterOption>> getPopularOperators({
    int limit = 20,
  }) async => (await _worker.getPopularOperators(
    limit,
  )).map((row) => _operatorOption(row, true)).toList(growable: false);

  @override
  Future<List<OperatorFilterOption>> searchOperators(
    String text, {
    int limit = 50,
  }) async => (await _worker.searchOperators(
    text,
    limit,
  )).map((row) => _operatorOption(row, false)).toList(growable: false);
}

ChargingGroupDetail _detailFromRow(Map<String, Object?> row) =>
    ChargingGroupDetail(
      groupId: _string(row, 'groupId'),
      anchorStationId: _string(row, 'anchorStationId'),
      stationIds: _strings(row, 'stationIds'),
      name: _nullableString(row, 'name'),
      street: _nullableString(row, 'street'),
      houseNumber: _nullableString(row, 'houseNumber'),
      postalCode: _nullableString(row, 'postalCode'),
      city: _nullableString(row, 'city'),
      latitude: _double(row, 'latitude'),
      longitude: _double(row, 'longitude'),
      stationCount: _int(row, 'stationCount'),
      evseCount: _int(row, 'evseCount'),
      maxPowerKw: _nullableDouble(row, 'maxPowerKw'),
      actualDiameterM: _double(row, 'actualDiameterM'),
      operators: _operatorDetails(row),
      connectorTypes: _strings(row, 'connectorTypes'),
      powerBandCounts: _powerBandCounts(row),
      openingHours: _nullableString(row, 'openingHours'),
      datasetVersion: _string(row, 'datasetVersion'),
      datasetCreatedAt: _string(row, 'datasetCreatedAt'),
      sourceName: _string(row, 'sourceName'),
      sourceVersion: _string(row, 'sourceVersion'),
    );

OperatorFilterOption _operatorOption(
  Map<String, Object?> row,
  bool canonical,
) => OperatorFilterOption(
  value: _string(row, 'value'),
  displayName: _string(row, 'display_name'),
  evseCount: _int(row, 'evse_count'),
  isCanonical: canonical,
);

ChargingGroupSummary _summaryFromRow(Map<String, Object?> row) {
  final maximumPower = row['maxPowerKw'];
  final city = row['city'];
  return ChargingGroupSummary(
    groupId: _string(row, 'groupId'),
    latitude: _double(row, 'latitude'),
    longitude: _double(row, 'longitude'),
    stationCount: _int(row, 'stationCount'),
    evseCount: _int(row, 'evseCount'),
    hpcEvseCount: _int(row, 'hpcEvseCount'),
    maxPowerKw: maximumPower == null ? null : (maximumPower as num).toDouble(),
    city: city == null ? null : city as String,
    name: _nullableString(row, 'name'),
    street: _nullableString(row, 'street'),
    houseNumber: _nullableString(row, 'houseNumber'),
    postalCode: _nullableString(row, 'postalCode'),
    isFavorite: row['isFavorite']! as bool,
  );
}

String _string(Map<String, Object?> row, String key) => row[key]! as String;

int _int(Map<String, Object?> row, String key) => row[key]! as int;

double _double(Map<String, Object?> row, String key) =>
    (row[key]! as num).toDouble();

double? _nullableDouble(Map<String, Object?> row, String key) {
  final value = row[key];
  return value == null ? null : (value as num).toDouble();
}

String? _nullableString(Map<String, Object?> row, String key) =>
    row[key] as String?;

List<String> _strings(Map<String, Object?> row, String key) =>
    (row[key]! as List<Object?>).cast<String>();

Map<int, int> _powerBandCounts(Map<String, Object?> row) {
  final values = row['powerBandCounts']! as Map<String, Object?>;
  return <int, int>{
    for (final entry in values.entries)
      int.parse(entry.key): entry.value! as int,
  };
}

List<ChargingOperatorDetail> _operatorDetails(Map<String, Object?> row) =>
    (row['operators']! as List<Object?>)
        .cast<Map<String, Object?>>()
        .map(
          (operator) => ChargingOperatorDetail(
            name: _string(operator, 'name'),
            connectorCountsByPowerBand: _connectorCountsByPowerBand(operator),
          ),
        )
        .toList(growable: false);

Map<int, Map<String, int>> _connectorCountsByPowerBand(
  Map<String, Object?> operator,
) {
  final bands = operator['connectorCountsByPowerBand']! as Map<String, Object?>;
  return <int, Map<String, int>>{
    for (final band in bands.entries)
      int.parse(band.key): <String, int>{
        for (final connector in (band.value! as Map<String, Object?>).entries)
          connector.key: connector.value! as int,
      },
  };
}
