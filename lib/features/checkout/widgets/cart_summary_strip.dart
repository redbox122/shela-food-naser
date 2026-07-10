import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/smart_image.dart';
import 'package:sixam_mart/features/cart/domain/models/cart_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Presentational cart summary shown at the top of the checkout screen.
///
/// Design ported from the old app: renders "يوجد @count منتجات في سلتك" using the
/// dynamic cart count and a horizontal row of small rounded product thumbnails.
/// Pure UI — it reads the already-loaded [cartList] (the new app's own
/// CartController data) and performs no business logic.
class CartSummaryStrip extends StatelessWidget {
  final List<CartModel?>? cartList;
  const CartSummaryStrip({super.key, required this.cartList});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<CartModel> items =
        (cartList ?? const <CartModel?>[]).whereType<CartModel>().toList();
    if (items.isEmpty) return const SizedBox();

    final bool isDark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      color: isDark ? theme.scaffoldBackgroundColor : theme.cardColor,
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeLarge,
        vertical: Dimensions.paddingSizeDefault,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'items_in_your_cart'.trParams({'count': '${items.length}'}),
            textAlign: TextAlign.right,
            style: tajawalBold.copyWith(
              fontSize: 18,
              height: 1.6,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: Dimensions.paddingSizeSmall),
              itemBuilder: (context, index) {
                final String url = items[index].item?.displayImage ?? '';
                return Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xffF6F5F8),
                    borderRadius:
                        BorderRadius.circular(Dimensions.radiusDefault),
                    border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.6)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SmartImage(
                    url: url,
                    height: 90,
                    width: 90,
                    fit: BoxFit.contain,
                    errorWidget: Icon(Icons.fastfood_outlined,
                        size: 22, color: theme.disabledColor),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
