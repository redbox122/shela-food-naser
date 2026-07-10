/// Deduplication helpers for list data coming from the network.
///
/// The app merges items from several endpoints (home unified, offers, category,
/// market products, search…) and today each call site dedupes by hand with
/// `toSet()` / manual `where` + a local `Set`. These helpers centralise that
/// logic so every screen dedupes the same way — stable order, id-based, no
/// behavioural change to existing callers (this is a new, opt-in utility).
///
/// Pure Dart: no Flutter / GetX / network imports, so it is trivially testable.
library;

extension DeduplicateList<T> on List<T> {
  /// Returns a new list with duplicates removed by their id, **keeping the first
  /// occurrence** and preserving order.
  ///
  /// ```dart
  /// final unique = products.uniqueById((p) => p.id.toString());
  /// ```
  List<T> uniqueById(String Function(T item) getId) {
    final seen = <String>{};
    final result = <T>[];
    for (final item in this) {
      if (seen.add(getId(item))) {
        result.add(item);
      }
    }
    return result;
  }

  /// Like [uniqueById] but **keeps the last occurrence** of each id (useful when
  /// a later page/source carries a fresher copy of the same item). Order follows
  /// the last-seen position.
  List<T> uniqueByIdKeepLast(String Function(T item) getId) {
    final byId = <String, T>{};
    for (final item in this) {
      byId[getId(item)] = item; // later writes overwrite earlier ones
    }
    return byId.values.toList();
  }
}

/// Merges any number of lists and removes duplicates by id.
///
/// By default the **last** occurrence wins (fresher source overrides the older
/// one) while preserving first-seen order, which matches the common
/// "merge cache + network" case. Set [keepFirst] to keep the first occurrence
/// instead.
///
/// ```dart
/// final all = mergeUniqueById(
///   [cachedProducts, networkProducts],
///   (p) => p.id.toString(),
/// );
/// ```
List<T> mergeUniqueById<T>(
  List<List<T>> lists,
  String Function(T item) getId, {
  bool keepFirst = false,
}) {
  final order = <String>[];
  final byId = <String, T>{};
  for (final list in lists) {
    for (final item in list) {
      final id = getId(item);
      if (!byId.containsKey(id)) {
        order.add(id);
        byId[id] = item;
      } else if (!keepFirst) {
        byId[id] = item; // last wins, position stays first-seen
      }
    }
  }
  return [for (final id in order) byId[id] as T];
}
