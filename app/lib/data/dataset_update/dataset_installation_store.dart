import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:ladepark_explorer/features/dataset_update/domain/dataset_update_manifest.dart';
import 'package:sqlite3/sqlite3.dart';

final class DatasetInstallationStore {
  const DatasetInstallationStore(this.rootDirectory);

  final Directory rootDirectory;

  File get _activePointer => File('${rootDirectory.path}/active.json');

  Future<String?> activeDatabasePath() async {
    try {
      final version = await _activeVersion();
      if (version == null) return null;
      final file = File(
        '${rootDirectory.path}/versions/$version/charging.sqlite3',
      );
      return await file.exists() ? file.path : null;
    } on Object {
      return null;
    }
  }

  Future<void> install(
    DatasetUpdateManifest manifest,
    Stream<List<int>> compressedBytes,
    void Function(int received, int total) onProgress,
  ) async {
    final previousVersion = await _activeVersion();
    final staging = Directory('${rootDirectory.path}/staging');
    await staging.create(recursive: true);
    final archive = File('${staging.path}/charging.sqlite3.gz.part');
    final archiveSink = archive.openWrite();
    var received = 0;
    await for (final chunk in compressedBytes) {
      received += chunk.length;
      if (received > manifest.artifact.sizeBytes) {
        await archiveSink.close();
        await archive.delete();
        throw const FormatException('Dataset download exceeds manifest size.');
      }
      archiveSink.add(chunk);
      onProgress(received, manifest.artifact.sizeBytes);
    }
    await archiveSink.close();
    await _verifyFile(
      archive,
      manifest.artifact.sizeBytes,
      manifest.artifact.sha256,
    );

    final candidate = File('${staging.path}/charging.sqlite3.candidate');
    await archive
        .openRead()
        .transform(gzip.decoder)
        .pipe(candidate.openWrite());
    await _verifyFile(
      candidate,
      manifest.artifact.uncompressedSizeBytes,
      manifest.artifact.uncompressedSha256,
    );
    await Isolate.run(() => _validateCandidate(candidate.path, manifest));

    final versionDirectory = Directory(
      '${rootDirectory.path}/versions/${manifest.datasetVersion}',
    );
    await versionDirectory.create(recursive: true);
    final installed = File('${versionDirectory.path}/charging.sqlite3');
    if (await installed.exists()) await installed.delete();
    await candidate.rename(installed.path);
    final pointerCandidate = File('${rootDirectory.path}/active.json.tmp');
    await pointerCandidate.writeAsString(
      jsonEncode({
        'dataset_id': manifest.datasetId,
        'dataset_version': manifest.datasetVersion,
      }),
      flush: true,
    );
    await pointerCandidate.rename(_activePointer.path);
    await archive.delete();
    await _removeObsoleteVersions({manifest.datasetVersion, ?previousVersion});
  }

  Future<String?> _activeVersion() async {
    try {
      final pointer =
          jsonDecode(await _activePointer.readAsString())
              as Map<String, Object?>;
      return pointer['dataset_version']! as String;
    } on Object {
      return null;
    }
  }

  Future<void> _removeObsoleteVersions(Set<String> retained) async {
    final versions = Directory('${rootDirectory.path}/versions');
    if (!await versions.exists()) return;
    await for (final entry in versions.list()) {
      if (entry is! Directory) continue;
      final segments = entry.uri.pathSegments;
      final version = segments[segments.length - 2];
      if (!retained.contains(version)) await entry.delete(recursive: true);
    }
  }
}

Future<void> _verifyFile(
  File file,
  int expectedSize,
  String expectedHash,
) async {
  if (await file.length() != expectedSize) {
    throw const FormatException('Dataset file size mismatch.');
  }
  final digest = await sha256.bind(file.openRead()).first;
  if (digest.toString() != expectedHash) {
    throw const FormatException('Dataset checksum mismatch.');
  }
}

void _validateCandidate(String path, DatasetUpdateManifest manifest) {
  final database = sqlite3.open(path, mode: OpenMode.readOnly);
  try {
    if (database.userVersion != manifest.schemaVersion ||
        database.select('PRAGMA integrity_check').single.values.single !=
            'ok') {
      throw const FormatException('Dataset SQLite validation failed.');
    }
    final metadata = {
      for (final row in database.select('SELECT key, value FROM metadata'))
        row['key']! as String: row['value']! as String,
    };
    if (metadata['dataset_id'] != manifest.datasetId ||
        metadata['dataset_version'] != manifest.datasetVersion ||
        metadata['schema_version'] != '${manifest.schemaVersion}' ||
        metadata['region'] != 'DE') {
      throw const FormatException('Dataset metadata mismatch.');
    }
  } finally {
    database.close();
  }
}
