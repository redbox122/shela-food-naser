import 'package:flutter/material.dart';
import 'package:sixam_mart/features/home/widgets/market/offers/market_offers_tabs.dart';
import 'package:sixam_mart/util/dimensions.dart';

/// Single filter row: "كل المنتجات" + sub_category pills on a white strip.
/// Selecting a pill filters the product grid (it no longer scrolls to a
/// section), so the bar just reports the tapped index.
class MarketOffersTabsBar extends StatelessWidget {
  final List<String> labels;
  final int selectedTab;

  /// Brand accent (active pill border + text) and its pale fill.
  final Color accent;
  final Color accentPale;

  final ValueChanged<int> onTabTap;

  const MarketOffersTabsBar({
    super.key,
    required this.labels,
    required this.selectedTab,
    required this.accent,
    required this.accentPale,
    required this.onTabTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: Colors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault),
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final bool selected = i == selectedTab;
          return GestureDetector(
            onTap: () => onTabTap(i),
            child: Center(
              child: PillTab(
                label: labels[i],
                selected: selected,
                accent: accent,
                accentFill: accentPale,
              ),
            ),
          );
        },
      ),
    );
  }
}
