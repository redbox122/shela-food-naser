import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'dart:ui';

/// Premium amount input with gradient effects and smooth animations
/// Creates a delightful input experience with visual feedback
class PremiumAmountInput extends StatefulWidget {
  final TextEditingController controller;
  final double availableBalance;
  final String paymentSource;
  final void Function(String)? onChanged;

  const PremiumAmountInput({
    super.key,
    required this.controller,
    required this.availableBalance,
    required this.paymentSource,
    this.onChanged,
  });

  @override
  State<PremiumAmountInput> createState() => _PremiumAmountInputState();
}

class _PremiumAmountInputState extends State<PremiumAmountInput>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusController;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        if (_isFocused) {
          _focusController.forward();
          HapticFeedback.lightImpact();
        } else {
          _focusController.reverse();
        }
      });
    });
  }

  @override
  void dispose() {
    _focusController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with gradient
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF31A342), Color(0xFFFA9D2B)],
          ).createShader(bounds),
          child: Text(
            'amount_to_send'.tr,
            style: robotoBold.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              color: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Amount input container with animated border
        AnimatedBuilder(
          animation: _focusController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF31A342).withValues(alpha: 
                      0.1 + (_focusController.value * 0.2),
                    ),
                    const Color(0xFFFA9D2B).withValues(alpha: 
                      0.1 + (_focusController.value * 0.2),
                    ),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withValues(alpha: 
                      _focusController.value * 0.3,
                    ),
                    blurRadius: 20 * _focusController.value,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.paddingSizeLarge,
                      vertical: Dimensions.paddingSizeDefault,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _isFocused
                            ? Theme.of(context).primaryColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Currency symbol with gradient
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF31A342), Color(0xFFFA9D2B)],
                          ).createShader(bounds),
                          child: Text(
                            'ريال',
                            style: robotoBold.copyWith(
                              fontSize: Dimensions.fontSizeExtraLarge,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: Dimensions.paddingSizeSmall),
                        
                        // Amount text field
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            focusNode: _focusNode,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: robotoBold.copyWith(
                              fontSize: 32,
                              color: Theme.of(context).textTheme.bodyLarge!.color,
                              fontWeight: FontWeight.w900,
                            ),
                            decoration: InputDecoration(
                              hintText: '0.00',
                              hintStyle: robotoBold.copyWith(
                                fontSize: 32,
                                color: Colors.grey.shade300,
                                fontWeight: FontWeight.w900,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (value) {
                              widget.onChanged?.call(value);
                              HapticFeedback.selectionClick();
                            },
                            inputFormatters: [
                              // ignore: deprecated_member_use
                              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        
        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Balance indicator with progress bar
        _buildBalanceIndicator(context),
        
        const SizedBox(height: Dimensions.paddingSizeDefault),

        // Quick amount chips
        _buildQuickAmountChips(context),
      ],
    );
  }

  /// Builds balance indicator with animated progress bar
  Widget _buildBalanceIndicator(BuildContext context) {
    final double currentAmount = double.tryParse(widget.controller.text) ?? 0;
    final double progress = widget.availableBalance > 0
        ? (currentAmount / widget.availableBalance).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'available_balance'.tr,
              style: robotoMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).disabledColor,
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF31A342), Color(0xFFFA9D2B)],
              ).createShader(bounds),
              child: Text(
                PriceConverter.convertPrice(widget.availableBalance),
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: Dimensions.paddingSizeSmall),
        
        // Animated progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 6,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.grey.shade200,
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: MediaQuery.of(context).size.width * progress * 0.85,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: progress > 0.9
                          ? [Colors.red, Colors.orange] // Warning colors
                          : [const Color(0xFF31A342), const Color(0xFFFA9D2B)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds quick amount selection chips with ripple animation
  Widget _buildQuickAmountChips(BuildContext context) {
    final quickAmounts = [50.0, 100.0, 200.0, 500.0];

    return Wrap(
      spacing: Dimensions.paddingSizeSmall,
      runSpacing: Dimensions.paddingSizeSmall,
      children: quickAmounts.map((amount) {
        final bool isAvailable = amount <= widget.availableBalance;
        
        return GestureDetector(
          onTap: isAvailable ? () {
            widget.controller.text = amount.toStringAsFixed(0);
            widget.onChanged?.call(widget.controller.text);
            HapticFeedback.mediumImpact();
          } : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeLarge,
              vertical: Dimensions.paddingSizeSmall,
            ),
            decoration: BoxDecoration(
              gradient: isAvailable
                  ? const LinearGradient(
                      colors: [Color(0xFF31A342), Color(0xFFFA9D2B)],
                    )
                  : null,
              color: isAvailable ? null : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(30),
            ),
            child:               Text(
                '+${amount.toStringAsFixed(0)}',
                style: robotoBold.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: isAvailable
                      ? Colors.white
                      : Colors.grey.shade400,
                ),
              ),
          ),
        );
      }).toList(),
    );
  }
}

