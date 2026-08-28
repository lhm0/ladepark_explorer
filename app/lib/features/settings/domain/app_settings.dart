enum AppLanguage { system, german, english }

enum NavigationPreference { askEveryTime, appleMaps, googleMaps }

final class AppSettings {
  const AppSettings({
    this.language = AppLanguage.system,
    this.navigationPreference = NavigationPreference.askEveryTime,
    this.automaticDatasetChecks = true,
  });

  final AppLanguage language;
  final NavigationPreference navigationPreference;
  final bool automaticDatasetChecks;

  AppSettings copyWith({
    AppLanguage? language,
    NavigationPreference? navigationPreference,
    bool? automaticDatasetChecks,
  }) => AppSettings(
    language: language ?? this.language,
    navigationPreference: navigationPreference ?? this.navigationPreference,
    automaticDatasetChecks:
        automaticDatasetChecks ?? this.automaticDatasetChecks,
  );
}
