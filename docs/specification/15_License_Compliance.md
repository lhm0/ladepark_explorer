# Lizenz- und Datenquellen-Dossier

Status: Lebendes Compliance-Dokument und Basis der finalen Lizenzprüfung

Stand: 26. Juli 2026

Verantwortung: Projektinhaber

## 1. Zweck und Pflege

Dieses Dokument ist die zentrale, fortlaufend zu aktualisierende Akte für alle
Lizenz- und Nutzungsfragen des Ladepark Explorers. Es dokumentiert:

- verwendete und erwogene Datenquellen,
- Lizenzen und Nutzungsbedingungen,
- konkrete Nutzung im Projekt,
- daraus abgeleitete Pflichten,
- technische Maßnahmen zur Einhaltung,
- offene Risiken und Freigabekriterien,
- Nachweise für die Prüfung vor einem Release.

Bei jeder neuen Datenquelle, jedem Anbieterwechsel und jeder Änderung der
Datenverarbeitung ist dieses Dokument im selben Commit zu aktualisieren.
Frühere Entscheidungen bleiben im Änderungsprotokoll nachvollziehbar.

Die finale Prüfung soll anhand dieses Dokuments ohne erneute Rekonstruktion der
gesamten Projektgeschichte möglich sein.

Es ist keine Rechtsberatung. Lizenzannahmen müssen vor dem ersten öffentlichen
Datensatz anhand der dann aktuellen Bedingungen erneut geprüft und im Release
protokolliert werden. Ziel der Architektur ist jedoch, eine rechtlich möglichst
klare Standardkonstellation zu schaffen, die keine kostspielige juristische
Einzelfallprüfung voraussetzt.

## 2. Wirtschaftliche Randbedingung und Risikoprinzip

Der Projektinhaber handelt als Privatperson und kann keine umfangreiche
anwaltliche Lizenzprüfung finanzieren. Wird eine individuelle juristische
Begutachtung zwingende Voraussetzung für die Veröffentlichung, gefährdet dies
die Realisierung des Projekts.

Daraus folgt:

1. Quellen mit klarer kommerzieller Nutzungserlaubnis werden bevorzugt.
2. Daten mit unterschiedlichen Lizenzen werden fachlich und technisch getrennt.
3. Lizenzpflichten werden lieber großzügig erfüllt als auf Grenzfälle gestützt.
4. Abgeleitete Open-Data-Bestände werden bei vertretbarem Aufwand offen
   bereitgestellt.
5. Unklare oder restriktive Quellen werden nicht verwendet.
6. Öffentlich erreichbare Gratisdienste werden nicht mit frei nutzbaren Daten
   verwechselt.
7. Kann ein wesentliches Restrisiko nicht durch Architektur oder Verzicht
   beseitigt werden, wird die betroffene Funktion verschoben.

### Akzeptiertes Restrisiko

Eine absolute Rechtssicherheit kann dieses Dokument nicht garantieren.
Akzeptiert wird nur das allgemeine Restrisiko, das bei nachvollziehbarer Nutzung
etablierter Standardlizenzen nach deren offiziellen Hinweisen verbleibt.

Nicht akzeptiert werden:

- bewusstes Vertrauen auf ungeklärte Lizenzgrenzen,
- Kopieren aus Quellen ohne ausdrückliches Weiterverwendungsrecht,
- Vermischen von Daten, wenn dadurch unklar wird, welche Share-Alike-Pflichten
  gelten,
- Geschäftsmodelle, die nur funktionieren, wenn Lizenzpflichten möglichst eng
  oder aggressiv ausgelegt werden.

## 3. Verbindliche Lizenzarchitektur für Version 1.0

ADR-0003 legt folgende konservative Struktur fest:

```text
BNetzA-Stammdaten (CC BY 4.0)
  -> charging.sqlite

OSM-Infrastruktur (ODbL 1.0)
  -> osm_amenities.sqlite
  -> separat unter ODbL bereitgestellt

lokale App-Daten
  -> Favoriten und Einstellungen
  -> keine Quelldatenbank
```

### 3.1 Trennung

- BNetzA-Ladepunkte, Leistungen, Betreiber und ausschließlich aus Distanz
  abgeleitete `proximity_group`-Objekte liegen im BNetzA-basierten
  Stammdatenartefakt.
- OSM-Infrastrukturmerkmale liegen in einem separaten Artefakt mit eigener
  Lizenz, Attribution und Versionsangabe.
- Die App darf beide Bestände zur Laufzeit gemeinsam anzeigen.
- Verknüpfungen bleiben nachvollziehbar und übertragen keine OSM-Eigenschaften
  in das BNetzA-Artefakt.
- Das OSM-Artefakt und die zu seiner Erzeugung nötige Extraktionsmethode werden
  unter ODbL-kompatiblen Bedingungen öffentlich angeboten.

### 3.2 Abstandsgruppierung

OSM-Parkplatzflächen, Straßen und Zufahrten werden in Version 1.0 nicht als
automatische Eingabe für die persistente Bildung oder Identität eines
Ladeparks verwendet. Die Version-1-Gruppierung nutzt ausschließlich
BNetzA-Koordinaten und den gewählten maximalen Gruppendurchmesser. Adresse,
Betreiber, Parkraumtext, Webseiten und fremde Karten haben keinen Einfluss.

Diese Einschränkung reduziert Automatisierungsqualität, vermeidet aber die
schwerer zu bewertende Frage, ob OSM die BNetzA-basierten Ladeparkobjekte zu
einer Derivative Database macht.

### 3.3 Änderung nur nach dokumentierter Prüfung

Eine spätere Verschmelzung, OSM-gestütztes automatisches Clustering oder
Übernahme von OSM-Koordinaten in das BNetzA-Artefakt erfordert:

- dokumentierte Bewertung anhand der dann aktuellen ODbL und OSMF-Guidelines,
- aktualisiertes ADR,
- klaren Bereitstellungsplan für abgeleitete Daten,
- Freigabe im Lizenzreview.

Kann die Einordnung nicht mit vertretbarem Aufwand geklärt werden, bleibt die
Trennung bestehen.

## 4. Quellenübersicht

| Quelle | Zweck | Lizenz/Bedarf | Status |
| --- | --- | --- | --- |
| Bundesnetzagentur-Ladesäulenregister | primäre Ladeinfrastruktur | CC BY 4.0, Namensnennung `bundesnetzagentur.de` | vorgesehen |
| OpenStreetMap | separates Infrastrukturartefakt, gegebenenfalls Karte | ODbL 1.0, Attribution und Share-Alike für den OSM-Bestand | vorgesehen |
| manuelle Recherche | Korrekturen, Zufahrt, Ausstattung großer Parks | nur aus Quellen mit dokumentiertem Weiterverwendungsrecht | vorgesehen |
| Kartenkacheln/-stil | Hintergrundkarte | anbieterabhängig | offen |
| Geocoding | Orts- und Adresssuche | anbieterabhängig | offen |

## 5. Bundesnetzagentur – CC BY 4.0

### 5.1 Eignung

Das Ladesäulenregister ist die primäre Quelle. Nach den
[FAQ der Bundesnetzagentur](https://www.bundesnetzagentur.de/DE/Fachthemen/ElektrizitaetundGas/E-Mobilitaet/FAQ/start.html)
enthält die veröffentlichte Liste öffentlich zugängliche Ladeeinrichtungen, die
das Anzeigeverfahren vollständig durchlaufen haben. Die Behörde weist zugleich
darauf hin, dass das Register die deutsche Ladeinfrastruktur nicht lückenlos
erfasst.

Die veröffentlichte Liste wird monatlich als CSV und XLSX angeboten. Die
[Fachthemenseite Elektromobilität](https://www.bundesnetzagentur.de/DE/Fachthemen/ElektrizitaetundGas/E-Mobilitaet/artikel.html)
nennt zusätzlich eine automatisierbare Schnittstelle mit tagesaktuellen Daten.
Deren technischer Vertrag ist vor Implementierung gesondert zu verifizieren.

### 5.2 Erlaubte Nutzung

Die Registerdaten stehen laut Bundesnetzagentur unter CC BY 4.0. Sie dürfen
kostenfrei und ausdrücklich auch kommerziell gespeichert, geteilt und
bearbeitet werden. Damit sind insbesondere App-Veröffentlichung, Filterung,
Normalisierung und Ladeparkbildung erlaubt.

Als Namensnennung ist `bundesnetzagentur.de` zu verwenden. Die
Bundesnetzagentur übernimmt keine Haftung für Richtigkeit und Vollständigkeit.

Pflichten für das Projekt:

- sichtbare Quellenangabe in der App und in den Datenmetadaten,
- Speicherung von Quell-URL, Abrufdatum und veröffentlichtem Datenstand,
- Beibehaltung des Lizenzhinweises im Datensatzmanifest,
- Link auf CC BY 4.0,
- Hinweis, dass die Daten normalisiert, gruppiert und ergänzt wurden,
- kein Eindruck einer Unterstützung oder Freigabe durch die Bundesnetzagentur,
- keine zusätzlichen rechtlichen oder technischen Beschränkungen speziell für
  den CC-BY-lizenzierten Ausgangsbestand,
- keine Darstellung der Daten als garantiert vollständig oder aktuell.

Vorgesehener Attributionstext:

> Ladeinfrastrukturdaten: bundesnetzagentur.de, lizenziert unter CC BY 4.0.
> Durch Ladepark Explorer normalisiert, gruppiert und teilweise ergänzt. Keine
> Gewähr für Vollständigkeit oder Richtigkeit.

CC BY 4.0 verpflichtet nicht zur Offenlegung des App-Quellcodes oder eigener
Algorithmen und enthält kein Share-Alike-Gebot.

### 5.3 Verifiziertes Veröffentlichungsschema

Die XLSX-Datei mit Stand 7. Juli 2026 wurde am 26. Juli 2026 auf Schemaebene
geprüft. Jede Datenzeile entspricht einer Ladeeinrichtung. Sie enthält 47
Spalten:

- Ladeeinrichtungs-ID,
- Betreiber und Anzeigename,
- Status und Art der Ladeeinrichtung,
- Anzahl und Nennleistung der Ladepunkte,
- Inbetriebnahmedatum,
- Straße, Hausnummer, Adresszusatz, Postleitzahl, Ort, Kreis und Bundesland,
- Breiten- und Längengrad,
- Standortbezeichnung und Informationen zum Parkraum,
- Bezahlsysteme,
- Öffnungszeiten einschließlich Wochentagen und Tageszeiten,
- sechs wiederholte Gruppen aus Steckertyp, Nennleistung, EVSE-ID und Public
  Key.

Das Schema ist eine beobachtete Quellschnittstelle, keine dauerhafte Garantie.
Der Importer muss Spalten anhand kanonischer Namen zuordnen, unbekannte Spalten
protokollieren und bei fehlenden Pflichtspalten kontrolliert abbrechen.

### 5.4 Grenzen

- Ein Registereintrag ist eine Ladeeinrichtung, kein Ladestandort.
- Gemeinsam gelegene Betreiber werden nicht zu einem Standort
  zusammengefasst.
- EVSE-IDs sind nur vorhanden, wenn sie gemeldet wurden.
- Infrastruktur wie WC, Café oder Restaurant ist nicht zuverlässig enthalten.
- Koordinaten und Betreiberangaben beruhen wesentlich auf Meldungen der
  Betreiber und können fehlerhaft sein.
- Die Zahl der veröffentlichten Ladeeinrichtungen ist nicht vollständig.

## 6. OpenStreetMap – ODbL 1.0

### 6.1 Was ist die OSM-Datei?

OpenStreetMap ist eine Geodatenbank, nicht nur die sichtbare Karte auf
openstreetmap.org. Ein regionaler OSM-Bulk-Extrakt enthält Knoten, Wege,
Flächen, Beziehungen und beschreibende Tags.

Das vorgesehene `.osm.pbf`-Format ist ein kompaktes Binärformat für große
OSM-Datenbestände. Ein Deutschlandextrakt ist mehrere Gigabyte groß und wird
nur von der Build-Pipeline verarbeitet. Er wird nicht vollständig an die App
ausgeliefert.

Mögliche Bezugsquelle ist der
[Deutschlandextrakt von Geofabrik](https://download.geofabrik.de/europe/germany.html).
Geofabrik ist ein externer Extraktanbieter; die enthaltenen Daten stammen von
OpenStreetMap-Mitwirkenden und bleiben unter ODbL. Anbieter, URL, Snapshot,
Hash und gegebenenfalls zusätzliche Anbieterbedingungen werden vor dem ersten
Download verbindlich registriert.

### 6.2 Vorgesehene Verwendung

OpenStreetMap kann liefern:

- WC, Automaten, Geschäfte, Cafés und Restaurants,
- Orts- und Adressdaten,
- Kartengrundlage, sofern ein geeigneter Kachel- oder Vektordienst gewählt wird.

OSM-Merkmale bleiben mit OSM-Objekt-ID, Objekttyp, Versions- beziehungsweise
Zeitinformation und verwendeten Tags nachvollziehbar.

In Version 1.0 werden Infrastrukturmerkmale in ein separates ODbL-Artefakt
extrahiert. Parkplatzflächen und Zufahrten dürfen angezeigt oder intern geprüft
werden, steuern aber nicht automatisch die persistente BNetzA-Ladeparkbildung.

### 6.3 Lizenzfolgen

OSM-Daten stehen gemäß der
[offiziellen Copyright-Seite](https://www.openstreetmap.org/copyright) unter
ODbL 1.0. Kommerzielle Nutzung ist erlaubt. Nutzung und Veränderung verlangen
Attribution; bei einer abgeleiteten Datenbank gelten Share-Alike- und
Bereitstellungspflichten. Die
[Attribution Guidelines der OSM Foundation](https://osmfoundation.org/wiki/Licence/Attribution_Guidelines)
verlangen für interaktive Karten regelmäßig eine sichtbare Attribution und für
Datenbanken einen Lizenzhinweis in Daten oder Metadaten.

Für Version 1.0 wird nicht versucht, diese Pflichten zu vermeiden:

- Der OSM-Ausgangsbestand und das extrahierte Infrastrukturartefakt werden als
  ODbL-Bestand behandelt.
- Das Extraktartefakt oder eine ODbL-konforme Methode zu seiner Erzeugung wird
  öffentlich angeboten.
- OSM und ODbL werden in App, Artefaktmetadaten und Downloadbereich genannt.
- Empfänger dürfen das OSM-Artefakt unter ODbL weiterverwenden.

Vorgesehener Attributionstext:

> Enthält Daten von OpenStreetMap-Mitwirkenden, verfügbar unter ODbL 1.0.

Die genaue Bereitstellungsform wird vor dem ersten OSM-basierten
Datensatzrelease praktisch getestet und in diesem Dossier protokolliert.

### 6.4 Collective und Derivative Database

Eine Collective Database enthält unabhängige Datenbestände. Bei ihr erfasst
Share-Alike nur den OSM-Teil. Eine Derivative Database entsteht vereinfacht,
wenn OSM-Daten verändert, korrigiert, erweitert oder so mit anderen Daten
verschmolzen werden, dass ein abgeleiteter Bestand entsteht.

Die
[Collective Database Guideline der OSM Foundation](https://osmfoundation.org/wiki/Licence/Community_Guidelines/Collective_Database_Guideline_Guideline)
erlaubt eine gemeinsame technische Speicherung unabhängiger Daten insbesondere dann,
wenn ein Merkmalstyp innerhalb einer Region vollständig aus OSM oder vollständig
aus einer Nicht-OSM-Quelle stammt. Physische Trennung ist nicht zwingend,
erleichtert aber Nachweis, Aktualisierung und Weitergabe.

Für das Projekt gilt deshalb:

- Ladeinfrastrukturmerkmalstypen stammen aus BNetzA.
- OSM-Infrastrukturmerkmalstypen stammen vollständig aus OSM.
- manuell recherchierte Infrastruktur wird nicht mit dem OSM-Artefakt
  dedupliziert oder verschmolzen, solange die lizenzielle Einordnung ungeklärt
  wäre.
- OSM und BNetzA erhalten getrennte Tabellen beziehungsweise Artefakte,
  Quellenmetadaten und Lizenzen.

### 6.5 Beschaffung

Systematische POI- und Parkplatzableitung erfolgt nicht über die öffentlichen
interaktiven Dienste von OSM.

Die öffentliche
[Nominatim Usage Policy](https://operations.osmfoundation.org/policies/nominatim/)
verbietet unter anderem clientseitiges Autocomplete und systematische
POI-Abfragen; reguläre Bulk-Geocodierung wird stark eingeschränkt. Daher gilt:

- kein öffentlicher Nominatim-Dienst als fest eingebauter
  Produktions-Autocomplete-Dienst,
- keine regelmäßige, deutschlandweite POI-Gewinnung über Nominatim,
- kein regelmäßiges Massenscraping öffentlicher Overpass-Instanzen,
- stattdessen regionaler PBF-/Bulk-Extrakt, eigener Dienst oder vertraglich
  geeigneter Datenanbieter,
- Anbieter und Aktualisierungsverfahren werden vor Implementierung entschieden.

## 7. Nominatim

### 7.1 Begriff

[Nominatim](https://nominatim.org/release-docs/latest/) ist Software für Suche,
Geocoding und Reverse Geocoding auf OSM-Daten:

- Text oder Adresse zu Koordinate,
- Koordinate zu Adresse.

Zu unterscheiden sind:

1. die selbst installierbare Open-Source-Software,
2. der öffentliche Dienst `nominatim.openstreetmap.org`,
3. kommerzielle oder anderweitig gehostete Nominatim-Dienste.

### 7.2 Öffentlicher Dienst

Die
[Nominatim Usage Policy](https://operations.osmfoundation.org/policies/nominatim/)
ist keine Datenlizenz, sondern eine zusätzliche Nutzungsregel des öffentlichen
OSMF-Servers. Sie begrenzt unter anderem Anfragerate und Bulk-Nutzung, verlangt
Identifikation, Caching und Attribution und verbietet clientseitiges
Autocomplete.

Entscheidung für Version 1.0:

- Der öffentliche Nominatim-Dienst wird nicht als Produktionsabhängigkeit in die
  App eingebaut.
- Lokale Orts-, Adress- und Ladeparksuche wird bevorzugt.
- Ein späterer Online-Geocoder benötigt klare kommerzielle Bedingungen,
  Datenschutzprüfung, Attribution und austauschbare Konfiguration.
- Eine eigene Nominatim-Installation ist wegen Backend- und Betriebsaufwand
  nicht für Version 1.0 vorgesehen.

Die ODbL der zugrunde liegenden OSM-Daten gilt unabhängig davon, ob Nominatim
selbst oder ein anderer Geocoder verwendet wird.

## 8. Kartenkacheln und Kartenstil

Freie OSM-Daten bedeuten nicht, dass öffentliche OSM-Kachelserver beliebig
genutzt werden dürfen. Die
[Tile Usage Policy](https://operations.osmfoundation.org/policies/tiles/)
verbietet auf `tile.openstreetmap.org` insbesondere Bulk-Download,
Vorabdownload und Offlinepakete und bietet kein SLA.

Für Version 1.0 gilt:

- kein Offline- oder Prefetch-Download von `tile.openstreetmap.org`,
- kein Produktionsbetrieb, der von kostenloser OSMF-Serverkapazität abhängt,
- Kartenanbieter nur mit dokumentierter kommerzieller App-Nutzung,
  Offline-Regelung, Attribution, Datenschutz und Kosten,
- alternativ selbst bereitgestellte Vektorkacheln unter Erfüllung der ODbL.

Anbieter und Betriebsmodell bleiben offen. Vor Auswahl wird ein eigener Eintrag
im Quellen- und Diensteregister dieses Dokuments ergänzt.

## 9. Manuelle Recherche

Manuelle Ergänzungen sind besonders für große und fachlich wichtige Standorte
zulässig. Jede Angabe benötigt:

- eine interne Regel- beziehungsweise Review-ID,
- die betroffene stabile Objekt-ID,
- Quelle oder nachvollziehbaren Vor-Ort-Nachweis,
- Prüfdatum,
- Bearbeiter,
- übernommene Aussage,
- Lizenz beziehungsweise dokumentiertes Recht zur Weiterverwendung,
- optional ein Ablauf- oder Wiedervorlagendatum.

Informationen aus Google Maps, Betreiberwebseiten oder anderen
urheberrechtlich geschützten Angeboten dürfen nicht allein wegen ihrer
öffentlichen Sichtbarkeit in den Datensatz kopiert werden. Google Maps ist in
Version 1.0 Zielanwendung für Navigation, nicht automatisch Datenquelle.

Zulässige manuelle Quellen sind:

- eigene Vor-Ort-Feststellung,
- ausdrücklich offen lizenzierte Daten,
- schriftlich freigegebene Betreiberangaben,
- amtliche offene Daten mit kompatibler Lizenz.

Die bloße Überprüfung einer eigenen Feststellung anhand einer Karte erlaubt
nicht das Kopieren geschützter Detailangaben aus dieser Karte.

Der in ADR-0012 entschiedene redaktionelle Informationsbestand verwendet
anfänglich ausschließlich eigene Vor-Ort-Feststellungen und eigene Fotos. Für
jedes veröffentlichte Foto werden Urheber, Aufnahmezeitpunkt, Prüfstatus und
Dateiprüfsumme dokumentiert. Personen und Kennzeichen werden vermieden oder
unkenntlich gemacht; Innenaufnahmen und Aufnahmen entgegen einem erkennbaren
Hausrecht werden nicht veröffentlicht. Das konkrete Foto- und
Freigabeverfahren wird vor dem ersten produktiven Bildbestand rechtlich
geprüft.

## 10. Betreiberlinks und Betreiberkoordinaten

### 10.1 Hyperlinks

Links auf frei zugängliche offizielle Betreiber- oder Standortseiten dürfen
manuell kuratiert und in der App angezeigt werden, sofern:

- keine Zugangssperre oder Bezahlschranke umgangen wird,
- kein erkennbar rechtswidrig veröffentlichter Inhalt verlinkt wird,
- regelmäßig geprüft wird, ob der Link noch zum beabsichtigten offiziellen
  Ziel führt,
- kein Eindruck einer Partnerschaft oder Empfehlung durch den Betreiber
  erzeugt wird,
- keine Logos, Vorschaubilder oder Seitentexte ohne Erlaubnis übernommen werden.

Der Europäische Gerichtshof hat das Verlinken frei zugänglicher, mit Zustimmung
veröffentlichter Inhalte grundsätzlich von einer neuen öffentlichen Wiedergabe
unterschieden. Bei Gewinnerzielungsabsicht steigen jedoch die
Prüfanforderungen, wenn Inhalte möglicherweise ohne Zustimmung veröffentlicht
wurden.

Für das Projekt werden nur erkennbare offizielle Betreiberseiten verlinkt.

### 10.2 Koordinaten und Standortdaten

Eine Webseite öffentlich ansehen zu können bedeutet nicht, dass ihre
Koordinaten oder Standortdaten in eine eigene Datenbank übernommen werden
dürfen. Einzelne Koordinaten sind zwar regelmäßig Tatsachen; Nutzungsbedingungen
und Datenbankrechte können aber insbesondere eine wiederholte oder
systematische Extraktion begrenzen.

Verbindliche Regel:

- Keine GPS-Koordinaten werden aus Betreiberwebseiten, Google Maps oder Apple
  Karten abgelesen und gespeichert.
- Die Zuordnung eines Links zu einer Station erfolgt über BNetzA-Identität,
  BNetzA-Adresse und Betreibername.
- Eine standortspezifische Bestätigung oder abweichende Koordinate wird nur mit
  ausdrücklicher Betreiberbestätigung übernommen.
- Betreiberwebseiten dürfen Anlass für eine Bestätigungsanfrage sein, nicht
  alleinige Quelle einer Zusammengehörigkeitsregel.
- Es erfolgt kein Scraping oder automatisiertes Crawling ohne ausdrückliche
  Erlaubnis und dokumentierte Bedingungen.

Damit bleiben die Links ein redaktioneller Verweis und werden nicht zum
Einfallstor für eine neue, aus fremden Webseiten extrahierte Standortdatenbank.

### 10.3 Manueller Adressabgleich

Die auf einer frei zugänglichen offiziellen Betreiberseite sichtbare Adresse
darf manuell gelesen werden, um zu prüfen, ob die Seite zu einer bereits aus
der BNetzA bekannten Ladeeinrichtung gehört.

Dabei gilt:

- Die Webseitenadresse dient nur als Abgleichkriterium.
- In `charging` gespeichert und in der App angezeigt wird weiterhin die
  BNetzA-Adresse.
- Neu gespeichert wird nur die redaktionelle Zuordnung von `station_id` zu
  URL, Prüfdatum und Zuordnungsmethode.
- Die Webseitenadresse wird weder als separater Rohwert archiviert noch als
  Betreiberadressdatenbank veröffentlicht.
- Es erfolgt keine automatisierte Extraktion, kein Scraping und kein
  massenhafter Seitenabruf.

Der Vorgang ist eine eigene redaktionelle Entscheidung:

> Diese frei zugängliche offizielle Seite beschreibt nach manuellem Vergleich
> denselben Standort wie diese bereits bekannte BNetzA-Station.

Vorgesehener Nachweis:

```text
operator_link_id
station_id
url
link_type
matching_method
matching_status
checked_at
optional permission_reference
```

Zulässige `matching_method`-Werte:

- `manual_exact_address_match`,
- `manual_name_and_address_match`,
- `operator_confirmation`.

Zulässige `matching_status`-Werte:

- `verified`: eindeutige manuelle Übereinstimmung oder Betreiberbestätigung,
- `needs_confirmation`: mehrdeutig; nicht in der App anzeigen,
- `rejected`: Seite gehört nicht eindeutig zur Station.

### 10.4 Entscheidungsregeln

Eine URL darf ohne Betreiberanfrage zugeordnet werden, wenn:

- die Seite erkennbar eine offizielle Betreiber- oder Standortseite ist,
- Betreibername und vollständige Adresse mit der BNetzA-Zuordnung eindeutig
  übereinstimmen, oder
- Standortname, Ort und Adresse gemeinsam nur eine plausible BNetzA-Station
  ergeben.

Eine URL darf nicht produktiv zugeordnet werden, wenn:

- die Adressen abweichen,
- nur ein Ort oder eine Kartenmarkierung ohne eindeutige Adresse vorhanden ist,
- mehrere BNetzA-Stationen desselben Betreibers infrage kommen,
- die Webseite mehrere Standorte gemeinsam beschreibt,
- Betreiber oder Standortzugehörigkeit unklar sind.

Diese Fälle erhalten `needs_confirmation`. Nur bei fachlicher Relevanz wird der
Betreiber gezielt um Bestätigung gebeten. Eine flächendeckende Kontaktaufnahme
mit allen Betreibern ist nicht erforderlich.

### 10.5 Korrektur von Adresse oder Koordinate

Eine von der BNetzA abweichende Adresse oder Koordinate auf einer Webseite wird
nicht als Korrektur übernommen. Eine Korrektur ist nur zulässig durch:

1. ausdrückliche Betreiberbestätigung mit dokumentiertem Verwendungsrecht,
2. kompatibel lizenzierte Open Data oder
3. eigene Vor-Ort-Feststellung.

Bei Betreiberbestätigung werden mindestens gespeichert:

```text
source = operator_confirmation
permission_reference
confirmed_at
confirmed_fields
```

Die Bestätigung muss erkennen lassen, dass die sachlichen Angaben im Ladepark
Explorer gespeichert und veröffentlicht werden dürfen.

Vorgesehener Datensatz:

```text
operator_link_id
operator_id
optional station_id
url
link_type
checked_at
permission_reference
```

Nicht gespeichert werden Seitentexte, Bilder, Karten, fremde Koordinaten oder
sonstige extrahierte Standortmerkmale.

## 11. Dynamische Abstandsgruppen und Community-Daten

Version 1.0 bildet Abstandsgruppen ausschließlich aus BNetzA-Koordinaten und
einem konfigurierbaren maximalen Gruppendurchmesser. Standard sind 50 Meter.
Google, Apple, OSM und Betreiberwebseiten beeinflussen diese Berechnung nicht.

Ab Version 1.5 können originäre Nutzerantworten und ausdrückliche
Betreiberbestätigungen versionierte `verified_park`-Regeln erzeugen.
Teilnahmebedingungen müssen dem Projekt die erforderlichen Rechte zur
Speicherung, Aggregation, Bearbeitung und Veröffentlichung der sachlichen
Rückmeldungen einräumen. Einzelantworten werden nicht ungeprüft produktiv.

Diese Entscheidung ist in ADR-0004 dokumentiert.

## 12. Provenienz und Konflikte

Jede fachliche Angabe erhält, soweit technisch sinnvoll:

- Quellsystem,
- Quellobjekt-ID,
- Abruf- oder Prüfdatum,
- Importlauf,
- Ermittlungsmethode,
- Lizenzkennung,
- Vertrauensstatus.

Prioritätsregeln:

1. Version 1.0 kennt keine manuellen Merge-/Splitregeln ohne ausdrückliche
   Betreiberbestätigung.
2. Zulässig überprüfte Infrastrukturangaben dürfen automatische Angaben
   übersteuern, müssen aber ein Prüfdatum besitzen.
3. Widersprüchliche Quellwerte werden nicht verlustlos überschrieben; der
   gewählte Wert und seine Herkunft bleiben nachvollziehbar.
4. Fehlende Angaben werden als unbekannt behandelt.

Die genaue feldbezogene Konfliktauflösung steht in `05_Importer.md`.

## 13. Pflichtdarstellung in der App

Mindestens ein dauerhaft erreichbarer Bereich „Datenquellen und Lizenzen“
enthält:

- BNetzA-Attribution und CC-BY-4.0-Link,
- Bearbeitungshinweis,
- OSM-Attribution und ODbL-Link,
- Datenstände,
- Karten-, Geocoding- und weitere Anbieter,
- Haftungs- und Vollständigkeitshinweis,
- Link zum öffentlich angebotenen OSM-Ableitungsartefakt beziehungsweise zur
  Erzeugungsmethode.

Wenn die Karte OSM-Daten zeigt, erscheint die OSM-Attribution zusätzlich
sichtbar an oder nahe der Karte entsprechend den OSMF Attribution Guidelines.

## 14. Technische Nachweise

Pro Datensatzrelease werden archiviert:

- verwendete Lizenztexte beziehungsweise unveränderliche Referenz-URLs,
- Datum der Lizenzprüfung,
- Quell- und Dienstanbieterbedingungen,
- Quelldateiname, Download-URL, Snapshot und Hash,
- Pipeline-Version,
- Zuordnung jedes Ausgabeartefakts zu seiner Lizenz,
- Screenshot beziehungsweise UI-Test der Attribution,
- URL und Hash des veröffentlichten ODbL-Artefakts,
- ausgefüllte Release-Checkliste,
- Abweichungen und Freigabeentscheidung.

## 15. Release-Checkliste

Vor Veröffentlichung jedes Datensatzes:

- [ ] Jede Quelle steht im Quellenregister.
- [ ] Kommerzielle Nutzung ist ausdrücklich erlaubt.
- [ ] Lizenzstand und Bedingungen wurden erneut geprüft und datiert.
- [ ] Quell-URL, Snapshot und Hash sind archiviert.
- [ ] BNetzA-Attribution nennt `bundesnetzagentur.de`, CC BY 4.0 und
      Bearbeitung.
- [ ] OSM-Attribution und ODbL-Link sind sichtbar und im Artefakt enthalten.
- [ ] OSM- und BNetzA-Artefakte sind weiterhin fachlich nachvollziehbar
      getrennt.
- [ ] Die Version-1-Gruppierung verwendet ausschließlich BNetzA-Koordinaten,
      oder eine spätere abweichende Entscheidung ist vollständig dokumentiert.
- [ ] ODbL-Artefakt beziehungsweise Erzeugungsmethode ist öffentlich
      erreichbar.
- [ ] Karten- und Geocodingdienste erlauben die konkrete Produktionsnutzung.
- [ ] Kein öffentlicher Gratisdienst wird entgegen seiner Usage Policy genutzt.
- [ ] Manuelle Angaben besitzen ein dokumentiertes Weiterverwendungsrecht.
- [ ] Keine Google-Maps- oder Webseiteninhalte wurden ohne Erlaubnis kopiert.
- [ ] Betreiberlinks führen auf erkennbare frei zugängliche offizielle Seiten.
- [ ] Keine Koordinaten oder Standortmerkmale wurden aus Betreiberwebseiten
      extrahiert.
- [ ] Ein manueller Adressabgleich speichert weiterhin nur die BNetzA-Adresse
      und die redaktionelle URL-Zuordnung.
- [ ] Mehrdeutige Linkzuordnungen werden nicht produktiv angezeigt.
- [ ] Abweichende Adressen oder Koordinaten besitzen eine dokumentierte
      Betreiberbestätigung oder andere zulässige Quelle.
- [ ] Attributionen wurden im UI-Test geprüft.
- [ ] Manifest und Qualitätsbericht enthalten alle Lizenzmetadaten.
- [ ] Keine nicht freigegebenen Roh- oder personenbezogenen Daten sind
      enthalten.
- [ ] Alle offenen roten Risiken sind geschlossen oder die Funktion wurde aus
      dem Release entfernt.

## 16. Ampelbewertung

| Thema | Status | Begründung/Nächste Aktion |
| --- | --- | --- |
| BNetzA kommerziell verwenden | Grün | CC BY 4.0 erlaubt kommerzielle Nutzung; Attribution und Bearbeitungshinweis umsetzen |
| BNetzA-Abstandsgruppierung | Grün | ausschließlich eigene Distanzberechnung aus CC-BY-Daten |
| separates OSM-Infrastrukturartefakt | Gelb-Grün | ODbL-Pflichten bewusst vollständig erfüllen; Bereitstellung praktisch testen |
| OSM-basiertes automatisches Park-Clustering | Rot für 1.0 | potenzielle Derivative-Database-Frage; vorerst nicht verwenden |
| öffentlicher Nominatim-Dienst | Rot für Produktion | Usage Policy und Skalierungsrisiko |
| öffentlicher OSM-Rastertile-Dienst offline | Rot | Offline-/Bulk-Download untersagt |
| lokaler Suchindex aus BNetzA-Daten | Grün | CC BY 4.0 mit Attribution |
| kommerzieller Karten-/Geocodinganbieter | Offen | Vertrag, Datenschutz, Kosten und Attribution prüfen |
| manuell recherchierte Angaben | Gelb | nur mit eigenem Nachweis oder ausdrücklichem Weiterverwendungsrecht |
| eigene Vor-Ort-Feststellungen | Grün-Gelb | eigene Erhebung, Erhebungsdatum und Review dokumentieren |
| eigene Ladeparkfotos | Gelb | Aufnahmeort, Hausrecht, Personen, Kennzeichen und Markenwirkung vor Veröffentlichung prüfen |
| kuratierter Link auf offizielle Betreiberseite | Grün-Gelb | Linkprüfung, keine Zugangsumgehung, keine kopierten Inhalte oder suggerierte Partnerschaft |
| manueller Adressabgleich zur URL-Zuordnung | Grün-Gelb | Webseitenadresse nur lesen und vergleichen; BNetzA-Adresse und eigene Linkentscheidung speichern |
| Koordinaten aus Betreiberwebseite übernehmen | Rot | mögliche Nutzungs-/Datenbankrechtsfragen; BNetzA-Koordinaten oder Betreiberbestätigung verwenden |
| abweichende Webseitenadresse als Korrektur übernehmen | Rot ohne Bestätigung | nur mit Betreiberfreigabe, kompatibler Open-Data-Quelle oder eigener Feststellung |
| dynamische Gruppen nur aus BNetzA-Abstand | Grün | CC BY 4.0 erlaubt Bearbeitung; Näherungscharakter transparent machen |
| originäres Nutzerfeedback ab Version 1.5 | Gelb-Grün | eigene Teilnahmebedingungen, Missbrauchsschutz und Reviewprozess erforderlich |

„Gelb-Grün“ bedeutet: Die Standardlizenz ist grundsätzlich handhabbar, aber der
konkrete Veröffentlichungs- und Attributionsprozess muss vor Release technisch
nachgewiesen werden. „Rot“ bedeutet: nicht implementieren oder ausliefern,
solange keine neue dokumentierte Entscheidung vorliegt.

## 17. Offene Entscheidungen

- Nutzung der neuen Bundesnetzagentur-Webserviceschnittstelle oder
  dateibasierter Import,
- konkreter OSM-Bulk-Datenanbieter,
- Kartenkachel-, Stil- und Geocodinganbieter,
- Attributionsdarstellung in Karte, Detailansicht und Einstellungsbereich,
- Aufbewahrungsdauer der Quelldateien,
- Hostingort und Format des öffentlichen ODbL-Artefakts,
- genaue Grenze zwischen OSM-Infrastruktur und eigener manueller Feststellung.
- verbindlicher Foto-Reviewprozess einschließlich Hausrecht, Datenschutz und
  dokumentierter Entfernung beanstandeter Bilder.

Keine dieser offenen Entscheidungen darf die beschlossene Trennung von BNetzA
und OSM oder den getrennten redaktionellen Bestand stillschweigend aufheben.

## 18. Änderungsprotokoll

| Datum | Änderung | Entscheidung/Nachweis |
| --- | --- | --- |
| 26.07.2026 | Erstanlage der Quellen- und Lizenzbewertung | BNetzA CC BY 4.0 und OSM ODbL als vorgesehene Quellen dokumentiert |
| 26.07.2026 | Ausbau zum Compliance-Dossier | wirtschaftliche Randbedingung aufgenommen; getrennte BNetzA-/OSM-Artefakte und Verzicht auf OSM-Clustering für Version 1.0 festgelegt |
| 26.07.2026 | Dynamische Abstandsgruppen und Betreiberlinks | Version 1.0 gruppiert nur anhand BNetzA-Distanzen; Koordinaten werden nicht aus Webseiten übernommen; bestätigte Parks folgen ab Version 1.5 |
| 26.07.2026 | Manueller Adressabgleich | Betreiberadresse darf zur eindeutigen URL-Zuordnung gelesen, aber nicht als eigener Datenwert übernommen werden; unklare und abweichende Fälle benötigen Bestätigung |
