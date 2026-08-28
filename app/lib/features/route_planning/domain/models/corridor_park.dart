import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_summary.dart';

/// A charging park found inside the route corridor (FR-ROUTE-003), annotated
/// with where it sits along the route and a rough detour estimate.
class CorridorPark {
  const CorridorPark({
    required this.group,
    required this.positionKm,
    required this.detourKm,
  });

  final ChargingGroupSummary group;

  /// Distance from the route start to the point on the route nearest this park.
  final double positionKm;

  /// Rough there-and-back extra distance to reach this park from the route.
  final double detourKm;
}
