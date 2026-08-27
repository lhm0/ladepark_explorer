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
}
