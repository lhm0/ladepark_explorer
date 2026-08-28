import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/platform/navigation/apple_maps_navigation_adapter.dart';
import 'package:ladepark_explorer/platform/navigation/navigation_adapter.dart';

// Platform contract for FR-NAV-001, FR-ROUTE-011 and NFR-PORT-001.
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

  test('hands the whole waypoint chain to Apple Maps', () async {
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

    final handoff = await const AppleMapsNavigationAdapter().openRoute(
      const NavigationRoute(
        origin: NavigationWaypoint(latitude: 52.5, longitude: 13.4, name: 'A'),
        destination: NavigationWaypoint(
          latitude: 48.1,
          longitude: 11.6,
          name: 'B',
        ),
        stops: <NavigationWaypoint>[
          NavigationWaypoint(latitude: 50.0, longitude: 12.0, name: 'Stop 1'),
        ],
      ),
    );

    expect(receivedCall?.method, 'openAppleMapsRoute');
    final waypoints =
        (receivedCall?.arguments as Map)['waypoints'] as List<Object?>;
    expect(waypoints, hasLength(3));
    expect((waypoints.first! as Map)['name'], 'A');
    expect((waypoints.last! as Map)['name'], 'B');
    expect(handoff.truncated, isFalse);
    expect(handoff.includedStops, 1);
  });

  test('Apple Maps is always available on the supported platform', () async {
    expect(await const AppleMapsNavigationAdapter().isAvailable(), isTrue);
  });
}
