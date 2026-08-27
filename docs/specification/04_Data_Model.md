# Domänenmodell und Glossar

Status: Verbindlicher Spezifikationskern

Stand: 26. Juli 2026

## 1. Modellierungsgrundsätze

- Die stabile `station` ist das zentrale persistente Objekt von Version 1.0.
- Die App bildet daraus konfigurierbare `proximity_group`-Objekte.
- Ein dauerhaft identifizierter `verified_park` entsteht erst durch bestätigte
  Regeln ab Version 1.5.
- Die Produktbezeichnung „Ladepark“ ist keine starre Größenklasse.
- Technische Quellobjekte bleiben nachvollziehbar, auch wenn die Oberfläche sie
  zusammenfasst.
- Alle langfristig referenzierten Objekte erhalten stabile interne IDs.
- Quell-IDs werden als Referenzen gespeichert, nicht als interne Identität
  verwendet.
- Unbekannt, nicht vorhanden und vorhanden sind unterschiedliche Zustände.
- Angaben aus mehreren Quellen behalten Herkunft und Datenstand.

## 2. Begriffe

### Dynamische Abstandsgruppe / `proximity_group`

Eine für eine Datensatzversion und einen gewählten maximalen
Gruppendurchmesser deterministisch berechnete Menge räumlich benachbarter
Ladeeinrichtungen. Sie ist eine Näherung und keine bestätigte Aussage über
Parkplatz, Zufahrt oder Grundstück.

### Bestätigter Ladepark / `verified_park`

Ein ab Version 1.5 durch freigegebene Nutzerfeedback- oder
Betreiberbestätigungsregeln als praktisch zusammengehörig behandelter Standort.
Betreibergrenzen verhindern eine Zusammenfassung nicht. Es gibt keine feste
Mindestzahl von Ladepunkten.

„Ladepark“ bleibt die nutzernahe Produktbezeichnung. Die UI muss unterscheiden,
ob eine Gruppe nur abstandsbasiert oder bestätigt ist.

### Ladesäule / Station

Eine physische Ladeeinrichtung, die einen oder mehrere Ladepunkte bereitstellen
kann. Eine Ladesäule ist nicht das zentrale Anzeigeobjekt der App.

### Ladepunkt / EVSE

Eine technische Einheit, die genau ein Elektrofahrzeug gleichzeitig mit Energie
versorgen kann. Können an einer Ladesäule zwei Fahrzeuge gleichzeitig laden,
besitzt sie zwei Ladepunkte beziehungsweise EVSEs.

EVSE steht für „Electric Vehicle Supply Equipment“. Für die fachliche
Kommunikation in der App wird der verständlichere Begriff „Ladepunkt“
verwendet.

### Anschluss / Connector

Eine physische Anschlussmöglichkeit eines Ladepunkts, beispielsweise CCS oder
Typ 2. Mehrere Anschlüsse an demselben Ladepunkt erhöhen die Zahl der
gleichzeitig ladbaren Fahrzeuge nicht, sofern nur einer gleichzeitig genutzt
werden kann.

### Betreiber / Operator

Organisation, die einen Ladepunkt oder eine Station betreibt. Ein Ladestandort
kann Stationen und Ladepunkte mehrerer Betreiber enthalten.

### DC-Schnellladepunkt

Ein Ladepunkt, der Gleichstromladen unterstützt. Die App verwendet keine
unveränderliche fachliche HPC-Grenze. Nutzende wählen eine Mindestleistung; der
Standardwert beträgt 100 kW.

### Maximale Ladeleistung

Die für einen Ladepunkt beziehungsweise Anschluss ausgewiesene technische
Maximalleistung in kW. Sie ist keine Garantie für die im konkreten Ladevorgang
erreichbare Leistung.

### Infrastrukturmerkmal

Eine am Ladestandort oder in unmittelbar sinnvoll nutzbarer Nähe verfügbare
Einrichtung: WC, Automat, Einkaufsmöglichkeit, Café oder Restaurant. Die genaue
räumliche Zuordnungsregel wird mit den Datenquellen in der
Importer-Spezifikation festgelegt.

### Datenstand

Zeitpunkt, zu dem eine Quellangabe abgerufen, veröffentlicht oder manuell
überprüft wurde. Er ist nicht zwingend identisch mit dem Erstellungsdatum des
App-Datensatzes.

### Favorit

Eine ausschließlich lokal gespeicherte Referenz auf eine stabile
`anchor_station_id` sowie optionale Darstellungsinformationen der damaligen
Gruppe.

## 3. Kernentitäten

### 3.1 `proximity_group`

Repräsentiert eine für Darstellung und Filterung berechnete Abstandsgruppe. Sie
wird nicht als langfristige Wahrheit gespeichert.

Kernattribute:

- `proximity_group_id`: aus Datensatzversion, Durchmesser und sortierten
  Stations-IDs deterministisch abgeleitete ID,
- `diameter_m`,
- `anchor_station_id`: lexikografisch kleinste stabile Stations-ID,
- enthaltene Stations-IDs,
- repräsentative Koordinate,
- abgeleitete Gesamtzahl gleichzeitig nutzbarer Ladepunkte,
- abgeleitete Leistungs- und Steckertypzusammenfassung,
- Datenstand.

Invarianten:

- Jede Station gehört für eine konkrete Durchmessereinstellung genau einer
  `proximity_group` an.
- Jede paarweise Stationsdistanz einer Gruppe ist höchstens `diameter_m`.
- Die Gruppe enthält mindestens eine Station.
- Eine Betreibergrenze beeinflusst die Berechnung nicht.
- Die aggregierte Ladepunktzahl wird aus eindeutigen EVSEs gebildet und nicht
  aus der Anzahl der Anschlüsse.

Die Gruppen-ID ist nicht dauerhaft stabil. Favoriten verwenden die
Anker-Station.

### 3.2 `verified_park` – ab Version 1.5

Repräsentiert einen durch freigegebene Regeln bestätigten Ladepark.

Kernattribute:

- stabile `verified_park_id`,
- enthaltene beziehungsweise ausdrücklich getrennte Stations-IDs,
- Regelversion und Freigabestatus,
- Herkunft `community_consensus` oder `operator_confirmation`,
- Konfidenz und Prüfdatum,
- Anzeigename und optional bestätigter Navigationspunkt.

### 3.3 `station`

Repräsentiert eine physische oder durch die Quelle als Station gelieferte
Ladeeinrichtung.

Kernattribute:

- `station_id`: stabile interne ID,
- Betreiberreferenz,
- Koordinate,
- Adresse, soweit abweichend oder quellbezogen,
- Betriebs- und Zugangsstatus,
- Datenstand.

Eine spätere Präzisierung muss klären, wie Quellen ohne verlässliche
Stationsidentität behandelt werden.

### 3.4 `evse`

Repräsentiert einen gleichzeitig nutzbaren Ladepunkt.

Kernattribute:

- `evse_id`: stabile interne ID,
- `station_id`,
- Stromart AC/DC,
- ausgewiesene maximale Leistung in kW,
- öffentlicher Zugangsstatus,
- Betriebsstatus der Stammdaten,
- Datenstand.

Invarianten:

- Ein EVSE versorgt höchstens ein Fahrzeug gleichzeitig.
- Die Zahl der Connectoren ist nicht automatisch die Zahl der Ladepunkte.
- Live-Belegung gehört nicht zu Version 1.0.

### 3.5 `connector`

Repräsentiert eine Anschlussmöglichkeit eines EVSE.

Kernattribute:

- `connector_id`: interne ID,
- `evse_id`,
- standardisierter Steckertyp,
- maximale Leistung, falls anschlussspezifisch,
- Datenstand.

### 3.6 `operator`

Repräsentiert einen Betreiber.

Kernattribute:

- `operator_id`: stabile interne ID,
- kanonischer Name,
- bekannte Quellbezeichnungen beziehungsweise Aliase.

Betreiberidentitäten müssen normalisiert werden, damit Schreibvarianten nicht
zu künstlich getrennten Filtern führen.

Die Detailprojektion einer dynamischen Gruppe zählt je kanonischem Betreiber
beziehungsweise ungeklärtem Quellnamen unterschiedliche EVSEs nach disjunkter
Leistungsklasse und Steckertyp. Ein EVSE mit mehreren unterschiedlichen
Steckertypen wird in jeder passenden Steckertypzelle gezählt; Zellwerte
verschiedener Steckertypen sind deshalb nicht zwingend addierbar. Nicht
geprüfte Betreiberidentitäten werden nicht stillschweigend zusammengeführt.

### 3.7 `amenity`

Repräsentiert ein Infrastrukturmerkmal eines Ladestandorts.

Kernattribute:

- `amenity_id`,
- räumliche Zuordnung zur Station beziehungsweise dynamischen Gruppe,
- Typ: WC, Automat, Einkauf, Café oder Restaurant,
- Zustand: vorhanden, nicht vorhanden oder unbekannt,
- optional Name und Koordinate,
- Entfernung beziehungsweise Zuordnungsgrundlage,
- Quellreferenz und Datenstand,
- Ermittlung: automatisiert oder manuell recherchiert.

Eigene redaktionelle Erhebungen liegen gemäß ADR-0012 in einem getrennten
Informationsbestand und referenzieren mindestens eine stabile `station_id`.
Für Fotos werden Metadaten und relative Assetpfade gespeichert; die Bilddatei
selbst ist kein SQLite-BLOB.

Ein fehlender Quelldatensatz darf nicht automatisch als „nicht vorhanden“
interpretiert werden.

### 3.8 `source_reference`

Verbindet ein internes Objekt mit seiner Herkunft.

Kernattribute:

- `source_reference_id`,
- Typ und ID des internen Objekts,
- Quellsystem,
- Quellobjekt-ID oder nachvollziehbare Fundstelle,
- Abruf-, Veröffentlichungs- oder Prüfdatum,
- Lizenz- beziehungsweise Attributionsinformation,
- optional Vertrauens- oder Prüfstatus.

## 4. Beziehungen

```text
station
  ├── 1..n evse
  │        └── 1..n connector
  ├── 1 operator
  └── 1..n source_reference

proximity_group (berechnet)
  └── 1..n station

verified_park (ab 1.5)
  └── 1..n station
```

Die konkrete relationale Abbildung kann aus Performancegründen zusätzliche
Aggregat- und Zuordnungstabellen enthalten. Diese ändern nicht die fachlichen
Beziehungen.

## 5. Bildung einer Abstandsgruppe

Version 1.0 verwendet ausschließlich Koordinaten der BNetzA-Stationen und den
vom Nutzer gewählten maximalen Gruppendurchmesser.

- Standardwert: 50 Meter.
- Vorgesehene Werte: 25, 50, 100, 200 und 300 Meter.
- Sämtliche paarweisen Stationsabstände einer Gruppe müssen den Grenzwert
  einhalten.
- Betreiber, Adresse, Zufahrt, Straßen und fremde Karten beeinflussen die
  Berechnung nicht.
- Die Berechnung ist für gleiche Eingabe, Datensatzversion und Einstellung
  deterministisch.

Der genaue Algorithmus und seine Referenzfälle stehen in `06_Clustering.md`.
Ab Version 1.5 haben freigegebene `verified_park`-Regeln Vorrang; andernfalls
bleibt die Abstandsgruppe der Fallback.

## 6. Stabile Identitäten

Interne IDs dürfen nicht direkt von veränderlichen Betreiber-, Adress- oder
Quellbezeichnungen abhängen. Sie müssen Datensatzupdates überstehen, damit
Favoriten erhalten bleiben und spätere Community-Inhalte zugeordnet werden
können.

ADR-0002 legt UUIDv5-basierte Quellobjekt-IDs fest. ADR-0004 ersetzt die
persistente Park-ID für Version 1.0 durch eine nur kontextbezogene Gruppen-ID
und stabile Anker-Stationen. Dauerhafte Park-IDs gelten erst für freigegebene
`verified_park`-Objekte ab Version 1.5.

Vor Implementierung sind nur noch die konkreten Namespace-UUIDs, das
Build-seitige Registerformat und Review-Schwellen zu bestimmen.

## 7. Abgeleitete Werte

Für Suche, Filter und Darstellung dürfen vorberechnete Werte gespeichert werden:

- Gesamtzahl der EVSEs,
- Zahl der AC- und DC-EVSEs,
- Zahl der EVSEs oberhalb definierter Leistungsschwellen,
- höchste ausgewiesene Ladeleistung,
- Menge der Steckertypen und Betreiber,
- zusammengefasster Infrastrukturstatus.

Abgeleitete Werte müssen deterministisch aus den normalisierten Kerndaten und
versionierten Regeln erzeugt werden.

## 8. Noch offene Modellfragen

- standardisierte Liste der Steckertypen,
- Modellierung eingeschränkten öffentlichen Zugangs,
- Leistungsklassen für Anzeige und Voraggregation,
- Umgang mit geteiltem dynamischem Lastmanagement,
- räumliche Definition „in sinnvoll nutzbarer Nähe“ für Infrastruktur,
- Vertrauensmodell für automatisch und manuell ermittelte Angaben,
- Aufbewahrungsdauer verschwundener Identitätsobjekte.
