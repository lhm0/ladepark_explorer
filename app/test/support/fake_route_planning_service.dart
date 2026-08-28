import 'package:ladepark_explorer/features/route_planning/domain/models/route_option.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_request.dart';
import 'package:ladepark_explorer/features/route_planning/domain/route_planning_exception.dart';
import 'package:ladepark_explorer/features/route_planning/domain/route_planning_service.dart';

class FakeRoutePlanningService implements RoutePlanningService {
  FakeRoutePlanningService({this.options = const <RouteOption>[], this.error});

  List<RouteOption> options;
  RoutePlanningError? error;
  final List<RouteRequest> requests = <RouteRequest>[];

  @override
  Future<List<RouteOption>> planRoute(RouteRequest request) async {
    requests.add(request);
    final failure = error;
    if (failure != null) {
      throw RoutePlanningException(failure);
    }
    return options;
  }
}
