# ADR-0012 – Getrennter redaktioneller Ladepark-Informationsbestand

Status: Angenommen

Datum: 25. August 2026

## Kontext

Version 1.0 soll für zunächst wenige ausgewählte Ladeparks selbst erhobene
Standortinformationen und eigene Fotos anzeigen. Erfasst werden insbesondere
Restaurant, Shop, Kaffeeautomat, Snackautomat und Toilette. Die App besitzt
kein fachliches Backend und soll keine fremden Karten-, Bewertungs- oder
Bilddatenbanken übernehmen.

Die dynamische `proximity_group` ist datensatz- und durchmesserabhängig. Eine
redaktionelle Information darf deshalb nicht ausschließlich an deren instabile
Gruppen-ID gebunden werden.

## Entscheidung

- Redaktionelle Informationen werden außerhalb der App mit einem
  projektlokalen, versionierten Pflege- und Buildprozess erfasst und geprüft.
- Eigene Vor-Ort-Feststellungen und eigene Fotos bilden die anfängliche
  Quelle. Fremde Kartendienste, Fotos, Beschreibungstexte und Datenbanken
  werden nicht kopiert.
- Der Build erzeugt einen getrennten, read-only
  `park_info.sqlite`-Informationsbestand. Er wird nicht mit dem
  BNetzA-Ladebestand oder einem späteren OSM-Artefakt verschmolzen.
- Fotos werden nicht als SQLite-BLOB gespeichert. Die Datenbank enthält
  Metadaten und relative Referenzen auf für die App optimierte Bilddateien.
  Unveränderte Originale bleiben außerhalb des App-Artefakts im
  Redaktionsbestand.
- Eine Zuordnung verwendet mindestens eine stabile `station_id` und kann
  mehrere Stationen umfassen. Die App löst sie zur aktuell gewählten
  Abstandsgruppe auf.
- Jedes Merkmal unterscheidet `vorhanden`, `nicht vorhanden` und `unbekannt`
  und speichert Erhebungsdatum, Erhebungsart und Reviewstatus.
- Jedes veröffentlichte Foto besitzt mindestens eine stabile ID, Urheber,
  Aufnahmedatum, Dateiprüfsumme und dokumentierte Freigabeprüfung. Personen
  und Kennzeichen werden vor der Veröffentlichung vermieden oder unkenntlich
  gemacht.
- Der Informationsbestand und die optimierten Bilder werden zunächst beim
  App-Build als git-ignorierte, versionierte Assets eingebunden. Ein späterer
  statischer Download verwendet denselben Schema- und Manifestvertrag.
- Die App enthält in Version 1.0 keine Eingabe-, Upload- oder
  Community-Funktion für diese Inhalte.

## Gründe

- Eigene Erhebung reduziert Abhängigkeiten von Nutzungsbedingungen fremder
  Plattformen.
- Die physische Trennung erhält Herkunft, Lizenzstatus und Aktualisierbarkeit
  jedes Datenbestands.
- Stabile Stationsreferenzen überstehen eine Änderung des gewählten
  Gruppendurchmessers.
- Separate Bilddateien lassen sich besser verkleinern, cachen und später
  inkrementell verteilen als SQLite-BLOBs.

## Folgen

Positiv:

- ausgewählte Ladeparks können ohne Server reichhaltiger beschrieben werden,
- kleine Anfangsbestände erhöhen die Größe der App nur kontrolliert,
- eine spätere statische oder servergestützte Distribution bleibt möglich,
- unbekannte und nicht erhobene Informationen bleiben erkennbar.

Negativ:

- Erhebung, Bildbereinigung und Review verursachen manuelle Arbeit,
- Angaben altern und benötigen ein sichtbares Erhebungsdatum,
- Build, Integritätsprüfung und App-Zugriff benötigen einen zweiten
  Datensatzvertrag,
- rechtliche Freigabeprüfungen bleiben trotz eigener Aufnahmen erforderlich.
