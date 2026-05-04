// ignore_for_file: deprecated_member_use

import 'package:country_code_picker/country_code_picker.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_asset_image_widget.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sixam_mart/common/widgets/code_picker_widget.dart';

class CustomTextField extends StatefulWidget {
  final String titleText;
  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final FocusNode? nextFocus;
  final TextInputType inputType;
  final TextInputAction inputAction;
  final bool isPassword;
  final Function? onChanged;
  final Function? onSubmit;
  final bool isEnabled;
  final int maxLines;
  final TextCapitalization capitalization;
  final String? prefixImage;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final double prefixSize;
  final TextAlign textAlign;
  final bool isAmount;
  final bool isNumber;
  final bool showTitle;
  final bool showBorder;
  final double iconSize;
  final bool isPhone;
  final String? countryDialCode;
  final Function(CountryCode countryCode)? onCountryChanged;
  final bool showLabelText;
  final bool required;
  final String? labelText;
  final String? Function(String?)? validator;
  final double? labelTextSize;
  final Widget? suffixChild;
  final String? suffixImage;
  final Function()? suffixOnPressed;
  final bool divider;
  final bool fromUpdateProfile;
  /// When the field is disabled and shows "(non_changeable)", use a neutral
  /// color instead of [ColorScheme.error] (e.g. read-only phone on profile).
  final bool neutralHintForNonChangeable;

  const CustomTextField({
    super.key,
    this.titleText = 'Write something...',
    this.hintText = '',
    this.controller,
    this.focusNode,
    this.nextFocus,
    this.isEnabled = true,
    this.inputType = TextInputType.text,
    this.inputAction = TextInputAction.next,
    this.maxLines = 1,
    this.onSubmit,
    this.onChanged,
    this.prefixImage,
    this.prefixIcon,
    this.suffixIcon,
    this.capitalization = TextCapitalization.none,
    this.isPassword = false,
    this.prefixSize = Dimensions.paddingSizeSmall,
    this.textAlign = TextAlign.start,
    this.isAmount = false,
    this.isNumber = false,
    this.showTitle = false,
    this.showBorder = true,
    this.iconSize = 18,
    this.isPhone = false,
    this.countryDialCode,
    this.onCountryChanged,
    this.showLabelText = true,
    this.required = false,
    this.labelText,
    this.validator,
    this.labelTextSize,
    this.suffixChild,
    this.suffixOnPressed,
    this.suffixImage,
    this.divider = false,
    this.fromUpdateProfile = false,
    this.neutralHintForNonChangeable = false,
  });

  @override
  CustomTextFieldState createState() => CustomTextFieldState();
}

class CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (!mounted) return;
    final hasFocus = widget.focusNode?.hasFocus ?? false;
    if (_isFocused != hasFocus) {
      setState(() {
        _isFocused = hasFocus;
      });
    }
  }

  @override
  void dispose() {
    widget.focusNode?.removeListener(_handleFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasLabelText = (widget.labelText?.trim().isNotEmpty ?? false);
    final bool shouldShowNonChangeableHint = widget.isEnabled == false;
    final bool shouldBuildLabel =
        widget.showLabelText && (hasLabelText || shouldShowNonChangeableHint);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.showTitle
            ? Text(widget.titleText,
                style:
                    robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall))
            : const SizedBox(),
        SizedBox(
            height: widget.showTitle
                ? ResponsiveHelper.isDesktop(context)
                    ? Dimensions.paddingSizeDefault
                    : Dimensions.paddingSizeExtraSmall
                : 0),
        InkWell(
          splashColor: Colors.transparent,
          hoverColor: Colors.transparent,
          focusColor: Colors.transparent,
          onTap: () {
            final focusNode = widget.focusNode;
            if (focusNode != null && !focusNode.hasFocus) {
              FocusScope.of(context).requestFocus(focusNode);
            }
          },
          child: TextFormField(
            maxLines: widget.maxLines,
            controller: widget.controller,
            focusNode: widget.focusNode,
            textDirection: widget.isPhone ? TextDirection.ltr : null,
            textAlign: widget.textAlign,
            validator: widget.validator,
            style: robotoRegular.copyWith(fontSize: Dimensions.fontSizeLarge),
            textInputAction: widget.inputAction,
            keyboardType:
                widget.isAmount ? TextInputType.number : widget.inputType,
            cursorColor: theme.primaryColor,
            textCapitalization: widget.capitalization,
            enabled: widget.isEnabled,
            obscureText: widget.isPassword ? _obscureText : false,
            inputFormatters: widget.inputType == TextInputType.phone
                ? <TextInputFormatter>[
                    FilteringTextInputFormatter.allow(RegExp('[0-9]'))
                  ]
                : widget.isAmount
                    ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                    : widget.isNumber
                        ? [FilteringTextInputFormatter.allow(RegExp(r'\d'))]
                        : null,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(
                    style: widget.showBorder
                        ? BorderStyle.solid
                        : BorderStyle.none,
                    width: ResponsiveHelper.isDesktop(context) ? 0.7 : 0.3,
                    color: theme.disabledColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(
                    style: widget.showBorder
                        ? BorderStyle.solid
                        : BorderStyle.none,
                    color: theme.primaryColor),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(
                    style: widget.showBorder
                        ? BorderStyle.solid
                        : BorderStyle.none,
                    width: 0.3,
                    color: theme.primaryColor),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(
                    style: widget.showBorder
                        ? BorderStyle.solid
                        : BorderStyle.none,
                    color: theme.colorScheme.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                borderSide: BorderSide(
                    style: widget.showBorder
                        ? BorderStyle.solid
                        : BorderStyle.none,
                    color: theme.colorScheme.error),
              ),
              isDense: true,
              hintText: widget.hintText.isEmpty ||
                      !ResponsiveHelper.isDesktop(context)
                  ? widget.titleText
                  : widget.hintText,
              fillColor: theme.cardColor,
              hintStyle: robotoRegular.copyWith(
                  fontSize: Dimensions.fontSizeLarge, color: theme.hintColor),
              filled: true,
              labelStyle: widget.showLabelText
                  ? robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: theme.hintColor)
                  : null,
              errorStyle:
                  robotoRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
              label: shouldBuildLabel
                  ? Text.rich(TextSpan(children: [
                      if (hasLabelText)
                        TextSpan(
                          text: widget.labelText!.trim(),
                          style: robotoRegular.copyWith(
                            fontSize: widget.labelTextSize ??
                                Dimensions.fontSizeLarge,
                            color: ((_isFocused ||
                                        widget.controller?.text.isNotEmpty ==
                                            true) &&
                                    widget.isEnabled)
                                ? theme.textTheme.bodyLarge?.color
                                : theme.hintColor.withValues(alpha: 0.75),
                          ),
                        ),
                      if (widget.required && hasLabelText)
                        TextSpan(
                            text: ' *',
                            style: robotoRegular.copyWith(
                                color: theme.colorScheme.error,
                                fontSize: Dimensions.fontSizeLarge)),
                      if (shouldShowNonChangeableHint)
                        TextSpan(
                            text: hasLabelText
                                ? ' (${'non_changeable'.tr})'
                                : '(${'non_changeable'.tr})',
                            style: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeLarge,
                                color: widget.neutralHintForNonChangeable
                                    ? theme.hintColor.withValues(alpha: 0.75)
                                    : theme.colorScheme.error)),
                    ]))
                  : null,
              prefixIcon: widget.prefixImage != null && widget.prefixIcon == null
                      ? Padding(
                          padding: EdgeInsets.all(
                              ResponsiveHelper.isDesktop(context)
                                  ? Dimensions.paddingSizeSmall
                                  : Dimensions.paddingSizeDefault),
                          child: CustomAssetImageWidget(widget.prefixImage!,
                              height: 10,
                              width: 10,
                              color: _isFocused
                                  ? theme.primaryColor
                                  : theme.hintColor.withValues(alpha: 0.7)),
                        )
                      : widget.prefixImage == null && widget.prefixIcon != null
                          ? Icon(widget.prefixIcon,
                              size: widget.iconSize,
                              color: _isFocused
                                  ? theme.primaryColor
                                  : theme.hintColor.withValues(alpha: 0.7))
                          : null,
              suffixIcon: (widget.isPhone || widget.countryDialCode != null)
                  ? SizedBox(
                      width: 95,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                        Container(
                          height: 20,
                          width: 2,
                          color: theme.disabledColor,
                        ),
                        Container(
                          width: 85,
                          height: 40,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(Dimensions.radiusSmall),
                              bottomRight:
                                  Radius.circular(Dimensions.radiusSmall),
                            ),
                          ),
                          margin: const EdgeInsets.only(),
                          padding: const EdgeInsets.only(right: 5),
                          child: Center(
                            child: CodePickerWidget(
                              flagWidth: 25,
                              padding: EdgeInsets.zero,
                              onChanged: widget.onCountryChanged,
                              initialSelection: widget.countryDialCode,
                              favorite: [widget.countryDialCode ?? ''],
                              enabled: widget.isEnabled &&
                                  (Get.find<SplashController>()
                                          .configModel
                                          ?.countryPickerStatus ??
                                      true),
                              dialogBackgroundColor: theme.cardColor,
                              textStyle: robotoRegular.copyWith(
                                fontSize: Dimensions.fontSizeDefault,
                                color: theme.textTheme.bodyMedium!.color,
                              ),
                            ),
                          ),
                        ),
                      ]),
                    )
                  : widget.isPassword
                  ? IconButton(
                      icon: Icon(
                          _obscureText
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: theme.hintColor.withValues(alpha: 0.3)),
                      onPressed: _toggle,
                    )
                  : widget.suffixImage != null
                      ? InkWell(
                          onTap: widget.suffixOnPressed,
                          child: Padding(
                            padding: EdgeInsets.all(
                                ResponsiveHelper.isDesktop(context)
                                    ? Dimensions.paddingSizeSmall
                                    : Dimensions.paddingSizeDefault),
                            child: Image.asset(widget.suffixImage!,
                                height: 10, width: 10, fit: BoxFit.cover),
                          ))
                      : widget.suffixChild,
            ),
            onFieldSubmitted: (text) => widget.nextFocus != null
                ? FocusScope.of(context).requestFocus(widget.nextFocus)
                : widget.onSubmit != null
                    ? widget.onSubmit!(text)
                    : null,
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
            onChanged: widget.onChanged as void Function(String)?,
          ),
        ),
        widget.divider
            ? const Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeLarge),
                child: Divider())
            : const SizedBox(),
      ],
    );
  }

  void _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }
}
