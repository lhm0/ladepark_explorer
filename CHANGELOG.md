# Änderungshistorie

Dieses Dokument fasst die veröffentlichten und intern eingefrorenen Stände der
App zusammen. Der laufende Detailstand steht in
[`PROJECT_STATUS.md`](PROJECT_STATUS.md); Scope und Verhalten sind in
[`docs/specification/`](docs/specification/) verbindlich.

## 1.1.0 – „Routen-Update“ (funktional eingefroren)

Ergänzt Version 1.0 um eine Routenplanung mit einfacher Reichweitenschätzung.
Meilensteine M14, M15, M16 und M19; spezifiziert in
[`docs/specification/17_Route_Planning.md`](docs/specification/17_Route_Planning.md),
Architektur in ADR-0019 bis ADR-0023 sowie dem Navigations-Nachtrag zu
ADR-0016.

- **Basisroute A→B** über Apple `MKDirections`, nativ als Overlay in der
  bestehenden `MKMapView`, mit Distanz, Fahrzeit, Alternativrouten und klaren
  Offline-, Fehler- und Drosselungszuständen (`FR-ROUTE-001/002`).
- **Korridorsuche:** Ladeparks entlang der Route unter den aktiven Filtern als
  orange Kartenmarker; die Korridorbreite ist je Fahrt einstellbar (20–60 km,
  10-km-Schritte). Ein Marker öffnet die Detailansicht mit „Ladestop einfügen“
  (`FR-ROUTE-003`).
- **Manuelle Ladestopps:** gesetzte Stopps liegen als blaue nummerierte
  Marker auf der Route, sind zum Entfernen antippbar, werden `MKDirections`
  als Wegpunkte übergeben und bleiben sichtbar, solange die Route angezeigt
  wird (`FR-ROUTE-004`).
- **Lokales Fahrzeugprofil** in den Einstellungen: nutzbare Kapazität,
  Verbrauch je 100 km, Reserve- und Ziel-Ladezustand, Ladeleistung und
  Steckertypen. Bleibt lokal und überlebt einen Neustart
  (`FR-ROUTE-005`, ADR-0021).
- **Farbige Ladezustandsroute:** die Linie verläuft von Grün über Gelb nach
  Rot, unter der Reserve dunkelrot; nach jedem Ladestopp beginnt sie wieder
  bei Grün. Start-Ladezustand und Ladeziel am Stopp (Vorgabe 80 %) sind je
  Fahrt einstellbar; eine Textzeile zeigt den Ladezustandsverlauf. Ein Stopp
  bleibt auch dann wirksam, wenn die Neuberechnung über ihn fehlschlägt
  (`FR-ROUTE-006`, ADR-0020/0023).
- **Routenübergabe an eine Navigations-App:** „In Navigation öffnen“ übergibt
  die geplante Route. Apple Maps erhält die vollständige Kette aus Start,
  Ladestopps und Ziel; Google Maps wird über sein App-Schema zum nächsten
  Ladestopp geführt, da das Schema keine Wegpunktkette annimmt. Es gelten die
  bestehende Navigationswahl und der Apple-Fallback (`FR-ROUTE-011`,
  ADR-0016 Nachtrag).
- **Kartenfilter überleben den App-Neustart** (`FR-FILTER-001`): die Auswahl
  wird lokal als JSON im Einstellungsspeicher abgelegt; der transiente
  Umkreisfilter wird nicht gespeichert.

Bewusst **nicht** in 1.1: der automatische Ladestopp-Vorschlag mit Ladezeit
und Gesamtreisezeit sowie die adaptive Neuplanung mit Sperren
(`FR-ROUTE-007` bis `FR-ROUTE-010`, Meilensteine M17/M18). Diese folgen als
**Version 1.2**. Die „intelligente“ Verbrauchsvorhersage (Straßenart,
Steigung, Temperatur, Ladekurve, Fahrergewohnheiten) bleibt hinter den
austauschbaren Schnittstellen `EnergyModel`, `ChargingModel` und
`StopPlanner` nachrüstbar.

## 1.0.0 – Grundstand (noch nicht veröffentlicht)

Meilensteine M0 bis M12: native MapKit-Karte mit dynamischen Abstandsgruppen,
lokaler SQLite-Datenzugriff im Hintergrund-Isolate, Ort-/Adress-/Koordinaten-
suche mit Umkreis, gekoppelte Lade- und Infrastrukturfilter, Detailansicht,
lokale Favoriten, eigener redaktioneller Vor-Ort-Informationsbestand mit
geprüften Fotos, Übergabe an Apple Maps oder Google Maps, Deutsch/Englisch,
statische verifizierte und atomare Datensatzupdates sowie eine bewusste
No-Telemetry-Entscheidung. Der Basisdatensatz `2026.07.0` ist als GitHub
Release verfügbar. Die Release-Härtung (M13: Zugänglichkeit, Gerätematrix,
Performance-Messung, App-Store-Vorbereitung) steht noch aus.
