import 'dart:io';

// Protects the platform boundary required by NFR-PORT-001.
final forbiddenImport = RegExp(
  r"^import 'package:ladepark_explorer/(data|platform|[^']*/presentation)/",
  multiLine: true,
);

void main() {
  final violations = <String>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    if (!entity.path.contains('/domain/')) continue;
    if (forbiddenImport.hasMatch(entity.readAsStringSync())) {
      violations.add(entity.path);
    }
  }
  if (violations.isNotEmpty) {
    stderr.writeln(
      'Domain code must not import data, platform, or presentation code:',
    );
    stderr.writeln(violations.join('\n'));
    exitCode = 1;
    return;
  }
  stdout.writeln('Flutter architecture boundaries are valid.');
}
