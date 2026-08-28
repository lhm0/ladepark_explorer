import 'package:flutter/services.dart';
import 'package:ladepark_explorer/platform/navigation/navigation_adapter.dart';

final class AppleMapsNavigationAdapter implements NavigationAdapter {
  const AppleMapsNavigationAdapter();

  static const _channel = MethodChannel('de.ladeparkexplorer/platform');

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> openDirections({
    required double latitude,
    required double longitude,
    String? name,
  }) {
    return _channel.invokeMethod<void>(
      'openAppleMapsDirections',
      <String, Object?>{
        'latitude': latitude,
        'longitude': longitude,
        'name': name,
      },
    );
  }

  @override
  Future<NavigationHandoff> openRoute(NavigationRoute route) async {
    // Apple Maps routes through an ordered list of map items, so the whole
    // chain is handed over.
    await _channel.invokeMethod<void>('openAppleMapsRoute', <String, Object?>{
      'waypoints': <Map<String, Object?>>[
        _point(route.origin),
        for (final stop in route.stops) _point(stop),
        _point(route.destination),
      ],
    });
    return NavigationHandoff(
      includedStops: route.stops.length,
      totalStops: route.stops.length,
    );
  }

  Map<String, Object?> _point(NavigationWaypoint waypoint) => <String, Object?>{
    'latitude': waypoint.latitude,
    'longitude': waypoint.longitude,
    'name': waypoint.name,
  };
}
