# Dynamische Abstandsgruppierung

Status: Kernalgorithmus und Referenzfälle implementiert

Stand: 26. Juli 2026

## 0. Implementierungsstand

Implementiert:

- Haversine-Distanz mit festem mittlerem Erdradius `6.371.008,8 m`,
- Grenzvergleich mit einer ausschließlich numerischen Toleranz von
  `0,0000001 m`,
- deterministisches agglomeratives Complete Linkage,
- räumliches Raster zur Kandidatensuche ohne Änderung der fachlichen
  Distanzentscheidung,
- Gruppen-ID, Ankerstation und Medoid gemäß dieser Spezifikation,
- alle zehn Referenzfälle sowie zusätzliche Determinismus-, Medoid- und
  Vergleichstests gegen eine naive Referenzimplementierung,
- kompakter CLI-Qualitätsbericht je Datensatzversion und Durchmesser.
- CSV-Review-Export als Vereinigung der Top-Gruppen nach Stations-, EVSE- und
  HPC-Zahl; HPC ist dabei DC mit mindestens 100 kW.

Der Algorithmus ist ein Build-Schritt. Alle fünf Varianten werden beim
SQLite-Build vorberechnet, gespeichert und anschließend auf Vollständigkeit,
Eindeutigkeit der Mitgliedschaften und Einhaltung des Maximaldurchmessers
validiert.

## 1. Ziel und Semantik

Version 1.0 fasst BNetzA-Ladeeinrichtungen ausschließlich anhand ihrer
Koordinaten räumlich zusammen. Das Ergebnis heißt `proximity_group` und ist
eine Näherung, kein bestätigter gemeinsamer Parkplatz.

Die Gruppierung beantwortet:

> Welche Ladeeinrichtungen liegen bei dem gewählten maximalen
> Gruppendurchmesser räumlich nahe genug, um gemeinsam dargestellt und
> ausgewertet zu werden?

Sie beantwortet nicht:

- Nutzen alle Stationen dieselbe Zufahrt?
- Liegen sie auf demselben Grundstück oder Parkplatz?
- Können Fahrzeuge ohne Umweg zwischen den Stationen wechseln?
- Handelt es sich nach Betreiberverständnis um einen gemeinsamen Ladepark?

Diese Einschränkung muss in der App transparent erklärt werden.

## 2. Eingabe und Ausgabe

Eingabe:

- Datensatzversion,
- stabile `station_id`,
- BNetzA-Breiten- und Längengrad jeder Station,
- gewählter maximaler Gruppendurchmesser.

Version 1.0 verwendet nicht:

- Betreiber oder Adresse,
- Standort- oder Parkraumtext,
- OSM-Geometrien oder -Tags,
- Google- oder Apple-Karten,
- Webseiteninhalte,
- manuelle Merge-/Splitentscheidungen ohne ausdrückliche
  Betreiberbestätigung.

Ausgabe pro Gruppe:

- kontextbezogene `proximity_group_id`,
- `anchor_station_id`,
- sortierte Stations-IDs,
- eingestellter Durchmesser,
- repräsentative Koordinate,
- Stations-, EVSE-, Leistungs-, Betreiber- und Connectoraggregate.

## 3. Konfiguration

Bezeichnung in der App:

> Maximaler Gruppendurchmesser

Vorgesehene Werte:

| Wert | Bedeutung |
| ---: | --- |
| 25 m | sehr enge Gruppierung |
| 50 m | Standard |
| 100 m | großzügige Gruppierung |
| 200 m | großflächige Gruppierung |
| 300 m | sehr großzügige Gruppierung |

Die App kann diese Werte lokal wechseln, ohne einen neuen Datensatz zu laden.
Eine freie Zahleneingabe ist für Version 1.0 nicht vorgesehen.

## 4. Distanzberechnung

- Koordinatensystem der Quelle ist WGS84.
- Distanzen werden in Metern mit einer dokumentierten geodätischen Formel oder
  einer für Deutschland geeigneten metrischen Projektion berechnet.
- Direkte euklidische Grad-Differenzen sind unzulässig.
- Berechnung und Rundung müssen auf allen unterstützten Plattformen dieselben
  Grenzentscheidungen liefern.
- Intern wird mit höherer Genauigkeit gerechnet als in der UI angezeigt.
- Ein Abstand exakt auf dem Grenzwert gilt als innerhalb der Gruppe.

Ungültige oder fehlende Koordinaten führen zu einem Datenqualitätsfehler. Eine
betroffene Station wird nicht stillschweigend einer Nachbargruppe zugeordnet.

## 5. Algorithmus

Der Algorithmus ist ein deterministisches agglomeratives Complete-Linkage-
Verfahren mit harter Durchmessergrenze.

### 5.1 Definition

Der Durchmesser einer Gruppe ist:

```text
max(distance(a, b)) für alle Stationspaare a, b der Gruppe
```

Eine Vereinigung ist nur zulässig, wenn der Durchmesser der vereinigten Gruppe
höchstens dem gewählten Grenzwert entspricht.

### 5.2 Ablauf

1. Stationen aufsteigend nach `station_id` sortieren.
2. Jede Station als eigene Gruppe initialisieren.
3. Für jedes Gruppenpaar die kleinste stationsübergreifende Distanz bestimmen.
4. Zulässige Gruppenpaare aufsteigend sortieren nach:
   - kleinster stationsübergreifender Distanz,
   - kleinster Anker-ID der ersten Gruppe,
   - kleinster Anker-ID der zweiten Gruppe.
5. Das erste Paar vereinigen, dessen gemeinsamer maximaler Durchmesser den
   Grenzwert nicht überschreitet.
6. Kandidaten aktualisieren und Schritt 4 wiederholen.
7. Enden, wenn keine Vereinigung mehr zulässig ist.

Die Anker-Station ist immer die lexikografisch kleinste `station_id` einer
Gruppe.

### 5.3 Vermeidung von Kettenclustern

Beispiel bei 300 Metern:

```text
A --- 200 m --- B --- 200 m --- C
```

Wenn A zu C 400 Meter entfernt ist, dürfen nicht alle drei Stationen dieselbe
Gruppe bilden. Complete Linkage verhindert dies, weil der gemeinsame
Gruppendurchmesser 400 Meter wäre.

### 5.4 Gruppen-ID

```text
proximity_group_id =
  UUIDv5(
    namespace_proximity_group,
    dataset_version + ":" +
    diameter_m + ":" +
    join(",", sorted_station_ids)
  )
```

Die ID ist reproduzierbar, aber nicht langfristig stabil. Sie ändert sich bei:

- anderer Datensatzversion,
- anderem Durchmesser,
- veränderter Gruppenmitgliedschaft.

## 6. Vorberechnung

Die Pipeline darf Gruppenmitgliedschaften für alle fünf vorgesehenen
Durchmesser vorberechnen und in der App-Datenbank speichern. Das reduziert
Rechenaufwand auf dem Gerät und garantiert plattformübergreifend identische
Ergebnisse.

Jede vorberechnete Zeile enthält:

- Datensatzversion,
- Durchmesser,
- Gruppen-ID,
- Anker-Station,
- Mitgliedsstation.

Die App darf die Gruppierung alternativ lokal berechnen, muss dann aber mit den
Pipeline-Referenzwerten bytegenau übereinstimmende IDs und Mitgliedschaften
erzeugen.

## 7. Aggregate und Darstellung

Für die ausgewählte Gruppe werden berechnet:

- Zahl der Ladeeinrichtungen,
- Zahl aller gleichzeitig nutzbaren Ladepunkte,
- AC-/DC-Zahlen,
- Zahl der Ladepunkte oberhalb der gewählten Mindestleistung,
- höchste ausgewiesene Leistung,
- Betreiber und Steckertypen,
- räumlich zugeordnete Infrastrukturmerkmale.

Die repräsentative Koordinate ist der Medoid: die Stationskoordinate mit der
kleinsten Summe der Distanzen zu allen anderen Gruppenmitgliedern. Bei
Gleichstand entscheidet die kleinere `station_id`.

Navigation verwendet standardmäßig die Anker-Station oder eine vom Nutzer
ausgewählte Station. Ein geometrischer Mittelpunkt wird nicht ungeprüft als
Navigationsziel verwendet.

## 8. Favoriten

Ein Favorit speichert:

- `anchor_station_id`,
- beim Speichern gewählten Gruppendurchmesser,
- optional damalige Stations-IDs und Anzeigename,
- Erstellungsdatum.

Beim Öffnen wird die aktuelle Gruppe gesucht, die die Anker-Station enthält.
Dadurch bleibt der Favorit bei einer geänderten Durchmessereinstellung oder
Gruppenmitgliedschaft auffindbar.

Ist die Anker-Station in einem neuen Datensatz nicht mehr vorhanden:

1. Ein expliziter Stationsalias wird geprüft.
2. Ohne Alias bleibt der Favorit als nicht mehr verfügbar erhalten.
3. Eine automatische Zuordnung nur anhand räumlicher Nähe findet nicht statt.

## 9. Referenzfälle Version 1.0

### PG-001 – Einzelstation

Eine Station bildet bei jedem Durchmesser eine eigene Gruppe.

### PG-002 – Abstand exakt auf Grenze

Zwei Stationen sind exakt 50 Meter entfernt. Bei 50 Metern bilden sie eine
Gruppe, bei 25 Metern zwei Gruppen.

### PG-003 – Abstand knapp über Grenze

Zwei Stationen sind 50,01 Meter entfernt. Bei 50 Metern bleiben sie getrennt.

### PG-004 – Kette

A–B und B–C liegen innerhalb, A–C außerhalb des Grenzwerts. Alle drei dürfen
nicht gemeinsam gruppiert werden.

### PG-005 – Gleichstand

Mehrere Merge-Kandidaten besitzen dieselbe Distanz. Stabile Stations-IDs führen
auf allen Plattformen zum gleichen Ergebnis.

### PG-006 – Betreiber ohne Bedeutung

Zwei Stationen unterschiedlicher Betreiber werden bei zulässigem Durchmesser
genauso behandelt wie Stationen desselben Betreibers.

### PG-007 – Straße ohne Bedeutung

Zwei nahe Stationen auf getrennten Straßenseiten werden zusammengefasst, wenn
die reine Distanzregel erfüllt ist. Die UI weist darauf hin, dass
Zugänglichkeit nicht geprüft wurde.

### PG-008 – Durchmesserwechsel

Dieselben Stationen bilden bei 25, 50 und 300 Metern gegebenenfalls
unterschiedliche Gruppen. Der Favorit bleibt über die Anker-Station auffindbar.

### PG-009 – Datensatzupdate

Eine neue Station verändert eine Gruppe und ihre Gruppen-ID. Bestehende
Favoriten bleiben über ihre Anker-Station auffindbar.

### PG-010 – Ungültige Koordinate

Eine Station mit ungültiger Koordinate erzeugt einen Qualitätsfehler und keine
willkürliche Gruppenzuordnung.

## 10. Bestätigte Parks ab Version 1.5

Version 1.5 ergänzt eine eigene Feedback- und Regelpipeline:

1. Nutzende bewerten, ob konkrete Stationen praktisch zusammengehören.
2. Rückmeldungen werden pseudonymisiert beziehungsweise kontobezogen gegen
   Mehrfachabstimmung geschützt.
3. Widersprüche, Missbrauch und zeitliche Änderungen werden erkannt.
4. Einzelmeldungen werden nicht direkt produktiv.
5. Eine noch festzulegende Mindestzahl und Zustimmungsquote erzeugen einen
   Review-Kandidaten.
6. Freigegebene Merge-/Splitregeln erzeugen versionierte `verified_park`-
   Objekte.
7. Fehlt eine bestätigte Regel, bleibt die Abstandsgruppe der Fallback.

Betreiberbestätigungen können ebenfalls `verified_park`-Regeln begründen. Sie
benötigen eine archivierte ausdrückliche Bestätigung und ein dokumentiertes
Verwendungsrecht.

## 11. Betreiberwebseiten

Betreiberwebseiten dürfen:

- als Link in der App kuratiert werden,
- Anlass für eine Bestätigungsanfrage geben.

Sie dürfen ohne ausdrückliche Erlaubnis nicht:

- systematisch nach Koordinaten oder Standortdaten ausgelesen werden,
- alleinige Evidenz einer Merge-/Splitentscheidung sein,
- durch kopierte Texte, Bilder, Karten oder Standortlisten in die Datenbank
  einfließen.

Die räumliche Zuordnung eines Links erfolgt anhand von BNetzA-Daten,
Betreibername und einer ausdrücklichen Betreiberbestätigung, nicht anhand
kopierter Webseitenkoordinaten.

Eine eindeutige URL-Zuordnung darf auch durch manuellen Vergleich der sichtbar
angegebenen Betreiberadresse mit der bereits gespeicherten BNetzA-Adresse
erfolgen. Die Webseitenadresse wird dabei nicht als eigener Wert übernommen.
Mehrdeutige oder abweichende Fälle benötigen eine Betreiberbestätigung.

## 12. Qualitätsbericht

Pro Datensatz und Durchmesser:

- Zahl der Gruppen,
- Größenverteilung,
- größter Gruppendurchmesser,
- Gruppen mit besonders vielen Stationen oder EVSEs,
- geänderte Gruppen gegenüber dem Vorgänger,
- fehlende oder ungültige Koordinaten,
- Referenztestergebnisse.

### 12.1 Kalibrierung mit BNetzA-Snapshot vom 7. Juli 2026

| Durchmesser | Gruppen | Einzelgruppen | Mehrstationsgruppen | Größte Gruppe |
| ---: | ---: | ---: | ---: | ---: |
| 25 m | 61.891 | 43.004 | 18.887 | 513 Stationen |
| 50 m | 59.237 | 39.898 | 19.339 | 513 Stationen |
| 100 m | 55.352 | 35.471 | 19.881 | 527 Stationen |
| 200 m | 48.224 | 27.448 | 20.776 | 527 Stationen |
| 300 m | 42.267 | 21.214 | 21.053 | 546 Stationen |

Der größte tatsächliche Durchmesser lag bei jeder Variante innerhalb der
konfigurierten Grenze. Die größte 25-/50-Meter-Gruppe enthält 513
BNetzA-Stationen an exakt derselben Koordinate in Grünheide und wird als
Datenqualitäts- beziehungsweise Darstellungsfall weiter beobachtet. Sie wird
nicht aufgrund externer Karteninformationen korrigiert.

Der erste 50-Meter-Review-Export mit Top 100 je Kategorie enthält nach
Entfernung von Überschneidungen 221 Gruppen. Er zeigt:

- große HPC-Kandidaten, unter anderem in Merklingen, Schleiz,
  Oberhonnefeld-Gierend, Kamen, Eschborn, Hilden und Geiselwind,
- große Gruppen ohne HPC-Ladepunkt, insbesondere Werks-, Flughafen- und
  Unternehmensstandorte,
- zahlreiche identische Quellkoordinaten bei einzelnen Großstandorten.

Diese Beobachtungen bestätigen, dass reine Stations- oder EVSE-Zahl nicht als
Ladeparkqualität interpretiert werden darf. DC-/HPC-Filter und
Infrastrukturmerkmale sind für die Produktdarstellung erforderlich.

## 13. Noch vor Version 1.5 zu entscheiden

- Teilnahmebedingungen und Nutzungsrechte für Feedback,
- Konten- oder Pseudonymisierungskonzept,
- Schutz gegen Mehrfachabstimmung und Manipulation,
- Mindestzahl und Quote für Review-Kandidaten,
- administrativer Reviewprozess,
- Zeitablauf und erneute Prüfung bestätigter Regeln,
- Konfliktauflösung zwischen Community und Betreiberbestätigung.
