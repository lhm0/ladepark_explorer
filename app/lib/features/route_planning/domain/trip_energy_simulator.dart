import 'package:ladepark_explorer/features/route_planning/domain/energy_model.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_segment.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_stop.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/vehicle_profile.dart';

/// Estimated state of charge along the route (FR-ROUTE-006).
class TripEnergyProfile {
  const TripEnergyProfile({
    required this.socPercentByPoint,
    required this.cumulativeKmByPoint,
    required this.reservePercent,
    this.deficitKm,
  });

  /// State of charge in percent at each polyline point (length = points).
  final List<double> socPercentByPoint;

  /// Distance from the start at each polyline point.
  final List<double> cumulativeKmByPoint;

  final int reservePercent;

  /// Distance from the start at which the estimated state of charge first
  /// drops below the reserve, or null if it never does.
  final double? deficitKm;

  bool get reachesReserve => deficitKm == null;

  double midSocForSegment(int index) =>
      (socPercentByPoint[index] + socPercentByPoint[index + 1]) / 2;
}

/// Walks the route segment by segment, applying an [EnergyModel] between stops
/// and jumping the state of charge back up at each charging stop. Independent
/// of the concrete model (NFR-ROUTE-EXT-001).
final class TripEnergySimulator {
  const TripEnergySimulator();

  TripEnergyProfile simulate({
    required RoutePath path,
    required List<RouteStop> stops,
    required VehicleProfile vehicle,
    required double startSocPercent,
    EnergyModel model = const ConstantRateEnergyModel(),
    double Function(RouteStop stop, double arrivalSocPercent)?
    departureSocPercent,
  }) {
    final departure =
        departureSocPercent ??
        (stop, arrival) => vehicle.targetArrivalSocPercent.toDouble();
    final orderedStops = <RouteStop>[...stops]
      ..sort((a, b) => a.positionKm.compareTo(b.positionKm));
    final energies = model.estimate(path, vehicle, const TripContext());

    var soc = startSocPercent.clamp(0, 100).toDouble();
    final socByPoint = <double>[soc];
    final kmByPoint = <double>[0];
    var cumulativeKm = 0.0;
    var nextStop = 0;
    double? deficitKm;

    void applyStopsUpTo(double km) {
      while (nextStop < orderedStops.length &&
          orderedStops[nextStop].positionKm <= km) {
        soc = departure(orderedStops[nextStop], soc).clamp(0, 100).toDouble();
        nextStop++;
      }
    }

    if (soc < vehicle.reserveSocPercent) deficitKm = 0;
    for (var i = 0; i < path.length; i++) {
      applyStopsUpTo(cumulativeKm);
      final deltaSoc = vehicle.usableBatteryKwh == 0
          ? 0.0
          : energies[i].energyKwh / vehicle.usableBatteryKwh * 100;
      soc = (soc - deltaSoc).clamp(-100, 100).toDouble();
      cumulativeKm += path[i].distanceKm;
      socByPoint.add(soc);
      kmByPoint.add(cumulativeKm);
      if (deficitKm == null && soc < vehicle.reserveSocPercent) {
        deficitKm = cumulativeKm;
      }
    }
    applyStopsUpTo(cumulativeKm);

    return TripEnergyProfile(
      socPercentByPoint: socByPoint,
      cumulativeKmByPoint: kmByPoint,
      reservePercent: vehicle.reserveSocPercent,
      deficitKm: deficitKm,
    );
  }
}
