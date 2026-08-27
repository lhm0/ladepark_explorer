# ADR-0013 – Lokale Standortsuche und eingehende Koordinaten

Status: Angenommen

Datum: 25. August 2026

## Kontext

M6 benötigt eine Suche nach Ort, Adresse und Ladepark, eine
Umkreissuche um den eigenen Standort und einen Weg, Koordinaten aus einem
anderen Kontext an den Ladepark Explorer zu übergeben.

Apple und Google dokumentieren URL-Formate, mit denen ihre eigenen
Kartenanwendungen geöffnet werden. Es existiert jedoch kein gemeinsamer
Rückübergabestandard, durch den beide Karten-Apps eine Koordinate unmittelbar
an eine beliebige installierte Dritt-App senden. Eine Aufnahme in das
iOS-Teilen-Menü würde eine gesonderte Share Extension erfordern. Verkürzte
Google-Maps-Links lassen sich erst nach einer Online-Weiterleitung auswerten.

## Entscheidung

- Orts- und Adressangaben werden mit `MKLocalSearch` auf eine Koordinate
  aufgelöst. Die UI kennzeichnet diesen Schritt ausdrücklich als online.
- Ausgehend von dieser Koordinate durchsucht die App den lokalen Ladebestand
  mit den aktiven Filtern in wachsenden Radien von 5 bis 200 Kilometern. Die
  Karte bleibt auf den gesuchten Ort zentriert und wählt einen Maßstab, in dem
  mindestens der nächste passende Ladepark sichtbar ist.
- Ist die Online-Ortsauflösung nicht verfügbar, bleibt die bisherige lokale
  FTS-Suche nach bereits im Ladebestand vorhandenen Orts-, Adress- und
  Ladeparknamen als Offline-Fallback erhalten.
- Direkte Koordinaten sowie nicht verkürzte Apple- und Google-Maps-URLs mit
  sichtbaren Koordinaten können in dasselbe Suchfeld eingefügt werden.
- Die App registriert den Link
  `ladeparkexplorer://location?lat=<latitude>&lon=<longitude>` und verarbeitet
  ihn bei Kalt- und Warmstart.
- Eine iOS Share Extension und die Online-Auflösung verkürzter Links gehören
  nicht zu M6. Sie können später ergänzt werden, ohne den internen
  Koordinatenvertrag zu ändern.
- Der eigene Standort wird erst nach einer Nutzeraktion und ausschließlich mit
  `When In Use`-Berechtigung angefordert. Er verlässt für die Umkreissuche das
  Gerät nicht.
- Die auswählbaren Radien sind 5, 10, 25, 50 und 100 Kilometer. Nach einer
  Bounding-Box-Vorauswahl berechnet die App die Haversine-Distanz lokal.

## Folgen

Die Ladeparksuche nach einer ermittelten Koordinate und die Umkreissuche bleiben
lokal; nur die Auflösung eines freien Ortsnamens durch Apple Maps benötigt eine
Netzverbindung. Direkte Links sind automatisierbar und anbieterunabhängig. Ein unmittelbarer Aufruf aus dem
Teilen-Menü von Apple Maps oder Google Maps ist ohne die spätere
Share Extension nicht zugesagt.

Referenzen:

- [Apple Map Links](https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/MapLinks/MapLinks.html)
- [Google Maps URLs](https://developers.google.com/maps/documentation/urls/get-started)
- [Apple App Extensions](https://developer.apple.com/app-extensions/)
