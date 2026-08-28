import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/vehicle_profile.dart';
import 'package:ladepark_explorer/features/route_planning/domain/repositories/vehicle_profile_repository.dart';
import 'package:ladepark_explorer/features/settings/application/settings_providers.dart';

/// The vehicle profile is stored in the shared settings database (ADR-0021),
/// so it reuses the settings repository instance.
final vehicleProfileRepositoryProvider =
    FutureProvider<VehicleProfileRepository>(
      (ref) async =>
          await ref.watch(settingsRepositoryProvider.future)
              as VehicleProfileRepository,
    );

final vehicleProfileControllerProvider =
    AsyncNotifierProvider<VehicleProfileController, VehicleProfile?>(
      VehicleProfileController.new,
    );

/// Loads, saves and clears the single local vehicle profile (FR-ROUTE-005).
final class VehicleProfileController extends AsyncNotifier<VehicleProfile?> {
  @override
  Future<VehicleProfile?> build() async => (await ref.watch(
    vehicleProfileRepositoryProvider.future,
  )).loadVehicleProfile();

  Future<void> save(VehicleProfile profile) async {
    await (await ref.read(
      vehicleProfileRepositoryProvider.future,
    )).saveVehicleProfile(profile);
    state = AsyncData(profile);
  }

  Future<void> clear() async {
    await (await ref.read(
      vehicleProfileRepositoryProvider.future,
    )).clearVehicleProfile();
    state = const AsyncData(null);
  }
}
