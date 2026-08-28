import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/domain/energy_model.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_segment.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/vehicle_profile.dart';

// Consumption model for FR-ROUTE-006 / ADR-0020.
void main() {
  test(
    'ConstantRateEnergyModel uses distance times consumption per 100 km',
    () {
      final path = <RouteSegment>[
        RouteSegment(
          start: const GeoCoordinate(latitude: 52, longitude: 13),
          end: const GeoCoordinate(latitude: 51, longitude: 13),
          distanceKm: 50,
          travelTime: const Duration(minutes: 30),
        ),
        RouteSegment(
          start: const GeoCoordinate(latitude: 51, longitude: 13),
          end: const GeoCoordinate(latitude: 50, longitude: 13),
          distanceKm: 120,
          travelTime: const Duration(minutes: 72),
        ),
      ];
      const vehicle = VehicleProfile(
        usableBatteryKwh: 60,
        consumptionKwhPer100Km: 18,
        maxChargePowerKw: 150,
      );

      final energies = const ConstantRateEnergyModel().estimate(
        path,
        vehicle,
        const TripContext(),
      );

      expect(energies, hasLength(2));
      expect(energies[0].energyKwh, closeTo(50 / 100 * 18, 0.001));
      expect(energies[1].energyKwh, closeTo(120 / 100 * 18, 0.001));
    },
  );
}
