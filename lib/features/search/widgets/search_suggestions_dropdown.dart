import 'package:flutter/material.dart';
import 'package:sixam_mart/features/search/domain/models/search_suggestion_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/smart_image.dart';
import 'package:sixam_mart/util/design_tokens.dart';

/// Widget that displays search suggestions in a dropdown format
class SearchSuggestionsDropdown extends StatefulWidget {
  final SearchSuggestionModel? suggestionModel;
  final Function(String name, bool isStore, int? id)? onSuggestionTap;
  final bool isLoading;

  const SearchSuggestionsDropdown({
    super.key,
    this.suggestionModel,
    this.onSuggestionTap,
    this.isLoading = false,
  });

  @override
  State<SearchSuggestionsDropdown> createState() =>
      _SearchSuggestionsDropdownState();
}

class _SearchSuggestionsDropdownState extends State<SearchSuggestionsDropdown>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: DesignTokens.animationMedium,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController, curve: DesignTokens.curveEaseOutCubic),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(
      CurvedAnimation(
          parent: _animationController, curve: DesignTokens.curveEaseOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  List<dynamic> _getAllSuggestions() {
    final List<dynamic> allSuggestions = [];
    if (widget.suggestionModel != null) {
      if (widget.suggestionModel!.items != null &&
          widget.suggestionModel!.items!.isNotEmpty) {
        for (final item in widget.suggestionModel!.items!) {
          allSuggestions.add({'type': 'item', 'data': item});
        }
      }
      if (widget.suggestionModel!.stores != null &&
          widget.suggestionModel!.stores!.isNotEmpty) {
        for (final store in widget.suggestionModel!.stores!) {
          allSuggestions.add({'type': 'store', 'data': store});
        }
      }
    }
    return allSuggestions.take(7).toList();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _getAllSuggestions();

    if (widget.isLoading) {
      return Container(
        margin: const EdgeInsets.only(top: DesignTokens.spaceSmall),
        decoration: BoxDecoration(
          color: DesignTokens.cardBackground,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
          boxShadow: DesignTokens.shadowStrong,
        ),
        child: const Padding(
          padding: EdgeInsets.all(DesignTokens.spaceDefault),
          child: Center(
            child: CircularProgressIndicator(
              color: DesignTokens.primaryGreen,
            ),
          ),
        ),
      );
    }

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(top: DesignTokens.spaceSmall),
          constraints: const BoxConstraints(maxHeight: 320),
          decoration: BoxDecoration(
            color: DesignTokens.cardBackground,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
            boxShadow: DesignTokens.shadowStrong,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(DesignTokens.spaceSmall),
            itemCount: suggestions.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: DesignTokens.divider,
            ),
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              final isStore = (suggestion['type'] as String?) == 'store';
              final data = suggestion['data'];

              return _SuggestionItem(
                name: isStore ? (data.name as String?) ?? '' : (data.name as String?) ?? '',
                imageUrl: isStore ? (data.logoFullUrl as String?) ?? '' : (data.imageFullUrl as String?) ?? '',
                isStore: isStore,
                onTap: () {
                  if (widget.onSuggestionTap != null) {
                    widget.onSuggestionTap!((data.name as String?) ?? '', isStore, data.id as int?);
                  } else {
                    _defaultSuggestionTap((data.name as String?) ?? '', isStore, data.id as int?);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _defaultSuggestionTap(String name, bool isStore, int? id) {
    if (widget.onSuggestionTap == null && id != null) {
      if (isStore) {
        Get.toNamed(RouteHelper.getStoreRoute(id: id, page: 'store'));
      } else {
        Get.toNamed(RouteHelper.getItemDetailsRoute(id, false));
      }
    }
  }
}

/// Individual suggestion item widget
class _SuggestionItem extends StatefulWidget {
  final String name;
  final String? imageUrl;
  final bool isStore;
  final VoidCallback onTap;

  const _SuggestionItem({
    required this.name,
    this.imageUrl,
    required this.isStore,
    required this.onTap,
  });

  @override
  State<_SuggestionItem> createState() => _SuggestionItemState();
}

class _SuggestionItemState extends State<_SuggestionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      duration: DesignTokens.animationDefault,
      vsync: this,
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _staggerController, curve: DesignTokens.curveEaseOut),
    );
    Future.delayed(Duration(milliseconds: 50 * (widget.hashCode % 5)), () {
      if (mounted) {
        _staggerController.forward();
      }
    });
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spaceMedium,
              vertical: DesignTokens.spaceDefault,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSmall),
                  child: SmartImage(
                    url: widget.imageUrl ?? '',
                    width: 48,
                    height: 48,
                    cacheWidth: 300,
                    cacheHeight: 300,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: DesignTokens.divider,
                        borderRadius:
                            BorderRadius.circular(DesignTokens.radiusSmall),
                      ),
                      child: Icon(
                        widget.isStore ? Icons.store : Icons.shopping_bag,
                        color: DesignTokens.textLight,
                        size: 24,
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
                        widget.name,
                        style: const TextStyle(
                          color: DesignTokens.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: DesignTokens.spaceExtraSmall),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spaceSmall,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isStore
                              ? DesignTokens.secondaryOrange.withValues(alpha: 0.1)
                              : DesignTokens.primaryGreen.withValues(alpha: 0.1),
                          borderRadius:
                              BorderRadius.circular(DesignTokens.radiusFull),
                        ),
                        child: Text(
                          widget.isStore ? 'Store' : 'Item',
                          style: TextStyle(
                            color: widget.isStore
                                ? DesignTokens.secondaryOrange
                                : DesignTokens.primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: DesignTokens.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
