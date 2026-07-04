import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_divider.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/rating_bar.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/order/widgets/address_details_widget.dart';
import 'package:url_launcher/url_launcher_string.dart';

class TrackDetailsViewWidget extends StatelessWidget {
  final String? status;
  final OrderModel track;
  final Function? callback;
  final bool showChatPermission;
  TrackDetailsViewWidget(
      {super.key,
      required this.track,
      required this.status,
      this.callback,
      required this.showChatPermission});

  void _showContactOptions(BuildContext context, bool takeAway) {
    final String phone = takeAway
        ? (track.store?.phone ?? '')
        : (track.deliveryMan?.phone ?? '');

    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('contact_options'.tr, style: robotoMedium),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.wb_sunny_outlined,
                    color: Color(0xFF25D366)),
                title: Text('whatsapp'.tr, style: robotoRegular),
                onTap: () async {
                  Navigator.pop(ctx);
                  final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
                  final url = 'https://wa.me/$cleanPhone';
                  if (await canLaunchUrlString(url)) {
                    await launchUrlString(url,
                        mode: LaunchMode.externalApplication);
                  } else {
                    showCustomSnackBar('${'can_not_launch'.tr} WhatsApp');
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.chat_bubble_outline,
                    color: Theme.of(context).primaryColor),
                title: Text('in_app_chat'.tr, style: robotoRegular),
                onTap: () {
                  Navigator.pop(ctx);
                  if (callback != null) callback!();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double distance = 0;
    final bool takeAway = track.orderType == 'take_away';
    if (track.deliveryMan != null) {
      distance = Geolocator.distanceBetween(
            double.parse(track.deliveryAddress!.latitude!),
            double.parse(track.deliveryAddress!.longitude!),
            double.parse(track.deliveryMan!.lat ?? '0'),
            double.parse(track.deliveryMan!.lng ?? '0'),
          ) /
          1000;
    }

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        color: Theme.of(context).cardColor,
      ),
      alignment: Alignment.center,
      child: (!takeAway && track.deliveryMan == null)
          ? Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              child: Row(
                children: [
                  Text(
                    'delivery_man_not_assigned'.tr,
                    style: robotoMedium,
                    textAlign: TextAlign.center,
                  ),
                  // Card(
                  //   color: Colors.red,
                  //   child: ElevatedButton(
                  //     child: const Text('dataA'),
                  //     onPressed: () async {
                  //       // final controller = Get.find<OrderController>();

                  //       // await controller.trackOrder("100038", null, true, contactNumber: "966599966674");

                  //       // final deliveryManId = controller.trackModel?.deliveryManId?.toString() ?? 'N/A';

                  //       // debugPrint("\x1B[32m  /$deliveryManId  \x1B[0m");

                  //       final location = Get.find<LocationController>();

                  //       // location.get_Location_Delivery_man("100038");
                  //     },
                  //   ),
                  // ),
                ],
              ),
            )
          : Column(children: [
              Text('trip_route'.tr, style: robotoMedium),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              Row(children: [
                Expanded(
                    flex: 3,
                    child: Text(
                      takeAway
                          ? track.deliveryAddress?.address ?? ''
                          : (track.deliveryMan?.location != null &&
                                  track.deliveryMan!.location!.isNotEmpty &&
                                  track.deliveryMan!.location !=
                                      'Location unavailable')
                              ? track.deliveryMan!.location!
                              : track.store?.address ??
                                  'location_not_available'.tr,
                      style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    )),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                SizedBox(
                    width: 80,
                    child: CustomDivider(
                        color: Theme.of(context).primaryColor, height: 2)),
                Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor)),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Expanded(
                  flex: 5,
                  child: (takeAway && track.orderType != 'parcel')
                      ? Text(
                          track.store != null ? track.store!.address! : '',
                          style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : (track.orderType == 'parcel' && status == 'picked_up')
                          ? AddressDetailsWidget(
                              addressDetails: track.receiverDetails)
                          : AddressDetailsWidget(
                              addressDetails: track.deliveryAddress),
                ),
              ]),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              takeAway
                  ? InkWell(
                      onTap: () async {
                        final String url =
                            'https://www.google.com/maps/dir/?api=1&destination=${track.store != null ? track.store!.latitude : ''}'
                            ',${track.store != null ? track.store!.longitude : ''}&mode=d';
                        if (await canLaunchUrlString(url)) {
                          await launchUrlString(url,
                              mode: LaunchMode.externalApplication);
                        } else {
                          showCustomSnackBar('unable_to_launch_google_map'.tr);
                        }
                      },
                      child: Column(children: [
                        Icon(Icons.directions,
                            size: 25, color: Theme.of(context).primaryColor),
                        Text(
                          'direction'.tr,
                          style: robotoRegular.copyWith(
                              fontSize: Dimensions.fontSizeExtraSmall,
                              color: Theme.of(context).disabledColor),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeSmall),
                      ]),
                    )
                  : Column(children: [
                      Image.asset(Images.route,
                          height: 20,
                          width: 20,
                          color: Theme.of(context).primaryColor),
                      Text(
                        '${distance.toStringAsFixed(2)} ${'km'.tr}',
                        style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: Theme.of(context).disabledColor),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),
                    ]),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    takeAway
                        ? Get.find<SplashController>()
                                .configModel!
                                .moduleConfig!
                                .module!
                                .showRestaurantText!
                            ? 'store'.tr
                            : 'store'.tr
                        : 'delivery_man'.tr,
                    style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall),
                  )),
              const SizedBox(height: Dimensions.paddingSizeExtraSmall),
              Row(children: [
                ClipOval(
                    child: CustomImage(
                  image:
                      '${takeAway ? (track.store != null ? track.store!.logoFullUrl : '') : track.deliveryMan!.imageFullUrl}',
                  height: 35,
                  width: 35,
                )),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                        takeAway
                            ? track.store != null
                                ? track.store!.name!
                                : ''
                            : '${track.deliveryMan!.fName} ${track.deliveryMan!.lName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall),
                      ),
                      RatingBar(
                        rating: takeAway
                            ? track.store != null
                                ? track.store!.avgRating
                                : '' as double?
                            : track.deliveryMan!.avgRating,
                        size: 10,
                        ratingCount: takeAway
                            ? track.store != null
                                ? track.store!.ratingCount
                                : '' as int?
                            : track.deliveryMan!.ratingCount,
                      ),
                    ])),
                InkWell(
                  onTap: () async {
                    if (await canLaunchUrlString(
                        'tel:${takeAway ? track.store != null ? track.store!.phone : '' : track.deliveryMan!.phone}')) {
                      launchUrlString(
                          'tel:${takeAway ? track.store != null ? track.store!.phone : '' : track.deliveryMan!.phone}',
                          mode: LaunchMode.externalApplication);
                    } else {
                      showCustomSnackBar(
                          '${'can_not_launch'.tr} ${takeAway ? track.store != null ? track.store!.phone : '' : track.deliveryMan!.phone}');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeExtraSmall,
                        horizontal: Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusSmall),
                      color: Colors.green,
                    ),
                    child: Text(
                      'call'.tr,
                      style: robotoRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: Theme.of(context).cardColor),
                    ),
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                showChatPermission
                    ? InkWell(
                        onTap: () => _showContactOptions(context, takeAway),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: Get.context!.width >= 1300
                                  ? 7
                                  : Dimensions.paddingSizeExtraSmall,
                              horizontal: Dimensions.paddingSizeSmall),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(Dimensions.radiusSmall),
                            color: Colors.green,
                          ),
                          child: Icon(Icons.chat,
                              size: 12, color: Theme.of(context).cardColor),
                        ),
                      )
                    : const SizedBox(),
              ]),
            ]),
    );
  }
}
