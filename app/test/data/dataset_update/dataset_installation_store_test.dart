import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/data/dataset_update/dataset_installation_store.dart';
import 'package:ladepark_explorer/features/dataset_update/domain/dataset_update_manifest.dart';

// Atomic installation and rollback contract for FR-DATA-002 and
// NFR-RELIABILITY-001.
void main() {
  test('verifies and activates a complete SQLite update', () async {
    final directory = await Directory.systemTemp.createTemp('dataset-update');
    addTearDown(() => directory.delete(recursive: true));
    final database = File(
      '${Directory.current.parent.path}/contracts/charging_dataset/v2/fixture.sqlite3',
    );
    final bytes = await database.readAsBytes();
    final compressed = gzip.encode(bytes);
    final manifest = _manifest(bytes, compressed);
    final store = DatasetInstallationStore(directory);

    await store.install(manifest, Stream.value(compressed), (_, _) {});

    final active = await store.activeDatabasePath();
    expect(active, isNotNull);
    expect(await File(active!).readAsBytes(), bytes);
  });

  test('keeps the previous pointer after a corrupt download', () async {
    final directory = await Directory.systemTemp.createTemp('dataset-rollback');
    addTearDown(() => directory.delete(recursive: true));
    final database = File(
      '${Directory.current.parent.path}/contracts/charging_dataset/v2/fixture.sqlite3',
    );
    final bytes = await database.readAsBytes();
    final compressed = gzip.encode(bytes);
    final store = DatasetInstallationStore(directory);
    await store.install(
      _manifest(bytes, compressed),
      Stream.value(compressed),
      (_, _) {},
    );
    final previous = await store.activeDatabasePath();

    await expectLater(
      store.install(
        _manifest(bytes, compressed),
        Stream.value(<int>[1, 2, 3]),
        (_, _) {},
      ),
      throwsFormatException,
    );
    expect(await store.activeDatabasePath(), previous);
  });
}

DatasetUpdateManifest _manifest(List<int> plain, List<int> compressed) =>
    DatasetUpdateManifest(
      datasetId: 'ladepark-explorer-de',
      datasetVersion: '2026.07.0-contract',
      schemaVersion: 2,
      createdAt: DateTime.utc(2026, 7, 26),
      artifact: DatasetArtifact(
        url: Uri.parse('https://example.test/charging.sqlite3.gz'),
        sizeBytes: compressed.length,
        sha256: sha256.convert(compressed).toString(),
        uncompressedSizeBytes: plain.length,
        uncompressedSha256: sha256.convert(plain).toString(),
      ),
    );
