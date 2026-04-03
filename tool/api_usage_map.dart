// ignore_for_file: avoid_print
/// Layers a **usage map** on top of [AppConstants] inventory:
/// - which constants are referenced under `lib/` (file:line)
/// - which trace scripts mention which paths (smoke coverage heuristic)
/// - gap: declared vs referenced vs smoke-covered
///
/// Run from repo root:
///   dart run tool/api_usage_map.dart
///
/// Writes:
///   test/api_traffic_trace/generated/api_usage_map.json
///   test/api_traffic_trace/generated/gap_report.txt
library;

import 'dart:convert';
import 'dart:io';

import 'api_constants_parser.dart';

const String _outDir = 'test/api_traffic_trace/generated';
const String _outJson = '$_outDir/api_usage_map.json';
const String _outTxt = '$_outDir/gap_report.txt';

List<File> _dartFilesUnder(String root) {
  final dir = Directory(root);
  if (!dir.existsSync()) {
    return [];
  }
  final List<File> out = [];
  for (final entity in dir.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) {
      continue;
    }
    final String p = entity.path.replaceAll('\\', '/');
    if (!p.endsWith('.dart')) {
      continue;
    }
    if (p.contains('/.dart_tool/')) {
      continue;
    }
    out.add(entity);
  }
  return out;
}

/// References like `AppConstants.loginUri` (word boundary).
List<String> findAppConstantReferences(
  String constantName,
  String fileContent,
  String relativePath,
) {
  final RegExp re = RegExp(r'\bAppConstants\.' + RegExp.escape(constantName) + r'\b');
  final List<String> locations = [];
  final lines = fileContent.split('\n');
  for (int i = 0; i < lines.length; i++) {
    if (re.hasMatch(lines[i])) {
      locations.add('$relativePath:${i + 1}');
    }
  }
  return locations;
}

/// Heuristic: collect `/api/...` and `/cart/...` string literals from trace tests.
Set<String> extractSmokePathsFromTraceTests() {
  final Set<String> paths = {};
  final RegExp apiLiteral = RegExp(r"'(/(?:api|cart)[^']*)'");
  final RegExp pathKey = RegExp(r"path:\s*'(/[^']+)'");
  final dir = Directory('test/api_traffic_trace');
  if (!dir.existsSync()) {
    return paths;
  }
  for (final entity in dir.listSync(recursive: false)) {
    if (entity is! File || !entity.path.endsWith('.dart')) {
      continue;
    }
    final String content = entity.readAsStringSync();
    for (final Match m in apiLiteral.allMatches(content)) {
      paths.add(m.group(1)!);
    }
    for (final Match m in pathKey.allMatches(content)) {
      paths.add(m.group(1)!);
    }
  }
  return paths;
}

/// True if [declaredPath] is covered by any smoke path (prefix or equality).
bool smokeCoversPath(String declaredPath, Set<String> smokePaths) {
  if (smokePaths.contains(declaredPath)) {
    return true;
  }
  for (final String s in smokePaths) {
    if (declaredPath.startsWith(s) || s.startsWith(declaredPath)) {
      if (declaredPath.length <= s.length + 15) {
        return true;
      }
    }
    if (s.contains(declaredPath) && declaredPath.length >= 12) {
      return true;
    }
  }
  return false;
}

void main() {
  final List<({String name, String path})> apiEntries = loadFilteredApiEntries();

  final libFiles = _dartFilesUnder('lib');
  final Map<String, List<String>> usageByConstant = {};
  final Map<String, List<String>> usageInTest = {};

  for (final ({String name, String path}) e in apiEntries) {
    usageByConstant[e.name] = [];
  }

  for (final File f in libFiles) {
    final String rel = f.path.replaceAll('\\', '/');
    final String content = f.readAsStringSync();
    for (final ({String name, String path}) e in apiEntries) {
      final String name = e.name;
      final List<String> hits =
          findAppConstantReferences(name, content, rel);
      if (hits.isNotEmpty) {
        usageByConstant[name] = [...usageByConstant[name]!, ...hits];
      }
    }
  }

  final testLibFiles = _dartFilesUnder('test');
  for (final File f in testLibFiles) {
    final String rel = f.path.replaceAll('\\', '/');
    final String content = f.readAsStringSync();
    for (final ({String name, String path}) e in apiEntries) {
      final String name = e.name;
      final List<String> hits =
          findAppConstantReferences(name, content, rel);
      if (hits.isNotEmpty) {
        usageInTest.putIfAbsent(name, () => []);
        usageInTest[name] = [...usageInTest[name]!, ...hits];
      }
    }
  }

  final Set<String> referencedConstants = usageByConstant.entries
      .where((MapEntry<String, List<String>> e) => e.value.isNotEmpty)
      .map((MapEntry<String, List<String>> e) => e.key)
      .toSet();

  final Set<String> unusedInLib = apiEntries
      .where((({String name, String path}) e) =>
          (usageByConstant[e.name] ?? []).isEmpty)
      .map((e) => e.name)
      .toSet();

  final Set<String> unusedAnywhere = apiEntries
      .map((e) => e.name)
      .where((String n) =>
          !referencedConstants.contains(n) && !usageInTest.containsKey(n))
      .toSet();

  final Set<String> testOnly = usageInTest.keys
      .where((String k) => !referencedConstants.contains(k))
      .toSet();

  final Set<String> smokePaths = extractSmokePathsFromTraceTests();

  final List<Map<String, dynamic>> perConstant = [];
  for (final (:String name, :String path) in apiEntries) {
    final List<String> libLocs = usageByConstant[name] ?? [];
    final List<String> testLocs = usageInTest[name] ?? [];
    final bool refLib = libLocs.isNotEmpty;
    final bool smoke = smokeCoversPath(path, smokePaths);
    perConstant.add({
      'constant': name,
      'path': path,
      'referenced_in_lib': refLib,
      'reference_count_lib': libLocs.length,
      'locations_lib': libLocs,
      'locations_test': testLocs,
      'smoke_path_heuristic_match': smoke,
      'needs_live_validation': refLib && !smoke,
    });
  }

  final int verifiedBySmoke = perConstant
      .where((m) => m['referenced_in_lib'] == true && m['smoke_path_heuristic_match'] == true)
      .length;
  final int declaredUnusedLib = unusedAnywhere.length;
  final int declaredUsedNotSmoke = perConstant
      .where((m) => m['needs_live_validation'] == true)
      .length;

  final Map<String, dynamic> report = {
    'generated_at': DateTime.now().toUtc().toIso8601String(),
    'summary': {
      'declared_api_constants': apiEntries.length,
      'unique_paths': apiEntries.map((e) => e.path).toSet().length,
      'referenced_in_lib': referencedConstants.length,
      'never_referenced_anywhere': declaredUnusedLib,
      'referenced_only_in_tests_not_lib': testOnly.length,
      'smoke_literal_paths_extracted': smokePaths.length,
      'referenced_in_lib_and_smoke_match': verifiedBySmoke,
      'referenced_in_lib_but_not_smoke': declaredUsedNotSmoke,
    },
    'smoke_paths_extracted': smokePaths.toList()..sort(),
    'constants_unused_in_lib': unusedInLib.toList()..sort(),
    'constants_only_referenced_from_test': testOnly.toList()..sort(),
    'per_constant': perConstant,
    'notes': [
      'Usage = textual match of AppConstants.<name> in source; aliases/prefix imports may be missed.',
      'Dynamic URL building may reference a constant in an expression not matching the simple pattern.',
      'Smoke coverage = string literals in test/api_traffic_trace/*.dart only; partial vs run_all_traces.',
      'needs_live_validation = referenced in lib but path not matched by smoke heuristic.',
    ],
  };

  Directory(_outDir).createSync(recursive: true);
  File(_outJson).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));

  final buf = StringBuffer()
    ..writeln('API USAGE GAP REPORT (generated)')
    ..writeln('====================================')
    ..writeln('')
    ..writeln('INVENTORY')
    ..writeln('  Declared API-style constants: ${apiEntries.length}')
    ..writeln('  Unique path strings:          ${apiEntries.map((e) => e.path).toSet().length}')
    ..writeln('')
    ..writeln('USAGE (lib/)')
    ..writeln('  Constants referenced:         ${referencedConstants.length}')
    ..writeln('  Never referenced (lib+test): $declaredUnusedLib')
    ..writeln('  Referenced only under test/:  ${testOnly.length}')
    ..writeln('')
    ..writeln('SMOKE TEST HEURISTIC (strings in test/api_traffic_trace/*.dart)')
    ..writeln('  Distinct /api or /cart paths extracted: ${smokePaths.length}')
    ..writeln('  Referenced in lib AND matched by smoke: $verifiedBySmoke')
    ..writeln('  Referenced in lib BUT not matched:      $declaredUsedNotSmoke  <-- prioritize live checks')
    ..writeln('')
    ..writeln('CATEGORIES')
    ..writeln('  [declared only]     = in AppConstants, never AppConstants.name in lib or test')
    ..writeln('  [used in app]       = AppConstants.name appears under lib/')
    ..writeln('  [smoke approx]      = path string found in trace *.dart (not full matrix)')
    ..writeln('  [needs validation]  = used in lib, no smoke string match')
    ..writeln('')
    ..writeln('Full JSON: $_outJson')
    ..writeln('');

  File(_outTxt).writeAsStringSync(buf.toString());

  print(buf.toString());
  print('Wrote $_outJson');
  print('Wrote $_outTxt');
}
