import 'package:ladepark_explorer/features/route_planning/domain/models/vehicle_profile.dart';

/// Local, account-free storage of the single vehicle profile (FR-ROUTE-005,
/// ADR-0021). The SQLite implementation shares the versioned settings
/// database.
abstract interface class VehicleProfileRepository {
  /// The stored profile, or null if none has been saved yet.
  Future<VehicleProfile?> loadVehicleProfile();

  Future<void> saveVehicleProfile(VehicleProfile profile);

  Future<void> clearVehicleProfile();
}
