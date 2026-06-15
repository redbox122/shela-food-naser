import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/design_tokens.dart';

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
            Text(
              'no_results_found'.tr,
              style: const TextStyle(
                color: DesignTokens.textLight,
                fontSize: 14,
                fontWeight: FontWeight.w400,
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
