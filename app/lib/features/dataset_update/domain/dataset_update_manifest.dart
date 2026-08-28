import 'dart:convert';

final class DatasetArtifact {
  const DatasetArtifact({
    required this.url,
    required this.sizeBytes,
    required this.sha256,
    required this.uncompressedSizeBytes,
    required this.uncompressedSha256,
  });

  final Uri url;
  final int sizeBytes;
  final String sha256;
  final int uncompressedSizeBytes;
  final String uncompressedSha256;
}

final class DatasetUpdateManifest {
  const DatasetUpdateManifest({
    required this.datasetId,
    required this.datasetVersion,
    required this.schemaVersion,
    required this.createdAt,
    required this.artifact,
  });

  final String datasetId;
  final String datasetVersion;
  final int schemaVersion;
  final DateTime createdAt;
  final DatasetArtifact artifact;

  static DatasetUpdateManifest parse(String source) {
    final root = jsonDecode(source) as Map<String, Object?>;
    if (root['manifest_format_version'] != 1 ||
        root['dataset_id'] != 'ladepark-explorer-de' ||
        root['region'] != 'DE') {
      throw const FormatException('Unsupported dataset manifest.');
    }
    final artifacts = root['artifacts'] as List<Object?>;
    final artifact = artifacts.cast<Map<String, Object?>>().singleWhere(
      (value) => value['type'] == 'charging_sqlite_gzip',
    );
    final result = DatasetUpdateManifest(
      datasetId: root['dataset_id']! as String,
      datasetVersion: root['dataset_version']! as String,
      schemaVersion: root['schema_version']! as int,
      createdAt: DateTime.parse(root['created_at']! as String).toUtc(),
      artifact: DatasetArtifact(
        url: Uri.parse(artifact['url']! as String),
        sizeBytes: artifact['size_bytes']! as int,
        sha256: artifact['sha256']! as String,
        uncompressedSizeBytes: artifact['uncompressed_size_bytes']! as int,
        uncompressedSha256: artifact['uncompressed_sha256']! as String,
      ),
    );
    if (result.schemaVersion != 2 ||
        !result.artifact.url.isScheme('https') ||
        result.artifact.sizeBytes <= 0 ||
        result.artifact.uncompressedSizeBytes <= 0 ||
        !_isSha256(result.artifact.sha256) ||
        !_isSha256(result.artifact.uncompressedSha256) ||
        !_isVersion(result.datasetVersion)) {
      throw const FormatException('Invalid dataset manifest.');
    }
    return result;
  }

  bool isNewerThan(String installedVersion) =>
      _compareVersions(datasetVersion, installedVersion) > 0;
}

bool _isSha256(String value) => RegExp(r'^[0-9a-f]{64}$').hasMatch(value);
bool _isVersion(String value) => RegExp(r'^\d{4}\.\d{2}\.\d+$').hasMatch(value);

int _compareVersions(String left, String right) {
  final leftParts = left.split('.').map(int.parse).toList();
  final rightMatch = RegExp(r'^(\d+)\.(\d+)\.(\d+)').firstMatch(right);
  if (rightMatch == null) return 1;
  final rightParts = [
    int.parse(rightMatch.group(1)!),
    int.parse(rightMatch.group(2)!),
    int.parse(rightMatch.group(3)!),
  ];
  for (var index = 0; index < 3; index++) {
    final comparison = leftParts[index].compareTo(rightParts[index]);
    if (comparison != 0) return comparison;
  }
  return 0;
}
