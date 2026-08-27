# ADR-0015 – Konservativer Filter für durchgehende Zugänglichkeit

Status: Angenommen

Datum: 27. August 2026

## Kontext

`FR-FILTER-001` verlangt eine Filterung nach Öffnungszeiten. Der
Bundesnetzagentur-Snapshot vom 7. Juli 2026 unterscheidet im Feld
`Öffnungszeiten` im Wesentlichen `247`, `Eingeschränkt` und `Keine Angabe` und
liefert bei bekannten Angaben zusätzlich Wochentage und Tageszeiten. Ein
vollständiger Kalender mit Feiertagen oder eine belastbare Aussage „jetzt
geöffnet“ ist daraus nicht ableitbar.

Die Mindestzahl und Mindestleistung der Ladepunkte bilden bereits eine
gekoppelte Bedingung. Ein bloßes 24/7-Angebot innerhalb einer gemischten Gruppe
darf deshalb nicht sämtliche Ladepunkte der Gruppe als durchgehend zugänglich
erscheinen lassen.

## Entscheidung

- Version 1.0 bietet den Öffnungszeitenfilter „Nur durchgehend zugängliche
  Ladeangebote“.
- Der Importer normalisiert jede Station konservativ in `always_open`,
  `restricted` oder `unknown`.
- `always_open` wird nur vergeben, wenn die Quellangabe eindeutig `247` oder
  `24/7` lautet und vorhandene strukturierte Zusatzfelder dem nicht
  widersprechen. Alle sieben Wochentage mit sieben ganztägigen Zeitintervallen
  gelten als bestätigende Darstellung.
- Fehlende, widersprüchliche oder nicht sicher interpretierbare Angaben bleiben
  `unknown`; es wird kein Wert geraten.
- Der Originaltext einschließlich Wochentagen und Tageszeiten bleibt im
  Ladebestand erhalten.
- Für jede dynamische Gruppe werden pro Leistungsgrenze ausschließlich EVSEs
  aus `always_open`-Stationen voraggregiert.
- Bei aktivem Filter müssen mindestens die eingestellte Zahl von Ladepunkten
  sowohl die Mindestleistung erfüllen als auch zu durchgehend zugänglichen
  Stationen gehören.
- Ein allgemeines Wochenzeitmodell und „jetzt geöffnet“ sind nicht Bestandteil
  dieser Entscheidung.

## Folgen

Der Filter besitzt eine klare, offline reproduzierbare Bedeutung und kann
nicht durch eine einzelne 24/7-Station in einer großen gemischten Gruppe
übererfüllt werden. Konservative Unbekanntwerte können echte 24/7-Angebote
ausblenden, erzeugen aber keine falsche Zusage. Das Charging-SQLite-Schema wird
auf Version 2 angehoben.
