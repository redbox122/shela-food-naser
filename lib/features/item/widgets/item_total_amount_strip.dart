import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// 🎨 NEW DESIGN: grey "total amount" strip shown once a quantity is picked.
class ItemTotalAmountStrip extends StatelessWidget {
  final double priceWithAddons;

  const ItemTotalAmountStrip({super.key, required this.priceWithAddons});

  @override
  Widget build(BuildContext context) {
    final TextStyle valueStyle = tajawalBold.copyWith(
      fontSize: Dimensions.fontSizeDefault,
      height: 1.6,
      letterSpacing: 0,
      color: const Color(0xFF43474F),
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Text('total_amount'.tr, style: valueStyle),
        const Expanded(child: SizedBox()),
        PriceConverter.convertPrice2(priceWithAddons, textStyle: valueStyle),
      ]),
    );
  }
}
