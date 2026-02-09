import 'package:flutter/material.dart';
import 'package:sixam_mart/features/home/widgets/banner_view.dart';
import 'package:sixam_mart/features/offers/widgets/offers_view.dart';
import 'package:sixam_mart/util/dimensions.dart';

class PromotionalBannerView extends StatelessWidget {
  const PromotionalBannerView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banners - Display featured banners loaded by multi-module screen
        BannerView(isFeatured: true),
        
        SizedBox(height: Dimensions.paddingSizeDefault),
        
        // Offers
        OffersView(),
        
        SizedBox(height: Dimensions.paddingSizeLarge),
      ],
    );
  }
}
