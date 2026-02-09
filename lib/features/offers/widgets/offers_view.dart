// ignore_for_file: prefer_const_constructors_in_immutables

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:sixam_mart/common/widgets/loading/loading.dart';
import 'package:sixam_mart/features/offers/controllers/offers_controller.dart';
import 'package:sixam_mart/features/offers/domain/models/offers_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import '../../../common/widgets/custom_text.dart';
import '../../../common/widgets/custom_image.dart';
import '../../../helper/route_helper.dart';
import '../../../util/app_colors.dart';
import '../../../util/styles.dart';

class OffersView extends StatelessWidget {
  const OffersView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<Offers_Controller>(
      builder: (controller) {
        final offers = controller.offersMode?.data ?? [];

        if (controller.isLoading == true && offers.isEmpty) {
          return SizedBox(
            height: 140,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor),
              ),
            ),
          );
        }

        // If not loading and no offers, show empty state placeholder
        if (offers.isEmpty) {
          return const EmptyOffersPlaceholder(
            title: 'لا توجد عروض حالياً',
            subtitle: 'تابعنا للحصول على أحدث العروض',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Dimensions.fontSizeLarge),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall,
                vertical: Dimensions.paddingSizeExtraSmall,
              ),
              child: Text(
                'offers'.tr,
                style: robotoBold.copyWith(
                  fontSize: ResponsiveHelper.isDesktop(context)
                      ? Dimensions.fontSizeLarge
                      : Dimensions.fontSizeLarge,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
            SizedBox(
              height: 140,
              child: AnimationLimiter(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: offers.length,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                  ),
                  itemBuilder: (context, index) {
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        horizontalOffset: 50.0,
                        child: FadeInAnimation(
                          child: Offers(
                            offer: offers[index],
                            onTap: () {
                              Get.toNamed<void>(RouteHelper.getOffersItemScreen(
                                  offers[index].id, offers[index].name,
                                  offerDiscount:
                                      offers[index].discountMax?.toDouble()));
                              controller.getOffersItemList(
                                  id: offers[index].id.toString(),
                                  offset: 1);
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
          ],
        );
      },
    );
  }
}

class Offers extends StatelessWidget {
  final Datum offer;
  final GestureTapCallback? onTap;

  const Offers({super.key, required this.offer, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: ResponsiveHelper.isWeb() ? 300 : 250, // عرض البطاقة الأفقي
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // مسافة بين البطاقات
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          // 🎨 UI IMPROVEMENT: Premium design with shadows and rounded corners
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // الصورة
            Stack(
              children: [
                // 🎨 UI IMPROVEMENT: Rounded image with gradient overlay
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      CustomImage(
                        image: offer.banner ?? '',
                        width: 120,
                        height: 120,
                        placeholder: Images.placeholder,
                      ),
                      // Gradient overlay for premium look
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 🎨 UI IMPROVEMENT: Enhanced discount badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppColors.orangeColor,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orangeColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Custom_Text(
                      context,
                      text: '${offer.discountMax ?? 0}%',
                      style: font10White400W(context),
                    ),
                  ),
                ),
              ],
            ),
            // النصوص
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Custom_Text(
                      context,
                      text: offer.name ?? '',
                      textOverFlow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: font10Black600W(context),
                    ),
                    const SizedBox(height: 10),
                    Custom_Text(
                      context,
                      text: 'عدد المنتجات: ${offer.itemsCount ?? 0}',
                      style: font11Grey700W(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state placeholder for offers section
/// Shows a friendly message when no offers are available
class EmptyOffersPlaceholder extends StatelessWidget {
  final String title;
  final String? subtitle;

  const EmptyOffersPlaceholder({
    super.key,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: Dimensions.fontSizeLarge),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeSmall,
            vertical: Dimensions.paddingSizeExtraSmall,
          ),
          child: Text(
            'offers'.tr,
            style: robotoBold.copyWith(
              fontSize: ResponsiveHelper.isDesktop(context)
                  ? Dimensions.fontSizeLarge
                  : Dimensions.fontSizeLarge,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeSmall,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: Dimensions.paddingSizeLarge,
            horizontal: Dimensions.paddingSizeDefault,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 48,
                color: Theme.of(context).disabledColor,
              ),
              const SizedBox(height: Dimensions.paddingSizeDefault),
              Text(
                title,
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                textAlign: TextAlign.center,
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  subtitle!,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).disabledColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
