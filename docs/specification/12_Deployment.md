# Deployment

Status: Basisdatensatz-Packaging implementiert; Updateverteilung noch offen

Version 1 nutzt statische, unveränderliche Datensatzartefakte. Cloudflare R2 ist
die bevorzugte, aber noch zu bestätigende Distribution. Build, Signierung,
Veröffentlichung und Rollback heruntergeladener Updates sind noch
auszuarbeiten.

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
Originalfotos gehören weder in das App-Bundle noch in das Repository. Eine
gemeinsame Updateverteilung folgt erst mit M11.
