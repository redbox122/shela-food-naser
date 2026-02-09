import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/features/wallet_transfer/controllers/wallet_transfer_controller.dart';
import 'package:sixam_mart/features/wallet_transfer/widgets/payment_source_selector_widget.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// Bottom sheet for sending funds with swipe-to-send functionality
class SendFundBottomSheet extends StatefulWidget {
  final String recipientName;
  final String recipientPhone;
  final Function(String, String, String?)
      onSend; // paymentSource, amount, message
  final Function()? onChangeReceiver; // Callback for change receiver

  const SendFundBottomSheet({
    super.key,
    required this.recipientName,
    required this.recipientPhone,
    required this.onSend,
    this.onChangeReceiver,
  });

  @override
  State<SendFundBottomSheet> createState() => _SendFundBottomSheetState();
}

class _SendFundBottomSheetState extends State<SendFundBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  String _selectedPaymentSource = 'wallet';
  bool _isSending = false;

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// Handles send action
  void _handleSend() {
    final amount = _amountController.text.trim();
    if (amount.isEmpty) {
      Get.snackbar('error'.tr, 'please_enter_amount'.tr);
      return;
    }

    final amountValue = double.tryParse(amount);
    if (amountValue == null || amountValue <= 0) {
      Get.snackbar('error'.tr, 'invalid_amount'.tr);
      return;
    }

    final controller = Get.find<WalletTransferController>();
    if (!controller.canTransfer(amountValue, _selectedPaymentSource)) {
      Get.snackbar('error'.tr, 'insufficient_balance'.tr);
      return;
    }

    setState(() {
      _isSending = true;
    });

    widget.onSend(
      _selectedPaymentSource,
      amount,
      _messageController.text.trim().isEmpty
          ? null
          : _messageController.text.trim(),
    );
  }

  /// Handles change receiver
  Future<void> _handleChangeReceiver() async {
    if (widget.onChangeReceiver != null) {
      widget.onChangeReceiver!();
    } else {
      Get.back(); // Close bottom sheet
      // Navigate back to choose receiver screen
      final BuildContext buildContext = context;
      final result = await Get.toNamed(RouteHelper.getChooseReceiverRoute());
      if (result != null && result is Map) {
        final recipientName = result['name'] as String? ?? '';
        final recipientPhone = result['phone'] as String? ?? '';

        if (recipientName.isNotEmpty && recipientPhone.isNotEmpty) {
          // Show new bottom sheet with updated recipient
          if (!buildContext.mounted) {
            return;
          }
          showModalBottomSheet(
            context: buildContext,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => SendFundBottomSheet(
              recipientName: recipientName,
              recipientPhone: recipientPhone,
              onSend: widget.onSend,
              onChangeReceiver: widget.onChangeReceiver,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLtr = Get.find<LocalizationController>().isLtr;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(Dimensions.radiusExtraLarge),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () => Get.back(),
                    ),
                    Expanded(
                      child: Text(
                        'send_fund'.tr,
                        style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeExtraLarge,
                          color: Theme.of(context).primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance close button width
                  ],
                ),
              ),

              const Divider(height: 1),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount input
                      _buildAmountInput(),

                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      // Payment source selector
                      PaymentSourceSelectorWidget(
                        selectedSource: _selectedPaymentSource,
                        onSourceChanged: (source) {
                          setState(() {
                            _selectedPaymentSource = source;
                          });
                        },
                      ),

                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      // Message field (optional)
                      _buildMessageField(),

                      const SizedBox(height: Dimensions.paddingSizeLarge),

                      // Send to section
                      _buildSendToSection(),

                      const SizedBox(height: Dimensions.paddingSizeExtraLarge),
                    ],
                  ),
                ),
              ),

              // Swipe button
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'swipe_to_send_fund'.tr,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    _buildSwipeButton(context, isLtr),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Builds amount input field
  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'amount_to_send'.tr,
          style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeLarge,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: 'ريال ',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
          ),
          style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
          onChanged: (value) {
            setState(() {});
          },
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        GetBuilder<WalletTransferController>(
          builder: (controller) {
            final balance = _selectedPaymentSource == 'wallet'
                ? Get.find<WalletTransferController>()
                    .getAvailableBalance(_selectedPaymentSource)
                : Get.find<WalletTransferController>()
                    .getAvailableBalance(_selectedPaymentSource);
            return Text(
              '${'available_balance'.tr}: ${balance.toStringAsFixed(2)}',
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).disabledColor,
              ),
            );
          },
        ),
      ],
    );
  }

  /// Builds message field
  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'message_optional'.tr,
          style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeLarge,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        TextField(
          controller: _messageController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'enter_message'.tr,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds send to section
  Widget _buildSendToSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'send_to'.tr,
          style: robotoBold.copyWith(
            fontSize: Dimensions.fontSizeLarge,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            border: Border.all(
              color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    Theme.of(context).primaryColor.withValues(alpha: 0.1),
                radius: 24,
                child: Text(
                  widget.recipientName.isNotEmpty
                      ? widget.recipientName[0].toUpperCase()
                      : '?',
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.recipientName,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.recipientPhone,
                      style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _handleChangeReceiver,
                child: Text(
                  'change'.tr,
                  style: robotoMedium.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds custom swipe button
  Widget _buildSwipeButton(BuildContext context, bool isLtr) {
    return _CustomSwipeButton(
      isActive: !_isSending && _amountController.text.isNotEmpty,
      buttonText: 'send_money'.tr,
      activeColor: Theme.of(context).primaryColor,
      inactiveColor: Colors.grey.shade300,
      onSwipeComplete: _handleSend,
      swipeDirection: isLtr ? SwipeDirection.right : SwipeDirection.left,
    );
  }
}

/// Custom swipe button widget
enum SwipeDirection { left, right }

class _CustomSwipeButton extends StatefulWidget {
  final bool isActive;
  final String buttonText;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onSwipeComplete;
  final SwipeDirection swipeDirection;

  const _CustomSwipeButton({
    required this.isActive,
    required this.buttonText,
    required this.activeColor,
    required this.inactiveColor,
    required this.onSwipeComplete,
    required this.swipeDirection,
  });

  @override
  State<_CustomSwipeButton> createState() => _CustomSwipeButtonState();
}

class _CustomSwipeButtonState extends State<_CustomSwipeButton>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  late AnimationController _controller;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width =
        MediaQuery.of(context).size.width - (Dimensions.paddingSizeLarge * 2);
    final maxDrag = width - 80;
    final isRightSwipe = widget.swipeDirection == SwipeDirection.right;

    return Container(
      width: width,
      height: 56,
      decoration: BoxDecoration(
        color: widget.isActive ? widget.inactiveColor : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          // Background text
          Center(
            child: Text(
              widget.buttonText,
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: widget.isActive ? Colors.white : Colors.grey.shade600,
              ),
            ),
          ),
          // Draggable button
          if (widget.isActive && !_isCompleted)
            Positioned(
              left: isRightSwipe ? _dragPosition.clamp(0.0, maxDrag) : null,
              right: isRightSwipe ? null : _dragPosition.clamp(0.0, maxDrag),
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  if (!widget.isActive || _isCompleted) return;

                  setState(() {
                    if (isRightSwipe) {
                      _dragPosition += details.delta.dx;
                    } else {
                      _dragPosition -= details.delta.dx;
                    }
                    _dragPosition = _dragPosition.clamp(0.0, maxDrag);

                    if (_dragPosition >= maxDrag * 0.9) {
                      _isCompleted = true;
                      widget.onSwipeComplete();
                    }
                  });
                },
                onHorizontalDragEnd: (details) {
                  if (!_isCompleted) {
                    setState(() {
                      _dragPosition = 0.0;
                    });
                  }
                },
                child: Container(
                  width: 80,
                  height: 56,
                  decoration: BoxDecoration(
                    color: widget.activeColor,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: widget.activeColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isRightSwipe ? Icons.arrow_back : Icons.arrow_forward,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
