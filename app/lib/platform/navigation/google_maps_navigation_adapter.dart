import 'package:flutter/services.dart';
import 'package:ladepark_explorer/platform/navigation/navigation_adapter.dart';

final class GoogleMapsNavigationAdapter implements NavigationAdapter {
  const GoogleMapsNavigationAdapter();

  static const _channel = MethodChannel('de.ladeparkexplorer/platform');

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
    // The comgooglemaps:// scheme opens the app reliably but has no waypoint
    // parameter, so Google Maps is guided to the next charging stop (or the
    // destination when the plan has none). The remaining stops are re-opened
    // from the app after each charge.
    final target = route.stops.isEmpty ? route.destination : route.stops.first;
    await _channel.invokeMethod<void>('openGoogleMapsRoute', <String, Object?>{
      'origin': _point(route.origin),
      'destination': _point(target),
    });
    return NavigationHandoff(includedStops: 0, totalStops: route.stops.length);
  }

  Map<String, Object?> _point(NavigationWaypoint waypoint) => <String, Object?>{
    'latitude': waypoint.latitude,
    'longitude': waypoint.longitude,
    'name': waypoint.name,
  };
}
