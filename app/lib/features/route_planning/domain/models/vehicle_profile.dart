/// Local vehicle profile for the range and charging estimation (FR-ROUTE-005,
/// ADR-0021). Version 1.1 supports exactly one profile.
class VehicleProfile {
  const VehicleProfile({
    this.usableBatteryKwh = 0,
    this.consumptionKwhPer100Km = 0,
    this.maxChargePowerKw = 0,
    this.reserveSocPercent = 10,
    this.targetArrivalSocPercent = 80,
    this.defaultStartSocPercent = 90,
    this.connectorTypes = const <String>[],
  });

  /// Usable battery capacity in kWh.
  final double usableBatteryKwh;

  /// Average consumption in kWh per 100 km.
  final double consumptionKwhPer100Km;

  /// Maximum charging power the vehicle accepts, in kW.
  final double maxChargePowerKw;

  /// Reserve state of charge kept in the plan, in percent.
  final int reserveSocPercent;

  /// Desired state of charge on arrival, in percent. Also the assumed
  /// departure state of charge after a stop until FR-ROUTE-008.
  final int targetArrivalSocPercent;

  /// Default state of charge at the start of a trip, in percent. A trip may
  /// override this.
  final int defaultStartSocPercent;

  /// Connector types the vehicle can use, as dataset slugs.
  final List<String> connectorTypes;

  /// Whether the profile has the values the range estimation needs.
  bool get isComplete =>
      usableBatteryKwh > 0 &&
      consumptionKwhPer100Km > 0 &&
      maxChargePowerKw > 0 &&
      reserveSocPercent >= 0 &&
      reserveSocPercent < targetArrivalSocPercent &&
      targetArrivalSocPercent <= 100 &&
      defaultStartSocPercent >= 0 &&
      defaultStartSocPercent <= 100;

  VehicleProfile copyWith({
    double? usableBatteryKwh,
    double? consumptionKwhPer100Km,
    double? maxChargePowerKw,
    int? reserveSocPercent,
    int? targetArrivalSocPercent,
    int? defaultStartSocPercent,
    List<String>? connectorTypes,
  }) => VehicleProfile(
    usableBatteryKwh: usableBatteryKwh ?? this.usableBatteryKwh,
    consumptionKwhPer100Km:
        consumptionKwhPer100Km ?? this.consumptionKwhPer100Km,
    maxChargePowerKw: maxChargePowerKw ?? this.maxChargePowerKw,
    reserveSocPercent: reserveSocPercent ?? this.reserveSocPercent,
    targetArrivalSocPercent:
        targetArrivalSocPercent ?? this.targetArrivalSocPercent,
    defaultStartSocPercent:
        defaultStartSocPercent ?? this.defaultStartSocPercent,
    connectorTypes: connectorTypes ?? this.connectorTypes,
  );

  @override
  bool operator ==(Object other) =>
      other is VehicleProfile &&
      usableBatteryKwh == other.usableBatteryKwh &&
      consumptionKwhPer100Km == other.consumptionKwhPer100Km &&
      maxChargePowerKw == other.maxChargePowerKw &&
      reserveSocPercent == other.reserveSocPercent &&
      targetArrivalSocPercent == other.targetArrivalSocPercent &&
      defaultStartSocPercent == other.defaultStartSocPercent &&
      _sameList(connectorTypes, other.connectorTypes);

  @override
  int get hashCode => Object.hash(
    usableBatteryKwh,
    consumptionKwhPer100Km,
    maxChargePowerKw,
    reserveSocPercent,
    targetArrivalSocPercent,
    defaultStartSocPercent,
    Object.hashAll(connectorTypes),
  );
}

bool _sameList(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
