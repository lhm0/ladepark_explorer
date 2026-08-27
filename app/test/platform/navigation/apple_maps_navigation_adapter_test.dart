import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/platform/navigation/apple_maps_navigation_adapter.dart';

// Platform contract for FR-NAV-001 and NFR-PORT-001.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sends a typed Apple Maps destination to the platform', () async {
    const channel = MethodChannel('de.ladeparkexplorer/platform');
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          receivedCall = call;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await const AppleMapsNavigationAdapter().openDirections(
      latitude: 52.52,
      longitude: 13.405,
      name: 'Testpark Nord',
    );

    expect(receivedCall?.method, 'openAppleMapsDirections');
    expect(receivedCall?.arguments, <String, Object?>{
      'latitude': 52.52,
      'longitude': 13.405,
      'name': 'Testpark Nord',
    });
  });

  test('Apple Maps is always available on the supported platform', () async {
    expect(await const AppleMapsNavigationAdapter().isAvailable(), isTrue);
  });
}
