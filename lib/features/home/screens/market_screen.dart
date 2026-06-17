import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/widgets/home_current_offers_section.dart';
import 'package:sixam_mart/features/home/widgets/home_top_notice_strip.dart';
import 'package:sixam_mart/features/home/widgets/market/market_banner_section.dart';
import 'package:sixam_mart/features/home/widgets/market/market_brands_section.dart';
import 'package:sixam_mart/features/home/widgets/market/market_categories_section.dart';
import 'package:sixam_mart/features/home/widgets/market/market_recent_orders_section.dart';
import 'package:sixam_mart/features/home/widgets/market/market_stores_section.dart';
import 'package:sixam_mart/features/home/screens/home_search_screen.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// 🎨 REDESIGN: "شاشة الماركت" — the grocery-module storefront opened from the
/// "ماركت" service tile on the home screen.
///
/// Self-contained: each section fetches its own data scoped to the grocery
/// module (via [_groceryModuleId]) without switching the app's active module,
/// so returning to the home screen leaves it untouched.
class MarketScreen extends StatefulWidget {
  /// Title shown in the header (e.g. "الماركت").
  final String title;

  /// Module type carried from the service tile (expected: `grocery`).
  final String moduleType;

  const MarketScreen({
    super.key,
    required this.title,
    required this.moduleType,
  });

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  /// Shared selected store-category — single source of truth for the top
  /// categories rail, the "فئة المتاجر" filter chip, and the stores list.
  int? _selectedCategoryId;

  /// The market module id. The market ("هايبر شله") is module 3 — the same
  /// module the banner and brands already use. Resolving by moduleType
  /// ('grocery') returns the wrong module (restaurants) / null, so the market
  /// stores list comes back empty of real data; module 3 returns the actual
  /// market stores (e.g. هايبر شلة, id 1) with full details.
  static const int _marketModuleId = 3;

  int? get _groceryModuleId => _marketModuleId;

  void _selectCategory(int? id) {
    if (id == _selectedCategoryId) return;
    setState(() => _selectedCategoryId = id);
  }

  @override
  Widget build(BuildContext context) {
    final int? moduleId = _groceryModuleId;

    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Column(
        children: [
          _MarketHeader(title: widget.title),
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
                  ),
                ),

                // Browse sections — hidden once a category is selected so the
                // screen collapses to categories + filters + filtered stores.
                if (_selectedCategoryId == null) ...[
                  // Promotional banner — /api/v1/banners (grocery-scoped).
                  SliverToBoxAdapter(
                    child: MarketBannerSection(moduleId: moduleId),
                  ),

                  // "العروض الحالية" — reused cross-module offers rail.
                  const SliverToBoxAdapter(child: HomeCurrentOffersSection()),

                  // "الطلبات السابقة" — recent orders as logo cards.
                  const SliverToBoxAdapter(child: MarketRecentOrdersSection()),

                  // "أشهر العلامات التجارية" — /api/v2/brands (grocery-scoped).
                  SliverToBoxAdapter(
                    child: MarketBrandsSection(moduleId: moduleId),
                  ),
                ],

                // "المتاجر" — filter chips + stores filtered by the category.
                SliverToBoxAdapter(
                  child: MarketStoresSection(
                    moduleId: moduleId,
                    categoryId: _selectedCategoryId,
                    onCategoryChanged: _selectCategory,
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
class _MarketHeader extends StatelessWidget {
  final String title;

  const _MarketHeader({required this.title});

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
              icon: Icons.arrow_back_ios_new,
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
              icon: Icons.search,
              onTap: () => Get.to<void>(() => const HomeSearchScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  /// When false, the icon shows with no grey circle background.
  final bool showBackground;

  const _CircleIconButton({
    required this.icon,
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
          child: Icon(icon, size: 22, color: const Color(0xFF121C19)),
        ),
      ),
    );
  }
}
