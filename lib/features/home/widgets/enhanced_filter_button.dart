/// Enhanced Filter Button Widget
/// 
/// Beautiful filter button with active filter count badge
/// Smooth animations and modern design
library;

import 'package:flutter/material.dart';
import 'package:sixam_mart/util/design_tokens.dart';
import 'package:sixam_mart/util/styles.dart';

class EnhancedFilterButton extends StatelessWidget {
  final VoidCallback onTap;
  final int activeFilterCount;
  final bool showBadge;

  const EnhancedFilterButton({
    super.key,
    required this.onTap,
    this.activeFilterCount = 0,
    this.showBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = activeFilterCount > 0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DesignTokens.animationDefault,
        curve: DesignTokens.curveEaseOut,
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          gradient: hasActiveFilters
              ? DesignTokens.primaryGreenGradient
              : null,
          color: hasActiveFilters
              ? null
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(DesignTokens.radiusDefault),
          border: Border.all(
            color: hasActiveFilters
                ? Colors.transparent
                : Theme.of(context).primaryColor,
            width: 1.5,
          ),
          boxShadow: hasActiveFilters
              ? DesignTokens.glowShadow(DesignTokens.primaryGreen)
              : DesignTokens.shadowSubtle,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Icon(
                Icons.tune_rounded,
                color: hasActiveFilters
                    ? Colors.white
                    : Theme.of(context).primaryColor,
                size: 22,
              ),
            ),
            if (hasActiveFilters && showBadge && activeFilterCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: DesignTokens.orangeGradient,
                    shape: BoxShape.circle,
                    boxShadow: DesignTokens.shadowMedium,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      activeFilterCount > 9 ? '9+' : '$activeFilterCount',
                      style: robotoBold.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}








