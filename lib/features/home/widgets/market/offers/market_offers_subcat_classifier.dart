import 'market_offers_models.dart';

/// Client-side sub-category classifier (panda-style) — groups a category's
/// products into virtual sub-categories by keyword, WITHOUT any backend change.
///
/// Why client-side: Hyper Shela's categories/products are rebuilt by an
/// external daily sync (panda/ramz), so manually-created backend sub-categories
/// get wiped. Grouping in the app instead is sync-proof and works on every
/// category with no production writes.
///
/// Algorithm (ported from the reviewed category_analyzer tool): grocery names
/// read as `<brand> <headNoun> <type> <size>` (e.g. "الوليمة أرز بسمتي 5 كجم"),
/// so the distinguishing token sits RIGHT AFTER the head-noun taken from the
/// category name ("الزيت والسمن" -> {زيت, سمن}). Group by that type; a category
/// needs ≥2 significant groups to be worth splitting, else return empty.
class SubCatClassifier {
  // Units, sizes, packaging, generic quality words — never a real sub-group.
  static const Set<String> _noise = {
    'مل', 'لتر', 'لترات', 'كجم', 'كغم', 'كيلو', 'جم', 'جرام', 'غرام', 'عبوة',
    'علبة', 'علب', 'كيس', 'أكياس', 'حبة', 'حبات', 'قطعة', 'قطع', 'كرتون',
    'عدد', '×', 'x', 'X', 'الكل', 'من', 'و', 'مع', 'في', 'او', 'أو', 'الى',
    'إلى', 'كبير', 'كبيرة', 'صغير', 'صغيرة', 'وسط', 'متعدد', 'الاستخدام',
    'بلاستيك', 'بلاستيكية', 'زجاج', 'زجاجة', 'زجاجية', 'بكر', 'ممتاز',
    'ممتازة', 'درجة', 'الدرجة', 'الأولى', 'الاولى', 'أولى', 'اولى',
    'الطبيعي', 'نقي', 'نقية', 'طبيعي', 'اصلي', 'أصلي', 'واط', 'هرتز',
    'أبيض', 'أسود', 'رمادي', 'احمر', 'أحمر', 'اخضر', 'أخضر',
  };

  static final RegExp _arabic = RegExp(r'[؀-ۿ]');
  static final RegExp _nonWord = RegExp(r'[^؀-ۿ0-9A-Za-z]');
  static final RegExp _leadingAl = RegExp(r'^(ال|وال)');
  static final RegExp _numOnly = RegExp(r'^[0-9٠-٩.,×xX]+$');

  static String _normalize(String s) =>
      s.replaceAll('أ', 'ا').replaceAll('إ', 'ا').replaceAll('آ', 'ا');

  static String _clean(String w) =>
      _normalize(w).replaceAll(_nonWord, '').replaceAll('ـ', '');

  static String _stripAl(String w) => w.replaceFirst(_leadingAl, '');

  static bool _isNum(String w) => _numOnly.hasMatch(w);

  /// Public: head-nouns of a category name (used by the brand extractor and the
  /// screen's filters). e.g. 'الزيت والسمن' -> ['زيت','سمن'].
  static List<String> headNouns(String categoryName) => _headNouns(categoryName);

  /// The brand of a product = the meaningful token(s) BEFORE the head-noun
  /// (grocery names lead with the brand: "عافية زيت ذرة" -> "عافية", "أبو كاس
  /// أرز بسمتي" -> "أبو كاس"). Falls back to the first meaningful token when no
  /// head-noun is present. Returns '' when nothing usable is found.
  static String brandOf(String name, List<String> heads) {
    final toks = _normalize(name)
        .split(RegExp(r'\s+'))
        .map(_clean)
        .where((t) => t.isNotEmpty)
        .toList();
    final before = <String>[];
    for (final t in toks) {
      if (heads.contains(_stripAl(t))) break;
      if (_isNum(t) || _noise.contains(t) || !_arabic.hasMatch(t)) continue;
      before.add(t);
      if (before.length >= 2) break; // brands are 1–2 words
    }
    if (before.isNotEmpty) return before.join(' ');
    final meaningful = toks
        .where((t) => !_isNum(t) && !_noise.contains(t) && _arabic.hasMatch(t))
        .toList();
    return meaningful.isNotEmpty ? meaningful.first : '';
  }

  /// Distinct brands (with counts) found across [products], largest first.
  /// Only brands appearing on ≥[minCount] products are kept, so single-item
  /// noise doesn't clutter the filter.
  static List<MapEntry<String, int>> brands(
    String categoryName,
    List<OfferProduct> products, {
    int minCount = 2,
    int maxBrands = 24,
  }) {
    final heads = _headNouns(categoryName);
    final counts = <String, int>{};
    for (final p in products) {
      final b = brandOf(p.name ?? '', heads);
      if (b.isNotEmpty) counts[b] = (counts[b] ?? 0) + 1;
    }
    final list = counts.entries.where((e) => e.value >= minCount).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return list.take(maxBrands).toList();
  }

  /// Head-nouns from a category name, e.g. 'الزيت والسمن' -> ['زيت','سمن'].
  static List<String> _headNouns(String categoryName) {
    final out = <String>[];
    for (final raw in _normalize(categoryName).split(RegExp(r'\s+'))) {
      final w = _stripAl(_clean(raw));
      if (w.length >= 3 && _arabic.hasMatch(w) && !_noise.contains(w)) {
        out.add(w);
      }
    }
    return out;
  }

  /// The distinguishing "type" token of one product name.
  static String _typeOf(String name, List<String> heads) {
    final toks = _normalize(name)
        .split(RegExp(r'\s+'))
        .map(_clean)
        .where((t) => t.isNotEmpty)
        .toList();
    final meaningful =
        toks.where((t) => !_isNum(t) && !_noise.contains(t)).toList();

    // 1) after a head-noun -> the real type (بسمتي / زيتون / نباتي)
    for (var i = 0; i < toks.length; i++) {
      final base = _stripAl(toks[i]);
      if (heads.contains(base)) {
        for (var j = i + 1; j < toks.length; j++) {
          final nxt = _stripAl(toks[j]);
          if (nxt.isNotEmpty &&
              !_isNum(nxt) &&
              !_noise.contains(nxt) &&
              _arabic.hasMatch(nxt) &&
              !heads.contains(nxt)) {
            return nxt;
          }
        }
        // head-noun present but nothing after -> the head-noun IS the type
        // (e.g. "سمن" distinguishes it from "زيت").
        return base;
      }
    }
    // 2) no head-noun -> skip a leading brand, take next meaningful token
    if (meaningful.length >= 2) return _stripAl(meaningful[1]);
    return meaningful.isNotEmpty ? _stripAl(meaningful.first) : '';
  }

  /// Group [products] into virtual sub-categories. Returns an empty list when
  /// the category is flat/homogeneous (fewer than 2 significant groups), so the
  /// caller shows no second bar. Every product is placed in exactly one group
  /// (leftovers fall into "أخرى") so nothing is hidden.
  static List<SubCat> classify(
    String categoryName,
    List<OfferProduct> products, {
    int minProducts = 10,
    int minGroup = 3,
    int maxGroups = 8,
  }) {
    if (products.length < minProducts) return const [];
    final heads = _headNouns(categoryName);

    final byType = <String, List<OfferProduct>>{};
    for (final p in products) {
      final t = _typeOf(p.name ?? '', heads);
      (byType[t.isEmpty ? '__none' : t] ??= []).add(p);
    }

    // significant groups only, largest first, capped
    final significant = byType.entries
        .where((e) => e.key != '__none' && e.value.length >= minGroup)
        .toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    if (significant.length < 2) return const [];
    final kept = significant.take(maxGroups).toList();
    final keptKeys = kept.map((e) => e.key).toSet();

    // everything not in a kept group -> "أخرى" (so no product is dropped)
    final other = <OfferProduct>[];
    byType.forEach((k, v) {
      if (!keptKeys.contains(k)) other.addAll(v);
    });

    final result = <SubCat>[
      for (final e in kept)
        SubCat(
          id: 'kw:${e.key}',
          name: e.key,
          products: e.value,
          total: e.value.length,
        ),
    ];
    if (other.length >= minGroup) {
      result.add(SubCat(
        id: 'kw:__other',
        name: 'أخرى',
        products: other,
        total: other.length,
      ));
    }
    return result;
  }
}
