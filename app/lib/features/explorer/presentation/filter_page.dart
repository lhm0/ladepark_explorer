import 'package:flutter/material.dart';
import 'package:ladepark_explorer/features/explorer/domain/models/explorer_filters.dart';
import 'package:ladepark_explorer/features/park_info/domain/models/park_information.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';

class FilterPage extends StatefulWidget {
  const FilterPage({
    required this.initialFilters,
    required this.optionsFuture,
    required this.popularOperatorsFuture,
    required this.searchOperators,
    super.key,
  });

  final ExplorerFilters initialFilters;
  final Future<ChargingFilterOptions> optionsFuture;
  final Future<List<OperatorFilterOption>> popularOperatorsFuture;
  final Future<List<OperatorFilterOption>> Function(String text)
  searchOperators;

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  late ExplorerFilters _filters = widget.initialFilters;
  bool _allowPop = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return PopScope<ExplorerFilters>(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _finish();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(strings.filters)),
        body: FutureBuilder<ChargingFilterOptions>(
          future: widget.optionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final options = snapshot.data ?? const ChargingFilterOptions();
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _DropdownFilter(
                  label: strings.groupDiameter,
                  value: _filters.diameterM,
                  values: const <int>[25, 50, 100, 200, 300],
                  valueLabel: (value) => '$value m',
                  onChanged: (value) =>
                      _change(_filters.copyWith(diameterM: value)),
                ),
                _DropdownFilter(
                  label: strings.minimumChargingPoints,
                  value: _filters.minimumEvseCount,
                  values: const <int>[1, 2, 4, 6, 8, 10, 12, 16, 20],
                  valueLabel: (value) => '$value',
                  onChanged: (value) =>
                      _change(_filters.copyWith(minimumEvseCount: value)),
                ),
                _DropdownFilter(
                  label: strings.minimumPower,
                  value: _filters.minimumPowerKw,
                  values: const <int>[0, 50, 100, 150, 200, 250, 300, 350],
                  valueLabel: (value) => '$value kW',
                  onChanged: (value) =>
                      _change(_filters.copyWith(minimumPowerKw: value)),
                ),
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      strings.minimumChargingOffer(
                        _filters.minimumEvseCount,
                        _filters.minimumPowerKw,
                      ),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                _OperatorSelector(
                  popularFuture: widget.popularOperatorsFuture,
                  search: widget.searchOperators,
                  selectedIds: _filters.operatorIds,
                  selectedNames: _filters.operatorNames,
                  onChanged: (ids, names) => _change(
                    _filters.copyWith(operatorIds: ids, operatorNames: names),
                  ),
                ),
                _MultiSelectTile(
                  label: strings.connectors,
                  values: options.connectorTypes,
                  selected: _filters.connectorTypes,
                  onChanged: (values) =>
                      _change(_filters.copyWith(connectorTypes: values)),
                ),
                _AmenitySelector(
                  selected: _filters.requiredAmenities,
                  onChanged: (values) =>
                      _change(_filters.copyWith(requiredAmenities: values)),
                ),
                _NearbyRadiusFilter(
                  value: _filters.nearbyRadiusKm,
                  onChanged: (value) => _change(
                    value == null
                        ? _filters.copyWith(clearNearbyRadius: true)
                        : _filters.copyWith(nearbyRadiusKm: value),
                  ),
                ),
                SwitchListTile(
                  key: const ValueKey('always-open-only'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(strings.alwaysOpenOnly),
                  subtitle: Text(strings.alwaysOpenOnlyExplanation),
                  value: _filters.alwaysOpenOnly,
                  onChanged: (value) =>
                      _change(_filters.copyWith(alwaysOpenOnly: value)),
                ),
                SwitchListTile(
                  key: const ValueKey('favorites-only'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  title: Text(strings.favoritesOnly),
                  value: _filters.favoritesOnly,
                  onChanged: (value) =>
                      _change(_filters.copyWith(favoritesOnly: value)),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  key: const ValueKey('reset-filters'),
                  onPressed: () => _change(ExplorerFilters.defaults),
                  child: Text(strings.resetFilters),
                ),
                const SizedBox(height: 12),
                TextButton(
                  key: const ValueKey('cancel-filter-changes'),
                  onPressed: () => _change(widget.initialFilters),
                  child: Text(strings.cancelFilterChanges),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _change(ExplorerFilters filters) => setState(() => _filters = filters);

  void _finish() {
    if (_allowPop) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, _filters);
    });
  }
}

class _NearbyRadiusFilter extends StatelessWidget {
  const _NearbyRadiusFilter({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<int?>(
        key: const ValueKey('nearby-radius'),
        initialValue: value,
        decoration: InputDecoration(
          labelText: strings.distanceFromCurrentLocation,
          border: const OutlineInputBorder(),
        ),
        items: <DropdownMenuItem<int?>>[
          DropdownMenuItem<int?>(child: Text(strings.noDistanceLimit)),
          for (final radius in const <int>[5, 10, 25, 50, 100])
            DropdownMenuItem<int?>(
              value: radius,
              child: Text(strings.radiusKm(radius)),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

class _AmenitySelector extends StatelessWidget {
  const _AmenitySelector({required this.selected, required this.onChanged});

  final List<AmenityType> selected;
  final ValueChanged<List<AmenityType>> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final labels = <AmenityType, String>{
      AmenityType.restaurant: strings.restaurant,
      AmenityType.shop: strings.shop,
      AmenityType.coffeeMachine: strings.coffeeMachine,
      AmenityType.snackMachine: strings.snackMachine,
      AmenityType.toilet: strings.toilet,
    };
    return Card(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.infrastructureFilter,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              strings.infrastructureFilterExplanation,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            for (final type in AmenityType.values)
              CheckboxListTile(
                key: ValueKey('amenity-${type.name}'),
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: const VisualDensity(vertical: -4),
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(labels[type]!),
                value: selected.contains(type),
                onChanged: (checked) {
                  final values = <AmenityType>[...selected];
                  checked == true ? values.add(type) : values.remove(type);
                  values.sort((a, b) => a.index.compareTo(b.index));
                  onChanged(List<AmenityType>.unmodifiable(values));
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.values,
    required this.valueLabel,
    required this.onChanged,
  });

  final String label;
  final int value;
  final List<int> values;
  final String Function(int value) valueLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<int>(
        key: ValueKey('filter-$label-$value'),
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items: values
            .map(
              (value) => DropdownMenuItem<int>(
                value: value,
                child: Text(valueLabel(value)),
              ),
            )
            .toList(growable: false),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class _MultiSelectTile extends StatelessWidget {
  const _MultiSelectTile({
    required this.label,
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final List<String> values;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        key: ValueKey('filter-$label'),
        title: Text(label),
        subtitle: Text(
          selected.isEmpty ? strings.anyValue : selected.join(', '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final result = await showDialog<List<String>>(
            context: context,
            builder: (context) => _SelectionDialog(
              title: label,
              values: values,
              initiallySelected: selected,
            ),
          );
          if (result != null) onChanged(result);
        },
      ),
    );
  }
}

class _OperatorSelector extends StatefulWidget {
  const _OperatorSelector({
    required this.popularFuture,
    required this.search,
    required this.selectedIds,
    required this.selectedNames,
    required this.onChanged,
  });

  final Future<List<OperatorFilterOption>> popularFuture;
  final Future<List<OperatorFilterOption>> Function(String text) search;
  final List<String> selectedIds;
  final List<String> selectedNames;
  final void Function(List<String> ids, List<String> names) onChanged;

  @override
  State<_OperatorSelector> createState() => _OperatorSelectorState();
}

class _OperatorSelectorState extends State<_OperatorSelector> {
  List<OperatorFilterOption> _searchResults = const [];
  int _searchRevision = 0;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.operators,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 2),
            Text(
              strings.operatorCountExplanation,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            FutureBuilder<List<OperatorFilterOption>>(
              future: widget.popularFuture,
              builder: (context, snapshot) {
                final options = [
                  ...(snapshot.data ?? const <OperatorFilterOption>[]),
                ]..sort(_compareOperators);
                return Column(
                  children: [
                    for (final option in options)
                      _OperatorOptionRow(
                        option: option,
                        selected: widget.selectedIds.contains(option.value),
                        onTap: () => _toggle(option),
                      ),
                  ],
                );
              },
            ),
            TextField(
              key: const ValueKey('operator-search'),
              decoration: InputDecoration(
                labelText: strings.filterSearch,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (text) async {
                final revision = ++_searchRevision;
                final results = text.trim().length < 2
                    ? const <OperatorFilterOption>[]
                    : await widget.search(text);
                if (mounted && revision == _searchRevision) {
                  setState(
                    () =>
                        _searchResults = [...results]..sort(_compareOperators),
                  );
                }
              },
            ),
            for (final option in _searchResults)
              _OperatorOptionRow(
                option: option,
                selected: widget.selectedNames.contains(option.value),
                onTap: () => _toggle(option),
              ),
          ],
        ),
      ),
    );
  }

  void _toggle(OperatorFilterOption option) {
    final ids = widget.selectedIds.toSet();
    final names = widget.selectedNames.toSet();
    final selected = option.isCanonical ? ids : names;
    selected.contains(option.value)
        ? selected.remove(option.value)
        : selected.add(option.value);
    widget.onChanged((ids.toList()..sort()), (names.toList()..sort()));
  }
}

class _OperatorOptionRow extends StatelessWidget {
  const _OperatorOptionRow({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final OperatorFilterOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            height: 28,
            child: Checkbox(
              value: selected,
              onChanged: (_) => onTap(),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${option.displayName} (${option.evseCount})',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ),
  );
}

int _compareOperators(
  OperatorFilterOption first,
  OperatorFilterOption second,
) =>
    first.displayName.toLowerCase().compareTo(second.displayName.toLowerCase());

class _SelectionDialog extends StatefulWidget {
  const _SelectionDialog({
    required this.title,
    required this.values,
    required this.initiallySelected,
  });

  final String title;
  final List<String> values;
  final List<String> initiallySelected;

  @override
  State<_SelectionDialog> createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<_SelectionDialog> {
  late final Set<String> _selected = widget.initiallySelected.toSet();
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final visible = widget.values
        .where((value) => value.toLowerCase().contains(_search.toLowerCase()))
        .take(100)
        .toList(growable: false);
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        height: 420,
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: strings.filterSearch,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _search = value),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final value = visible[index];
                  return _CompactSelectionRow(
                    key: ValueKey('selection-option-$value'),
                    label: value,
                    value: _selected.contains(value),
                    onChanged: (checked) => setState(() {
                      checked == true
                          ? _selected.add(value)
                          : _selected.remove(value);
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(_selected.clear),
          child: Text(strings.clearSelection),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            (_selected.toList()..sort()).toList(growable: false),
          ),
          child: Text(strings.done),
        ),
      ],
    );
  }
}

class _CompactSelectionRow extends StatelessWidget {
  const _CompactSelectionRow({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onChanged(!value),
    child: SizedBox(
      height: 30,
      child: Row(
        children: [
          SizedBox(
            width: 30,
            height: 28,
            child: Checkbox(
              value: value,
              onChanged: (checked) => onChanged(checked ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    ),
  );
}
