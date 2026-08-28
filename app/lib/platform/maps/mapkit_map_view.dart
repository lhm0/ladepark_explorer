import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_summary.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_bounds.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/platform/maps/map_adapter.dart';

const _viewType = 'de.ladeparkexplorer/map';

class MapKitMapView extends StatelessWidget {
  const MapKitMapView({
    required this.onMapCreated,
    required this.unavailableLabel,
    this.eagerGestures = true,
    super.key,
  });

  final ValueChanged<MapKitAdapter> onMapCreated;
  final String unavailableLabel;

  /// Whether the platform view claims every pointer eagerly. The main map keeps
  /// this on for immediate panning; the route preview turns it off to reduce
  /// the iOS platform-view gesture-wedge risk (see ADR-0019 Nachtrag).
  final bool eagerGestures;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Center(child: Text(unavailableLabel)),
      );
    }
    return UiKitView(
      viewType: _viewType,
      gestureRecognizers: eagerGestures
          ? <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
            }
          : const <Factory<OneSequenceGestureRecognizer>>{},
      creationParams: const <String, Object?>{
        'latitude': 51.1657,
        'longitude': 10.4515,
        'latitudeDelta': 8.8,
        'longitudeDelta': 12.5,
      },
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: (viewId) {
        final adapter = MapKitAdapter(viewId);
        onMapCreated(adapter);
      },
    );
  }
}

final class MapKitAdapter implements MapAdapter {
  MapKitAdapter(int viewId) : _channel = MethodChannel('$_viewType/$viewId') {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  final MethodChannel _channel;
  final StreamController<GeoBounds> _bounds = StreamController.broadcast();
  final StreamController<String> _selections = StreamController.broadcast();
  final StreamController<String> _corridorSelections =
      StreamController.broadcast();
  final StreamController<String> _routeStopSelections =
      StreamController.broadcast();
  List<ChargingGroupSummary>? _pendingMarkerGroups;
  Future<void>? _markerDrain;
  bool _disposed = false;

  @override
  Stream<String> get selectedGroupIds => _selections.stream;

  @override
  Stream<String> get selectedCorridorParkIds => _corridorSelections.stream;

  @override
  Stream<String> get selectedRouteStopIds => _routeStopSelections.stream;

  @override
  Stream<GeoBounds> get visibleBounds => _bounds.stream;

  @override
  Future<void> showGroups(List<ChargingGroupSummary> groups) {
    if (_disposed) {
      return Future<void>.value();
    }
    _pendingMarkerGroups = groups;
    return _markerDrain ??= _drainMarkerUpdates().whenComplete(() {
      _markerDrain = null;
    });
  }

  Future<void> _drainMarkerUpdates() async {
    while (!_disposed && _pendingMarkerGroups != null) {
      final groups = _pendingMarkerGroups!;
      _pendingMarkerGroups = null;
      final stopwatch = Stopwatch()..start();
      await _channel.invokeMethod<void>(
        'showGroups',
        groups
            .map(
              (group) => <String, Object?>{
                'groupId': group.groupId,
                'latitude': group.latitude,
                'longitude': group.longitude,
                'evseCount': group.evseCount,
                'hpcEvseCount': group.hpcEvseCount,
                'isFavorite': group.isFavorite,
              },
            )
            .toList(growable: false),
      );
      stopwatch.stop();
      if (kDebugMode) {
        debugPrint(
          '[LadeparkMap] markerUpdate count=${groups.length} '
          'elapsedMs=${stopwatch.elapsedMilliseconds} '
          'pending=${_pendingMarkerGroups != null}',
        );
      }
    }
  }

  Future<void> requestVisibleBounds() async {
    if (!_disposed) {
      await _channel.invokeMethod<void>('requestVisibleBounds');
    }
  }

  @override
  Future<GeoCoordinate> focusUserLocation({required double radiusKm}) async {
    if (_disposed) {
      throw StateError('Der Kartenadapter ist bereits geschlossen.');
    }
    final values = await _channel.invokeMapMethod<Object?, Object?>(
      'focusUserLocation',
      <String, Object?>{'radiusKm': radiusKm},
    );
    if (values == null) {
      throw PlatformException(code: 'location_unavailable');
    }
    return GeoCoordinate(
      latitude: _number(values, 'latitude'),
      longitude: _number(values, 'longitude'),
    );
  }

  @override
  Future<void> focusCoordinate(
    GeoCoordinate coordinate, {
    required double radiusKm,
  }) async {
    if (!_disposed) {
      await _channel.invokeMethod<void>('focusCoordinate', <String, Object?>{
        'latitude': coordinate.latitude,
        'longitude': coordinate.longitude,
        'radiusKm': radiusKm,
      });
    }
  }

  @override
  Future<void> showGermanyOverview() async {
    if (!_disposed) {
      await _channel.invokeMethod<void>('showGermanyOverview');
    }
  }

  @override
  Future<void> showRoute(
    List<GeoCoordinate> polyline, {
    List<int>? segmentColorsArgb,
  }) async {
    if (_disposed) {
      return;
    }
    await _channel.invokeMethod<void>('showRoute', <String, Object?>{
      'polyline': polyline
          .map(
            (point) => <String, Object?>{
              'latitude': point.latitude,
              'longitude': point.longitude,
            },
          )
          .toList(growable: false),
      'segmentColors': ?segmentColorsArgb,
    });
  }

  @override
  Future<void> showRouteStops(List<RouteStopMarker> stops) async {
    if (_disposed) {
      return;
    }
    await _channel.invokeMethod<void>('showRouteStops', <String, Object?>{
      'stops': stops
          .map(
            (stop) => <String, Object?>{
              'latitude': stop.coordinate.latitude,
              'longitude': stop.coordinate.longitude,
              'groupId': stop.id,
            },
          )
          .toList(growable: false),
    });
  }

  @override
  Future<void> showRouteCorridor(List<ChargingGroupSummary> parks) async {
    if (_disposed) {
      return;
    }
    await _channel.invokeMethod<void>('showRouteCorridor', <String, Object?>{
      'parks': parks
          .map(
            (park) => <String, Object?>{
              'latitude': park.latitude,
              'longitude': park.longitude,
              'groupId': park.groupId,
            },
          )
          .toList(growable: false),
    });
  }

  @override
  Future<void> clearRoute() async {
    if (!_disposed) {
      await _channel.invokeMethod<void>('clearRoute');
    }
  }

  Future<Object?> _handleMethodCall(MethodCall call) async {
    final arguments = call.arguments;
    if (call.method == 'boundsChanged' && arguments is Map<Object?, Object?>) {
      _bounds.add(
        GeoBounds(
          south: _number(arguments, 'south'),
          west: _number(arguments, 'west'),
          north: _number(arguments, 'north'),
          east: _number(arguments, 'east'),
        ),
      );
    } else if (call.method == 'groupSelected' && arguments is String) {
      _selections.add(arguments);
    } else if (call.method == 'corridorParkSelected' && arguments is String) {
      _corridorSelections.add(arguments);
    } else if (call.method == 'routeStopSelected' && arguments is String) {
      _routeStopSelections.add(arguments);
    }
    return null;
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _pendingMarkerGroups = null;
    await _markerDrain;
    _channel.setMethodCallHandler(null);
    await _bounds.close();
    await _selections.close();
    await _corridorSelections.close();
    await _routeStopSelections.close();
  }
}

double _number(Map<Object?, Object?> values, String key) {
  final value = values[key];
  if (value is num) {
    return value.toDouble();
  }
  throw PlatformException(
    code: 'invalid_map_message',
    message: 'MapKit lieferte ungültige Kartengrenzen.',
  );
}
