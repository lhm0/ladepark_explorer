import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/features/explorer/application/explorer_providers.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/corridor_park.dart';
import 'package:ladepark_explorer/features/route_planning/domain/route_corridor.dart';

/// Progress and result of the route corridor search (FR-ROUTE-003).
class CorridorState {
  const CorridorState({
    this.isSearching = false,
    this.hasSearched = false,
    this.done = 0,
    this.total = 0,
    this.parks = const <CorridorPark>[],
    this.limitReached = false,
    this.failed = false,
  });

  final bool isSearching;
  final bool hasSearched;
  final int done;
  final int total;
  final List<CorridorPark> parks;

  /// A sample query hit the 500-result cap, so the corridor may be incomplete.
  final bool limitReached;

  /// At least one sample query failed (for example while offline).
  final bool failed;

  double? get progress => total == 0 ? null : done / total;

  CorridorState copyWith({
    bool? isSearching,
    bool? hasSearched,
    int? done,
    int? total,
    List<CorridorPark>? parks,
    bool? limitReached,
    bool? failed,
  }) => CorridorState(
    isSearching: isSearching ?? this.isSearching,
    hasSearched: hasSearched ?? this.hasSearched,
    done: done ?? this.done,
    total: total ?? this.total,
    parks: parks ?? this.parks,
    limitReached: limitReached ?? this.limitReached,
    failed: failed ?? this.failed,
  );
}

final corridorControllerProvider =
    NotifierProvider<CorridorController, CorridorState>(CorridorController.new);

/// Samples the route polyline and runs the existing radius query at each point
/// (ADR-0022). Queries run sequentially in the charging isolate, honouring the
/// "one map query at a time" rule.
final class CorridorController extends Notifier<CorridorState> {
  @override
  CorridorState build() => const CorridorState();

  /// Distance between sample points along the route. ADR-0022.
  static const double sampleSpacingKm = 20;

  /// Half-width of the corridor searched around each sample point. ADR-0022.
  static const double corridorRadiusKm = 10;

  int _run = 0;

  Future<void> search(List<GeoCoordinate> polyline) async {
    final run = ++_run;
    final samples = sampleAlongPolyline(polyline, spacingKm: sampleSpacingKm);
    if (samples.length < 2) {
      state = const CorridorState(hasSearched: true);
      return;
    }
    state = CorridorState(isSearching: true, total: samples.length);

    final explorer = ref.read(explorerMapControllerProvider.notifier);
    final byId = <String, CorridorPark>{};
    var limitReached = false;
    var failed = false;

    for (var index = 0; index < samples.length; index++) {
      try {
        final groups = await explorer.findGroupsNear(
          samples[index],
          radiusKm: corridorRadiusKm,
        );
        if (groups.length >= 500) limitReached = true;
        for (final group in groups) {
          if (byId.containsKey(group.groupId)) continue;
          final point = GeoCoordinate(
            latitude: group.latitude,
            longitude: group.longitude,
          );
          byId[group.groupId] = CorridorPark(
            group: group,
            positionKm: positionAlongPolylineKm(polyline, point),
            detourKm: estimateDetourKm(polyline, point),
          );
        }
      } on Object {
        failed = true;
      }
      if (run != _run) return;
      state = state.copyWith(done: index + 1);
    }

    final parks = byId.values.toList()
      ..sort((a, b) => a.positionKm.compareTo(b.positionKm));
    state = CorridorState(
      hasSearched: true,
      done: samples.length,
      total: samples.length,
      parks: parks,
      limitReached: limitReached,
      failed: failed,
    );
  }

  void clear() {
    _run++;
    state = const CorridorState();
  }
}
