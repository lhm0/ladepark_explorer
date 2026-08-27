import 'dart:io';

import 'package:ladepark_explorer/features/favorites/domain/models/favorite.dart';
import 'package:ladepark_explorer/features/favorites/domain/repositories/favorite_repository.dart';
import 'package:sqlite3/sqlite3.dart';

final class SqliteFavoriteRepository implements FavoriteRepository {
  SqliteFavoriteRepository._(this._database);

  final Database _database;
  bool _closed = false;

  static Future<SqliteFavoriteRepository> open(String databasePath) async {
    final file = File(databasePath);
    await file.parent.create(recursive: true);
    final database = sqlite3.open(databasePath);
    database.execute('PRAGMA journal_mode = WAL');
    database.execute('PRAGMA foreign_keys = ON');
    if (database.userVersion == 0) {
      database.execute('''
        CREATE TABLE favorite (
          anchor_station_id TEXT PRIMARY KEY,
          saved_diameter_m INTEGER NOT NULL,
          saved_at TEXT NOT NULL,
          display_name TEXT,
          street TEXT,
          house_number TEXT,
          postal_code TEXT,
          city TEXT,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL
        ) WITHOUT ROWID
      ''');
      database.userVersion = 1;
    }
    if (database.userVersion != 1) {
      database.close();
      throw StateError('Nicht unterstützte Benutzerdatenbank-Version.');
    }
    return SqliteFavoriteRepository._(database);
  }

  void _ensureOpen() {
    if (_closed) throw StateError('Favoritenspeicher ist geschlossen.');
  }

  @override
  Future<List<Favorite>> getAll() async {
    _ensureOpen();
    return _database
        .select('SELECT * FROM favorite ORDER BY saved_at DESC')
        .map(_favoriteFromRow)
        .toList(growable: false);
  }

  @override
  Future<void> save(Favorite favorite) async {
    _ensureOpen();
    _database.execute(
      '''
        INSERT INTO favorite (
          anchor_station_id, saved_diameter_m, saved_at, display_name,
          street, house_number, postal_code, city, latitude, longitude
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON CONFLICT(anchor_station_id) DO UPDATE SET
          saved_diameter_m = excluded.saved_diameter_m,
          saved_at = excluded.saved_at,
          display_name = excluded.display_name,
          street = excluded.street,
          house_number = excluded.house_number,
          postal_code = excluded.postal_code,
          city = excluded.city,
          latitude = excluded.latitude,
          longitude = excluded.longitude
      ''',
      <Object?>[
        favorite.anchorStationId,
        favorite.savedDiameterM,
        favorite.savedAt.toUtc().toIso8601String(),
        favorite.displayName,
        favorite.street,
        favorite.houseNumber,
        favorite.postalCode,
        favorite.city,
        favorite.latitude,
        favorite.longitude,
      ],
    );
  }

  @override
  Future<void> remove(String anchorStationId) async {
    _ensureOpen();
    _database.execute(
      'DELETE FROM favorite WHERE anchor_station_id = ?',
      <Object?>[anchorStationId],
    );
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _database.close();
  }
}

Favorite _favoriteFromRow(Row row) => Favorite(
  anchorStationId: row['anchor_station_id']! as String,
  savedDiameterM: row['saved_diameter_m']! as int,
  savedAt: DateTime.parse(row['saved_at']! as String),
  displayName: row['display_name'] as String?,
  street: row['street'] as String?,
  houseNumber: row['house_number'] as String?,
  postalCode: row['postal_code'] as String?,
  city: row['city'] as String?,
  latitude: (row['latitude']! as num).toDouble(),
  longitude: (row['longitude']! as num).toDouble(),
);
