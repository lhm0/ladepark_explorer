#!/bin/sh

set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_file=${1:-"$repository_root/editorial/park_info/park-info.json"}
media_directory=${2:-"$repository_root/editorial/park_info/media"}
charging_database=${3:-"$repository_root/data/output/charging-de-2026.07.0.sqlite3"}

if [ ! -f "$charging_database" ]; then
  charging_database="$repository_root/app/assets/datasets/charging-2026.07.0-contract.sqlite3"
  echo "Vollständiger Ladebestand fehlt; Stationsreferenzen werden gegen das Contract-Fixture geprüft."
fi

cd "$repository_root/importer"
uv run ladepark-importer build-park-info \
  "$source_file" \
  --media "$media_directory" \
  --charging-database "$charging_database" \
  --output "$repository_root/app/assets/generated/park-info.sqlite3" \
  --media-output "$repository_root/app/assets/generated/park-info-media" \
  --replace
