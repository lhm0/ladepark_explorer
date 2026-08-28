import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/features/settings/presentation/privacy_page.dart';
import 'package:ladepark_explorer/l10n/app_localizations.dart';

// Privacy regression for FR-PRIV-001: no remote diagnostics are offered and
// copying the deliberately sparse local status requires an explicit action.
void main() {
  testWidgets('discloses privacy boundaries and copies sparse diagnostics', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardText =
              (call.arguments as Map<Object?, Object?>)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PrivacyPage(automaticDatasetChecks: false),
      ),
    );

    expect(find.text('Keine automatische Übertragung'), findsOneWidget);
    expect(find.text('Bewusste Netzwerkzugriffe'), findsOneWidget);
    expect(find.textContaining('Telemetrie: deaktiviert'), findsOneWidget);
    expect(
      find.textContaining('Automatische Datensatzprüfung: deaktiviert'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.byKey(const ValueKey('copy-diagnostics')));
    await tester.tap(find.byKey(const ValueKey('copy-diagnostics')));
    await tester.pump();

    expect(clipboardText, contains('Telemetrie: deaktiviert'));
    expect(clipboardText, isNot(contains('Koordinate')));
    expect(find.text('Diagnosestatus wurde kopiert.'), findsOneWidget);
  });
}
