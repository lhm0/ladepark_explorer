import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

final class BundledChargingDatabase {
  const BundledChargingDatabase({
    this.fallbackAssetPath =
        'assets/datasets/charging-2026.07.0-contract.sqlite3',
    this.fileName = 'charging-2026.07.0-contract.sqlite3',
  });

  static const preferredAssetPath = 'assets/generated/charging-de.sqlite3';
  static const _platformChannel = MethodChannel('de.ladeparkexplorer/platform');

  final String fallbackAssetPath;
  final String fileName;

  Future<String> resolve() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final path = await _platformChannel
          .invokeMethod<String>('resolveDatasetPath', const <String, Object?>{
            'preferred': preferredAssetPath,
            'fallback': 'assets/datasets/charging-2026.07.0-contract.sqlite3',
          });
      if (path != null) {
        return path;
      }
    }
    return _materializeFallback();
  }

  Future<String> _materializeFallback() async {
    final asset = await rootBundle.load(fallbackAssetPath);
    final directory = Directory(
      '${Directory.systemTemp.path}/ladepark_explorer',
    );
    await directory.create(recursive: true);
    final database = File('${directory.path}/$fileName');
    if (!await database.exists() ||
        await database.length() != asset.lengthInBytes) {
      await database.writeAsBytes(
        asset.buffer.asUint8List(asset.offsetInBytes, asset.lengthInBytes),
        flush: true,
      );
    }
    return database.path;
  }
}
