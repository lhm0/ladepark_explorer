# ADR-0022 – Routenkorridor-Suche über Abtastung der Polyline

Status: Angenommen

Datum: 28. August 2026

## Kontext

Version 1.1 zeigt Ladeparks in einem Korridor um die berechnete Route, die die
aktiven Filter erfüllen
([`../specification/17_Route_Planning.md`](../specification/17_Route_Planning.md),
`FR-ROUTE-003`). Der Ladebestand liegt read-only in einem Hintergrund-Isolate
mit FTS5-, Stations- und Gruppen-R\*Tree-Indizes. Die bestehende
Kartenabfrage `findGroups` beherrscht bereits Kartenausschnitt,
Gruppendurchmesser, gekoppelte Anzahl/Leistung, Betreiber, Connector,
Infrastruktur, 24/7, Favoriten und eine Umkreisabfrage (Bounding-Box plus
exakte Haversine-Distanz um ein Zentrum). Sie liefert höchstens 500 Ergebnisse
und folgt einem Latest-wins-Vertrag mit höchstens einer laufenden Abfrage.

Der sprachübergreifende Datensatzvertrag unter `contracts/charging_dataset/`
ist wie eine API zu behandeln: Änderungen an Tabellen, Metadaten oder
Abfragesemantik erfordern gemeinsame Anpassung von Python-Produzent,
Flutter-Konsument, Fixture und Vertrag (`ADR-0007`).

## Entscheidung

- Die Korridorsuche der Version 1.1 tastet die von `ADR-0019` gelieferte
  dezimierte Polyline in festem Abstand ab und führt je Abtastpunkt die
  vorhandene Umkreisabfrage (`center`, `radiusKm`) mit den aktiven Filtern
  aus. Die Teilergebnisse werden über `groupId` dedupliziert.
- Abtastabstand und Korridorradius sind konfigurierbar und dokumentiert. Mit
  M15 festgelegt: 20 Kilometer Abtastabstand, 10 Kilometer Korridorradius
  (`CorridorController.sampleSpacingKm` und `corridorRadiusKm`). Eine spätere
  Anpassung nach Feldtests bleibt möglich.
- Die Abfragen laufen sequentiell im bestehenden Charging-Isolate und halten
  den Latest-wins-Vertrag ein. Die Oberfläche zeigt einen Fortschritt, da die
  Korridorsuche länger dauern kann als eine einzelne Kartenabfrage.
- Für jeden Treffer berechnet die App lokal die Position entlang der Route
  (Streckenkilometer des nächsten Polylinienpunkts) und einen geschätzten
  Umweg (zusätzliche Distanz gegenüber dem Weiterfahren auf der Route). Dafür
  ist keine zusätzliche Netzabfrage nötig.
- Überschreitet die Gesamttrefferzahl die 500-Ergebnis-Grenze einer
  Teilabfrage, wird sichtbar begrenzt statt stillschweigend unvollständig
  dargestellt.
- Der Datensatzvertrag wird in Version 1.1 **nicht** geändert. Es entsteht
  keine neue SQLite-Abfrage und keine neue Schemaversion.
- Eine echte Korridorabfrage im Isolate – Übergabe der Polyline, R\*Tree-
  Vorauswahl, exakte Distanz zur Polylinie – bleibt eine mögliche spätere
  Optimierung. Sie würde eine Vertrags- und Fixture-Erweiterung nach `ADR-0007`
  auslösen und ist nur bei nachgewiesenem Performancebedarf vorzunehmen.

## Gründe

- Der Ansatz nutzt ausschließlich vorhandene, getestete Abfragepfade und
  ändert weder Schema noch Vertrag; das hält M15 klein und risikoarm.
- Die Zahl der Teilabfragen ist durch die Streckenlänge nach oben begrenzt und
  für typische Fahrten (einige zehn Abfragen) vertretbar.
- Position und Umweg lassen sich aus der dezimierten Polyline lokal und
  ausreichend genau bestimmen.
- Der teurere, aber effizientere Weg bleibt bewusst als spätere Option offen,
  ohne ihn jetzt zu bauen.

## Folgen

Positiv:

- keine Vertrags-, Schema- oder Fixture-Änderung in Version 1.1,
- vollständige Wiederverwendung der bestehenden Filter- und Umkreissemantik,
- klar begrenzter, überschaubarer Umsetzungsaufwand.

Negativ beziehungsweise zu beachten:

- Mehrere sequentielle Abfragen sind langsamer als eine einzige Abfrage; die
  Oberfläche braucht einen Fortschritt und `NFR-ROUTE-PERF-001` misst diesen
  Fall.
- Überlappende Umkreise erzeugen Doppeltreffer, die dedupliziert werden
  müssen.
- Ein sehr enger Abtastabstand bei sehr langen Strecken kann viele Abfragen
  erzeugen; Abstand und Radius sind entsprechend zu wählen und gegebenenfalls
  die spätere Isolate-Abfrage einzuführen.
- Die Korridorbreite ist eine Näherung; Zufahrten und Fahrtrichtung werden
  nicht bewertet.
