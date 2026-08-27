import json
from pathlib import Path
from uuid import UUID

import pytest

from ladepark_importer.errors import ImporterError
from ladepark_importer.operator_registry import load_operator_registry

OPERATOR_NAMESPACE = UUID("fc0ee23e-bbe3-4192-b54d-ae40244d72af")


def test_registry_operator_id_is_stable_for_registry_key(tmp_path: Path) -> None:
    path = _write_registry(
        tmp_path,
        [
            _entry("example", "Example GmbH", ["Example GmbH"]),
        ],
    )

    first = load_operator_registry(path, OPERATOR_NAMESPACE, {"Example GmbH"})
    second = load_operator_registry(path, OPERATOR_NAMESPACE, {"Example GmbH"})

    assert first.operators[0].operator_id == second.operators[0].operator_id


def test_registry_rejects_alias_assigned_to_two_operators(tmp_path: Path) -> None:
    path = _write_registry(
        tmp_path,
        [
            _entry("first", "First GmbH", ["Shared GmbH"]),
            _entry("second", "Second GmbH", ["Shared GmbH"]),
        ],
    )

    with pytest.raises(ImporterError, match="Alias mehrfach zugeordnet"):
        load_operator_registry(path, OPERATOR_NAMESPACE, {"Shared GmbH"})


def test_registry_rejects_unknown_source_alias(tmp_path: Path) -> None:
    path = _write_registry(
        tmp_path,
        [_entry("unknown", "Unknown GmbH", ["Not in source"])],
    )

    with pytest.raises(ImporterError, match="Unbekannter BNetzA-Alias"):
        load_operator_registry(path, OPERATOR_NAMESPACE, {"Known GmbH"})


def _entry(key: str, canonical_name: str, aliases: list[str]) -> dict[str, object]:
    return {
        "registry_key": key,
        "canonical_name": canonical_name,
        "display_name": canonical_name,
        "status": "reviewed",
        "aliases": aliases,
        "reviewed_at": "2026-08-24",
        "rationale": "Testentscheidung",
    }


def _write_registry(tmp_path: Path, operators: list[dict[str, object]]) -> Path:
    path = tmp_path / "operators.json"
    path.write_text(
        json.dumps({"version": 1, "operators": operators}),
        encoding="utf-8",
    )
    return path
