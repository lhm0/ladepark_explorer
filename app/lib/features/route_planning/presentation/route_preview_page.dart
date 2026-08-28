import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_summary.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/application/corridor_providers.dart';
import 'package:ladepark_explorer/features/route_planning/application/route_planning_providers.dart';
import 'package:ladepark_explorer/features/route_planning/application/route_planning_state.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_stop.dart';
import 'package:ladepark_explorer/features/route_planning/presentation/route_format.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';
import 'package:ladepark_explorer/platform/maps/mapkit_map_view.dart';

/// Result handed back to the map screen.
enum RoutePreviewResult { newRoute }

/// Opaque full-screen route preview (FR-ROUTE-001..004).
///
/// Per ADR-0011 no Flutter surface is composited over the native map. The map
/// and the selector are non-overlapping siblings in a [Column]: the map fills a
/// fixed remaining space above a panel of constant height. The corridor parks
/// and the chosen stops are drawn as native markers on this screen's own map;
/// tapping a corridor marker opens the park detail with an "insert stop"
/// action. The map widget instance is cached so panel updates do not rebuild
/// the platform view (ADR-0019 Nachtrag, flutter#62717).
class RoutePreviewPage extends ConsumerStatefulWidget {
  const RoutePreviewPage({required this.onOpenDetail, super.key});

  /// Opens the park detail (with the "insert stop" action) for a corridor
  /// marker the user tapped.
  final Future<void> Function(String groupId) onOpenDetail;

  @override
  ConsumerState<RoutePreviewPage> createState() => _RoutePreviewPageState();
}

class _RoutePreviewPageState extends ConsumerState<RoutePreviewPage> {
  MapKitAdapter? _mapAdapter;
  StreamSubscription<String>? _corridorTapSubscription;
  Widget? _mapView;

  @override
  void dispose() {
    unawaited(_corridorTapSubscription?.cancel());
    unawaited(_mapAdapter?.dispose());
    super.dispose();
  }

  void _onMapCreated(MapKitAdapter adapter) {
    unawaited(_attachAdapter(adapter));
  }

  Future<void> _attachAdapter(MapKitAdapter adapter) async {
    final previous = _mapAdapter;
    final previousSubscription = _corridorTapSubscription;
    _mapAdapter = adapter;
    _corridorTapSubscription = adapter.selectedCorridorParkIds.listen(
      widget.onOpenDetail,
    );
    await previousSubscription?.cancel();
    await previous?.dispose();
    if (!mounted) {
      await adapter.dispose();
      _mapAdapter = null;
      return;
    }
    await _redraw(adapter);
  }

  Future<void> _redraw(MapKitAdapter adapter) async {
    final state = ref.read(routePlanningControllerProvider);
    final option = state.selectedOption;
    if (option == null) return;
    await adapter.showRoute(option.polyline);
    await adapter.showRouteStops(_stopCoordinates(state.stops));
    await adapter.showRouteCorridor(_corridorParks());
  }

  List<GeoCoordinate> _stopCoordinates(List<RouteStop> stops) =>
      stops.map((stop) => stop.coordinate).toList(growable: false);

  List<ChargingGroupSummary> _corridorParks() {
    final stopIds = ref
        .read(routePlanningControllerProvider)
        .stops
        .map((stop) => stop.groupId)
        .toSet();
    return ref
        .read(corridorControllerProvider)
        .parks
        .where((park) => !stopIds.contains(park.groupId))
        .toList(growable: false);
  }

  void _searchCorridor() {
    final option = ref.read(routePlanningControllerProvider).selectedOption;
    if (option != null) {
      unawaited(
        ref.read(corridorControllerProvider.notifier).search(option.polyline),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(routePlanningControllerProvider);

    ref.listen<RoutePlanningState>(routePlanningControllerProvider, (
      previous,
      next,
    ) {
      final option = next.selectedOption;
      if (option == null) return;
      final routeChanged = !identical(option, previous?.selectedOption);
      final stopsChanged = !identical(next.stops, previous?.stops);
      if (routeChanged) {
        unawaited(_mapAdapter?.showRoute(option.polyline));
      }
      if (routeChanged || stopsChanged) {
        unawaited(_mapAdapter?.showRouteStops(_stopCoordinates(next.stops)));
        unawaited(_mapAdapter?.showRouteCorridor(_corridorParks()));
      }
    });
    ref.listen<CorridorState>(corridorControllerProvider, (previous, next) {
      if (!identical(next.parks, previous?.parks)) {
        unawaited(_mapAdapter?.showRouteCorridor(_corridorParks()));
      }
    });

    _mapView ??= Semantics(
      label: strings.routeMapSemantics,
      child: MapKitMapView(
        unavailableLabel: strings.mapUnavailable,
        onMapCreated: _onMapCreated,
        eagerGestures: false,
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(strings.routeOverviewTitle)),
      body: state.selectedOption == null
          ? Center(child: Text(strings.routeErrorFailed))
          : Column(
              children: [
                Expanded(child: _mapView!),
                _RouteSelectorPanel(
                  state: state,
                  onSelect: ref
                      .read(routePlanningControllerProvider.notifier)
                      .selectAlternative,
                  onSearchCorridor: _searchCorridor,
                  onShowOnMap: () => Navigator.of(context).pop(),
                  onNewRoute: () =>
                      Navigator.of(context).pop(RoutePreviewResult.newRoute),
                  onClear: () {
                    ref.read(routePlanningControllerProvider.notifier).clear();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
    );
  }
}

class _RouteSelectorPanel extends ConsumerWidget {
  const _RouteSelectorPanel({
    required this.state,
    required this.onSelect,
    required this.onSearchCorridor,
    required this.onShowOnMap,
    required this.onNewRoute,
    required this.onClear,
  });

  final RoutePlanningState state;
  final ValueChanged<int> onSelect;
  final VoidCallback onSearchCorridor;
  final VoidCallback onShowOnMap;
  final VoidCallback onNewRoute;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final option = state.selectedOption!;
    final corridor = ref.watch(corridorControllerProvider);
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 220,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_car_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        strings.routeSummary(
                          formatRouteDistance(strings, option.totalDistanceKm),
                          formatRouteDuration(strings, option.totalTravelTime),
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (state.isCalculating)
                      const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (state.options.length > 1) ...[
                        Text(
                          strings.routeAlternativesHeading,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        for (
                          var index = 0;
                          index < state.options.length;
                          index++
                        )
                          _AlternativeRow(
                            key: ValueKey('route-alternative-$index'),
                            label: strings.routeOptionLabel(index + 1),
                            summary: strings.routeSummary(
                              formatRouteDistance(
                                strings,
                                state.options[index].totalDistanceKm,
                              ),
                              formatRouteDuration(
                                strings,
                                state.options[index].totalTravelTime,
                              ),
                            ),
                            selected: index == state.selectedIndex,
                            onTap: () => onSelect(index),
                          ),
                        const SizedBox(height: 4),
                      ],
                      OutlinedButton.icon(
                        onPressed: corridor.isSearching
                            ? null
                            : onSearchCorridor,
                        icon: const Icon(Icons.ev_station_outlined),
                        label: Text(strings.routeCorridorTitle),
                      ),
                      const SizedBox(height: 6),
                      _CorridorStatus(corridor: corridor),
                      const SizedBox(height: 2),
                      Text(
                        strings.routeStopsCount(state.stops.length),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onShowOnMap,
                        icon: const Icon(Icons.map_outlined),
                        label: Text(strings.routeShowOnMap),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: onNewRoute,
                      tooltip: strings.routeNewRoute,
                      icon: const Icon(Icons.add_road_outlined),
                    ),
                    const SizedBox(width: 8),
                    IconButton.outlined(
                      onPressed: onClear,
                      tooltip: strings.routeClear,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CorridorStatus extends StatelessWidget {
  const _CorridorStatus({required this.corridor});

  final CorridorState corridor;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.bodySmall;
    if (corridor.isSearching) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: corridor.progress),
          const SizedBox(height: 4),
          Text(
            strings.routeCorridorSearching(corridor.done, corridor.total),
            style: style,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    if (!corridor.hasSearched) {
      return const SizedBox.shrink();
    }
    final message = corridor.parks.isEmpty
        ? strings.routeCorridorEmpty
        : strings.routeCorridorCount(corridor.parks.length);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message, style: style, textAlign: TextAlign.center),
        if (corridor.limitReached)
          Text(
            strings.routeCorridorLimit,
            style: style?.copyWith(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
        if (corridor.failed)
          Text(
            strings.routeCorridorFailed,
            style: style?.copyWith(color: Theme.of(context).colorScheme.error),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

class _AlternativeRow extends StatelessWidget {
  const _AlternativeRow({
    required this.label,
    required this.summary,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final String summary;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? colors.primary : colors.outline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$label  ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: summary),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
