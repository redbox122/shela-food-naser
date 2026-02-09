import 'package:flutter/material.dart';
import '../../../common/widgets/custom_Images.dart';
import '../../../common/widgets/custom_text.dart';
import '../../../util/app_colors.dart';
import '../../../util/styles.dart';

class StatisticsKaidhaAndContainerDetails extends StatelessWidget {
  const StatisticsKaidhaAndContainerDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Custom_Text(context,
            text: 'Kaidha Service Statistics',
            style: font14Black400W(
              context,
            )),
        const SizedBox(
          height: 16,
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: AppColors.primaryColor),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Custom_Text(context,
                        text: 'المبلغ المقدم من قيدها',
                        style: font13White400W(
                          context,
                        )),
                    const SizedBox(
                      height: 35,
                    ),
                    Row(
                      children: [
                        custom_Images_asset(
                            image: 'assets/image/wallet.png', w: 29, h: 24),
                        const SizedBox(
                          width: 5,
                        ),
                        Custom_Text(context,
                            text: '5.5 رس',
                            style: font13White400W(
                              context,
                            )),
                      ],
                    )
                  ],
                )),
                Expanded(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Custom_Text(context,
                        text: 'المبلغ المتاح للشراء',
                        style: font13White400W(
                          context,
                        )),
                    const SizedBox(
                      height: 35,
                    ),
                    Custom_Text(context,
                        text: '5.5 رس',
                        style: font13White400W(
                          context,
                        )),
                  ],
                ))
              ],
            ),
          ),
        )
      ],
    );
  }
}
