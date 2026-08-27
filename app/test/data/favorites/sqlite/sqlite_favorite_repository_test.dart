import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/data/favorites/sqlite/sqlite_favorite_repository.dart';
import 'package:ladepark_explorer/features/favorites/domain/models/favorite.dart';
import 'package:sqlite3/sqlite3.dart';

// Persistence and isolation tests for FR-FAV-001.
void main() {
  test('persists, updates, lists, and removes favorites', () async {
    final directory = Directory.systemTemp.createTempSync('ladepark-fav-test-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/user.sqlite3';
    var repository = await SqliteFavoriteRepository.open(path);

    await repository.save(_favorite(name: 'Erster Name'));
    await repository.close();
    repository = await SqliteFavoriteRepository.open(path);
    addTearDown(repository.close);

    var favorites = await repository.getAll();
    expect(favorites, hasLength(1));
    expect(favorites.single.displayName, 'Erster Name');
    expect(favorites.single.savedAt, DateTime.utc(2026, 8, 26));

    await repository.save(_favorite(name: 'Neuer Name'));
    favorites = await repository.getAll();
    expect(favorites, hasLength(1));
    expect(favorites.single.displayName, 'Neuer Name');

    await repository.remove('station-1');
    expect(await repository.getAll(), isEmpty);
  });

  test('rejects an unsupported user database schema', () async {
    final directory = Directory.systemTemp.createTempSync('ladepark-fav-test-');
    addTearDown(() => directory.deleteSync(recursive: true));
    final path = '${directory.path}/user.sqlite3';
    final database = sqlite3.open(path);
    database.userVersion = 2;
    database.close();

    await expectLater(
      SqliteFavoriteRepository.open(path),
      throwsA(isA<StateError>()),
    );
  });
}

Favorite _favorite({required String name}) => Favorite(
  anchorStationId: 'station-1',
  savedDiameterM: 50,
  savedAt: DateTime.utc(2026, 8, 26),
  displayName: name,
  street: 'Testweg',
  houseNumber: '1',
  postalCode: '10115',
  city: 'Berlin',
  latitude: 52.52,
  longitude: 13.405,
);
