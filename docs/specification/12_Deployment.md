# Deployment

Status: Basisdatensatz-Packaging und M11-Updateverteilung implementiert

Version 1 nutzt statische, unveränderliche Datensatzartefakte. M11 verwendet
öffentliche GitHub Releases; der Zugriff ist hinter Manifest- und HTTP-Vertrag
gekapselt und kann später auf Cloudflare R2 umgestellt werden.

Der mitgelieferte Basisdatensatz wird gemäß ADR-0010 vor dem App-Build als
git-ignoriertes Asset vorbereitet:

```text
./tooling/prepare_app_dataset.sh
```

Ohne Argument verwendet das Skript
`data/output/charging-de-2026.07.0.sqlite3`. Ein anderer Schema-v2-Bestand kann
als erster Parameter übergeben werden. Das Skript prüft Schemaversion,
Datensatzversion und Region und erzeugt atomar
`app/assets/generated/charging-de.sqlite3`.

Auf iOS öffnet die App den Bestand direkt und read-only aus dem App-Bundle.
Fehlt das generierte Asset, fällt ein Entwicklungs- oder CI-Build auf die
kleine Contract-Fixture zurück. Der lokale M4-Simulator-Build mit dem
Deutschlandbestand enthält eine 386-MB-SQLite-Datei und ist insgesamt rund
537 MB groß. Downloadgröße, App-Store-Verarbeitung und Gerätespeicher sind vor
einem Release gesondert zu messen.

Gemäß ADR-0012 ist ein zweiter Vorbereitungsschritt implementiert:

```text
./tooling/prepare_park_info_dataset.sh
```

Er validiert `editorial/park_info/park-info.json` einschließlich Reviewstatus,
Stationsreferenzen und Bildprüfsummen gegen den vorbereiteten Ladebestand und
erzeugt git-ignoriert `app/assets/generated/park-info.sqlite3` sowie
`app/assets/generated/park-info-media/`. Fehlt der vollständige Ladebestand,
wird für Entwicklung nur gegen das Contract-Fixture geprüft. Ein App-Build
ohne Produktbestand verwendet ein kleines redaktionelles Contract-Fixture.
Originalfotos gehören weder in das App-Bundle noch in das Repository. Der
redaktionelle Bestand bleibt vom monatlichen BNetzA-Update getrennt.

## Statische Updates

Ein Releasepaket wird reproduzierbar erzeugt mit:

```text
cd importer
uv run ladepark-importer build-release \
  ../data/output/charging-de-2026.07.0.sqlite3 \
  --output ../data/output/release-2026.07.0 \
  --repository lhm0/ladepark_explorer \
  --git-commit <commit>
```

Es enthält `manifest.json` und ein deterministisch gzip-komprimiertes
SQLite-Artefakt. Die App prüft beim Start standardmäßig nur das Manifest. Eine
verfügbare Version wird mit Datenstand und Größe in den Einstellungen gezeigt;
erst nach Bestätigung folgen Download, doppelte SHA-256-Prüfung,
SQLite-Integritäts- und Metadatenprüfung sowie atomare Aktivierung gemäß
ADR-0017. Der vorherige Downloadbestand bleibt als Rollback erhalten.

Der erste Produktbestand ist veröffentlicht als
[`dataset-2026.07.0`](https://github.com/lhm0/ladepark_explorer/releases/tag/dataset-2026.07.0).
Die von der App verwendete stabile Manifestadresse lautet
`https://github.com/lhm0/ladepark_explorer/releases/latest/download/manifest.json`.
Das komprimierte Artefakt besitzt 182.274.446 Byte und die SHA-256-Prüfsumme
`46300b02b4e6230ae1e119e9ec5d7ffcb04ff1064de7e8a193583c3a1fef4b8d`.
Manifest und Archiv wurden nach der Veröffentlichung am 28. August 2026 über
ihre öffentlichen URLs vollständig zurückgeladen und verifiziert.
