import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ladepark_explorer/app/ladepark_explorer_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Composition boundary for NFR-PORT-001; concrete adapters are overridden in tests.
  runApp(const ProviderScope(child: LadeparkExplorerApp()));
}
