import 'package:ladepark_explorer/features/route_planning/domain/models/route_option.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_request.dart';
import 'package:ladepark_explorer/features/route_planning/domain/route_planning_exception.dart';

/// UI state of the route planning feature: the computed alternatives, which one
/// is selected, whether a calculation is running and the last error.
class RoutePlanningState {
  const RoutePlanningState({
    this.options = const <RouteOption>[],
    this.selectedIndex = 0,
    this.isCalculating = false,
    this.error,
    this.request,
  });

  final List<RouteOption> options;
  final int selectedIndex;
  final bool isCalculating;
  final RoutePlanningError? error;

  /// The last request, kept so the user can retry after an error.
  final RouteRequest? request;

  bool get hasRoute => options.isNotEmpty;

  RouteOption? get selectedOption => options.isEmpty
      ? null
      : options[selectedIndex.clamp(0, options.length - 1)];

  RoutePlanningState copyWith({
    List<RouteOption>? options,
    int? selectedIndex,
    bool? isCalculating,
    RoutePlanningError? error,
    bool clearError = false,
    RouteRequest? request,
  }) => RoutePlanningState(
    options: options ?? this.options,
    selectedIndex: selectedIndex ?? this.selectedIndex,
    isCalculating: isCalculating ?? this.isCalculating,
    error: clearError ? null : (error ?? this.error),
    request: request ?? this.request,
  );
}
