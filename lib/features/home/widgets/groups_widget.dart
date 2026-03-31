import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Groups Widget
/// 
/// Displays the restaurants section header with filter buttons
/// Replaces hardcoded design with responsive implementation
class Groups extends StatefulWidget {
  const Groups({
    super.key,
    this.onFilterTap,
    this.onOffersTap,
    this.onTopRatedTap,
    this.onFastestDeliveryTap,
    this.onIconButtonTap,
    this.onStoreTypeSelected,
    this.selectedStoreType,
  });

  final VoidCallback? onFilterTap;
  final VoidCallback? onOffersTap;
  final VoidCallback? onTopRatedTap;
  final VoidCallback? onFastestDeliveryTap;
  final VoidCallback? onIconButtonTap;
  final void Function(String)? onStoreTypeSelected;
  final String? selectedStoreType;

  @override
  State<Groups> createState() => _GroupsState();
}

class _GroupsState extends State<Groups> {
  late ScrollController _scrollController;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final isScrolled = _scrollController.offset > 0;
    if (isScrolled != _isScrolled) {
      setState(() {
        _isScrolled = isScrolled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 570.0; // Base design width from Figma
    final theme = Theme.of(context);
    final splashController = Get.find<SplashController>();
    return Obx(() {
      final moduleName = (splashController.selectedModule.value?.moduleName ??
              splashController.module?.moduleName ??
              '')
          .trim();
      final moduleId = splashController.selectedModule.value?.id ??
          splashController.module?.id;
      final isCafeModule = moduleName.contains('مقه') ||
          moduleName.toLowerCase().contains('cafe') ||
          moduleName.toLowerCase().contains('coffee') ||
          moduleId == 9;
      final titleText = moduleId == 9
          ? 'المقاهي'
          : (moduleName.isNotEmpty
              ? moduleName
              : (isCafeModule ? 'المقاهي' : 'المطاعم'));

      return Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: screenWidth,
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Icon Button Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Title (right side in RTL)
                  Text(
                    titleText,
                    style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge * 1.2,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),

                  // Icon Button (left side in RTL)
                  _buildIconButton(context, scaleFactor),
                ],
              ),

              const SizedBox(height: Dimensions.paddingSizeSmall * 0.6),

              // Unified Filter Chips Row - All chips in one row with sticky filter
              _buildUnifiedChipsRow(context, scaleFactor),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildIconButton(BuildContext context, double scaleFactor) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppColorTokens>()!;

    return InkWell(
      onTap: widget.onIconButtonTap ?? () {},
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      child: Container(
        width: 95 * scaleFactor,
        height: 43 * scaleFactor,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          border: Border.all(
            color: tokens.outlineSoft,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apps,
              size: 19 * scaleFactor,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Icon(
              Icons.more_vert,
              size: 19 * scaleFactor,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildUnifiedChipsRow(BuildContext context, double scaleFactor) {
    // ⚠️ UI REQUIREMENT: Only "all" button should be visible
    // Do NOT re-add discounts / popular / filter buttons
    final storeTypes = [
      {'value': 'all', 'label': 'الكل'},
    ];

    return SizedBox(
      height: 40 * scaleFactor,
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        children: [
          // Store type chips - only "الكل" (All)
          ...storeTypes.map((type) {
            final isSelected = widget.selectedStoreType == type['value'];
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeExtraSmall * 0.5,
              ),
              child: _buildUnifiedChip(
                context,
                scaleFactor,
                text: type['label']!,
                isSelected: isSelected,
                onTap: () {
                  if (widget.onStoreTypeSelected != null) {
                    widget.onStoreTypeSelected!(type['value']!);
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }


  /// Unified chip builder for consistent styling
  Widget _buildUnifiedChip(
    BuildContext context,
    double scaleFactor, {
    required String text,
    bool isSelected = false,
    List<IconData>? leadingIcons,
    VoidCallback? onTap,
  }) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(20 * scaleFactor),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
          vertical: Dimensions.paddingSizeExtraSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : tokens.surfaceSoft,
          borderRadius: BorderRadius.circular(20 * scaleFactor),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : tokens.outlineSoft,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Leading icons (if any)
            if (leadingIcons != null && leadingIcons.isNotEmpty)
              ...leadingIcons.map((icon) => Padding(
                    padding: EdgeInsets.only(
                      left: icon == leadingIcons.first
                          ? 0
                          : Dimensions.paddingSizeExtraSmall * 0.3,
                      right: Dimensions.paddingSizeExtraSmall * 0.3,
                    ),
                    child: Icon(
                      icon,
                      size: 18 * scaleFactor,
                      color: isSelected
                          ? Colors.white
                          : Theme.of(context).disabledColor,
                    ),
                  )),
            // Text
            Flexible(
              child: Text(
                text,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
