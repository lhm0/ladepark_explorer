import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/platform/navigation/google_maps_navigation_adapter.dart';

// Platform contract for FR-NAV-001 and NFR-PORT-001.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('de.ladeparkexplorer/platform');

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('checks whether Google Maps is installed', () async {
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          receivedCall = call;
          return true;
        });

    expect(await const GoogleMapsNavigationAdapter().isAvailable(), isTrue);
    expect(receivedCall?.method, 'isGoogleMapsAvailable');
  });

  test('sends coordinates to Google Maps', () async {
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          receivedCall = call;
          return null;
        });

    await const GoogleMapsNavigationAdapter().openDirections(
      latitude: 51.2,
      longitude: 6.9,
      name: 'Hilden',
    );
    expect(receivedCall?.method, 'openGoogleMapsDirections');
    expect(receivedCall?.arguments, <String, Object?>{
      'latitude': 51.2,
      'longitude': 6.9,
      'name': 'Hilden',
    });
  });
}
