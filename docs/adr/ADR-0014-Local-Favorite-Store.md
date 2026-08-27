# ADR-0014 – Getrennter lokaler Favoritenspeicher

Status: Angenommen

Datum: 26. August 2026

## Kontext

Der ausgelieferte Ladebestand ist versioniert und wird ausschließlich
read-only geöffnet. Dynamische Abstandsgruppen besitzen keine dauerhaft
stabile Gruppen-ID. Favoriten müssen App-Neustarts, Datensatzwechsel und eine
Änderung des Gruppendurchmessers überleben, dürfen aber in Version 1.0 weder
ein Konto noch ein fachliches Backend voraussetzen.

## Entscheidung

- Favoriten liegen in einer eigenen schreibbaren SQLite-Datenbank im
  Application-Support-Verzeichnis der App.
- Fachlicher Schlüssel ist die stabile `anchor_station_id`, nicht die
  `proximity_group_id`.
- Zusätzlich werden Speicherdatum, damaliger Gruppendurchmesser und ein kleiner
  Darstellungssnapshot gespeichert. Der Snapshot ersetzt keine aktuellen
  Ladedaten.
- Beim Öffnen wird die aktuelle Gruppe gesucht, die den Stationsanker beim
  aktuell gewählten Gruppendurchmesser enthält.
- Vor der Gruppenauflösung wird ein expliziter Eintrag in `station_id_alias`
  berücksichtigt. Eine geografische Näherungszuordnung findet nicht statt.
- Fehlt die Station, bleibt der Favorit mit seinem Snapshot als „derzeit nicht
  verfügbar“ erhalten.
- Der Kartenfilter „Nur Favoriten“ beschränkt Gruppen auf Mitgliedschaften der
  gespeicherten Ankerstationen. Stationsaliase werden dabei ebenso wie beim
  Öffnen eines Favoriten berücksichtigt; eine leere Favoritenmenge liefert ein
  leeres Kartenergebnis.
- Dieselbe Zuordnung ergänzt kompakte Kartenergebnisse um `isFavorite`. Der
  native MapKit-Adapter zeigt dafür ein System-Herz mit Blitz; es werden weder
  eigene Markerbilder noch Einzelabfragen pro sichtbarer Gruppe erzeugt.
- Favoriten erhalten keine MapKit-Clustering-ID. Ändert sich der Status einer
  bereits sichtbaren Annotation, wird sie einmal entfernt und wieder eingesetzt,
  damit MapKit ihre Clusterzuordnung unmittelbar neu berechnet.
- Favoriten erhalten die maximale MapKit-Z-Priorität. Das ist erforderlich,
  weil getrennte Abstandsgruppen nahezu identische repräsentative Koordinaten
  besitzen und sich ihre Marker andernfalls überdecken können.
- Schemaänderungen des Benutzerspeichers werden unabhängig vom
  Ladebestand versioniert.
- Die kleinen Favoritenoperationen werden asynchron gekapselt. Wegen der sehr
  geringen und begrenzten Datenmenge erhält der Benutzerspeicher in Version 1.0
  keinen eigenen langlebigen Isolate.

## Folgen

Favoriten werden durch den Austausch des Ladebestands nicht überschrieben und
können später um weitere rein lokale Einstellungen ergänzt werden. Eine
Deinstallation der App entfernt sie; geräteübergreifende Synchronisation ist
nicht Bestandteil von Version 1.0.

Die App benötigt einen plattformneutralen Pfad zum Application-Support-
Verzeichnis. Dafür wird `path_provider` verwendet. Der Ladebestand bleibt
unverändert read-only.
