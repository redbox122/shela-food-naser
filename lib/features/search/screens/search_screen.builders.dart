part of 'search_screen.dart';
// ignore_for_file: invalid_use_of_protected_member

/// Widget builders for [SearchScreenState], split out to keep the main
/// screen file small. Part of the same library → full private access.
extension _SearchScreenBuilders on SearchScreenState {
  // Removed: _SearchHeader() - No longer used after redesign

  /// Module chips section for filtering by module
  Widget _ModuleChipsSection() {
    return GetBuilder<SplashController>(
      id: 'moduleList',
      builder: (splashController) {
        final moduleList =
            List<ModuleModel>.from(splashController.moduleList ?? []);
        moduleList.sort((a, b) {
          final int p =
              _moduleSortPriority(a).compareTo(_moduleSortPriority(b));
          if (p != 0) return p;
          return (a.id ?? 0).compareTo(b.id ?? 0);
        });
        final currentModule = splashController.module;

        // Don't show if less than 2 modules
        if (moduleList.length < 2) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 68,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: moduleList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final module = moduleList[index];
                  final isActive =
                      currentModule != null && module.id == currentModule.id;
                  final bool isComingSoon = _isComingSoonModule(module);
                  if (isComingSoon &&
                      module.id != null &&
                      !_loggedComingSoonModules.contains(module.id!)) {
                    _loggedComingSoonModules.add(module.id!);
                    debugPrint(
                        '[Search][COMING_SOON_MODULE_SHOWN] moduleId=${module.id} name=${module.moduleName ?? ''}');
                  }

                  return _ModuleChip(
                    module: module,
                    isActive: isActive,
                    isComingSoon: isComingSoon,
                    onTap: () async {
                      if (isComingSoon) {
                        debugPrint(
                            '[Search][COMING_SOON_MODULE_TAP_BLOCKED] moduleId=${module.id ?? 'null'} name=${module.moduleName ?? ''}');
                        Get.rawSnackbar(message: 'قريبًا');
                        return;
                      }
                      if (!isActive) {
                        if (_isRestaurantModule(module)) {
                          debugPrint('[SEARCH_TAB_TAP_RESTAURANTS]');
                        }
                        await _handleModuleSwitch(module);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  /// Individual module chip widget - clean minimal design
  Widget _ModuleChip({
    required ModuleModel module,
    required bool isActive,
    required bool isComingSoon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>()!;
    if (isComingSoon) {
      return SizedBox(
        width: 150,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: tokens.surfaceSoft,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  module.moduleName ?? '',
                  style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: theme.disabledColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CustomImage(
                      image: module.iconFullUrl ?? '',
                      width: 22,
                      height: 22,
                      placeholder: Images.placeholder,
                    ),
                  ),
                  Positioned(
                    left: 2,
                    right: 2,
                    bottom: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.inverseSurface,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'coming_soon'.tr,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.onInverseSurface,
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 150,
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  CustomImage(
                    image: module.iconFullUrl ?? '',
                    width: 24,
                    height: 24,
                    placeholder: Images.placeholder,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      module.moduleName ?? '',
                      style: TextStyle(
                        color: isActive
                            ? theme.primaryColor
                            : theme.textTheme.bodyMedium?.color,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (isActive) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 2,
                    width: 34,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Removed: _LocationSection() - No longer used after redesign

  /// Search input field with magnifying glass, clear button, back button, and focus animations
  Widget _SearchInputField(search.SearchController searchController) {
    final isRtl = Get.locale?.languageCode == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            // Back button (on right for RTL, left for LTR)
            if (isRtl) ...[
              Expanded(
                child: AnimatedBuilder(
                  animation: _focusAnimationController,
                  builder: (context, child) {
                    final isFocused = _searchFocusNode.hasFocus;
                    return Transform.scale(
                      scale: _focusScaleAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusDefault),
                          boxShadow: isFocused
                              ? DesignTokens.glowShadow(
                                  DesignTokens.primaryGreen)
                              : DesignTokens.shadowMedium,
                        ),
                        child: TextField(
                          controller: _SearchController,
                          focusNode: _searchFocusNode,
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: DesignTokens.textDark,
                            letterSpacing: -0.2,
                          ),
                          onChanged: (text) {
                            if (_isSyncingSearchText) return;
                            _searchSuggestions(text);
                            searchController.setSearchText(text);
                            if (text.trim().isEmpty) {
                              _liveSearchTimer?.cancel();
                              _handleQueryClear();
                            } else {
                              _scheduleLiveSearch(text, searchController);
                            }
                            setState(() {});
                          },
                          onSubmitted: (text) {
                            _showSuggestion = false;
                            if (text.isNotEmpty) {
                              debugPrint(
                                  '[SEARCH_QUERY_SUBMIT] query=$text selectedType=${searchController.isStore ? 'stores' : 'items'}');
                              _actionSearch(searchController.isStore, text, false);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'search_hint'.tr,
                            hintStyle: const TextStyle(
                              color: DesignTokens.textLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.2,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: DesignTokens.secondaryOrange,
                              size: 22,
                            ),
                            suffixIcon: _SearchController.text.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _SearchController.clear();
                                      _showSuggestion = false;
                                      if (_isSyncingSearchText) return;
                                      _handleQueryClear();
                                      setState(() {});
                                    },
                                    icon: const Icon(
                                      Icons.clear,
                                      color: DesignTokens.textLight,
                                      size: 20,
                                    ),
                                  )
                                : null,
                            filled: true,
                            fillColor: DesignTokens.primaryGreen
                                .withValues(alpha: 0.1),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.spaceDefault,
                              vertical: DesignTokens.spaceSmall + 2,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusDefault),
                              borderSide: BorderSide(
                                color: DesignTokens.primaryGreen
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusDefault),
                              borderSide: BorderSide(
                                color: DesignTokens.primaryGreen
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusDefault),
                              borderSide: const BorderSide(
                                color: DesignTokens.primaryGreen,
                                width: DesignTokens.borderMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: DesignTokens.spaceSmall),
              // Back button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                  child: Container(
                    width: DesignTokens.minTouchTarget,
                    height: DesignTokens.minTouchTarget,
                    decoration: BoxDecoration(
                      color: DesignTokens.cardBackground,
                      shape: BoxShape.circle,
                      boxShadow: DesignTokens.shadowSubtle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: DesignTokens.textDark,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Back button (LTR)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                  child: Container(
                    width: DesignTokens.minTouchTarget,
                    height: DesignTokens.minTouchTarget,
                    decoration: BoxDecoration(
                      color: DesignTokens.cardBackground,
                      shape: BoxShape.circle,
                      boxShadow: DesignTokens.shadowSubtle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: DesignTokens.textDark,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.spaceSmall),
              Expanded(
                child: AnimatedBuilder(
                  animation: _focusAnimationController,
                  builder: (context, child) {
                    final isFocused = _searchFocusNode.hasFocus;
                    return Transform.scale(
                      scale: _focusScaleAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusDefault),
                          boxShadow: isFocused
                              ? DesignTokens.glowShadow(
                                  DesignTokens.primaryGreen)
                              : DesignTokens.shadowMedium,
                        ),
                        child: TextField(
                          controller: _SearchController,
                          focusNode: _searchFocusNode,
                          textAlignVertical: TextAlignVertical.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: DesignTokens.textDark,
                            letterSpacing: -0.2,
                          ),
                          onChanged: (text) {
                            if (_isSyncingSearchText) return;
                            _searchSuggestions(text);
                            searchController.setSearchText(text);
                            if (text.trim().isEmpty) {
                              _liveSearchTimer?.cancel();
                              _handleQueryClear();
                            } else {
                              _scheduleLiveSearch(text, searchController);
                            }
                            setState(() {});
                          },
                          onSubmitted: (text) {
                            _showSuggestion = false;
                            if (text.isNotEmpty) {
                              debugPrint(
                                  '[SEARCH_QUERY_SUBMIT] query=$text selectedType=${searchController.isStore ? 'stores' : 'items'}');
                              _actionSearch(searchController.isStore, text, false);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'search_hint'.tr,
                            hintStyle: const TextStyle(
                              color: DesignTokens.textLight,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.2,
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: DesignTokens.secondaryOrange,
                              size: 22,
                            ),
                            suffixIcon: _SearchController.text.isNotEmpty
                                ? IconButton(
                                    onPressed: () {
                                      _SearchController.clear();
                                      _showSuggestion = false;
                                      if (_isSyncingSearchText) return;
                                      _handleQueryClear();
                                      setState(() {});
                                    },
                                    icon: const Icon(
                                      Icons.clear,
                                      color: DesignTokens.textLight,
                                      size: 20,
                                    ),
                                  )
                                : null,
                            filled: true,
                            fillColor: DesignTokens.primaryGreen
                                .withValues(alpha: 0.1),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: DesignTokens.spaceDefault,
                              vertical: DesignTokens.spaceSmall + 2,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusDefault),
                              borderSide: BorderSide(
                                color: DesignTokens.primaryGreen
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusDefault),
                              borderSide: BorderSide(
                                color: DesignTokens.primaryGreen
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                  DesignTokens.radiusDefault),
                              borderSide: const BorderSide(
                                color: DesignTokens.primaryGreen,
                                width: DesignTokens.borderMedium,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
        // Suggestions dropdown - hidden when search is active to prevent list under search bar
        if (_showSuggestion &&
            _SearchController.text.isNotEmpty &&
            !searchController.isSearchMode)
          SearchSuggestionsDropdown(
            suggestionModel: searchController.searchSuggestionModel,
            isLoading: _isLoadingSuggestions,
            onSuggestionTap: (name, isStore, id) {
              _SearchController.text = name;
              searchController.setSearchText(name);
              _showSuggestion = false;
              _actionSearch(isStore, name, false);
              setState(() {});
            },
          ),
      ],
    );
  }

  /// Category tabs for filtering search results (Stores vs Items, or Items vs Categories for Module 3)
  Widget _SearchCategoryTabs() {
    return GetBuilder<SplashController>(
      builder: (splashController) {
        return GetBuilder<search.SearchController>(
          builder: (searchController) {
            final isStoreTab = searchController.isStore;
            final isEcommerce =
                splashController.module?.moduleType == 'ecommerce';

            return Row(
              children: [
                // First tab: Items/Products (or Items for ecommerce)
                Expanded(
                  child: InkWell(
                    onTap: () {
                      // Just switch the tab, data is already loaded
                      _switchTab(false);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            isEcommerce ? 'item'.tr : 'item'.tr,
                            style: TextStyle(
                              color: (isEcommerce ? !isStoreTab : !isStoreTab)
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        if (isEcommerce ? !isStoreTab : !isStoreTab)
                          Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Second tab: All Stores (or Categories for ecommerce)
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (isEcommerce) {
                        // For ecommerce: Categories tab - navigate to categories
                        Get.toNamed(RouteHelper.getCategoryRoute());
                      } else {
                        // For other modules: All Stores tab - just switch, data is already loaded
                        _switchTab(true);
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            isEcommerce
                                ? 'categories'.tr
                                : (splashController.configModel!.moduleConfig!
                                        .module!.showRestaurantText!
                                    ? 'restaurants'.tr
                                    : 'stores'.tr),
                            style: TextStyle(
                              color: (isEcommerce ? false : isStoreTab)
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.1,
                            ),
                          ),
                        ),
                        // Categories tab never shows underline (it's a navigation)
                        if (!isEcommerce && isStoreTab)
                          Container(
                            height: 2,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Category tabs for quick filters (navigation)
  Widget _CategoryTabs() {
    return SizedBox(
      height: DesignTokens.minTouchTarget,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (_, i) {
          final tabs = [
            'restaurant_categories'.tr,
            'restaurants_and_stores'.tr,
            'store_categories'.tr,
          ];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                switch (i) {
                  case 0: // Restaurant Categories
                    Get.toNamed(RouteHelper.getCategoryRoute());
                    break;
                  case 1: // Restaurants & Stores
                    Get.toNamed(RouteHelper.getAllStoreRoute('all'));
                    break;
                  case 2: // Store Categories
                    Get.toNamed(RouteHelper.getCategoryRoute());
                    break;
                }
              },
              borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DesignTokens.spaceDefault,
                  vertical: DesignTokens.spaceSmall,
                ),
                decoration: BoxDecoration(
                  gradient: DesignTokens.headerGreenGradient,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusFull),
                  boxShadow: DesignTokens.shadowSubtle,
                ),
                child: Center(
                  child: Text(
                    tabs[i],
                    style: const TextStyle(
                      color: DesignTokens.textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, __) =>
            const SizedBox(width: DesignTokens.spaceSmall),
        itemCount: 3,
      ),
    );
  }

  /// Recent searches section
  Widget _RecentSearchesSection(search.SearchController searchController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'previously_searched_for'.tr,
          style: const TextStyle(
            color: DesignTokens.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: DesignTokens.spaceSmall),

        // Recent search items
        if (searchController.isLoadingHistory) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.spaceDefault),
              child: CircularProgressIndicator(
                color: DesignTokens.primaryGreen,
              ),
            ),
          ),
        ] else if (searchController.historyList.isNotEmpty) ...[
          for (int i = 0;
              i < searchController.historyList.length && i < 3;
              i++) ...[
            _RecentSearchRow(
              text: searchController.historyList[i],
              onDelete: () => searchController.removeHistory(i),
              onTap: () => _actionSearch(
                  searchController.isStore, searchController.historyList[i], false),
            ),
            if (i < 2) const SizedBox(height: DesignTokens.spaceSmall),
          ],
        ] else ...[
          // Default recent searches if no history
          _RecentSearchRow(
            text: 'offers_and_discounts'.tr,
            onDelete: () {},
            onTap: () => _actionSearch(
                searchController.isStore, 'offers_and_discounts'.tr, false),
          ),
          const SizedBox(height: DesignTokens.spaceSmall),
          _RecentSearchRow(
            text: 'drinks'.tr,
            onDelete: () {},
            onTap: () =>
                _actionSearch(searchController.isStore, 'drinks'.tr, false),
          ),
          const SizedBox(height: DesignTokens.spaceSmall),
          _RecentSearchRow(
            text: 'market'.tr,
            onDelete: () {},
            onTap: () =>
                _actionSearch(searchController.isStore, 'market'.tr, false),
          ),
        ],
      ],
    );
  }

  /// A single recent search row
  Widget _RecentSearchRow({
    required String text,
    required VoidCallback onDelete,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spaceDefault,
            vertical: DesignTokens.spaceMedium,
          ),
          decoration: BoxDecoration(
            color: DesignTokens.cardBackground,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            boxShadow: DesignTokens.shadowSubtle,
            border: Border.all(
              color: DesignTokens.divider,
            ),
          ),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.close,
                      color: DesignTokens.textLight,
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.spaceSmall),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: DesignTokens.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const Icon(
                Icons.search,
                color: DesignTokens.secondaryOrange,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Most searched section with product grid
  Widget _MostSearchedSection(search.SearchController searchController) {
    final bool hasTrendingData =
        (searchController.trendingCategoryList?.isNotEmpty ?? false);
    final bool hasPopularData =
        (searchController.popularCategoryList?.isNotEmpty ?? false);
    final bool isFallbackStale =
        searchController.fallbackCategoriesModuleId != null &&
            _selectedSearchModuleId != null &&
            searchController.fallbackCategoriesModuleId !=
                _selectedSearchModuleId;
    if (isFallbackStale) {
      debugPrint(
          '[Search][FALLBACK_BLOCKED_STALE] activeModuleId=${_selectedSearchModuleId ?? 'null'} fallbackModuleId=${searchController.fallbackCategoriesModuleId ?? 'null'}');
    }
    final bool hasFallbackData =
        !isFallbackStale &&
            searchController.discoveryFallbackCategories.isNotEmpty;
    final bool hasAnyLoading = searchController.isLoadingTrendingCategories ||
        searchController.isLoadingPopularCategories;
    final bool hasAnyError = searchController.hasTrendingCategoriesError ||
        searchController.hasPopularCategoriesError;
    if (!hasAnyLoading &&
        !hasAnyError &&
        !hasTrendingData &&
        !hasPopularData &&
        !hasFallbackData) {
      debugPrint(
          '[Search][SECTION_EMPTY] type=most_searched moduleId=${searchController.activeModuleId ?? 'null'}');
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trending Categories (Last 24 Hours)
        if (searchController.isLoadingTrendingCategories) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.spaceDefault),
              child: CircularProgressIndicator(
                color: DesignTokens.secondaryOrange,
              ),
            ),
          ),
          const SizedBox(height: DesignTokens.spaceLarge),
        ] else if (searchController.trendingCategoryList != null &&
            searchController.trendingCategoryList!.isNotEmpty) ...[
          Row(
            children: [
              const Icon(
                Icons.trending_up,
                color: DesignTokens.secondaryOrange,
                size: 20,
              ),
              const SizedBox(width: DesignTokens.spaceSmall),
              Text(
                'trending_last_24h'.tr,
                style: const TextStyle(
                  color: DesignTokens.secondaryOrange,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceSmall),

          // Trending categories grid
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, i) {
                final category = searchController.trendingCategoryList![i]!;
                return _TrendingCategoryTile(
                  category: category,
                  onTap: () {
                    Get.toNamed(RouteHelper.getCategoryItemRoute(
                        category.id, category.name ?? 'Category'));
                  },
                );
              },
              separatorBuilder: (_, __) =>
                  const SizedBox(width: DesignTokens.spaceMedium),
              itemCount: searchController.trendingCategoryList!.length > 5
                  ? 5
                  : searchController.trendingCategoryList!.length,
            ),
          ),
          const SizedBox(height: DesignTokens.spaceLarge),
        ] else if (searchController.hasTrendingCategoriesError) ...[
          ErrorStateView(
            onRetry: () {
              searchController.getTrendingCategories();
            },
          ),
          const SizedBox(height: DesignTokens.spaceLarge),
        ] else ...[
          const SizedBox.shrink(),
        ],

        if (hasPopularData || hasFallbackData) ...[
          Text(
            'most_searched'.tr,
            style: const TextStyle(
              color: DesignTokens.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: DesignTokens.spaceDefault),
        ],

        // Product tiles - only show if API returns data
        if (searchController.isLoadingPopularCategories) ...[
          const Center(
            child: Padding(
              padding: EdgeInsets.all(DesignTokens.spaceDefault),
              child: CircularProgressIndicator(
                color: DesignTokens.primaryGreen,
              ),
            ),
          ),
        ] else if (searchController.popularCategoryList != null &&
            searchController.popularCategoryList!.isNotEmpty) ...[
          for (int i = 0;
              i < searchController.popularCategoryList!.length && i < 5;
              i++) ...[
            _MostSearchedTile(
              category: searchController.popularCategoryList![i]!,
              onTap: () {
                // Navigate to category items
                Get.toNamed(RouteHelper.getCategoryItemRoute(
                    searchController.popularCategoryList![i]!.id,
                    searchController.popularCategoryList![i]!.name ??
                        'Category'));
              },
            ),
            const SizedBox(height: DesignTokens.spaceMedium),
          ],
        ] else if (searchController.hasPopularCategoriesError) ...[
          ErrorStateView(
            onRetry: () {
              searchController.getPopularCategories();
            },
          ),
        ] else if (hasFallbackData) ...[
          for (int i = 0;
              i < searchController.discoveryFallbackCategories.length && i < 5;
              i++) ...[
            _MostSearchedTile(
              category: _CategoryTile(
                title:
                    searchController.discoveryFallbackCategories[i].name ?? '',
                image: searchController
                        .discoveryFallbackCategories[i].imageFullUrl ??
                    AppConstants.placeholderImageUrl,
                banner: false,
              ),
              onTap: () {
                final CategoryModel category =
                    searchController.discoveryFallbackCategories[i];
                if (category.id != null) {
                  Get.toNamed(RouteHelper.getCategoryItemRoute(
                      category.id, category.name ?? 'Category'));
                }
              },
            ),
            const SizedBox(height: DesignTokens.spaceMedium),
          ],
        ] else ...[
          const SizedBox.shrink(),
        ],
        // If empty, just don't show anything (no hardcoded defaults)
      ],
    );
  }

  /// Search results section - filtered by selected tab (Products vs Stores)
  Widget _SearchResultsSection(search.SearchController searchController) {
    final isStoreTab = searchController.isStore;
    if (!searchController.isLoading && searchController.hasError) {
      return ErrorStateView(
        onRetry: () {
          final String query = (searchController.searchText ?? '').trim();
          if (query.isNotEmpty) {
            searchController.searchData(query: query, fromHome: false);
          }
        },
      );
    }

    // ✅ Show beautiful loading indicator while searching
    if (searchController.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceLarge * 2),
        child: LoadingWidget(
          messageKey: 'bringing_great_products',
          showMessage: true,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isStoreTab) ...[
          // Show stores only
          if (searchController.searchStoreList != null &&
              searchController.searchStoreList!.isNotEmpty) ...[
            for (final store in searchController.searchStoreList!.take(20)) ...[
              _SearchResultItem(item: store, isStore: true),
              const SizedBox(height: DesignTokens.spaceSmall),
            ],
          ] else if (searchController.searchStoreList != null &&
              searchController.searchStoreList!.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceLarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'no_results_found'.tr,
                      style: const TextStyle(
                        color: DesignTokens.textLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'no_results_found_subtitle'.tr,
                      style: TextStyle(
                        color: DesignTokens.textLight.withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ] else ...[
          // Show stores with their items (grouped by store)
          _StoresWithItemsView(searchController),
        ],
      ],
    );
  }

  /// Widget to display stores with their items in a compact grid
  Widget _StoresWithItemsView(search.SearchController searchController) {
    final String currentQuery = searchController.searchText ?? '';
    if (_lastSearchResultsQuery != currentQuery) {
      _lastSearchResultsQuery = currentQuery;
      _storeVisibleItemCount.clear();
    }

    // ✅ Show beautiful loading indicator while searching
    if (searchController.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: DesignTokens.spaceLarge * 2),
        child: LoadingWidget(
          messageKey: 'bringing_great_products',
          showMessage: true,
        ),
      );
    }
    if (searchController.hasError) {
      return ErrorStateView(
        onRetry: () {
          final String query = (searchController.searchText ?? '').trim();
          if (query.isNotEmpty) {
            searchController.searchData(query: query, fromHome: false);
          }
        },
      );
    }

    if (searchController.searchItemList == null) {
      return const SizedBox.shrink();
    }

    if (searchController.searchItemList!.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'no_results_found'.tr,
                style: const TextStyle(
                  color: DesignTokens.textLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'no_results_found_subtitle'.tr,
                style: TextStyle(
                  color: DesignTokens.textLight.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Group items by storeId
    final Map<int, List<Item>> itemsByStore = {};
    final Map<int, Store?> storeMap = {};

    for (final item in searchController.searchItemList!) {
      if (item.storeId != null) {
        itemsByStore.putIfAbsent(item.storeId!, () => []).add(item);

        // Try to find store in searchStoreList
        if (searchController.searchStoreList != null) {
          final store = searchController.searchStoreList!.firstWhereOrNull(
            (s) => s.id == item.storeId,
          );
          if (store != null) {
            storeMap[item.storeId!] = store;
          }
        }
      }
    }

    if (itemsByStore.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'no_results_found'.tr,
                style: const TextStyle(
                  color: DesignTokens.textLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'no_results_found_subtitle'.tr,
                style: TextStyle(
                  color: DesignTokens.textLight.withValues(alpha: 0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in itemsByStore.entries.take(20)) ...[
          _StoreWithItemsCard(
            store: storeMap[entry.key],
            storeId: entry.key,
            storeName: entry.value.first.storeName ?? 'Store',
            items: entry.value,
          ),
          const SizedBox(height: DesignTokens.spaceMedium),
        ],
      ],
    );
  }

  /// Card showing a store with its items in a 2-column grid + more action
  Widget _StoreWithItemsCard({
    required Store? store,
    required int storeId,
    required String storeName,
    required List<Item> items,
  }) {
    final splashController = Get.find<SplashController>();
    final bool disableStoreNavigationInHyper =
        splashController.module?.moduleType == AppConstants.ecommerce ||
            splashController.module?.id == 3;
    final int visibleCount = _storeVisibleItemCount[storeId] ?? 6;
    final int itemCountToShow =
        visibleCount > items.length ? items.length : visibleCount;
    final bool hasMoreItems = itemCountToShow < items.length;

    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spaceSmall),
      decoration: BoxDecoration(
        color: DesignTokens.cardBackground,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        border: Border.all(
          color: DesignTokens.divider,
        ),
        boxShadow: DesignTokens.shadowMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store header
          InkWell(
            onTap: disableStoreNavigationInHyper
                ? null
                : () {
                    final int targetStoreId = store?.id ?? storeId;
                    if (targetStoreId > 0) {
                      Get.toNamed(RouteHelper.getStoreRoute(
                          id: targetStoreId, page: 'store'));
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceDefault),
              child: Row(
                children: [
                  // Store logo - ✅ FIX: Handle empty URL to prevent infinite shimmer loading
                  ClipRRect(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusSmall),
                    child: _buildStoreImage(store),
                  ),
                  const SizedBox(width: DesignTokens.spaceDefault),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          storeName,
                          style: const TextStyle(
                            color: DesignTokens.textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (store != null && store.distance != null) ...[
                          const SizedBox(height: DesignTokens.spaceExtraSmall),
                          Text(
                            '${store.distance!.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              color: DesignTokens.textLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: disableStoreNavigationInHyper
                        ? DesignTokens.divider
                        : DesignTokens.textLight,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceDefault,
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCountToShow,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: DesignTokens.spaceSmall,
                mainAxisSpacing: DesignTokens.spaceSmall,
                childAspectRatio: 0.88,
              ),
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  onTap: () {
                    Get.find<ItemController>().navigateToItemPage(
                      item,
                      context,
                    );
                  },
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                  child: Container(
                    padding: const EdgeInsets.all(DesignTokens.spaceExtraSmall),
                    decoration: BoxDecoration(
                      color: DesignTokens.cardBackground,
                      borderRadius:
                          BorderRadius.circular(DesignTokens.radiusSmall),
                      border: Border.all(color: DesignTokens.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusSmall),
                          child: SmartImage(
                            url: item.imageFullUrl ?? '',
                            width: double.infinity,
                            height: 88,
                            cacheWidth: 300,
                            cacheHeight: 300,
                            fit: BoxFit.cover,
                            errorWidget: Container(
                              width: double.infinity,
                              height: 88,
                              color: DesignTokens.divider,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: DesignTokens.textLight,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spaceExtraSmall),
                        Expanded(
                          child: Text(
                            item.name ?? '',
                            style: const TextStyle(
                              color: DesignTokens.textDark,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.1,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${item.price ?? 0} ${'currency'.tr}',
                          style: const TextStyle(
                            color: DesignTokens.secondaryOrange,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (hasMoreItems)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _storeVisibleItemCount[storeId] = itemCountToShow + 6;
                  });
                },
                child: Text('more'.tr),
              ),
            ),
        ],
      ),
    );
  }

  /// ✅ FIX: Build store image with proper handling for null/empty URLs
  /// When store is null or has no logo URL, shows placeholder icon immediately
  /// instead of infinite shimmer loading
  Widget _buildStoreImage(Store? store) {
    final String? imageUrl = store?.logoFullUrl ?? store?.coverPhotoFullUrl;

    // If no valid URL, show placeholder directly (no shimmer loading)
    if (imageUrl == null || imageUrl.isEmpty || imageUrl.trim().isEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: DesignTokens.divider,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        ),
        child: const Icon(
          Icons.store,
          color: DesignTokens.textLight,
          size: 24,
        ),
      );
    }

    // Valid URL - use SmartImage with proper error handling
    return SmartImage(
      url: imageUrl,
      width: 50,
      height: 50,
      cacheWidth: 300,
      cacheHeight: 300,
      fit: BoxFit.cover,
      errorWidget: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: DesignTokens.divider,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        ),
        child: const Icon(
          Icons.store,
          color: DesignTokens.textLight,
          size: 24,
        ),
      ),
    );
  }

  /// Trending category tile (horizontal scroll)
  Widget _TrendingCategoryTile({
    required PopularCategoryModel category,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        child: Container(
          width: 100,
          decoration: BoxDecoration(
            color: DesignTokens.cardBackground,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            border: Border.all(
              color: DesignTokens.divider,
            ),
            boxShadow: DesignTokens.shadowMedium,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(DesignTokens.radiusMedium),
                ),
                child: Stack(
                  children: [
                    SmartImage(
                      url: category.imageFullUrl ??
                          AppConstants.placeholderImageUrl,
                      width: 100,
                      height: 70,
                      cacheWidth: 300,
                      cacheHeight: 300,
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        width: 100,
                        height: 70,
                        color: DesignTokens.divider,
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 24,
                          color: DesignTokens.textLight,
                        ),
                      ),
                    ),
                    // Gradient overlay for better text readability
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: DesignTokens.imageOverlayGradient,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: DesignTokens.spaceSmall),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: DesignTokens.spaceSmall),
                child: Text(
                  category.name ?? 'Category',
                  style: const TextStyle(
                    color: DesignTokens.textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Individual search result item
  Widget _SearchResultItem({required dynamic item, required bool isStore}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (isStore) {
            Get.toNamed(RouteHelper.getStoreRoute(
                id: (item.id is int?
                    ? item.id
                    : (item.id != null
                        ? int.tryParse(item.id.toString())
                        : null)) as int?,
                page: 'store'));
          } else {
            Get.toNamed(RouteHelper.getItemDetailsRoute(
                (item.id is int?
                    ? item.id
                    : (item.id != null
                        ? int.tryParse(item.id.toString())
                        : null)) as int?,
                false));
          }
        },
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(DesignTokens.spaceMedium),
          decoration: BoxDecoration(
            color: DesignTokens.cardBackground,
            border: Border.all(
              color: DesignTokens.divider,
            ),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            boxShadow: DesignTokens.shadowMedium,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                child: SmartImage(
                  url: (isStore
                      ? (item.logoFullUrl ??
                          item.imageFullUrl ??
                          AppConstants.placeholderImageUrl60)
                      : (item.imageFullUrl ??
                          AppConstants.placeholderImageUrl60)) as String,
                  width: 64,
                  height: 64,
                  cacheWidth: 300,
                  cacheHeight: 300,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    width: 64,
                    height: 64,
                    color: DesignTokens.divider,
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 24,
                      color: DesignTokens.textLight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.spaceMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (item.name ?? (isStore ? 'Store Name' : 'Item Name'))
                          as String,
                      style: const TextStyle(
                        color: DesignTokens.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isStore && item.price != null) ...[
                      const SizedBox(height: DesignTokens.spaceExtraSmall),
                      Text(
                        '${item.price} ${'currency'.tr}',
                        style: const TextStyle(
                          color: DesignTokens.secondaryOrange,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    if (isStore &&
                        item.avgRating != null &&
                        (item.avgRating is num &&
                            (item.avgRating as num) > 0)) ...[
                      const SizedBox(height: DesignTokens.spaceExtraSmall),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: DesignTokens.secondaryOrange,
                            size: 16,
                          ),
                          const SizedBox(width: DesignTokens.spaceExtraSmall),
                          Text(
                            (item.avgRating is num
                                ? (item.avgRating as num).toStringAsFixed(1)
                                : '0.0'),
                            style: const TextStyle(
                              color: DesignTokens.textDark,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (item.ratingCount != null &&
                              (item.ratingCount is num &&
                                  (item.ratingCount as num) > 0)) ...[
                            const SizedBox(width: DesignTokens.spaceExtraSmall),
                            Text(
                              '(${item.ratingCount})',
                              style: const TextStyle(
                                color: DesignTokens.textLight,
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: DesignTokens.textLight,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _DiscoveryEmptyState(search.SearchController searchController) {
    final bool hasQuery = (searchController.searchText ?? '').trim().isNotEmpty;
    if (hasQuery) {
      return const SizedBox.shrink();
    }
    final bool anyLoading = searchController.isLoadingHistory ||
        searchController.isLoadingSuggestedItems ||
        searchController.isLoadingPopularCategories ||
        searchController.isLoadingTrendingCategories ||
        searchController.isLoading;
    final bool hasDiscoveryData = searchController.historyList.isNotEmpty ||
        (searchController.popularCategoryList?.isNotEmpty ?? false) ||
        (searchController.trendingCategoryList?.isNotEmpty ?? false) ||
        (searchController.suggestedItemList?.isNotEmpty ?? false) ||
        searchController.discoveryFallbackCategories.isNotEmpty;
    if (anyLoading || hasDiscoveryData) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceLarge),
      child: Text(
        'لا توجد بيانات حالياً',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: DesignTokens.textLight,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Home indicator bar
  Widget _HomeIndicator() {
    return Center(
      child: Container(
        width: 80,
        height: 4,
        decoration: BoxDecoration(
          color: DesignTokens.textLight.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
        ),
      ),
    );
  }
}

/// Data for "most searched" tiles
class _CategoryTile {
  final String title;
  final String image;
  final bool banner;

  _CategoryTile({
    required this.title,
    required this.image,
    required this.banner, // ✅ أضفناه
  });
}

/// Visual card used for each entry in the "most searched" list
class _MostSearchedTile extends StatelessWidget {
  final dynamic category;
  final VoidCallback? onTap;

  const _MostSearchedTile({
    this.category,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(DesignTokens.radiusDefault);

    // Use category data if available, otherwise use default tile
    final tile = category is _CategoryTile
        ? category
        : _CategoryTile(
            title: (category?.name ?? 'Category') as String,
            image: (category?.imageFullUrl ?? AppConstants.placeholderImageUrl)
                as String,
            banner: false, // ✅ الحل
          );

    final img = ClipRRect(
      borderRadius: radius,
      child: AspectRatio(
        aspectRatio: (tile.banner is bool && tile.banner == true) ? 16 / 6 : 1,
        child: SmartImage(
          url: tile.image as String,
          cacheWidth: (tile.banner is bool && tile.banner == true) ? 800 : 300,
          cacheHeight: (tile.banner is bool && tile.banner == true) ? 800 : 300,
          fit: BoxFit.cover,
          errorWidget: Container(
            color: DesignTokens.divider,
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                color: DesignTokens.textLight,
              ),
            ),
          ),
        ),
      ),
    );

    if (tile.banner is bool && tile.banner == true) {
      // Full-width banner with label on the left
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: DesignTokens.shadowMedium,
            ),
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                img,
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: radius,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.scrim.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: DesignTokens.spaceDefault,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      tile.title as String,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        shadows: [
                          Shadow(
                            color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Regular row tile
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          decoration: BoxDecoration(
            color: DesignTokens.cardBackground,
            border: Border.all(
              color: DesignTokens.divider,
            ),
            borderRadius: radius,
            boxShadow: DesignTokens.shadowMedium,
          ),
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceDefault),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tile.title as String,
                    style: const TextStyle(
                      color: DesignTokens.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceDefault),
                SizedBox(
                  width: 130,
                  height: 100,
                  child: img,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
