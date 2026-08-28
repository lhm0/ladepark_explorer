import 'package:flutter/services.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_bounds.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_leg.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_option.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_request.dart';
import 'package:ladepark_explorer/features/route_planning/domain/route_planning_exception.dart';
import 'package:ladepark_explorer/features/route_planning/domain/route_planning_service.dart';

/// MapKit `MKDirections` implementation of [RoutePlanningService] (ADR-0019).
///
/// The native side computes the route, decimates its polyline and returns only
/// the summary geometry needed by the app. The exact provider polyline stays
/// native.
final class MkDirectionsRoutePlanningService implements RoutePlanningService {
  const MkDirectionsRoutePlanningService({
    this.channel = const MethodChannel('de.ladeparkexplorer/platform'),
  });

  final MethodChannel channel;

  @override
  Future<List<RouteOption>> planRoute(RouteRequest request) async {
    List<Object?>? raw;
    try {
      raw = await channel
          .invokeListMethod<Object?>('planRoute', <String, Object?>{
            'origin': _coordinate(request.origin.coordinate),
            'destination': _coordinate(request.destination.coordinate),
            'waypoints': request.intermediateWaypoints
                .map((waypoint) => _coordinate(waypoint.coordinate))
                .toList(growable: false),
            'includeAlternatives': request.includeAlternatives,
          });
    } on PlatformException catch (error) {
      throw RoutePlanningException(_errorFor(error.code), error.message);
    } on MissingPluginException catch (error) {
      throw RoutePlanningException(
        RoutePlanningError.serviceFailed,
        error.message,
      );
    }

    if (raw == null || raw.isEmpty) {
      throw const RoutePlanningException(RoutePlanningError.noRouteFound);
    }
    return raw
        .whereType<Map<Object?, Object?>>()
        .map(_optionFrom)
        .toList(growable: false);
  }

  RouteOption _optionFrom(Map<Object?, Object?> values) {
    final polyline = (values['polyline'] as List<Object?>? ?? const <Object?>[])
        .whereType<Map<Object?, Object?>>()
        .map(_coordinateFrom)
        .toList(growable: false);
    final bounds = values['bounds'] as Map<Object?, Object?>? ?? const {};
    final legs = (values['legs'] as List<Object?>? ?? const <Object?>[])
        .whereType<Map<Object?, Object?>>()
        .map(_legFrom)
        .toList(growable: false);
    return RouteOption(
      totalDistanceKm: _number(values['totalDistanceKm']),
      totalTravelTime: Duration(
        seconds: _number(values['totalTravelTimeSeconds']).round(),
      ),
      boundingBox: GeoBounds(
        south: _number(bounds['south']),
        west: _number(bounds['west']),
        north: _number(bounds['north']),
        east: _number(bounds['east']),
      ),
      polyline: polyline,
      legs: legs,
    );
  }

  RouteLeg _legFrom(Map<Object?, Object?> values) => RouteLeg(
    start: GeoCoordinate(
      latitude: _number(values['startLatitude']),
      longitude: _number(values['startLongitude']),
    ),
    end: GeoCoordinate(
      latitude: _number(values['endLatitude']),
      longitude: _number(values['endLongitude']),
    ),
    distanceKm: _number(values['distanceKm']),
    travelTime: Duration(seconds: _number(values['travelTimeSeconds']).round()),
  );

  GeoCoordinate _coordinateFrom(Map<Object?, Object?> values) => GeoCoordinate(
    latitude: _number(values['latitude']),
    longitude: _number(values['longitude']),
  );

  Map<String, Object?> _coordinate(GeoCoordinate coordinate) =>
      <String, Object?>{
        'latitude': coordinate.latitude,
        'longitude': coordinate.longitude,
      };

  RoutePlanningError _errorFor(String code) => switch (code) {
    'route_offline' => RoutePlanningError.offline,
    'route_throttled' => RoutePlanningError.throttled,
    'route_not_found' => RoutePlanningError.noRouteFound,
    'route_invalid_request' => RoutePlanningError.invalidRequest,
    _ => RoutePlanningError.serviceFailed,
  };
}

double _number(Object? value) => value is num ? value.toDouble() : 0;
