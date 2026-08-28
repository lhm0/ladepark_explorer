import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/features/route_planning/application/route_planning_providers.dart';
import 'package:ladepark_explorer/features/route_planning/application/route_planning_state.dart';
import 'package:ladepark_explorer/features/route_planning/presentation/route_format.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';
import 'package:ladepark_explorer/platform/maps/mapkit_map_view.dart';

/// Result handed back to the map screen.
enum RoutePreviewResult { newRoute }

/// Opaque full-screen route preview (FR-ROUTE-001, FR-ROUTE-002).
///
/// Per ADR-0011 no Flutter surface is composited over the native map. The map
/// and the alternative selector are non-overlapping siblings in a [Column]: the
/// map fills the space above a static panel that never changes size and is
/// never inserted or removed. The map widget instance is cached so panel
/// updates do not rebuild the platform view (ADR-0019 Nachtrag, flutter#62717).
class RoutePreviewPage extends ConsumerStatefulWidget {
  const RoutePreviewPage({super.key});

  @override
  ConsumerState<RoutePreviewPage> createState() => _RoutePreviewPageState();
}

class _RoutePreviewPageState extends ConsumerState<RoutePreviewPage> {
  MapKitAdapter? _mapAdapter;
  Widget? _mapView;

  @override
  void dispose() {
    unawaited(_mapAdapter?.dispose());
    super.dispose();
  }

  void _onMapCreated(MapKitAdapter adapter) {
    unawaited(_attachAdapter(adapter));
  }

  Future<void> _attachAdapter(MapKitAdapter adapter) async {
    final previous = _mapAdapter;
    _mapAdapter = adapter;
    await previous?.dispose();
    if (!mounted) {
      await adapter.dispose();
      _mapAdapter = null;
      return;
    }
    final option = ref.read(routePlanningControllerProvider).selectedOption;
    if (option != null) {
      await adapter.showRoute(option.polyline);
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
      if (option != null && !identical(option, previous?.selectedOption)) {
        unawaited(_mapAdapter?.showRoute(option.polyline));
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

class _RouteSelectorPanel extends StatelessWidget {
  const _RouteSelectorPanel({
    required this.state,
    required this.onSelect,
    required this.onShowOnMap,
    required this.onNewRoute,
    required this.onClear,
  });

  final RoutePlanningState state;
  final ValueChanged<int> onSelect;
  final VoidCallback onShowOnMap;
  final VoidCallback onNewRoute;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final option = state.selectedOption!;
    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                ],
              ),
              if (state.options.length > 1) ...[
                const SizedBox(height: 4),
                Text(
                  strings.routeAlternativesHeading,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                for (var index = 0; index < state.options.length; index++)
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
              ],
              const SizedBox(height: 12),
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
