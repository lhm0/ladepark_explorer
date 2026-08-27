import 'dart:io';

import 'package:ladepark_explorer/features/settings/domain/app_settings.dart';
import 'package:ladepark_explorer/features/settings/domain/settings_repository.dart';
import 'package:sqlite3/sqlite3.dart';

final class SqliteSettingsRepository implements SettingsRepository {
  SqliteSettingsRepository._(this._database);

  final Database _database;
  bool _closed = false;

  static Future<SqliteSettingsRepository> open(String databasePath) async {
    final file = File(databasePath);
    await file.parent.create(recursive: true);
    final database = sqlite3.open(databasePath);
    database.execute('PRAGMA journal_mode = WAL');
    if (database.userVersion == 0) {
      database.execute('''
        CREATE TABLE app_setting (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        ) WITHOUT ROWID
      ''');
      database.userVersion = 1;
    }
    if (database.userVersion != 1) {
      database.close();
      throw StateError('Unsupported settings database version.');
    }
    return SqliteSettingsRepository._(database);
  }

  void _ensureOpen() {
    if (_closed) throw StateError('Settings repository is closed.');
  }

  @override
  Future<AppSettings> load() async {
    _ensureOpen();
    final values = <String, String>{
      for (final row in _database.select('SELECT key, value FROM app_setting'))
        row['key']! as String: row['value']! as String,
    };
    return AppSettings(
      language: AppLanguage.values.firstWhere(
        (value) => value.name == values['language'],
        orElse: () => AppLanguage.system,
      ),
      navigationPreference: NavigationPreference.values.firstWhere(
        (value) => value.name == values['navigation_preference'],
        orElse: () => NavigationPreference.askEveryTime,
      ),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    _ensureOpen();
    final statement = _database.prepare('''
      INSERT INTO app_setting (key, value) VALUES (?, ?)
      ON CONFLICT(key) DO UPDATE SET value = excluded.value
    ''');
    try {
      statement.execute(<Object?>['language', settings.language.name]);
      statement.execute(<Object?>[
        'navigation_preference',
        settings.navigationPreference.name,
      ]);
    } finally {
      statement.close();
    }
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _database.close();
  }
}
