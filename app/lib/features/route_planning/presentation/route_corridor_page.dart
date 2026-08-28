import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/route_planning/application/corridor_providers.dart';
import 'package:ladepark_explorer/features/route_planning/application/route_planning_providers.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/corridor_park.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_stop.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';

/// Opaque full-screen list of charging parks in the route corridor
/// (FR-ROUTE-003) with a per-park toggle to use it as a stop (FR-ROUTE-004).
class RouteCorridorPage extends ConsumerStatefulWidget {
  const RouteCorridorPage({required this.onOpenDetail, super.key});

  final void Function(String groupId) onOpenDetail;

  @override
  ConsumerState<RouteCorridorPage> createState() => _RouteCorridorPageState();
}

class _RouteCorridorPageState extends ConsumerState<RouteCorridorPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _searchIfNeeded());
  }

  void _searchIfNeeded() {
    final corridor = ref.read(corridorControllerProvider);
    if (corridor.isSearching || corridor.hasSearched) return;
    _search();
  }

  void _search() {
    final option = ref.read(routePlanningControllerProvider).selectedOption;
    if (option != null) {
      ref.read(corridorControllerProvider.notifier).search(option.polyline);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final corridor = ref.watch(corridorControllerProvider);
    final planning = ref.watch(routePlanningControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.routeCorridorTitle),
        actions: [
          if (!corridor.isSearching)
            IconButton(
              onPressed: _search,
              tooltip: strings.routeCorridorRetry,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
      body: Column(
        children: [
          if (corridor.isSearching)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: corridor.progress),
                  const SizedBox(height: 8),
                  Text(
                    strings.routeCorridorSearching(
                      corridor.done,
                      corridor.total,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          if (!corridor.isSearching && corridor.limitReached)
            _Banner(text: strings.routeCorridorLimit),
          if (!corridor.isSearching && corridor.failed)
            _Banner(text: strings.routeCorridorFailed),
          Expanded(
            child: corridor.parks.isEmpty
                ? (corridor.isSearching
                      ? const SizedBox.shrink()
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              strings.routeCorridorEmpty,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ))
                : ListView.separated(
                    itemCount: corridor.parks.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final park = corridor.parks[index];
                      final group = park.group;
                      final isStop = planning.containsStop(group.groupId);
                      return ListTile(
                        title: Text(
                          group.name ??
                              group.city ??
                              strings.chargingParkDetails,
                        ),
                        subtitle: Text(
                          <String>[
                            strings.routeCorridorPosition(
                              park.positionKm.round(),
                            ),
                            strings.routeCorridorDetour(park.detourKm.round()),
                            strings.searchResultChargingPoints(group.evseCount),
                          ].join(' · '),
                        ),
                        onTap: () => widget.onOpenDetail(group.groupId),
                        trailing: Semantics(
                          label: isStop
                              ? strings.routeRemoveStop
                              : strings.routeAddStop,
                          child: Switch(
                            value: isStop,
                            onChanged: planning.isCalculating
                                ? null
                                : (value) => _toggleStop(park, value),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _toggleStop(CorridorPark park, bool asStop) {
    final notifier = ref.read(routePlanningControllerProvider.notifier);
    final group = park.group;
    if (asStop) {
      notifier.addStop(
        RouteStop(
          groupId: group.groupId,
          coordinate: GeoCoordinate(
            latitude: group.latitude,
            longitude: group.longitude,
          ),
          positionKm: park.positionKm,
          name: group.name ?? group.city,
        ),
      );
    } else {
      notifier.removeStop(group.groupId);
    }
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
