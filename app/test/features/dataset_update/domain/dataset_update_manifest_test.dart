import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/dataset_update/domain/dataset_update_manifest.dart';

// Manifest and version contract for FR-DATA-002.
void main() {
  test('parses a supported manifest and compares numeric versions', () {
    final manifest = DatasetUpdateManifest.parse(
      jsonEncode({
        'manifest_format_version': 1,
        'dataset_id': 'ladepark-explorer-de',
        'dataset_version': '2026.10.0',
        'schema_version': 2,
        'created_at': '2026-10-01T00:00:00Z',
        'region': 'DE',
        'artifacts': [
          {
            'type': 'charging_sqlite_gzip',
            'url': 'https://example.test/charging.sqlite3.gz',
            'size_bytes': 100,
            'sha256': 'a' * 64,
            'uncompressed_size_bytes': 200,
            'uncompressed_sha256': 'b' * 64,
          },
        ],
      }),
    );

    expect(manifest.isNewerThan('2026.09.9'), isTrue);
    expect(manifest.isNewerThan('2026.10.0'), isFalse);
    expect(manifest.artifact.sizeBytes, 100);
  });

  test('rejects an insecure artifact URL', () {
    expect(
      () => DatasetUpdateManifest.parse(
        jsonEncode({
          'manifest_format_version': 1,
          'dataset_id': 'ladepark-explorer-de',
          'dataset_version': '2026.10.0',
          'schema_version': 2,
          'created_at': '2026-10-01T00:00:00Z',
          'region': 'DE',
          'artifacts': [
            {
              'type': 'charging_sqlite_gzip',
              'url': 'http://example.test/charging.sqlite3.gz',
              'size_bytes': 100,
              'sha256': 'a' * 64,
              'uncompressed_size_bytes': 200,
              'uncompressed_sha256': 'b' * 64,
            },
          ],
        }),
      ),
      throwsFormatException,
    );
  });
}
