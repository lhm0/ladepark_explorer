import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/data/park_info/sqlite/sqlite_park_information_repository.dart';
import 'package:ladepark_explorer/features/park_info/domain/models/park_information.dart';

// Read-only adapter contract for FR-DATA-004 and FR-FILTER-002.
void main() {
  const database = 'assets/datasets/park-info-contract.sqlite3';

  test('resolves reviewed information through a stable station id', () async {
    final repository = SqliteParkInformationRepository.open(database);
    addTearDown(repository.close);

    final result = await repository.findForStations(const [
      'fff955ec-a4d7-52ee-9250-46c4d6d53840',
    ], german: true);

    expect(result?.title, 'Redaktioneller Testpark');
    expect(result?.amenities[AmenityType.restaurant], AmenityState.present);
    expect(result?.amenities[AmenityType.shop], AmenityState.absent);
    expect(result?.amenities[AmenityType.snackMachine], AmenityState.unknown);
    expect(result?.photos, isEmpty);
  });

  test(
    'does not turn missing editorial coverage into absent amenities',
    () async {
      final repository = SqliteParkInformationRepository.open(database);
      addTearDown(repository.close);

      expect(
        await repository.findForStations(const ['unknown'], german: true),
        isNull,
      );
    },
  );

  test(
    'returns anchors only when every requested amenity is present',
    () async {
      final repository = SqliteParkInformationRepository.open(database);
      addTearDown(repository.close);

      expect(
        await repository.findStationIdsWithAmenities(const <AmenityType>[
          AmenityType.restaurant,
          AmenityType.coffeeMachine,
          AmenityType.toilet,
        ]),
        const <String>['fff955ec-a4d7-52ee-9250-46c4d6d53840'],
      );
      expect(
        await repository.findStationIdsWithAmenities(const <AmenityType>[
          AmenityType.restaurant,
          AmenityType.shop,
        ]),
        isEmpty,
      );
      expect(
        await repository.findStationIdsWithAmenities(const <AmenityType>[
          AmenityType.snackMachine,
        ]),
        isEmpty,
      );
    },
  );
}
