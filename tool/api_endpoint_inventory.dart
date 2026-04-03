// ignore_for_file: avoid_print
/// Extracts every `static const String *Uri` (and similar) path from [AppConstants]
/// for evidence-based API audits. This is **inventory**, not runtime health.
///
/// Run from repo root:
///   dart run tool/api_endpoint_inventory.dart
///
/// Writes:
///   test/api_traffic_trace/generated/api_endpoint_inventory.json
library;

import 'dart:convert';
import 'dart:io';

import 'api_constants_parser.dart';

const String _constantsPath = 'lib/util/app_constants.dart';
const String _outDir = 'test/api_traffic_trace/generated';
const String _outJson = '$_outDir/api_endpoint_inventory.json';

void main() {
  final File f = File(_constantsPath);
  if (!f.existsSync()) {
    stderr.writeln('Missing $_constantsPath');
    exitCode = 1;
    return;
  }
  final String source = f.readAsStringSync();
  final entries = parseAppConstantsUriConstants(source);

  final List<({String name, String path})> apiEntries =
      entries.where(isApiStyleEntry).toList();
  final Set<String> uniquePaths = {};
  for (final e in apiEntries) {
    uniquePaths.add(e.path);
  }

  final Map<String, dynamic> report = {
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'source_file': _constantsPath,
    'raw_parsed_constants': entries.length,
    'api_filtered_entries': apiEntries.length,
    'unique_path_strings': uniquePaths.length,
    'entries': apiEntries
        .map((e) => {'constant': e.name, 'path': e.path})
        .toList(growable: false),
    'unique_paths_sorted': uniquePaths.toList()..sort(),
    'notes': [
      'Paths are string constants in the client — not proof they are called, GET vs POST, or healthy.',
      'Some calls build URLs by concatenation; those may not appear as full paths here.',
      'Runtime verification requires per-method, per-auth, per-body matrix against each environment.',
    ],
  };

  Directory(_outDir).createSync(recursive: true);
  File(_outJson).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));

  print('Wrote $_outJson');
  print('');
  print('Raw parsed const String entries: ${entries.length}');
  print('After API filter (*Uri or /api/...): ${apiEntries.length}');
  print('Unique path strings: ${uniquePaths.length}');
  print('');
  print('This file is EVIDENCE of client-side route constants, not server health.');
}
