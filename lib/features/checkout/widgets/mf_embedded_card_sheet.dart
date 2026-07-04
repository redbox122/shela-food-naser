// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myfatoorah_flutter/myfatoorah_flutter.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Embedded MyFatoorah card payment — the PCI-compliant card form rendered
/// INSIDE the app (no WebView redirect). The card data is entered directly into
/// MyFatoorah's native view (it never touches our code) and tokenized/saved in
/// MyFatoorah (`saveToken: true`). On success the sheet pops with the invoiceId.
///
/// Returns (via Get.back) the invoiceId String on success, or null on
/// cancel/failure so the caller can fall back to the hosted WebView flow.
class MFEmbeddedCardSheet extends StatefulWidget {
  final double amount;
  final String? customerReference;

  const MFEmbeddedCardSheet({
    super.key,
    required this.amount,
    this.customerReference,
  });

  @override
  State<MFEmbeddedCardSheet> createState() => _MFEmbeddedCardSheetState();
}

class _MFEmbeddedCardSheetState extends State<MFEmbeddedCardSheet> {
  // The SAME instance is rendered AND used for load()/pay().
  final MFCardPaymentView _cardView = MFCardPaymentView();

  bool _loading = true; // initiating session
  bool _processing = false; // charging
  String? _invoiceId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSession());
  }

  Future<void> _initSession() async {
    try {
      // saveToken: true → the card is stored in MyFatoorah for reuse.
      final MFInitiateSessionResponse session = await MFSDK.initiateSession(
        MFInitiateSessionRequest(saveToken: true),
        (bin) {},
      );
      // Bind the embedded form to the session so it can collect the card.
      _cardView.load(session, (bin) {});
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      debugPrint('[MF][embedded] initiateSession failed: $e');
      if (mounted) {
        // Pop with null → caller falls back to the hosted WebView flow.
        Get.back<String?>(result: null);
      }
    }
  }

  Future<void> _pay() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final profile = Get.isRegistered<ProfileController>()
          ? Get.find<ProfileController>().userInfoModel
          : null;
      final String name = [profile?.fName, profile?.lName]
          .where((p) => (p ?? '').trim().isNotEmpty)
          .join(' ')
          .trim();

      final MFExecutePaymentRequest request = MFExecutePaymentRequest(
        invoiceValue: widget.amount,
        displayCurrencyIso: 'SAR',
        customerReference: widget.customerReference,
        customerName: name.isNotEmpty ? name : null,
        customerEmail: (profile?.email ?? '').trim().isNotEmpty
            ? profile!.email
            : null,
      );

      // Charges the entered card IN-APP (3DS may show briefly when required).
      final MFGetPaymentStatusResponse status = await _cardView.pay(
        request,
        MFLanguage.ARABIC,
        (invoiceId) {
          if (invoiceId.isNotEmpty) _invoiceId = invoiceId;
        },
        currency: 'SAR',
      );

      if ((status.invoiceId ?? 0) != 0) {
        _invoiceId = status.invoiceId.toString();
      }
      final String st = (status.invoiceStatus ?? '').toLowerCase();
      final bool paid = st == 'paid' || st == 'success';
      debugPrint(
          '[MF][embedded] pay status=$st invoiceId=$_invoiceId paid=$paid');

      if (paid && (_invoiceId?.isNotEmpty ?? false)) {
        Get.back<String?>(result: _invoiceId);
      } else {
        setState(() => _processing = false);
        showCustomSnackBar('pay_card_failed_retry'.tr,
            isError: true);
      }
    } catch (e) {
      debugPrint('[MF][embedded] pay failed: $e');
      if (mounted) setState(() => _processing = false);
      showCustomSnackBar('pay_card_failed'.tr, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: Dimensions.paddingSizeLarge,
        right: Dimensions.paddingSizeLarge,
        top: Dimensions.paddingSizeLarge,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            Dimensions.paddingSizeLarge,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('pay_card_payment'.tr,
                  style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge)),
              const Spacer(),
              IconButton(
                onPressed: () => Get.back<String?>(result: null),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.amount.toStringAsFixed(2)} ﷼',
            textAlign: TextAlign.center,
            style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeOverLarge,
                color: const Color(0xFF30913F)),
          ),
          const SizedBox(height: 16),

          // The embedded MyFatoorah card form (native PCI view).
          SizedBox(
            height: 240,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF30913F)))
                : _cardView,
          ),
          const SizedBox(height: 16),

          Material(
            color: const Color(0xFF30913F),
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _loading || _processing ? null : _pay,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: _processing
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text('pay_pay_now'.tr,
                          style: robotoBold.copyWith(
                              color: Colors.white,
                              fontSize: Dimensions.fontSizeLarge)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'pay_card_saved'.tr,
            textAlign: TextAlign.center,
            style: robotoRegular.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
                color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }
}
