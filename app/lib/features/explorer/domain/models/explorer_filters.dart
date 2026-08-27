import 'package:ladepark_explorer/features/park_info/domain/models/park_information.dart';

class ExplorerFilters {
  const ExplorerFilters({
    this.diameterM = 50,
    this.minimumEvseCount = 20,
    this.minimumPowerKw = 100,
    this.operatorNames = const <String>[],
    this.operatorIds = const <String>[],
    this.connectorTypes = const <String>[],
    this.requiredAmenities = const <AmenityType>[],
    this.nearbyRadiusKm,
    this.alwaysOpenOnly = false,
    this.favoritesOnly = false,
  });

  static const defaults = ExplorerFilters();

  final int diameterM;
  final int minimumEvseCount;
  final int minimumPowerKw;
  final List<String> operatorNames;
  final List<String> operatorIds;
  final List<String> connectorTypes;
  final List<AmenityType> requiredAmenities;
  final int? nearbyRadiusKm;
  final bool alwaysOpenOnly;
  final bool favoritesOnly;

  bool get isDefault => this == defaults;

  ExplorerFilters copyWith({
    int? diameterM,
    int? minimumEvseCount,
    int? minimumPowerKw,
    List<String>? operatorNames,
    List<String>? operatorIds,
    List<String>? connectorTypes,
    List<AmenityType>? requiredAmenities,
    int? nearbyRadiusKm,
    bool clearNearbyRadius = false,
    bool? alwaysOpenOnly,
    bool? favoritesOnly,
  }) => ExplorerFilters(
    diameterM: diameterM ?? this.diameterM,
    minimumEvseCount: minimumEvseCount ?? this.minimumEvseCount,
    minimumPowerKw: minimumPowerKw ?? this.minimumPowerKw,
    operatorNames: operatorNames ?? this.operatorNames,
    operatorIds: operatorIds ?? this.operatorIds,
    connectorTypes: connectorTypes ?? this.connectorTypes,
    requiredAmenities: requiredAmenities ?? this.requiredAmenities,
    nearbyRadiusKm: clearNearbyRadius
        ? null
        : nearbyRadiusKm ?? this.nearbyRadiusKm,
    alwaysOpenOnly: alwaysOpenOnly ?? this.alwaysOpenOnly,
    favoritesOnly: favoritesOnly ?? this.favoritesOnly,
  );

  @override
  bool operator ==(Object other) =>
      other is ExplorerFilters &&
      diameterM == other.diameterM &&
      minimumEvseCount == other.minimumEvseCount &&
      minimumPowerKw == other.minimumPowerKw &&
      _same(operatorNames, other.operatorNames) &&
      _same(operatorIds, other.operatorIds) &&
      _same(connectorTypes, other.connectorTypes) &&
      _same(requiredAmenities, other.requiredAmenities) &&
      nearbyRadiusKm == other.nearbyRadiusKm &&
      alwaysOpenOnly == other.alwaysOpenOnly &&
      favoritesOnly == other.favoritesOnly;

  @override
  int get hashCode => Object.hash(
    diameterM,
    minimumEvseCount,
    minimumPowerKw,
    Object.hashAll(operatorNames),
    Object.hashAll(operatorIds),
    Object.hashAll(connectorTypes),
    Object.hashAll(requiredAmenities),
    nearbyRadiusKm,
    alwaysOpenOnly,
    favoritesOnly,
  );
}

class ChargingFilterOptions {
  const ChargingFilterOptions({this.connectorTypes = const <String>[]});

  final List<String> connectorTypes;
}

class OperatorFilterOption {
  const OperatorFilterOption({
    required this.value,
    required this.displayName,
    required this.evseCount,
    required this.isCanonical,
  });

  final String value;
  final String displayName;
  final int evseCount;
  final bool isCanonical;
}

bool _same<T>(List<T> first, List<T> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
