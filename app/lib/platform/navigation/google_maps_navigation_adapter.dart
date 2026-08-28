import 'package:flutter/services.dart';
import 'package:ladepark_explorer/platform/navigation/navigation_adapter.dart';

final class GoogleMapsNavigationAdapter implements NavigationAdapter {
  const GoogleMapsNavigationAdapter();

  static const _channel = MethodChannel('de.ladeparkexplorer/platform');

  /// Google Maps' directions URL takes a limited number of intermediate
  /// waypoints; the plan is shortened to the first ones towards the
  /// destination when it has more.
  static const int maxStops = 8;

  @override
  Future<bool> isAvailable() async =>
      await _channel.invokeMethod<bool>('isGoogleMapsAvailable') ?? false;

  @override
  Future<void> openDirections({
    required double latitude,
    required double longitude,
    String? name,
  }) =>
      _channel.invokeMethod<void>('openGoogleMapsDirections', <String, Object?>{
        'latitude': latitude,
        'longitude': longitude,
        'name': name,
      });

  @override
  Future<NavigationHandoff> openRoute(NavigationRoute route) async {
    final included = route.stops.length <= maxStops
        ? route.stops
        : route.stops.sublist(0, maxStops);
    await _channel.invokeMethod<void>('openGoogleMapsRoute', <String, Object?>{
      'origin': _point(route.origin),
      'destination': _point(route.destination),
      'waypoints': <Map<String, Object?>>[
        for (final stop in included) _point(stop),
      ],
    });
    return NavigationHandoff(
      includedStops: included.length,
      totalStops: route.stops.length,
    );
  }

  Map<String, Object?> _point(NavigationWaypoint waypoint) => <String, Object?>{
    'latitude': waypoint.latitude,
    'longitude': waypoint.longitude,
    'name': waypoint.name,
  };
}
