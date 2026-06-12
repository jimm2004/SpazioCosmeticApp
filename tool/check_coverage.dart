import 'dart:io';

void main(List<String> args) {
  final minCoverage = args.isNotEmpty ? double.tryParse(args[0]) ?? 30.0 : 30.0;
  final path = args.length > 1 ? args[1] : 'coverage/lcov.info';
  final file = File(path);

  if (!file.existsSync()) {
    stderr.writeln('No existe $path. Ejecutá primero: flutter test test --coverage');
    exit(1);
  }

  var found = 0;
  var hit = 0;

  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('LF:')) {
      found += int.tryParse(line.substring(3).trim()) ?? 0;
    }
    if (line.startsWith('LH:')) {
      hit += int.tryParse(line.substring(3).trim()) ?? 0;
    }
  }

  if (found == 0) {
    stderr.writeln('Coverage: 0.00% (0/0 líneas).');
    stderr.writeln('No hay líneas medibles en $path.');
    stderr.writeln('Solución: tus tests deben importar y ejecutar código desde lib/, por ejemplo:');
    stderr.writeln("import 'package:store_mood_app/core/testing/domain_test_harness.dart';");
    exit(1);
  }

  final coverage = (hit / found) * 100;
  stdout.writeln('Coverage: ${coverage.toStringAsFixed(2)}% ($hit/$found líneas).');

  if (coverage < minCoverage) {
    stderr.writeln('Cobertura insuficiente. Mínimo requerido: ${minCoverage.toStringAsFixed(2)}%.');
    exit(1);
  }

  stdout.writeln('Cobertura aprobada.');
}
