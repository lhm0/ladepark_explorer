import re
from dataclasses import dataclass

from ladepark_importer.errors import SchemaError

STATION_ID_COLUMN = "Ladeeinrichtungs-ID"

REQUIRED_COLUMNS = frozenset(
    {
        STATION_ID_COLUMN,
        "Betreiber",
        "Status",
        "Anzahl Ladepunkte",
        "Straße",
        "Hausnummer",
        "Postleitzahl",
        "Ort",
        "Breitengrad",
        "Längengrad",
    }
)

KNOWN_BASE_COLUMNS = frozenset(
    {
        *REQUIRED_COLUMNS,
        "Anzeigename (Karte)",
        "Art der Ladeeinrichtung",
        "Nennleistung Ladeeinrichtung [kW]",
        "Inbetriebnahmedatum",
        "Adresszusatz",
        "Kreis/kreisfreie Stadt",
        "Bundesland",
        "Standortbezeichnung",
        "Informationen zum Parkraum",
        "Bezahlsysteme",
        "Öffnungszeiten",
        "Öffnungszeiten: Wochentage",
        "Öffnungszeiten: Tageszeiten",
    }
)

SLOT_COLUMN_PATTERN = re.compile(
    r"^(Steckertypen|Nennleistung Stecker|EVSE-ID|Public Key)([1-9][0-9]*)$"
)


@dataclass(frozen=True, slots=True)
class SourceSchema:
    headers: tuple[str, ...]
    slot_numbers: tuple[int, ...]
    unknown_columns: tuple[str, ...]


def inspect_schema(headers: tuple[str, ...]) -> SourceSchema:
    cleaned = tuple(header.strip() for header in headers)
    if len(set(cleaned)) != len(cleaned):
        duplicates = sorted({header for header in cleaned if cleaned.count(header) > 1})
        raise SchemaError(f"Doppelte Spalten: {', '.join(duplicates)}")

    missing = sorted(REQUIRED_COLUMNS - set(cleaned))
    if missing:
        raise SchemaError(f"Fehlende Pflichtspalten: {', '.join(missing)}")

    slots: set[int] = set()
    unknown: list[str] = []
    for header in cleaned:
        if header in KNOWN_BASE_COLUMNS:
            continue
        match = SLOT_COLUMN_PATTERN.fullmatch(header)
        if match is None:
            unknown.append(header)
            continue
        slots.add(int(match.group(2)))

    if not slots:
        raise SchemaError("Keine Ladepunkt-Slotspalten gefunden")

    for slot in slots:
        required_slot_columns = {
            f"Steckertypen{slot}",
            f"Nennleistung Stecker{slot}",
        }
        missing_slot_columns = sorted(required_slot_columns - set(cleaned))
        if missing_slot_columns:
            raise SchemaError(
                f"Unvollständiger Ladepunkt-Slot {slot}: {', '.join(missing_slot_columns)}"
            )

    return SourceSchema(
        headers=cleaned,
        slot_numbers=tuple(sorted(slots)),
        unknown_columns=tuple(sorted(unknown)),
    )
