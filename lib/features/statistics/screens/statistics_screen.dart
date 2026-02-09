import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/widgets/appBar.dart';
import '../../../util/app_colors.dart';
import '../../../util/dimensions.dart';
import '../controllers/analytics_controller.dart';
import '../widgets/enhanced_summary_cards.dart';
import '../widgets/simple_charts_banner.dart';
import '../widgets/enhanced_most_purchased_products.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetX<AnalyticsController>(
      init: Get.find<AnalyticsController>(),
      builder: (controller) {
        return Scaffold(
          backgroundColor: AppColors.wtColor,
          appBar: custom_AppBar(context,
              title: 'statistics'.tr,
              icon: Icons.arrow_back_sharp,
              titleIcon: Icons.shopping_bag_outlined),
          body: RefreshIndicator(
            onRefresh: () => controller.refreshData(),
            color: AppColors.primaryColor,
            child: controller.isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : const SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: EdgeInsets.all(Dimensions.paddingSizeDefault),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced Summary Cards
                          EnhancedSummaryCards(),
                          SizedBox(height: Dimensions.paddingSizeLarge),

                          // Simple Charts
                          SimpleChartsBanner(),
                          SizedBox(height: Dimensions.paddingSizeLarge),

                          // Enhanced Most Purchased Products
                          EnhancedMostPurchasedProducts(),
                          SizedBox(height: Dimensions.paddingSizeLarge),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }
}
