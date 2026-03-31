import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/store/widgets/store_description_view_widget.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:get/get.dart';

/// ⚡ TASK 1: Extracted flattened store header for web to reduce nesting
class FlattenedStoreHeaderWeb extends StatelessWidget {
  final Store? store;

  const FlattenedStoreHeaderWeb({
    super.key,
    required this.store,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      alignment: Alignment.center,
      child: SizedBox(
        width: Dimensions.webMaxWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                  child: Stack(
                    children: [
                      Hero(
                        tag: 'store_image_header_${store?.id ?? 0}',
                        child: CustomImage(
                          height: 240,
                          width: 590,
                          image: store?.coverPhotoFullUrl ?? '',
                        ),
                      ),
                      if (store?.discount != null)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                            ),
                            padding: const EdgeInsets.all(
                                Dimensions.paddingSizeExtraSmall),
                            child: Text(
                              '${store?.discount?.discountType == 'percent' ? '${store?.discount?.discount}% ${'off'.tr}' : '${PriceConverter.convertPrice2(store?.discount?.discount ?? 0)} ${'off'.tr}'} '
                              '${'on_all_products'.tr}, ${'after_minimum_purchase'.tr} ${PriceConverter.convertPrice2(store?.discount?.minPurchase ?? 0)},'
                              ' ${'daily_time'.tr}: ${DateConverter.convertTimeToTime(store?.discount?.startTime ?? '')} '
                              '- ${DateConverter.convertTimeToTime(store?.discount?.endTime ?? '')}',
                              style: robotoMedium.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeLarge),
              Expanded(
                child: StoreDescriptionViewWidget(store: store),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
