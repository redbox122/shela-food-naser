import 'package:flutter/material.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// 🎨 NEW DESIGN: unit price with the riyal glyph and an optional struck-through
/// original price (matches the card price style).
class ItemPriceText extends StatelessWidget {
  final Item item;
  const ItemPriceText({super.key, required this.item});

  static const Color _priceColor = Color(0xFF121C19);
  static const Color _oldPriceColor = Color(0xFF717885);

  bool get _hasDiscount =>
      (item.originalPrice ?? 0) > 0 &&
      (item.originalPrice ?? 0) > (item.price ?? 0);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Current price first, then the struck-through old price (swapped).
        Text(
          PriceConverter.convertPrice(item.price ?? 0),
          style: tajawalBold.copyWith(
              fontSize: Dimensions.fontSizeLarge, color: _priceColor),
        ),
        const SizedBox(width: 3),
        Image.asset(Images.sar, height: 18, color: _priceColor),
        if (_hasDiscount) ...[
          const SizedBox(width: 8),
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    PriceConverter.convertPrice(item.originalPrice ?? 0),
                    style: tajawalMedium.copyWith(
                        fontSize: 12, color: _oldPriceColor),
                  ),
                  const SizedBox(width: 2),
                  Image.asset(Images.sar, height: 11, color: _oldPriceColor),
                ],
              ),
              Positioned.fill(
                child: Center(child: Container(height: 1.2, color: Colors.red)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
