#!/bin/sh

set -eu

repository_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
source_database=${1:-"$repository_root/data/output/charging-de-2026.07.0.sqlite3"}
target_directory="$repository_root/app/assets/generated"
target_database="$target_directory/charging-de.sqlite3"
temporary_database="$target_directory/charging-de.sqlite3.tmp"

if [ ! -f "$source_database" ]; then
  echo "Datensatz nicht gefunden: $source_database" >&2
  exit 1
fi

schema_version=$(sqlite3 "$source_database" 'PRAGMA user_version;')
dataset_version=$(sqlite3 "$source_database" \
  "SELECT value FROM metadata WHERE key = 'dataset_version';")
region=$(sqlite3 "$source_database" \
  "SELECT value FROM metadata WHERE key = 'region';")

if [ "$schema_version" != "2" ] || [ -z "$dataset_version" ] || [ "$region" != "DE" ]; then
  echo "Datensatz besitzt keinen unterstützten deutschen Schema-v2-Vertrag." >&2
  exit 1
fi

mkdir -p "$target_directory"
cp "$source_database" "$temporary_database"
mv "$temporary_database" "$target_database"

echo "App-Datensatz vorbereitet: $target_database"
echo "Datensatzversion: $dataset_version"
