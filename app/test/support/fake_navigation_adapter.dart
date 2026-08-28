import 'package:ladepark_explorer/platform/navigation/navigation_adapter.dart';

class FakeNavigationAdapter implements NavigationAdapter {
  FakeNavigationAdapter({this.available = true});

  final bool available;
  NavigationRoute? lastRoute;
  int openRouteCount = 0;

  /// Overrides the handoff returned by [openRoute]; defaults to "all stops
  /// included".
  NavigationHandoff? handoffOverride;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> openDirections({
    required double latitude,
    required double longitude,
    String? name,
  }) async {}

  @override
  Future<NavigationHandoff> openRoute(NavigationRoute route) async {
    lastRoute = route;
    openRouteCount++;
    return handoffOverride ??
        NavigationHandoff(
          includedStops: route.stops.length,
          totalStops: route.stops.length,
        );
  }
}
