import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/route_planning/application/vehicle_profile_providers.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/vehicle_profile.dart';

import '../../support/fake_vehicle_profile_repository.dart';

// State integration for FR-ROUTE-005.
void main() {
  const profile = VehicleProfile(
    usableBatteryKwh: 58,
    consumptionKwhPer100Km: 17,
    maxChargePowerKw: 150,
  );

  test('loads null, then saves and clears the profile', () async {
    final repository = FakeVehicleProfileRepository();
    final container = ProviderContainer(
      overrides: [
        vehicleProfileRepositoryProvider.overrideWith(
          (ref) async => repository,
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(vehicleProfileControllerProvider.future),
      isNull,
    );

    await container
        .read(vehicleProfileControllerProvider.notifier)
        .save(profile);
    expect(container.read(vehicleProfileControllerProvider).value, profile);
    expect(await repository.loadVehicleProfile(), profile);

    await container.read(vehicleProfileControllerProvider.notifier).clear();
    expect(container.read(vehicleProfileControllerProvider).value, isNull);
    expect(await repository.loadVehicleProfile(), isNull);
  });

  test('starts from a stored profile', () async {
    final container = ProviderContainer(
      overrides: [
        vehicleProfileRepositoryProvider.overrideWith(
          (ref) async => FakeVehicleProfileRepository(profile),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(
      await container.read(vehicleProfileControllerProvider.future),
      profile,
    );
  });
}
