// ignore_for_file: non_constant_identifier_names, avoid_print, use_build_context_synchronously, camel_case_types

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';

class Show_Pdf_Screen extends StatefulWidget {
  const Show_Pdf_Screen({super.key});

  @override
  State<Show_Pdf_Screen> createState() => _Show_Pdf_ScreenState();
}

class _Show_Pdf_ScreenState extends State<Show_Pdf_Screen> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<KaidhaSubscription_Controller>(
      builder: (KaidhaSubController) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Icon(Icons.access_time, size: 80, color: Colors.green),
                  const SizedBox(height: 20),
                  const Text('طلبك قيد المراجعة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'طلبك قيد المراجعة النهائية. سيتم تحديد الحد الائتماني وتفعيل المحفظة خلال 24 - 48 ساعة. سنقوم بإشعارك فور الانتهاء.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Progress indicator

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStepCircle(Icons.check, 'تم استلام الطلب', Colors.green),
                      _buildStepLine(),
                      _buildStepCircle(Icons.hourglass_bottom, 'قيد المراجعة', Colors.green),
                      _buildStepLine(),
                      _buildStepCircle(null, 'تفعيل المحفظة', Colors.grey),
                    ],
                  ),

                  const SizedBox(height: 32),

                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, color: Colors.black54),
                      SizedBox(width: 8),
                      Text(
                        'الوقت المتوقع 24-48 ساعة عمل',
                        style: TextStyle(fontSize: 16, color: Colors.black54),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  const Text('هل لديك استفسار؟', style: TextStyle(fontSize: 16)),

                  const SizedBox(height: 10),

                  OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    icon: const Icon(Icons.phone, color: Colors.orange),
                    label: const Text('تواصل مع خدمة العملاء', style: TextStyle(color: Colors.orange, fontSize: 16)),
                  ),

                  //
                ],
              ),

              //

              Container(
                width: 1170,
                padding: EdgeInsets.all(Dimensions.fontSizeDefault),
                child: CustomButton(
                  color: AppColors.orangeColor,
                  buttonText: 'استعراض العقد',
                  onPressed: () async {
                    Get.toNamed(RouteHelper.getContract_ReviewRoute());
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepCircle(IconData? icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.1),
          child: icon != null
              ? Icon(icon, color: color, size: 18)
              : Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 20,
      height: 1,
      color: Colors.grey[400],
    );
  }
}

//

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Icon(Icons.access_time, size: 80, color: Colors.green),
        const SizedBox(height: 20),
        const Text(
          'طلبك قيد المراجعة',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'طلبك قيد المراجعة النهائية. سيتم تحديد الحد الائتماني وتفعيل المحفظة خلال 24 - 48 ساعة. سنقوم بإشعارك فور الانتهاء.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(height: 32),
        // Progress indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStepCircle(Icons.check, 'تم استلام الطلب', Colors.green),
            _buildStepLine(),
            _buildStepCircle(Icons.hourglass_bottom, 'قيد المراجعة', Colors.green),
            _buildStepLine(),
            _buildStepCircle(null, 'تفعيل المحفظة', Colors.grey),
          ],
        ),
        const SizedBox(height: 32),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, color: Colors.black54),
            SizedBox(width: 8),
            Text(
              'الوقت المتوقع 24-48 ساعة عمل',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
        const Spacer(),
        const Text('هل لديك استفسار؟', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {},
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.orange),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          ),
          icon: const Icon(Icons.phone, color: Colors.orange),
          label: const Text(
            'تواصل مع خدمة العملاء',
            style: TextStyle(color: Colors.orange, fontSize: 16),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStepCircle(IconData? icon, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color.withValues(alpha: 0.1),
          child: icon != null
              ? Icon(icon, color: color, size: 18)
              : Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 20,
      height: 1,
      color: Colors.grey[400],
    );
  }
}
