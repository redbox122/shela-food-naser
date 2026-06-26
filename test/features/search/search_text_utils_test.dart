import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/features/search/utils/search_text_utils.dart';

/// Proves the "most searched" cleaning + Arabic normalization rules: truncated
/// fragments are dropped, diacritics/hamza/ال variants collapse to one, and the
/// list is capped — the visible bug was "جب/سم/كب/بي" and duplicates.
void main() {
  group('normalizeArabic', () {
    test('strips diacritics so جُبن == جبن', () {
      expect(normalizeArabic('جُبن'), normalizeArabic('جبن'));
    });

    test('unifies hamza forms (أ/إ/آ → ا)', () {
      expect(normalizeArabic('أحمد'), 'احمد');
      expect(normalizeArabic('إيمان'), normalizeArabic('ايمان'));
    });

    test('strips tatweel', () {
      expect(normalizeArabic('فيتــامين'), 'فيتامين');
    });
  });

  group('arabicDedupKey', () {
    test('الجبن and جبن share a key', () {
      expect(arabicDedupKey('الجبن'), arabicDedupKey('جبن'));
    });

    test('does NOT over-strip short words like ألم (→ الم)', () {
      // remainder after "ال" would be 1 char, so the article is kept.
      expect(arabicDedupKey('ألم'), 'الم');
    });
  });

  group('cleanPopularTerms', () {
    test('drops truncated fragments under 3 chars (جب/سم/كب/بي)', () {
      final out = cleanPopularTerms(['بيتزا', 'جب', 'سم', 'كب', 'بي', 'جبن']);
      expect(out, ['بيتزا', 'جبن']);
    });

    test('de-dups normalized variants (جبن = جُبن = الجبن)', () {
      final out = cleanPopularTerms(['جبن', 'جُبن', 'الجبن', 'شاورما']);
      expect(out, ['جبن', 'شاورما']);
    });

    test('honours the blocklist (normalized compare)', () {
      final out = cleanPopularTerms(
        ['نوتيلا', 'ممنوع'],
        blocklist: {normalizeArabic('ممنوع')},
      );
      expect(out, ['نوتيلا']);
    });

    test('caps the list at the limit', () {
      final many = List.generate(20, (i) => 'كلمة$i');
      expect(cleanPopularTerms(many, limit: 10).length, 10);
    });

    test('keeps the first (highest-ranked) display form on dedup', () {
      // API arrives hit-count desc, so the first spelling wins.
      expect(cleanPopularTerms(['الجبن', 'جبن']), ['الجبن']);
    });
  });
}
