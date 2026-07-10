import 'dart:async';

import 'package:sixam_mart/core/utils/deduplicator.dart';

/// Reusable, id-deduplicating pagination controller.
///
/// Wraps the "load page → append → know if there's more" bookkeeping that today
/// is re-implemented per screen (home, offers, category, market products…). It
/// guarantees **no duplicate items** across pages (a common backend quirk where
/// the same item reappears on page boundaries) via an internal id set, and it
/// can optionally **pre-fetch the next page** in the background so scrolling
/// never stalls.
///
/// Pure Dart / framework-agnostic: hook it into GetX, Bloc, or setState. It does
/// NOT touch the network itself — you pass a [fetch] callback that uses the
/// app's existing `ApiClient`, so nothing about the current data layer changes.
///
/// ```dart
/// final _pager = PaginationHelper<Product>(limit: 20);
/// await _pager.loadMore(
///   fetch: (offset) => repo.products(offset: offset, limit: 20),
///   getId: (p) => p.id.toString(),
/// );
/// final items = _pager.items; // deduped, in order
/// ```
class PaginationHelper<T> {
  PaginationHelper({this.limit = 20, this.prefetchNext = false});

  /// Page size requested each round.
  final int limit;

  /// When true, after a successful [loadMore] the next page is fetched in the
  /// background and buffered, so the following [loadMore] returns instantly.
  final bool prefetchNext;

  int _page = 0;
  bool _hasMore = true;
  bool _isLoading = false;

  final List<T> _allItems = [];
  final Set<String> _seenIds = {};

  // Buffered next page (only used when [prefetchNext] is true).
  List<T>? _prefetched;
  Future<List<T>>? _prefetchFuture;

  /// Whether more pages might still exist (last page returned a full [limit]).
  bool get hasMore => _hasMore;

  /// Whether a foreground load is in flight.
  bool get isLoading => _isLoading;

  /// Zero-based index of the next page to request.
  int get nextPage => _page;

  /// The accumulated, de-duplicated items (read-only view).
  List<T> get items => List.unmodifiable(_allItems);

  /// Loads the next page and appends only items whose id hasn't been seen yet.
  ///
  /// - [fetch] receives the **offset** (`page * limit`) and returns that page.
  /// - [getId] extracts a stable id used for de-duplication.
  ///
  /// Returns the newly added (unique) items for this call, or an empty list if
  /// nothing new arrived / a load was skipped.
  Future<List<T>> loadMore({
    required Future<List<T>> Function(int offset) fetch,
    required String Function(T item) getId,
  }) async {
    if (_isLoading || !_hasMore) return const [];
    _isLoading = true;
    try {
      // Use the buffered page if we pre-fetched it earlier, else fetch now.
      final List<T> page = _prefetched != null
          ? _prefetched!
          : await (_prefetchFuture ?? fetch(_page * limit));
      _prefetched = null;
      _prefetchFuture = null;

      final List<T> added = [];
      for (final item in page) {
        if (_seenIds.add(getId(item))) {
          _allItems.add(item);
          added.add(item);
        }
      }

      _page++;
      _hasMore = page.length >= limit;

      // Kick off the next page in the background for an instant next call.
      if (prefetchNext && _hasMore) {
        _prefetchFuture = fetch(_page * limit);
        // Materialise into [_prefetched] when it resolves; ignore failures so a
        // background miss just falls back to a normal fetch next time.
        unawaited(_prefetchFuture!.then((p) => _prefetched = p).catchError((_) {
          _prefetched = null;
          _prefetchFuture = null;
          return <T>[];
        }));
      }

      return added;
    } finally {
      _isLoading = false;
    }
  }

  /// Replaces the whole list with [fresh] (deduped) — use after pull-to-refresh
  /// so the first page stays consistent with the paginator's id set.
  void seedFirstPage(List<T> fresh, String Function(T item) getId) {
    reset();
    final unique = fresh.uniqueById(getId);
    _allItems.addAll(unique);
    _seenIds.addAll(unique.map(getId));
    _page = 1;
    _hasMore = fresh.length >= limit;
  }

  /// Clears all state back to the first page.
  void reset() {
    _page = 0;
    _hasMore = true;
    _isLoading = false;
    _allItems.clear();
    _seenIds.clear();
    _prefetched = null;
    _prefetchFuture = null;
  }
}
