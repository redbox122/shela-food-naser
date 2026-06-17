import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/design_tokens.dart';
import 'package:sixam_mart/util/images.dart';

/// Shared "no results" placeholder used by every search results list.
class SearchEmptyState extends StatelessWidget {
  const SearchEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              Images.not_found,
              width: 200,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            Text(
              'no_results_found'.tr,
              style: const TextStyle(
                color: DesignTokens.textDark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
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
}
