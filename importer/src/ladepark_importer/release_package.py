"""Deterministic static update package for FR-DATA-002."""

import gzip
import hashlib
import json
import shutil
import sqlite3
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from ladepark_importer.charging_sqlite import validate_charging_sqlite
from ladepark_importer.errors import ImporterError


@dataclass(frozen=True, slots=True)
class ReleasePackageResult:
    manifest: Path
    artifact: Path
    dataset_version: str
    compressed_size: int
    compressed_sha256: str


def build_release_package(
    database: Path,
    output: Path,
    repository: str,
    git_commit: str,
) -> ReleasePackageResult:
    validate_charging_sqlite(database)
    metadata = _metadata(database)
    dataset_version = metadata["dataset_version"]
    tag = f"dataset-{dataset_version}"
    artifact_name = f"charging-de-{dataset_version}.sqlite3.gz"
    output.mkdir(parents=True, exist_ok=True)
    artifact = output / artifact_name
    temporary = artifact.with_suffix(f"{artifact.suffix}.tmp")
    try:
        with (
            database.open("rb") as source,
            temporary.open("wb") as target,
            gzip.GzipFile(
                filename="",
                mode="wb",
                fileobj=target,
                compresslevel=6,
                mtime=0,
            ) as compressed,
        ):
            shutil.copyfileobj(source, compressed, length=1024 * 1024)
        temporary.replace(artifact)
    finally:
        temporary.unlink(missing_ok=True)

    repository = repository.strip().strip("/")
    if repository.count("/") != 1:
        raise ImporterError("GitHub-Repository muss als owner/name angegeben werden")
    artifact_url = f"https://github.com/{repository}/releases/download/{tag}/{artifact_name}"
    manifest_data: dict[str, Any] = {
        "manifest_format_version": 1,
        "dataset_id": metadata["dataset_id"],
        "dataset_version": dataset_version,
        "schema_version": int(metadata["schema_version"]),
        "created_at": metadata["created_at"],
        "region": metadata["region"],
        "pipeline_version": metadata["pipeline_version"],
        "git_commit": git_commit,
        "source": {
            "name": "Bundesnetzagentur Ladesäulenregister",
            "version": metadata["source_version"],
            "license": "CC-BY-4.0",
            "attribution": "bundesnetzagentur.de",
        },
        "compatibility": {
            "minimum_app_version": "1.0.0",
            "readable_schema_versions": [int(metadata["schema_version"])],
        },
        "artifacts": [
            {
                "type": "charging_sqlite_gzip",
                "url": artifact_url,
                "license": "CC-BY-4.0",
                "size_bytes": artifact.stat().st_size,
                "sha256": _sha256(artifact),
                "uncompressed_size_bytes": database.stat().st_size,
                "uncompressed_sha256": _sha256(database),
            }
        ],
    }
    manifest = output / "manifest.json"
    manifest.write_text(
        json.dumps(manifest_data, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    return ReleasePackageResult(
        manifest=manifest,
        artifact=artifact,
        dataset_version=dataset_version,
        compressed_size=artifact.stat().st_size,
        compressed_sha256=_sha256(artifact),
    )


def _metadata(database: Path) -> dict[str, str]:
    with sqlite3.connect(f"file:{database}?mode=ro", uri=True) as connection:
        values = dict(connection.execute("SELECT key, value FROM metadata"))
    required = {
        "dataset_id",
        "dataset_version",
        "schema_version",
        "created_at",
        "region",
        "pipeline_version",
        "source_version",
    }
    if missing := required.difference(values):
        raise ImporterError(f"Fehlende Release-Metadaten: {sorted(missing)}")
    return values


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()
