# ADR-0003 – Lizenzsichere Trennung von BNetzA- und OSM-Daten

Status: Angenommen

Datum: 26. Juli 2026

## Kontext

Die Bundesnetzagentur veröffentlicht Registerdaten unter CC BY 4.0.
OpenStreetMap-Daten stehen unter ODbL 1.0. ODbL kann bei einer öffentlich
verwendeten Derivative Database Share-Alike- und Bereitstellungspflichten
auslösen.

Der Projektinhaber ist Privatperson. Eine umfangreiche individuelle
Lizenzbegutachtung ist wirtschaftlich nicht tragbar. Die Veröffentlichung darf
daher nicht von einer aggressiven oder ungeklärten Auslegung der
Collective-/Derivative-Database-Grenze abhängen.

## Entscheidung

Version 1.0 trennt:

- BNetzA-basierte Ladeinfrastruktur und ohne OSM gebildete Ladeparks in einem
  CC-BY-konform attribuierten Stammdatenartefakt,
- OSM-basierte Infrastrukturmerkmale in einem separaten ODbL-Artefakt,
- lokale Benutzerdaten in einem getrennten App-Speicher.

Das OSM-Artefakt wird mit Attribution und Lizenzhinweis unter
ODbL-kompatiblen Bedingungen öffentlich angeboten. Herkunft und
Objektreferenzen bleiben erhalten.

OSM-Parkplatz-, Straßen- und Zufahrtsdaten steuern in Version 1.0 nicht
automatisch die persistente Bildung oder Identität eines Ladeparks. Version 1.0
bildet ausschließlich dynamische Abstandsgruppen aus BNetzA-Koordinaten gemäß
ADR-0004.

Der öffentliche Nominatim-Dienst und öffentliche OSM-Rastertile-Dienste werden
nicht als Produktions- beziehungsweise Offlineinfrastruktur eingeplant.

## Gründe

- CC BY 4.0 und ODbL können jeweils nach klaren Standardregeln erfüllt werden.
- Physische und fachliche Trennung macht Attribution, Weitergabe und
  Aktualisierung nachvollziehbar.
- Bewusstes Erfüllen von ODbL für den OSM-Teil ist robuster als der Versuch,
  möglichst wenige Pflichten anzunehmen.
- Der Verzicht auf OSM-basiertes Clustering reduziert die rechtlich
  schwierigste Verschmelzung.
- Die App kann beide Datenbestände weiterhin gemeinsam darstellen und filtern.

## Folgen

Positiv:

- vergleichsweise klare Lizenzzuordnung,
- kommerzielle App-Nutzung bleibt möglich,
- kein Offenlegungszwang für App-Code oder BNetzA-basierten Algorithmus aus
  ODbL allein,
- OSM-Pflichten werden transparent und überprüfbar erfüllt,
- eine Funktion kann entfernt werden, ohne den anderen Datenbestand zu ändern.

Negativ:

- zwei Datensatzartefakte und Updatepfade,
- keine automatische Nutzung von OSM-Parkplatzgeometrie für die
  Version-1-Abstandsgruppierung,
- Infrastrukturzusammenführung in der App wird komplexer,
- OSM-Ableitungsartefakt und Extraktionsmethode müssen öffentlich bereitgestellt
  werden,
- manuelle Clusterreviews werden wichtiger.

## Änderungsbedingung

Eine Verschmelzung der Artefakte oder OSM-gestütztes persistentes Clustering
benötigt ein neues oder ersetzendes ADR, eine aktualisierte Lizenzbewertung und
einen eindeutigen Plan zur Erfüllung aller ODbL-Pflichten. Bleibt die
rechtliche Einordnung unklar, wird die Änderung nicht umgesetzt.
