// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Ladepark Explorer';

  @override
  String get filters => 'Filter';

  @override
  String get search => 'Suchen';

  @override
  String get locationSearch => 'Ort oder Koordinate suchen';

  @override
  String get locationSearchHint => 'Ort, Adresse oder Ladepark';

  @override
  String get coordinateSearchHint =>
      'Ortsnamen werden mit Apple Maps online aufgelöst. Koordinaten und direkte Maps-URLs funktionieren ebenfalls.';

  @override
  String get noSearchResults =>
      'Der Ort oder ein passender Ladepark in seiner Umgebung wurde nicht gefunden.';

  @override
  String get searchFailed => 'Die lokale Suche konnte nicht ausgeführt werden.';

  @override
  String searchResultChargingPoints(int count) {
    return '$count Ladepunkte';
  }

  @override
  String get nearbySearch => 'Ladeparks in meiner Nähe';

  @override
  String get nearbyRadiusExplanation =>
      'In welchem Umkreis sollen Ladeparks angezeigt werden?';

  @override
  String get distanceFromCurrentLocation => 'Entfernung zum aktuellen Standort';

  @override
  String get noDistanceLimit => 'Nicht begrenzen';

  @override
  String activeNearbyRadius(int radius) {
    return 'Umkreis $radius km';
  }

  @override
  String get alwaysOpenOnly => 'Nur durchgehend zugängliche Ladeangebote';

  @override
  String get alwaysOpenOnlyExplanation =>
      'Die erforderlichen Ladepunkte müssen laut Datenquelle rund um die Uhr zugänglich sein.';

  @override
  String radiusKm(int radius) {
    return '$radius km';
  }

  @override
  String get locationPermissionDenied =>
      'Der Standortzugriff ist nicht erlaubt. Du kannst ihn in den iOS-Einstellungen aktivieren.';

  @override
  String get locationUnavailable =>
      'Der aktuelle Standort konnte nicht bestimmt werden.';

  @override
  String get groupDiameter => 'Maximaler Gruppendurchmesser';

  @override
  String get minimumChargingPoints => 'Erforderliche Ladepunkte';

  @override
  String get minimumPower => 'Mindestleistung je Ladepunkt';

  @override
  String minimumChargingOffer(int count, int power) {
    return 'Mindestens $count Ladepunkte mit jeweils mindestens $power kW';
  }

  @override
  String get resetFilters => 'Standard herstellen';

  @override
  String get cancelFilterChanges => 'Abbruch';

  @override
  String get favoritesOnly => 'Nur Favoriten anzeigen';

  @override
  String get infrastructureFilter => 'Ausstattung';

  @override
  String get infrastructureFilterExplanation =>
      'Alle ausgewählten Merkmale müssen als vorhanden geprüft sein. Fehlende Angaben gelten als unbekannt.';

  @override
  String get anyValue => 'Alle';

  @override
  String get filterSearch => 'Auswahl durchsuchen';

  @override
  String get operatorCountExplanation =>
      'Zahl in Klammern: Ladepunkte im Datensatz';

  @override
  String get clearSelection => 'Auswahl löschen';

  @override
  String get done => 'Fertig';

  @override
  String get mapSemantics => 'Karte mit Ladeparks';

  @override
  String get mapUnavailable => 'Die Apple-Karte ist nur auf iOS verfügbar.';

  @override
  String get myLocation => 'Mein Standort';

  @override
  String get germanyOverview => 'Deutschland anzeigen';

  @override
  String get loadingParks => 'Ladeparks werden geladen …';

  @override
  String visibleParks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ladeparks',
      one: 'Ein Ladepark',
      zero: 'Keine Ladeparks',
    );
    return '$_temp0';
  }

  @override
  String visibleParksLimitReached(int count) {
    return '$count+ Ladeparks';
  }

  @override
  String get datasetMissing => 'Der Ladepark-Datensatz fehlt.';

  @override
  String get datasetUnsupported =>
      'Der Ladepark-Datensatz hat eine nicht unterstützte Version.';

  @override
  String get invalidFilterQuery =>
      'Die gewählten Filter konnten nicht verarbeitet werden.';

  @override
  String get chargingParksLoadFailed =>
      'Die Ladeparks konnten nicht geladen werden.';

  @override
  String get detailsUnavailable => 'Details konnten nicht geladen werden.';

  @override
  String get chargingParkDetails => 'Ladeparkdetails';

  @override
  String stationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Stationen',
      one: 'Eine Station',
    );
    return '$_temp0';
  }

  @override
  String evseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ladepunkte',
      one: 'Ein Ladepunkt',
    );
    return '$_temp0';
  }

  @override
  String get operators => 'Betreiber';

  @override
  String get chargingPointsByOperator =>
      'Ladepunkte nach Betreiber und Leistung';

  @override
  String get power => 'Leistung';

  @override
  String get connectors => 'Anschlüsse';

  @override
  String get unknown => 'Unbekannt';

  @override
  String get openingHours => 'Öffnungszeiten';

  @override
  String get powerClasses => 'Leistungsklassen';

  @override
  String maximumPower(double power) {
    return 'Maximal $power kW';
  }

  @override
  String get maximumPowerUnknown => 'Maximale Leistung unbekannt';

  @override
  String proximityApproximation(int diameter) {
    return 'Räumliche Näherung; tatsächlicher Gruppendurchmesser: $diameter m. Zufahrten, Straßen und Grundstücksgrenzen sind nicht geprüft.';
  }

  @override
  String datasetVersion(String version) {
    return 'Datensatz $version';
  }

  @override
  String dataSource(String source, String version) {
    return 'Quelle: $source, Stand $version';
  }

  @override
  String datasetCreatedAt(String createdAt) {
    return 'Datensatz erstellt: $createdAt';
  }

  @override
  String get navigationUnavailable =>
      'Die Navigations-App konnte nicht geöffnet werden.';

  @override
  String get openNavigation => 'Route starten';

  @override
  String get settings => 'Einstellungen';

  @override
  String get settingsUnavailable =>
      'Die Einstellungen konnten nicht geladen werden.';

  @override
  String get language => 'Sprache';

  @override
  String get systemLanguage => 'Systemsprache';

  @override
  String get german => 'Deutsch';

  @override
  String get english => 'Englisch';

  @override
  String get navigationApp => 'Navigations-App';

  @override
  String get askEveryTime => 'Jedes Mal fragen';

  @override
  String get notInstalled => 'Nicht installiert';

  @override
  String get googleMapsUnavailable => 'Google Maps ist nicht verfügbar';

  @override
  String get googleMapsFallbackExplanation =>
      'Google Maps ist nicht installiert. Soll die Route stattdessen in Apple Maps geöffnet werden?';

  @override
  String get useAppleMaps => 'Apple Maps verwenden';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get favorites => 'Favoriten';

  @override
  String get noFavorites => 'Noch keine Ladeparks als Favoriten gespeichert.';

  @override
  String get addFavorite => 'Als Favorit speichern';

  @override
  String get removeFavorite => 'Favorit entfernen';

  @override
  String get favoriteUnavailable => 'Im aktuellen Datensatz nicht verfügbar';

  @override
  String get onSiteInformation => 'Vor Ort geprüft';

  @override
  String observedOn(String date) {
    return 'Erhoben am $date';
  }

  @override
  String photoCredit(String author, String date) {
    return 'Foto: $author, aufgenommen am $date';
  }

  @override
  String get restaurant => 'Restaurant';

  @override
  String get shop => 'Shop';

  @override
  String get coffeeMachine => 'Kaffeeautomat';

  @override
  String get snackMachine => 'Snackautomat';

  @override
  String get toilet => 'Toilette';

  @override
  String get amenityPresent => 'Vorhanden';

  @override
  String get amenityAbsent => 'Nicht vorhanden';
}
