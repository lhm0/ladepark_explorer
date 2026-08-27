import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

// Contract availability for FR-DATA-001, NFR-DATA-001, and NFR-PORT-001.
void main() {
  test('shared charging dataset contract is available to the app', () {
    final database = File('../contracts/charging_dataset/v2/fixture.sqlite3');
    final expectations = File(
      '../contracts/charging_dataset/v2/expectations.json',
    );
    final bundledDatabase = File(
      'assets/datasets/charging-2026.07.0-contract.sqlite3',
    );

    expect(database.existsSync(), isTrue);
    expect(
      database.readAsBytesSync().take(16).toList(),
      utf8.encode('SQLite format 3\u0000'),
    );
    expect(expectations.existsSync(), isTrue);
    expect(bundledDatabase.readAsBytesSync(), database.readAsBytesSync());
    final contract = jsonDecode(expectations.readAsStringSync());
    expect((contract as Map<String, dynamic>)['schema_version'], 2);

    final sqliteDatabase = sqlite3.open(database.path, mode: OpenMode.readOnly);
    addTearDown(sqliteDatabase.close);
    expect(sqliteDatabase.userVersion, 2);
    expect(
      sqliteDatabase
          .select('SELECT COUNT(*) AS count FROM station')
          .single['count'],
      2,
    );
  });
}
