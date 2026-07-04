import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';

/// 🎨 REDESIGN: A single tab definition for [HomeBottomNavBar].
class HomeNavBarItem {
  final String icon;
  final String activeIcon;
  final String label;

  /// When true, the tab shows a badge with the current cart product count.
  final bool isCart;

  const HomeNavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.isCart = false,
  });
}

/// 🎨 REDESIGN: Bottom navigation bar matching the new design.
///
/// Five tabs, no centre floating action button. The selected tab shows a solid
/// (black-tinted) icon with its label; unselected tabs show the same icon in a
/// muted grey with no label.
class HomeBottomNavBar extends StatelessWidget {
  final List<HomeNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const HomeBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  // Inactive icon tint = Icon-disable hsba(0,0%,33%). Active uses its own
  // (already-styled) asset, so it is not tinted.
  static const Color _inactiveColor = Color(0xFF545454);
  static const Color _activeLabelColor = Color(0xFF121C19);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (index) {
              return _NavItem(
                item: items[index],
                isSelected: index == currentIndex,
                onTap: () => onTap(index),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final HomeNavBarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  Widget _buildIcon(BuildContext context) {
    final Widget image = Image.asset(
      isSelected ? item.activeIcon : item.icon,
      height: 24,
      width: 24,
      // Active asset is pre-styled (filled black) → no tint.
      color: isSelected ? null : HomeBottomNavBar._inactiveColor,
      errorBuilder: (_, __, ___) => Icon(
        isSelected ? Icons.circle : Icons.circle_outlined,
        size: 24,
        color: isSelected
            ? HomeBottomNavBar._activeLabelColor
            : HomeBottomNavBar._inactiveColor,
      ),
    );
    if (!item.isCart) return image;
    return GetBuilder<CartController>(
      builder: (cart) {
        final int count = cart.cartList.length;
        if (count <= 0) return image;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            image,
            Positioned(
              top: -6,
              right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                constraints:
                    const BoxConstraints(minWidth: 16, minHeight: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF31A342),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    height: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildIcon(context),
            // Always show the label under every icon; the selected tab uses the
            // active label colour, the rest use the muted inactive colour.
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w500,
                fontSize: 12,
                height: 1.4,
                color: isSelected
                    ? HomeBottomNavBar._activeLabelColor
                    : HomeBottomNavBar._inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}