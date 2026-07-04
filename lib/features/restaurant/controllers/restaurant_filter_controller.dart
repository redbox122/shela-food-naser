import 'package:get/get.dart';

/// Sort + filter state for a module store list (restaurants / cafes / grocery /
/// pharmacy). Purely additive: it holds UI state and produces API query params,
/// and never touches existing controllers. Screens opt in by creating one
/// instance per [moduleType] (tag) and calling [onApply] when the user applies.
class RestaurantFilterModel {
  // ── Sort ──
  // recommended / distance / time / discount / rating
  String sortBy;

  // ── Quick filters (multi-select) ──
  bool freeDelivery;
  bool within30Min;
  bool hasOffers;
  bool isNew;

  // ── Price (single-select): '$' / '$$' / '$$$' ──
  String? priceRange;

  // ── Rating (single-select): 4.0 / 4.5 ──
  double? minRating;

  RestaurantFilterModel({
    this.sortBy = 'recommended',
    this.freeDelivery = false,
    this.within30Min = false,
    this.hasOffers = false,
    this.isNew = false,
    this.priceRange,
    this.minRating,
  });

  RestaurantFilterModel copyWith({
    String? sortBy,
    bool? freeDelivery,
    bool? within30Min,
    bool? hasOffers,
    bool? isNew,
    String? priceRange,
    bool clearPriceRange = false,
    double? minRating,
    bool clearMinRating = false,
  }) {
    return RestaurantFilterModel(
      sortBy: sortBy ?? this.sortBy,
      freeDelivery: freeDelivery ?? this.freeDelivery,
      within30Min: within30Min ?? this.within30Min,
      hasOffers: hasOffers ?? this.hasOffers,
      isNew: isNew ?? this.isNew,
      priceRange: clearPriceRange ? null : (priceRange ?? this.priceRange),
      minRating: clearMinRating ? null : (minRating ?? this.minRating),
    );
  }

  /// Number of *active* filters (sort excluded, matching the "تطبيق (n)" badge).
  int get activeFiltersCount {
    int n = 0;
    if (freeDelivery) n++;
    if (within30Min) n++;
    if (hasOffers) n++;
    if (isNew) n++;
    if (priceRange != null) n++;
    if (minRating != null) n++;
    return n;
  }

  bool get isSortDefault => sortBy == 'recommended';

  /// Maps [priceRange] symbols to the API's 1/2/3 scale.
  int? get priceRangeApiValue {
    switch (priceRange) {
      case '\$':
        return 1;
      case '\$\$':
        return 2;
      case '\$\$\$':
        return 3;
    }
    return null;
  }

  /// Maps [sortBy] to the API `sort_by` value.
  String get sortByApiValue {
    switch (sortBy) {
      case 'distance':
        return 'distance';
      case 'time':
        return 'delivery_time';
      case 'discount':
        return 'discount';
      case 'rating':
        return 'rating';
      default:
        return 'recommended';
    }
  }

  /// Query params for `GET /restaurants/list` (only the active ones).
  Map<String, String> toQueryParams() {
    final Map<String, String> p = {'sort_by': sortByApiValue};
    if (freeDelivery) p['free_delivery'] = 'true';
    if (within30Min) p['max_delivery_time'] = '30';
    if (hasOffers) p['has_offers'] = 'true';
    if (isNew) p['is_new'] = 'true';
    if (minRating != null) p['min_rating'] = minRating!.toStringAsFixed(1);
    final int? pr = priceRangeApiValue;
    if (pr != null) p['price_range'] = pr.toString();
    return p;
  }
}

/// One controller per module store list. Register it with a tag equal to the
/// [moduleType] so the four screens each keep independent filter state.
class RestaurantFilterController extends GetxController {
  RestaurantFilterController({this.moduleType = 'restaurants'});

  final String moduleType;

  RestaurantFilterModel _applied = RestaurantFilterModel();
  RestaurantFilterModel get applied => _applied;

  /// Draft edited inside the bottom sheets before the user taps "تطبيق".
  RestaurantFilterModel _draft = RestaurantFilterModel();
  RestaurantFilterModel get draft => _draft;

  /// Fired after [apply]; the host screen wires this to reload its store list
  /// with [RestaurantFilterModel.toQueryParams].
  void Function(RestaurantFilterModel filter)? onApply;

  bool get hasActiveFilters =>
      _applied.activeFiltersCount > 0 || !_applied.isSortDefault;

  int get activeFiltersCount => _applied.activeFiltersCount;

  // ── Draft editing (used by the sheets) ──
  void beginEditing() {
    _draft = _applied.copyWith();
    update();
  }

  void setDraft(RestaurantFilterModel next) {
    _draft = next;
    update();
  }

  void setSort(String sortBy) {
    _draft = _draft.copyWith(sortBy: sortBy);
    update();
  }

  void toggleFreeDelivery() {
    _draft = _draft.copyWith(freeDelivery: !_draft.freeDelivery);
    update();
  }

  void toggleWithin30Min() {
    _draft = _draft.copyWith(within30Min: !_draft.within30Min);
    update();
  }

  void toggleHasOffers() {
    _draft = _draft.copyWith(hasOffers: !_draft.hasOffers);
    update();
  }

  void toggleIsNew() {
    _draft = _draft.copyWith(isNew: !_draft.isNew);
    update();
  }

  void setPriceRange(String? value) {
    if (_draft.priceRange == value) {
      _draft = _draft.copyWith(clearPriceRange: true);
    } else {
      _draft = _draft.copyWith(priceRange: value);
    }
    update();
  }

  void setMinRating(double? value) {
    if (_draft.minRating == value) {
      _draft = _draft.copyWith(clearMinRating: true);
    } else {
      _draft = _draft.copyWith(minRating: value);
    }
    update();
  }

  /// Quick chips on the top bar apply immediately (edit applied + fire).
  void quickToggleFreeDelivery() {
    _applied = _applied.copyWith(freeDelivery: !_applied.freeDelivery);
    apply(_applied);
  }

  void quickToggleWithin30Min() {
    _applied = _applied.copyWith(within30Min: !_applied.within30Min);
    apply(_applied);
  }

  void quickToggleHasOffers() {
    _applied = _applied.copyWith(hasOffers: !_applied.hasOffers);
    apply(_applied);
  }

  void quickToggleIsNew() {
    _applied = _applied.copyWith(isNew: !_applied.isNew);
    apply(_applied);
  }

  int get draftActiveCount => _draft.activeFiltersCount;

  /// Commit the draft (or a provided filter) as applied and notify the host.
  void apply([RestaurantFilterModel? filter]) {
    _applied = (filter ?? _draft).copyWith();
    update();
    onApply?.call(_applied);
  }

  /// "حذف الكل" — reset filters (keeps the current sort).
  void clearAllFilters() {
    _draft = RestaurantFilterModel(sortBy: _draft.sortBy);
    update();
  }

  /// Full reset (filters + sort) and notify.
  void resetAll() {
    _applied = RestaurantFilterModel();
    _draft = RestaurantFilterModel();
    update();
    onApply?.call(_applied);
  }
}
