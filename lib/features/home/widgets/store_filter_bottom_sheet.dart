/// Modern Store Filter Bottom Sheet
///
/// Beautiful, animated bottom sheet with comprehensive filtering options
/// Features smooth animations, gradient accents, and intuitive UX
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/features/category/domain/models/category_model.dart';
import 'package:sixam_mart/util/design_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class StoreFilterBottomSheet extends StatefulWidget {
  final StoreController storeController;
  final Function(Map<String, dynamic> filters)? onApply;

  const StoreFilterBottomSheet({
    super.key,
    required this.storeController,
    this.onApply,
  });

  @override
  State<StoreFilterBottomSheet> createState() => _StoreFilterBottomSheetState();
}

class _StoreFilterBottomSheetState extends State<StoreFilterBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Filter states
  String? _selectedSort;
  int? _minRating; // 4 = 4+, 45 = 4.5+
  bool _openNow = false;
  bool _freeDelivery = false;
  bool _hasDiscount = false;
  bool _featuredOnly = false;
  double? _maxDeliveryTime; // in minutes
  double? _maxMinOrder;
  List<int> _selectedCategoryIds = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCurrentFilters();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: DesignTokens.animationMedium,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: DesignTokens.curveEaseOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: DesignTokens.curveEaseOutCubic,
      ),
    );

    _animationController.forward();
  }

  void _loadCurrentFilters() {
    // Load current filter state from controller
    // This will be implemented when controller state is added
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _selectedSort = null;
      _minRating = null;
      _openNow = false;
      _freeDelivery = false;
      _hasDiscount = false;
      _featuredOnly = false;
      _maxDeliveryTime = null;
      _maxMinOrder = null;
      _selectedCategoryIds = [];
    });
  }

  Map<String, dynamic> _getActiveFilters() {
    return {
      'sort': _selectedSort,
      'minRating': _minRating,
      'openNow': _openNow,
      'freeDelivery': _freeDelivery,
      'hasDiscount': _hasDiscount,
      'featuredOnly': _featuredOnly,
      'maxDeliveryTime': _maxDeliveryTime,
      'maxMinOrder': _maxMinOrder,
      'categoryIds': _selectedCategoryIds,
    };
  }

  void _applyFilters() {
    if (widget.onApply != null) {
      widget.onApply!(_getActiveFilters());
    }
    Get.back();
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedSort != null) count++;
    if (_minRating != null) count++;
    if (_openNow) count++;
    if (_freeDelivery) count++;
    if (_hasDiscount) count++;
    if (_featuredOnly) count++;
    if (_maxDeliveryTime != null) count++;
    if (_maxMinOrder != null) count++;
    if (_selectedCategoryIds.isNotEmpty) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = _getActiveFilterCount() > 0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        minHeight: 400,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(DesignTokens.radiusExtraLarge),
        ),
        boxShadow: DesignTokens.shadowExtraStrong,
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              _buildDragHandle(),

              // Header
              _buildHeader(hasActiveFilters),

              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(DesignTokens.spaceDefault),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sort Section
                        _buildSortSection(),

                        const SizedBox(height: DesignTokens.spaceLarge),

                        // Quick Filters
                        _buildQuickFilters(),

                        const SizedBox(height: DesignTokens.spaceLarge),

                        // Rating Filter
                        _buildRatingFilter(),

                        const SizedBox(height: DesignTokens.spaceLarge),

                        // Delivery Time Filter
                        _buildDeliveryTimeFilter(),

                        const SizedBox(height: DesignTokens.spaceLarge),

                        // Category Filter
                        _buildCategoryFilter(),

                        const SizedBox(height: DesignTokens.spaceLarge),

                        // Minimum Order Filter
                        _buildMinOrderFilter(),

                        const SizedBox(height: DesignTokens.spaceHuge),
                      ],
                    ),
                  ),
                ),
              ),

              // Footer with Action Buttons
              _buildFooter(hasActiveFilters),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: DesignTokens.spaceMedium),
      height: 4,
      width: 40,
      decoration: BoxDecoration(
        color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
      ),
    );
  }

  Widget _buildHeader(bool hasActiveFilters) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spaceDefault,
        vertical: DesignTokens.spaceMedium,
      ),
      decoration: BoxDecoration(
        gradient: DesignTokens.headerGreenGradient,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.spaceSmall),
            decoration: BoxDecoration(
              gradient: DesignTokens.primaryGreenGradient,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
              boxShadow: DesignTokens.glowShadow(DesignTokens.primaryGreen),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: DesignTokens.spaceDefault),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'filter_stores'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: DesignTokens.textDark,
                  ),
                ),
                if (hasActiveFilters)
                  Text(
                    '$_getActiveFilterCount ${'filters_active'.tr}',
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: DesignTokens.primaryGreen,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.close_rounded,
              color: Theme.of(context).disabledColor,
            ),
            onPressed: () => Get.back(),
          ),
        ],
      ),
    );
  }

  Widget _buildSortSection() {
    return _buildSection(
      title: 'sort_by'.tr,
      icon: Icons.sort_rounded,
      child: Wrap(
        spacing: DesignTokens.spaceSmall,
        runSpacing: DesignTokens.spaceSmall,
        children: [
          _buildFilterChip(
            label: 'distance'.tr,
            icon: Icons.location_on_rounded,
            isSelected: _selectedSort == 'distance',
            onTap: () => setState(() => _selectedSort =
                _selectedSort == 'distance' ? null : 'distance'),
          ),
          _buildFilterChip(
            label: 'rating'.tr,
            icon: Icons.star_rounded,
            isSelected: _selectedSort == 'rating',
            onTap: () => setState(() =>
                _selectedSort = _selectedSort == 'rating' ? null : 'rating'),
          ),
          _buildFilterChip(
            label: 'delivery_time'.tr,
            icon: Icons.access_time_rounded,
            isSelected: _selectedSort == 'delivery_time',
            onTap: () => setState(() => _selectedSort =
                _selectedSort == 'delivery_time' ? null : 'delivery_time'),
          ),
          _buildFilterChip(
            label: 'minimum_order'.tr,
            icon: Icons.shopping_bag_rounded,
            isSelected: _selectedSort == 'min_order',
            onTap: () => setState(() => _selectedSort =
                _selectedSort == 'min_order' ? null : 'min_order'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return _buildSection(
      title: 'quick_filters'.tr,
      icon: Icons.flash_on_rounded,
      child: Wrap(
        spacing: DesignTokens.spaceSmall,
        runSpacing: DesignTokens.spaceSmall,
        children: [
          _buildToggleChip(
            label: 'open_now'.tr,
            icon: Icons.schedule_rounded,
            isSelected: _openNow,
            onTap: () => setState(() => _openNow = !_openNow),
          ),
          _buildToggleChip(
            label: 'free_delivery'.tr,
            icon: Icons.local_shipping_rounded,
            isSelected: _freeDelivery,
            onTap: () => setState(() => _freeDelivery = !_freeDelivery),
          ),
          _buildToggleChip(
            label: 'has_discount'.tr,
            icon: Icons.local_offer_rounded,
            isSelected: _hasDiscount,
            onTap: () => setState(() => _hasDiscount = !_hasDiscount),
          ),
          _buildToggleChip(
            label: 'featured_only'.tr,
            icon: Icons.star_border_rounded,
            isSelected: _featuredOnly,
            onTap: () => setState(() => _featuredOnly = !_featuredOnly),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingFilter() {
    return _buildSection(
      title: 'minimum_rating'.tr,
      icon: Icons.star_rate_rounded,
      child: Wrap(
        spacing: DesignTokens.spaceSmall,
        runSpacing: DesignTokens.spaceSmall,
        children: [
          _buildFilterChip(
            label: '4+ ⭐',
            icon: Icons.star_rounded,
            isSelected: _minRating == 4,
            onTap: () =>
                setState(() => _minRating = _minRating == 4 ? null : 4),
          ),
          _buildFilterChip(
            label: '4.5+ ⭐',
            icon: Icons.star_rounded,
            isSelected: _minRating == 45,
            onTap: () =>
                setState(() => _minRating = _minRating == 45 ? null : 45),
          ),
          _buildFilterChip(
            label: 'all_ratings'.tr,
            icon: Icons.star_outline_rounded,
            isSelected: _minRating == null,
            onTap: () => setState(() => _minRating = null),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryTimeFilter() {
    return _buildSection(
      title: 'delivery_time'.tr,
      icon: Icons.timer_rounded,
      child: Wrap(
        spacing: DesignTokens.spaceSmall,
        runSpacing: DesignTokens.spaceSmall,
        children: [
          _buildFilterChip(
            label: 'under_30_min'.tr,
            icon: Icons.hourglass_empty_rounded,
            isSelected: _maxDeliveryTime == 30,
            onTap: () => setState(
                () => _maxDeliveryTime = _maxDeliveryTime == 30 ? null : 30),
          ),
          _buildFilterChip(
            label: '30_60_min'.tr,
            icon: Icons.hourglass_bottom_rounded,
            isSelected: _maxDeliveryTime == 60,
            onTap: () => setState(
                () => _maxDeliveryTime = _maxDeliveryTime == 60 ? null : 60),
          ),
          _buildFilterChip(
            label: 'any_time'.tr,
            icon: Icons.hourglass_full_rounded,
            isSelected: _maxDeliveryTime == null,
            onTap: () => setState(() => _maxDeliveryTime = null),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categoryController = Get.find<CategoryController>();
    final categories = categoryController.categoryList ?? [];

    if (categories.isEmpty) return const SizedBox.shrink();

    return _buildSection(
      title: 'categories'.tr,
      icon: Icons.category_rounded,
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = _selectedCategoryIds.contains(category.id);

            return Padding(
              padding: EdgeInsets.only(
                right:
                    index < categories.length - 1 ? DesignTokens.spaceSmall : 0,
              ),
              child: _buildCategoryChip(
                category: category,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCategoryIds.remove(category.id);
                    } else {
                      _selectedCategoryIds.add(category.id!);
                    }
                  });
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMinOrderFilter() {
    return _buildSection(
      title: 'minimum_order'.tr,
      icon: Icons.attach_money_rounded,
      child: Wrap(
        spacing: DesignTokens.spaceSmall,
        runSpacing: DesignTokens.spaceSmall,
        children: [
          _buildFilterChip(
            label: 'under_10'.tr,
            icon: Icons.shopping_cart_rounded,
            isSelected: _maxMinOrder == 10,
            onTap: () =>
                setState(() => _maxMinOrder = _maxMinOrder == 10 ? null : 10),
          ),
          _buildFilterChip(
            label: '10_25'.tr,
            icon: Icons.shopping_cart_rounded,
            isSelected: _maxMinOrder == 25,
            onTap: () =>
                setState(() => _maxMinOrder = _maxMinOrder == 25 ? null : 25),
          ),
          _buildFilterChip(
            label: '25_50'.tr,
            icon: Icons.shopping_cart_rounded,
            isSelected: _maxMinOrder == 50,
            onTap: () =>
                setState(() => _maxMinOrder = _maxMinOrder == 50 ? null : 50),
          ),
          _buildFilterChip(
            label: 'any_amount'.tr,
            icon: Icons.shopping_cart_outlined,
            isSelected: _maxMinOrder == null,
            onTap: () => setState(() => _maxMinOrder = null),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: DesignTokens.primaryGreen),
            const SizedBox(width: DesignTokens.spaceSmall),
            Text(
              title,
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: DesignTokens.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spaceDefault),
        child,
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: DesignTokens.animationDefault,
      curve: DesignTokens.curveEaseOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusDefault),
          child: AnimatedContainer(
            duration: DesignTokens.animationDefault,
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceDefault,
              vertical: DesignTokens.spaceSmall,
            ),
            decoration: BoxDecoration(
              gradient: isSelected ? DesignTokens.primaryGreenGradient : null,
              color: isSelected ? null : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(DesignTokens.radiusDefault),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : Theme.of(context).dividerColor,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? DesignTokens.glowShadow(DesignTokens.primaryGreen)
                  : DesignTokens.shadowSubtle,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? Colors.white : DesignTokens.primaryGreen,
                ),
                const SizedBox(width: DesignTokens.spaceSmall),
                Text(
                  label,
                  style: robotoMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: isSelected ? Colors.white : DesignTokens.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return _buildFilterChip(
      label: label,
      icon: icon,
      isSelected: isSelected,
      onTap: onTap,
    );
  }

  Widget _buildCategoryChip({
    required CategoryModel category,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusDefault),
        child: AnimatedContainer(
          duration: DesignTokens.animationDefault,
          padding: const EdgeInsets.all(DesignTokens.spaceDefault),
          decoration: BoxDecoration(
            gradient: isSelected ? DesignTokens.primaryGreenGradient : null,
            color: isSelected ? null : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(DesignTokens.radiusDefault),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : Theme.of(context).dividerColor,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? DesignTokens.glowShadow(DesignTokens.primaryGreen)
                : DesignTokens.shadowSubtle,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (category.image != null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusSmall),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(category.image!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: DesignTokens.spaceSmall),
              Text(
                category.name ?? '',
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall,
                  color: isSelected ? Colors.white : DesignTokens.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool hasActiveFilters) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spaceDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: hasActiveFilters ? _resetFilters : null,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: DesignTokens.spaceDefault,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusDefault),
                ),
                side: BorderSide(
                  color: hasActiveFilters
                      ? DesignTokens.primaryGreen
                      : Theme.of(context).dividerColor,
                ),
              ),
              child: Text(
                'reset'.tr,
                style: robotoMedium.copyWith(
                  color: hasActiveFilters
                      ? DesignTokens.primaryGreen
                      : Theme.of(context).disabledColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spaceDefault),
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                gradient: DesignTokens.primaryGreenGradient,
                borderRadius: BorderRadius.circular(DesignTokens.radiusDefault),
                boxShadow: DesignTokens.glowShadow(DesignTokens.primaryGreen),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _applyFilters,
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusDefault),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: DesignTokens.spaceDefault,
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'apply_filters'.tr,
                          style: robotoBold.copyWith(
                            color: Colors.white,
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                        ),
                        if (hasActiveFilters) ...[
                          const SizedBox(width: DesignTokens.spaceSmall),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.spaceSmall,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusFull),
                            ),
                            child: Text(
                              '$_getActiveFilterCount',
                              style: robotoBold.copyWith(
                                color: Colors.white,
                                fontSize: Dimensions.fontSizeExtraSmall,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
