# ADR-0021 – Lokaler Fahrzeugprofil-Speicher

Status: Angenommen

Datum: 28. August 2026

## Kontext

Die Reichweiten- und Ladeplanung der Version 1.1 benötigt ein Fahrzeugprofil
([`../specification/17_Route_Planning.md`](../specification/17_Route_Planning.md),
`FR-ROUTE-005`): nutzbare Batteriekapazität, Durchschnittsverbrauch je 100
Kilometer, Reserve-Ladezustand, Ziel-Ladezustand bei Ankunft, maximale
Ladeleistung und kompatible Steckertypen.

Diese Angaben sind eine dauerhafte Nutzerpräferenz. Sie dürfen weder vom
austauschbaren Ladebestand abhängen noch ein Konto oder Backend voraussetzen.
Die App besitzt bereits einen schema-versionierten SQLite-Einstellungsspeicher
im Application-Support-Verzeichnis (`ADR-0016`) und einen getrennten
schreibbaren Favoritenspeicher (`ADR-0014`).

## Entscheidung

- Das Fahrzeugprofil wird im vorhandenen schema-versionierten
  Einstellungsspeicher abgelegt, nicht im Ladebestand und nicht im
  Favoritenspeicher. Es ist Nutzerpräferenzdatum mit demselben Lebenszyklus
  wie Sprache und Navigationswahl.
- Der Speicher erhält eine eigene Tabelle `vehicle_profiles` mit einer
  Primärschlüssel-`id`. Version 1.1 verwaltet genau ein Profil und einen
  Verweis auf das aktive Profil; das Schema erlaubt ohne Migration mehrere
  Profile.
- Gespeicherte Felder: nutzbare Kapazität in kWh, Verbrauch in kWh je 100 km,
  Reserve-Ladezustand in Prozent, Ziel-Ladezustand bei Ankunft in Prozent,
  maximale Ladeleistung in kW, Liste kompatibler Steckertypen sowie ein
  optionaler Vorgabewert für den Start-Ladezustand. Der Start-Ladezustand
  einer konkreten Fahrt ist flüchtiger Sitzungszustand und wird nicht im
  Profil überschrieben.
- Der Zugriff läuft über einen eigenen Repository-Vertrag
  `VehicleProfileRepository` in
  `app/lib/features/route_planning/domain/`; die SQLite-Umsetzung liegt unter
  `app/lib/data/settings/` und teilt sich die Datei mit den übrigen
  Einstellungen. Domänencode kennt nur den Vertrag.
- Die Schemaversion des Einstellungsspeichers wird angehoben. Eine
  Migration legt die neue Tabelle an, ohne bestehende Einstellungen zu
  verändern. Der Migrationspfad wird wie die bestehenden Settings-Migrationen
  automatisiert getestet.
- Fehlende oder unvollständige Profilwerte gelten als unbekannt. Ohne
  vollständiges Profil bleiben Basisroute, Korridorsuche und manuelle Stopps
  nutzbar; nur die Reichweiten- und Ladeplanung ist inaktiv.
- Das Profil wird ausschließlich lokal gespeichert und nicht übertragen
  (`NFR-ROUTE-PRIV-001`).

## Gründe

- Der vorhandene Einstellungsspeicher bietet bereits schema-versionierte
  Migration, Application-Support-Ablage und den passenden Lebenszyklus.
- Eine eigene Tabelle mit `id` hält den späteren Ausbau auf mehrere Profile
  offen, ohne Version 1.1 zu verkomplizieren.
- Die Trennung in einen eigenen Repository-Vertrag hält die Domäne frei von
  SQLite und erlaubt einfache Testdoppel.

## Folgen

- Das Fahrzeugprofil überlebt App-Neustarts und Datensatzwechsel und wird bei
  Deinstallation durch iOS entfernt.
- Eine spätere Erweiterung auf mehrere Profile, eine Profilauswahl in der
  Oberfläche oder zusätzliche Felder (etwa Ladekurvenkennung) kann dasselbe
  Schema migrationssicher fortschreiben.
- Der Einstellungsspeicher wächst um einen fachlich eigenständigen Bereich;
  die Settings-Repository-Umsetzung muss die neue Tabelle sauber von den
  Schlüssel-Wert-Einstellungen trennen.
