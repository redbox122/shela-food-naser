import 'package:flutter/material.dart';
import 'package:sixam_mart/features/home/widgets/market/offers/market_offers_models.dart';
import 'package:sixam_mart/features/home/widgets/market/offers/market_offers_tabs.dart';
import 'package:sixam_mart/util/dimensions.dart';

class MarketOffersHeader extends StatelessWidget {
  /// Brand accent (band fill).
  final Color accent;

  final List<StoreCat> cats;
  final int selectedCat;

  final VoidCallback onBack;
  final ValueChanged<int> onCatTap;

  const MarketOffersHeader({
    super.key,
    required this.accent,
    required this.cats,
    required this.selectedCat,
    required this.onBack,
    required this.onCatTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      color: accent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              const SizedBox(width: 4),
              _backIcon(),
              Expanded(child: _topBar()),
            ],
          ),
        ),
      ),
    );
  }

  /// Plain white back chevron (no chip) — sits on the right in the RTL layout.
  Widget _backIcon() {
    return InkResponse(
      onTap: onBack,
      radius: 24,
      child: const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.arrow_back_ios, size: 22, color: Colors.white),
      ),
    );
  }

  /// Scrollable store categories; the active one is solid white with a white
  /// indicator (handled by [CaretTab]).
  Widget _topBar() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeSmall),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, i) {
          return GestureDetector(
            onTap: () => onCatTap(i),
            // Bottom-align so the active tab's white indicator sits at the very
            // bottom edge of the band (against the white sub-category strip).
            child: Align(
              alignment: Alignment.bottomCenter,
              child: CaretTab(
                label: cats[i].name,
                selected: i == selectedCat,
              ),
            ),
          );
        },
      ),
    );
  }
}
