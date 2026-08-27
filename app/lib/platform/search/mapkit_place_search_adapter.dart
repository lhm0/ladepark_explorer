import 'package:flutter/services.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';

final class MapKitPlaceSearchAdapter {
  const MapKitPlaceSearchAdapter({
    this.channel = const MethodChannel('de.ladeparkexplorer/platform'),
  });

  final MethodChannel channel;

  Future<GeoCoordinate?> geocodePlace(String query) async {
    final values = await channel.invokeMapMethod<Object?, Object?>(
      'geocodePlace',
      <String, Object?>{'query': query},
    );
    if (values == null) return null;
    return GeoCoordinate(
      latitude: (values['latitude']! as num).toDouble(),
      longitude: (values['longitude']! as num).toDouble(),
    );
  }
}
