import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';

class NoDataScreen extends StatelessWidget {
  final bool isCart;
  final bool showFooter;
  final String? text;
  final String? subtitle;
  final bool fromAddress;
  final Widget? actionWidget;
  const NoDataScreen(
      {super.key,
      required this.text,
      this.isCart = false,
      this.showFooter = false,
      this.subtitle,
      this.fromAddress = false,
      this.actionWidget});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: FooterView(
        visibility: showFooter,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Center(
            child: Image.asset(
              fromAddress
                  ? Images.address
                  : isCart
                      ? Images.empty_cart
                      : Images.noDataFound,
              width: MediaQuery.of(context).size.height * 0.15,
              height: MediaQuery.of(context).size.height * 0.15,
            ),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          Text(
            isCart ? 'cart_is_empty'.tr : text!,
            style: robotoMedium.copyWith(
                fontSize: MediaQuery.of(context).size.height * 0.0175,
                color: fromAddress
                    ? Theme.of(context).textTheme.bodyMedium!.color
                    : Theme.of(context).disabledColor),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            SizedBox(height: MediaQuery.of(context).size.height * 0.008),
            Text(
              subtitle!,
              style: robotoRegular.copyWith(
                fontSize: MediaQuery.of(context).size.height * 0.014,
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionWidget != null && !fromAddress) ...[
            const SizedBox(height: 4),
            actionWidget!,
          ],
          SizedBox(height: MediaQuery.of(context).size.height * 0.03),
          if (isCart)
            Builder(builder: (context) {
              final bool isArabic = Get.locale?.languageCode == 'ar' ||
                  Directionality.of(context) == TextDirection.rtl;
              final String cartEmptyHint = 'cart_empty_hint'.tr;
              final bool isMissingCartHint =
                  cartEmptyHint == 'cart_empty_hint' ||
                      cartEmptyHint == 'cart_empyy_hint';
              final String startShoppingText = 'start_shopping'.tr;
              final bool isMissingStartShopping =
                  startShoppingText == 'start_shopping';

              return Column(
                children: [
                  Text(
                    isMissingCartHint
                        ? (isArabic
                            ? '\u0627\u0628\u062f\u0623 \u0627\u0644\u062a\u0633\u0648\u0642 \u0644\u0627\u0643\u062a\u0634\u0627\u0641 \u0623\u0641\u0636\u0644 \u0627\u0644\u0639\u0631\u0648\u0636 \u0648\u0627\u0644\u0645\u0646\u062a\u062c\u0627\u062a.'
                            : 'Start shopping to discover great deals and products.')
                        : cartEmptyHint,
                    style: robotoRegular.copyWith(
                        fontSize: MediaQuery.of(context).size.height * 0.017,
                        color: Theme.of(context).hintColor),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  InkWell(
                    onTap: () => Get.offAllNamed(
                      RouteHelper.getMainRoute('home'),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusDefault),
                        color: Theme.of(context).primaryColor,
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 22),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.storefront,
                              size: 18.0, color: Theme.of(context).cardColor),
                          const SizedBox(width: 8),
                          Text(
                            isMissingStartShopping
                                ? (isArabic
                                    ? '\u0627\u0628\u062f\u0623 \u0627\u0644\u062a\u0633\u0648\u0642'
                                    : 'Start shopping')
                                : startShoppingText,
                            style: robotoMedium.copyWith(
                                color: Theme.of(context).cardColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                ],
              );
            }),
          fromAddress
              ? Text(
                  'please_add_your_address_for_your_better_experience'.tr,
                  style: robotoMedium.copyWith(
                      fontSize: MediaQuery.of(context).size.height * 0.0175,
                      color: Theme.of(context).disabledColor),
                  textAlign: TextAlign.center,
                )
              : const SizedBox(),
          if (isCart || fromAddress)
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
          fromAddress
              ? InkWell(
                  onTap: () => Get.toNamed<void>(
                      RouteHelper.getAddAddressRoute(false, false, 0)),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusDefault),
                      color: Theme.of(context).primaryColor,
                    ),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_circle_outline_sharp,
                            size: 18.0, color: Theme.of(context).cardColor),
                        Text('add_address'.tr,
                            style: robotoMedium.copyWith(
                                color: Theme.of(context).cardColor)),
                      ],
                    ),
                  ),
                )
              : const SizedBox(),
        ]),
      ),
    );
  }
}
