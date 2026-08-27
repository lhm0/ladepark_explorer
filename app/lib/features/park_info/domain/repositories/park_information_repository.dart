import 'package:ladepark_explorer/features/park_info/domain/models/park_information.dart';

abstract interface class ParkInformationRepository {
  /// Returns station anchors whose editorial park has every requested amenity
  /// explicitly marked as present (FR-FILTER-002).
  Future<List<String>> findStationIdsWithAmenities(
    List<AmenityType> requiredAmenities,
  );

  Future<ParkInformation?> findForStations(
    List<String> stationIds, {
    required bool german,
  });
}
