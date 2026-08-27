import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ladepark_explorer/app/ladepark_explorer_app.dart';
import 'package:ladepark_explorer/features/explorer/application/explorer_providers.dart';

import 'support/fake_charging_repository.dart';

void main() {
  testWidgets('shows the localized Wurf A map shell', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chargingRepositoryProvider.overrideWith(
            (ref) async => FakeChargingRepository(),
          ),
        ],
        child: const LadeparkExplorerApp(locale: Locale('de')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ladepark Explorer'), findsOneWidget);
    expect(
      find.text('Die Apple-Karte ist nur auf iOS verfügbar.'),
      findsOneWidget,
    );
    expect(find.text('Keine Ladeparks'), findsOneWidget);
    expect(find.byIcon(Icons.zoom_out_map), findsOneWidget);
  });
}
