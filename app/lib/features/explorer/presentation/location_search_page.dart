import 'package:flutter/material.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/geo_coordinate.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/location_search_target.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';

class LocationSearchPage extends StatefulWidget {
  const LocationSearchPage({required this.resolvePlace, super.key});

  final Future<LocationSearchTarget?> Function(String text) resolvePlace;

  @override
  State<LocationSearchPage> createState() => _LocationSearchPageState();
}

class _LocationSearchPageState extends State<LocationSearchPage> {
  final TextEditingController _controller = TextEditingController();
  bool _searched = false;
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.locationSearch)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              key: const ValueKey('location-search-field'),
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: strings.locationSearchHint,
                helperText: strings.coordinateSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _loading ? null : _submit,
                  tooltip: strings.search,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 12),
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(padding: const EdgeInsets.all(12), child: Text(_error!)),
            if (!_loading && _searched && _error == null)
              Expanded(child: Center(child: Text(strings.noSearchResults))),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final coordinate = parseLocationInput(text);
    if (coordinate != null) {
      Navigator.pop(
        context,
        LocationSearchTarget(center: coordinate, radiusKm: 10),
      );
      return;
    }
    setState(() {
      _loading = true;
      _searched = true;
      _error = null;
    });
    try {
      final target = await widget.resolvePlace(text);
      if (mounted && target != null) Navigator.pop(context, target);
    } on Object {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context).searchFailed);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

GeoCoordinate? parseLocationInput(String input) {
  final trimmed = input.trim();
  final direct = RegExp(
    r'^\s*(-?\d{1,2}(?:\.\d+)?)\s*[,; ]\s*(-?\d{1,3}(?:\.\d+)?)\s*$',
  ).firstMatch(trimmed);
  if (direct != null) {
    return _checkedCoordinate(direct.group(1), direct.group(2));
  }
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;
  final latitude = uri.queryParameters['lat'];
  final longitude = uri.queryParameters['lon'] ?? uri.queryParameters['lng'];
  if (latitude != null && longitude != null) {
    return _checkedCoordinate(latitude, longitude);
  }
  for (final key in const <String>['ll', 'q', 'query', 'destination']) {
    final value = uri.queryParameters[key];
    if (value == null) continue;
    final pair = value.split(',');
    if (pair.length == 2) return _checkedCoordinate(pair[0], pair[1]);
  }
  final pathCoordinate = RegExp(
    r'@(-?\d{1,2}(?:\.\d+)?),(-?\d{1,3}(?:\.\d+)?)',
  ).firstMatch(uri.path);
  return pathCoordinate == null
      ? null
      : _checkedCoordinate(pathCoordinate.group(1), pathCoordinate.group(2));
}

GeoCoordinate? _checkedCoordinate(String? latitude, String? longitude) {
  final lat = double.tryParse(latitude ?? '');
  final lon = double.tryParse(longitude ?? '');
  if (lat == null ||
      lon == null ||
      lat < -90 ||
      lat > 90 ||
      lon < -180 ||
      lon > 180) {
    return null;
  }
  return GeoCoordinate(latitude: lat, longitude: lon);
}
