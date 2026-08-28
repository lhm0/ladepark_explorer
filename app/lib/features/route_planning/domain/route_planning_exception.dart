/// Stable failure categories for [RoutePlanningService], mirroring the
/// `ChargingRepositoryError` approach. Supports the clear offline, error and
/// throttling states required by NFR-ROUTE-OFFLINE-001.
enum RoutePlanningError {
  /// No network connection was available for the online route calculation.
  offline,

  /// The map service rejected the request because of rate limiting.
  throttled,

  /// The service returned no route for the given points.
  noRouteFound,

  /// The request was malformed, for example missing an origin or destination.
  invalidRequest,

  /// Any other failure of the route service or platform channel.
  serviceFailed,
}

class RoutePlanningException implements Exception {
  const RoutePlanningException(this.error, [this.message]);

  final RoutePlanningError error;
  final String? message;

  @override
  String toString() =>
      'RoutePlanningException(${error.name}${message == null ? '' : ': $message'})';
}
