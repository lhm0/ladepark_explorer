# Importer und Datenpipeline

Status: BNetzA-Kernpipeline und charging-Export implementiert; übrige
Abschnitte sind Spezifikation

Stand: 26. Juli 2026

## 0. Implementierungsstand

Implementiert:

- Python-3.12-Projekt und Toolchain gemäß ADR-0005,
- lokaler CLI-Befehl `inspect` für CSV und XLSX,
- Erkennung und Prüfung des BNetzA-Spaltenvertrags einschließlich
  vorgeschalteter Informationszeilen und gequoteter mehrzeiliger CSV-Felder,
- Normalisierung und Validierung zentraler Quellwerte,
- deterministische BNetzA-Stations-ID,
- typisierte Stations-, EVSE- und Connectorobjekte,
- UUIDv5-IDs für EVSEs und Connectoren einschließlich dokumentiertem
  Slot-Fallback bei fehlender oder ungültiger EVSE-ID,
- versionierte Connector-Zuordnung mit Erhalt und Warnung bei unbekannten
  Quellwerten,
- deterministische JSON-Ausgabe der normalisierten Objekte über den
  CLI-Befehl `normalize`,
- kompakter Normalisierungs- und Qualitätsbericht über den CLI-Befehl
  `report`,
- maschinenlesbarer Prüfbericht mit Quellhash und Mengengerüst,
- dynamische Abstandsgruppierung für 25, 50, 100, 200 und 300 Meter,
- Review-Export und Gruppierungsberichte,
- reproduzierbarer und atomarer `charging.sqlite`-Export,
- Integritäts- und Schema-Validierung des SQLite-Artefakts,
- read-only Abfrageprototyp für Karte, Umkreis, Text, Leistung, Betreiber,
  Connectoren und Gruppendetails,
- synthetische Import-Fixture und automatisierte Tests.

Noch geplant sind insbesondere vollständige Source-Reference-Objekte, das
getrennte OSM-Artefakt, Manifest,
Stationsaliase und verbindliche Qualitätsgates des Gesamtimports.

Der erste vollständige Prüflauf mit der offiziellen CSV vom 7. Juli 2026
erkannte 113.385 Stationen, 204.078 Ladepunkte und sechs Quellslots. Das Schema
enthielt keine unbekannten Spalten; die gemeldeten Ladepunktzahlen stimmten mit
den belegten Slots überein. Die Rohdatei selbst wird nicht in Git gespeichert.

Der erste vollständige Normalisierungslauf erzeugte:

- 113.385 Stationen und 204.078 EVSEs,
- 151.120 AC- und 52.958 DC-EVSEs,
- 214.785 Connectoren,
- keine unbekannten Connector-Typen,
- 3.500 syntaktisch nicht nutzbare und 1.101 mehrfach vorkommende EVSE-IDs,
  für die stabile Slot-Fallback-IDs verwendet werden,
- 120 Stationen ohne Hausnummer,
- einen Fall mit uneindeutiger Zuordnung mehrerer Leistungswerte zu einem
  Connector,
- 11.910 unterschiedliche Betreiber-Quellnamen ohne Betreiberregister.

Diese Zahlen sind Kalibrierungswerte des Snapshots vom 7. Juli 2026 und keine
allgemeinen Produktkonstanten.

## 1. Zweck und Systemgrenze

Der Importer erzeugt aus versionierten Rohdaten einen geprüften,
reproduzierbaren App-Datensatz. Er ist ein lokal oder in CI ausgeführtes
Build-Werkzeug und kein dauerhaft laufender Dienst.

Eingaben:

- Bundesnetzagentur-Registerdatei,
- optionaler OSM-Bulk-Extrakt,
- versionierte Betreiber-, Identitäts- und Override-Register,
- manuell recherchierte Infrastrukturangaben,
- Pipeline-Konfiguration.

Ausgaben:

- normalisierte Build-Datenbank,
- BNetzA-basierte App-Datenbank `charging.sqlite`,
- getrennte ODbL-App-Datenbank `osm_amenities.sqlite`,
- `manifest.json`,
- Qualitätsbericht,
- Review-Fälle,
- Protokoll und Hashes aller Eingaben.

Die Pipeline implementiert `FR-DATA-001` bis `FR-DATA-003`,
`NFR-DATA-001` und die Datenanteile der Filter- und Detailanforderungen.

## 2. Technische Leitplanken

- Implementierung in Python.
- Schritte sind über eine CLI einzeln und als vollständige Pipeline ausführbar.
- Rohdaten werden nie in-place verändert.
- Zeit, Netzwerk und zufällige Werte werden nicht implizit in fachliche
  Ergebnisse einbezogen.
- Sortierung ist vor jeder ID-, Aggregat- und Exportoperation explizit.
- Koordinaten werden intern als WGS84-Dezimalgrad verarbeitet.
- Entfernungen werden geodätisch beziehungsweise in einer für Deutschland
  geeigneten Projektion berechnet, nicht durch naive Grad-Differenzen.
- Geld-, Zeit- und Dezimalwerte werden ohne binäre Rundungsartefakte
  normalisiert.
- Jeder Lauf erhält eine eindeutige `run_id`; der fachliche Datensatz bleibt bei
  gleichen Eingaben deterministisch.

## 3. Verzeichnis- und Artefaktkonzept

Die Implementierung trennt CLI-Unterbefehle (`commands/`), vollständige
Build-Orchestrierung (`pipeline/`) und den versionierten Charging-SQLite-Adapter
(`charging_sqlite/`). Der sprachübergreifende ausführbare Vertrag liegt unter
`contracts/charging_dataset/v2/`. Diese Grenzen folgen ADR-0007 und ADR-0015.

Vorgesehene logische Struktur:

```text
data/
  raw/                 unveränderte Quelldateien, nicht zwingend in Git
  registry/            versionierte IDs, Betreiber und Overrides
  reference/           Gruppierungs- und Import-Referenzfälle
  work/                reproduzierbare Zwischenstände
  output/              SQLite, Manifest und Qualitätsbericht
```

Große oder lizenzbedingt gesondert zu behandelnde Rohdaten werden über Hash und
Archivpfad referenziert, nicht zwingend in Git gespeichert. Register, Regeln,
Konfiguration und kleine Referenzfälle gehören in die Versionskontrolle.

## 4. Pipeline

```text
acquire
  -> fingerprint
  -> inspect schema
  -> parse
  -> validate raw
  -> normalize
  -> resolve identities
  -> cluster
  -> apply overrides
  -> aggregate
  -> extract OSM amenities separately
  -> validate domain
  -> export charging and OSM SQLite artifacts
  -> verify artifact
  -> build manifest and quality report
```

Ein fehlgeschlagener Schritt beendet den Lauf mit ungleich null. Ein
Produktionsartefakt wird erst nach allen Muss-Prüfungen veröffentlicht.

## 5. Eingabevertrag Bundesnetzagentur

### 5.1 Beschaffung

Der Importer akzeptiert zunächst eine explizit angegebene lokale CSV- oder
XLSX-Datei. Ein Download-Adapter darf ergänzt werden, muss aber:

- eine explizite HTTPS-URL verwenden,
- Umleitungen protokollieren,
- Timeout und begrenzte Wiederholungen besitzen,
- Antworttyp und plausible Dateigröße prüfen,
- Rohdatei vor Verarbeitung unverändert speichern,
- SHA-256, Abrufzeit und endgültige URL protokollieren.

Die automatisierbare Webserviceschnittstelle wird erst nach Prüfung ihrer
offiziellen technischen Beschreibung als Standardquelle verwendet.

### 5.2 Pflichtfelder

Für den ersten Import sind folgende Quellspalten Pflicht:

- `Ladeeinrichtungs-ID`,
- `Betreiber`,
- `Status`,
- `Anzahl Ladepunkte`,
- `Straße`,
- `Hausnummer`,
- `Postleitzahl`,
- `Ort`,
- `Breitengrad`,
- `Längengrad`,
- mindestens eine Gruppe aus Steckertyp und Nennleistung.

Erwartete optionale Felder:

- Anzeigename,
- Art und Nennleistung der Ladeeinrichtung,
- Inbetriebnahmedatum,
- Adresszusatz, Kreis und Bundesland,
- Standortbezeichnung und Parkrauminformation,
- Öffnungszeiten,
- EVSE-IDs und Public Keys,
- weitere Ladepunkt-Slots.

Die tatsächliche Quellschnittstelle vom 7. Juli 2026 ist in
`15_License_Compliance.md` dokumentiert.

### 5.3 Schema-Drift

- Fehlendes Pflichtfeld: Lauf abbrechen.
- Unbekanntes zusätzliches Feld: Warnung und vollständige Auflistung im
  Qualitätsbericht.
- Umbenanntes Feld: nur über eine versionierte Alias-Konfiguration akzeptieren.
- Neue wiederholte Ladepunkt-Slots: generisch erkennen, sofern das Namensmuster
  eindeutig ist; andernfalls abbrechen.
- Doppelte Ladeeinrichtungs-ID: Muss-Fehler, außer eine explizite und getestete
  Quellregel löst den Fall auf.

## 6. Parsing und Normalisierung

### 6.1 Text

- Unicode in NFC normalisieren.
- Führende und folgende Leerzeichen entfernen.
- interne Leerraumfolgen für Vergleichsschlüssel vereinheitlichen.
- Originalwert für Provenienz und Debugging erhalten.
- Leere Zeichenfolgen, `-`, `n/a` und definierte Quellplatzhalter als `NULL`
  abbilden.

### 6.2 IDs

- Quell-IDs als Zeichenfolgen einlesen; keine führenden Nullen verlieren.
- EVSE-IDs trimmen und nach einer separat getesteten Syntaxregel kanonisieren.
- Interne IDs gemäß ADR-0002 erzeugen.
- Ungültige optionale EVSE-ID als Datenwarnung behandeln und Fallback-ID
  verwenden.

### 6.3 Koordinaten

- Dezimalkomma und Dezimalpunkt kontrolliert akzeptieren.
- Breitengrad muss in `[-90, 90]`, Längengrad in `[-180, 180]` liegen.
- Für den Deutschland-Datensatz zusätzlich eine großzügige Deutschland-
  Bounding-Box prüfen; Treffer außerhalb sind Review-Fälle.
- Koordinate `(0, 0)` und offensichtlich gerundete oder identische
  Masseneinträge melden.
- Quellkoordinate und normalisierte Koordinate getrennt nachvollziehbar halten.

### 6.4 Leistung

- Werte in kW als nichtnegative Dezimalzahl normalisieren.
- Mehrere durch Semikolon getrennte Leistungswerte werden als geordnete Liste
  gelesen.
- Entspricht die Zahl der Werte der Zahl der Connectoren, erfolgt die Zuordnung
  positionsgetreu.
- Ein einzelner Leistungswert bei mehreren Connectoren gilt für alle
  Connectoren des Quellslots.
- Bei jeder anderen Kardinalität bleibt die anschlussspezifische Leistung
  unbekannt und der Fall wird gemeldet. Die EVSE-Maximalleistung ist dann das
  Maximum der vorhandenen Quellwerte.
- Einheit darf nicht stillschweigend geraten werden.
- technische Plausibilitätsgrenzen sind konfigurierbar; Überschreitungen werden
  als Review-Fall gemeldet.
- Stationsnennleistung und EVSE-/Connectorleistung bleiben getrennte Werte.
- Filteraggregate verwenden die ausgewiesene maximale Leistung des EVSE
  beziehungsweise Connectors nach dokumentierter Ableitungsregel.

### 6.5 Ladepunkte und Connectoren

Jeder belegte Quellslot wird zunächst als EVSE-Kandidat interpretiert. Die
Spalte `SteckertypenN` kann mehrere Connector-Typen enthalten und wird über eine
versionierte Mappingtabelle zerlegt.

Prüfungen:

- erzeugte EVSE-Zahl gegen `Anzahl Ladepunkte`,
- Leistung vorhanden und plausibel,
- EVSE-ID innerhalb des Snapshots eindeutig, soweit vorhanden,
- Steckertyp auf kanonischen Typ abbildbar,
- unbekannter Steckertyp wird erhalten und als Warnung gemeldet.

Abweichungen zwischen Slotzahl und gemeldeter Ladepunktzahl dürfen nicht
unbemerkt korrigiert werden. Bis eine Quellregel festgelegt ist, wird die
Ladeeinrichtung als Review-Fall markiert.

### 6.6 Adresse und Betreiber

Adresse wird in strukturierte Felder und einen Vergleichsschlüssel
normalisiert. Für die Anzeige bleiben Quellschreibweisen verfügbar.

Betreiber werden über das versionierte Betreiberregister auf eine kanonische
Identität abgebildet. Ein unbekannter Name erzeugt einen neuen Review-Eintrag;
eine rein fuzzy-basierte automatische Zusammenführung ist unzulässig.

Der implementierte Befehl `operator-review` erzeugt dafür einen
deterministischen Semikolon-CSV-Export aller BNetzA-Betreiberbezeichnungen.
Die Priorisierung erfolgt nach der Zahl unterschiedlicher normalisierter EVSEs,
ergänzt um Stations-, AC-, DC- und HPC-Zahlen. Die Statistik wird direkt aus
Stationen und EVSEs gebildet und summiert ausdrücklich keine
Abstandsgruppenaggregate, weil diese für fünf Durchmesser mehrfach vorliegen.
Technisch normalisierte Vergleichsschlüssel und begrenzte ähnliche Namen sind
nur Kandidaten für die manuelle Prüfung. Sie erzeugen weder `operator`-Objekte
noch Aliaszuordnungen.

`operator-worklist` reduziert den Gesamtbericht auf die Top N nach EVSE-Zahl
und deren Ähnlichkeitskandidaten. Die leeren Entscheidungsfelder dienen nur der
gemeinsamen Prüfung. Verbindliche Entscheidungen werden ausschließlich in
`importer/config/operators.json` versioniert. Das Register enthält stabile
`registry_key`s, kanonische und angezeigte Namen, exakte Quellaliase,
Reviewdatum und Begründung. `operator-registry-validate` verhindert doppelte
Schlüssel und Aliaszuordnungen, unbekannte Quellnamen sowie unvollständige oder
nicht geprüfte Einträge. `operator-coverage` weist anschließend die erfassten
Quellnamen, Stationen und EVSEs sowie den prozentualen EVSE-Anteil aus.

Beim SQLite-Build werden die geprüften Aliase auf stabile `operator_id`s
abgebildet. Direkte Stations-/EVSE-Zahlen werden als Filterstatistik
materialisiert; dadurch kann die App die führenden 20 Betreiber ohne
Gruppen-Mehrfachzählung oder Laufzeitaggregation laden. Ungeprüfte Quellnamen
bleiben unverändert erhalten und lokal durchsuchbar.

### 6.7 Öffnungszeiten

Quelltext, Wochentage und Tageszeiten werden verlustfrei gespeichert. Schema v2
normalisiert konservativ `always_open`, `restricted` oder `unknown`. Nur die
eindeutige BNetzA-Kennzeichnung `247` beziehungsweise `24/7` ohne
widersprechende Zusatzfelder wird als durchgehend zugänglich übernommen. Bei
fehlenden oder widersprüchlichen Angaben bleibt der Wert unbekannt und der Originaltext
sichtbar.

## 7. Separates Infrastrukturartefakt

### 7.1 OSM

OSM-Daten werden gemäß ADR-0003 aus einem versionierten Bulk-Extrakt in ein
eigenständiges ODbL-Artefakt verarbeitet. Mindestens folgende Kategorien werden
abgebildet:

| App-Kategorie | Typische OSM-Ausgangsmerkmale |
| --- | --- |
| WC | `amenity=toilets` |
| Automat | geeignete `amenity=vending_machine`-Tags |
| Einkauf | relevante `shop=*`-Objekte |
| Café | `amenity=cafe` |
| Restaurant | `amenity=restaurant` oder geeignete Gastronomietypen |

Die endgültige Tag-Mappingtabelle und räumliche Nähe werden versioniert. Ein
fehlendes OSM-Objekt bedeutet `unknown`, nicht `absent`.

OSM-Geometrien und -Tags werden nicht in `charging.sqlite` kopiert. Das
OSM-Artefakt enthält Infrastrukturkoordinaten und OSM-Identitäten, aber keine
persistente Zuordnung zu einer Abstandsgruppe. Die App ordnet Merkmale zur
Laufzeit räumlich zur aktuell gewählten Gruppe zu.

### 7.2 Manuelle Angaben

Manuelle Angaben folgen dem Vertrag aus `15_License_Compliance.md`. In Version 1.0
werden sie nicht mit OSM-Amenities dedupliziert. Eigene, rechtssicher
weiterverwendbare Feststellungen liegen in einem getrennten eigenen
Infrastrukturbereich mit eindeutiger Provenienz. Abgelaufene oder nicht mehr
nachvollziehbare Angaben werden auf `unknown` zurückgesetzt oder als Review-Fall
markiert.

### 7.3 Konfliktauflösung

Die App darf getrennte Infrastrukturbelege gemeinsam anzeigen. Eine
materialisierte effektive Zusammenführung im Build erfolgt für Version 1.0
nicht. `absent` wird nur durch eine ausdrücklich negative, zulässige und
hinreichend aktuelle eigene Feststellung gesetzt. Automatische OSM-Suche erzeugt
nur positive Nachweise oder `unknown`.

## 8. Identitätsauflösung

Die Pipeline lädt vor der Abstandsgruppierung:

- Namespace-Konfiguration,
- Betreiberregister,
- Identitätsregister,
- Stations-ID-Aliase.

Sie wendet ADR-0002 an. Neue, entfernte, reaktivierte und potenziell geänderte
Objekte werden im Qualitätsbericht separat gezählt.

Muss-Fehler:

- gleiche interne ID für fachlich verschiedene aktive Objekte,
- eine aktive Quell-ID auf mehrere aktive interne Objekte,
- Aliaszyklus,
- Veränderung eines Namespace-Werts nach dem ersten produktiven Release.

## 9. Abstandsgruppierung

Die Gruppierung folgt `06_Clustering.md`. Sie erhält ausschließlich
normalisierte Stationen aus der BNetzA-Quelle. Betreiber, Adresse, OSM,
Webseiten und manuelle Einschätzungen beeinflussen Version 1.0 nicht.

Die Reihenfolge ist:

1. gültige BNetzA-Koordinaten prüfen,
2. Distanzen beziehungsweise räumlichen Kandidatenindex erzeugen,
3. Complete-Linkage-Gruppen für 25, 50, 100, 200 und 300 Meter bilden,
4. kontextbezogene Gruppen-IDs und stabile Anker-Stationen bestimmen,
5. Referenzfälle und Durchmessergrenzen prüfen,
6. Mitgliedschaften für die App exportieren.

## 10. Aggregation

Pro vorberechneter Abstandsgruppe und Durchmesser werden deterministisch
berechnet:

- Zahl der Stationen,
- Zahl aller EVSEs,
- Zahl AC und DC,
- höchste ausgewiesene Leistung,
- Leistungsbänder,
- Betreiber- und Connector-Mengen,
- Öffnungszeiten-Zusammenfassung,
- getrennt ermittelte eigene Infrastrukturstatus; OSM-Amenities werden nicht
  in das BNetzA-Aggregat kopiert,
- repräsentative Medoid-Koordinate,
- Anker-Station als Navigationsfallback,
- Datenstand und Quellen.

Die repräsentative Koordinate ist nicht automatisch ein bestätigter
Zufahrtspunkt. Die App erklärt diese Einschränkung.

## 11. Validierung und Qualitätsgates

### 11.1 Muss-Gates

Ein Produktionsbuild schlägt fehl bei:

- fehlender oder nicht lesbarer Pflichtquelle,
- unerwarteter Pflichtschemaänderung,
- ungültigen Primär- oder internen IDs,
- nicht auflösbaren ID-Kollisionen,
- ungültigem SQLite-Schema oder Fremdschlüsselverletzungen,
- fehlgeschlagenen Gruppierungs-Referenzfällen,
- nicht deterministischem Wiederholungsbuild,
- fehlender Lizenz- oder Quellenmetadaten,
- negativem oder unplausiblem Kernaggregat,
- Prüfsummenabweichung nach Export.

### 11.2 Konfigurierbare Veränderungsgates

Gegenüber dem letzten freigegebenen Datensatz werden Schwellwerte geprüft:

- Gesamtzahl Stationen und EVSEs,
- neue und entfernte Objekte,
- Anteil fehlender Koordinaten, Leistungen und Betreiber,
- Zahl geänderter Gruppenmitgliedschaften je Durchmesser,
- Anteil unbekannter Infrastrukturmerkmale,
- Dateigröße und Indexgröße.

Initiale Schwellwerte werden nach dem ersten Referenzimport festgelegt. Eine
Überschreitung verlangt Review und dokumentierte Freigabe, nicht zwingend eine
automatische Verwerfung.

### 11.3 Qualitätsbericht

Der maschinenlesbare und menschenlesbare Bericht enthält:

- Lauf- und Pipelineversion,
- Eingaben mit Hashes,
- Zeilen- und Objektzahlen je Schritt,
- Fehler, Warnungen und Review-Fälle,
- unbekannte Quellspalten und Mappingwerte,
- Datenvollständigkeit je Kernfeld,
- Stationsidentitäts- und Gruppenstatistik je Durchmesser,
- Ergebnisse aller Referenzfälle und Gates,
- Ausgabeartefakte mit Hashes.

## 12. Fehlerbehandlung

Fehlerklassen:

- `SOURCE_ERROR`: Download, Datei oder Lizenzmetadaten,
- `SCHEMA_ERROR`: unerwartete Schnittstelle,
- `DATA_ERROR`: ungültiger Einzelwert oder widersprüchlicher Datensatz,
- `IDENTITY_ERROR`: nicht sichere ID-Zuordnung,
- `CLUSTER_ERROR`: ungültige oder nicht deterministische Abstandsgruppierung,
- `EXPORT_ERROR`: SQLite oder Manifest,
- `QUALITY_GATE_ERROR`: überschrittenes Muss-Gate.

Einzelfehler dürfen nur dann als Quarantäne fortgeführt werden, wenn:

- die Regel explizit konfiguriert ist,
- der Datensatz ohne das Objekt fachlich konsistent bleibt,
- Anzahl und Grund im Qualitätsbericht stehen,
- ein Schwellwert eine massenhafte stille Verwerfung verhindert.

## 13. CLI-Vertrag

Vorgesehene Befehle:

```text
importer acquire --config <datei>
importer inspect --source <datei>
importer build --config <datei> --output <verzeichnis>
importer validate --database <datei> --manifest <datei>
importer compare --old <manifest> --new <manifest>
```

Jeder Befehl bietet `--help`, liefert bei Erfolg Exitcode `0` und schreibt
maschinenlesbare Ergebnisse optional als JSON. Produktionsbuilds verwenden
keine interaktiven Rückfragen.

## 14. Teststrategie

Mindestens:

- Unit-Tests für jedes Normalisierungs- und Mappingverfahren,
- tabellengetriebene Tests für Quellwerte und Randfälle,
- Vertragsfixture mit anonymisierten beziehungsweise frei nutzbaren
  Beispielzeilen,
- Referenztests für Stations-IDs und Abstandsgruppierung,
- Integrationsbuild eines kleinen End-to-End-Datensatzes,
- deterministischer Doppelbuild mit Bytevergleich der fachlichen Inhalte,
- Schema- und Querytests gegen die erzeugte App-Datenbank,
- Tests für fehlerhafte, fehlende und neue Quellspalten.

## 15. Definition of Done für den ersten Importer

- Bundesnetzagentur-XLSX oder -CSV wird ohne manuelle Tabellenbearbeitung
  eingelesen.
- Pflichtfelder und Schema-Drift werden wie spezifiziert behandelt.
- Stationen, EVSEs, Connectoren und Betreiber werden mit stabilen IDs erzeugt.
- Gruppierungs-Referenzfälle bestehen.
- beide App-SQLite-Artefakte, Manifest und Qualitätsbericht sind valide.
- Ein zweiter Lauf mit gleichen Eingaben erzeugt dieselben fachlichen Daten.
- Quellen- und Lizenzmetadaten sind vollständig.
- Standardkommandos sind in `AGENTS.md` dokumentiert.
