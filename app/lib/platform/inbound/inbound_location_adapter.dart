import 'dart:async';

import 'package:flutter/services.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';

final class InboundLocationAdapter {
  InboundLocationAdapter({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel('de.ladeparkexplorer/platform') {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  final MethodChannel _channel;
  final StreamController<GeoCoordinate> _locations =
      StreamController.broadcast();

  Stream<GeoCoordinate> get locations => _locations.stream;

  Future<GeoCoordinate?> takePendingLocation() async {
    final values = await _channel.invokeMapMethod<Object?, Object?>(
      'takePendingLocation',
    );
    return values == null ? null : _coordinate(values);
  }

  Future<Object?> _handleMethodCall(MethodCall call) async {
    if (call.method == 'locationReceived' &&
        call.arguments is Map<Object?, Object?>) {
      _locations.add(_coordinate(call.arguments! as Map<Object?, Object?>));
    }
    return null;
  }

  Future<void> dispose() async {
    _channel.setMethodCallHandler(null);
    await _locations.close();
  }
}

GeoCoordinate _coordinate(Map<Object?, Object?> values) => GeoCoordinate(
  latitude: (values['latitude']! as num).toDouble(),
  longitude: (values['longitude']! as num).toDouble(),
);
