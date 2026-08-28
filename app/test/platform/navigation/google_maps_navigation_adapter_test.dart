import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/platform/navigation/google_maps_navigation_adapter.dart';
import 'package:ladepark_explorer/platform/navigation/navigation_adapter.dart';

// Platform contract for FR-NAV-001, FR-ROUTE-011 and NFR-PORT-001.
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

  test('hands origin, stops and destination to Google Maps', () async {
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          receivedCall = call;
          return null;
        });

    final handoff = await const GoogleMapsNavigationAdapter().openRoute(
      const NavigationRoute(
        origin: NavigationWaypoint(latitude: 52.5, longitude: 13.4),
        destination: NavigationWaypoint(latitude: 48.1, longitude: 11.6),
        stops: <NavigationWaypoint>[
          NavigationWaypoint(latitude: 50.0, longitude: 12.0),
          NavigationWaypoint(latitude: 49.0, longitude: 11.8),
        ],
      ),
    );

    expect(receivedCall?.method, 'openGoogleMapsRoute');
    expect(
      ((receivedCall?.arguments as Map)['waypoints'] as List<Object?>),
      hasLength(2),
    );
    expect(handoff.truncated, isFalse);
    expect(handoff.includedStops, 2);
  });

  test('shortens the plan to the Google Maps waypoint limit', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => null);

    final stops = <NavigationWaypoint>[
      for (var i = 0; i < GoogleMapsNavigationAdapter.maxStops + 3; i++)
        NavigationWaypoint(latitude: 50.0 + i * 0.1, longitude: 12.0),
    ];
    final handoff = await const GoogleMapsNavigationAdapter().openRoute(
      NavigationRoute(
        origin: const NavigationWaypoint(latitude: 52.5, longitude: 13.4),
        destination: const NavigationWaypoint(latitude: 48.1, longitude: 11.6),
        stops: stops,
      ),
    );

    expect(handoff.includedStops, GoogleMapsNavigationAdapter.maxStops);
    expect(handoff.totalStops, stops.length);
    expect(handoff.truncated, isTrue);
  });
}
