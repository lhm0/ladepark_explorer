# Anforderungen – Version 1.0

Status: Verbindlicher Spezifikationskern

Stand: 26. Juli 2026

## 1. Verwendung

Dieses Dokument beschreibt beobachtbares Produktverhalten. Anforderungen mit
Priorität **Muss** gehören zum Umfang von Version 1.0. Technische Einzelheiten
werden in den nachgelagerten Kapiteln festgelegt.

Kennzeichnung:

- `FR`: funktionale Anforderung
- `NFR`: nicht-funktionale Anforderung
- Priorität `Muss`: für Version 1.0 erforderlich
- Priorität `Soll`: wichtig, darf aber bei einem dokumentierten,
  releasebezogenen Grund verschoben werden

## 2. Kartenansicht und Standortsuche

### FR-MAP-001 – Ladestandorte auf der Karte

- Priorität: Muss
- Beschreibung: Die App zeigt Ladestandorte des installierten Datensatzes auf
  einer verschieb- und zoombaren Karte an.
- Akzeptanz:
  - Beim ersten Start ist eine sinnvolle Deutschlandansicht sichtbar.
  - Verschieben und Zoomen aktualisieren die sichtbaren Standorte.
  - Mehrere Ladepunkte desselben ermittelten Standorts erscheinen als ein
    gemeinsamer Ladestandort.
  - Die Darstellung bleibt ohne Internetzugang nutzbar, soweit die verwendeten
    Kartendaten lokal beziehungsweise im Plattformcache vorhanden sind.

### FR-MAP-002 – Eigener Standort

- Priorität: Muss
- Beschreibung: Nach erteilter Systemberechtigung kann die eigene Position auf
  der Karte angezeigt und als Ausgangspunkt einer Umgebungssuche verwendet
  werden.
- Akzeptanz:
  - Die App fordert die Berechtigung erst an, wenn eine Standortfunktion
    verwendet wird.
  - Eine verweigerte oder nicht verfügbare Berechtigung verhindert nicht die
    manuelle Nutzung von Karte, Suche und Filtern.
  - Nutzende können die Karte wieder auf ihre aktuelle Position zentrieren.

### FR-GROUP-001 – Dynamische Abstandsgruppen

- Priorität: Muss
- Beschreibung: Die App fasst Ladeeinrichtungen anhand eines wählbaren
  maximalen Gruppendurchmessers räumlich zusammen.
- Akzeptanz:
  - Verfügbare Werte sind mindestens 25, 50, 100, 200 und 300 Meter.
  - Standardwert ist 50 Meter.
  - In jeder erzeugten Gruppe beträgt jede paarweise Stationsdistanz höchstens
    den gewählten Wert.
  - Gleiche Eingaben, Datensatzversion und Einstellung erzeugen dasselbe
    Ergebnis.
  - Die Oberfläche bezeichnet das Ergebnis als räumliche Näherung und weist
    darauf hin, dass Zufahrten, Straßen und Grundstücksgrenzen nicht geprüft
    werden.
  - Eine Einstellungsänderung berechnet Darstellung und Aggregate ohne
    Datendownload neu.

### FR-SEARCH-001 – Textsuche

- Priorität: Muss
- Beschreibung: Nutzende können nach Ort, Adresse oder Name eines Ladestandorts
  suchen.
- Akzeptanz:
  - Treffer können ausgewählt und auf der Karte geöffnet werden.
  - Eine Suche ohne Treffer zeigt einen verständlichen Leerzustand.
  - Ein Orts- oder Adressname wird zunächst auf eine Koordinate aufgelöst.
    Anschließend wird unabhängig vom Ortsfeld des Ladebestands der nächste
    Ladepark gesucht, der die aktiven Filter erfüllt.
  - Die Karte bleibt auf den gesuchten Ort zentriert und zeigt mindestens den
    nächsten passenden Ladepark, sofern innerhalb von 200 Kilometern einer
    vorhanden ist.
  - Bereits lokal verfügbare Standort- und Adressdaten sind offline
    durchsuchbar.
  - Direkte Koordinaten und nicht verkürzte Apple- beziehungsweise
    Google-Maps-URLs mit enthaltenen Koordinaten können eingegeben werden.
  - Der App-Link
    `ladeparkexplorer://location?lat=<latitude>&lon=<longitude>` öffnet die
    übergebene Koordinate in der Karte.
  - Eine gegebenenfalls online arbeitende Geocodingsuche ist als solche
    erkennbar und blockiert die lokale Suche nicht.

### FR-SEARCH-002 – Standorte in meiner Nähe

- Priorität: Muss
- Beschreibung: Nutzende können Ladestandorte anhand der Entfernung zur
  aktuellen Position anzeigen beziehungsweise filtern.
- Akzeptanz:
  - Die Entfernung wird aus aktueller Position und Standortkoordinaten
    berechnet.
  - Der Suchradius ist einstellbar.
  - Verfügbare Radien sind 5, 10, 25, 50 und 100 Kilometer.
  - Ohne Standortberechtigung erklärt die App, wie die Funktion aktiviert
    werden kann.

## 3. Filterung

### FR-FILTER-001 – Ladeangebot filtern

- Priorität: Muss
- Beschreibung: Ladestandorte können mindestens nach folgenden Kriterien
  gefiltert werden:
  - gekoppelte Mindestanzahl von Ladepunkten, die jeweils eine einstellbare
    Mindestleistung in kW erfüllen,
  - Betreiber,
  - Steckertyp,
  - Öffnungszeiten,
  - Entfernung zum aktuellen Standort,
  - nur Favoriten.
- Akzeptanz:
  - Mehrere aktive Filter werden mit UND verknüpft; Mehrfachwerte innerhalb
    eines Filters, etwa mehrere Betreiber, werden mit ODER verknüpft.
  - Ein Standort, der einen Grenzwert exakt erfüllt, wird angezeigt.
  - Ladepunkte unterhalb der gewählten Mindestleistung gehen nicht in die
    gewählte Mindestanzahl ein.
  - Änderungen wirken ohne erneuten Datendownload.
  - Aktive Filter sind sichtbar und können gemeinsam zurückgesetzt werden.
  - Die Filterauswahl bleibt über einen App-Neustart erhalten; sie wird lokal
    gespeichert (`ADR-0016`). Ausgenommen ist „Entfernung zum aktuellen
    Standort“, da dieser Filter einen aktuellen Standort voraussetzt und beim
    Start zurückgesetzt wird.
  - Das Verlassen der Filteransicht über Zurück übernimmt den sichtbaren
    Filterstand.
  - „Abbruch“ stellt den Stand beim Öffnen der Filteransicht wieder her, ohne
    die Ansicht zu schließen.
  - „Standard herstellen“ setzt alle Filter auf die definierten Standardwerte,
    ohne die Ansicht zu schließen.
  - „Nur Favoriten“ zeigt ausschließlich Gruppen, die mindestens einen lokal
    gespeicherten Stationsanker enthalten; ohne Favoriten ist das Ergebnis
    leer.
  - Favorisierte Gruppen sind auch ohne aktiven Favoritenfilter auf der Karte
    durch einen grünen Herz-Blitz-Marker erkennbar.
  - Die 20 Betreiber mit den meisten Ladepunkten werden direkt mit ihrem
    kuratierten Anzeigenamen angeboten, innerhalb dieser Auswahl alphabetisch
    sortiert und mit der Ladepunktzahl in Klammern gekennzeichnet.
  - Weitere, noch nicht kanonisierte Betreiberbezeichnungen sind ab zwei
    Zeichen lokal durchsuchbar und auswählbar.

### FR-FILTER-002 – Infrastruktur filtern

- Priorität: Muss
- Beschreibung: Ladestandorte können nach vorhandener Infrastruktur gefiltert
  werden: WC, Automaten, Einkaufsmöglichkeiten, Café und Restaurant.
- Akzeptanz:
  - Jede Kategorie kann unabhängig aktiviert oder deaktiviert werden.
  - Mehrere ausgewählte Kategorien müssen am Standort gemeinsam vorhanden sein.
  - „Nicht vorhanden“ und „unbekannt“ werden fachlich unterschieden.
  - Ein Standort mit unbekanntem Merkmal erfüllt einen auf „vorhanden“
    gesetzten Filter nicht.

### FR-FILTER-003 – Standardfilter

- Priorität: Muss
- Beschreibung: Beim ersten Start werden reine AC-Standorte standardmäßig
  ausgeblendet. Sichtbar sind Abstandsgruppen mit maximal 50 Metern
  Gruppendurchmesser und mindestens 20 Ladepunkten, deren jeweils ausgewiesene
  maximale Leistung mindestens 100 kW beträgt.
- Akzeptanz:
  - Nutzende können die Mindestleistung reduzieren und dadurch weitere
    Standorte einschließlich reiner AC-Standorte sichtbar machen.
  - Nutzende können die erforderliche Ladepunktzahl reduzieren.
  - Das Zurücksetzen stellt 50 Meter Gruppendurchmesser, 20 erforderliche
    Ladepunkte und 100 kW Mindestleistung je Ladepunkt wieder her.

## 4. Standortdetails und Navigation

### FR-DETAIL-001 – Detailansicht

- Priorität: Muss
- Beschreibung: Für einen Ladestandort werden mindestens folgende bekannte
  Informationen angezeigt:
  - Name und Adresse,
  - Betreiber am Standort,
  - Koordinaten,
  - Gesamtzahl gleichzeitig nutzbarer Ladepunkte,
  - Anzahl der Ladepunkte je Leistungsklasse,
  - höchste ausgewiesene Ladeleistung,
  - Steckertypen,
  - Öffnungszeiten,
  - Infrastrukturmerkmale,
  - Datenstand und Datenquellen.
- Akzeptanz:
  - Fehlende Angaben werden als unbekannt und nicht mit einem erfundenen Wert
    dargestellt.
  - Bei Infrastrukturmerkmalen können „vorhanden“, „nicht vorhanden“ und
    „unbekannt“ unterschieden werden.
  - Mehrere Betreiber eines gemeinsamen Standorts werden dargestellt.
  - Eine kompakte Matrix schlüsselt die Ladepunkte nach Betreiber,
    disjunkter Leistungsklasse und Steckertyp auf; Stationszahlen werden in
    dieser Ansicht nicht gezeigt.
  - Die angegebene Leistung wird nicht als garantierte reale Ladeleistung
    bezeichnet.

### FR-NAV-001 – Übergabe an Navigations-App

- Priorität: Muss
- Beschreibung: Die Koordinaten eines Ladestandorts können an Apple Maps oder
  Google Maps als Navigationsziel übergeben werden.
- Akzeptanz:
  - Apple Maps kann auf einem unterstützten iPhone als Ziel geöffnet werden.
  - Ist Google Maps installiert, kann es als Zielanwendung gewählt werden.
  - Ist eine gewählte Anwendung nicht verfügbar, bietet die App eine
    verständliche Alternative.
  - Ohne bestätigten Navigationspunkt werden die Koordinaten der Anker-Station
    oder einer vom Nutzer gewählten Station übergeben.

### FR-LINK-001 – Offizielle Betreiberlinks

- Priorität: Soll
- Beschreibung: Die App kann kuratierte Links zu frei zugänglichen offiziellen
  Betreiber- oder Standortseiten anzeigen.
- Akzeptanz:
  - Der Link ist als externe Betreiberwebseite gekennzeichnet.
  - Es werden keine Zugangssperren umgangen und keine fremden Texte, Bilder,
    Karten oder Logos übernommen.
  - Eine standortspezifische Zuordnung beruht auf BNetzA-Daten oder
    ausdrücklicher Betreiberbestätigung.
  - Eine Adresse auf der Betreiberseite darf manuell mit der BNetzA-Adresse
    verglichen werden; gespeichert und angezeigt bleibt die BNetzA-Adresse.
  - GPS-Koordinaten werden nicht aus der Betreiberwebseite übernommen.
  - Bei mehrdeutiger oder abweichender Adresse wird der Link ohne
    Betreiberbestätigung nicht produktiv angezeigt.
  - Linkziel und Prüfdatum sind dokumentiert.
  - Die Darstellung suggeriert keine Partnerschaft oder Empfehlung.

## 5. Favoriten

### FR-FAV-001 – Lokale Favoriten

- Priorität: Muss
- Beschreibung: Ladestandorte können als Favoriten gespeichert und wieder
  entfernt werden.
- Akzeptanz:
  - Favoriten bleiben nach Neustart, Datensatzupdate und Änderung des
    Gruppendurchmessers über eine stabile Anker-Station auffindbar.
  - Favoriten werden ausschließlich lokal gespeichert.
  - Es ist kein Benutzerkonto erforderlich.
  - Eine eigene Ansicht zeigt ausschließlich Favoriten.
  - Ist ein Stationsanker nicht mehr auflösbar, bleibt der Favorit mit seinem
    Darstellungssnapshot als derzeit nicht verfügbar erhalten.
  - Eine automatische Neuzuordnung nur anhand räumlicher Nähe findet nicht
    statt.

## 6. Datensatz und Aktualisierung

### FR-DATA-001 – Mitgelieferter Basisdatensatz

- Priorität: Muss
- Beschreibung: Die App wird mit einem verwendbaren Basisdatensatz für
  Deutschland ausgeliefert.
- Akzeptanz:
  - Karte, lokale Suche, Filter und Detailansicht sind vor dem ersten
    Datendownload nutzbar.
  - Die App zeigt Version und Erstellungsdatum des installierten Datensatzes.
  - Alle öffentlich zugänglichen Standorte werden importiert, soweit sie in den
    verwendeten Quellen verfügbar und lizenzrechtlich nutzbar sind.

### FR-DATA-002 – Datensatzaktualisierung

- Priorität: Muss
- Beschreibung: Die App prüft standardmäßig automatisch, ob ein neuer
  versionierter Datensatz verfügbar ist. Nutzende können diese Prüfung
  deaktivieren und manuell auslösen.
- Akzeptanz:
  - Die automatische Prüfung ist in den Einstellungen konfigurierbar.
  - Ein Datensatz darf über WLAN oder Mobilfunk geladen werden.
  - Vor dem Download werden mindestens Version beziehungsweise Datenstand und
    Downloadgröße angezeigt.
  - Ein unvollständiger, beschädigter oder nicht verifizierbarer Download
    ersetzt den funktionsfähigen Datensatz nicht.
  - Nach erfolgreichem Austausch bleiben Favoriten über ihre Anker-Station
    erhalten.
  - Das Veröffentlichungsziel für neue Datensätze ist einmal pro Monat.

### FR-DATA-003 – Quellen und Datenunsicherheit

- Priorität: Muss
- Beschreibung: Ladeinformationen und Infrastrukturmerkmale können aus
  verschiedenen Quellen stammen und müssen nachvollziehbar bleiben.
- Akzeptanz:
  - Für importierte Datensätze werden Quelle und Abruf- beziehungsweise
    Recherchestand gespeichert, soweit verfügbar.
  - Manuell recherchierte Ergänzungen sind von automatisiert übernommenen
    Angaben unterscheidbar.
  - Unsichere oder fehlende Infrastrukturinformationen werden nicht als sicher
    vorhanden dargestellt.

### FR-DATA-004 – Redaktionelle Standortinformationen und Fotos

- Priorität: Muss
- Beschreibung: Für ausgewählte Ladeparks kann die App selbst vor Ort
  erhobene Infrastrukturinformationen und eigene Fotos aus einem getrennten,
  lokal installierten Informationsbestand anzeigen.
- Akzeptanz:
  - Der Informationsbestand wird außerhalb der App gepflegt, geprüft und als
    versioniertes read-only Artefakt erzeugt.
  - Er unterscheidet Restaurant, Shop, Kaffeeautomat, Snackautomat und Toilette
    sowie jeweils `vorhanden`, `nicht vorhanden` und `unbekannt`.
  - Jede veröffentlichte Angabe zeigt mindestens ihr Erhebungsdatum; fehlende
    Abdeckung wird nicht als `nicht vorhanden` dargestellt.
  - Fotos stammen anfänglich aus eigener Erhebung und durchlaufen vor der
    Veröffentlichung eine dokumentierte Rechte- und Datenschutzprüfung.
  - Personen und Fahrzeugkennzeichen sind nicht erkennbar.
  - Die Zuordnung bleibt bei einem Wechsel des Gruppendurchmessers über stabile
    Stationsreferenzen erhalten.
  - Der Bestand wird zunächst mit der App ausgeliefert und benötigt zur Anzeige
    weder Benutzerkonto noch Serververbindung.

## 7. Sprache und Einstellungen

### FR-I18N-001 – Deutsch und Englisch

- Priorität: Muss
- Beschreibung: Die Benutzeroberfläche ist auf Deutsch und Englisch verfügbar.
- Akzeptanz:
  - Beim ersten Start wird standardmäßig eine unterstützte Systemsprache
    verwendet; andernfalls Deutsch.
  - Die Sprache kann in den Einstellungen unabhängig von der Systemsprache
    gewählt werden.
  - Filterbezeichnungen, Zustände, Fehlermeldungen und Einwilligungstexte sind in
    beiden Sprachen vorhanden.
  - Eigennamen und Quellinhalte müssen nicht maschinell übersetzt werden.

## 8. Datenschutz und Diagnosedaten

### FR-PRIV-001 – Datenschutz und freiwillige Diagnostik

- Priorität: Muss
- Beschreibung: Version 1.0 überträgt keine Nutzungs- oder Fehlerdaten an den
  Entwickler. Eine spätere Telemetrie ist nur nach ausdrücklicher Einwilligung
  zulässig.
- Akzeptanz:
  - Version 1.0 enthält kein Analyse-, Werbe-, Tracking- oder automatisches
    Crash-Reporting-SDK und benötigt deshalb keine Scheineinwilligung bei der
    Ersteinrichtung.
  - Die Einstellungen erklären lokale Daten und bewusste Netzwerkzugriffe.
  - Ein lokaler Diagnosestatus wird nur nach ausdrücklicher Aktion kopiert und
    enthält keine Koordinaten, Suchbegriffe, Favoriten oder Gerätekennung.
  - Es gibt kein Werbetracking und kein personenbezogenes Nutzungsprofil.
  - Vor einer späteren Dienstauswahl werden Ereignisse, Aufbewahrung,
    Anonymisierung und Datenempfänger dokumentiert; die Einwilligung ist
    freiwillig, widerrufbar und nicht vorausgewählt.

## 9. Nicht-funktionale Anforderungen

### NFR-OFFLINE-001 – Offlinefähigkeit

- Priorität: Muss
- Beschreibung: Kernfunktionen arbeiten mit dem installierten Datensatz ohne
  aktive Internetverbindung.
- Akzeptanz:
  - Lokale Standortanzeige, lokale Suche, Filter, Details und Favoriten
    benötigen keine Serververbindung.
  - Onlineabhängige Teilfunktionen wie Updateprüfung oder externes Geocoding
    zeigen einen verständlichen Zustand und beeinträchtigen lokale Funktionen
    nicht.
  - Die tatsächliche Offlineverfügbarkeit von Kartenkacheln wird vor
    Implementierung anhand von Kartenanbieter und Lizenz festgelegt.

### NFR-PERF-001 – Reaktionsfähigkeit

- Priorität: Muss
- Beschreibung: Karteninteraktion und lokale Filterung wirken auf einem
  unterstützten Referenzgerät flüssig.
- Akzeptanz:
  - Ein Filterergebnis wird bei normaler Datenmenge nach einer Änderung
    innerhalb von 500 ms sichtbar.
  - Das Öffnen lokal vorhandener Standortdetails dauert höchstens 500 ms.
  - Messgerät, Datensatzgröße und Messverfahren werden vor dem Performance-Test
    dokumentiert.

### NFR-RELIABILITY-001 – Ausfallsicherer Datenwechsel

- Priorität: Muss
- Beschreibung: Ein fehlgeschlagenes Update darf den zuletzt funktionsfähigen
  Datensatz nicht beschädigen.
- Akzeptanz:
  - Download und Integritätsprüfung erfolgen vor der Aktivierung.
  - Bei einem Fehler bleibt der bisherige Datensatz aktiv.
  - Der Fehler wird verständlich angezeigt und ein erneuter Versuch ist
    möglich.

### NFR-PORT-001 – Android-Portierbarkeit

- Priorität: Soll
- Beschreibung: Die iPhone-Implementierung verwendet eine gemeinsame,
  plattformübergreifende Codebasis und isoliert notwendige
  iOS-Spezialfunktionen.
- Akzeptanz:
  - Fachlogik, Datenzugriff und Filterung enthalten keine unnötigen
    iOS-Abhängigkeiten.
  - Plattformspezifische Navigation, Berechtigungen und Speicherung liegen
    hinter dokumentierten Schnittstellen.
  - Eine Android-Portierung erfordert keine Neuentwicklung des Domänen- oder
    Datenzugriffslayers.

### NFR-ACCESS-001 – Grundlegende Zugänglichkeit

- Priorität: Soll
- Beschreibung: Die App folgt den grundlegenden
  Bedienungshilfen-Konventionen der Plattform.
- Akzeptanz:
  - Wesentliche Bedienelemente besitzen verständliche
    Screenreader-Beschriftungen.
  - Dynamische Schriftgrößen führen in den zentralen Abläufen nicht zum Verlust
    von Informationen oder Funktionen.
  - Information wird nicht ausschließlich über Farbe vermittelt.

### NFR-DATA-001 – Reproduzierbare Datenpipeline

- Priorität: Muss
- Beschreibung: Gleiche Eingabedaten, Regeln und Pipeline-Versionen erzeugen
  denselben fachlichen Ausgabedatensatz.
- Akzeptanz:
  - Eingabequellen und Pipeline-Version werden im Datensatzmanifest erfasst.
  - Manuelle Cluster- und Infrastrukturregeln sind versioniert.
  - Referenzfälle prüfen insbesondere betreiberübergreifende,
    zusammenzuführende und ausdrücklich zu trennende Standorte.

## 10. Ausdrücklich ausgeschlossene Anforderungen

Version 1.0 enthält keine Anforderungen für Live-Verfügbarkeit, Preise,
Ladevorgänge, Zahlungen, Community-Inhalte, Benutzerkonten, Cloud-Synchronisation
oder eine eigene Navigation. Entsprechende Vorbereitungen dürfen den
Funktionsumfang nicht faktisch vorziehen.

Die Routenplanung mit einfacher Reichweiten- und Ladeplanung ist nicht
Bestandteil von Version 1.0. Sie ist als Planungshilfe – nicht als
Turn-by-Turn-Navigation – für **Version 1.1** in
[`17_Route_Planning.md`](17_Route_Planning.md) mit den Anforderungen
`FR-ROUTE-*` und `NFR-ROUTE-*` gesondert spezifiziert.

## 11. Noch zu konkretisierende Werte

Vor Umsetzung beziehungsweise Abnahme der betroffenen Anforderung werden
festgelegt:

- Auswahlwerte und Standardwerte aller Filter,
- Leistungsgrenzen der dargestellten Leistungsklassen,
- Standardradius und auswählbare Radien für „in meiner Nähe“,
- Referenzgerät und endgültiges Performance-Messverfahren,
- Karten- und Geocodinganbieter einschließlich Offline- und Lizenzkonzept,
- älteste unterstützte iOS-Version,
- zulässige Telemetrieereignisse und technischer Anbieter.
