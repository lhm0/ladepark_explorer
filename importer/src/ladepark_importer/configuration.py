import json
from dataclasses import dataclass
from pathlib import Path
from uuid import UUID

from ladepark_importer.errors import ImporterError
from ladepark_importer.normalization import normalize_text


@dataclass(frozen=True, slots=True)
class Namespaces:
    bnetza_station: UUID
    bnetza_evse: UUID
    external_evse: UUID
    connector: UUID
    operator: UUID
    proximity_group: UUID
    verified_park: UUID


def load_namespaces(path: Path) -> Namespaces:
    try:
        values = json.loads(path.read_text(encoding="utf-8"))
        return Namespaces(**{key: UUID(value) for key, value in values.items()})
    except (OSError, ValueError, TypeError) as error:
        raise ImporterError(
            f"Namespace-Konfiguration kann nicht gelesen werden: {error}"
        ) from error


def load_connector_types(path: Path) -> dict[str, tuple[str, ...]]:
    try:
        values = json.loads(path.read_text(encoding="utf-8"))
        mappings: dict[str, tuple[str, ...]] = {}
        for source_name, connector_types in values.items():
            normalized_source = normalize_text(source_name)
            if normalized_source is None or not isinstance(connector_types, list):
                raise ValueError("ungültiger Mappingeintrag")
            mappings[normalized_source.casefold()] = tuple(str(value) for value in connector_types)
        return mappings
    except (OSError, ValueError, TypeError) as error:
        raise ImporterError(
            f"Connector-Konfiguration kann nicht gelesen werden: {error}"
        ) from error
