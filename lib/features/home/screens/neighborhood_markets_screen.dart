import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/screens/home_search_screen.dart';
import 'package:sixam_mart/features/home/widgets/home_current_offers_section.dart';
import 'package:sixam_mart/features/home/widgets/home_top_notice_strip.dart';
import 'package:sixam_mart/features/home/widgets/market/market_banner_section.dart';
import 'package:sixam_mart/features/home/widgets/market/market_brands_section.dart';
import 'package:sixam_mart/features/home/widgets/market/market_categories_section.dart';
import 'package:sixam_mart/features/home/widgets/market/market_stores_section.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 REDESIGN: "أسواق الحي" — the neighborhood-markets storefront opened from
/// the "أسواق الحي" service tile on the home screen.
///
/// A module storefront (notice → categories → banner → brands → offers →
/// stores) scoped to the neighborhood-markets module so it surfaces its own
/// stores and data.
///
/// Self-contained: each section fetches its own data scoped to
/// [_neighborhoodModuleId] without switching the app's active module, so
/// returning to the home screen leaves it untouched.
class NeighborhoodMarketsScreen extends StatefulWidget {
  /// Title shown in the header (e.g. "أسواق الحي").
  final String title;

  /// Module type carried from the service tile (e.g. `grocery`, `food`,
  /// `pharmacy`).
  final String moduleType;

  /// Backend module id whose categories/banners/brands/stores are shown.
  /// Defaults to the neighborhood-markets (grocery) module.
  final int moduleId;

  const NeighborhoodMarketsScreen({
    super.key,
    required this.title,
    required this.moduleType,
    this.moduleId = 7,
  });

  @override
  State<NeighborhoodMarketsScreen> createState() =>
      _NeighborhoodMarketsScreenState();
}

class _NeighborhoodMarketsScreenState extends State<NeighborhoodMarketsScreen> {
  /// Shared selected store-category — single source of truth for the top
  /// categories rail, the "فئة المتاجر" filter chip, and the stores list.
  int? _selectedCategoryId;

  /// Backend module id (from the widget) driving every section's data fetch
  /// (categories / banner / brands / stores).
  int? get _moduleId => widget.moduleId;

  void _selectCategory(int? id) {
    if (id == _selectedCategoryId) return;
    setState(() => _selectedCategoryId = id);
  }

  @override
  Widget build(BuildContext context) {
    final int? moduleId = _moduleId;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        children: [
          _Header(title: widget.title, moduleId: moduleId),
          Expanded(
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Address / context-aware notice pill.
                const SliverToBoxAdapter(child: HomeTopNoticeStrip()),

                // Categories rail — tapping a card filters the stores below.
                SliverToBoxAdapter(
                  child: MarketCategoriesSection(
                    moduleId: moduleId,
                    selectedId: _selectedCategoryId,
                    onSelect: _selectCategory,
                    singleRow: true,
                  ),
                ),

                // Browse sections — hidden once a category is selected so the
                // screen collapses to categories + filters + filtered stores.
                if (_selectedCategoryId == null) ...[
                  // Promotional banner — /api/v1/banners (module-scoped).
                  SliverToBoxAdapter(
                    child: MarketBannerSection(moduleId: moduleId),
                  ),

                  // "أشهر العلامات التجارية" — this module's own stores
                  // (/api/v2/stores), shown as circular logo chips.
                  SliverToBoxAdapter(
                    child: MarketBrandsSection(moduleId: moduleId),
                  ),

                  // "العروض الحالية" — scoped to this screen's module so each
                  // section shows only its own offers.
                  SliverToBoxAdapter(
                      child: HomeCurrentOffersSection(moduleId: moduleId)),
                ],

                // "المتاجر" — filter chips + stores filtered by the category.
                SliverToBoxAdapter(
                  child: MarketStoresSection(
                    moduleId: moduleId,
                    categoryId: _selectedCategoryId,
                    onCategoryChanged: _selectCategory,
                    storeCoverHeader: true,
                  ),
                ),

                const SliverToBoxAdapter(
                  child: SizedBox(height: Dimensions.paddingSizeLarge),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Header row: back chevron (RTL leading/right), centered title, search icon
/// (RTL trailing/left).
class _Header extends StatelessWidget {
  final String title;

  /// Module this storefront belongs to — passed to search so it scopes results
  /// and shows this module's own stores.
  final int? moduleId;

  const _Header({required this.title, this.moduleId});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
          vertical: Dimensions.paddingSizeSmall,
        ),
        child: Row(
          children: [
            // Back (RTL: on the right, chevron points right). No background.
            _CircleIconButton(
              image: Images.arrow_back_ios_new,
              onTap: () => Get.back<void>(),
              showBackground: false,
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  height: 1.2,
                  color: Color(0xFF121C19),
                ),
              ),
            ),
            // Search (RTL: on the left).
            _CircleIconButton(
              image: Images.search,
              onTap: () =>
                  Get.to<void>(() => HomeSearchScreen(moduleId: moduleId)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final String image;
  final VoidCallback onTap;

  /// When false, the icon shows with no grey circle background.
  final bool showBackground;

  const _CircleIconButton({
    required this.image,
    required this.onTap,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: showBackground ? const Color(0xFFF4F5F7) : Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            image,
            width: 22,
            height: 22,
            fit: BoxFit.contain,
            color: const Color(0xFF121C19),
            errorBuilder: (_, __, ___) => const SizedBox(width: 22, height: 22),
          ),
        ),
      ),
    );
  }
}
