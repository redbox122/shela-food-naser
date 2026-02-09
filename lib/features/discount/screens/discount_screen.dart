import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common/widgets/appBar.dart';
import '../../../common/widgets/custom_text.dart';
import '../../../util/app_colors.dart';
import '../../../util/styles.dart';

class DiscountScreen extends StatelessWidget {
  const DiscountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wtColor,
      appBar: custom_AppBar(context, title: 'discount'.tr, icon: Icons.arrow_back_sharp, titleIcon: Icons.percent),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Image.asset('assets/image/discount.png', width: 30, height: 30),
              const SizedBox(
                height: 10,
              ),
              Custom_Text(context,
                  text: 'لا يوجد كود خصم',
                  style: font14SecondaryColor500W(
                    context,
                  )),
              const SizedBox(height: 10),
              Custom_Text(context,
                  text: 'يمكنك العثور على كود خصم هنا',
                  style: font13Black400W(
                    context,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
