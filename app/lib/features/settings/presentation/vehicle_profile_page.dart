import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/features/route_planning/application/vehicle_profile_providers.dart';
import 'package:ladepark_explorer/features/route_planning/domain/models/vehicle_profile.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';

const _connectorOptions = <(String label, String slug)>[
  ('CCS', 'ccs'),
  ('CHAdeMO', 'chademo'),
  ('Typ 2', 'type_2'),
];

/// Editor for the single local vehicle profile (FR-ROUTE-005, ADR-0021),
/// reached from the settings page.
class VehicleProfilePage extends ConsumerStatefulWidget {
  const VehicleProfilePage({this.initial, super.key});

  final VehicleProfile? initial;

  @override
  ConsumerState<VehicleProfilePage> createState() => _VehicleProfilePageState();
}

class _VehicleProfilePageState extends ConsumerState<VehicleProfilePage> {
  late final TextEditingController _battery;
  late final TextEditingController _consumption;
  late final TextEditingController _maxPower;
  late final TextEditingController _reserve;
  late final TextEditingController _target;
  late final TextEditingController _start;
  late Set<String> _connectors;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initial ?? const VehicleProfile();
    String number(double value) =>
        value == 0 ? '' : _trimZeros(value.toStringAsFixed(1));
    _battery = TextEditingController(text: number(profile.usableBatteryKwh));
    _consumption = TextEditingController(
      text: number(profile.consumptionKwhPer100Km),
    );
    _maxPower = TextEditingController(text: number(profile.maxChargePowerKw));
    _reserve = TextEditingController(text: '${profile.reserveSocPercent}');
    _target = TextEditingController(text: '${profile.targetArrivalSocPercent}');
    _start = TextEditingController(text: '${profile.defaultStartSocPercent}');
    _connectors = widget.initial?.connectorTypes.toSet() ?? <String>{};
  }

  @override
  void dispose() {
    for (final controller in <TextEditingController>[
      _battery,
      _consumption,
      _maxPower,
      _reserve,
      _target,
      _start,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.vehicleProfileTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            strings.vehicleProfileExplanation,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          _numberField(
            _battery,
            strings.vehicleBatteryLabel,
            'vehicle-battery',
          ),
          _numberField(
            _consumption,
            strings.vehicleConsumptionLabel,
            'vehicle-consumption',
          ),
          _numberField(
            _maxPower,
            strings.vehicleMaxPowerLabel,
            'vehicle-max-power',
          ),
          _numberField(
            _reserve,
            strings.vehicleReserveLabel,
            'vehicle-reserve',
            integer: true,
          ),
          _numberField(
            _target,
            strings.vehicleTargetLabel,
            'vehicle-target',
            integer: true,
          ),
          _numberField(
            _start,
            strings.vehicleStartLabel,
            'vehicle-start',
            integer: true,
          ),
          const SizedBox(height: 16),
          Text(
            strings.vehicleConnectorsLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final (label, slug) in _connectorOptions)
                FilterChip(
                  label: Text(label),
                  selected: _connectors.contains(slug),
                  onSelected: (selected) => setState(() {
                    if (selected) {
                      _connectors.add(slug);
                    } else {
                      _connectors.remove(slug);
                    }
                  }),
                ),
            ],
          ),
          if (_showError) ...[
            const SizedBox(height: 16),
            Text(
              strings.vehicleProfileInvalid,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(strings.vehicleProfileSave),
          ),
          if (widget.initial != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
              label: Text(strings.vehicleProfileDelete),
            ),
          ],
        ],
      ),
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label,
    String keyPrefix, {
    bool integer = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      key: ValueKey(keyPrefix),
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !integer),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(labelText: label),
    ),
  );

  double? _parseNumber(String text) =>
      double.tryParse(text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    final battery = _parseNumber(_battery.text);
    final consumption = _parseNumber(_consumption.text);
    final maxPower = _parseNumber(_maxPower.text);
    final reserve = int.tryParse(_reserve.text.trim());
    final target = int.tryParse(_target.text.trim());
    final start = int.tryParse(_start.text.trim());

    final profile = VehicleProfile(
      usableBatteryKwh: battery ?? 0,
      consumptionKwhPer100Km: consumption ?? 0,
      maxChargePowerKw: maxPower ?? 0,
      reserveSocPercent: reserve ?? -1,
      targetArrivalSocPercent: target ?? -1,
      defaultStartSocPercent: start ?? -1,
      connectorTypes: <String>[
        for (final (_, slug) in _connectorOptions)
          if (_connectors.contains(slug)) slug,
      ],
    );
    if (!profile.isComplete) {
      setState(() => _showError = true);
      return;
    }
    final strings = AppLocalizations.of(context);
    await ref.read(vehicleProfileControllerProvider.notifier).save(profile);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(strings.vehicleProfileSaved)));
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    await ref.read(vehicleProfileControllerProvider.notifier).clear();
    if (mounted) Navigator.of(context).pop();
  }
}

String _trimZeros(String value) =>
    value.contains('.') ? value.replaceAll(RegExp(r'\.?0+$'), '') : value;
