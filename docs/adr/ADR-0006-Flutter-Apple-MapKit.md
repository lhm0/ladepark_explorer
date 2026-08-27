# ADR-0006 – Flutter-App mit Apple MapKit für Version 1.0

Status: Angenommen

Datum: 26. Juli 2026

## Kontext

Version 1.0 startet auf dem iPhone, soll aber ohne Neuentwicklung der
Fachlogik auf Android portierbar bleiben. Eine Kartenlösung mit
nutzungsabhängiger Abrechnung oder verpflichtendem Cloud-Abrechnungskonto
erzeugt für das privat finanzierte Projekt ein nicht akzeptables Kostenrisiko.

## Entscheidung

- Die gemeinsame App-Basis ist Flutter Stable; das erste Gerüst verwendet
  Flutter 3.44.8 und Dart 3.12.2.
- Version 1.0 unterstützt iOS ab Version 14.
- Das Android-Gerüst wird ab API 24 mitgeführt.
- Die iPhone-Karte verwendet natives Apple MapKit ohne Online-Geocoding.
- MapKit liegt hinter einer plattformneutralen Kartenschnittstelle. Ein
  späterer Android-Adapter kann eine andere Darstellungstechnologie,
  voraussichtlich MapLibre mit kontrollierter Kartenversorgung, verwenden.
- Ladeparkdaten, Suche und Filter stammen ausschließlich aus dem lokalen
  SQLite-Bestand. Apple Maps dient der Darstellung und externen Navigation,
  nicht der Datengewinnung.
- Die UI greift über ein `ChargingRepository` zu. Ladebestand und
  Benutzerspeicher bleiben getrennt.

## Folgen

Positiv:

- kein variables Kartenkostenrisiko in der iPhone-Version,
- reguläre native Apple-Kartenintegration und gute App-Store-Kompatibilität,
- gemeinsame Flutter-Fachlogik für iOS und Android,
- klar abgegrenzte spätere Android-Kartenimplementierung.

Negativ:

- die Kartenansicht selbst ist nicht vollständig gemeinsamer Plattformcode,
- MapKit-Integration und iOS-Build benötigen ein vollständiges Xcode,
- Android benötigt später einen eigenen Kartenadapter und eine gesondert
  bewertete Kartenversorgung.

## Verworfene Alternativen

- Google Maps wurde wegen des notwendigen Abrechnungskontos und des möglichen
  zukünftigen beziehungsweise missbrauchsbedingten Kostenrisikos verworfen.
- Öffentliche OSM-Kachelserver wurden wegen fehlender kommerzieller
  Verfügbarkeitsgarantie und der Tile Usage Policy verworfen.
- Ein eigener Kartenkachelbetrieb wird für Version 1.0 nicht vorgezogen, weil
  er zusätzliche Betriebs- und Lizenzkomplexität erzeugt.
