# Redaktioneller Ladeparkbestand

Dieser Ordner ist die Pflegequelle für `FR-DATA-004`. Die fachlichen Angaben
stehen in `park-info.json`; veröffentlichungsfertige eigene Bilder werden lokal
unter `media/` abgelegt. Originalfotos und unbearbeitete Aufnahmen gehören
nicht in dieses Repository.

Der lokal git-ignorierte Ordner `../../park-images/` kann als Arbeitsablage für
Originale dienen. Er wird weder vom Build gelesen noch in die App übernommen.

## Pflegeablauf

1. Die stabilen `station_id`-Werte des Standorts aus dem Ladebestand ermitteln.
2. Einen Eintrag aus `park-info.example.json` nach `park-info.json` übernehmen.
3. Alle fünf Merkmale explizit als `present`, `absent` oder `unknown` erfassen.
4. Nur selbst erhobene Angaben verwenden und `observed_on` eintragen.
5. Bilder außerhalb des Projekts bearbeiten: Personen und Kennzeichen entfernen,
   Ausrichtung korrigieren und auf eine app-taugliche Größe reduzieren.
6. Das fertige Bild nach `media/` kopieren und die SHA-256-Prüfsumme eintragen
   (`shasum -a 256 editorial/park_info/media/DATEI`).
7. Rechte- und Datenschutzprüfung mit beiden Prüfzeitpunkten dokumentieren und
   den Park erst danach auf `review_status: approved` setzen.
8. Aus dem Repository-Hauptverzeichnis ausführen:

   ```text
   ./tooling/prepare_park_info_dataset.sh
   ```

Der Build bricht bei unbekannten Stations-IDs, unvollständigen Merkmalen,
nicht freigegebenen Einträgen, fehlenden Bildern oder falschen Prüfsummen ab.
Er veröffentlicht anschließend `app/assets/generated/park-info.sqlite3` und
die geprüften Bilder unter `app/assets/generated/park-info-media/`.

Die JSON-Schlüssel und zulässigen Werte sind im Beispiel dokumentiert. IDs
werden nach der ersten Veröffentlichung nicht wiederverwendet oder geändert.
