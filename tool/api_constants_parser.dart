/// Shared parsing of [AppConstants] string constants from `lib/util/app_constants.dart`.
library;

import 'dart:io';

/// Parses `static const String` declarations (single- and two-line forms).
List<({String name, String path})> parseAppConstantsUriConstants(String source) {
  final List<({String name, String path})> out = [];
  final RegExp singleLine = RegExp(
    r"static const String (\w+)\s*=\s*'([^']+)';",
    multiLine: true,
  );
  for (final Match m in singleLine.allMatches(source)) {
    out.add((name: m.group(1)!, path: m.group(2)!));
  }
  final RegExp openLine = RegExp(
    r"^\s*static const String (\w+)\s*=\s*$",
    multiLine: true,
  );
  final lines = source.split('\n');
  for (int i = 0; i < lines.length; i++) {
    final open = openLine.firstMatch(lines[i]);
    if (open == null) {
      continue;
    }
    final String name = open.group(1)!;
    if (i + 1 >= lines.length) {
      continue;
    }
    final next = RegExp(r"^\s*'([^']+)'\s*;\s*$").firstMatch(lines[i + 1]);
    if (next != null) {
      final String path = next.group(1)!;
      if (!out.any((e) => e.name == name && e.path == path)) {
        out.add((name: name, path: path));
      }
    }
  }
  out.sort((a, b) => a.name.compareTo(b.name));
  return out;
}

bool isApiStyleEntry(({String name, String path}) e) {
  if (e.name.endsWith('Uri')) {
    return true;
  }
  if (e.path.startsWith('/api/') ||
      e.path.startsWith('/cart/') ||
      e.path == '/cart/merge') {
    return true;
  }
  return false;
}

List<({String name, String path})> loadFilteredApiEntries() {
  final File f = File('lib/util/app_constants.dart');
  final String source = f.readAsStringSync();
  final entries = parseAppConstantsUriConstants(source);
  return entries.where(isApiStyleEntry).toList();
}
