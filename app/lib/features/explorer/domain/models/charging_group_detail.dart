class ChargingGroupDetail {
  const ChargingGroupDetail({
    required this.groupId,
    required this.anchorStationId,
    required this.stationIds,
    required this.name,
    required this.street,
    required this.houseNumber,
    required this.postalCode,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.stationCount,
    required this.evseCount,
    required this.maxPowerKw,
    required this.actualDiameterM,
    required this.operators,
    required this.connectorTypes,
    required this.powerBandCounts,
    required this.openingHours,
    required this.datasetVersion,
    required this.datasetCreatedAt,
    required this.sourceName,
    required this.sourceVersion,
  });

  final String groupId;
  final String anchorStationId;
  final List<String> stationIds;
  final String? name;
  final String? street;
  final String? houseNumber;
  final String? postalCode;
  final String? city;
  final double latitude;
  final double longitude;
  final int stationCount;
  final int evseCount;
  final double? maxPowerKw;
  final double actualDiameterM;
  final List<ChargingOperatorDetail> operators;
  final List<String> connectorTypes;
  final Map<int, int> powerBandCounts;
  final String? openingHours;
  final String datasetVersion;
  final String datasetCreatedAt;
  final String sourceName;
  final String sourceVersion;
}

class ChargingOperatorDetail {
  const ChargingOperatorDetail({
    required this.name,
    required this.connectorCountsByPowerBand,
  });

  final String name;
  final Map<int, Map<String, int>> connectorCountsByPowerBand;
}
