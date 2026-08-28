import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/data/charging/bundled_charging_database.dart';
import 'package:ladepark_explorer/data/dataset_update/dataset_installation_store.dart';
import 'package:ladepark_explorer/data/dataset_update/http_dataset_update_source.dart';
import 'package:ladepark_explorer/features/dataset_update/domain/dataset_update_manifest.dart';
import 'package:ladepark_explorer/features/explorer/application/explorer_providers.dart';
import 'package:ladepark_explorer/features/settings/application/settings_providers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

enum DatasetUpdatePhase {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  installed,
  failed,
}

final class DatasetUpdateState {
  const DatasetUpdateState({
    this.phase = DatasetUpdatePhase.idle,
    this.manifest,
    this.progress = 0,
  });

  final DatasetUpdatePhase phase;
  final DatasetUpdateManifest? manifest;
  final double progress;
}

final datasetUpdateSourceProvider = Provider<DatasetUpdateSource>(
  (ref) => HttpDatasetUpdateSource(),
);

final datasetInstallationStoreProvider =
    FutureProvider<DatasetInstallationStore>((ref) async {
      final support = await getApplicationSupportDirectory();
      return DatasetInstallationStore(
        Directory('${support.path}/charging-datasets'),
      );
    });

final datasetUpdateControllerProvider =
    AsyncNotifierProvider<DatasetUpdateController, DatasetUpdateState>(
      DatasetUpdateController.new,
    );

final class DatasetUpdateController extends AsyncNotifier<DatasetUpdateState> {
  bool _startedAutomatically = false;

  @override
  Future<DatasetUpdateState> build() async {
    final settings = await ref.watch(settingsControllerProvider.future);
    if (settings.automaticDatasetChecks && !_startedAutomatically) {
      _startedAutomatically = true;
      unawaited(Future<void>.microtask(check));
    }
    return const DatasetUpdateState();
  }

  Future<void> check() async {
    if (state.value?.phase == DatasetUpdatePhase.checking ||
        state.value?.phase == DatasetUpdatePhase.downloading) {
      return;
    }
    state = const AsyncData(
      DatasetUpdateState(phase: DatasetUpdatePhase.checking),
    );
    try {
      final manifest = DatasetUpdateManifest.parse(
        await ref.read(datasetUpdateSourceProvider).loadManifest(),
      );
      final currentPath = await const BundledChargingDatabase().resolve();
      final currentVersion = await _readDatasetVersion(currentPath);
      state = AsyncData(
        DatasetUpdateState(
          phase: manifest.isNewerThan(currentVersion)
              ? DatasetUpdatePhase.available
              : DatasetUpdatePhase.upToDate,
          manifest: manifest,
        ),
      );
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<void> install() async {
    final manifest = state.requireValue.manifest;
    if (manifest == null) return;
    state = AsyncData(
      DatasetUpdateState(
        phase: DatasetUpdatePhase.downloading,
        manifest: manifest,
      ),
    );
    try {
      final source = ref.read(datasetUpdateSourceProvider);
      final store = await ref.read(datasetInstallationStoreProvider.future);
      await store.install(
        manifest,
        await source.download(manifest.artifact.url),
        (received, total) {
          state = AsyncData(
            DatasetUpdateState(
              phase: DatasetUpdatePhase.downloading,
              manifest: manifest,
              progress: received / total,
            ),
          );
        },
      );
      ref.invalidate(chargingRepositoryProvider);
      ref.invalidate(explorerMapControllerProvider);
      state = AsyncData(
        DatasetUpdateState(
          phase: DatasetUpdatePhase.installed,
          manifest: manifest,
          progress: 1,
        ),
      );
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }
}

Future<String> _readDatasetVersion(String path) async {
  final database = sqlite3.open(path, mode: OpenMode.readOnly);
  try {
    return database
            .select("SELECT value FROM metadata WHERE key = 'dataset_version'")
            .single['value']!
        as String;
  } finally {
    database.close();
  }
}
