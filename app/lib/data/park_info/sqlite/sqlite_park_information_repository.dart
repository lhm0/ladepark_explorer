import 'package:ladepark_explorer/features/park_info/domain/models/park_information.dart';
import 'package:ladepark_explorer/features/park_info/domain/repositories/park_information_repository.dart';
import 'package:sqlite3/sqlite3.dart';

final class SqliteParkInformationRepository
    implements ParkInformationRepository {
  SqliteParkInformationRepository._(this._database);

  final Database _database;

  static SqliteParkInformationRepository open(String path) {
    final database = sqlite3.open(path, mode: OpenMode.readOnly);
    if (database.userVersion != 1) {
      database.close();
      throw StateError('Nicht unterstützte park_info-Schemaversion.');
    }
    return SqliteParkInformationRepository._(database);
  }

  void close() => _database.close();

  @override
  Future<List<String>> findStationIdsWithAmenities(
    List<AmenityType> requiredAmenities,
  ) async {
    if (requiredAmenities.isEmpty) return const <String>[];
    final values = requiredAmenities.map(_amenityValue).toSet().toList();
    final placeholders = List<String>.filled(values.length, '?').join(', ');
    return _database
        .select(
          '''
            SELECT ps.station_id
            FROM park_info_station ps
            WHERE ps.park_info_id IN (
              SELECT a.park_info_id
              FROM amenity a
              WHERE a.amenity_type IN ($placeholders)
                AND a.state = 'present'
              GROUP BY a.park_info_id
              HAVING COUNT(DISTINCT a.amenity_type) = ?
            )
            ORDER BY ps.station_id
          ''',
          <Object?>[...values, values.length],
        )
        .map((row) => row['station_id']! as String)
        .toList(growable: false);
  }

  @override
  Future<ParkInformation?> findForStations(
    List<String> stationIds, {
    required bool german,
  }) async {
    if (stationIds.isEmpty) return null;
    final placeholders = List<String>.filled(stationIds.length, '?').join(', ');
    final parks = _database.select('''
      SELECT DISTINCT p.park_info_id, p.title, p.observed_on,
             ${german ? 'p.notes_de' : 'COALESCE(p.notes_en, p.notes_de)'} AS notes
      FROM park_info p JOIN park_info_station ps ON ps.park_info_id = p.park_info_id
      WHERE ps.station_id IN ($placeholders)
      ORDER BY p.observed_on DESC, p.park_info_id LIMIT 1
    ''', stationIds);
    if (parks.isEmpty) return null;
    final row = parks.single;
    final id = row['park_info_id']! as String;
    final amenities = _database.select(
      'SELECT amenity_type, state FROM amenity WHERE park_info_id = ? ORDER BY amenity_type',
      [id],
    );
    final photos = _database.select(
      '''SELECT photo_id, asset_path, author, captured_on,
                ${german ? 'alt_de' : 'COALESCE(alt_en, alt_de)'} AS alt_text
         FROM photo WHERE park_info_id = ? ORDER BY photo_id''',
      [id],
    );
    return ParkInformation(
      id: id,
      title: row['title'] as String?,
      observedOn: row['observed_on']! as String,
      notes: row['notes'] as String?,
      amenities: {
        for (final amenity in amenities)
          _amenityType(amenity['amenity_type']! as String): AmenityState.values
              .byName(amenity['state']! as String),
      },
      photos: photos
          .map(
            (photo) => ParkPhoto(
              id: photo['photo_id']! as String,
              assetPath: photo['asset_path']! as String,
              author: photo['author']! as String,
              capturedOn: photo['captured_on']! as String,
              altText: photo['alt_text']! as String,
            ),
          )
          .toList(growable: false),
    );
  }
}

AmenityType _amenityType(String value) => switch (value) {
  'coffee_machine' => AmenityType.coffeeMachine,
  'snack_machine' => AmenityType.snackMachine,
  _ => AmenityType.values.byName(value),
};

String _amenityValue(AmenityType value) => switch (value) {
  AmenityType.coffeeMachine => 'coffee_machine',
  AmenityType.snackMachine => 'snack_machine',
  _ => value.name,
};
