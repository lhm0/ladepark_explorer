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
}
