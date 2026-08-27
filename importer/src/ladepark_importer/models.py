from dataclasses import asdict, dataclass
from decimal import Decimal
from typing import Any, cast


@dataclass(frozen=True, slots=True)
class Address:
    street: str
    house_number: str | None
    postal_code: str
    city: str
    address_addition: str | None
    district: str | None
    federal_state: str | None


@dataclass(frozen=True, slots=True)
class Connector:
    connector_id: str
    evse_id: str
    connector_type: str
    source_type: str
    max_power_kw: Decimal | None


@dataclass(frozen=True, slots=True)
class Evse:
    evse_id: str
    station_id: str
    source_evse_id: str | None
    source_slot: int
    max_power_kw: Decimal
    current_type: str
    connectors: tuple[Connector, ...]


@dataclass(frozen=True, slots=True)
class Station:
    station_id: str
    source_station_id: str
    operator_source_name: str
    display_name: str | None
    status: str
    station_type: str | None
    declared_evse_count: int
    nominal_power_kw: Decimal | None
    latitude: Decimal
    longitude: Decimal
    address: Address
    location_name: str | None
    parking_information: str | None
    payment_systems: str | None
    opening_hours: str | None
    opening_hours_weekdays: str | None
    opening_hours_times: str | None
    evses: tuple[Evse, ...]


@dataclass(frozen=True, slots=True)
class NormalizedSnapshot:
    stations: tuple[Station, ...]
    warnings: tuple[str, ...]

    @property
    def evse_count(self) -> int:
        return sum(len(station.evses) for station in self.stations)

    @property
    def connector_count(self) -> int:
        return sum(len(evse.connectors) for station in self.stations for evse in station.evses)

    def to_dict(self) -> dict[str, Any]:
        return cast(dict[str, Any], _json_value(asdict(self)))


def _json_value(value: Any) -> Any:
    if isinstance(value, Decimal):
        return str(value)
    if isinstance(value, dict):
        return {key: _json_value(item) for key, item in value.items()}
    if isinstance(value, (list, tuple)):
        return [_json_value(item) for item in value]
    return value
