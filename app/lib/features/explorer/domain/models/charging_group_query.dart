import 'package:ladepark_explorer/features/explorer/domain/models/geo_bounds.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';

class ChargingGroupQuery {
  const ChargingGroupQuery({
    required this.bounds,
    this.diameterM = 50,
    this.minimumEvseCount = 20,
    this.minimumPowerKw = 100,
    this.operatorNames = const [],
    this.operatorIds = const [],
    this.connectorTypes = const [],
    this.favoriteAnchorStationIds = const [],
    this.amenityAnchorStationIds = const [],
    this.amenitiesOnly = false,
    this.alwaysOpenOnly = false,
    this.favoritesOnly = false,
    this.searchText,
    this.center,
    this.radiusKm,
    this.limit = 500,
  }) : assert(limit > 0 && limit <= 500),
       assert((center == null) == (radiusKm == null)),
       assert(radiusKm == null || radiusKm > 0);

  final GeoBounds bounds;
  final int diameterM;
  final int minimumEvseCount;
  final int minimumPowerKw;
  final List<String> operatorNames;
  final List<String> operatorIds;
  final List<String> connectorTypes;
  final List<String> favoriteAnchorStationIds;
  final List<String> amenityAnchorStationIds;
  final bool amenitiesOnly;
  final bool alwaysOpenOnly;
  final bool favoritesOnly;
  final String? searchText;
  final GeoCoordinate? center;
  final double? radiusKm;
  final int limit;
}
