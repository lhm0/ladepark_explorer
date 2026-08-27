"""Reproducible builder for manually curated park information and own photos."""

import hashlib
import json
import shutil
import sqlite3
from dataclasses import dataclass
from datetime import date, datetime
from pathlib import Path
from typing import Any

from ladepark_importer.errors import ImporterError
from ladepark_importer.park_info.schema import (
    AMENITY_STATES,
    AMENITY_TYPES,
    SCHEMA_SQL,
    SCHEMA_VERSION,
)


@dataclass(frozen=True)
class ParkInfoBuildResult:
    database: str
    media_directory: str
    park_count: int
    station_reference_count: int
    amenity_count: int
    photo_count: int
    sha256: str


def build_park_info_sqlite(
    source: Path,
    media_source: Path,
    charging_database: Path,
    output: Path,
    media_output: Path,
    *,
    replace: bool = False,
) -> ParkInfoBuildResult:
    document = _load_document(source)
    parks = _list(document, "parks")
    metadata = _metadata(document)
    station_ids = _charging_station_ids(charging_database)
    _validate_document(parks, media_source, station_ids)
    if output.exists() and not replace:
        raise ImporterError(f"Zieldatei existiert bereits: {output}")
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(f"{output.suffix}.tmp")
    if temporary.exists():
        temporary.unlink()
    connection = sqlite3.connect(temporary)
    try:
        connection.execute("PRAGMA foreign_keys = ON")
        connection.execute(f"PRAGMA user_version = {SCHEMA_VERSION}")
        connection.executescript(SCHEMA_SQL)
        connection.executemany(
            "INSERT INTO metadata(key, value) VALUES (?, ?)", sorted(metadata.items())
        )
        for park in sorted(parks, key=lambda item: _text(item, "park_info_id")):
            park_id = _text(park, "park_info_id")
            connection.execute(
                "INSERT INTO park_info VALUES (?, ?, ?, ?, ?, ?)",
                (
                    park_id,
                    _optional_text(park, "title"),
                    _date(park, "observed_on"),
                    _timestamp(park, "reviewed_at"),
                    _optional_text(park, "notes_de"),
                    _optional_text(park, "notes_en"),
                ),
            )
            connection.executemany(
                "INSERT INTO park_info_station VALUES (?, ?)",
                [(park_id, item) for item in sorted(_string_list(park, "station_ids"))],
            )
            amenities = _dict(park, "amenities")
            connection.executemany(
                "INSERT INTO amenity VALUES (?, ?, ?)",
                [(park_id, kind, amenities[kind]) for kind in AMENITY_TYPES],
            )
            for photo in sorted(_list(park, "photos"), key=lambda item: _text(item, "photo_id")):
                file_name = _safe_file_name(_text(photo, "file"))
                asset_path = f"assets/generated/park-info-media/{file_name}"
                connection.execute(
                    "INSERT INTO photo VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    (
                        _text(photo, "photo_id"),
                        park_id,
                        asset_path,
                        _text(photo, "author"),
                        _date(photo, "captured_on"),
                        _text(photo, "sha256").lower(),
                        _text(photo, "alt_de"),
                        _optional_text(photo, "alt_en"),
                        _timestamp(photo, "rights_reviewed_at"),
                        _timestamp(photo, "privacy_reviewed_at"),
                    ),
                )
        connection.commit()
        connection.execute("VACUUM")
    except (sqlite3.Error, KeyError, TypeError, ValueError) as error:
        raise ImporterError(f"Redaktioneller SQLite-Build fehlgeschlagen: {error}") from error
    finally:
        connection.close()
    validate_park_info_sqlite(temporary)
    if output.exists():
        output.unlink()
    temporary.replace(output)
    _replace_media(parks, media_source, media_output)
    return ParkInfoBuildResult(
        database=str(output),
        media_directory=str(media_output),
        park_count=len(parks),
        station_reference_count=sum(len(_string_list(park, "station_ids")) for park in parks),
        amenity_count=len(parks) * len(AMENITY_TYPES),
        photo_count=sum(len(_list(park, "photos")) for park in parks),
        sha256=_sha256(output),
    )


def validate_park_info_sqlite(database: Path) -> None:
    try:
        connection = sqlite3.connect(f"file:{database}?mode=ro", uri=True)
        integrity = connection.execute("PRAGMA integrity_check").fetchone()
        if integrity != ("ok",):
            raise ImporterError(f"SQLite integrity_check fehlgeschlagen: {integrity}")
        if connection.execute("PRAGMA user_version").fetchone() != (SCHEMA_VERSION,):
            raise ImporterError("Nicht unterstützte park_info-Schemaversion")
        required = {"dataset_version", "created_at", "schema_version", "source_type"}
        keys = {row[0] for row in connection.execute("SELECT key FROM metadata")}
        if not required <= keys:
            raise ImporterError(f"Fehlende park_info-Metadaten: {sorted(required - keys)}")
        if connection.execute("PRAGMA foreign_key_check").fetchall():
            raise ImporterError("park_info enthält Fremdschlüsselfehler")
    except sqlite3.Error as error:
        raise ImporterError(f"park_info-Validierung fehlgeschlagen: {error}") from error
    finally:
        if "connection" in locals():
            connection.close()


def _load_document(source: Path) -> dict[str, Any]:
    try:
        value = json.loads(source.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise ImporterError(
            f"Redaktionelle Quelldatei kann nicht gelesen werden: {error}"
        ) from error
    if not isinstance(value, dict):
        raise ImporterError("Redaktionelle Quelldatei muss ein JSON-Objekt sein")
    return value


def _metadata(document: dict[str, Any]) -> dict[str, str]:
    return {
        "dataset_version": _text(document, "dataset_version"),
        "created_at": _timestamp(document, "created_at"),
        "schema_version": str(SCHEMA_VERSION),
        "source_type": "own_on_site_research",
    }


def _charging_station_ids(database: Path) -> set[str]:
    try:
        with sqlite3.connect(f"file:{database}?mode=ro", uri=True) as connection:
            return {row[0] for row in connection.execute("SELECT station_id FROM station")}
    except sqlite3.Error as error:
        raise ImporterError(f"Ladebestand kann nicht geprüft werden: {error}") from error


def _validate_document(parks: list[dict[str, Any]], media: Path, station_ids: set[str]) -> None:
    park_ids: set[str] = set()
    photo_ids: set[str] = set()
    files: set[str] = set()
    for park in parks:
        park_id = _text(park, "park_info_id")
        if park_id in park_ids:
            raise ImporterError(f"Doppelte park_info_id: {park_id}")
        park_ids.add(park_id)
        if _text(park, "review_status") != "approved":
            raise ImporterError(f"Nicht freigegebener Eintrag: {park_id}")
        missing = set(_string_list(park, "station_ids")) - station_ids
        if missing:
            raise ImporterError(f"Unbekannte Stations-IDs in {park_id}: {sorted(missing)}")
        amenities = _dict(park, "amenities")
        if set(amenities) != set(AMENITY_TYPES):
            raise ImporterError(f"{park_id}: genau fünf Infrastrukturmerkmale sind erforderlich")
        invalid = {str(value) for value in amenities.values()} - set(AMENITY_STATES)
        if invalid:
            raise ImporterError(f"{park_id}: ungültige Infrastrukturzustände {sorted(invalid)}")
        _date(park, "observed_on")
        _timestamp(park, "reviewed_at")
        for photo in _list(park, "photos"):
            photo_id = _text(photo, "photo_id")
            file_name = _safe_file_name(_text(photo, "file"))
            if photo_id in photo_ids or file_name in files:
                raise ImporterError(f"Doppeltes Foto oder Medienziel: {photo_id}/{file_name}")
            photo_ids.add(photo_id)
            files.add(file_name)
            path = media / file_name
            if not path.is_file():
                raise ImporterError(f"Fotodatei fehlt: {path}")
            expected = _text(photo, "sha256").lower()
            if len(expected) != 64 or _sha256(path) != expected:
                raise ImporterError(f"Foto-Prüfsumme stimmt nicht: {path}")
            _text(photo, "author")
            _text(photo, "alt_de")
            _date(photo, "captured_on")
            _timestamp(photo, "rights_reviewed_at")
            _timestamp(photo, "privacy_reviewed_at")


def _replace_media(parks: list[dict[str, Any]], source: Path, output: Path) -> None:
    temporary = output.with_name(f"{output.name}.tmp")
    if temporary.exists():
        shutil.rmtree(temporary)
    temporary.mkdir(parents=True)
    (temporary / ".gitkeep").touch()
    for park in parks:
        for photo in _list(park, "photos"):
            name = _safe_file_name(_text(photo, "file"))
            shutil.copyfile(source / name, temporary / name)
    if output.exists():
        shutil.rmtree(output)
    temporary.replace(output)


def _safe_file_name(value: str) -> str:
    path = Path(value)
    if path.name != value or path.suffix.lower() not in {".jpg", ".jpeg", ".png", ".webp"}:
        raise ImporterError(f"Ungültiger veröffentlichter Bildname: {value}")
    return value


def _text(value: dict[str, Any], key: str) -> str:
    result = value.get(key)
    if not isinstance(result, str) or not result.strip():
        raise ImporterError(f"Pflichtfeld fehlt oder ist leer: {key}")
    return result.strip()


def _optional_text(value: dict[str, Any], key: str) -> str | None:
    result = value.get(key)
    if result is None:
        return None
    if not isinstance(result, str):
        raise ImporterError(f"Feld muss Text sein: {key}")
    return result.strip() or None


def _date(value: dict[str, Any], key: str) -> str:
    result = _text(value, key)
    try:
        date.fromisoformat(result)
    except ValueError as error:
        raise ImporterError(f"Ungültiges ISO-Datum in {key}: {result}") from error
    return result


def _timestamp(value: dict[str, Any], key: str) -> str:
    result = _text(value, key)
    try:
        datetime.fromisoformat(result.replace("Z", "+00:00"))
    except ValueError as error:
        raise ImporterError(f"Ungültiger RFC-3339-Zeitpunkt in {key}: {result}") from error
    return result


def _list(value: dict[str, Any], key: str) -> list[dict[str, Any]]:
    result = value.get(key)
    if not isinstance(result, list) or any(not isinstance(item, dict) for item in result):
        raise ImporterError(f"Feld muss eine Objektliste sein: {key}")
    return result


def _dict(value: dict[str, Any], key: str) -> dict[str, Any]:
    result = value.get(key)
    if not isinstance(result, dict):
        raise ImporterError(f"Feld muss ein Objekt sein: {key}")
    return result


def _string_list(value: dict[str, Any], key: str) -> list[str]:
    result = value.get(key)
    if (
        not isinstance(result, list)
        or not result
        or any(not isinstance(item, str) for item in result)
    ):
        raise ImporterError(f"Feld muss eine nicht leere Textliste sein: {key}")
    return [item.strip() for item in result]


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()
