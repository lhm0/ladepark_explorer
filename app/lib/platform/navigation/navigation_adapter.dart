/// One point handed to a navigation app.
class NavigationWaypoint {
  const NavigationWaypoint({
    required this.latitude,
    required this.longitude,
    this.name,
  });

  final double latitude;
  final double longitude;
  final String? name;
}

/// The planned route handed to a navigation app: start, ordered charging stops
/// and destination (FR-ROUTE-011).
class NavigationRoute {
  const NavigationRoute({
    required this.origin,
    required this.destination,
    this.stops = const <NavigationWaypoint>[],
  });

  final NavigationWaypoint origin;
  final NavigationWaypoint destination;
  final List<NavigationWaypoint> stops;
}

/// What a navigation app actually accepted from a [NavigationRoute].
class NavigationHandoff {
  const NavigationHandoff({
    required this.includedStops,
    required this.totalStops,
  });

  /// Number of charging stops passed to the app.
  final int includedStops;

  /// Number of charging stops in the plan.
  final int totalStops;

  /// True when the app could not take every stop and the plan was shortened.
  bool get truncated => includedStops < totalStops;
}

abstract interface class NavigationAdapter {
  Future<bool> isAvailable();

  /// Opens driving directions to a single destination.
  Future<void> openDirections({
    required double latitude,
    required double longitude,
    String? name,
  });

  /// Opens driving directions for the whole planned route. Stops beyond what
  /// the target app supports are dropped; the result says how many were kept.
  Future<NavigationHandoff> openRoute(NavigationRoute route);
}
