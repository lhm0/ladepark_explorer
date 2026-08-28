import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_bounds.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/application/energy_providers.dart';
import 'package:ladepark_explorer/features/route_planning/application/route_planning_providers.dart';
import 'package:ladepark_explorer/features/route_planning/application/vehicle_profile_providers.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_leg.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_option.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_request.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_waypoint.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/vehicle_profile.dart';

import '../../support/fake_route_planning_service.dart';
import '../../support/fake_vehicle_profile_repository.dart';

// tripEnergyProfileProvider recomputes when a stop is added (FR-ROUTE-006).
void main() {
  // ~6 points spread north to south over roughly 500 km.
  final polyline = <GeoCoordinate>[
    for (var i = 0; i <= 5; i++)
      GeoCoordinate(latitude: 52.5 - i * 0.9, longitude: 13.0),
  ];

  RouteOption option() => RouteOption(
    totalDistanceKm: 500,
    totalTravelTime: const Duration(hours: 5),
    boundingBox: const GeoBounds(south: 47, west: 12, north: 53, east: 14),
    polyline: polyline,
    legs: const <RouteLeg>[],
  );

  const request = RouteRequest(
    origin: RouteWaypoint(
      coordinate: GeoCoordinate(latitude: 52.5, longitude: 13.0),
    ),
    destination: RouteWaypoint(
      coordinate: GeoCoordinate(latitude: 48.0, longitude: 13.0),
    ),
  );

  // Small battery, high consumption -> the charge collapses without a stop.
  const profile = VehicleProfile(
    usableBatteryKwh: 40,
    consumptionKwhPer100Km: 25,
    maxChargePowerKw: 100,
    reserveSocPercent: 10,
    targetArrivalSocPercent: 80,
    defaultStartSocPercent: 90,
  );

  test(
    'a charging stop lifts the state of charge from that point on',
    () async {
      final container = ProviderContainer(
        overrides: [
          routePlanningServiceProvider.overrideWithValue(
            FakeRoutePlanningService(options: <RouteOption>[option()]),
          ),
          vehicleProfileRepositoryProvider.overrideWith(
            (ref) async => FakeVehicleProfileRepository(profile),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(vehicleProfileControllerProvider.future);
      await container
          .read(routePlanningControllerProvider.notifier)
          .planRoute(request);

      final before = container.read(tripEnergyProfileProvider)!;
      // Without a stop the charge falls monotonically.
      expect(
        before.socPercentByPoint.last,
        lessThan(before.socPercentByPoint[3]),
      );

      // Add a stop at the third polyline point.
      await container
          .read(routePlanningControllerProvider.notifier)
          .addStop(groupId: 'mid', coordinate: polyline[3]);

      final after = container.read(tripEnergyProfileProvider)!;
      expect(
        after.socPercentByPoint,
        isNot(equals(before.socPercentByPoint)),
        reason: 'the SoC curve must change once a stop is inserted',
      );
      // The point at/after the stop should be well above the pre-stop value.
      expect(
        after.socPercentByPoint[4],
        greaterThan(before.socPercentByPoint[4] + 20),
      );
      // The stop trace shows the reset to the profile target by default.
      expect(after.stopSocs, hasLength(1));
      expect(after.stopSocs.single.departureSocPercent, closeTo(80, 0.001));
      expect(after.chargeTargetSocPercent, 80);

      // A per-trip charge target overrides the profile target.
      container
          .read(routePlanningControllerProvider.notifier)
          .setTripChargeTargetSoc(60);
      final retargeted = container.read(tripEnergyProfileProvider)!;
      expect(retargeted.chargeTargetSocPercent, 60);
      expect(
        retargeted.stopSocs.single.departureSocPercent,
        closeTo(60, 0.001),
      );
    },
  );
}
