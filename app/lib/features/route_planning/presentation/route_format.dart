import 'package:ladepark_explorer/features/route_planning/domain/route_planning_exception.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';

/// Formats a driving distance for display, e.g. `12.3 km` or `248 km`.
String formatRouteDistance(AppLocalizations strings, double kilometres) {
  final value = kilometres >= 100
      ? kilometres.round().toString()
      : kilometres.toStringAsFixed(1);
  return strings.routeDistanceKm(value);
}

/// Formats a travel time as `2 h 40 min` or `45 min`.
String formatRouteDuration(AppLocalizations strings, Duration duration) {
  final totalMinutes = duration.inMinutes;
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return hours == 0
      ? strings.routeDurationMinutes(minutes)
      : strings.routeDurationHoursMinutes(hours, minutes);
}

/// Maps a [RoutePlanningError] to a localized, user-facing message.
String routeErrorMessage(AppLocalizations strings, RoutePlanningError error) =>
    switch (error) {
      RoutePlanningError.offline => strings.routeErrorOffline,
      RoutePlanningError.throttled => strings.routeErrorThrottled,
      RoutePlanningError.noRouteFound => strings.routeErrorNotFound,
      RoutePlanningError.invalidRequest => strings.routeErrorInvalid,
      RoutePlanningError.serviceFailed => strings.routeErrorFailed,
    };
