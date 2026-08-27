# ADR-0004 – Dynamische Abstandsgruppen und später bestätigte Ladeparks

Status: Angenommen

Datum: 26. Juli 2026

## Kontext

Aus Koordinaten und Adressen allein lässt sich nicht zuverlässig erkennen, ob
Ladeeinrichtungen praktisch denselben Parkplatz oder dieselbe Zufahrt nutzen.
Google Maps und Apple Karten dürfen nicht systematisch zur Erstellung einer
eigenen Standortdatenbank ausgewertet werden. Eine OSM-gestützte persistente
Parkbildung würde zusätzliche ODbL-Abgrenzungsfragen erzeugen.

Version 1.0 soll dennoch benachbarte Ladeeinrichtungen sinnvoll
zusammenhängend darstellen. Ab Version 1.5 können originäre Rückmeldungen von
Nutzern und ausdrückliche Betreiberbestätigungen eine eigene, zunehmend bessere
Zusammengehörigkeitsdatenbank bilden.

## Entscheidung

### Version 1.0

- Alle verfügbaren öffentlich zugänglichen BNetzA-Ladeeinrichtungen werden
  importiert.
- Die App zeigt dynamische `proximity_group`-Objekte, keine als objektiv
  bestätigt bezeichneten Ladeparks.
- Gruppen basieren ausschließlich auf BNetzA-Koordinaten und einem
  konfigurierbaren maximalen Gruppendurchmesser.
- Standardwert ist 50 Meter.
- Vorgesehene Werte sind 25, 50, 100, 200 und 300 Meter.
- Die Oberfläche erklärt, dass es sich um eine räumliche Näherung handelt, die
  Zufahrten, Straßen und Grundstücksgrenzen nicht berücksichtigt.
- Favoriten speichern eine stabile Anker-Station, nicht ausschließlich eine
  dynamische Gruppen-ID.
- Google Maps und Apple Karten werden nicht zur Datengewinnung oder
  Gruppenentscheidung verwendet.
- Betreiberzuordnungen und bestätigte Zusammengehörigkeit werden nur bei
  ausdrücklicher Betreiberbestätigung übernommen.
- Betreiberwebseiten dürfen Anlass für eine Bestätigungsanfrage sein, sind aber
  nicht alleinige Evidenz für eine Merge-/Splitregel.
- Offizielle Betreiberlinks dürfen durch manuellen Vergleich der sichtbaren
  Adresse mit der BNetzA-Adresse einer Station zugeordnet werden.
- Gespeichert bleibt die BNetzA-Adresse; die Webseitenadresse wird nicht als
  eigener Datenwert übernommen.
- Mehrdeutige oder abweichende Adressen benötigen Betreiberbestätigung, bevor
  ein standortspezifischer Link produktiv angezeigt wird.

### Gruppierungsalgorithmus

Der eingestellte Wert ist der maximale Durchmesser einer Gruppe, nicht nur der
maximale Abstand zwischen benachbarten Kettengliedern.

1. Jede Ladeeinrichtung beginnt als eigene Gruppe.
2. Kandidatengruppen werden in aufsteigender Minimaldistanz betrachtet.
3. Zwei Gruppen werden nur vereinigt, wenn jede paarweise Distanz der
   vereinigten Gruppe höchstens dem eingestellten Durchmesser entspricht.
4. Bei gleichen Distanzen entscheidet die lexikografische Reihenfolge der
   stabilen Stations-IDs.
5. Der Vorgang endet, wenn keine zulässige Vereinigung verbleibt.

Damit können transitive Ketten den eingestellten Maximaldurchmesser nicht
überschreiten.

Eine Gruppen-ID ist nur innerhalb von Datensatzversion und
Durchmessereinstellung reproduzierbar:

```text
proximity_group_id =
  UUIDv5(namespace_proximity_group,
         dataset_version + ":" + diameter_m + ":" + sorted_station_ids)
```

Sie ist keine langfristige fachliche Identität.

### Version 1.5

- Eine eigene Feedbackdatenbank sammelt Merge-/Split-Rückmeldungen.
- Nutzende beantworten, ob Ladeeinrichtungen praktisch zusammengehören.
- Antworten werden aggregiert und gegen Mehrfachabstimmungen, Manipulation und
  widersprüchliche Meldungen geschützt.
- Einzelne Rückmeldungen verändern den produktiven Datensatz nicht direkt.
- Übernahmeschwellen, Vertrauenswerte und gegebenenfalls administrativer Review
  werden vor Implementierung spezifiziert.
- Freigegebene Regeln werden als versionierte `verified_park`-Daten
  veröffentlicht.
- Für nicht bestätigte Standorte bleibt der Abstandsalgorithmus der Fallback.

Auswertungsreihenfolge ab Version 1.5:

```text
Bestätigte Parkregel vorhanden?
  Ja   -> verified_park verwenden
  Nein -> proximity_group mit gewähltem Maximaldurchmesser
```

## Folgen

Positiv:

- Version 1.0 verwendet nur klar lizenzierte BNetzA-Eingaben.
- Die Gruppierung ist transparent, deterministisch und konfigurierbar.
- Nutzende können die gewünschte räumliche Granularität selbst wählen.
- Favoriten bleiben über Anker-Stationen stabil.
- Eine eigene bestätigte Datenbasis kann organisch wachsen.

Negativ:

- Abstandsgruppen können getrennte Zufahrten oder Straßenseiten
  fälschlicherweise zusammenfassen.
- Dasselbe Gebiet kann je nach Einstellung unterschiedlich gruppiert sein.
- Dynamische Gruppen sind nicht als langfristige Referenzen geeignet.
- Infrastruktur- und Navigationszuordnung muss Gruppenänderungen berücksichtigen.
- Community-Daten benötigen ab Version 1.5 Backend, Teilnahmebedingungen,
  Missbrauchsschutz und Moderation.

## Nicht zulässige Interpretation

Eine `proximity_group` darf in UI und Dokumentation nicht als verifiziert
zusammengehöriger Ladepark dargestellt werden. Der Produktname „Ladepark
Explorer“ bleibt bestehen; die konkrete Version-1-Gruppierung wird jedoch als
räumliche Näherung gekennzeichnet.
