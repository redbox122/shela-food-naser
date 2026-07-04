import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/smart_image.dart';
import '../../../util/app_colors.dart';
import '../../../util/dimensions.dart';
import '../controllers/analytics_controller.dart';
import '../domain/models/most_purchased_product.dart';
import '../../language/controllers/language_controller.dart';

class SimpleProductDeepDiveScreen extends StatefulWidget {
  final MostPurchasedProduct product;
  final AnalyticsController controller;

  const SimpleProductDeepDiveScreen({
    super.key,
    required this.product,
    required this.controller,
  });

  @override
  State<SimpleProductDeepDiveScreen> createState() =>
      _SimpleProductDeepDiveScreenState();
}

class _SimpleProductDeepDiveScreenState
    extends State<SimpleProductDeepDiveScreen> {
  Map<String, dynamic>? _productAnalytics;
  List<Map<String, dynamic>> _allTransactions = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  // Helper function to safely get translations with fallbacks
  String _tr(String key, String fallback) {
    final translation = key.tr;
    return translation.isNotEmpty && translation != key
        ? translation
        : fallback;
  }

  // Helper function to convert Western Arabic numerals to Eastern Arabic numerals
  String _convertToArabicNumerals(String text) {
    const Map<String, String> arabicNumerals = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩'
    };

    return text.split('').map((char) => arabicNumerals[char] ?? char).join();
  }

  @override
  void initState() {
    super.initState();
    _loadProductAnalytics();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    // No need for infinite scrolling since we get all transactions
    // from the main API response
  }

  Future<void> _loadProductAnalytics({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Force refresh by bypassing any potential caching
      final analytics = await widget.controller.getProductAnalytics(
          widget.product.itemId.toString(),
          forceRefresh: forceRefresh);
      setState(() {
        _productAnalytics = analytics;
        _isLoading = false;
      });

      // Load all transactions after analytics are loaded
      await _loadAllTransactions();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    // Clear any cached data and force fresh API call
    await _loadProductAnalytics(forceRefresh: true);
  }

  Future<void> _loadAllTransactions() async {
    // Since the API doesn't have a separate transactions endpoint,
    // we'll use the purchase_history data from the main analytics response
    if (_productAnalytics != null) {
      final purchaseHistory =
          _productAnalytics!['purchase_history'] as List<dynamic>? ?? [];
      setState(() {
        _allTransactions = List<Map<String, dynamic>>.from(purchaseHistory);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure translations are loaded
    if (!Get.isRegistered<LocalizationController>()) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.wtColor,
      appBar: AppBar(
        backgroundColor: AppColors.greenColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _tr('product_deep_dive_product_details', 'st_product_details'.tr),
          style: const TextStyle(
            color: AppColors.wtColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_sharp, color: AppColors.wtColor),
          onPressed: () => Get.back(),
        ),
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
            color: AppColors.gryColor.withValues(alpha: 0.5),
            size: 64,
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text(
            _tr('failed_to_load_analytics', 'st_analytics_load_failed'.tr),
            style: TextStyle(
              color: AppColors.gryColor.withValues(alpha: 0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          ElevatedButton(
            onPressed: _loadProductAnalytics,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.greenColor,
              foregroundColor: AppColors.wtColor,
            ),
            child: Text(_tr('retry', 'st_retry'.tr)),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.greenColor,
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductHeader(),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            _buildAnalyticsCards(),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            _buildSimplePriceChart(),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            _buildPurchaseHistory(),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            _buildTransactionHistory(),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            _buildRecommendations(),
          ],
        ),
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
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.product.category,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.gryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_convertToArabicNumerals(widget.product.priceRange.current.toStringAsFixed(2))} ر.س',
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
        color: AppColors.gryColor.withValues(alpha: 0.1),
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
                  color: AppColors.gryColor.withValues(alpha: 0.5),
                  size: 40,
                ),
              )
            : Icon(
                Icons.image,
                color: AppColors.gryColor.withValues(alpha: 0.5),
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
            title:
                _tr('product_deep_dive_total_transactions', 'st_total_transactions'.tr),
            value:
                _convertToArabicNumerals((analytics['total_purchases'] ?? 0).toString()),
            color: AppColors.greenColor,
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: _buildAnalyticsCard(
            icon: Icons.account_balance_wallet,
            title: _tr(
                    'product_deep_dive_spent_on_product', 'st_spent_on_product'.tr)
                .replaceAll('{amount}',
                    _convertToArabicNumerals((analytics['total_spent'] ?? 0).toString()))
                .replaceAll('{months}', '1'),
            value:
                '${_convertToArabicNumerals((analytics['total_spent'] ?? 0).toString())} ر.س',
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
              color: AppColors.gryColor,
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

  Widget _buildSimplePriceChart() {
    final priceHistory =
        _productAnalytics!['price_history'] as List<dynamic>? ?? [];

    if (priceHistory.isEmpty) {
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
          Text(
            _tr('price_history', 'st_price_history'.tr),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: SimplePriceChartPainter(priceHistory),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseHistory() {
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
            _tr('product_deep_dive_smart_stats_analytics',
                'st_smart_stats'.tr),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          _buildDetailRow(
              _tr('product_deep_dive_average_quantity', 'st_avg_quantity'.tr),
              '${_convertToArabicNumerals((_productAnalytics!['analytics']?['average_order_value'] ?? 'N/A').toString())} ر.س'),
          _buildDetailRow(
              _tr('product_deep_dive_purchase_frequency_days',
                  'st_purchase_frequency_days'.tr), () {
            final String frequency = _productAnalytics!['analytics']
                        ?['purchase_frequency']
                    ?.toString() ??
                'N/A';

            // Hardcoded Arabic translations as fallback
            switch (frequency.toLowerCase()) {
              case 'daily':
                return 'st_daily'.tr;
              case 'weekly':
                return 'st_weekly'.tr;
              case 'monthly':
                return 'st_monthly'.tr;
              case 'yearly':
                return 'st_yearly'.tr;
              default:
                return frequency;
            }
          }()),
          _buildDetailRow(
              _tr('product_deep_dive_last_purchase_date', 'st_last_purchase_date'.tr),
              _convertToArabicNumerals(_productAnalytics!['analytics']
                          ?['last_purchase']
                      ?.toString() ??
                  'N/A')),
          _buildDetailRow(
              _tr('product_deep_dive_trend_analysis', 'st_trend_analysis'.tr), () {
            final String trend = _productAnalytics!['analytics']?['purchase_pattern']
                        ?['seasonal_trend']
                    ?.toString() ??
                'N/A';

            // Hardcoded Arabic translations as fallback
            switch (trend.toLowerCase()) {
              case 'stable':
                return 'st_stable'.tr;
              case 'increasing':
                return 'st_increasing'.tr;
              case 'decreasing':
                return 'st_decreasing'.tr;
              case 'up':
                return 'st_rising'.tr;
              case 'down':
                return 'st_falling'.tr;
              default:
                return trend;
            }
          }()),
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
                color: AppColors.gryColor,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.title,
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
                _tr('recommendations', 'st_recommendations'.tr),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.title,
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
                color: AppColors.title,
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
              _tr('product_deep_dive_transaction_history', 'st_transactions_date'.tr),
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
                    _tr('product_deep_dive_no_transactions_found',
                        'st_no_transactions'.tr),
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
              Expanded(
                flex: 2,
                child: Text(
                  _tr('product_deep_dive_transaction_history',
                      'st_transactions_date'.tr),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '${purchaseHistory.length} ${_tr('all_transactions', 'st_all_transactions'.tr)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.greyColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _allTransactions.length,
            itemBuilder: (context, index) {
              final transaction = _allTransactions[index];
              return GestureDetector(
                onTap: () {
                  // Navigate to order details screen using the same pattern as wallet
                  final orderId =
                      transaction['invoice']?.toString().replaceAll('#', '') ??
                          '';
                  if (orderId.isNotEmpty) {
                    Get.toNamed(
                        '/order-details?id=$orderId&from=true&from_offline=null&contact=null');
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.greyColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.greyColor.withValues(alpha: 0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.greenColor.withValues(alpha: 0.1),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_tr('order_id', 'معرف الطلب')}: ${transaction['invoice'] ?? 'N/A'}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _convertToArabicNumerals(
                                  (transaction['date'] as String?) ?? 'N/A'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.greyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${_convertToArabicNumerals((transaction['quantity'] ?? 0).toString())} ${_tr('units', 'وحدات')}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textColor,
                              ),
                            ),
                            Text(
                              '${_tr('price_per_unit', 'السعر لكل وحدة')}: ${_convertToArabicNumerals((transaction['unit_price'] ?? 0).toString())} ر.س',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.greyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${_convertToArabicNumerals((transaction['total'] ?? 0).toString())} ر.س',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.greenColor,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 12,
                                  color: AppColors.greenColor,
                                ),
                              ],
                            ),
                            Text(
                              _tr('total_price', 'st_total_price'.tr),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.greyColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SimplePriceChartPainter extends CustomPainter {
  final List<dynamic> priceHistory;

  SimplePriceChartPainter(this.priceHistory);

  @override
  void paint(Canvas canvas, Size size) {
    if (priceHistory.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.greenColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final prices =
        priceHistory.map((e) => (e['price'] as num).toDouble()).toList();
    final maxValue = prices.reduce((a, b) => a > b ? a : b);
    final minValue = prices.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    for (int i = 0; i < prices.length; i++) {
      final x = (i / (prices.length - 1)) * size.width;
      final y = size.height - ((prices[i] - minValue) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw dots
    final dotPaint = Paint()
      ..color = AppColors.greenColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < prices.length; i++) {
      final x = (i / (prices.length - 1)) * size.width;
      final y = size.height - ((prices[i] - minValue) / range) * size.height;
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
