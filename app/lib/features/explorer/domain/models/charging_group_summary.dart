class ChargingGroupSummary {
  const ChargingGroupSummary({
    required this.groupId,
    required this.latitude,
    required this.longitude,
    required this.stationCount,
    required this.evseCount,
    required this.hpcEvseCount,
    required this.maxPowerKw,
    required this.city,
    this.name,
    this.street,
    this.houseNumber,
    this.postalCode,
    this.isFavorite = false,
  });

  final String groupId;
  final double latitude;
  final double longitude;
  final int stationCount;
  final int evseCount;
  final int hpcEvseCount;
  final double? maxPowerKw;
  final String? city;
  final String? name;
  final String? street;
  final String? houseNumber;
  final String? postalCode;
  final bool isFavorite;
}
