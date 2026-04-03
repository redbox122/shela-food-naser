import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/cart/controllers/cart_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Sticky cart entry: **edge bubble** on phones (Messenger-style), **full strip**
/// on tablet/desktop/web.
class StickyCartBar extends StatelessWidget {
  const StickyCartBar({
    super.key,
    required this.isEnabled,
    this.cartController,
  });

  final bool isEnabled;
  final CartController? cartController;

  static void _openCart() {
    HapticFeedback.lightImpact();
    Get.toNamed(RouteHelper.getCartRoute());
  }

  @override
  Widget build(BuildContext context) {
    if (!isEnabled) {
      return const SizedBox.shrink();
    }
    final bool edgeLayout = ResponsiveHelper.isMobile(context);
    if (cartController != null) {
      return _StickyCartBarBody(
        cartController: cartController!,
        edgeLayout: edgeLayout,
      );
    }
    if (!Get.isRegistered<CartController>()) {
      return const SizedBox.shrink();
    }
    return GetBuilder<CartController>(
      builder: (CartController cart) {
        return _StickyCartBarBody(
          cartController: cart,
          edgeLayout: edgeLayout,
        );
      },
    );
  }
}

class _StickyCartBarBody extends StatefulWidget {
  const _StickyCartBarBody({
    required this.cartController,
    required this.edgeLayout,
  });

  final CartController cartController;
  final bool edgeLayout;

  @override
  State<_StickyCartBarBody> createState() => _StickyCartBarBodyState();
}

class _StickyCartBarBodyState extends State<_StickyCartBarBody>
    with SingleTickerProviderStateMixin {
  /// Snappy in/out — was 340ms; exit previously had no animation at all.
  static const Duration _kEntranceDuration = Duration(milliseconds: 160);

  late final AnimationController _entrance;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: _kEntranceDuration,
    );
    _fade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0, 0.92, curve: Curves.easeOut),
    );
    final Offset slideBegin = widget.edgeLayout
        ? const Offset(-0.22, 0)
        : const Offset(0, 0.12);
    _slide = Tween<Offset>(
      begin: slideBegin,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entrance,
      curve: Curves.easeOutCubic,
    ));
    if (widget.cartController.shouldShowStickyCartBar) {
      _entrance.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _StickyCartBarBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool wasHidden =
        !oldWidget.cartController.shouldShowStickyCartBar;
    final bool nowShown = widget.cartController.shouldShowStickyCartBar;
    if (wasHidden && nowShown) {
      _entrance.forward(from: 0);
    } else if (nowShown &&
        !_entrance.isCompleted &&
        !_entrance.isAnimating) {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CartController cart = widget.cartController;
    final bool cartWantsShow = cart.shouldShowStickyCartBar;
    if (!cartWantsShow) {
      return const SizedBox.shrink();
    }
    final bool hasItems = cart.cartList.isNotEmpty;
    final bool showLoadingPlaceholder = !hasItems &&
        (cart.isCartDataLoading || cart.serverCartListReplaceInProgress);
    final int itemCount = cart.stickyCartBarDisplayQuantity;
    final double subTotal = cart.stickyCartBarDisplaySubtotal;
    final Widget content = widget.edgeLayout
        ? _StickyCartEdgeBubble(
            itemCount: itemCount,
            subTotal: subTotal,
            showLoadingPlaceholder: showLoadingPlaceholder,
          )
        : _StickyCartWideStrip(
            itemCount: itemCount,
            subTotal: subTotal,
          );
    final EdgeInsets padding = widget.edgeLayout
        ? EdgeInsets.zero
        : EdgeInsets.fromLTRB(
            Dimensions.paddingSizeDefault,
            0,
            Dimensions.paddingSizeDefault,
            Dimensions.paddingSizeSmall,
          );
    final Widget paddedContent = Padding(
      padding: padding,
      child: content,
    );
    final bool useStaticChild =
        cartWantsShow && _entrance.isCompleted && !_entrance.isAnimating;
    if (useStaticChild) {
      return paddedContent;
    }
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: paddedContent,
      ),
    );
  }
}

/// Messenger-style circular chip hugging the screen start edge.
class _StickyCartEdgeBubble extends StatelessWidget {
  const _StickyCartEdgeBubble({
    required this.itemCount,
    required this.subTotal,
    this.showLoadingPlaceholder = false,
  });

  final int itemCount;
  final double subTotal;
  final bool showLoadingPlaceholder;

  static const double _diameter = 56;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.primaryColor;
    final String totalStr = PriceConverter.convertPrice(subTotal);
    final String a11yLabel =
        '${'view_cart'.tr} · $itemCount ${'items'.tr} · ${'total'.tr} $totalStr. '
        '${'sticky_cart_details_hint'.tr}';
    final String badgeLabel = itemCount > 99 ? '99+' : '$itemCount';
    final Widget bubble = Opacity(
      opacity: showLoadingPlaceholder ? 0.88 : 1,
      child: SizedBox(
        width: _diameter,
        height: _diameter,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              width: _diameter,
              height: _diameter,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: primary.withValues(alpha: 0.38),
                    blurRadius: 18,
                    offset: const Offset(4, 6),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                clipBehavior: Clip.antiAlias,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: StickyCartBar._openCart,
                  customBorder: const CircleBorder(),
                  splashColor: AppColors.wtColor.withValues(alpha: 0.2),
                  highlightColor: AppColors.wtColor.withValues(alpha: 0.08),
                  child: Ink(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[
                          primary,
                          primary.withValues(alpha: 0.88),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.92),
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.shopping_bag_rounded,
                        color: AppColors.wtColor,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: -2,
              end: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  badgeLabel,
                  style: robotoBold.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      button: true,
      label: a11yLabel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          bubble,
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 118),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: StickyCartBar._openCart,
                borderRadius: BorderRadius.circular(10),
                splashColor: primary.withValues(alpha: 0.08),
                highlightColor: primary.withValues(alpha: 0.04),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.cardColor.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.14),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    child: Text(
                      'sticky_cart_details_hint'.tr,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: robotoRegular.copyWith(
                        fontSize: 10,
                        height: 1.25,
                        color: AppColors.greyColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Original full-width bottom strip (tablet / desktop / web).
class _StickyCartWideStrip extends StatelessWidget {
  const _StickyCartWideStrip({
    required this.itemCount,
    required this.subTotal,
  });

  final int itemCount;
  final double subTotal;

  static const double _minTapHeight = 54;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.primaryColor;
    const Color ctaOnAccent = AppColors.wtColor;
    final TextDirection dir = Directionality.of(context);
    return Semantics(
      button: true,
      label: '${'view_cart'.tr}, $itemCount ${'items'.tr}, ${'total'.tr}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: StickyCartBar._openCart,
          borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
          splashColor: primary.withValues(alpha: 0.12),
          highlightColor: primary.withValues(alpha: 0.06),
          child: Ink(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusExtraLarge),
              border: Border.all(
                color: primary.withValues(alpha: 0.14),
                width: 1,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: primary.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minTapHeight),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: Dimensions.paddingSizeSmall,
                  end: Dimensions.paddingSizeDefault,
                  top: Dimensions.paddingSizeSmall,
                  bottom: Dimensions.paddingSizeSmall,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusDefault),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Icon(
                          Icons.shopping_bag_rounded,
                          color: primary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeDefault),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$itemCount',
                                  style: robotoBold.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: primary,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'items'.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: robotoMedium.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: AppColors.greyColor,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: <Widget>[
                              Text(
                                '${'total'.tr}  ',
                                style: robotoRegular.copyWith(
                                  fontSize: Dimensions.fontSizeExtraSmall,
                                  color: AppColors.greyColor,
                                  height: 1.2,
                                ),
                              ),
                              Flexible(
                                child: PriceConverter.convertPrice2(
                                  subTotal,
                                  textStyle: robotoBold.copyWith(
                                    fontSize: Dimensions.fontSizeLarge,
                                    color: AppColors.textColor,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: <Color>[
                            AppColors.secondaryColor,
                            AppColors.secondaryColor.withValues(alpha: 0.88),
                          ],
                        ),
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusDefault),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.secondaryColor.withValues(
                                alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            'view_cart'.tr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: ctaOnAccent,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            dir == TextDirection.rtl
                                ? Icons.arrow_back_ios_new_rounded
                                : Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: ctaOnAccent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
