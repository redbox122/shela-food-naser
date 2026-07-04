import 'package:flutter/material.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

/// حقل إدخال موحّد بتصميم: عنوان (مع نجمة إلزامية اختيارية) فوق صندوق
/// رمادي فاتح بزوايا دائرية وبدون حدود ظاهرة — بخط Tajawal.
class LabeledInputField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final bool isPassword;
  final bool required;
  final bool readOnly;
  final TextInputType inputType;
  final TextCapitalization capitalization;
  final TextInputAction inputAction;
  final TextDirection? textDirection;
  final String? Function(String?)? validator;
  final void Function(String?)? onChanged;

  /// عنصر يظهر في نهاية الحقل (يسار الحقل في الاتجاه RTL) — مثل مفتاح الدولة.
  /// يتم تجاهله عند [isPassword] لأن أيقونة إظهار كلمة المرور تأخذ مكانه.
  final Widget? suffix;

  /// عنصر يظهر في بداية الحقل (يسار الحقل في اتجاه LTR) — مثل مفتاح الدولة +966.
  final Widget? prefix;

  const LabeledInputField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.focusNode,
    this.nextFocus,
    this.isPassword = false,
    this.required = false,
    this.readOnly = false,
    this.inputType = TextInputType.text,
    this.capitalization = TextCapitalization.none,
    this.inputAction = TextInputAction.next,
    this.textDirection,
    this.validator,
    this.onChanged,
    this.suffix,
    this.prefix,
  });

  @override
  State<LabeledInputField> createState() => _LabeledInputFieldState();
}

class _LabeledInputFieldState extends State<LabeledInputField> {
  bool _obscure = true;

  static const Color _fillColor = Color(0xFFF6F5F8);

  OutlineInputBorder _border(Color color, {double width = 0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      borderSide:
          width == 0 ? BorderSide.none : BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(TextSpan(children: [
          TextSpan(
            text: widget.label,
            style: tajawalBold.copyWith(
              fontSize: Dimensions.fontSizeMedim,
              color: Color(0xff111B18),
            ),
          ),
          if (widget.required)
            TextSpan(
              text: ' *',
              style: tajawalBold.copyWith(
                  fontSize: Dimensions.fontSizeExtraLarge,
                  color: theme.colorScheme.error),
            ),
        ])),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          readOnly: widget.readOnly,
          keyboardType: widget.inputType,
          textCapitalization: widget.capitalization,
          textInputAction: widget.inputAction,
          textDirection: widget.textDirection,
          obscureText: widget.isPassword ? _obscure : false,
          validator: widget.validator,
          onChanged: widget.onChanged,
          cursorColor: theme.primaryColor,
          style: tajawalRegular.copyWith(fontSize: Dimensions.fontSizeDefault),
          onFieldSubmitted: (_) => widget.nextFocus != null
              ? FocusScope.of(context).requestFocus(widget.nextFocus)
              : null,
          onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: tajawalMedium.copyWith(
                fontSize: Dimensions.fontSizeLarge, color: Color(0xff555555)),
            filled: true,
            fillColor: _fillColor,
            isDense: true,
            prefixIcon: widget.prefix,
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault, vertical: 14),
            border: _border(_fillColor),
            enabledBorder: _border(_fillColor),
            focusedBorder: _border(theme.primaryColor, width: 1),
            errorBorder: _border(theme.colorScheme.error, width: 1),
            focusedErrorBorder: _border(theme.colorScheme.error, width: 1),
            errorStyle: tajawalRegular.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall),
            suffixIcon: widget.isPassword
                ? IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: theme.hintColor,
                    ),
                  )
                : widget.suffix,
          ),
        ),
      ],
    );
  }
}
