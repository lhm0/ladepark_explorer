import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/explorer/presentation/location_search_page.dart'
    show parseLocationInput;
import 'package:ladepark_explorer/features/route_planning/application/route_planning_providers.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_request.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/route_waypoint.dart';
import 'package:ladepark_explorer/features/route_planning/presentation/route_format.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';

/// Opaque full-screen route-planning entry point (FR-ROUTE-001, FR-ROUTE-002).
///
/// It only collects start and destination. The calculation, the native route
/// overlay and the summary live on the map screen.
class RoutePlanningPage extends ConsumerStatefulWidget {
  const RoutePlanningPage({
    required this.resolveEndpoint,
    required this.currentLocation,
    this.initialDestination,
    super.key,
  });

  /// Resolves a free-text place or address to a coordinate. Direct coordinates
  /// are parsed locally before this is called.
  final Future<GeoCoordinate?> Function(String query) resolveEndpoint;

  /// Returns the current device location. May throw [PlatformException] with
  /// code `location_permission_denied` or `location_unavailable`.
  final Future<GeoCoordinate> Function() currentLocation;

  /// Pre-filled destination, e.g. when planning from a charging park detail.
  final RouteWaypoint? initialDestination;

  @override
  ConsumerState<RoutePlanningPage> createState() => _RoutePlanningPageState();
}

class _RoutePlanningPageState extends ConsumerState<RoutePlanningPage> {
  final TextEditingController _startController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  bool _useCurrentLocation = false;
  String? _startError;
  String? _destinationError;

  @override
  void initState() {
    super.initState();
    final destination = widget.initialDestination;
    if (destination != null) {
      _destinationController.text =
          '${destination.coordinate.latitude.toStringAsFixed(5)}, '
          '${destination.coordinate.longitude.toStringAsFixed(5)}';
    }
  }

  @override
  void dispose() {
    _startController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final state = ref.watch(routePlanningControllerProvider);
    final isCalculating = state.isCalculating;

    return Scaffold(
      appBar: AppBar(title: Text(strings.routePlanningTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(strings.routeUseCurrentLocation),
            value: _useCurrentLocation,
            onChanged: isCalculating
                ? null
                : (value) => setState(() {
                    _useCurrentLocation = value;
                    _startError = null;
                  }),
          ),
          if (!_useCurrentLocation) ...[
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('route-start-field'),
              controller: _startController,
              enabled: !isCalculating,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: strings.routeStartLabel,
                helperText: strings.routeEndpointHint,
                errorText: _startError,
                prefixIcon: const Icon(Icons.trip_origin),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('route-destination-field'),
            controller: _destinationController,
            enabled: !isCalculating,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: strings.routeDestinationLabel,
              helperText:
                  widget.initialDestination?.label ?? strings.routeEndpointHint,
              errorText: _destinationError,
              prefixIcon: const Icon(Icons.place_outlined),
            ),
            onSubmitted: (_) => _calculate(),
          ),
          const SizedBox(height: 16),
          Text(
            strings.routeOnlineHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (state.error case final error?) ...[
            const SizedBox(height: 16),
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(routeErrorMessage(strings, error)),
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: isCalculating ? null : _calculate,
            icon: isCalculating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.directions),
            label: Text(
              isCalculating ? strings.routeCalculating : strings.routeCalculate,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _calculate() async {
    final strings = AppLocalizations.of(context);
    setState(() {
      _startError = null;
      _destinationError = null;
    });

    GeoCoordinate? start;
    try {
      start = _useCurrentLocation
          ? await widget.currentLocation()
          : await _resolve(_startController.text);
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _startError = error.code == 'location_permission_denied'
            ? strings.locationPermissionDenied
            : strings.locationUnavailable;
      });
      return;
    }
    final destination = await _resolve(_destinationController.text);
    if (!mounted) return;

    var invalid = false;
    if (start == null) {
      setState(() => _startError = strings.routeStartNotFound);
      invalid = true;
    }
    if (destination == null) {
      setState(() => _destinationError = strings.routeDestinationNotFound);
      invalid = true;
    }
    if (invalid) return;

    await ref
        .read(routePlanningControllerProvider.notifier)
        .planRoute(
          RouteRequest(
            origin: RouteWaypoint(coordinate: start!),
            destination: RouteWaypoint(coordinate: destination!),
          ),
        );
    if (!mounted) return;
    final result = ref.read(routePlanningControllerProvider);
    if (result.error == null && result.hasRoute) {
      Navigator.of(context).pop();
    }
  }

  Future<GeoCoordinate?> _resolve(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return null;
    final parsed = parseLocationInput(trimmed);
    if (parsed != null) return parsed;
    try {
      return await widget.resolveEndpoint(trimmed);
    } on Object {
      return null;
    }
  }
}
