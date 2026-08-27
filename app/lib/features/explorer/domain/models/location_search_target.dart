import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_summary.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';

class LocationSearchTarget {
  const LocationSearchTarget({
    required this.center,
    required this.radiusKm,
    this.nearestGroup,
  });

  final GeoCoordinate center;
  final double radiusKm;
  final ChargingGroupSummary? nearestGroup;
}
