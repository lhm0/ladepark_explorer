import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/app/theme.dart';
import 'package:ladepark_explorer/features/explorer/presentation/map_screen.dart';
import 'package:ladepark_explorer/features/settings/application/settings_providers.dart';
import 'package:ladepark_explorer/features/settings/domain/app_settings.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';

class LadeparkExplorerApp extends ConsumerWidget {
  const LadeparkExplorerApp({super.key, this.locale});

  final Locale? locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedLanguage = ref.watch(settingsControllerProvider).value?.language;
    final selectedLocale =
        locale ??
        switch (savedLanguage) {
          AppLanguage.german => const Locale('de'),
          AppLanguage.english => const Locale('en'),
          _ => null,
        };
    return MaterialApp(
      locale: selectedLocale,
      localeListResolutionCallback: (locales, supportedLocales) {
        if (selectedLocale != null) return selectedLocale;
        for (final locale in locales ?? const <Locale>[]) {
          if (locale.languageCode == 'de' || locale.languageCode == 'en') {
            return Locale(locale.languageCode);
          }
        }
        return const Locale('de');
      },
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: buildAppTheme(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MapScreen(),
    );
  }
}
