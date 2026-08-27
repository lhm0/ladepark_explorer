"""Schema-v1 contract for FR-DATA-004."""

SCHEMA_VERSION = 1
AMENITY_TYPES = ("restaurant", "shop", "coffee_machine", "snack_machine", "toilet")
AMENITY_STATES = ("present", "absent", "unknown")

SCHEMA_SQL = """
CREATE TABLE metadata (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
) WITHOUT ROWID;

CREATE TABLE park_info (
    park_info_id TEXT PRIMARY KEY,
    title TEXT,
    observed_on TEXT NOT NULL,
    reviewed_at TEXT NOT NULL,
    notes_de TEXT,
    notes_en TEXT
) WITHOUT ROWID;

CREATE TABLE park_info_station (
    park_info_id TEXT NOT NULL REFERENCES park_info(park_info_id),
    station_id TEXT NOT NULL,
    PRIMARY KEY (park_info_id, station_id)
) WITHOUT ROWID;

CREATE TABLE amenity (
    park_info_id TEXT NOT NULL REFERENCES park_info(park_info_id),
    amenity_type TEXT NOT NULL CHECK(amenity_type IN
      ('restaurant', 'shop', 'coffee_machine', 'snack_machine', 'toilet')),
    state TEXT NOT NULL CHECK(state IN ('present', 'absent', 'unknown')),
    PRIMARY KEY (park_info_id, amenity_type)
) WITHOUT ROWID;

CREATE TABLE photo (
    photo_id TEXT PRIMARY KEY,
    park_info_id TEXT NOT NULL REFERENCES park_info(park_info_id),
    asset_path TEXT NOT NULL UNIQUE,
    author TEXT NOT NULL,
    captured_on TEXT NOT NULL,
    file_sha256 TEXT NOT NULL CHECK(length(file_sha256) = 64),
    alt_de TEXT NOT NULL,
    alt_en TEXT,
    rights_reviewed_at TEXT NOT NULL,
    privacy_reviewed_at TEXT NOT NULL
) WITHOUT ROWID;

CREATE INDEX idx_park_info_station_station
ON park_info_station(station_id, park_info_id);
CREATE INDEX idx_photo_park ON photo(park_info_id, photo_id);
"""
