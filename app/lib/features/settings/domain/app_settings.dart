enum AppLanguage { system, german, english }

enum NavigationPreference { askEveryTime, appleMaps, googleMaps }

final class AppSettings {
  const AppSettings({
    this.language = AppLanguage.system,
    this.navigationPreference = NavigationPreference.askEveryTime,
  });

  final AppLanguage language;
  final NavigationPreference navigationPreference;

  AppSettings copyWith({
    AppLanguage? language,
    NavigationPreference? navigationPreference,
  }) => AppSettings(
    language: language ?? this.language,
    navigationPreference: navigationPreference ?? this.navigationPreference,
  );
}
