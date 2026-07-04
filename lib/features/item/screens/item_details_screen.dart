import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/widgets/cart_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/features/checkout/screens/checkout_screen.dart';
import 'package:sixam_mart/features/item/widgets/details_app_bar_widget.dart';
import 'package:sixam_mart/features/item/widgets/details_web_view_widget.dart';
import 'package:sixam_mart/features/item/widgets/item_image_view_widget.dart';
import 'package:sixam_mart/common/widgets/food_variation_section.dart';
import 'package:sixam_mart/features/item/widgets/item_image_carousel.dart';
import 'package:sixam_mart/features/item/widgets/item_info_header.dart';
import 'package:sixam_mart/features/item/widgets/item_floating_cart_bar.dart';
import 'package:sixam_mart/features/item/widgets/item_details_skeleton.dart';
import 'package:sixam_mart/features/item/widgets/item_add_to_cart_row.dart';
import 'package:sixam_mart/features/item/widgets/item_total_amount_strip.dart';
import 'package:sixam_mart/features/item/widgets/ecommerce_variation_selector.dart';
import 'package:sixam_mart/features/item/widgets/item_prescription_badge.dart';
import 'package:sixam_mart/features/item/widgets/item_extra_info_sections.dart';
import 'package:sixam_mart/features/item/widgets/item_sold_with_grid.dart';

class ItemDetailsScreen extends StatefulWidget {
  final Item? item;
  final List<Item>? itemList;
  final bool inStorePage;
  final bool? isCampaign;
  const ItemDetailsScreen(
      {super.key,
      required this.item,
      required this.inStorePage,
      this.isCampaign,
      this.itemList});

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  // 🎨 UI-only: hide info sections not present in the new design
  // (description, nutrition, allergies). Logic/data loading stays intact.
  static const bool _showExtraInfoSections = false;

  final Size size = Get.size;
  final GlobalKey<ScaffoldMessengerState> _globalKey = GlobalKey();
  final GlobalKey<DetailsAppBarWidgetState> _key = GlobalKey();

  // 🎨 NEW DESIGN: tracks whether the user picked a quantity yet.
  // false → show the circular "+" button; true → show the "- N +" counter pill.
  bool _quantitySelected = false;

  @override
  void initState() {
    super.initState();

    // ⚡ SILICON VALLEY WAY: Use widget.item immediately for instant UI (0ms perceived load)
    // Set item in controller immediately so header shows name/image instantly
    // ⚠️ FIX: Use post-frame callback to prevent "setState during build" error
    // Flutter prohibits any setState/update() calls during the build phase
    if (widget.item != null) {
      final itemController = Get.find<ItemController>();
      final hasBasicData =
          widget.item!.name != null || widget.item!.imageFullUrl != null;
      if (hasBasicData) {
        // ⚡ FIX: Defer setItemMiniCache to post-frame callback to avoid "setState during build"
        WidgetsBinding.instance.addPostFrameCallback((_) {
          itemController.setItemMiniCache(widget.item!);
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            debugPrint(
                '⚡ ItemDetailsScreen: Item header visible instantly (0ms) - using widget.item');
          }
        });
      }
    }

    // ⚡ BACKGROUND FETCH: Only fetch additional details in background (not basic info)
    // This makes the app feel "Lightning Fast" even if internet is slow
    if (widget.item != null) {
      final itemController = Get.find<ItemController>();
      // Fetch additional details in background (non-blocking)
      itemController.getProductDetails(widget.item!).then((_) {
        itemController.setSelect(0, false);
        itemController.getSimilarProducts(widget.item!.categoryId.toString());
      }).catchError((Object e) {
        if (kDebugMode && AppConstants.enableVerboseLogs) {
          debugPrint('❌ ItemDetailsScreen: Error fetching item details: $e');
        }
      });
    }
  }

  /// Live cart-driven quantity change for the details counter.
  ///
  /// Mirrors the cart screen's stepper so the cart badge/totals update
  /// automatically and directly:
  /// - not in cart + increment → add the item (qty 1), respecting required
  ///   variation selection;
  /// - in cart + increment/decrement → mutate the real cart line via
  ///   [CartController.setQuantityById] (optimistic, no navigation/snackbar);
  /// - in cart + decrement at qty 1 → remove the line and collapse the pill.
  ///
  /// Campaign items keep the local-preview behaviour (they use the campaign
  /// checkout flow, not the cart).
  Future<void> _applyCartQuantityChange({
    required bool isIncrement,
    required CartController cartController,
    required ItemController itemController,
    required CartModel? cartModel,
    required OnlineCart? cart,
    required int stock,
  }) async {
    final Item? item = itemController.item;
    if (item?.id == null) return;

    final bool isCampaign = item!.availableDateStarts != null;
    if (isCampaign) {
      itemController.setQuantity(isIncrement, stock, item.quantityLimit);
      return;
    }

    final int? cartId = cartController.getCartIdByItemId(item.id!);

    // Not in cart yet → first increment adds it to the cart.
    if (cartId == null) {
      if (!isIncrement) {
        if (mounted) setState(() => _quantitySelected = false);
        return;
      }
      if (cartModel == null || cart == null) return;
      if (!itemController.ensureRequiredVariationsSelected()) return;
      final bool ok = await cartController.addToCartWithFallback(
        cartModel: cartModel,
        onlineCart: cart,
      );
      if (ok && mounted) {
        await itemController.setExistInCart(item, null, notify: true);
      }
      return;
    }

    // Already in cart → mutate the real line live.
    final int idx = cartController.cartList.indexWhere((e) => e.id == cartId);
    final int currentQty =
        idx != -1 ? (cartController.cartList[idx].quantity ?? 1) : 1;

    if (isIncrement) {
      await cartController.setQuantityById(
          true, cartId, stock, item.quantityLimit);
    } else if (currentQty > 1) {
      await cartController.setQuantityById(
          false, cartId, stock, item.quantityLimit);
    } else {
      await cartController.removeFromCartById(cartId,
          item: item, reason: 'item_details_decrement');
      if (mounted) setState(() => _quantitySelected = false);
    }

    if (mounted) {
      await itemController.setExistInCart(item, null, notify: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<CartController>(builder: (cartController) {
      return GetBuilder<ItemController>(
        builder: (itemController) {
          final details = itemController.detailsViewData;
          final int stock = details.stock;
          final CartModel? cartModel = details.cartModel;
          final OnlineCart? cart = details.cart;
          final double priceWithAddons = details.priceWithAddons;

          return Scaffold(
            key: _globalKey,
            backgroundColor: Theme.of(context).cardColor,
            endDrawerEnableOpenDragGesture: false,
            appBar: ResponsiveHelper.isDesktop(context)
                ? const CustomAppBar(title: '')
                : DetailsAppBarWidget(key: _key),
            body: SafeArea(
                child: (itemController.item != null)
                    ? ResponsiveHelper.isDesktop(context)
                        ? DetailsWebViewWidget(
                            cartModel: cartModel,
                            stock: stock,
                            priceWithAddOns: priceWithAddons,
                            cart: cart,
                          )
                        : Stack(children: [
                            Positioned.fill(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(
                                    Dimensions.paddingSizeSmall),
                                physics: const BouncingScrollPhysics(),
                                child: Center(
                                  child: SizedBox(
                                    width: Dimensions.webMaxWidth,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // 🎨 NEW DESIGN: centered 194×194 product image
                                        // (carousel + dot indicators when multiple).
                                        ItemImageCarousel(
                                          item: itemController.item!,
                                          onTap: (widget.isCampaign ?? false)
                                              ? null
                                              : () => Navigator.of(context)
                                                      .pushNamed(
                                                    RouteHelper
                                                        .getItemImagesRoute(
                                                            itemController
                                                                .item!),
                                                    arguments:
                                                        ItemImageViewWidget(
                                                            item: itemController
                                                                .item),
                                                  ),
                                        ),
                                        const SizedBox(height: 20),

                                        // 🎨 NEW DESIGN: info header — favourite on
                                        // the start edge, name / description / unit
                                        // right-aligned beside it.
                                        ItemInfoHeader(
                                            item: itemController.item!),
                                        // ✅ DATA-DRIVEN MORPHING: Priority 3 - Simple Product (no variations - direct add to cart)

                                        // 🎨 NEW DESIGN: morphing add-to-cart control
                                        // - out of stock   → pill "product_not_available"
                                        // - no qty picked  → circular "+" button
                                        // - qty picked     → green "- N +" counter pill
                                        ItemAddToCartRow(
                                          itemController: itemController,
                                          quantitySelected: _quantitySelected,
                                          onActivate: () {
                                            HapticFeedback.lightImpact();
                                            setState(() =>
                                                _quantitySelected = true);
                                            _applyCartQuantityChange(
                                              isIncrement: true,
                                              cartController:
                                                  Get.find<CartController>(),
                                              itemController: itemController,
                                              cartModel: cartModel,
                                              cart: cart,
                                              stock: stock,
                                            );
                                          },
                                          onIncrement: () {
                                            HapticFeedback.lightImpact();
                                            _applyCartQuantityChange(
                                              isIncrement: true,
                                              cartController:
                                                  Get.find<CartController>(),
                                              itemController: itemController,
                                              cartModel: cartModel,
                                              cart: cart,
                                              stock: stock,
                                            );
                                          },
                                          onDecrement: () {
                                            HapticFeedback.lightImpact();
                                            _applyCartQuantityChange(
                                              isIncrement: false,
                                              cartController:
                                                  Get.find<CartController>(),
                                              itemController: itemController,
                                              cartModel: cartModel,
                                              cart: cart,
                                              stock: stock,
                                            );
                                          },
                                        ),

                                        // Total amount — only once a quantity is picked
                                        if (_quantitySelected &&
                                            (itemController.item?.stock ?? 1) >
                                                0) ...[
                                          const SizedBox(
                                              height: Dimensions
                                                  .paddingSizeDefault),
                                          ItemTotalAmountStrip(
                                              priceWithAddons: priceWithAddons),
                                        ],


                                        // ✅ DATA-DRIVEN MORPHING: Priority 1 - Food Variations (Coffee, Food modules)
                                        if (itemController
                                                    .item?.foodVariations !=
                                                null &&
                                            itemController.item!.foodVariations!
                                                .isNotEmpty)
                                          Column(
                                            children: [
                                              FoodVariationSection(
                                                foodVariations: itemController
                                                    .item!.foodVariations!,
                                                item: itemController.item!,
                                                selectedVariations:
                                                    itemController
                                                        .selectedVariations,
                                                onVariationSelected:
                                                    (variationIndex,
                                                        optionIndex) {
                                                  itemController
                                                      .setNewCartVariationIndex(
                                                          variationIndex,
                                                          optionIndex,
                                                          itemController.item!);
                                                },
                                              ),
                                              const SizedBox(
                                                  height: Dimensions
                                                      .paddingSizeLarge),
                                            ],
                                          )
                                        // ✅ DATA-DRIVEN MORPHING: Priority 2 - eCommerce Variations (choiceOptions + variations)
                                        else if (itemController
                                                    .item?.choiceOptions !=
                                                null &&
                                            itemController.item!.choiceOptions!
                                                .isNotEmpty &&
                                            itemController.variationIndex !=
                                                null)
                                          EcommerceVariationSelector(
                                              itemController: itemController),
                                        const SizedBox(
                                            height: Dimensions
                                                .paddingSizeExtraLarge),

                                        ItemPrescriptionBadge(
                                            item: itemController.item),

                                        // Description / nutrition / allergies —
                                        // hidden by the new design, data intact.
                                        ItemExtraInfoSections(
                                          show: _showExtraInfoSections,
                                          controllerItem: itemController.item,
                                          widgetItem: widget.item,
                                        ),

                                        // 🎨 NEW DESIGN: "يُباع معها أيضاً" —
                                        // horizontal strip of 167×190 cards.
                                        ItemSoldWithGrid(
                                            items: itemController
                                                .similarProductsList),
                                        // Breathing room so the floating cart
                                        // doesn't cover the last row.
                                        const SizedBox(height: 100),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Bottom action bar (bag + search)

                            GetBuilder<CartController>(
                                builder: (cartController) {
                              final bool isCampaign =
                                  itemController.item?.availableDateStarts !=
                                      null;

                              Future<void> onAddToCart() async {
                                HapticFeedback.lightImpact();
                                if (!itemController
                                    .ensureRequiredVariationsSelected()) {
                                  return;
                                }
                                if (isCampaign) {
                                  Get.toNamed<void>(
                                      RouteHelper.getCampaignCheckoutRoute(),
                                      arguments: CheckoutScreen(
                                        storeId: null,
                                        fromCart: false,
                                        cartList: [cartModel],
                                      ));
                                } else {
                                  // Cart is now driven live by the +/- counter.
                                  // If the item is already in the cart, just
                                  // open the cart instead of appending its
                                  // quantity again (prevents double-counting).
                                  final int? existingCartId =
                                      itemController.item?.id != null
                                          ? cartController.getCartIdByItemId(
                                              itemController.item!.id!)
                                          : null;
                                  if (existingCartId != null) {
                                    showCartSnackBar(context);
                                    Get.toNamed<dynamic>(
                                        RouteHelper.getCartRoute());
                                    return;
                                  }
                                  // Use smart fallback flow for both new/existing items.
                                  // This avoids stale cartIndex/cartId failures and supports repeated adds.
                                  await cartController
                                      .addToCartWithFallback(
                                    cartModel: cartModel!,
                                    onlineCart: cart!,
                                  )
                                      .then((success) {
                                    if (success && mounted) {
                                      itemController.setExistInCart(
                                          widget.item, null);
                                      if (!context.mounted) {
                                        return;
                                      }
                                      showCartSnackBar(context);
                                      Get.toNamed<dynamic>(
                                          RouteHelper.getCartRoute());
                                      _key.currentState!.shake();
                                    }
                                  });
                                }
                              }

                              return Align(
                                alignment: Alignment.bottomCenter,
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: ItemFloatingCartBar(
                                    isCampaign: isCampaign,
                                    isLoading: cartController.isLoading,
                                    onAddToCart: onAddToCart,
                                    onSearch: () => Get.toNamed<void>(
                                        RouteHelper.getSearchRoute()),
                                  ),
                                ),
                              );
                            }),
                          ])
                    : const ItemDetailsSkeleton()),
          );
        },
      );
    });
  }
}
