import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/platform/search/mapkit_place_search_adapter.dart';

// Platform contract for the online place-resolution part of FR-SEARCH-001.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resolves a place name through the native MapKit channel', () async {
    const channel = MethodChannel('test/place-search');
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          received = call;
          return <String, double>{'latitude': 53.5511, 'longitude': 9.9937};
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    final coordinate = await const MapKitPlaceSearchAdapter(
      channel: channel,
    ).geocodePlace('Hamburg');

    expect(received?.method, 'geocodePlace');
    expect(received?.arguments, <String, Object?>{'query': 'Hamburg'});
    expect(
      coordinate,
      const GeoCoordinate(latitude: 53.5511, longitude: 9.9937),
    );
  });
}
