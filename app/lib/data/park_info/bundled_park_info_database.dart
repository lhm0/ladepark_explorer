import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

final class BundledParkInfoDatabase {
  const BundledParkInfoDatabase();

  static const preferredAsset = 'assets/generated/park-info.sqlite3';
  static const fallbackAsset = 'assets/datasets/park-info-contract.sqlite3';

  Future<String> resolve() async {
    ByteData data;
    var name = 'park-info.sqlite3';
    try {
      data = await rootBundle.load(preferredAsset);
    } on FlutterError {
      data = await rootBundle.load(fallbackAsset);
      name = 'park-info-contract.sqlite3';
    }
    final directory = Directory(
      '${Directory.systemTemp.path}/ladepark_explorer',
    );
    await directory.create(recursive: true);
    final file = File('${directory.path}/$name');
    // The editorial database is small. Always replacing it prevents a new
    // bundle artifact with the same byte length from leaving stale content in
    // the temporary directory after an app update.
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    return file.path;
  }
}
