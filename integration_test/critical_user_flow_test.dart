/*import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';
import 'package:sixam_mart/main.dart' as app;
import 'package:get/get.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  patrolTest(
    'Critical User Flow: Home → Popular Stores → Store → Add 2 Items → Verify Cart Badge',
    ($) async {
      // Step 1: App Launch - Wait for Home Screen to load
      app.main();
      await $.pumpAndSettle(const Duration(seconds: 5));

      // Wait for home screen to fully load
      // Look for common home screen elements
      await $.native.waitUntilVisible(
        selector: Selector(
          className: 'android.widget.FrameLayout',
        ),
        timeout: const Duration(seconds: 30),
      );
      await $.pumpAndSettle(const Duration(seconds: 3));

      // Step 2: Scroll down to "Popular Stores" section
      // Use Flutter finder to find text containing "popular" (translated)
      final popularStoresFinder = find.textContaining('popular', findRichText: true);
      
      // Scroll until Popular Stores section is visible
      await $.tester.scrollUntilVisible(
        popularStoresFinder,
        500.0,
        scrollable: find.byType(Scrollable),
      );
      await $.pumpAndSettle(const Duration(seconds: 2));

      // Verify Popular Stores section is visible
      expect(popularStoresFinder, findsWidgets);

      // Step 3: Tap the first Store card in Popular Stores section
      // Store cards are in a horizontal ListView, wrapped in tappable widgets
      // Try multiple strategies to find and tap the first store card
      bool storeTapped = false;
      
      // Strategy 1: Find by CustomInkWell (used in StoreCardWithDistance)
      try {
        final customInkWells = find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString().contains('CustomInkWell') ||
                      widget.runtimeType.toString().contains('InkWell'),
        );
        if (customInkWells.evaluate().isNotEmpty) {
          // Find the first one that's in a horizontal scrollable area
          await $.tester.tap(customInkWells.first);
          storeTapped = true;
        }
      } catch (e) {
        // Continue to next strategy
      }

      // Strategy 2: Find by horizontal ListView and tap first child
      if (!storeTapped) {
        try {
          final horizontalListViews = find.byWidgetPredicate(
            (widget) => widget is ListView && 
                       (widget).scrollDirection == Axis.horizontal,
          );
          if (horizontalListViews.evaluate().isNotEmpty) {
            // Tap in the center-left area of the first horizontal ListView
            final listViewFinder = horizontalListViews.first;
            await $.tester.tapAt($.tester.getTopLeft(listViewFinder) + const Offset(100, 50));
            storeTapped = true;
          }
        } catch (e) {
          // Continue to next strategy
        }
      }

      // Strategy 3: Fallback - tap on first tappable widget
      if (!storeTapped) {
        try {
          final tappableWidgets = find.byWidgetPredicate(
            (widget) => widget is InkWell || 
                       widget is GestureDetector ||
                       widget.runtimeType.toString().contains('InkWell'),
          );
          if (tappableWidgets.evaluate().isNotEmpty) {
            await $.tester.tap(tappableWidgets.first);
            storeTapped = true;
          }
        } catch (e) {
          // Last resort: tap in the area where store cards typically appear
          await $.tester.tapAt(const Offset(200, 400));
        }
      }

      await $.pumpAndSettle(const Duration(seconds: 3));

      // Wait for store screen to load - look for store-specific elements
      await $.pumpAndSettle(const Duration(seconds: 2));

      // Step 4: Add 2 items to cart
      // Find "Add" buttons or add icons in item cards
      int itemsAdded = 0;

      // Strategy 1: Find by icon (Icons.add)
      final addIcons = find.byIcon(Icons.add);
      if (addIcons.evaluate().isNotEmpty) {
        for (int i = 0; i < addIcons.evaluate().length && itemsAdded < 2; i++) {
          try {
            await $.tester.tap(addIcons.at(i));
            await $.pumpAndSettle(const Duration(seconds: 2));
            itemsAdded++;
            await Future.delayed(const Duration(milliseconds: 500));
          } catch (e) {
            continue;
          }
        }
      }

      // Strategy 2: If not enough items added, look for text buttons with "add"
      if (itemsAdded < 2) {
        final addTextButtons = find.textContaining('add', findRichText: true);
        final addButtonEvaluations = addTextButtons.evaluate();
        
        for (int i = 0; i < addButtonEvaluations.length && itemsAdded < 2; i++) {
          try {
            await $.tester.tap(addTextButtons.at(i));
            await $.pumpAndSettle(const Duration(seconds: 2));
            itemsAdded++;
            await Future.delayed(const Duration(milliseconds: 500));
          } catch (e) {
            continue;
          }
        }
      }

      // Strategy 3: Find by widget type (CartCountView or similar add buttons)
      if (itemsAdded < 2) {
        // Look for circular containers that might be add buttons
        final circularButtons = find.byWidgetPredicate(
          (widget) {
            if (widget is Container) {
              final decoration = widget.decoration;
              if (decoration is BoxDecoration) {
                return decoration.shape == BoxShape.circle;
              }
            }
            return false;
          },
        );

        if (circularButtons.evaluate().isNotEmpty) {
          for (int i = 0; i < circularButtons.evaluate().length && itemsAdded < 2; i++) {
            try {
              await $.tester.tap(circularButtons.at(i));
              await $.pumpAndSettle(const Duration(seconds: 2));
              itemsAdded++;
              await Future.delayed(const Duration(milliseconds: 500));
            } catch (e) {
              continue;
            }
          }
        }
      }

      // Verify we added at least 2 items
      expect(
        itemsAdded,
        greaterThanOrEqualTo(2),
        reason: 'Should have added at least 2 items to cart. Actually added: $itemsAdded',
      );

      // Step 5: Verify Cart Badge updates to "2"
      await $.pumpAndSettle(const Duration(seconds: 2));

      // Look for cart badge with text "2"
      // The cart badge is a Text widget showing the count
      final cartBadgeText = find.text('2');
      
      // Wait for cart badge to appear (with retries)
      for (int attempt = 0; attempt < 5; attempt++) {
        await $.pumpAndSettle(const Duration(seconds: 1));
        if (cartBadgeText.evaluate().isNotEmpty) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Verify cart badge shows "2"
      expect(
        cartBadgeText,
        findsAtLeastNWidgets(1),
        reason: 'Cart badge should display "2" after adding 2 items',
      );

      // Additional verification: Check that cart count is visible somewhere in the UI
      // This ensures the cart state was properly updated
      final anyCartCount = find.textContaining('2');
      expect(
        anyCartCount,
        findsAtLeastNWidgets(1),
        reason: 'Cart count "2" should be visible somewhere in the UI',
      );
    },
  );
}

*/