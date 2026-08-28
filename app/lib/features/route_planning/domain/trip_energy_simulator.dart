import 'package:ladepark_explorer/features/route_planning/domain/energy_model.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_segment.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_stop.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/vehicle_profile.dart';

/// Estimated state of charge at one charging stop: the value on arrival and the
/// value the simulation assumes on departure (FR-ROUTE-006).
class StopSoc {
  const StopSoc({
    required this.groupId,
    required this.positionKm,
    required this.arrivalSocPercent,
    required this.departureSocPercent,
  });

  final String groupId;
  final double positionKm;
  final double arrivalSocPercent;
  final double departureSocPercent;
}

/// Estimated state of charge along the route (FR-ROUTE-006).
class TripEnergyProfile {
  const TripEnergyProfile({
    required this.socPercentByPoint,
    required this.cumulativeKmByPoint,
    required this.reservePercent,
    required this.chargeTargetSocPercent,
    this.stopSocs = const <StopSoc>[],
    this.deficitKm,
  });

  /// State of charge in percent at each polyline point (length = points).
  final List<double> socPercentByPoint;

  /// Distance from the start at each polyline point.
  final List<double> cumulativeKmByPoint;

  final int reservePercent;

  /// State of charge the simulation resets to on departure from a stop
  /// (version 1.1: the trip charge target, otherwise the profile target).
  final int chargeTargetSocPercent;

  /// Arrival and departure state of charge at each charging stop, ordered by
  /// position on the route.
  final List<StopSoc> stopSocs;

  /// Distance from the start at which the estimated state of charge first
  /// drops below the reserve, or null if it never does.
  final double? deficitKm;

  bool get reachesReserve => deficitKm == null;

  double midSocForSegment(int index) =>
      (socPercentByPoint[index] + socPercentByPoint[index + 1]) / 2;

  /// Linearly interpolated state of charge at [km] from the start. Used to show
  /// the charge a driver would arrive with at a park that is not (yet) a stop.
  double socAtKm(double km) {
    if (socPercentByPoint.isEmpty) return 0;
    if (km <= cumulativeKmByPoint.first) return socPercentByPoint.first;
    if (km >= cumulativeKmByPoint.last) return socPercentByPoint.last;
    for (var i = 1; i < cumulativeKmByPoint.length; i++) {
      if (km <= cumulativeKmByPoint[i]) {
        final span = cumulativeKmByPoint[i] - cumulativeKmByPoint[i - 1];
        final t = span <= 0 ? 0.0 : (km - cumulativeKmByPoint[i - 1]) / span;
        return socPercentByPoint[i - 1] +
            (socPercentByPoint[i] - socPercentByPoint[i - 1]) * t;
      }
    }
    return socPercentByPoint.last;
  }
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
    int? chargeTargetSocPercent,
    EnergyModel model = const ConstantRateEnergyModel(),
    double Function(RouteStop stop, double arrivalSocPercent)?
    departureSocPercent,
  }) {
    final chargeTarget =
        chargeTargetSocPercent ?? vehicle.targetArrivalSocPercent;
    final departure =
        departureSocPercent ?? (stop, arrival) => chargeTarget.toDouble();
    final orderedStops = <RouteStop>[...stops]
      ..sort((a, b) => a.positionKm.compareTo(b.positionKm));
    final energies = model.estimate(path, vehicle, const TripContext());

    var soc = startSocPercent.clamp(0, 100).toDouble();
    final socByPoint = <double>[soc];
    final kmByPoint = <double>[0];
    final stopSocs = <StopSoc>[];
    var cumulativeKm = 0.0;
    var nextStop = 0;
    double? deficitKm;

    void applyStopsUpTo(double km) {
      while (nextStop < orderedStops.length &&
          orderedStops[nextStop].positionKm <= km) {
        final stop = orderedStops[nextStop];
        final arrival = soc;
        soc = departure(stop, soc).clamp(0, 100).toDouble();
        stopSocs.add(
          StopSoc(
            groupId: stop.groupId,
            positionKm: stop.positionKm,
            arrivalSocPercent: arrival,
            departureSocPercent: soc,
          ),
        );
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
      chargeTargetSocPercent: chargeTarget,
      stopSocs: stopSocs,
      deficitKm: deficitKm,
    );
  }
}
