# Produktvision – Ladepark Explorer

Status: Verbindlicher Spezifikationskern

Stand: 26. Juli 2026

Zielrelease: Version 1.0

## 1. Kurzfassung

Der Ladepark Explorer ist eine mobile Planungs- und Analyseanwendung für
öffentlich zugängliche Ladeinfrastruktur in Deutschland. Im Mittelpunkt steht
nicht die einzelne Ladesäule, sondern die gemeinsame Betrachtung räumlich
benachbarter Ladeeinrichtungen mit ihrer gesamten Ladekapazität und nutzbaren
Infrastruktur.

Die App hilft Menschen, Standorte zu finden, an denen sie ihr Elektrofahrzeug
mit hoher Wahrscheinlichkeit schnell laden und die Ladezeit sinnvoll verbringen
können. Nutzende bestimmen selbst, was für ihre aktuelle Fahrt ein geeigneter
Ladepark ist, beispielsweise über Anzahl und Leistung der Ladepunkte sowie WC,
Automaten, Einkaufsmöglichkeiten, Café oder Restaurant.

Version 1.0 wird zunächst für das iPhone veröffentlicht. Sie arbeitet offline
mit einem lokal verfügbaren Datensatz und benötigt kein Benutzerkonto. Ein
dauerhaft betriebenes Anwendungsbackend ist nicht Bestandteil dieser Version.

## 2. Problem

Bestehende Lade-Apps betrachten häufig einzelne Ladesäulen, spontane
Verfügbarkeit, Tarife oder den Ladevorgang. Für die Reiseplanung sind jedoch
andere Fragen entscheidend:

- Gibt es am Zielstandort genügend Schnellladepunkte, sodass Alternativen
  vorhanden sind?
- Welche Ladeleistung kann dort grundsätzlich erreicht werden?
- Kann die Ladepause für WC, Verpflegung oder Einkäufe genutzt werden?
- Welche größeren Standorte befinden sich in einer unbekannten Region?
- Welche Betreiber und Steckertypen sind am Standort vertreten?

Eine einzelne Ladesäule ohne passende Infrastruktur ist selbst bei technischer
Verfügbarkeit nicht immer ein guter Pausenort. Umgekehrt kann ein gemeinsamer
Standort mit mehreren Betreibern für Reisende besonders attraktiv sein.

## 3. Produktvision

> Der Ladepark Explorer macht leistungsfähige Ladestandorte als
> zusammenhängende Reiseziele sichtbar und lässt Nutzende selbst bestimmen,
> welche Kombination aus Ladekapazität, Ladeleistung und Infrastruktur für ihre
> Fahrt geeignet ist.

Der Begriff „Ladepark“ ist dabei keine starre Größenklasse. Version 1.0 bildet
zunächst transparente dynamische Abstandsgruppen. Nutzende wählen deren
maximalen Gruppendurchmesser; der Standardwert beträgt 50 Meter. Erst ab
Version 1.5 können bestätigte Zusammengehörigkeitsregeln verifizierte
Ladeparkobjekte bilden.

## 4. Zielgruppen

### 4.1 E-Auto-Einsteiger

Menschen, die sich erstmals mit öffentlicher Ladeinfrastruktur beschäftigen,
benötigen eine verständliche Übersicht und klare Informationen. Die Anwendung
soll ihnen helfen, leistungsfähige Standorte zu erkennen und Unsicherheit bei
der Reiseplanung zu reduzieren.

### 4.2 Viel- und Langstreckenfahrer

Erfahrene Fahrer möchten in bekannten und unbekannten Regionen gezielt nach
Standorten mit hoher Kapazität, hoher Ladeleistung und geeigneter Infrastruktur
suchen. Sie brauchen leistungsfähige Filter, eine schnelle Kartenansicht und
die Übergabe des Ziels an eine Navigations-App.

Beide Gruppen sind für Version 1.0 gleichrangig. Die Oberfläche soll einen
sinnvollen Standard bieten, ohne die gezielte Recherche erfahrener Nutzender
einzuschränken.

## 5. Nutzenversprechen

Der Ladepark Explorer bietet:

- einen standortbezogenen Blick auf Ladeinfrastruktur statt einer isolierten
  Säulenansicht,
- frei wählbare Kriterien statt einer starren Ladeparkdefinition,
- betreiberübergreifende Zusammenfassung gemeinsam gelegener Ladepunkte,
- Informationen über Infrastruktur am Standort,
- lokale, schnelle Filterung und Nutzung ohne durchgehende Datenverbindung,
- direkten Wechsel von der Recherche zur Navigation.

Die App ergänzt Lade-, Roaming- und Navigationsanwendungen. Sie ersetzt sie
nicht.

## 6. Umfang von Version 1.0

### 6.1 Verbindlicher Funktionsumfang

Version 1.0 umfasst:

- einen mitgelieferten Basisdatensatz für Deutschland,
- monatlich angestrebte, versionierte Datenaktualisierungen,
- eine kartenbasierte Darstellung der Ladestandorte,
- Suche nach Ort, Adresse oder Ladepark,
- Anzeige des eigenen Standorts und Suche in der Nähe,
- frei kombinierbare Filter für Ladeangebot und Infrastruktur,
- konfigurierbare räumliche Gruppierung mit standardmäßig 50 Metern maximalem
  Gruppendurchmesser,
- Detailansichten für Ladestandorte,
- eigene Fotos und selbst erhobene Infrastrukturinformationen für zunächst
  ausgewählte Ladeparks,
- lokale Favoriten,
- Übergabe eines Standorts an Apple Maps oder Google Maps,
- deutsche und englische Benutzeroberfläche,
- optionale, einwilligungsbasierte anonyme Telemetrie und Fehlerberichte.

Alle öffentlich zugänglichen, aus den verwendeten Quellen importierbaren
Ladeeinrichtungen werden in der Datenbasis berücksichtigt. Reine AC-Standorte
werden standardmäßig ausgeblendet. Die Standardansicht zeigt Standorte mit
mindestens 20 Ladepunkten, die jeweils mindestens 100 kW leisten.

### 6.2 Nicht Bestandteil von Version 1.0

Folgende Funktionen sind ausdrücklich nicht Bestandteil:

- Live-Belegungsdaten,
- Ladetarife oder Preisvergleiche,
- Starten oder Bezahlen eines Ladevorgangs,
- eigene Routenplanung oder Turn-by-Turn-Navigation,
- Benutzerkonten,
- Bewertungen, Kommentare und Bilduploads,
- Moderation und Sperrung von Benutzern,
- Synchronisation von Favoriten zwischen Geräten,
- Android-Veröffentlichung,
- ein dauerhaft laufendes fachliches Anwendungsbackend.

Community-Funktionen sind für eine spätere Version vorgesehen und dürfen die
Auslieferung von Version 1.0 nicht blockieren.

## 7. Produktprinzipien

1. **Gemeinsame Betrachtung statt Einzelsäule:** Räumlich benachbarte
   Ladeeinrichtungen werden gemeinsam analysiert. Version 1.0 kennzeichnet
   diese Gruppierung ausdrücklich als Näherung.
2. **Nutzende definieren den geeigneten Park:** Größe und Ausstattung werden
   über Filter bestimmt, nicht über eine starre Produktdefinition.
3. **Schnellladen im Fokus:** DC-Schnellladeinfrastruktur prägt Darstellung und
   Standardfilter; AC-Daten bleiben für Vollständigkeit und spätere Nutzung
   erhalten.
4. **Offline zuerst:** Kernfunktionen bleiben mit dem lokalen Datensatz ohne
   Netzverbindung nutzbar.
5. **Vertrauen durch Herkunft:** Datenquelle, Aktualität und bekannte
   Unsicherheiten müssen nachvollziehbar sein.
6. **Datensparsamkeit:** Kein Benutzerkonto, kein Werbetracking und kein
   personenbezogenes Nutzungsprofil.
7. **Portierbare Umsetzung:** Der iPhone-Start darf eine zeitnahe
   Android-Portierung nicht unnötig erschweren.
8. **Reproduzierbare Datenpipeline:** Derselbe Eingabestand und dieselbe
   Pipeline-Version erzeugen fachlich dasselbe Ergebnis.

## 8. Daten- und Qualitätsverständnis

Das Ladesäulenregister der Bundesnetzagentur ist die primäre Quelle für
Ladeinfrastruktur. Angaben zu WC, Automaten, Einkaufsmöglichkeiten, Café und
Restaurant werden aus weiteren Quellen wie OpenStreetMap sowie durch
nachvollziehbare individuelle Recherche ergänzt.

Infrastrukturdaten können unvollständig oder veraltet sein. Die App darf keine
nicht belegten Eigenschaften als sicher darstellen. Soweit verfügbar werden
Quelle und Datenstand gespeichert. Verbesserungen durch Community-Rückmeldungen
sind erst für eine spätere Version vorgesehen.

Version 1.0 verwendet ausschließlich BNetzA-Koordinaten zur dynamischen
Gruppierung. Der maximale Gruppendurchmesser ist konfigurierbar; 50 Meter sind
der Standardwert. Zufahrten, Straßen, Betreiber oder Karten anderer Anbieter
fließen nicht automatisch ein. Ab Version 1.5 können freigegebene
Nutzerfeedback- und Betreiberregeln bestätigte Parks bilden.

## 9. Plattform und Bedienung

Version 1.0 richtet sich vorrangig an Smartphones und wird zuerst für das
iPhone veröffentlicht. Die technische Basis soll eine spätere
Android-Veröffentlichung mit möglichst wenig plattformspezifischer
Neuentwicklung ermöglichen.

Deutsch und Englisch sind ab Version 1.0 wählbar. Es gibt zunächst keine
verbindlich festgelegte minimale Betriebssystemversion. Die älteste
unterstützte iOS-Version wird vor Implementierungsbeginn anhand von
Framework-Kompatibilität, Sicherheitsupdates und Entwicklungsaufwand
entschieden.

Es gelten die üblichen Plattformkonventionen für dynamische Schriftgrößen,
Kontrast, Screenreader-Beschriftungen und ausreichend große Bedienziele. Eine
weitergehende formale Barrierefreiheitszertifizierung ist für Version 1.0 nicht
vorgesehen.

## 10. Erfolgskriterien

Version 1.0 ist produktseitig fertig, wenn:

- die App im Apple App Store veröffentlicht ist,
- die spezifizierten Kernabläufe stabil nutzbar sind,
- die Deutschland-Daten reproduzierbar erzeugt und aktualisiert werden können,
- Nutzende geeignete Standorte über Karte, Suche und Filter finden und an eine
  Navigations-App übergeben können,
- die App ohne Telemetrieeinwilligung vollständig funktioniert.

Der Markterfolg wird zunächst anhand von App-Store-Installationen, freiwillig
gemeldeter Nutzung und qualitativem Nutzerfeedback beurteilt. Konkrete Zielwerte
werden nach einem ersten öffentlichen Release festgelegt, wenn eine belastbare
Ausgangsbasis vorliegt.

## 11. Annahmen und Risiken

### Annahmen

- Die verwendeten Datenquellen dürfen für den vorgesehenen Zweck verarbeitet
  und veröffentlicht werden.
- Monatliche Datenaktualisierungen sind für den statischen Funktionsumfang
  ausreichend.
- Ein lokaler Deutschland-Datensatz ist auf typischen Smartphones hinsichtlich
  Größe und Abfrageleistung praktikabel.
- Eine gemeinsame Flutter-Codebasis erleichtert die spätere
  Android-Portierung.

### Wesentliche Risiken

- Quellfelder und Lizenzbedingungen können sich ändern.
- Infrastrukturmerkmale sind teilweise unvollständig oder veraltet.
- Eine reine Abstandsgruppe kann getrennte Zufahrten oder Straßenseiten
  fälschlich gemeinsam darstellen.
- Die reale Ladeleistung hängt von Fahrzeug, Belegung, Temperatur und
  Lastmanagement ab; die App zeigt nur technische Standortdaten.
- Zu alte unterstützte Betriebssystemversionen können Entwicklung und
  Bibliotheksauswahl unverhältnismäßig erschweren.
- Optionale Telemetrie liefert möglicherweise keine repräsentativen
  Nutzungszahlen.

## 12. Offene Produktentscheidungen

Vor Beginn der jeweils betroffenen Implementierung sind zu entscheiden:

- älteste unterstützte iOS-Version,
- konkrete Darstellungsform bei unbekannter oder unsicherer Infrastruktur,
- Auswahl und Lizenzprüfung zusätzlicher Infrastruktur- und Geocodingquellen,
- Telemetrieanbieter und genaue Liste zulässiger Ereignisse,
- messbare Zielwerte nach dem ersten öffentlichen Release.
