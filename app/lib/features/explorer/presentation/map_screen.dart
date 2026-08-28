import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/features/explorer/application/explorer_map_state.dart';
import 'package:ladepark_explorer/features/explorer/application/explorer_providers.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/charging_group_detail.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/explorer_filters.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/location_search_target.dart';
import 'package:ladepark_explorer/features/explorer/domain/repositories/charging_repository_exception.dart';
import 'package:ladepark_explorer/features/explorer/presentation/filter_page.dart';
import 'package:ladepark_explorer/features/explorer/presentation/location_search_page.dart';
import 'package:ladepark_explorer/features/favorites/application/favorite_providers.dart';
import 'package:ladepark_explorer/features/favorites/presentation/favorites_page.dart';
import 'package:ladepark_explorer/features/park_info/application/park_information_providers.dart';
import 'package:ladepark_explorer/features/park_info/domain/models/park_information.dart';
import 'package:ladepark_explorer/features/route_planning/application/route_planning_providers.dart';
import 'package:ladepark_explorer/features/route_planning/application/route_planning_state.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_waypoint.dart';
import 'package:ladepark_explorer/features/route_planning/presentation/route_planning_page.dart';
import 'package:ladepark_explorer/features/route_planning/presentation/route_preview_page.dart';
import 'package:ladepark_explorer/features/settings/application/settings_providers.dart';
import 'package:ladepark_explorer/features/settings/domain/app_settings.dart';
import 'package:ladepark_explorer/features/settings/presentation/settings_page.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';
import 'package:ladepark_explorer/platform/inbound/inbound_location_adapter.dart';
import 'package:ladepark_explorer/platform/maps/mapkit_map_view.dart';
import 'package:ladepark_explorer/platform/navigation/navigation_providers.dart';
import 'package:ladepark_explorer/platform/search/mapkit_place_search_adapter.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  MapKitAdapter? _mapAdapter;
  StreamSubscription<Object?>? _boundsSubscription;
  StreamSubscription<Object?>? _selectionSubscription;
  bool _detailsOpen = false;
  InboundLocationAdapter? _inboundLocationAdapter;
  StreamSubscription<GeoCoordinate>? _inboundLocationSubscription;
  GeoCoordinate? _pendingExternalLocation;
  RouteWaypoint? _pendingRouteDestination;
  final MapKitPlaceSearchAdapter _placeSearchAdapter =
      const MapKitPlaceSearchAdapter();

  @override
  void initState() {
    super.initState();
    _inboundLocationAdapter = InboundLocationAdapter();
    _inboundLocationSubscription = _inboundLocationAdapter!.locations.listen(
      _showExternalLocation,
    );
    unawaited(
      _inboundLocationAdapter!
          .takePendingLocation()
          .then((location) {
            if (location != null) _showExternalLocation(location);
          })
          .onError<MissingPluginException>((_, _) => null),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final mapState = ref.watch(explorerMapControllerProvider);
    final filters = mapState.value?.filters ?? ExplorerFilters.defaults;
    ref.listen<AsyncValue<ExplorerMapState>>(explorerMapControllerProvider, (
      previous,
      next,
    ) {
      final groups = next.value?.groups;
      if (groups != null && groups != previous?.value?.groups) {
        unawaited(_mapAdapter?.showGroups(groups));
      }
    });
    ref.listen(favoritesControllerProvider, (previous, next) {
      final favorites = next.value;
      if (favorites == null || favorites == previous?.value) return;
      ref
          .read(explorerMapControllerProvider.notifier)
          .favoriteAnchorsChanged(
            favorites
                .map((item) => item.anchorStationId)
                .toList(growable: false),
          );
    });
    ref.listen<RoutePlanningState>(routePlanningControllerProvider, (
      previous,
      next,
    ) {
      final option = next.selectedOption;
      if (option == null) {
        unawaited(_mapAdapter?.clearRoute());
      } else if (!identical(option, previous?.selectedOption)) {
        unawaited(_mapAdapter?.showRoute(option.polyline));
      }
    });
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.appTitle),
        actions: [
          IconButton(
            onPressed: _openSettings,
            tooltip: strings.settings,
            icon: const Icon(Icons.settings_outlined),
          ),
          IconButton(
            onPressed: mapState.hasValue ? _openRoutePlanning : null,
            tooltip: strings.routePlanning,
            icon: const Icon(Icons.directions_outlined),
          ),
          IconButton(
            onPressed: mapState.hasValue ? _openFavorites : null,
            tooltip: strings.favorites,
            icon: const Icon(Icons.favorite_outline),
          ),
          IconButton(
            onPressed: mapState.hasValue ? _openSearch : null,
            tooltip: strings.search,
            icon: const Icon(Icons.search),
          ),
          Badge(
            isLabelVisible: !filters.isDefault,
            label: Text('${_activeFilterCount(filters)}'),
            child: IconButton(
              onPressed: mapState.hasValue ? _openFilters : null,
              tooltip: strings.filters,
              icon: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (mapState.hasValue)
            Positioned.fill(
              child: Semantics(
                label: strings.mapSemantics,
                child: MapKitMapView(
                  unavailableLabel: strings.mapUnavailable,
                  onMapCreated: _mapCreated,
                ),
              ),
            )
          else
            ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: const Center(child: CircularProgressIndicator()),
            ),
          if (mapState case AsyncData(value: final value)) ...[
            Positioned(top: 12, left: 12, child: _MapStatusChip(state: value)),
            if (value.error case final ChargingRepositoryError error)
              Positioned(
                left: 12,
                right: 12,
                bottom: 16,
                child: Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_repositoryError(strings, error)),
                  ),
                ),
              ),
          ],
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'germany-overview',
            onPressed: _mapAdapter == null
                ? null
                : () {
                    ref
                        .read(explorerMapControllerProvider.notifier)
                        .clearNearby();
                    unawaited(_mapAdapter!.showGermanyOverview());
                  },
            tooltip: strings.germanyOverview,
            child: const Icon(Icons.zoom_out_map),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'user-location',
            onPressed: _mapAdapter == null ? null : _showMyLocation,
            tooltip: strings.myLocation,
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }

  Future<void> _openSearch() async {
    final controller = ref.read(explorerMapControllerProvider.notifier);
    final target = await Navigator.of(context).push<LocationSearchTarget>(
      PageRouteBuilder<LocationSearchTarget>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) =>
            LocationSearchPage(resolvePlace: _resolvePlace),
      ),
    );
    if (target == null || !mounted) return;
    controller.clearNearby();
    await _mapAdapter?.focusCoordinate(
      target.center,
      radiusKm: target.radiusKm,
    );
  }

  Future<void> _openSettings() => Navigator.of(
    context,
  ).push<void>(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));

  Future<void> _openRoutePlanning() async {
    final hasRoute = ref.read(routePlanningControllerProvider).hasRoute;
    if (hasRoute && _pendingRouteDestination == null) {
      final result = await _openRoutePreview();
      if (result == RoutePreviewResult.newRoute && mounted) {
        await _openRoutePlanningInput();
      }
      return;
    }
    await _openRoutePlanningInput();
  }

  Future<void> _openRoutePlanningInput() async {
    final destination = _pendingRouteDestination;
    _pendingRouteDestination = null;
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) =>
            RoutePlanningPage(
              resolveEndpoint: _resolveRouteEndpoint,
              currentLocation: _currentLocationForRoute,
              initialDestination: destination,
            ),
      ),
    );
    if (mounted && ref.read(routePlanningControllerProvider).hasRoute) {
      await _openRoutePreview();
    }
  }

  Future<RoutePreviewResult?> _openRoutePreview() {
    return Navigator.of(context).push<RoutePreviewResult>(
      PageRouteBuilder<RoutePreviewResult>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const RoutePreviewPage(),
      ),
    );
  }

  Future<GeoCoordinate?> _resolveRouteEndpoint(String query) async {
    try {
      return await _placeSearchAdapter.geocodePlace(query);
    } on PlatformException {
      return null;
    }
  }

  Future<GeoCoordinate> _currentLocationForRoute() async {
    final adapter = _mapAdapter;
    if (adapter == null) {
      throw PlatformException(code: 'location_unavailable');
    }
    return adapter.focusUserLocation(radiusKm: 10);
  }

  Future<void> _openFavorites() async {
    final favorites = await ref.read(favoritesControllerProvider.future);
    if (!mounted) return;
    final controller = ref.read(explorerMapControllerProvider.notifier);
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) => FavoritesPage(
          favorites: favorites,
          resolve: controller.loadGroupContainingStation,
          remove: ref.read(favoritesControllerProvider.notifier).remove,
          open: (detail) async {
            await Navigator.of(context).push<void>(
              PageRouteBuilder<void>(
                opaque: true,
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                pageBuilder: (context, animation, secondaryAnimation) =>
                    GroupDetailPage(
                      future: Future<ChargingGroupDetail?>.value(detail),
                    ),
              ),
            );
            return ref
                .read(favoritesControllerProvider.notifier)
                .contains(detail.anchorStationId);
          },
        ),
      ),
    );
  }

  Future<LocationSearchTarget?> _resolvePlace(String text) async {
    final controller = ref.read(explorerMapControllerProvider.notifier);
    try {
      final center = await _placeSearchAdapter.geocodePlace(text);
      if (center != null) return controller.findNearestPark(center);
    } on PlatformException {
      // Offline fallback: use a locally indexed station matching the text.
    }
    final localGroups = await controller.searchGroups(text);
    if (localGroups.isEmpty) return null;
    final group = localGroups.first;
    return LocationSearchTarget(
      center: GeoCoordinate(
        latitude: group.latitude,
        longitude: group.longitude,
      ),
      radiusKm: 10,
      nearestGroup: group,
    );
  }

  Future<void> _showMyLocation() async {
    final radiusKm = await Navigator.of(context).push<double>(
      PageRouteBuilder<double>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const _NearbyRadiusPage(),
      ),
    );
    if (radiusKm == null || !mounted || _mapAdapter == null) return;
    try {
      final coordinate = await _mapAdapter!.focusUserLocation(
        radiusKm: radiusKm,
      );
      ref
          .read(explorerMapControllerProvider.notifier)
          .showNearby(coordinate, radiusKm);
    } on PlatformException catch (error) {
      if (!mounted) return;
      _showLocationError(error);
    }
  }

  void _showLocationError(PlatformException error) {
    final strings = AppLocalizations.of(context);
    final message = error.code == 'location_permission_denied'
        ? strings.locationPermissionDenied
        : strings.locationUnavailable;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showExternalLocation(GeoCoordinate coordinate) {
    if (!mounted) return;
    ref.read(explorerMapControllerProvider.notifier).clearNearby();
    final mapAdapter = _mapAdapter;
    if (mapAdapter == null) {
      _pendingExternalLocation = coordinate;
      return;
    }
    unawaited(mapAdapter.focusCoordinate(coordinate, radiusKm: 10));
  }

  void _mapCreated(MapKitAdapter adapter) {
    unawaited(_replaceMapAdapter(adapter));
  }

  Future<void> _replaceMapAdapter(MapKitAdapter adapter) async {
    await _disposeMapAdapter();
    if (!mounted) {
      await adapter.dispose();
      return;
    }
    _mapAdapter = adapter;
    setState(() {});
    _boundsSubscription = adapter.visibleBounds.listen(
      ref.read(explorerMapControllerProvider.notifier).visibleBoundsChanged,
    );
    _selectionSubscription = adapter.selectedGroupIds.listen(_groupSelected);
    final groups = ref.read(explorerMapControllerProvider).value?.groups;
    if (groups != null) {
      unawaited(adapter.showGroups(groups));
    }
    final routeOption = ref
        .read(routePlanningControllerProvider)
        .selectedOption;
    if (routeOption != null) {
      unawaited(adapter.showRoute(routeOption.polyline));
    }
    final pendingExternalLocation = _pendingExternalLocation;
    if (pendingExternalLocation != null) {
      _pendingExternalLocation = null;
      await adapter.focusCoordinate(pendingExternalLocation, radiusKm: 10);
    } else {
      await adapter.requestVisibleBounds();
    }
  }

  Future<void> _groupSelected(String groupId) async {
    if (!mounted || _detailsOpen) {
      return;
    }
    _detailsOpen = true;
    final detailFuture = ref
        .read(explorerMapControllerProvider.notifier)
        .loadGroupDetail(groupId);
    try {
      await Navigator.of(context).push<void>(
        PageRouteBuilder<void>(
          opaque: true,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (context, animation, secondaryAnimation) =>
              GroupDetailPage(
                future: detailFuture,
                onPlanRoute: (detail) {
                  _pendingRouteDestination = RouteWaypoint(
                    coordinate: GeoCoordinate(
                      latitude: detail.latitude,
                      longitude: detail.longitude,
                    ),
                    label: detail.name ?? detail.city,
                  );
                  unawaited(_openRoutePlanning());
                },
              ),
        ),
      );
    } finally {
      _detailsOpen = false;
    }
  }

  Future<void> _openFilters() async {
    final current = ref.read(explorerMapControllerProvider).value;
    if (!mounted || current == null) return;
    final controller = ref.read(explorerMapControllerProvider.notifier);
    final result = await Navigator.of(context).push<ExplorerFilters>(
      PageRouteBuilder<ExplorerFilters>(
        opaque: true,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, animation, secondaryAnimation) => FilterPage(
          initialFilters: current.filters,
          optionsFuture: controller.loadFilterOptions(),
          popularOperatorsFuture: controller.loadPopularOperators(),
          searchOperators: controller.searchOperators,
        ),
      ),
    );
    if (result != null) {
      GeoCoordinate? nearbyCenter = current.nearbyCenter;
      final radiusChanged =
          result.nearbyRadiusKm != current.filters.nearbyRadiusKm;
      if (result.nearbyRadiusKm != null &&
          (nearbyCenter == null || radiusChanged)) {
        try {
          nearbyCenter = await _mapAdapter?.focusUserLocation(
            radiusKm: result.nearbyRadiusKm!.toDouble(),
          );
          if (nearbyCenter == null) return;
        } on PlatformException catch (error) {
          if (!mounted) return;
          _showLocationError(error);
          return;
        }
      }
      final favorites = await ref.read(favoritesControllerProvider.future);
      final parkInformationRepository = await ref.read(
        parkInformationRepositoryProvider.future,
      );
      final amenityAnchors = await parkInformationRepository
          .findStationIdsWithAmenities(result.requiredAmenities);
      controller.filtersChanged(
        result,
        favoriteAnchorStationIds: favorites
            .map((item) => item.anchorStationId)
            .toList(growable: false),
        amenityAnchorStationIds: amenityAnchors,
        nearbyCenter: nearbyCenter,
        clearNearby: result.nearbyRadiusKm == null,
      );
    }
  }

  Future<void> _disposeMapAdapter() async {
    final boundsSubscription = _boundsSubscription;
    final selectionSubscription = _selectionSubscription;
    final mapAdapter = _mapAdapter;
    _boundsSubscription = null;
    _selectionSubscription = null;
    _mapAdapter = null;
    await boundsSubscription?.cancel();
    await selectionSubscription?.cancel();
    await mapAdapter?.dispose();
  }

  @override
  void dispose() {
    unawaited(_disposeMapAdapter());
    unawaited(_inboundLocationSubscription?.cancel());
    unawaited(_inboundLocationAdapter?.dispose());
    super.dispose();
  }
}

String _repositoryError(
  AppLocalizations strings,
  ChargingRepositoryError error,
) => switch (error) {
  ChargingRepositoryError.databaseNotFound => strings.datasetMissing,
  ChargingRepositoryError.unsupportedSchema => strings.datasetUnsupported,
  ChargingRepositoryError.invalidQuery => strings.invalidFilterQuery,
  _ => strings.chargingParksLoadFailed,
};

class _NearbyRadiusPage extends StatelessWidget {
  const _NearbyRadiusPage();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.nearbySearch)),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(strings.nearbyRadiusExplanation),
          ),
          for (final radius in const <double>[5, 10, 25, 50, 100])
            ListTile(
              title: Text(strings.radiusKm(radius.toInt())),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pop(context, radius),
            ),
        ],
      ),
    );
  }
}

int _activeFilterCount(ExplorerFilters filters) {
  var count = 0;
  if (filters.diameterM != ExplorerFilters.defaults.diameterM) count++;
  if (filters.minimumEvseCount != ExplorerFilters.defaults.minimumEvseCount ||
      filters.minimumPowerKw != ExplorerFilters.defaults.minimumPowerKw) {
    count++;
  }
  if (filters.operatorNames.isNotEmpty || filters.operatorIds.isNotEmpty) {
    count++;
  }
  if (filters.connectorTypes.isNotEmpty) count++;
  if (filters.requiredAmenities.isNotEmpty) count++;
  if (filters.nearbyRadiusKm != null) count++;
  if (filters.alwaysOpenOnly) count++;
  if (filters.favoritesOnly) count++;
  return count;
}

class GroupDetailPage extends StatefulWidget {
  const GroupDetailPage({
    required this.future,
    this.enableFavoriteAction = true,
    this.onPlanRoute,
    super.key,
  });

  final Future<ChargingGroupDetail?> future;
  final bool enableFavoriteAction;

  /// When set, the detail sheet offers to plan a route to this park.
  final void Function(ChargingGroupDetail detail)? onPlanRoute;

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.chargingParkDetails)),
      body: FutureBuilder<ChargingGroupDetail?>(
        future: widget.future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text(strings.detailsUnavailable));
          }
          return GroupDetailSheet(
            detail: snapshot.data!,
            scrollController: _scrollController,
            enableFavoriteAction: widget.enableFavoriteAction,
            onPlanRoute: widget.onPlanRoute,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class _MapStatusChip extends StatelessWidget {
  const _MapStatusChip({required this.state});

  final ExplorerMapState state;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final radius = state.filters.nearbyRadiusKm;
    return Semantics(
      liveRegion: true,
      child: Chip(
        avatar: state.isQuerying
            ? const SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.ev_station, size: 18),
        label: Text(
          '${state.isQuerying
              ? strings.loadingParks
              : state.groups.length == 500
              ? strings.visibleParksLimitReached(500)
              : strings.visibleParks(state.groups.length)}'
          '${radius == null ? '' : ' · ${strings.activeNearbyRadius(radius)}'}',
        ),
      ),
    );
  }
}

class GroupDetailSheet extends ConsumerWidget {
  const GroupDetailSheet({
    required this.detail,
    required this.scrollController,
    this.enableFavoriteAction = true,
    this.onPlanRoute,
    super.key,
  });

  final ChargingGroupDetail detail;
  final ScrollController scrollController;
  final bool enableFavoriteAction;
  final void Function(ChargingGroupDetail detail)? onPlanRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final address = <String>[
      [
        detail.street,
        detail.houseNumber,
      ].whereType<String>().where((part) => part.isNotEmpty).join(' '),
      [
        detail.postalCode,
        detail.city,
      ].whereType<String>().where((part) => part.isNotEmpty).join(' '),
    ].where((line) => line.isNotEmpty).join(', ');
    final name = detail.name ?? detail.city ?? strings.chargingParkDetails;
    final isFavorite = enableFavoriteAction
        ? ref
                  .watch(favoritesControllerProvider)
                  .value
                  ?.any(
                    (favorite) =>
                        favorite.anchorStationId == detail.anchorStationId,
                  ) ??
              false
        : false;
    return SafeArea(
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (enableFavoriteAction)
                IconButton(
                  tooltip: isFavorite
                      ? strings.removeFavorite
                      : strings.addFavorite,
                  onPressed: () => ref
                      .read(favoritesControllerProvider.notifier)
                      .toggle(
                        detail,
                        ref
                                .read(explorerMapControllerProvider)
                                .value
                                ?.filters
                                .diameterM ??
                            ExplorerFilters.defaults.diameterM,
                      ),
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_outline,
                  ),
                ),
            ],
          ),
          if (address.isNotEmpty) Text(address),
          _ParkInformationSection(stationIds: detail.stationIds),
          const SizedBox(height: 16),
          _ChargingMatrix(operators: detail.operators),
          const SizedBox(height: 6),
          Text(
            detail.maxPowerKw == null
                ? strings.maximumPowerUnknown
                : strings.maximumPower(detail.maxPowerKw!),
          ),
          const SizedBox(height: 12),
          Text(
            '${strings.openingHours}: ${detail.openingHours ?? strings.unknown}',
          ),
          const SizedBox(height: 12),
          Text(
            strings.proximityApproximation(detail.actualDiameterM.round()),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            strings.datasetVersion(detail.datasetVersion),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            strings.dataSource(detail.sourceName, detail.sourceVersion),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            strings.datasetCreatedAt(detail.datasetCreatedAt),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _openNavigation(context, ref, name),
              icon: const Icon(Icons.directions),
              label: Text(strings.openNavigation),
            ),
          ),
          if (onPlanRoute case final planRoute?) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  planRoute(detail);
                },
                icon: const Icon(Icons.directions_outlined),
                label: Text(strings.planRouteToHere),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openNavigation(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) async {
    final strings = AppLocalizations.of(context);
    final preference =
        ref.read(settingsControllerProvider).value?.navigationPreference ??
        NavigationPreference.askEveryTime;
    final google = ref.read(googleMapsNavigationAdapterProvider);
    final apple = ref.read(appleMapsNavigationAdapterProvider);
    final googleAvailable = await google.isAvailable();
    if (!context.mounted) return;

    var choice = preference;
    if (preference == NavigationPreference.askEveryTime && googleAvailable) {
      choice =
          await showModalBottomSheet<NavigationPreference>(
            context: context,
            builder: (context) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.map_outlined),
                    title: const Text('Apple Maps'),
                    onTap: () =>
                        Navigator.pop(context, NavigationPreference.appleMaps),
                  ),
                  ListTile(
                    leading: const Icon(Icons.map_outlined),
                    title: const Text('Google Maps'),
                    onTap: () =>
                        Navigator.pop(context, NavigationPreference.googleMaps),
                  ),
                ],
              ),
            ),
          ) ??
          NavigationPreference.askEveryTime;
      if (choice == NavigationPreference.askEveryTime) return;
    } else if (preference == NavigationPreference.askEveryTime) {
      choice = NavigationPreference.appleMaps;
    }

    if (!context.mounted) return;
    if (choice == NavigationPreference.googleMaps && !googleAvailable) {
      final useApple = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(strings.googleMapsUnavailable),
          content: Text(strings.googleMapsFallbackExplanation),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(strings.useAppleMaps),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      if (useApple != true) return;
      choice = NavigationPreference.appleMaps;
    }

    try {
      await (choice == NavigationPreference.googleMaps ? google : apple)
          .openDirections(
            latitude: detail.latitude,
            longitude: detail.longitude,
            name: name,
          );
    } on Object {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(strings.navigationUnavailable)));
      }
    }
  }
}

class _ParkInformationSection extends ConsumerWidget {
  const _ParkInformationSection({required this.stationIds});

  final List<String> stationIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = AppLocalizations.of(context);
    final german = Localizations.localeOf(context).languageCode == 'de';
    final information = ref.watch(
      parkInformationProvider((ids: stationIds.join('|'), german: german)),
    );
    return information.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (value) {
        if (value == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.onSiteInformation,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final entry in value.amenities.entries)
                    _AmenityChip(type: entry.key, state: entry.value),
                ],
              ),
              if (value.notes case final String notes) ...[
                const SizedBox(height: 6),
                Text(notes),
              ],
              Text(
                strings.observedOn(value.observedOn),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              for (final photo in value.photos) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Semantics(
                    image: true,
                    label: photo.altText,
                    child: Image.asset(photo.assetPath, fit: BoxFit.cover),
                  ),
                ),
                Text(
                  strings.photoCredit(photo.author, photo.capturedOn),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AmenityChip extends StatelessWidget {
  const _AmenityChip({required this.type, required this.state});

  final AmenityType type;
  final AmenityState state;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final label = switch (type) {
      AmenityType.restaurant => strings.restaurant,
      AmenityType.shop => strings.shop,
      AmenityType.coffeeMachine => strings.coffeeMachine,
      AmenityType.snackMachine => strings.snackMachine,
      AmenityType.toilet => strings.toilet,
    };
    final icon = switch (state) {
      AmenityState.present => Icons.check_circle,
      AmenityState.absent => Icons.cancel_outlined,
      AmenityState.unknown => Icons.help_outline,
    };
    final stateLabel = switch (state) {
      AmenityState.present => strings.amenityPresent,
      AmenityState.absent => strings.amenityAbsent,
      AmenityState.unknown => strings.unknown,
    };
    return Semantics(
      label: '$label: $stateLabel',
      child: Tooltip(
        message: '$label: $stateLabel',
        child: Chip(
          visualDensity: VisualDensity.compact,
          avatar: Icon(icon, size: 17),
          label: Text(label),
        ),
      ),
    );
  }
}

class _ChargingMatrix extends StatelessWidget {
  const _ChargingMatrix({required this.operators});

  static const _powerBandLabels = <String>[
    '0–50 kW',
    '51–100 kW',
    '101–150 kW',
    '151–200 kW',
    '201–250 kW',
    '251–300 kW',
    '301–350 kW',
    '> 350 kW',
  ];

  final List<ChargingOperatorDetail> operators;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    if (operators.isEmpty) {
      return Text('${strings.operators}: ${strings.unknown}');
    }
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.chargingPointsByOperator,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Table(
                defaultColumnWidth: const FixedColumnWidth(88),
                columnWidths: const <int, TableColumnWidth>{
                  0: FixedColumnWidth(78),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                border: TableBorder(
                  horizontalInside: BorderSide(color: colors.outlineVariant),
                  verticalInside: BorderSide(color: colors.outlineVariant),
                ),
                children: [
                  TableRow(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.65),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            strings.power,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      for (final operator in operators)
                        Tooltip(
                          message: operator.name,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 4,
                            ),
                            child: Text(
                              operator.name,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.1,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  for (var band = 0; band < _powerBandLabels.length; band++)
                    TableRow(
                      decoration: BoxDecoration(
                        color: band.isOdd
                            ? colors.surfaceContainerHighest.withValues(
                                alpha: 0.35,
                              )
                            : colors.surface,
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          child: Text(
                            _powerBandLabels[band],
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        for (final operator in operators)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            child: _MatrixCell(
                              connectorCounts:
                                  operator.connectorCountsByPowerBand[band],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MatrixCell extends StatelessWidget {
  const _MatrixCell({required this.connectorCounts});

  final Map<String, int>? connectorCounts;

  @override
  Widget build(BuildContext context) {
    final entries = connectorCounts?.entries.toList()
      ?..sort((first, second) => first.key.compareTo(second.key));
    if (entries == null || entries.isEmpty) {
      return Text(
        '–',
        style: TextStyle(color: Theme.of(context).colorScheme.outline),
      );
    }
    return Text(
      entries
          .map((entry) => '${_connectorLabel(entry.key)}: ${entry.value}')
          .join('\n'),
      style: const TextStyle(fontSize: 12, height: 1.15),
    );
  }
}

String _connectorLabel(String value) => switch (value.toLowerCase()) {
  'ccs' => 'CCS',
  'chademo' => 'CHAdeMO',
  'type_2' => 'Typ 2',
  'type_2_socket' => 'Typ 2',
  'type_2_plug' => 'Typ 2',
  'schuko' => 'Schuko',
  _ => value.replaceAll('_', ' '),
};
