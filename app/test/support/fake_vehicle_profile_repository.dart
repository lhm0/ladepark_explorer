import 'package:ladepark_explorer/features/route_planning/domain/models/vehicle_profile.dart';
import 'package:ladepark_explorer/features/route_planning/domain/repositories/vehicle_profile_repository.dart';

class FakeVehicleProfileRepository implements VehicleProfileRepository {
  FakeVehicleProfileRepository([this._stored]);

  VehicleProfile? _stored;

  @override
  Future<VehicleProfile?> loadVehicleProfile() async => _stored;

  @override
  Future<void> saveVehicleProfile(VehicleProfile profile) async {
    _stored = profile;
  }

  @override
  Future<void> clearVehicleProfile() async {
    _stored = null;
  }
}
