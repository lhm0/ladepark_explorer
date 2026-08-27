// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Charging Park Explorer';

  @override
  String get filters => 'Filters';

  @override
  String get search => 'Search';

  @override
  String get locationSearch => 'Search place or coordinate';

  @override
  String get locationSearchHint => 'Place, address, or charging park';

  @override
  String get coordinateSearchHint =>
      'Place names are resolved online with Apple Maps. Coordinates and direct Maps URLs also work.';

  @override
  String get noSearchResults =>
      'The place or a matching charging park nearby could not be found.';

  @override
  String get searchFailed => 'The local search could not be completed.';

  @override
  String searchResultChargingPoints(int count) {
    return '$count charging points';
  }

  @override
  String get nearbySearch => 'Charging parks near me';

  @override
  String get nearbyRadiusExplanation =>
      'Within which radius should charging parks be shown?';

  @override
  String get distanceFromCurrentLocation => 'Distance from current location';

  @override
  String get noDistanceLimit => 'No limit';

  @override
  String activeNearbyRadius(int radius) {
    return 'Within $radius km';
  }

  @override
  String get alwaysOpenOnly => 'Only continuously accessible charging';

  @override
  String get alwaysOpenOnlyExplanation =>
      'The required charging points must be accessible around the clock according to the data source.';

  @override
  String radiusKm(int radius) {
    return '$radius km';
  }

  @override
  String get locationPermissionDenied =>
      'Location access is not allowed. You can enable it in iOS Settings.';

  @override
  String get locationUnavailable =>
      'Your current location could not be determined.';

  @override
  String get groupDiameter => 'Maximum group diameter';

  @override
  String get minimumChargingPoints => 'Required charging points';

  @override
  String get minimumPower => 'Minimum power per charging point';

  @override
  String minimumChargingOffer(int count, int power) {
    return 'At least $count charging points, each with at least $power kW';
  }

  @override
  String get resetFilters => 'Restore defaults';

  @override
  String get cancelFilterChanges => 'Cancel';

  @override
  String get favoritesOnly => 'Show favorites only';

  @override
  String get infrastructureFilter => 'Amenities';

  @override
  String get infrastructureFilterExplanation =>
      'Every selected amenity must be verified as present. Missing information is treated as unknown.';

  @override
  String get anyValue => 'Any';

  @override
  String get filterSearch => 'Search choices';

  @override
  String get operatorCountExplanation =>
      'Number in parentheses: charging points in the dataset';

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get done => 'Done';

  @override
  String get mapSemantics => 'Map with charging parks';

  @override
  String get mapUnavailable => 'Apple Maps is only available on iOS.';

  @override
  String get myLocation => 'My location';

  @override
  String get germanyOverview => 'Show Germany';

  @override
  String get loadingParks => 'Loading charging parks…';

  @override
  String visibleParks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count charging parks',
      one: 'One charging park',
      zero: 'No charging parks',
    );
    return '$_temp0';
  }

  @override
  String visibleParksLimitReached(int count) {
    return '$count+ charging parks';
  }

  @override
  String get datasetMissing => 'The charging park dataset is missing.';

  @override
  String get datasetUnsupported =>
      'The charging park dataset uses an unsupported version.';

  @override
  String get invalidFilterQuery =>
      'The selected filters could not be processed.';

  @override
  String get chargingParksLoadFailed =>
      'The charging parks could not be loaded.';

  @override
  String get detailsUnavailable => 'Details could not be loaded.';

  @override
  String get chargingParkDetails => 'Charging park details';

  @override
  String stationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stations',
      one: 'One station',
    );
    return '$_temp0';
  }

  @override
  String evseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count charging points',
      one: 'One charging point',
    );
    return '$_temp0';
  }

  @override
  String get operators => 'Operators';

  @override
  String get chargingPointsByOperator =>
      'Charging points by operator and power';

  @override
  String get power => 'Power';

  @override
  String get connectors => 'Connectors';

  @override
  String get unknown => 'Unknown';

  @override
  String get openingHours => 'Opening hours';

  @override
  String get powerClasses => 'Power classes';

  @override
  String maximumPower(double power) {
    return 'Maximum $power kW';
  }

  @override
  String get maximumPowerUnknown => 'Maximum power unknown';

  @override
  String proximityApproximation(int diameter) {
    return 'Spatial approximation; actual group diameter: $diameter m. Access roads, streets and property boundaries have not been checked.';
  }

  @override
  String datasetVersion(String version) {
    return 'Dataset $version';
  }

  @override
  String dataSource(String source, String version) {
    return 'Source: $source, as of $version';
  }

  @override
  String datasetCreatedAt(String createdAt) {
    return 'Dataset created: $createdAt';
  }

  @override
  String get navigationUnavailable => 'The navigation app could not be opened.';

  @override
  String get openNavigation => 'Start route';

  @override
  String get settings => 'Settings';

  @override
  String get settingsUnavailable => 'Settings could not be loaded.';

  @override
  String get language => 'Language';

  @override
  String get systemLanguage => 'System language';

  @override
  String get german => 'German';

  @override
  String get english => 'English';

  @override
  String get navigationApp => 'Navigation app';

  @override
  String get askEveryTime => 'Ask every time';

  @override
  String get notInstalled => 'Not installed';

  @override
  String get googleMapsUnavailable => 'Google Maps is unavailable';

  @override
  String get googleMapsFallbackExplanation =>
      'Google Maps is not installed. Open the route in Apple Maps instead?';

  @override
  String get useAppleMaps => 'Use Apple Maps';

  @override
  String get cancel => 'Cancel';

  @override
  String get favorites => 'Favorites';

  @override
  String get noFavorites => 'No charging parks saved as favorites yet.';

  @override
  String get addFavorite => 'Add to favorites';

  @override
  String get removeFavorite => 'Remove favorite';

  @override
  String get favoriteUnavailable => 'Unavailable in the current dataset';

  @override
  String get onSiteInformation => 'Verified on site';

  @override
  String observedOn(String date) {
    return 'Observed on $date';
  }

  @override
  String photoCredit(String author, String date) {
    return 'Photo: $author, taken on $date';
  }

  @override
  String get restaurant => 'Restaurant';

  @override
  String get shop => 'Shop';

  @override
  String get coffeeMachine => 'Coffee machine';

  @override
  String get snackMachine => 'Snack machine';

  @override
  String get toilet => 'Toilet';

  @override
  String get amenityPresent => 'Present';

  @override
  String get amenityAbsent => 'Not present';
}
