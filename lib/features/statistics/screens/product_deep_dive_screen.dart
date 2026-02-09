import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/smart_image.dart';
// import 'package:fl_chart/fl_chart.dart'; // Temporarily disabled due to package issues
import '../../../common/widgets/appBar.dart';
import '../../../util/app_colors.dart';
import '../../../util/dimensions.dart';
import '../controllers/analytics_controller.dart';
import '../domain/models/most_purchased_product.dart';
import '../widgets/product_transaction_item_widget.dart';

class ProductDeepDiveScreen extends StatefulWidget {
  final MostPurchasedProduct product;
  final AnalyticsController controller;

  const ProductDeepDiveScreen({
    super.key,
    required this.product,
    required this.controller,
  });

  @override
  State<ProductDeepDiveScreen> createState() => _ProductDeepDiveScreenState();
}

class _ProductDeepDiveScreenState extends State<ProductDeepDiveScreen> {
  Map<String, dynamic>? _productAnalytics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProductAnalytics();
  }

  Future<void> _loadProductAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analytics = await widget.controller
          .getProductAnalytics(widget.product.itemId.toString());
      setState(() {
        _productAnalytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wtColor,
      appBar: custom_AppBar(
        context,
        title: 'product_deep_dive.product_details'.tr,
        icon: Icons.arrow_back_sharp,
        onPressed: () => Navigator.pop(context),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _productAnalytics == null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.greenColor,
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.greyColor.withValues(alpha: 0.5),
            size: 64,
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text(
            'failed_to_load_analytics'.tr,
            style: TextStyle(
              color: AppColors.greyColor.withValues(alpha: 0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          ElevatedButton(
            onPressed: _loadProductAnalytics,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.greenColor,
              foregroundColor: AppColors.wtColor,
            ),
            child: Text('retry'.tr),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProductHeader(),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          _buildAnalyticsCards(),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          _buildSpendingTrendChart(),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          _buildPurchaseHistory(),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          _buildTransactionHistory(),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: AppColors.wtColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildProductImage(),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.product.category,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.greyColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.product.priceRange.current.toStringAsFixed(2)} ط±.ط³',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.greenColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.greyColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
        child: widget.product.image.isNotEmpty
            ? SmartImage(
                url: widget.product.image,
                height: 80,
                width: 80,
                cacheWidth: 300,
                cacheHeight: 300,
                fit: BoxFit.cover,
                errorWidget: Icon(
                  Icons.image,
                  color: AppColors.greyColor.withValues(alpha: 0.5),
                  size: 40,
                ),
              )
            : Icon(
                Icons.image,
                color: AppColors.greyColor.withValues(alpha: 0.5),
                size: 40,
              ),
      ),
    );
  }

  Widget _buildAnalyticsCards() {
    final analytics =
        _productAnalytics!['analytics'] as Map<String, dynamic>? ?? {};

    return Row(
      children: [
        Expanded(
          child: _buildAnalyticsCard(
            icon: Icons.shopping_cart,
            title: 'product_deep_dive.total_transactions'.tr,
            value: '${analytics['total_purchases'] ?? 0}',
            color: AppColors.greenColor,
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: _buildAnalyticsCard(
            icon: Icons.account_balance_wallet,
            title: 'product_deep_dive.spent_on_product'.tr,
            value: '${analytics['total_spent'] ?? 0} ر.س',
            color: AppColors.blueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: AppColors.wtColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.greyColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingTrendChart() {
    // Temporarily disabled due to fl_chart package issues
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: AppColors.wtColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'product_deep_dive.consumption_graph'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          const Center(
            child: Text(
              'Chart functionality temporarily disabled',
              style: TextStyle(
                color: AppColors.greyColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseHistory() {
    final analytics =
        _productAnalytics!['analytics'] as Map<String, dynamic>? ?? {};

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: AppColors.wtColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'product_deep_dive.smart_stats_analytics'.tr,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          _buildDetailRow('product_deep_dive.average_quantity'.tr,
              '${(analytics['average_order_value'] as num?)?.toDouble() ?? 0} ر.س'),
          _buildDetailRow('product_deep_dive.purchase_frequency_days'.tr,
              (analytics['purchase_frequency'] as String?) ?? 'N/A'),
          _buildDetailRow('product_deep_dive.last_purchase_date'.tr,
              (analytics['last_purchase'] as String?) ?? 'N/A'),
          _buildDetailRow('product_deep_dive.trend_analysis'.tr,
              ((analytics['purchase_pattern'] as Map<String, dynamic>?)?['seasonal_trend'] as String?) ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.greyColor,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations =
        _productAnalytics!['recommendations'] as List<dynamic>? ?? [];

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: AppColors.wtColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: AppColors.orangeColor,
                size: 20,
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Text(
                'recommendations'.tr,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          ...recommendations.map(
              (recommendation) => _buildRecommendationItem(recommendation as String)),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String recommendation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(
                top: 6, right: Dimensions.paddingSizeSmall),
            decoration: const BoxDecoration(
              color: AppColors.orangeColor,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              recommendation,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory() {
    if (_productAnalytics == null) {
      return const SizedBox.shrink();
    }

    final purchaseHistory =
        _productAnalytics!['purchase_history'] as List<dynamic>? ?? [];

    if (purchaseHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          color: AppColors.wtColor,
          borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
          boxShadow: [
            BoxShadow(
              color: AppColors.greyColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'product_deep_dive.transaction_history'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.greyColor,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'product_deep_dive.no_transactions_found'.tr,
                    style: const TextStyle(
                      color: AppColors.textColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: AppColors.wtColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        boxShadow: [
          BoxShadow(
            color: AppColors.greyColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'product_deep_dive.transaction_history'.tr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              Text(
                '${purchaseHistory.length} ${'product_deep_dive.total_transactions'.tr}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.greyColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Enhanced transaction list similar to wallet screen
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: purchaseHistory.length,
            separatorBuilder: (context, index) => Divider(
              color: AppColors.greyColor.withValues(alpha: 0.1),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final transaction = purchaseHistory[index] as Map<String, dynamic>;
              return ProductTransactionItemWidget(
                transaction: transaction,
                index: index,
                onTap: () {
                  // Navigate to order details if needed
                  // Get.toNamed('/order-details?id=${transaction['invoice']}');
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
