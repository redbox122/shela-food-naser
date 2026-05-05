import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/appBar.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Wallet peer-transfer transaction details (arguments-driven; no extra API).
class WalletTransactionDetailScreen extends StatefulWidget {
  const WalletTransactionDetailScreen({super.key});

  @override
  State<WalletTransactionDetailScreen> createState() =>
      _WalletTransactionDetailScreenState();
}

class _WalletTransactionDetailScreenState
    extends State<WalletTransactionDetailScreen> {
  bool _didLogOpen = false;

  void _logOpenOnce(Map<String, dynamic>? args) {
    if (_didLogOpen) {
      return;
    }
    _didLogOpen = true;
    if (args == null) {
      debugPrint('[TRANSACTION_DETAILS][OPEN] args=null');
      return;
    }
    final String summary =
        args.entries.map((MapEntry<String, dynamic> e) => '${e.key}=${e.value}').join(', ');
    debugPrint('[TRANSACTION_DETAILS][OPEN] args=$summary');
  }

  void _handleBack(BuildContext context, String? previousRoute) {
    debugPrint(
        '[TRANSACTION_DETAILS][BACK] previousRoute=${previousRoute ?? 'null'}');
    if (Navigator.of(context).canPop()) {
      Get.back();
      return;
    }
    final String fallback = RouteHelper.getSendFundsRoute();
    debugPrint('[TRANSACTION_DETAILS][BACK_FALLBACK] route=$fallback');
    Get.offNamed(fallback);
  }

  bool _hasRequiredArgs({
    required String? transactionId,
    required double? amount,
    required String? transactionType,
    required String? paymentSource,
    required String? recipientName,
  }) {
    return transactionId != null &&
        transactionId.isNotEmpty &&
        amount != null &&
        transactionType != null &&
        transactionType.isNotEmpty &&
        paymentSource != null &&
        paymentSource.isNotEmpty &&
        recipientName != null &&
        recipientName.isNotEmpty;
  }

  String _paymentSourceLabel(String? paymentSource) {
    if (paymentSource == 'wallet_qidha' ||
        paymentSource == 'qidha_wallet' ||
        paymentSource == 'qidha') {
      return 'qidha_wallet'.tr;
    }
    return 'regular_wallet'.tr;
  }

  String? _formatCreatedAt(String? createdAtRaw) {
    if (createdAtRaw == null || createdAtRaw.isEmpty) {
      return null;
    }
    try {
      final DateTime dt = DateConverter.isoStringToLocalDate(createdAtRaw);
      return DateConverter.dateToDateAndTimeAm(dt);
    } catch (_) {
      return createdAtRaw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? rawArgs =
        Get.arguments is Map<String, dynamic> ? Get.arguments as Map<String, dynamic> : null;
    _logOpenOnce(rawArgs);

    final String? transactionId = rawArgs?['transactionId']?.toString();
    final dynamic amountRaw = rawArgs?['amount'];
    final double? amount = amountRaw is num
        ? amountRaw.toDouble()
        : double.tryParse(amountRaw?.toString() ?? '');
    final String? transactionType = rawArgs?['transactionType']?.toString();
    final String? paymentSource = rawArgs?['paymentSource']?.toString();
    final String? recipientName = rawArgs?['recipientName']?.toString();
    final String? createdAtRaw = rawArgs?['createdAt']?.toString();
    final String? previousRoute = rawArgs?['previousRoute']?.toString();

    final bool hasRequiredArgs = _hasRequiredArgs(
      transactionId: transactionId,
      amount: amount,
      transactionType: transactionType,
      paymentSource: paymentSource,
      recipientName: recipientName,
    );

    if (!hasRequiredArgs) {
      debugPrint('[TRANSACTION_DETAILS][MISSING_ARGS]');
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, dynamic result) {
          if (didPop) {
            return;
          }
          _handleBack(context, previousRoute);
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).cardColor,
          appBar: custom_AppBar(
            context,
            title: 'transaction_details'.tr,
            icon: Icons.arrow_back_sharp,
            titleIcon: Icons.receipt_long,
            onPressed: () => _handleBack(context, previousRoute),
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'wallet_transaction_detail_missing_args'.tr,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).disabledColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Dimensions.paddingSizeLarge),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          Get.offNamed(RouteHelper.getSendFundsRoute()),
                      child: Text(
                        'back_to_wallet_screen'.tr,
                        style: robotoBold.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    debugPrint('[TRANSACTION_DETAILS][RENDER] transactionId=$transactionId');

    final String? createdAtDisplay = _formatCreatedAt(createdAtRaw);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) {
          return;
        }
        _handleBack(context, previousRoute);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).cardColor,
        appBar: custom_AppBar(
          context,
          title: 'transaction_details'.tr,
          icon: Icons.arrow_back_sharp,
          titleIcon: Icons.receipt_long,
          onPressed: () => _handleBack(context, previousRoute),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRow(context, 'transaction_id'.tr, transactionId!),
                  const Divider(),
                  _buildRow(
                    context,
                    'amount'.tr,
                    PriceConverter.convertPrice(amount!),
                    highlight: true,
                  ),
                  const Divider(),
                  _buildRow(
                    context,
                    'transaction_type'.tr,
                    transactionType!.tr,
                  ),
                  const Divider(),
                  _buildRow(
                    context,
                    'payment_source'.tr,
                    _paymentSourceLabel(paymentSource),
                  ),
                  const Divider(),
                  _buildRow(context, 'recipient'.tr, recipientName!),
                  if (createdAtDisplay != null) ...[
                    const Divider(),
                    _buildRow(context, 'date'.tr, createdAtDisplay),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    String value, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).disabledColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: (highlight ? robotoBold : robotoMedium).copyWith(
                fontSize:
                    highlight ? Dimensions.fontSizeLarge : Dimensions.fontSizeDefault,
                color: highlight
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodyLarge!.color,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
