import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/explorer/presentation/location_search_page.dart';

// Input contract for FR-SEARCH-001 and the M6 coordinate handover.
void main() {
  test('parses coordinates and direct Apple and Google Maps URLs', () {
    expect(
      parseLocationInput('53.5511, 9.9937'),
      const GeoCoordinate(latitude: 53.5511, longitude: 9.9937),
    );
    expect(
      parseLocationInput('https://maps.apple.com/?ll=53.5511,9.9937'),
      const GeoCoordinate(latitude: 53.5511, longitude: 9.9937),
    );
    expect(
      parseLocationInput(
        'https://www.google.com/maps/search/?api=1&query=53.5511%2C9.9937',
      ),
      const GeoCoordinate(latitude: 53.5511, longitude: 9.9937),
    );
    expect(
      parseLocationInput('ladeparkexplorer://location?lat=53.5511&lon=9.9937'),
      const GeoCoordinate(latitude: 53.5511, longitude: 9.9937),
    );
  });

  test('rejects text and coordinates outside the valid range', () {
    expect(parseLocationInput('Hamburg'), isNull);
    expect(parseLocationInput('93, 10'), isNull);
  });
}
