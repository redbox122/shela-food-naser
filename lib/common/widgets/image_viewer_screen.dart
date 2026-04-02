import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:sixam_mart/features/item/controllers/item_controller.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';

class ImageViewerScreen extends StatelessWidget {
  final Item item;
  final bool isCampaign;
  const ImageViewerScreen(
      {super.key, required this.item, this.isCampaign = false});

  @override
  Widget build(BuildContext context) {
    Get.find<ItemController>().setImageIndex(0, false);
    // ⚡ SMART IMAGE RENDERING: Use raw imagesFullUrl array for gallery view (not optimized helper)
    // Fallback to imageFullUrl if imagesFullUrl is null or empty
    final List<String?> imageList = [];
    if (item.imagesFullUrl != null && item.imagesFullUrl!.isNotEmpty) {
      imageList.addAll(item.imagesFullUrl!);
    } else if (item.imageFullUrl != null && item.imageFullUrl!.isNotEmpty) {
      // Fallback: use single optimized image if raw array is unavailable
      imageList.add(item.imageFullUrl);
    }
    final PageController pageController = PageController();

    return Scaffold(
      appBar: CustomAppBar(title: 'product_images'.tr),
      body: GetBuilder<ItemController>(builder: (itemController) {
        return Column(children: [
          Expanded(
              child: Stack(children: [
            PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration:
                  BoxDecoration(color: Theme.of(context).cardColor),
              itemCount: imageList.length,
              pageController: pageController,
              builder: (BuildContext context, int index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider:
                      CachedNetworkImageProvider('${imageList[index]}'),
                  initialScale: PhotoViewComputedScale.contained,
                  heroAttributes:
                      PhotoViewHeroAttributes(tag: index.toString()),
                );
              },
              loadingBuilder: (context, event) => Center(
                  child: SizedBox(
                      width: 20.0,
                      height: 20.0,
                      child: CircularProgressIndicator(
                        value: event == null
                            ? 0
                            : event.cumulativeBytesLoaded /
                                event.expectedTotalBytes!,
                      ))),
              onPageChanged: (int index) =>
                  itemController.setImageIndex(index, true),
            ),
            itemController.imageIndex != 0
                ? Positioned(
                    left: 5,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: InkWell(
                        onTap: () {
                          if (itemController.imageIndex > 0) {
                            pageController.animateToPage(
                              itemController.imageIndex - 1,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child:
                            const Icon(Icons.chevron_left_outlined, size: 40),
                      ),
                    ),
                  )
                : const SizedBox(),
            itemController.imageIndex != imageList.length - 1
                ? Positioned(
                    right: 5,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        shape: BoxShape.circle,
                      ),
                      child: InkWell(
                        onTap: () {
                          if (itemController.imageIndex < imageList.length) {
                            pageController.animateToPage(
                              itemController.imageIndex + 1,
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child:
                            const Icon(Icons.chevron_right_outlined, size: 40),
                      ),
                    ),
                  )
                : const SizedBox(),
          ])),
        ]);
      }),
    );
  }
}
