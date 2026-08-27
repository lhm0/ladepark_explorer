class Favorite {
  const Favorite({
    required this.anchorStationId,
    required this.savedDiameterM,
    required this.savedAt,
    required this.latitude,
    required this.longitude,
    this.displayName,
    this.street,
    this.houseNumber,
    this.postalCode,
    this.city,
  });

  final String anchorStationId;
  final int savedDiameterM;
  final DateTime savedAt;
  final String? displayName;
  final String? street;
  final String? houseNumber;
  final String? postalCode;
  final String? city;
  final double latitude;
  final double longitude;
}
