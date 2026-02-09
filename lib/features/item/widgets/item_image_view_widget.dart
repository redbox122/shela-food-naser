import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';

class ItemImageViewWidget extends StatelessWidget {
  final Item? item;
  final bool isCampaign;
  ItemImageViewWidget({super.key, required this.item, this.isCampaign = false});

  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    final List<String?> imageList = [];
    final List<String?> imageListForCampaign = [];

    if (isCampaign) {
      // Campaign items use optimized imageFullUrl (correct)
      imageListForCampaign.add(item!.imageFullUrl);
    } else {
      // ⚡ SMART IMAGE RENDERING: Use raw imagesFullUrl array for gallery view (not optimized helper)
      // Fallback to imageFullUrl if imagesFullUrl is null or empty
      if (item!.imagesFullUrl != null && item!.imagesFullUrl!.isNotEmpty) {
        imageList.addAll(item!.imagesFullUrl!);
      } else if (item!.imageFullUrl != null && item!.imageFullUrl!.isNotEmpty) {
        // Fallback: use single optimized image if raw array is unavailable
        imageList.add(item!.imageFullUrl);
      }
    }

    return GetBuilder<ItemController>(builder: (itemController) {
      return Column(mainAxisSize: MainAxisSize.min, children: [
        InkWell(
          onTap: isCampaign
              ? null
              : () {
                  if (!isCampaign) {
                    Navigator.of(context).pushNamed(RouteHelper.getItemImagesRoute(item!), arguments: ItemImageViewWidget(item: item));
                  }
                },
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                  child: Container(
                    height: ResponsiveHelper.isDesktop(context) 
                        ? 400 
                        : MediaQuery.of(context).size.width * 0.85,
                    width: double.infinity,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: isCampaign ? imageListForCampaign.length : imageList.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                          child: Center(
                            child: CustomImage(
                              image: '${isCampaign ? imageListForCampaign[index] : imageList[index]}',
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          ),
                        );
                      },
                      onPageChanged: (index) {
                        itemController.setImageSliderIndex(index);
                      },
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: Dimensions.paddingSizeSmall,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _indicators(context, itemController, isCampaign ? imageListForCampaign : imageList),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]);
    });
  }

  List<Widget> _indicators(BuildContext context, ItemController itemController, List<String?> imageList) {
    final List<Widget> indicators = [];
    for (int index = 0; index < imageList.length; index++) {
      indicators.add(TabPageSelectorIndicator(
        backgroundColor: index == itemController.imageSliderIndex ? Theme.of(context).primaryColor : Colors.white,
        borderColor: Colors.white,
        size: 10,
      ));
    }
    return indicators;
  }
}
