import 'package:sixam_mart/features/category/controllers/category_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/item_shimmer.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Get.find<CategoryController>().getCategoryList(false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(title: 'categories'.tr),
      body: SafeArea(
          child: SingleChildScrollView(
              controller: scrollController,
              child: FooterView(
                  child: Column(
                children: [
                  WebScreenTitleWidget(title: 'categories'.tr),
                  SizedBox(
                    width: Dimensions.webMaxWidth,
                    child: GetBuilder<CategoryController>(builder: (catController) {
                      return catController.hasCategoryError &&
                              !catController.isLoading &&
                              (catController.categoryList == null ||
                                  catController.categoryList!.isEmpty)
                          ? ErrorStateView(
                              onRetry: () {
                                catController.getCategoryList(false);
                              },
                            )
                          : catController.categoryList != null
                          ? catController.categoryList!.isNotEmpty
                              ? GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  shrinkWrap: true,
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: ResponsiveHelper.isDesktop(context)
                                        ? 6
                                        : ResponsiveHelper.isMobile(context)
                                            ? 4
                                            : 3,
                                    mainAxisSpacing: Dimensions.paddingSizeSmall,
                                    crossAxisSpacing: Dimensions.paddingSizeSmall,
                                    mainAxisExtent: 150, // ✅ ارتفاع ثابت لكل item لمنع overflow
                                  ),
                                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                                  itemCount: catController.categoryList!.length,
                                  itemBuilder: (context, index) {
                                    return InkWell(
                                      onTap: () => Get.toNamed(RouteHelper.getCategoryItemRoute(
                                        catController.categoryList![index].id,
                                        catController.categoryList![index].name!,
                                      )),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).cardColor,
                                          borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)],
                                        ),
                                        padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                                              child: CustomImage(
                                                height: 90,
                                                width: 80,
                                                image: '${catController.categoryList![index].imageFullUrl}',
                                              ),
                                            ),
                                            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                                            Flexible(
                                              child: Text(
                                                catController.categoryList![index].name!,
                                                textAlign: TextAlign.center,
                                                style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : NoDataScreen(text: 'no_category_found'.tr)
                          : ListView.builder(
                              itemCount: 5,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) => ItemShimmer(
                                isEnabled: true,
                                hasDivider: index < 4,
                              ),
                            ); // ⚡ TASK 2: Instant skeleton morphing
                    }),
                  ),
                ],
              )))),
    );
  }
}
