import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:ladepark_explorer/features/explorer/domain/repositories/charging_repository_exception.dart';
import 'package:sqlite3/sqlite3.dart';

const _supportedSchemaVersion = 2;
const _supportedDiameters = <int>{25, 50, 100, 200, 300};
const _supportedPowerBands = <int>{0, 50, 100, 150, 200, 250, 300, 350};
const _requiredMetadataKeys = <String>{
  'dataset_id',
  'dataset_version',
  'schema_version',
  'created_at',
  'pipeline_version',
  'region',
  'license_summary',
};

final class ChargingDatabaseWorker {
  ChargingDatabaseWorker._(this._receivePort);

  final ReceivePort _receivePort;
  final Map<int, Completer<Object?>> _pending = {};
  final Completer<SendPort> _ready = Completer<SendPort>();
  Isolate? _isolate;
  SendPort? _commandPort;
  int _nextRequestId = 1;
  bool _closed = false;

  static Future<ChargingDatabaseWorker> open(String databasePath) async {
    final receivePort = ReceivePort();
    final worker = ChargingDatabaseWorker._(receivePort);
    receivePort.listen(worker._handleMessage);
    worker._isolate = await Isolate.spawn<List<Object?>>(
      _workerMain,
      <Object?>[databasePath, receivePort.sendPort],
      errorsAreFatal: true,
      onError: receivePort.sendPort,
      onExit: receivePort.sendPort,
    );
    try {
      worker._commandPort = await worker._ready.future;
      return worker;
    } on Object {
      await worker._dispose();
      rethrow;
    }
  }

  Future<List<Map<String, Object?>>> findGroups(
    Map<String, Object?> query,
  ) async {
    final result = await _request('findGroups', query);
    if (result is! List<Object?>) {
      throw const ChargingRepositoryException(
        ChargingRepositoryError.queryFailed,
        'Die Datenbank lieferte ein ungültiges Gruppenergebnis.',
      );
    }
    return result.map(_objectMap).toList(growable: false);
  }

  Future<Map<String, Object?>?> getGroupDetail(String groupId) async {
    final result = await _request('getGroupDetail', <String, Object?>{
      'groupId': groupId,
    });
    return result == null ? null : _objectMap(result);
  }

  Future<Map<String, Object?>?> getGroupDetailContainingStation(
    String stationId,
    int diameterM,
  ) async {
    final result = await _request(
      'getGroupDetailContainingStation',
      <String, Object?>{'stationId': stationId, 'diameterM': diameterM},
    );
    return result == null ? null : _objectMap(result);
  }

  Future<Map<String, Object?>> getFilterOptions() async {
    return _objectMap(
      await _request('getFilterOptions', const <String, Object?>{}),
    );
  }

  Future<List<Map<String, Object?>>> getPopularOperators(int limit) async {
    final result = await _request('getPopularOperators', <String, Object?>{
      'limit': limit,
    });
    return (result! as List<Object?>).map(_objectMap).toList(growable: false);
  }

  Future<List<Map<String, Object?>>> searchOperators(
    String text,
    int limit,
  ) async {
    final result = await _request('searchOperators', <String, Object?>{
      'text': text,
      'limit': limit,
    });
    return (result! as List<Object?>).map(_objectMap).toList(growable: false);
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    await _request('close', const <String, Object?>{});
    await _dispose();
  }

  Future<Object?> _request(String command, Map<String, Object?> payload) {
    if (_closed || _commandPort == null) {
      return Future<Object?>.error(
        const ChargingRepositoryException(
          ChargingRepositoryError.repositoryClosed,
          'Das Ladepark-Repository ist bereits geschlossen.',
        ),
      );
    }
    final requestId = _nextRequestId++;
    final completer = Completer<Object?>();
    _pending[requestId] = completer;
    _commandPort!.send(<String, Object?>{
      'id': requestId,
      'command': command,
      'payload': payload,
    });
    return completer.future;
  }

  void _handleMessage(Object? message) {
    if (message case {'ready': final SendPort sendPort}) {
      if (!_ready.isCompleted) {
        _ready.complete(sendPort);
      }
      return;
    }
    if (message case {
      'startupError': {'code': final String code, 'message': final String text},
    }) {
      final error = _exception(code, text);
      if (!_ready.isCompleted) {
        _ready.completeError(error);
      }
      return;
    }
    if (message case {'id': final int id, 'result': final Object? result}) {
      _pending.remove(id)?.complete(result);
      return;
    }
    if (message case {
      'id': final int id,
      'error': {'code': final String code, 'message': final String text},
    }) {
      _pending.remove(id)?.completeError(_exception(code, text));
      return;
    }
    if (message == null || message is List<Object?>) {
      final error = const ChargingRepositoryException(
        ChargingRepositoryError.workerTerminated,
        'Der Datenbankprozess wurde unerwartet beendet.',
      );
      if (!_ready.isCompleted) {
        _ready.completeError(error);
      }
      _failPending(error);
    }
  }

  Future<void> _dispose() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _commandPort = null;
    _isolate?.kill();
    _isolate = null;
    _receivePort.close();
    _failPending(
      const ChargingRepositoryException(
        ChargingRepositoryError.repositoryClosed,
        'Das Ladepark-Repository wurde geschlossen.',
      ),
    );
  }

  void _failPending(ChargingRepositoryException error) {
    for (final completer in _pending.values) {
      completer.completeError(error);
    }
    _pending.clear();
  }
}

ChargingRepositoryException _exception(String code, String message) {
  final error = ChargingRepositoryError.values.firstWhere(
    (value) => value.name == code,
    orElse: () => ChargingRepositoryError.queryFailed,
  );
  return ChargingRepositoryException(error, message);
}

Map<String, Object?> _objectMap(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  throw const ChargingRepositoryException(
    ChargingRepositoryError.queryFailed,
    'Die Datenbank lieferte ein ungültiges Objekt.',
  );
}

void _workerMain(List<Object?> arguments) {
  final databasePath = arguments[0]! as String;
  final owner = arguments[1]! as SendPort;
  final commands = ReceivePort();
  Database? database;
  try {
    database = _openAndValidate(databasePath);
    owner.send(<String, Object?>{'ready': commands.sendPort});
  } on _WorkerFailure catch (error) {
    owner.send(<String, Object?>{'startupError': error.toMessage()});
    commands.close();
    return;
  } on Object catch (error) {
    owner.send(<String, Object?>{
      'startupError': _WorkerFailure(
        ChargingRepositoryError.queryFailed,
        'Die Ladepark-Datenbank konnte nicht geöffnet werden: $error',
      ).toMessage(),
    });
    commands.close();
    return;
  }

  commands.listen((Object? message) {
    if (message case {
      'id': final int id,
      'command': final String command,
      'payload': final Map<String, Object?> payload,
    }) {
      try {
        final Object? result = switch (command) {
          'findGroups' => _findGroups(database!, payload),
          'getGroupDetail' => _getGroupDetail(database!, payload),
          'getGroupDetailContainingStation' => _getGroupDetailContainingStation(
            database!,
            payload,
          ),
          'getFilterOptions' => _getFilterOptions(database!),
          'getPopularOperators' => _getPopularOperators(database!, payload),
          'searchOperators' => _searchOperators(database!, payload),
          'close' => null,
          _ => throw const _WorkerFailure(
            ChargingRepositoryError.invalidQuery,
            'Unbekannter Datenbankbefehl.',
          ),
        };
        owner.send(<String, Object?>{'id': id, 'result': result});
        if (command == 'close') {
          database!.close();
          commands.close();
        }
      } on _WorkerFailure catch (error) {
        owner.send(<String, Object?>{'id': id, 'error': error.toMessage()});
      } on SqliteException catch (error) {
        owner.send(<String, Object?>{
          'id': id,
          'error': _WorkerFailure(
            ChargingRepositoryError.queryFailed,
            'SQLite-Abfrage fehlgeschlagen: ${error.message}',
          ).toMessage(),
        });
      } on Object catch (error) {
        owner.send(<String, Object?>{
          'id': id,
          'error': _WorkerFailure(
            ChargingRepositoryError.queryFailed,
            'Datenbankabfrage fehlgeschlagen: $error',
          ).toMessage(),
        });
      }
    }
  });
}

Map<String, Object?> _getFilterOptions(Database database) {
  final connectors = database.select('''
    SELECT DISTINCT connector_type
    FROM group_connector
    WHERE trim(connector_type) <> ''
    ORDER BY connector_type COLLATE NOCASE
  ''');
  return <String, Object?>{
    'connectorTypes': connectors
        .map((row) => row['connector_type']! as String)
        .toList(growable: false),
  };
}

List<Map<String, Object?>> _getPopularOperators(
  Database database,
  Map<String, Object?> payload,
) {
  final hasMaterializedOptions = database.select(
    "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
    <Object?>['operator_filter_option'],
  ).isNotEmpty;
  if (!hasMaterializedOptions) return const [];
  final limit = _intValue(payload, 'limit');
  return database
      .select(
        '''
    SELECT o.operator_id AS value, o.canonical_name AS canonical_name,
           o.display_name, f.evse_count
    FROM operator_filter_option f JOIN operator o ON o.operator_id = f.operator_id
    ORDER BY f.evse_count DESC, o.canonical_name COLLATE NOCASE LIMIT ?
  ''',
        <Object?>[limit],
      )
      .map((row) => Map<String, Object?>.from(row))
      .toList();
}

List<Map<String, Object?>> _searchOperators(
  Database database,
  Map<String, Object?> payload,
) {
  final text = payload['text'];
  final limit = _intValue(payload, 'limit');
  if (text is! String || text.trim().length < 2) return const [];
  return database
      .select(
        '''
    SELECT source_name AS value, source_name AS display_name,
           (SELECT COUNT(*) FROM evse e JOIN station s ON s.station_id = e.station_id
            WHERE s.operator_source_id = os.operator_source_id) AS evse_count
    FROM operator_source os
    WHERE source_name LIKE ? COLLATE NOCASE
      AND canonical_operator_id IS NULL
    ORDER BY evse_count DESC, source_name COLLATE NOCASE LIMIT ?
  ''',
        <Object?>['%${text.trim()}%', limit],
      )
      .map((row) => Map<String, Object?>.from(row))
      .toList();
}

Database _openAndValidate(String path) {
  if (!File(path).existsSync()) {
    throw const _WorkerFailure(
      ChargingRepositoryError.databaseNotFound,
      'Die Ladepark-Datenbank wurde nicht gefunden.',
    );
  }
  final database = sqlite3.open(path, mode: OpenMode.readOnly);
  try {
    if (database.userVersion != _supportedSchemaVersion) {
      throw _WorkerFailure(
        ChargingRepositoryError.unsupportedSchema,
        'Nicht unterstützte SQLite-Schemaversion ${database.userVersion}.',
      );
    }
    final metadataRows = database.select('SELECT key, value FROM metadata');
    final metadata = <String, String>{
      for (final row in metadataRows)
        row['key']! as String: row['value']! as String,
    };
    final missingKeys = _requiredMetadataKeys.difference(metadata.keys.toSet());
    if (missingKeys.isNotEmpty ||
        metadata['schema_version'] != '$_supportedSchemaVersion') {
      throw const _WorkerFailure(
        ChargingRepositoryError.unsupportedSchema,
        'Die Metadaten des Ladepark-Datensatzes sind unvollständig oder inkompatibel.',
      );
    }
    return database;
  } on _WorkerFailure {
    database.close();
    rethrow;
  } on SqliteException catch (error) {
    database.close();
    throw _WorkerFailure(
      ChargingRepositoryError.unsupportedSchema,
      'Der SQLite-Schemavertrag ist unvollständig: ${error.message}',
    );
  }
}

List<Map<String, Object?>> _findGroups(
  Database database,
  Map<String, Object?> payload,
) {
  final query = _WorkerQuery.fromPayload(payload);
  final favoriteGroupIds = _resolveGroupIdsForStations(
    database,
    query.diameter,
    query.favoriteAnchorStationIds,
  );
  final amenityGroupIds = _resolveGroupIdsForStations(
    database,
    query.diameter,
    query.amenityAnchorStationIds,
  );
  final clauses = <String>['g.diameter_m = ?', 'g.evse_count >= ?'];
  final parameters = <Object?>[query.diameter, query.minimumEvseCount];

  final powerBandTable = query.alwaysOpenOnly
      ? 'group_always_open_power_band'
      : 'group_power_band';
  clauses.add('''
      EXISTS (
        SELECT 1 FROM $powerBandTable pb
        WHERE pb.group_id = g.group_id
          AND pb.minimum_power_kw = ?
          AND pb.evse_count >= ?
      )
    ''');
  parameters.addAll(<Object?>[query.minimumPowerKw, query.minimumEvseCount]);
  _addMultiValueFilter(clauses, parameters, query.operatorNames, '''
      EXISTS (
        SELECT 1 FROM group_operator_source gos
        JOIN operator_source os
          ON os.operator_source_id = gos.operator_source_id
        WHERE gos.group_id = g.group_id
          AND os.source_name IN ({placeholders})
      )
    ''');
  _addMultiValueFilter(clauses, parameters, query.operatorIds, '''
      EXISTS (
        SELECT 1 FROM group_operator go
        WHERE go.group_id = g.group_id
          AND go.operator_id IN ({placeholders})
      )
    ''');
  _addMultiValueFilter(clauses, parameters, query.connectorTypes, '''
      EXISTS (
        SELECT 1 FROM group_connector gc
        WHERE gc.group_id = g.group_id
          AND gc.connector_type IN ({placeholders})
      )
    ''');
  if (query.favoritesOnly) {
    if (favoriteGroupIds.isEmpty) {
      clauses.add('0');
    } else {
      final placeholders = List<String>.filled(
        favoriteGroupIds.length,
        '?',
      ).join(', ');
      clauses.add('g.group_id IN ($placeholders)');
      parameters.addAll(favoriteGroupIds);
    }
  }
  if (query.amenitiesOnly) {
    if (amenityGroupIds.isEmpty) {
      clauses.add('0');
    } else {
      final placeholders = List<String>.filled(
        amenityGroupIds.length,
        '?',
      ).join(', ');
      clauses.add('g.group_id IN ($placeholders)');
      parameters.addAll(amenityGroupIds);
    }
  }
  if (query.searchText case final String searchText) {
    clauses.add('''
      g.group_id IN (
        SELECT gm.group_id
        FROM station_search
        JOIN proximity_group_member gm
          ON gm.station_id = station_search.station_id
        WHERE station_search MATCH ?
      )
    ''');
    parameters.add(_ftsExpression(searchText));
  }

  final longitudeSpan = query.west <= query.east
      ? query.east - query.west
      : 360 - query.west + query.east;
  final useRTree = (query.north - query.south) * longitudeSpan <= 25;
  final groupGeoJoin = useRTree
      ? 'JOIN proximity_group_geo gg ON gg.group_rowid = g.group_rowid'
      : '';
  if (useRTree) {
    clauses.addAll(<String>['gg.max_latitude >= ?', 'gg.min_latitude <= ?']);
  } else {
    clauses.add('g.latitude BETWEEN ? AND ?');
  }
  parameters.addAll(<Object?>[query.south, query.north]);
  if (query.west <= query.east) {
    clauses.add(
      useRTree
          ? 'gg.max_longitude >= ? AND gg.min_longitude <= ?'
          : 'g.longitude BETWEEN ? AND ?',
    );
  } else {
    clauses.add(
      useRTree
          ? '(gg.max_longitude >= ? OR gg.min_longitude <= ?)'
          : '(g.longitude >= ? OR g.longitude <= ?)',
    );
  }
  parameters.addAll(<Object?>[
    query.west,
    query.east,
    query.radiusKm == null ? query.limit + 1 : 20001,
  ]);

  final rows = database.select('''
    SELECT g.group_id, g.latitude, g.longitude, g.station_count,
           g.evse_count, g.hpc_evse_count, g.max_power_kw,
           s.name, s.street, s.house_number, s.postal_code, s.city
    FROM proximity_group g
    $groupGeoJoin
    JOIN station s ON s.station_id = g.anchor_station_id
    WHERE ${clauses.map((clause) => '($clause)').join(' AND ')}
    ORDER BY g.hpc_evse_count DESC, g.evse_count DESC, g.group_id
    LIMIT ?
  ''', parameters);
  final radiusRows = query.radiusKm == null
      ? rows
      : (rows
            .where((row) => _rowDistanceKm(row, query) <= query.radiusKm!)
            .toList()
          ..sort(
            (first, second) => _rowDistanceKm(
              first,
              query,
            ).compareTo(_rowDistanceKm(second, query)),
          ));
  return radiusRows
      .take(query.limit)
      .map(
        (row) => <String, Object?>{
          'groupId': row['group_id'],
          'latitude': row['latitude'],
          'longitude': row['longitude'],
          'stationCount': row['station_count'],
          'evseCount': row['evse_count'],
          'hpcEvseCount': row['hpc_evse_count'],
          'maxPowerKw': row['max_power_kw'],
          'city': row['city'],
          'name': row['name'],
          'street': row['street'],
          'houseNumber': row['house_number'],
          'postalCode': row['postal_code'],
          'isFavorite': favoriteGroupIds.contains(row['group_id']),
        },
      )
      .toList(growable: false);
}

Set<String> _resolveGroupIdsForStations(
  Database database,
  int diameter,
  List<String> anchorStationIds,
) {
  final result = <String>{};
  const chunkSize = 400;
  for (var offset = 0; offset < anchorStationIds.length; offset += chunkSize) {
    final end = math.min(offset + chunkSize, anchorStationIds.length);
    final stationIds = anchorStationIds.sublist(offset, end);
    final placeholders = List<String>.filled(stationIds.length, '?').join(', ');
    final rows = database.select(
      '''
        SELECT DISTINCT gm.group_id
        FROM proximity_group_member gm
        JOIN proximity_group g ON g.group_id = gm.group_id
        WHERE g.diameter_m = ?
          AND (
            gm.station_id IN ($placeholders)
            OR gm.station_id IN (
              SELECT current_station_id
              FROM station_id_alias
              WHERE old_station_id IN ($placeholders)
            )
          )
      ''',
      <Object?>[diameter, ...stationIds, ...stationIds],
    );
    result.addAll(rows.map((row) => row['group_id']! as String));
  }
  return result;
}

Map<String, Object?>? _getGroupDetail(
  Database database,
  Map<String, Object?> payload,
) {
  final groupId = payload['groupId'];
  if (groupId is! String || groupId.isEmpty) {
    throw const _WorkerFailure(
      ChargingRepositoryError.invalidQuery,
      'Die Gruppen-ID darf nicht leer sein.',
    );
  }
  final groups = database.select(
    '''
      SELECT g.group_id, g.latitude, g.longitude, g.actual_diameter_m,
             g.anchor_station_id, g.station_count, g.evse_count, g.max_power_kw,
             s.name, s.street, s.house_number, s.postal_code, s.city,
             CASE s.opening_hours_status
               WHEN 'always_open' THEN '24/7'
               WHEN 'restricted' THEN COALESCE(
                 s.opening_hours_weekdays_raw || ': ' || s.opening_hours_times_raw,
                 s.opening_hours_raw
               )
               ELSE NULL
             END AS opening_hours_raw
      FROM proximity_group g
      JOIN station s ON s.station_id = g.anchor_station_id
      WHERE g.group_id = ?
    ''',
    <Object?>[groupId],
  );
  if (groups.isEmpty) {
    return null;
  }
  final group = groups.single;
  final operators = database.select(
    '''
    SELECT COALESCE(o.display_name, os.source_name) AS display_name,
           COUNT(e.evse_id) AS evse_count
    FROM proximity_group_member gm
    JOIN station s ON s.station_id = gm.station_id
    JOIN operator_source os
      ON os.operator_source_id = s.operator_source_id
    LEFT JOIN operator o ON o.operator_id = s.operator_id
    LEFT JOIN evse e ON e.station_id = s.station_id
    WHERE gm.group_id = ?
    GROUP BY COALESCE(s.operator_id, os.operator_source_id),
             COALESCE(o.display_name, os.source_name)
    ORDER BY evse_count DESC, display_name COLLATE NOCASE
  ''',
    <Object?>[groupId],
  );
  final operatorPowerConnectors = database.select(
    '''
    SELECT COALESCE(o.display_name, os.source_name) AS display_name,
           CASE
             WHEN e.max_power_kw <= 50 THEN 0
             WHEN e.max_power_kw <= 100 THEN 1
             WHEN e.max_power_kw <= 150 THEN 2
             WHEN e.max_power_kw <= 200 THEN 3
             WHEN e.max_power_kw <= 250 THEN 4
             WHEN e.max_power_kw <= 300 THEN 5
             WHEN e.max_power_kw <= 350 THEN 6
             ELSE 7
           END AS power_band,
           c.connector_type,
           COUNT(DISTINCT e.evse_id) AS evse_count
    FROM proximity_group_member gm
    JOIN station s ON s.station_id = gm.station_id
    JOIN operator_source os
      ON os.operator_source_id = s.operator_source_id
    LEFT JOIN operator o ON o.operator_id = s.operator_id
    JOIN evse e ON e.station_id = s.station_id
    JOIN connector c ON c.evse_id = e.evse_id
    WHERE gm.group_id = ?
    GROUP BY COALESCE(s.operator_id, os.operator_source_id),
             COALESCE(o.display_name, os.source_name), power_band,
             c.connector_type
    ORDER BY display_name COLLATE NOCASE, power_band, c.connector_type
  ''',
    <Object?>[groupId],
  );
  final connectorMatrix = <String, Map<String, Map<String, Object?>>>{};
  for (final row in operatorPowerConnectors) {
    final operatorName = row['display_name']! as String;
    final powerBand = '${row['power_band']! as int}';
    final connectorType = row['connector_type']! as String;
    final operatorBands = connectorMatrix.putIfAbsent(operatorName, () => {});
    final connectorCounts = operatorBands.putIfAbsent(powerBand, () => {});
    connectorCounts[connectorType] = row['evse_count'];
  }
  final connectors = database.select(
    '''
    SELECT connector_type
    FROM group_connector
    WHERE group_id = ?
    ORDER BY evse_count DESC, connector_type
  ''',
    <Object?>[groupId],
  );
  final stationIds = database.select(
    'SELECT station_id FROM proximity_group_member WHERE group_id = ? ORDER BY station_id',
    <Object?>[groupId],
  );
  final powerBands = database.select(
    '''
    SELECT minimum_power_kw, evse_count
    FROM group_power_band
    WHERE group_id = ?
    ORDER BY minimum_power_kw
  ''',
    <Object?>[groupId],
  );
  final metadataRows = database.select('''
    SELECT key, value FROM metadata
    WHERE key IN ('dataset_version', 'created_at')
  ''');
  final metadata = <String, String>{
    for (final row in metadataRows)
      row['key']! as String: row['value']! as String,
  };
  final source = database.select('''
    SELECT name, snapshot_version
    FROM source
    ORDER BY source_id
    LIMIT 1
  ''').single;
  return <String, Object?>{
    'groupId': group['group_id'],
    'anchorStationId': group['anchor_station_id'],
    'stationIds': stationIds
        .map((row) => row['station_id']! as String)
        .toList(growable: false),
    'name': group['name'],
    'street': group['street'],
    'houseNumber': group['house_number'],
    'postalCode': group['postal_code'],
    'city': group['city'],
    'latitude': group['latitude'],
    'longitude': group['longitude'],
    'stationCount': group['station_count'],
    'evseCount': group['evse_count'],
    'maxPowerKw': group['max_power_kw'],
    'actualDiameterM': group['actual_diameter_m'],
    'operators': operators
        .map(
          (row) => <String, Object?>{
            'name': row['display_name'],
            'connectorCountsByPowerBand':
                connectorMatrix[row['display_name']! as String] ??
                <String, Map<String, Object?>>{},
          },
        )
        .toList(growable: false),
    'connectorTypes': connectors
        .map((row) => row['connector_type']! as String)
        .toList(growable: false),
    'powerBandCounts': <String, Object?>{
      for (final row in powerBands)
        '${row['minimum_power_kw']}': row['evse_count'],
    },
    'openingHours': group['opening_hours_raw'],
    'datasetVersion': metadata['dataset_version'],
    'datasetCreatedAt': metadata['created_at'],
    'sourceName': source['name'],
    'sourceVersion': source['snapshot_version'],
  };
}

Map<String, Object?>? _getGroupDetailContainingStation(
  Database database,
  Map<String, Object?> payload,
) {
  final stationId = payload['stationId'];
  final diameterM = payload['diameterM'];
  if (stationId is! String ||
      stationId.isEmpty ||
      diameterM is! int ||
      !_supportedDiameters.contains(diameterM)) {
    throw const _WorkerFailure(
      ChargingRepositoryError.invalidQuery,
      'Stations-ID und Gruppendurchmesser sind ungültig.',
    );
  }
  final groups = database.select(
    '''
      SELECT gm.group_id
      FROM proximity_group_member gm
      JOIN proximity_group g ON g.group_id = gm.group_id
      WHERE gm.station_id = COALESCE(
        (SELECT current_station_id
         FROM station_id_alias
         WHERE old_station_id = ?),
        ?
      )
        AND g.diameter_m = ?
      LIMIT 1
    ''',
    <Object?>[stationId, stationId, diameterM],
  );
  if (groups.isEmpty) return null;
  return _getGroupDetail(database, <String, Object?>{
    'groupId': groups.single['group_id'],
  });
}

void _addMultiValueFilter(
  List<String> clauses,
  List<Object?> parameters,
  List<String> values,
  String template,
) {
  if (values.isEmpty) {
    return;
  }
  final placeholders = List<String>.filled(values.length, '?').join(', ');
  clauses.add(template.replaceFirst('{placeholders}', placeholders));
  parameters.addAll(values);
}

String _ftsExpression(String searchText) {
  final words = RegExp(r'[^\s]+')
      .allMatches(searchText)
      .map((match) => match.group(0)!.replaceAll('"', ''))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) {
    throw const _WorkerFailure(
      ChargingRepositoryError.invalidQuery,
      'Der Suchtext enthält keine durchsuchbaren Zeichen.',
    );
  }
  return words.map((word) => '"$word"*').join(' AND ');
}

final class _WorkerQuery {
  const _WorkerQuery({
    required this.diameter,
    required this.minimumEvseCount,
    required this.minimumPowerKw,
    required this.operatorNames,
    required this.operatorIds,
    required this.connectorTypes,
    required this.favoriteAnchorStationIds,
    required this.amenityAnchorStationIds,
    required this.amenitiesOnly,
    required this.alwaysOpenOnly,
    required this.favoritesOnly,
    required this.searchText,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusKm,
    required this.south,
    required this.west,
    required this.north,
    required this.east,
    required this.limit,
  });

  factory _WorkerQuery.fromPayload(Map<String, Object?> payload) {
    final diameter = _intValue(payload, 'diameter');
    final minimumEvseCount = _intValue(payload, 'minimumEvseCount');
    final minimumPowerKw = _intValue(payload, 'minimumPowerKw');
    final south = _doubleValue(payload, 'south');
    final west = _doubleValue(payload, 'west');
    final north = _doubleValue(payload, 'north');
    final east = _doubleValue(payload, 'east');
    final limit = _intValue(payload, 'limit');
    final searchText = payload['searchText'];
    final centerLatitude = _nullableDoubleValue(payload, 'centerLatitude');
    final centerLongitude = _nullableDoubleValue(payload, 'centerLongitude');
    final radiusKm = _nullableDoubleValue(payload, 'radiusKm');
    final favoriteAnchorStationIds = _stringList(
      payload,
      'favoriteAnchorStationIds',
    );
    final amenityAnchorStationIds = _stringList(
      payload,
      'amenityAnchorStationIds',
    );
    final favoritesOnly = payload['favoritesOnly'];
    final amenitiesOnly = payload['amenitiesOnly'];
    final alwaysOpenOnly = payload['alwaysOpenOnly'];
    if (!_supportedDiameters.contains(diameter) ||
        minimumEvseCount < 1 ||
        !_supportedPowerBands.contains(minimumPowerKw) ||
        south < -90 ||
        north > 90 ||
        south > north ||
        west < -180 ||
        west > 180 ||
        east < -180 ||
        east > 180 ||
        limit < 1 ||
        limit > 500 ||
        (searchText != null && searchText is! String) ||
        favoritesOnly is! bool ||
        amenitiesOnly is! bool ||
        alwaysOpenOnly is! bool ||
        ((centerLatitude == null) != (centerLongitude == null)) ||
        ((centerLatitude == null) != (radiusKm == null)) ||
        (centerLatitude != null &&
            (centerLatitude < -90 || centerLatitude > 90)) ||
        (centerLongitude != null &&
            (centerLongitude < -180 || centerLongitude > 180)) ||
        (radiusKm != null && (radiusKm <= 0 || radiusKm > 200))) {
      throw const _WorkerFailure(
        ChargingRepositoryError.invalidQuery,
        'Die Kartenabfrage enthält ungültige Filterwerte.',
      );
    }
    return _WorkerQuery(
      diameter: diameter,
      minimumEvseCount: minimumEvseCount,
      minimumPowerKw: minimumPowerKw,
      operatorNames: _stringList(payload, 'operatorNames'),
      operatorIds: _stringList(payload, 'operatorIds'),
      connectorTypes: _stringList(payload, 'connectorTypes'),
      favoriteAnchorStationIds: favoriteAnchorStationIds,
      amenityAnchorStationIds: amenityAnchorStationIds,
      amenitiesOnly: amenitiesOnly,
      alwaysOpenOnly: alwaysOpenOnly,
      favoritesOnly: favoritesOnly,
      searchText: searchText as String?,
      centerLatitude: centerLatitude,
      centerLongitude: centerLongitude,
      radiusKm: radiusKm,
      south: south,
      west: west,
      north: north,
      east: east,
      limit: limit,
    );
  }

  final int diameter;
  final int minimumEvseCount;
  final int minimumPowerKw;
  final List<String> operatorNames;
  final List<String> operatorIds;
  final List<String> connectorTypes;
  final List<String> favoriteAnchorStationIds;
  final List<String> amenityAnchorStationIds;
  final bool amenitiesOnly;
  final bool alwaysOpenOnly;
  final bool favoritesOnly;
  final String? searchText;
  final double? centerLatitude;
  final double? centerLongitude;
  final double? radiusKm;
  final double south;
  final double west;
  final double north;
  final double east;
  final int limit;
}

double? _nullableDoubleValue(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value == null) return null;
  if (value is num) return value.toDouble();
  throw const _WorkerFailure(
    ChargingRepositoryError.invalidQuery,
    'Die Kartenabfrage enthält ungültige Umkreiswerte.',
  );
}

double _haversineKm(
  double firstLatitude,
  double firstLongitude,
  double secondLatitude,
  double secondLongitude,
) {
  const earthRadiusKm = 6371.0088;
  final latitudeDelta = _radians(secondLatitude - firstLatitude);
  final longitudeDelta = _radians(secondLongitude - firstLongitude);
  final firstLatitudeRadians = _radians(firstLatitude);
  final secondLatitudeRadians = _radians(secondLatitude);
  final haversine =
      math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
      math.cos(firstLatitudeRadians) *
          math.cos(secondLatitudeRadians) *
          math.sin(longitudeDelta / 2) *
          math.sin(longitudeDelta / 2);
  return earthRadiusKm * 2 * math.asin(math.sqrt(haversine.clamp(0, 1)));
}

double _radians(double degrees) => degrees * math.pi / 180;

double _rowDistanceKm(Row row, _WorkerQuery query) => _haversineKm(
  (row['latitude']! as num).toDouble(),
  (row['longitude']! as num).toDouble(),
  query.centerLatitude!,
  query.centerLongitude!,
);

int _intValue(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value is int) {
    return value;
  }
  throw const _WorkerFailure(
    ChargingRepositoryError.invalidQuery,
    'Die Kartenabfrage ist unvollständig.',
  );
}

double _doubleValue(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value is num) {
    return value.toDouble();
  }
  throw const _WorkerFailure(
    ChargingRepositoryError.invalidQuery,
    'Die Kartenabfrage ist unvollständig.',
  );
}

List<String> _stringList(Map<String, Object?> payload, String key) {
  final value = payload[key];
  if (value is List<Object?> && value.every((element) => element is String)) {
    return value.cast<String>();
  }
  throw const _WorkerFailure(
    ChargingRepositoryError.invalidQuery,
    'Die Kartenabfrage enthält eine ungültige Auswahlliste.',
  );
}

final class _WorkerFailure implements Exception {
  const _WorkerFailure(this.error, this.message);

  final ChargingRepositoryError error;
  final String message;

  Map<String, Object?> toMessage() => <String, Object?>{
    'code': error.name,
    'message': message,
  };
}
