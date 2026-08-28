import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_summary.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/platform/maps/mapkit_map_view.dart';

// Platform message contract for FR-MAP-001 and NFR-PORT-001.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('requests the Germany overview from the native map', () async {
    const channel = MethodChannel('de.ladeparkexplorer/map/17');
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          receivedCall = call;
          return null;
        });
    final adapter = MapKitAdapter(17);
    addTearDown(() async {
      await adapter.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await adapter.showGermanyOverview();

    expect(receivedCall?.method, 'showGermanyOverview');
  });

  test('coalesces queued marker updates to the latest state', () async {
    const channel = MethodChannel('de.ladeparkexplorer/map/18');
    final calls = <MethodCall>[];
    final firstUpdate = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) {
          calls.add(call);
          return calls.length == 1 ? firstUpdate.future : Future<void>.value();
        });
    final adapter = MapKitAdapter(18);
    addTearDown(() async {
      await adapter.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final firstDrain = adapter.showGroups(<ChargingGroupSummary>[_group('1')]);
    unawaited(adapter.showGroups(<ChargingGroupSummary>[_group('2')]));
    unawaited(
      adapter.showGroups(<ChargingGroupSummary>[_group('3', isFavorite: true)]),
    );
    expect(calls, hasLength(1));

    firstUpdate.complete();
    await firstDrain;

    expect(calls, hasLength(2));
    final latestArguments = calls.last.arguments! as List<Object?>;
    final latestGroup = latestArguments.single! as Map<Object?, Object?>;
    expect(latestGroup['groupId'], '3');
    expect(latestGroup['isFavorite'], isTrue);
  });

  test('requests and focuses a user location with a radius', () async {
    const channel = MethodChannel('de.ladeparkexplorer/map/19');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return <String, double>{'latitude': 53.55, 'longitude': 9.99};
        });
    final adapter = MapKitAdapter(19);
    addTearDown(() async {
      await adapter.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    final coordinate = await adapter.focusUserLocation(radiusKm: 25);
    await adapter.focusCoordinate(coordinate, radiusKm: 10);

    expect(coordinate, const GeoCoordinate(latitude: 53.55, longitude: 9.99));
    expect(calls.first.method, 'focusUserLocation');
    expect(calls.first.arguments, <String, Object?>{'radiusKm': 25.0});
    expect(calls.last.method, 'focusCoordinate');
  });

  test('sends and clears a native route overlay for FR-ROUTE-001', () async {
    const channel = MethodChannel('de.ladeparkexplorer/map/20');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
    final adapter = MapKitAdapter(20);
    addTearDown(() async {
      await adapter.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    await adapter.showRoute(const <GeoCoordinate>[
      GeoCoordinate(latitude: 52.52, longitude: 13.40),
      GeoCoordinate(latitude: 48.14, longitude: 11.58),
    ]);
    await adapter.clearRoute();

    expect(calls.first.method, 'showRoute');
    expect(
      (calls.first.arguments as Map<Object?, Object?>)['polyline'],
      <Object?>[
        <String, Object?>{'latitude': 52.52, 'longitude': 13.40},
        <String, Object?>{'latitude': 48.14, 'longitude': 11.58},
      ],
    );
    expect(calls.last.method, 'clearRoute');
  });
}

ChargingGroupSummary _group(String id, {bool isFavorite = false}) =>
    ChargingGroupSummary(
      groupId: id,
      latitude: 52,
      longitude: 13,
      stationCount: 1,
      evseCount: 1,
      hpcEvseCount: 1,
      maxPowerKw: 150,
      city: 'Berlin',
      isFavorite: isFavorite,
    );
