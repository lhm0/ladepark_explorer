import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_detail.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_query.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_summary.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/explorer_filters.dart';

abstract interface class ChargingRepository {
  Future<List<ChargingGroupSummary>> findGroups(ChargingGroupQuery query);

  Future<ChargingGroupDetail?> getGroupDetail(String groupId);

  Future<ChargingGroupDetail?> getGroupDetailContainingStation(
    String stationId,
    int diameterM,
  );

  Future<ChargingFilterOptions> getFilterOptions();

  Future<List<OperatorFilterOption>> getPopularOperators({int limit = 20});

  Future<List<OperatorFilterOption>> searchOperators(
    String text, {
    int limit = 50,
  });
}
