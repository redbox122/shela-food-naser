// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:sixam_mart/common/widgets/custom_textfield_2.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';

import '../../../util/app_colors.dart';
import '../../../util/styles.dart';
import '../custom_Button_2.dart';
import '../custom_text.dart';

class CouponInputDialog extends StatefulWidget {
  const CouponInputDialog({super.key});

  @override
  _CouponInputDialogState createState() => _CouponInputDialogState();
}

class _CouponInputDialogState extends State<CouponInputDialog> {
  final _couponCodeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return _buildDialogContent(context);
  }

  Widget _buildDialogContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Container(
          width: ResponsiveHelper.isWeb()
              ? MediaQuery.of(context).size.width / 3
              : MediaQuery.of(context).size.width, // Take full screen width
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: ResponsiveHelper.isWeb() ? BorderRadius.circular(8) : BorderRadius.circular(0)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Custom_Text(context, text: 'اضف رمز القسيمة الجديدة', style: font14Black400W(context)),
              const SizedBox(height: 10),
              Custom_Text(context, text: 'رمز القسمية', style: font14Black400W(context)),
              const SizedBox(height: 10),
              const CustomAppTextField(
                labelText: 'رمز القسيمة',
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: custom_Button(context,
                        title: 'إضافة', onPressed: () {}, buttoncolor: AppColors.greenColor, h: 40, style: font13White400W(context)),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: custom_Button(context,
                        title: 'إلغاء', onPressed: () {}, buttoncolor: AppColors.wtColor, h: 40, style: font13Black400W(context)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _couponCodeController.dispose();
    super.dispose();
  }
}
