import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_request.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_waypoint.dart';
import 'package:ladepark_explorer/features/route_planning/domain/route_planning_exception.dart';
import 'package:ladepark_explorer/platform/route/mkdirections_route_planning_service.dart';

// Platform message contract for FR-ROUTE-001 and NFR-ROUTE-OFFLINE-001.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('test/route');
  const request = RouteRequest(
    origin: RouteWaypoint(
      coordinate: GeoCoordinate(latitude: 52.52, longitude: 13.40),
      label: 'Berlin',
    ),
    destination: RouteWaypoint(
      coordinate: GeoCoordinate(latitude: 48.14, longitude: 11.58),
    ),
    intermediateWaypoints: <RouteWaypoint>[
      RouteWaypoint(
        coordinate: GeoCoordinate(latitude: 50.11, longitude: 8.68),
      ),
    ],
  );

  void mock(Future<Object?>? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
  }

  test(
    'sends origin, destination and waypoints and parses the option',
    () async {
      MethodCall? received;
      mock((call) async {
        received = call;
        return <Object?>[
          <String, Object?>{
            'totalDistanceKm': 585.4,
            'totalTravelTimeSeconds': 19800,
            'bounds': <String, Object?>{
              'south': 48.1,
              'west': 8.6,
              'north': 52.6,
              'east': 13.5,
            },
            'polyline': <Object?>[
              <String, Object?>{'latitude': 52.52, 'longitude': 13.40},
              <String, Object?>{'latitude': 48.14, 'longitude': 11.58},
            ],
            'legs': <Object?>[
              <String, Object?>{
                'startLatitude': 52.52,
                'startLongitude': 13.40,
                'endLatitude': 50.11,
                'endLongitude': 8.68,
                'distanceKm': 300.0,
                'travelTimeSeconds': 10800,
              },
            ],
          },
        ];
      });

      final options = await const MkDirectionsRoutePlanningService(
        channel: channel,
      ).planRoute(request);

      expect(received?.method, 'planRoute');
      final arguments = received!.arguments as Map<Object?, Object?>;
      expect(arguments['origin'], <String, Object?>{
        'latitude': 52.52,
        'longitude': 13.40,
      });
      expect(arguments['destination'], <String, Object?>{
        'latitude': 48.14,
        'longitude': 11.58,
      });
      expect(
        (arguments['waypoints'] as List<Object?>).single,
        <String, Object?>{'latitude': 50.11, 'longitude': 8.68},
      );
      expect(arguments['includeAlternatives'], isTrue);

      expect(options, hasLength(1));
      final option = options.single;
      expect(option.totalDistanceKm, 585.4);
      expect(option.totalTravelTime, const Duration(seconds: 19800));
      expect(option.polyline, hasLength(2));
      expect(option.boundingBox.north, 52.6);
      expect(option.legs.single.distanceKm, 300.0);
    },
  );

  test(
    'maps the offline platform error to RoutePlanningError.offline',
    () async {
      mock((call) async {
        throw PlatformException(code: 'route_offline');
      });

      await expectLater(
        const MkDirectionsRoutePlanningService(
          channel: channel,
        ).planRoute(request),
        throwsA(
          isA<RoutePlanningException>().having(
            (exception) => exception.error,
            'error',
            RoutePlanningError.offline,
          ),
        ),
      );
    },
  );

  test('maps a throttling error', () async {
    mock((call) async {
      throw PlatformException(code: 'route_throttled');
    });

    await expectLater(
      const MkDirectionsRoutePlanningService(
        channel: channel,
      ).planRoute(request),
      throwsA(
        isA<RoutePlanningException>().having(
          (exception) => exception.error,
          'error',
          RoutePlanningError.throttled,
        ),
      ),
    );
  });

  test('treats an empty response as noRouteFound', () async {
    mock((call) async => <Object?>[]);

    await expectLater(
      const MkDirectionsRoutePlanningService(
        channel: channel,
      ).planRoute(request),
      throwsA(
        isA<RoutePlanningException>().having(
          (exception) => exception.error,
          'error',
          RoutePlanningError.noRouteFound,
        ),
      ),
    );
  });
}
