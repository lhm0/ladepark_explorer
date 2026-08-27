import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_detail.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_query.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_summary.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/explorer_filters.dart';
import 'package:ladepark_explorer/features/explorer/domain/repositories/charging_repository.dart';

typedef FindGroupsHandler =
    Future<List<ChargingGroupSummary>> Function(ChargingGroupQuery query);

final class FakeChargingRepository implements ChargingRepository {
  FakeChargingRepository({
    this.groups = const <ChargingGroupSummary>[],
    this.detail,
    this.findGroupsHandler,
    this.filterOptions = const ChargingFilterOptions(),
  });

  final List<ChargingGroupSummary> groups;
  final ChargingGroupDetail? detail;
  final FindGroupsHandler? findGroupsHandler;
  final ChargingFilterOptions filterOptions;
  final List<ChargingGroupQuery> queries = <ChargingGroupQuery>[];
  final List<String> detailRequests = <String>[];

  @override
  Future<List<ChargingGroupSummary>> findGroups(
    ChargingGroupQuery query,
  ) async {
    queries.add(query);
    if (findGroupsHandler != null) {
      return findGroupsHandler!(query);
    }
    return groups;
  }

  @override
  Future<ChargingGroupDetail?> getGroupDetail(String groupId) async {
    detailRequests.add(groupId);
    return detail;
  }

  @override
  Future<ChargingGroupDetail?> getGroupDetailContainingStation(
    String stationId,
    int diameterM,
  ) async => detail;

  @override
  Future<ChargingFilterOptions> getFilterOptions() async => filterOptions;

  @override
  Future<List<OperatorFilterOption>> getPopularOperators({
    int limit = 20,
  }) async => const [];

  @override
  Future<List<OperatorFilterOption>> searchOperators(
    String text, {
    int limit = 50,
  }) async => const [];
}
