part of 'market_store_screen.dart';

// ─── Sticky category tabs ────────────────────────────────────────────────────

/// Pinned horizontal category tab bar (food-delivery style). Each tab is a
/// category name; the active one is dark + bold with a green underline. Tapping
/// a tab asks the screen to scroll to that category's section, and the active
/// tab follows the scroll position (scroll-spy, handled by the screen state).
class _CategoryTabsDelegate extends SliverPersistentHeaderDelegate {
  final List<_Category> categories;
  final int activeIndex;
  final double height;
  final void Function(int index) onTap;

  _CategoryTabsDelegate({
    required this.categories,
    required this.activeIndex,
    required this.height,
    required this.onTap,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: height,
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeDefault),
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 18),
              itemBuilder: (_, i) {
                final bool active = i == activeIndex;
                final c = categories[i];
                final String name =
                    (c.name == null || c.name!.isEmpty) ? '—' : c.name!;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontWeight:
                                  active ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 14,
                              color: active
                                  ? const Color(0xFF121C19)
                                  : const Color(0xFF8A8F99),
                            ),
                          ),
                        ),
                      ),
                      // Underline shown only under the active tab.
                      Container(
                        height: 3,
                        width: 26,
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF30913F)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(height: 1, color: const Color(0xFFF0F1F3)),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_CategoryTabsDelegate old) =>
      old.activeIndex != activeIndex ||
      old.categories.length != categories.length ||
      old.height != height;
}
