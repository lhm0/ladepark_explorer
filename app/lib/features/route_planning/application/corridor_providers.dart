import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/features/explorer/application/explorer_providers.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_summary.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/domain/route_corridor.dart';

/// Progress and result of the route corridor search (FR-ROUTE-003).
class CorridorState {
  const CorridorState({
    this.isSearching = false,
    this.hasSearched = false,
    this.done = 0,
    this.total = 0,
    this.parks = const <ChargingGroupSummary>[],
    this.limitReached = false,
    this.failed = false,
    this.widthKm = CorridorController.defaultCorridorWidthKm,
  });

  final bool isSearching;
  final bool hasSearched;
  final int done;
  final int total;
  final List<ChargingGroupSummary> parks;

  /// Total width of the corridor searched around the route, in kilometres
  /// (FR-ROUTE-003). The radius queried around each sample point is half of it.
  final int widthKm;

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
    List<ChargingGroupSummary>? parks,
    bool? limitReached,
    bool? failed,
    int? widthKm,
  }) => CorridorState(
    isSearching: isSearching ?? this.isSearching,
    hasSearched: hasSearched ?? this.hasSearched,
    done: done ?? this.done,
    total: total ?? this.total,
    parks: parks ?? this.parks,
    limitReached: limitReached ?? this.limitReached,
    failed: failed ?? this.failed,
    widthKm: widthKm ?? this.widthKm,
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

  /// Default total corridor width searched around the route, in kilometres
  /// (ADR-0022, adjustable per trip since the M16b follow-up).
  static const int defaultCorridorWidthKm = 20;

  /// Smallest and largest corridor width the user can pick, in kilometres.
  static const int minCorridorWidthKm = 20;
  static const int maxCorridorWidthKm = 60;

  int _run = 0;

  /// Sets the corridor width in kilometres for the next search, clamped to the
  /// supported range and rounded to the 10 km step.
  void setWidthKm(int widthKm) {
    final stepped = (widthKm / 10).round() * 10;
    state = state.copyWith(
      widthKm: stepped.clamp(minCorridorWidthKm, maxCorridorWidthKm),
    );
  }

  Future<void> search(List<GeoCoordinate> polyline) async {
    final run = ++_run;
    final widthKm = state.widthKm;
    final samples = sampleAlongPolyline(polyline, spacingKm: sampleSpacingKm);
    if (samples.length < 2) {
      state = CorridorState(hasSearched: true, widthKm: widthKm);
      return;
    }
    state = CorridorState(
      isSearching: true,
      total: samples.length,
      widthKm: widthKm,
    );

    final explorer = ref.read(explorerMapControllerProvider.notifier);
    final byId = <String, ChargingGroupSummary>{};
    var limitReached = false;
    var failed = false;

    for (var index = 0; index < samples.length; index++) {
      try {
        final groups = await explorer.findGroupsNear(
          samples[index],
          radiusKm: widthKm / 2,
        );
        if (groups.length >= 500) limitReached = true;
        for (final group in groups) {
          byId.putIfAbsent(group.groupId, () => group);
        }
      } on Object {
        failed = true;
      }
      if (run != _run) return;
      state = state.copyWith(done: index + 1);
    }

    final parks = byId.values.toList()
      ..sort((a, b) => a.groupId.compareTo(b.groupId));
    state = CorridorState(
      hasSearched: true,
      done: samples.length,
      total: samples.length,
      parks: parks,
      limitReached: limitReached,
      failed: failed,
      widthKm: widthKm,
    );
  }

  void clear() {
    _run++;
    // Keep the chosen corridor width; it is a user preference for the session.
    state = CorridorState(widthKm: state.widthKm);
  }
}
