
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:myfatoorah_flutter/MFModels.dart';
import 'package:myfatoorah_flutter/myfatoorah_flutter.dart';
import 'package:sixam_mart/common/controllers/theme_controller.dart';
import 'package:sixam_mart/common/widgets/smart_image.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// In-App Payment Modal Widget
/// 
/// This widget provides an elegant in-app payment experience that matches the app's design.
/// It handles payment method selection and form input for various payment types including
/// Apple Pay, Google Pay, Mada, Visa, and other card payments.
class InAppPaymentModal extends StatefulWidget {
  final double amount;
  final void Function(String invoiceId)? onPaymentSuccess;
  final void Function(String error)? onPaymentError;
  final VoidCallback? onCancel;

  const InAppPaymentModal({
    super.key,
    required this.amount,
    this.onPaymentSuccess,
    this.onPaymentError,
    this.onCancel,
  });

  @override
  State<InAppPaymentModal> createState() => _InAppPaymentModalState();
}

class _InAppPaymentModalState extends State<InAppPaymentModal>
    with TickerProviderStateMixin {
  final CheckoutController _checkoutController = Get.find<CheckoutController>();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Form controllers
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryMonthController = TextEditingController();
  final TextEditingController _expiryYearController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardholderNameController = TextEditingController();

  // Focus nodes
  final FocusNode _cardNumberFocus = FocusNode();
  final FocusNode _expiryMonthFocus = FocusNode();
  final FocusNode _expiryYearFocus = FocusNode();
  final FocusNode _cvvFocus = FocusNode();
  final FocusNode _cardholderNameFocus = FocusNode();

  // Form state
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;
  int _selectedPaymentMethodIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardNumberController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    _cardNumberFocus.dispose();
    _expiryMonthFocus.dispose();
    _expiryYearFocus.dispose();
    _cvvFocus.dispose();
    _cardholderNameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
      ),
      insetPadding: EdgeInsets.all(ResponsiveHelper.isDesktop(context) ? 50 : 20),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
                maxWidth: ResponsiveHelper.isDesktop(context) ? 500 : double.infinity,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAmountDisplay(),
                            const SizedBox(height: Dimensions.paddingSizeLarge),
                            _buildPaymentMethodsList(),
                            const SizedBox(height: Dimensions.paddingSizeLarge),
            if (_selectedPaymentMethodIndex >= 0) ...[
              const SizedBox(height: Dimensions.paddingSizeDefault),
              _buildPaymentForm(),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              _buildActionButtons(),
            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.radiusLarge),
          topRight: Radius.circular(Dimensions.radiusLarge),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.payment,
            color: Theme.of(context).primaryColor,
            size: 24,
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(
              'payment'.tr,
              style: robotoBold.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          IconButton(
            onPressed: _handleCancel,
            icon: Icon(
              Icons.close,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Get.find<ThemeController>().darkTheme
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            'total_amount'.tr,
            style: robotoRegular.copyWith(
              color: Theme.of(context).hintColor,
              fontSize: Dimensions.fontSizeDefault,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          PriceConverter.convertPrice2(
            widget.amount,
            textStyle: robotoBold.copyWith(
              color: Theme.of(context).primaryColor,
              fontSize: Dimensions.fontSizeOverLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsList() {
    return GetBuilder<CheckoutController>(
      id: 'payment', // ✅ استخدام ID لتحديث جزئي
      builder: (checkoutController) {
        if (checkoutController.paymentMethods.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: Text('pay_no_methods2'.tr),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'select_payment_method'.tr,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: checkoutController.paymentMethods.length,
                itemBuilder: (context, index) {
                  final paymentMethod = checkoutController.paymentMethods[index];
                  final isSelected = _selectedPaymentMethodIndex == index;

                  return GestureDetector(
                    onTap: () => _selectPaymentMethod(index, paymentMethod),
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Theme.of(context).disabledColor.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SmartImage(
                            url: paymentMethod.imageUrl ?? '',
                            height: 40,
                            width: 40,
                            cacheWidth: 300,
                            cacheHeight: 300,
                            errorWidget: Icon(
                              Icons.payment,
                              size: 40,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSizeSmall),
                          Text(
                            paymentMethod.paymentMethodEn ?? '',
                            style: robotoMedium.copyWith(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Theme.of(context).textTheme.bodyMedium?.color,
                              fontSize: Dimensions.fontSizeSmall,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentForm() {
    if (_selectedPaymentMethodIndex < 0) return const SizedBox.shrink();

    final paymentMethod = _checkoutController.paymentMethods[_selectedPaymentMethodIndex];
    final paymentMethodName = paymentMethod.paymentMethodEn?.toLowerCase() ?? '';

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment method header
          Row(
            children: [
              Icon(
                Icons.credit_card,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Text(
                '${'payment_details_for'.tr} ${paymentMethod.paymentMethodEn}',
                style: robotoMedium.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          
          // Payment form content
          if (paymentMethodName.contains('apple') || paymentMethodName.contains('google')) 
            _buildDigitalWalletPayment(paymentMethod)
          else 
            _buildCardPaymentForm(),
        ],
      ),
    );
  }

  Widget _buildDigitalWalletPayment(MFPaymentMethod paymentMethod) {
    return Column(
      children: [
        Icon(
          Icons.contactless,
          size: 60,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
        Text(
          '${'secure_payment_with'.tr} ${paymentMethod.paymentMethodEn}',
          style: robotoMedium.copyWith(
            fontSize: Dimensions.fontSizeLarge,
            color: Theme.of(context).primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        Text(
          'tap_to_pay'.tr,
          style: robotoRegular.copyWith(
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCardPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        // Card Number
        _buildTextField(
          controller: _cardNumberController,
          focusNode: _cardNumberFocus,
          label: 'card_number'.tr,
          hint: '1234 5678 9012 3456',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(19),
            CardNumberInputFormatter(),
          ],
          validator: _validateCardNumber,
          onChanged: (value) => _formatCardNumber(value),
        ),
        
        const SizedBox(height: Dimensions.paddingSizeDefault),
        
        // Expiry Date and CVV Row
        Row(
          children: [
            // Expiry Month
            Expanded(
              child: _buildTextField(
                controller: _expiryMonthController,
                focusNode: _expiryMonthFocus,
                label: 'month'.tr,
                hint: 'MM',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                validator: _validateExpiryMonth,
                onChanged: (value) => _formatExpiryMonth(value),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            
            // Expiry Year
            Expanded(
              child: _buildTextField(
                controller: _expiryYearController,
                focusNode: _expiryYearFocus,
                label: 'year'.tr,
                hint: 'YY',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                validator: _validateExpiryYear,
                onChanged: (value) => _formatExpiryYear(value),
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            
            // CVV
            Expanded(
              child: _buildTextField(
                controller: _cvvController,
                focusNode: _cvvFocus,
                label: 'cvv'.tr,
                hint: '123',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: _validateCVV,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: Dimensions.paddingSizeDefault),
        
        // Cardholder Name
        _buildTextField(
          controller: _cardholderNameController,
          focusNode: _cardholderNameFocus,
          label: 'cardholder_name'.tr,
          hint: 'john_doe'.tr,
          textCapitalization: TextCapitalization.words,
          validator: _validateCardholderName,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: robotoMedium.copyWith(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: Dimensions.fontSizeDefault,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          validator: validator,
          onChanged: onChanged,
          style: robotoRegular.copyWith(
            fontSize: Dimensions.fontSizeDefault,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: robotoRegular.copyWith(
              color: Theme.of(context).hintColor,
            ),
            filled: true,
            fillColor: Theme.of(context).cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              borderSide: BorderSide(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              borderSide: BorderSide(
                color: Theme.of(context).disabledColor.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              borderSide: const BorderSide(
                color: Colors.red,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeDefault,
              vertical: Dimensions.paddingSizeDefault,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isProcessing ? null : _handleCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                vertical: Dimensions.paddingSizeDefault,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                side: BorderSide(
                  color: Theme.of(context).disabledColor,
                ),
              ),
            ),
            child: Text(
              'cancel'.tr,
              style: robotoMedium.copyWith(
                color: Theme.of(context).disabledColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: Dimensions.paddingSizeDefault),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _handlePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(
                vertical: Dimensions.paddingSizeDefault,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
              ),
            ),
            child: _isProcessing
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).cardColor,
                      ),
                    ),
                  )
                : Text(
                    'pay_now'.tr,
                    style: robotoMedium.copyWith(
                      color: Theme.of(context).cardColor,
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _selectPaymentMethod(int index, MFPaymentMethod paymentMethod) {
    setState(() {
      _selectedPaymentMethodIndex = index;
    });
    
    // If it's a card payment method, automatically focus on the first card field
    if (_checkoutController.requiresCardDetails(paymentMethod)) {
      // Small delay to ensure the form is rendered
      Future.delayed(const Duration(milliseconds: 100), () {
        _cardNumberFocus.requestFocus();
      });
    }
  }

  void _handleCancel() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
      widget.onCancel?.call();
    });
  }

  Future<void> _handlePayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final paymentMethod = _checkoutController.paymentMethods[_selectedPaymentMethodIndex];
      final paymentMethodName = paymentMethod.paymentMethodEn?.toLowerCase() ?? '';

      bool success = false;

      if (paymentMethodName.contains('apple') || paymentMethodName.contains('google')) {
        // Handle digital wallet payments
        success = await _processDigitalWalletPayment(paymentMethod);
      } else {
        // Handle card payments
        success = await _processCardPayment(paymentMethod);
      }

      if (success) {
        _animationController.reverse().then((_) {
          Navigator.of(context).pop();
          widget.onPaymentSuccess?.call(_checkoutController.lastInvoiceId);
        });
      } else {
        setState(() {
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      widget.onPaymentError?.call(e.toString());
    }
  }

  Future<bool> _processDigitalWalletPayment(MFPaymentMethod paymentMethod) async {
    // For digital wallet payments, we'll use the existing executePayment method
    // but in a way that doesn't open external popup
    return await _checkoutController.processDigitalWalletPayment(
      paymentMethod,
      widget.amount.toString(),
    );
  }

  Future<bool> _processCardPayment(MFPaymentMethod paymentMethod) async {
    // Create card data map for direct payment
    final cardData = {
      'cardNumber': _cardNumberController.text.replaceAll(' ', ''),
      'expiryMonth': _expiryMonthController.text.padLeft(2, '0'),
      'expiryYear': _expiryYearController.text,
      'cvv': _cvvController.text,
      'cardholderName': _cardholderNameController.text,
    };

    return await _checkoutController.processDirectPayment(
      paymentMethod,
      widget.amount.toString(),
      cardData,
    );
  }

  // Validation methods
  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'card_number_required'.tr;
    }
    final cleanValue = value.replaceAll(' ', '');
    if (cleanValue.length < 13 || cleanValue.length > 19) {
      return 'invalid_card_number'.tr;
    }
    if (!_isValidCardNumber(cleanValue)) {
      return 'invalid_card_number'.tr;
    }
    return null;
  }

  String? _validateExpiryMonth(String? value) {
    if (value == null || value.isEmpty) {
      return 'month_required'.tr;
    }
    final month = int.tryParse(value);
    if (month == null || month < 1 || month > 12) {
      return 'invalid_month'.tr;
    }
    return null;
  }

  String? _validateExpiryYear(String? value) {
    if (value == null || value.isEmpty) {
      return 'year_required'.tr;
    }
    final year = int.tryParse(value);
    if (year == null || year < 0 || year > 99) {
      return 'invalid_year'.tr;
    }
    final currentYear = DateTime.now().year % 100;
    if (year < currentYear) {
      return 'expired_year'.tr;
    }
    return null;
  }

  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'cvv_required'.tr;
    }
    if (value.length < 3 || value.length > 4) {
      return 'invalid_cvv'.tr;
    }
    return null;
  }

  String? _validateCardholderName(String? value) {
    if (value == null || value.isEmpty) {
      return 'cardholder_name_required'.tr;
    }
    if (value.length < 2) {
      return 'invalid_cardholder_name'.tr;
    }
    return null;
  }

  // Formatting methods
  void _formatCardNumber(String value) {
    final cleanValue = value.replaceAll(' ', '');
    final formatted = _addSpacesToCardNumber(cleanValue);
    if (formatted != value) {
      _cardNumberController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _formatExpiryMonth(String value) {
    if (value.length == 2) {
      _expiryYearFocus.requestFocus();
    }
  }

  void _formatExpiryYear(String value) {
    if (value.length == 2) {
      _cvvFocus.requestFocus();
    }
  }

  String _addSpacesToCardNumber(String cardNumber) {
    return cardNumber.replaceAllMapped(
      // ignore: deprecated_member_use
      RegExp(r'.{4}'),
      (match) => '${match.group(0)} ',
    ).trim();
  }

  bool _isValidCardNumber(String cardNumber) {
    // Luhn algorithm validation
    int sum = 0;
    bool alternate = false;
    
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);
      
      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit = (digit % 10) + 1;
        }
      }
      
      sum += digit;
      alternate = !alternate;
    }
    
    return (sum % 10) == 0;
  }
}

/// Custom input formatter for card numbers
class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final formatted = text.replaceAllMapped(
      // ignore: deprecated_member_use
      RegExp(r'.{4}'),
      (match) => '${match.group(0)} ',
    ).trim();
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
