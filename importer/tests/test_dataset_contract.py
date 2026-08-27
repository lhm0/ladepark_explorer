import json
from pathlib import Path
from typing import Any

from ladepark_importer.charging_sqlite import (
    GroupQuery,
    query_groups,
    validate_charging_sqlite,
)

CONTRACT_DIRECTORY = Path(__file__).parents[2] / "contracts" / "charging_dataset" / "v2"

# Contract coverage for FR-DATA-001 and NFR-DATA-001.


def test_versioned_contract_fixture_is_valid() -> None:
    result = validate_charging_sqlite(CONTRACT_DIRECTORY / "fixture.sqlite3")

    assert result.station_count == 2
    assert result.evse_count == 3
    assert result.connector_count == 3
    assert result.diameter_count == 5


def test_reference_queries_match_contract_expectations() -> None:
    contract: dict[str, Any] = json.loads(
        (CONTRACT_DIRECTORY / "expectations.json").read_text(encoding="utf-8")
    )

    assert contract["schema_version"] == 2
    for case in contract["queries"]:
        result = query_groups(
            CONTRACT_DIRECTORY / "fixture.sqlite3",
            GroupQuery(**case["parameters"]),
        )
        assert [group["group_id"] for group in result.groups] == case["expected_group_ids"], case[
            "name"
        ]
