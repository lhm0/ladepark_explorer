import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/features/route_planning/application/route_planning_state.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_request.dart';
import 'package:ladepark_explorer/features/route_planning/domain/route_planning_exception.dart';
import 'package:ladepark_explorer/features/route_planning/domain/route_planning_service.dart';
import 'package:ladepark_explorer/platform/route/mkdirections_route_planning_service.dart';

final routePlanningServiceProvider = Provider<RoutePlanningService>(
  (ref) => const MkDirectionsRoutePlanningService(),
);

final routePlanningControllerProvider =
    NotifierProvider<RoutePlanningController, RoutePlanningState>(
      RoutePlanningController.new,
    );

/// Coordinates route calculation and alternative selection (FR-ROUTE-001,
/// FR-ROUTE-002, NFR-ROUTE-OFFLINE-001). The selected route is drawn natively
/// on the map by the map screen.
final class RoutePlanningController extends Notifier<RoutePlanningState> {
  @override
  RoutePlanningState build() => const RoutePlanningState();

  Future<void> planRoute(RouteRequest request) async {
    state = state.copyWith(
      isCalculating: true,
      clearError: true,
      request: request,
    );
    try {
      final options = await ref
          .read(routePlanningServiceProvider)
          .planRoute(request);
      if (options.isEmpty) {
        state = state.copyWith(
          isCalculating: false,
          error: RoutePlanningError.noRouteFound,
        );
        return;
      }
      state = RoutePlanningState(options: options, request: request);
    } on RoutePlanningException catch (exception) {
      state = state.copyWith(isCalculating: false, error: exception.error);
    } on Object {
      state = state.copyWith(
        isCalculating: false,
        error: RoutePlanningError.serviceFailed,
      );
    }
  }

  Future<void> retry() async {
    final request = state.request;
    if (request != null) {
      await planRoute(request);
    }
  }

  void selectAlternative(int index) {
    if (index < 0 ||
        index >= state.options.length ||
        index == state.selectedIndex) {
      return;
    }
    state = state.copyWith(selectedIndex: index);
  }

  void clear() => state = const RoutePlanningState();
}
