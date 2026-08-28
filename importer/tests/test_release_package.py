import gzip
import hashlib
import json
from pathlib import Path

from ladepark_importer.release_package import build_release_package

CONTRACT_DATABASE = (
    Path(__file__).resolve().parents[2] / "contracts/charging_dataset/v2/fixture.sqlite3"
)


def test_builds_deterministic_verified_release_package(tmp_path: Path) -> None:
    first = build_release_package(
        CONTRACT_DATABASE, tmp_path / "first", "lhm0/ladepark_explorer", "abc123"
    )
    second = build_release_package(
        CONTRACT_DATABASE, tmp_path / "second", "lhm0/ladepark_explorer", "abc123"
    )

    assert first.artifact.read_bytes() == second.artifact.read_bytes()
    manifest = json.loads(first.manifest.read_text(encoding="utf-8"))
    artifact = manifest["artifacts"][0]
    assert manifest["manifest_format_version"] == 1
    assert artifact["size_bytes"] == first.artifact.stat().st_size
    assert artifact["sha256"] == hashlib.sha256(first.artifact.read_bytes()).hexdigest()
    assert gzip.decompress(first.artifact.read_bytes()) == CONTRACT_DATABASE.read_bytes()
