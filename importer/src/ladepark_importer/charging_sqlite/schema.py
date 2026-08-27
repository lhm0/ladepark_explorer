"""Versioned schema contract for the charging SQLite artifact."""

SCHEMA_VERSION = 2
POWER_BANDS_KW = (0, 50, 100, 150, 200, 250, 300, 350)
SOURCE_ID = "bnetza-ladesaeulenregister"

# Implementiert das Austauschformat für FR-DATA-001 und NFR-DATA-001.

SCHEMA_SQL = """
CREATE TABLE metadata (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
) WITHOUT ROWID;

CREATE TABLE operator (
    operator_id TEXT PRIMARY KEY,
    canonical_name TEXT NOT NULL,
    display_name TEXT NOT NULL,
    website TEXT,
    website_verified_at TEXT,
    website_evidence TEXT
        CHECK(website_evidence IN ('operator_confirmation', 'manual_link_check'))
) WITHOUT ROWID;

CREATE TABLE operator_source (
    operator_source_id TEXT PRIMARY KEY,
    source_name TEXT NOT NULL UNIQUE,
    canonical_operator_id TEXT REFERENCES operator(operator_id)
) WITHOUT ROWID;

CREATE TABLE operator_filter_option (
    operator_id TEXT PRIMARY KEY REFERENCES operator(operator_id),
    station_count INTEGER NOT NULL CHECK(station_count > 0),
    evse_count INTEGER NOT NULL CHECK(evse_count > 0),
    dc_evse_count INTEGER NOT NULL CHECK(dc_evse_count >= 0),
    hpc_evse_count INTEGER NOT NULL CHECK(hpc_evse_count >= 0)
) WITHOUT ROWID;

CREATE TABLE station (
    station_id TEXT PRIMARY KEY,
    station_rowid INTEGER NOT NULL UNIQUE,
    operator_id TEXT REFERENCES operator(operator_id),
    operator_source_id TEXT NOT NULL REFERENCES operator_source(operator_source_id),
    source_status TEXT NOT NULL,
    station_type TEXT,
    name TEXT,
    latitude REAL NOT NULL CHECK(latitude BETWEEN -90 AND 90),
    longitude REAL NOT NULL CHECK(longitude BETWEEN -180 AND 180),
    street TEXT,
    house_number TEXT,
    postal_code TEXT,
    city TEXT,
    state TEXT,
    opening_hours_raw TEXT,
    opening_hours_weekdays_raw TEXT,
    opening_hours_times_raw TEXT,
    opening_hours_status TEXT NOT NULL
        CHECK(opening_hours_status IN ('always_open', 'restricted', 'unknown')),
    commissioned_on TEXT,
    data_updated_at TEXT,
    parking_information TEXT,
    payment_systems TEXT
) WITHOUT ROWID;

CREATE TABLE evse (
    evse_id TEXT PRIMARY KEY,
    station_id TEXT NOT NULL REFERENCES station(station_id),
    external_evse_id TEXT,
    source_slot INTEGER NOT NULL CHECK(source_slot > 0),
    current_type TEXT NOT NULL CHECK(current_type IN ('ac', 'dc', 'mixed', 'unknown')),
    max_power_kw REAL CHECK(max_power_kw >= 0),
    access_status TEXT NOT NULL CHECK(access_status IN ('public', 'restricted', 'unknown'))
) WITHOUT ROWID;

CREATE TABLE connector_type (
    connector_type TEXT PRIMARY KEY,
    display_key TEXT NOT NULL,
    current_type TEXT NOT NULL CHECK(current_type IN ('ac', 'dc', 'mixed', 'unknown'))
) WITHOUT ROWID;

CREATE TABLE connector (
    connector_id TEXT PRIMARY KEY,
    evse_id TEXT NOT NULL REFERENCES evse(evse_id),
    connector_type TEXT NOT NULL REFERENCES connector_type(connector_type),
    source_connector_type TEXT NOT NULL,
    max_power_kw REAL CHECK(max_power_kw >= 0)
) WITHOUT ROWID;

CREATE TABLE proximity_group (
    group_id TEXT PRIMARY KEY,
    group_rowid INTEGER NOT NULL UNIQUE,
    diameter_m INTEGER NOT NULL CHECK(diameter_m IN (25, 50, 100, 200, 300)),
    anchor_station_id TEXT NOT NULL REFERENCES station(station_id),
    medoid_station_id TEXT NOT NULL REFERENCES station(station_id),
    latitude REAL NOT NULL,
    longitude REAL NOT NULL,
    actual_diameter_m REAL NOT NULL CHECK(actual_diameter_m >= 0),
    station_count INTEGER NOT NULL CHECK(station_count >= 1),
    evse_count INTEGER NOT NULL CHECK(evse_count >= 1),
    ac_evse_count INTEGER NOT NULL CHECK(ac_evse_count >= 0),
    dc_evse_count INTEGER NOT NULL CHECK(dc_evse_count >= 0),
    hpc_evse_count INTEGER NOT NULL CHECK(hpc_evse_count >= 0),
    max_power_kw REAL CHECK(max_power_kw >= 0)
) WITHOUT ROWID;

CREATE TABLE proximity_group_member (
    group_id TEXT NOT NULL REFERENCES proximity_group(group_id),
    station_id TEXT NOT NULL REFERENCES station(station_id),
    PRIMARY KEY (group_id, station_id)
) WITHOUT ROWID;

CREATE TABLE group_operator_source (
    group_id TEXT NOT NULL REFERENCES proximity_group(group_id),
    operator_source_id TEXT NOT NULL REFERENCES operator_source(operator_source_id),
    evse_count INTEGER NOT NULL CHECK(evse_count > 0),
    PRIMARY KEY (operator_source_id, group_id)
) WITHOUT ROWID;

CREATE TABLE group_operator (
    group_id TEXT NOT NULL REFERENCES proximity_group(group_id),
    operator_id TEXT NOT NULL REFERENCES operator(operator_id),
    evse_count INTEGER NOT NULL CHECK(evse_count > 0),
    PRIMARY KEY (group_id, operator_id)
) WITHOUT ROWID;

CREATE TABLE group_power_band (
    group_id TEXT NOT NULL REFERENCES proximity_group(group_id),
    minimum_power_kw INTEGER NOT NULL
        CHECK(minimum_power_kw IN (0, 50, 100, 150, 200, 250, 300, 350)),
    evse_count INTEGER NOT NULL CHECK(evse_count > 0),
    PRIMARY KEY (minimum_power_kw, group_id)
) WITHOUT ROWID;

CREATE TABLE group_always_open_power_band (
    group_id TEXT NOT NULL REFERENCES proximity_group(group_id),
    minimum_power_kw INTEGER NOT NULL
        CHECK(minimum_power_kw IN (0, 50, 100, 150, 200, 250, 300, 350)),
    evse_count INTEGER NOT NULL CHECK(evse_count > 0),
    PRIMARY KEY (minimum_power_kw, group_id)
) WITHOUT ROWID;

CREATE TABLE group_connector (
    group_id TEXT NOT NULL REFERENCES proximity_group(group_id),
    connector_type TEXT NOT NULL REFERENCES connector_type(connector_type),
    evse_count INTEGER NOT NULL CHECK(evse_count > 0),
    PRIMARY KEY (connector_type, group_id)
) WITHOUT ROWID;

CREATE TABLE source (
    source_id TEXT PRIMARY KEY,
    source_type TEXT NOT NULL,
    name TEXT NOT NULL,
    snapshot_version TEXT NOT NULL,
    source_url TEXT NOT NULL,
    license TEXT NOT NULL,
    attribution TEXT NOT NULL,
    sha256 TEXT NOT NULL
) WITHOUT ROWID;

CREATE TABLE source_reference (
    object_type TEXT NOT NULL CHECK(object_type IN ('station', 'evse')),
    object_id TEXT NOT NULL,
    source_id TEXT NOT NULL REFERENCES source(source_id),
    external_id TEXT NOT NULL,
    PRIMARY KEY (object_type, object_id, source_id)
) WITHOUT ROWID;

CREATE TABLE station_id_alias (
    old_station_id TEXT PRIMARY KEY,
    current_station_id TEXT NOT NULL REFERENCES station(station_id),
    reason TEXT NOT NULL
) WITHOUT ROWID;

CREATE TABLE operator_link (
    operator_link_id TEXT PRIMARY KEY,
    operator_id TEXT NOT NULL REFERENCES operator(operator_id),
    station_id TEXT REFERENCES station(station_id),
    url TEXT NOT NULL CHECK(url LIKE 'https://%'),
    link_type TEXT NOT NULL CHECK(link_type IN ('operator_home', 'official_location_page')),
    checked_at TEXT NOT NULL,
    title TEXT NOT NULL,
    matching_method TEXT NOT NULL,
    matching_status TEXT NOT NULL
        CHECK(matching_status IN ('verified', 'needs_confirmation', 'rejected')),
    permission_reference TEXT
) WITHOUT ROWID;

CREATE INDEX idx_evse_station_power ON evse(station_id, max_power_kw);
CREATE INDEX idx_station_operator_source ON station(operator_source_id, station_id);
CREATE INDEX idx_connector_evse_type ON connector(evse_id, connector_type);
CREATE INDEX idx_group_diameter ON proximity_group(diameter_m, group_id);
CREATE INDEX idx_group_member_station ON proximity_group_member(station_id, group_id);
CREATE INDEX idx_group_operator ON group_operator(operator_id, group_id);
CREATE INDEX idx_operator_link ON operator_link(operator_id, station_id);
CREATE INDEX idx_operator_filter_rank ON operator_filter_option(evse_count DESC, operator_id);

CREATE VIRTUAL TABLE station_geo USING rtree(
    station_rowid,
    min_latitude, max_latitude,
    min_longitude, max_longitude
);

CREATE VIRTUAL TABLE proximity_group_geo USING rtree(
    group_rowid,
    min_latitude, max_latitude,
    min_longitude, max_longitude
);

CREATE VIRTUAL TABLE station_search USING fts5(
    station_id UNINDEXED,
    name,
    city,
    postal_code,
    street,
    operator_name,
    tokenize='unicode61 remove_diacritics 2'
);
"""
