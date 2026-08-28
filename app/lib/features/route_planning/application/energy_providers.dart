import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/features/route_planning/application/route_planning_providers.dart';
import 'package:ladepark_explorer/features/route_planning/application/vehicle_profile_providers.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_segment.dart';
import 'package:ladepark_explorer/features/route_planning/domain/route_corridor.dart';
import 'package:ladepark_explorer/features/route_planning/domain/trip_energy_simulator.dart';

/// The estimated state of charge along the currently selected route
/// (FR-ROUTE-006). Null when there is no route or no complete vehicle profile.
final tripEnergyProfileProvider = Provider<TripEnergyProfile?>((ref) {
  final planning = ref.watch(routePlanningControllerProvider);
  final option = planning.selectedOption;
  final profile = ref.watch(vehicleProfileControllerProvider).value;
  if (option == null ||
      profile == null ||
      !profile.isComplete ||
      option.polyline.length < 2) {
    return null;
  }
  final path = buildRoutePath(
    option.polyline,
    totalTravelTime: option.totalTravelTime,
  );
  final stops = planning.stops
      .map(
        (stop) => stop.copyWith(
          positionKm: positionAlongPolylineKm(option.polyline, stop.coordinate),
        ),
      )
      .toList(growable: false);
  final startSoc =
      (planning.tripStartSocPercent ?? profile.defaultStartSocPercent)
          .toDouble();
  return const TripEnergySimulator().simulate(
    path: path,
    stops: stops,
    vehicle: profile,
    startSocPercent: startSoc,
  );
});
