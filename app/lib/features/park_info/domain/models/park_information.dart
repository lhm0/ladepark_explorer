enum AmenityState { present, absent, unknown }

enum AmenityType { restaurant, shop, coffeeMachine, snackMachine, toilet }

final class ParkPhoto {
  const ParkPhoto({
    required this.id,
    required this.assetPath,
    required this.author,
    required this.capturedOn,
    required this.altText,
  });

  final String id;
  final String assetPath;
  final String author;
  final String capturedOn;
  final String altText;
}

final class ParkInformation {
  const ParkInformation({
    required this.id,
    required this.title,
    required this.observedOn,
    required this.notes,
    required this.amenities,
    required this.photos,
  });

  final String id;
  final String? title;
  final String observedOn;
  final String? notes;
  final Map<AmenityType, AmenityState> amenities;
  final List<ParkPhoto> photos;
}
