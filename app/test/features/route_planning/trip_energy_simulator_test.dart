import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/domain/energy_model.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_segment.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_stop.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/vehicle_profile.dart';
import 'package:ladepark_explorer/features/route_planning/domain/trip_energy_simulator.dart';

// Range prediction for FR-ROUTE-006.
void main() {
  // A straight 400 km path split into 4 equal 100 km segments.
  final path = <RouteSegment>[
    for (var i = 0; i < 4; i++)
      RouteSegment(
        start: GeoCoordinate(latitude: 52.0 - i, longitude: 13.0),
        end: GeoCoordinate(latitude: 52.0 - i - 1, longitude: 13.0),
        distanceKm: 100,
        travelTime: const Duration(hours: 1),
      ),
  ];

  // 60 kWh usable, 15 kWh/100 km -> 15 kWh (25 % of 60) per 100 km segment.
  const vehicle = VehicleProfile(
    usableBatteryKwh: 60,
    consumptionKwhPer100Km: 15,
    maxChargePowerKw: 150,
    reserveSocPercent: 10,
    targetArrivalSocPercent: 80,
  );

  const simulator = TripEnergySimulator();

  test('state of charge falls by the consumed share per segment', () {
    final profile = simulator.simulate(
      path: path,
      stops: const <RouteStop>[],
      vehicle: vehicle,
      startSocPercent: 100,
      model: const ConstantRateEnergyModel(),
    );

    expect(profile.socPercentByPoint, hasLength(5));
    expect(profile.socPercentByPoint.first, 100);
    expect(profile.socPercentByPoint[1], closeTo(75, 0.001));
    expect(profile.socPercentByPoint.last, closeTo(0, 0.001));
    expect(profile.cumulativeKmByPoint.last, 400);
  });

  test('flags the deficit where the reserve is crossed without a stop', () {
    final profile = simulator.simulate(
      path: path,
      stops: const <RouteStop>[],
      vehicle: vehicle,
      startSocPercent: 100,
    );
    // 100 -> 75 -> 50 -> 25 -> 0; below 10 % after the 4th segment.
    expect(profile.reachesReserve, isFalse);
    expect(profile.deficitKm, closeTo(400, 0.001));
  });

  test('a charging stop lifts the state of charge back to the target', () {
    final profile = simulator.simulate(
      path: path,
      stops: <RouteStop>[
        RouteStop(
          groupId: 'mid',
          coordinate: const GeoCoordinate(latitude: 50, longitude: 13),
          positionKm: 200,
        ),
      ],
      vehicle: vehicle,
      startSocPercent: 100,
    );
    // 100 -> 75 -> 50, stop -> 80, -> 55 -> 30. Never below reserve.
    expect(profile.socPercentByPoint[2], closeTo(50, 0.001));
    expect(profile.socPercentByPoint[3], closeTo(55, 0.001));
    expect(profile.socPercentByPoint.last, closeTo(30, 0.001));
    expect(profile.reachesReserve, isTrue);

    // The stop trace exposes the reset for the UI diagnostics.
    expect(profile.stopSocs, hasLength(1));
    expect(profile.stopSocs.single.arrivalSocPercent, closeTo(50, 0.001));
    expect(profile.stopSocs.single.departureSocPercent, closeTo(80, 0.001));
    expect(profile.chargeTargetSocPercent, 80);
  });

  test('an explicit charge target replaces the profile target at a stop', () {
    final profile = simulator.simulate(
      path: path,
      stops: <RouteStop>[
        RouteStop(
          groupId: 'mid',
          coordinate: const GeoCoordinate(latitude: 50, longitude: 13),
          positionKm: 200,
        ),
      ],
      vehicle: vehicle,
      startSocPercent: 100,
      chargeTargetSocPercent: 60,
    );
    // 100 -> 75 -> 50, stop -> 60, -> 35 -> 10.
    expect(profile.stopSocs.single.departureSocPercent, closeTo(60, 0.001));
    expect(profile.socPercentByPoint[3], closeTo(35, 0.001));
    expect(profile.chargeTargetSocPercent, 60);
  });

  test('socAtKm interpolates the charge between polyline points', () {
    final profile = simulator.simulate(
      path: path,
      stops: const <RouteStop>[],
      vehicle: vehicle,
      startSocPercent: 100,
    );
    // 100 at km 0, 75 at km 100 -> 87.5 at km 50.
    expect(profile.socAtKm(50), closeTo(87.5, 0.001));
    expect(profile.socAtKm(0), 100);
    expect(profile.socAtKm(1000), closeTo(0, 0.001));
  });
}
