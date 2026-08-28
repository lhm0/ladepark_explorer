import 'package:ladepark_explorer/features/route_planning/domain/models/route_segment.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/vehicle_profile.dart';

/// Fahrtbezogene Zusatzgrößen für die Verbrauchsschätzung. In Version 1.1
/// leer; ein späteres Modell ergänzt hier Temperatur und Weiteres (ADR-0020).
class TripContext {
  const TripContext({this.ambientTempC});

  final double? ambientTempC;
}

/// Estimated energy use for one [RouteSegment].
class SegmentEnergy {
  const SegmentEnergy({required this.segment, required this.energyKwh});

  final RouteSegment segment;
  final double energyKwh;
}

/// Exchangeable consumption estimator (NFR-ROUTE-EXT-001, ADR-0020). A later
/// implementation may use road class, gradient, temperature and driver habits.
abstract interface class EnergyModel {
  List<SegmentEnergy> estimate(
    RoutePath path,
    VehicleProfile vehicle,
    TripContext context,
  );
}

/// Version 1.1 model: energy = distance / 100 km × profile consumption. All
/// optional segment attributes and the [TripContext] are ignored.
final class ConstantRateEnergyModel implements EnergyModel {
  const ConstantRateEnergyModel();

  @override
  List<SegmentEnergy> estimate(
    RoutePath path,
    VehicleProfile vehicle,
    TripContext context,
  ) => <SegmentEnergy>[
    for (final segment in path)
      SegmentEnergy(
        segment: segment,
        energyKwh: segment.distanceKm / 100 * vehicle.consumptionKwhPer100Km,
      ),
  ];
}
