/// Pure Arabic text helpers for search + "most searched" suggestions.
///
/// Kept free of Flutter/GetX so they can be unit-tested directly. Used by the
/// search screen to scope/clean discovery results (see HomeSearchScreen).
library;

// Tashkeel (U+064B–U+0652), superscript alef (U+0670), tatweel (U+0640).
final RegExp _arabicMarks = RegExp(r'[ً-ْٰـ]');
final RegExp _whitespace = RegExp(r'\s+');
final RegExp _hamzaForms = RegExp('[أإآٱ]');

/// Safe normalization: strips diacritics + tatweel, collapses whitespace,
/// lowercases. Never reduces DB matches (stored text carries no combining
/// marks), so "جُبن" reaches the same rows as "جبن". Use for the OUTGOING query.
String stripArabicMarks(String s) => s
    .replaceAll(_arabicMarks, '')
    .replaceAll(_whitespace, ' ')
    .trim()
    .toLowerCase();

/// Fuller normalization for ranking + de-duplication: also unifies hamza forms,
/// alef-maqsura (ى→ي) and ta-marbuta (ة→ه).
String normalizeArabic(String s) => stripArabicMarks(s)
    .replaceAll(_hamzaForms, 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ؤ', 'و')
    .replaceAll('ئ', 'ي')
    .replaceAll('ة', 'ه');

/// De-dup key: [normalizeArabic] plus a guarded strip of the leading "ال"
/// article (so "جبن" = "الجبن"), but only when ≥3 chars remain — keeps real
/// words like "ألم" (→ "الم") intact.
String arabicDedupKey(String s) {
  final String t = normalizeArabic(s);
  if (t.startsWith('ال') && (t.length - 2) >= 3) return t.substring(2);
  return t;
}

/// Cleans raw "most searched" terms: drop < 3 normalized chars (kills
/// "جب/سم/كب/بي"), drop blocklisted, de-dup by normalized key
/// ("جبن" = "جُبن" = "الجبن"), cap at [limit]. Keeps the original display form
/// of the first (highest-ranked) occurrence — callers pass a hit-count-desc list.
List<String> cleanPopularTerms(
  Iterable<String> raw, {
  Set<String> blocklist = const {},
  int limit = 10,
}) {
  final Set<String> seen = {};
  final List<String> out = [];
  for (final String term0 in raw) {
    final String term = term0.trim();
    if (term.isEmpty) continue;
    final String norm = normalizeArabic(term);
    if (norm.runes.length < 3) continue;
    if (blocklist.contains(norm)) continue;
    if (!seen.add(arabicDedupKey(term))) continue;
    out.add(term);
    if (out.length >= limit) break;
  }
  return out;
}
