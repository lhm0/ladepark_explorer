import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_summary.dart';
import 'package:ladepark_explorer/features/route_planning/application/corridor_providers.dart';
import 'package:ladepark_explorer/features/route_planning/application/energy_providers.dart';
import 'package:ladepark_explorer/features/route_planning/application/route_planning_providers.dart';
import 'package:ladepark_explorer/features/route_planning/application/route_planning_state.dart';
import 'package:ladepark_explorer/features/route_planning/application/vehicle_profile_providers.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_stop.dart';
import 'package:ladepark_explorer/features/route_planning/domain/trip_energy_simulator.dart';
import 'package:ladepark_explorer/features/route_planning/presentation/route_format.dart';
import 'package:ladepark_explorer/features/route_planning/presentation/route_soc_colour.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';
import 'package:ladepark_explorer/platform/maps/map_adapter.dart';
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
  final List<StreamSubscription<String>> _tapSubscriptions =
      <StreamSubscription<String>>[];
  Widget? _mapView;
  String? _lastRenderKey;
  bool _fittedOnce = false;

  @override
  void dispose() {
    for (final subscription in _tapSubscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_mapAdapter?.dispose());
    super.dispose();
  }

  void _onMapCreated(MapKitAdapter adapter) {
    unawaited(_attachAdapter(adapter));
  }

  Future<void> _attachAdapter(MapKitAdapter adapter) async {
    final previous = _mapAdapter;
    final previousSubscriptions = List<StreamSubscription<String>>.of(
      _tapSubscriptions,
    );
    _mapAdapter = adapter;
    _tapSubscriptions
      ..clear()
      ..add(adapter.selectedCorridorParkIds.listen(widget.onOpenDetail))
      ..add(adapter.selectedRouteStopIds.listen(widget.onOpenDetail));
    for (final subscription in previousSubscriptions) {
      await subscription.cancel();
    }
    await previous?.dispose();
    if (!mounted) {
      await adapter.dispose();
      _mapAdapter = null;
      return;
    }
    _lastRenderKey = null;
    _fittedOnce = false;
    _syncMap();
  }

  /// Reconciles the native map (route colours, stop markers, corridor markers)
  /// with the current state. Driven from [build], so it also runs when the page
  /// is revealed after the detail sheet pops.
  void _syncMap() {
    final adapter = _mapAdapter;
    if (adapter == null || !mounted) return;
    final planning = ref.read(routePlanningControllerProvider);
    final option = planning.selectedOption;
    if (option == null) return;
    final colours = _segmentColours();
    final stops = _stopMarkers(planning.stops);
    final corridor = _corridorParks();
    final key =
        '${option.polyline.length}'
        '|${colours?.join(',') ?? ''}'
        '|${stops.map((stop) => stop.id).join(',')}'
        '|${corridor.map((park) => park.groupId).join(',')}';
    if (key == _lastRenderKey) return;
    _lastRenderKey = key;
    unawaited(
      adapter.showRoute(
        option.polyline,
        segmentColorsArgb: colours,
        fitToRoute: !_fittedOnce,
      ),
    );
    _fittedOnce = true;
    unawaited(adapter.showRouteStops(stops));
    unawaited(adapter.showRouteCorridor(corridor));
  }

  List<int>? _segmentColours() {
    final energy = ref.read(tripEnergyProfileProvider);
    if (energy == null || energy.socPercentByPoint.length < 2) return null;
    final soc = energy.socPercentByPoint;
    return <int>[
      for (var i = 0; i < soc.length - 1; i++)
        socColourArgb(
          (soc[i] + soc[i + 1]) / 2,
          reservePercent: energy.reservePercent,
        ),
    ];
  }

  List<RouteStopMarker> _stopMarkers(List<RouteStop> stops) => stops
      .map((stop) => (id: stop.groupId, coordinate: stop.coordinate))
      .toList(growable: false);

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
    // Watched so a change to any of these rebuilds the page and re-syncs the
    // native map, even while the detail sheet still covers this page.
    ref.watch(tripEnergyProfileProvider);
    ref.watch(corridorControllerProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncMap());

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
          height: 288,
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
                      if (state.error case final error?) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                routeErrorMessage(strings, error),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => ref
                                  .read(
                                    routePlanningControllerProvider.notifier,
                                  )
                                  .retry(),
                              child: Text(strings.routeRetry),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
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
                      _ValueStepper(
                        key: const ValueKey('stepper-corridor-width'),
                        icon: Icons.swap_horiz,
                        label: strings.routeCorridorWidthLabel,
                        value: corridor.widthKm,
                        unit: 'km',
                        step: 10,
                        min: CorridorController.minCorridorWidthKm,
                        max: CorridorController.maxCorridorWidthKm,
                        onChanged: corridor.isSearching
                            ? null
                            : (value) => ref
                                  .read(corridorControllerProvider.notifier)
                                  .setWidthKm(value),
                      ),
                      const SizedBox(height: 4),
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
                      _EnergyStatus(state: state),
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

class _EnergyStatus extends ConsumerWidget {
  const _EnergyStatus({required this.state});

  final RoutePlanningState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final profile = ref.watch(vehicleProfileControllerProvider).value;
    if (profile == null || !profile.isComplete) {
      return const SizedBox.shrink();
    }
    final energy = ref.watch(tripEnergyProfileProvider);
    final notifier = ref.read(routePlanningControllerProvider.notifier);
    final startSoc =
        state.tripStartSocPercent ?? profile.defaultStartSocPercent;
    final chargeTarget =
        state.tripChargeTargetSocPercent ?? kDefaultChargeTargetSocPercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ValueStepper(
          key: const ValueKey('stepper-start-soc'),
          icon: Icons.battery_charging_full_outlined,
          label: strings.routeStartSocLabel,
          value: startSoc,
          unit: '%',
          onChanged: (value) => notifier.setTripStartSoc(value),
        ),
        _ValueStepper(
          key: const ValueKey('stepper-charge-target'),
          icon: Icons.battery_charging_full_outlined,
          label: strings.routeChargeTargetLabel,
          value: chargeTarget,
          unit: '%',
          onChanged: (value) => notifier.setTripChargeTargetSoc(value),
        ),
        if (energy != null) ...[
          const SizedBox(height: 2),
          Text(
            _socBreakdown(strings, energy, startSoc),
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
        if (energy?.deficitKm case final deficitKm?)
          Text(
            strings.routeRangeDeficit(deficitKm.round()),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  /// A compact, human-readable trace of the estimated state of charge so a
  /// tester can see the value reset at every stop (FR-ROUTE-006).
  String _socBreakdown(
    AppLocalizations strings,
    TripEnergyProfile energy,
    int startSoc,
  ) {
    final parts = <String>[strings.routeSocBreakdownStart(startSoc)];
    for (var i = 0; i < energy.stopSocs.length; i++) {
      final stop = energy.stopSocs[i];
      parts.add(
        strings.routeSocBreakdownStop(
          i + 1,
          stop.arrivalSocPercent.round(),
          stop.departureSocPercent.round(),
        ),
      );
    }
    parts.add(
      strings.routeSocBreakdownTarget(energy.socPercentByPoint.last.round()),
    );
    return parts.join('  ·  ');
  }
}

/// A compact "− value + " row shared by the start-SoC, charge-target and
/// corridor-width controls.
class _ValueStepper extends StatelessWidget {
  const _ValueStepper({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.onChanged,
    this.step = 5,
    this.min = 0,
    this.max = 100,
    super.key,
  });

  final IconData icon;
  final String label;
  final int value;
  final String unit;
  final ValueChanged<int>? onChanged;
  final int step;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final changed = onChanged;
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: changed == null || value <= min
              ? null
              : () => changed((value - step).clamp(min, max)),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        Text('$value $unit'),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: changed == null || value >= max
              ? null
              : () => changed((value + step).clamp(min, max)),
          icon: const Icon(Icons.add_circle_outline),
        ),
      ],
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
