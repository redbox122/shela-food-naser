
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/confirmation_dialog.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/widget/before_Pdf.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:intl/intl.dart';
import 'package:sixam_mart/util/styles.dart';

class Step3Screen extends StatefulWidget {
  const Step3Screen({super.key});

  @override
  State<Step3Screen> createState() => _Step3ScreenState();
}

class _Step3ScreenState extends State<Step3Screen> {
  bool isExpanded = false;

  String timeNow = '';
  String dayNow = '';
  Timer? _pollTimer;
  DateTime? _pollStartTime;

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _pollStartTime = null;
  }

  void _startPolling(KaidhaSubscriptionController controller) {
    if (_pollTimer != null) return;
    _pollStartTime = controller.nafathRequestCreatedAt ?? DateTime.now();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final DateTime pollStart = _pollStartTime ?? DateTime.now();
      if (DateTime.now().difference(pollStart).inSeconds >= 120) {
        _stopPolling();
        return;
      }
      if (!mounted) {
        _stopPolling();
        return;
      }
      await controller.Nafath_send_checkStatus(
          context, controller.identity_card_number.text,
          silent: true,
          allowAutoRetry: false);
      final status = controller.nafath_checkStatus?.status;
      final requestId = controller.nafath_checkStatus?.requestId;
      debugPrint(
          '🔎 Nafath checkStatus: status=$status, request_id=$requestId, at=${DateTime.now().toIso8601String()}');
      if (status == 'approved' ||
          status == 'rejected' ||
          status == 'expired' ||
          status == 'cancelled' ||
          status == 'no_request') {
        _stopPolling();
      }
    });
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(fn);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _initS();
    final controller = Get.find<KaidhaSubscriptionController>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (controller.identity_card_number.text.trim().isEmpty) {
        return;
      }
      await controller.Nafath_send_checkStatus(
        context,
        controller.identity_card_number.text,
        silent: false,
      );
    });
  }

  Future<void> _initS() async {
    await initializeDateFormatting('ar');

    timeNow = getCurrentTime();
    dayNow = getCurrentDay();
  }

  String getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute.toString().padLeft(2, '0');

    // صيغة 12 ساعة:
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;

    // تحديد صباحاً أو مساءً:
    final period = hour < 12 ? 'am'.tr : 'pm'.tr;

    String timeString = '$hour12:$minute $period';

    // Convert to Arabic-Indic numerals if Arabic locale
    if (Get.find<LocalizationController>().locale.languageCode == 'ar') {
      const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
      const arabicIndic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      for (int i = 0; i < western.length; i++) {
        timeString = timeString.replaceAll(western[i], arabicIndic[i]);
      }
    }

    return timeString;
  }

  String getCurrentDay() {
    final now = DateTime.now();
    final locale = Get.find<LocalizationController>().locale;
    final formatter = DateFormat('EEEE', locale.toString());
    return formatter.format(now);
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle headerStyle =
        TextStyle(fontSize: 15, fontWeight: FontWeight.bold);
    const TextStyle bulletStyle = TextStyle(fontSize: 13, height: 1.8);
    const TextStyle normalStyle = TextStyle(fontSize: 13, height: 1.6);

    //

    return GetBuilder<KaidhaSubscriptionController>(
      builder: (KaidhaSubController) {
        final bool canManagePending = KaidhaSubController.canManagePendingRequest;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final status = KaidhaSubController.nafath_checkStatus?.status;
          if (status == 'approved') {
            _stopPolling();
            return;
          }
          if (status == 'pending') {
            _startPolling(KaidhaSubController);
          } else {
            _stopPolling();
          }
        });
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: KaidhaSubController.isLoading_Status ||
                    KaidhaSubController.isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      //
                      KaidhaSubController.isShow == false
                          ? Card(
                              color: AppColors.gryColor_6,
                              child: SizedBox(
                                height: 200,
                                width: 350,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (KaidhaSubController
                                                .nafath_checkStatus?.status ==
                                            'pending' &&
                                        KaidhaSubController
                                                .nafath_checkStatus?.random !=
                                            null)
                                      Container(
                                        width: 80,
                                        height: 80,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: AppColors.greenColor,
                                              width: 3),
                                        ),
                                        child: Text(
                                          KaidhaSubController
                                                  .nafath_checkStatus?.random
                                                  ?.toString() ??
                                              '',
                                          style: robotoBold.copyWith(
                                              fontSize: 30,
                                              color: AppColors.greenColor),
                                          textAlign: TextAlign.center,
                                        ),
                                      )
                                    else
                                      Text(
                                        'بانتظار رقم نفاذ',
                                        style: robotoMedium.copyWith(
                                            fontSize: 16),
                                      ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'enter_verification_code'.tr,
                                      style: robotoMedium.copyWith(
                                          fontSize: 18),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox(height: 100),

                      const SizedBox(height: 30),

                      if (KaidhaSubController.isShow == false)
                        GestureDetector(
                          onTap: () => _safeSetState(() => isExpanded = !isExpanded),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: RichText(
                              text: TextSpan(
                                style:
                                    normalStyle.copyWith(color: Colors.black),
                                children: isExpanded
                                    ? [
                                        TextSpan(
                                            text:
                                                '${'welcome_to_kiadha_family'.tr}\n'),
                                        TextSpan(
                                            text:
                                                '${'welcome_contract_phase'.tr}\n'),
                                        const TextSpan(
                                            text:
                                                'لتسهيل الأمر عليك، أمامك الآن خياران لإتمام العملية:\n\n'),
                                        const TextSpan(
                                            text:
                                                '1. الخيار الأول (موصى به): مراجعة العقد ثم التوثيق\n',
                                            style: headerStyle),
                                        const TextSpan(
                                            text:
                                                'إذا كنت ترغب في الاطلاع على كافة تفاصيل وبنود العقد قبل أي التزام قانوني، يرجى اتباع الخطوات التالية:\n',
                                            style: normalStyle),
                                        TextSpan(
                                            text: 'contract_review_steps'.tr,
                                            style: bulletStyle),
                                        const TextSpan(
                                            text:
                                                '• ثانياً: بعد الانتهاء من المراجعة، اتبع خطوات التوثيق التالية:\n',
                                            style: bulletStyle),
                                        TextSpan(
                                            text:
                                                'nafath_verification_steps'.tr,
                                            style: bulletStyle),
                                        const TextSpan(
                                            text:
                                                '   ◦ ب. سيظهر أمامك الآن رقم محدد للعملية، يرجى تذكره.\n',
                                            style: bulletStyle),
                                        const TextSpan(
                                            text:
                                                '   ◦ ج. افتح تطبيق "نفاذ" في هاتفك، واختر الطلب الذي يحمل نفس الرقم.\n',
                                            style: bulletStyle),
                                        const TextSpan(
                                            text:
                                                '   ◦ د. أكمل إجراءات الموافقة لإتمام المصادقة بنجاح.\n\n',
                                            style: bulletStyle),
                                        const TextSpan(
                                            text:
                                                '2. الخيار الثاني: التوثيق المباشر\n',
                                            style: headerStyle),
                                        const TextSpan(
                                            text:
                                                'في حال كنت قد اطلعت على الشروط مسبقاً وتثق بها، يمكنك البدء بالتوثيق المباشر:\n',
                                            style: normalStyle),
                                        TextSpan(
                                            text:
                                                'nafath_direct_verification'.tr,
                                            style: bulletStyle),
                                        const TextSpan(
                                            text:
                                                '• ب. سيظهر أمامك رقم محدد للعملية.\n',
                                            style: bulletStyle),
                                        const TextSpan(
                                            text:
                                                '• ج. افتح تطبيق "نفاذ" في هاتفك واختر الطلب الذي يحمل نفس الرقم.\n',
                                            style: bulletStyle),
                                        const TextSpan(
                                            text:
                                                '• د. وافق على الطلب لإتمام المصادقة.\n',
                                            style: bulletStyle),
                                        const TextSpan(
                                          text: '\nإخفاء',
                                          style: TextStyle(
                                              color: AppColors.primaryColor,
                                              fontSize: 15),
                                        ),
                                      ]
                                    : [
                                        TextSpan(
                                            text:
                                                '${'welcome_to_kiadha_family'.tr}\n'),
                                        TextSpan(
                                            text:
                                                '${'welcome_contract_phase'.tr}\n'),
                                        const TextSpan(
                                          text: '..... عرض المزيد',
                                          style: TextStyle(
                                              color: AppColors.primaryColor,
                                              fontSize: 15),
                                        ),
                                      ],
                              ),
                            ),
                          ),
                        ),
                      Column(
                        children: [
                          const SizedBox(height: 10),
                          if (KaidhaSubController.nafath_checkStatus == null)
                            Container(
                              width: 1170,
                              padding:
                                  EdgeInsets.all(Dimensions.fontSizeDefault),
                              child: Column(
                                children: [
                                  Text(
                                    'لا يوجد طلب نفاذ سابق. سيتم بدء طلب جديد.',
                                    style: robotoMedium.copyWith(
                                        fontSize: 14,
                                        color: Colors.black87),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  CustomButton(
                                    color: AppColors.orangeColor,
                                    buttonText: 'ابدأ التحقق',
                                    onPressed: () async {
                                      await KaidhaSubController
                                          .Nafath_send_National_Id(
                                        context,
                                        KaidhaSubController
                                            .identity_card_number.text,
                                        forceNew: true,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          if (KaidhaSubController.nafath_checkStatus != null &&
                              KaidhaSubController.nafath_checkStatus!.status ==
                                  'pending')
                            Container(
                              width: 1170,
                              padding: EdgeInsets.all(
                                  Dimensions.fontSizeDefault),
                              child: Column(
                                children: [
                                  Text(
                                    'افتح تطبيق نفاذ واختر الرقم التالي للموافقة.',
                                    style: robotoMedium.copyWith(
                                        fontSize: 14,
                                        color: Colors.black87),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (canManagePending) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'لسه معلق، افتح نفاذ ووافق ثم تحقق.',
                                      style: robotoMedium.copyWith(
                                          fontSize: 13,
                                          color: Colors.black87),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  if (KaidhaSubController
                                              .nafath_checkStatus?.status ==
                                          'pending' &&
                                      KaidhaSubController
                                              .nafath_checkStatus?.random !=
                                          null)
                                    Container(
                                      width: 80,
                                      height: 80,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: AppColors.greenColor,
                                            width: 3),
                                      ),
                                      child: Text(
                                        KaidhaSubController
                                                .nafath_checkStatus?.random
                                                ?.toString() ??
                                            '',
                                        style: robotoBold.copyWith(
                                            fontSize: 30,
                                            color: AppColors.greenColor),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  CustomButton(
                                    color: AppColors.orangeColor,
                                    buttonText: 'تحقق من الحالة',
                                    onPressed: () async {
                                      await KaidhaSubController
                                          .Nafath_send_checkStatus(
                                              context,
                                              KaidhaSubController
                                                  .identity_card_number.text,
                                              silent: false);
                                    },
                                  ),
                                  if (canManagePending) ...[
                                    const SizedBox(height: 8),
                                    CustomButton(
                                      color: AppColors.primaryColor,
                                      buttonText: 'إعادة المحاولة',
                                      onPressed: () async {
                                        _stopPolling();
                                        await KaidhaSubController
                                            .Nafath_send_retry(
                                                context,
                                                KaidhaSubController
                                                    .identity_card_number.text);
                                        if (mounted) {
                                          _startPolling(KaidhaSubController);
                                        }
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    CustomButton(
                                      color: Colors.red,
                                      buttonText: 'إلغاء الطلب',
                                      onPressed: () async {
                                        _stopPolling();
                                        final cancelled =
                                            await KaidhaSubController
                                                .Nafath_cancelRequest(
                                                    context,
                                                    KaidhaSubController
                                                        .identity_card_number
                                                        .text);
                                        if (cancelled && mounted) {
                                          KaidhaSubController.backStage();
                                          Get.offNamed(RouteHelper
                                              .getKiadaWalletSubscription());
                                        }
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          if (KaidhaSubController.nafath_checkStatus != null &&
                              (KaidhaSubController.nafath_checkStatus!.status ==
                                      'rejected' ||
                                  KaidhaSubController
                                          .nafath_checkStatus!.status ==
                                      'expired' ||
                                  KaidhaSubController
                                          .nafath_checkStatus!.status ==
                                      'cancelled' ||
                                  KaidhaSubController
                                          .nafath_checkStatus!.status ==
                                      'no_request'))
                            Container(
                              width: 1170,
                              padding:
                                  EdgeInsets.all(Dimensions.fontSizeDefault),
                              child: Column(
                                children: [
                                  Text(
                                    KaidhaSubController.nafath_checkStatus!
                                                .status ==
                                            'expired'
                                        ? 'انتهت صلاحية طلب نفاذ. يمكنك إرسال طلب جديد.'
                                        : KaidhaSubController.nafath_checkStatus!
                                                    .status ==
                                                'rejected'
                                            ? 'تم رفض طلب التحقق من نفاذ.'
                                            : KaidhaSubController
                                                        .nafath_checkStatus!
                                                        .status ==
                                                    'cancelled'
                                                ? 'تم إلغاء طلب نفاذ.'
                                                : 'لا يوجد طلب نفاذ حالي.',
                                    style: robotoMedium.copyWith(
                                        fontSize: 14,
                                        color: Colors.redAccent),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  CustomButton(
                                    color: AppColors.orangeColor,
                                    buttonText: 'إعادة المحاولة',
                                    onPressed: () async {
                                      if (KaidhaSubController
                                              .nafath_checkStatus!.status ==
                                          'no_request') {
                                        await KaidhaSubController
                                            .Nafath_send_National_Id(
                                          context,
                                          KaidhaSubController
                                              .identity_card_number.text,
                                          forceNew: true,
                                        );
                                      } else {
                                        await KaidhaSubController
                                            .Nafath_send_retry(
                                                context,
                                                KaidhaSubController
                                                    .identity_card_number.text);
                                      }
                                      if (mounted) {
                                        _startPolling(KaidhaSubController);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                  CustomButton(
                                    color: AppColors.primaryColor,
                                    buttonText: 'تحقق من الحالة',
                                    onPressed: () async {
                                      await KaidhaSubController
                                          .Nafath_send_checkStatus(
                                              context,
                                              KaidhaSubController
                                                  .identity_card_number.text,
                                              silent: false);
                                    },
                                  ),
                                ],
                              ),
                            ),

                          // Review Contract Button (Phase 1)
                          Container(
                            width: 1170,
                            padding: EdgeInsets.all(Dimensions.fontSizeDefault),
                            child: CustomButton(
                              color: AppColors.primaryColor,
                              buttonText: 'review_contract_before_signing'.tr,
                              onPressed: () async {
                                KaidhaSubController.update_isShow();
                                Get.to(
                                  () => Befor_Pdf_Screen(
                                    time: timeNow,
                                    day: dayNow,
                                    name:
                                        '${KaidhaSubController.firstname.text} ${KaidhaSubController.fathername.text} ${KaidhaSubController.grandfathername.text} ${KaidhaSubController.last_name.text}',
                                    identityNumber: KaidhaSubController
                                        .identity_card_number.text
                                        .toString(),
                                    nationality: KaidhaSubController.nationality
                                        .toString(),
                                    neighborhood: KaidhaSubController
                                        .neighborhood.text
                                        .toString(),
                                    house_type: KaidhaSubController.house_type
                                        .toString(),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Nafath Verification Button (Phase 1)
                          if (KaidhaSubController.isShow == false)
                            Container(
                              width: 1170,
                              padding:
                                  EdgeInsets.all(Dimensions.fontSizeDefault),
                              child: CustomButton(
                                isLoading: KaidhaSubController.isLoading_Status,
                                color: AppColors.orangeColor,
                                buttonText: 'verify_authentication'.tr,
                                onPressed: () async {
                                  // Show confirmation dialog first
                                  await KaidhaSubController.onChange_dialog(
                                      context,
                                      KaidhaSubController
                                          .identity_card_number.text);
                                },
                              ),
                            ),

                          //

                          (KaidhaSubController.nafath_checkStatus != null &&
                                  KaidhaSubController
                                          .nafath_checkStatus!.status ==
                                      'approved')
                              ? Container(
                                  width: 1170,
                                  padding: EdgeInsets.all(
                                      Dimensions.fontSizeDefault),
                                  child: CustomButton(
                                    buttonText:
                                        'sign_contract_and_send_data'.tr,
                                    onPressed: () async {
                                      // Show confirmation dialog before signing
                                      Get.dialog(
                                        barrierDismissible: false,
                                        ConfirmationDialog(
                                          icon: Images.warning,
                                          title: 'تأكيد توقيع العقد',
                                          description:
                                              'هل أنت متأكد من توقيع العقد وإرسال البيانات؟',
                                          onYesPressed: () async {
                                            Get.back();
                                            // 8. Contract Signing Process
                                            // API Call 3: POST /api/qidha-wallet/nafath/sign
                                            // Submits digital signature data
                                            // Links signature to wallet
                                            // Updates contract status
                                            await KaidhaSubController
                                                .Nafath_send_All_Data(
                                              context,
                                              KaidhaSubController
                                                  .identity_card_number.text,
                                              KaidhaSubController.city,
                                              KaidhaSubController
                                                  .neighborhood.text,
                                              KaidhaSubController.house_type,
                                            ).then(
                                              (onValue) async {
                                                //
                                                debugPrint(
                                                    '\x1B[32m  Contract Signing API Call   ${onValue?.statusCode}  \x1B[0m');

                                                if (onValue != null &&
                                                    (onValue.statusCode ==
                                                            200 ||
                                                        onValue.statusCode ==
                                                            201 ||
                                                        onValue.statusCode ==
                                                            302)) {
                                                  // All 3 steps completed successfully
                                                  // 1. Final Nafath Verification ✅
                                                  // 2. Wallet Creation ✅
                                                  // 3. Status Update ✅

                                                  // Show success message and navigate to waiting screen
                                                  showCustomSnackBar(
                                                      'wallet_created_success'
                                                          .tr,
                                                      isError: false);

                                                  // Navigate to main subscription screen to show waiting for approval UI
                                                  Get.toNamed(RouteHelper
                                                      .getKiadaWalletSubscription());
                                                } else if (onValue
                                                        ?.statusCode ==
                                                    404) {
                                                  KaidhaSubController
                                                      .update_isShow();
                                                  showCustomSnackBar(
                                                      'try_again_later'.tr);
                                                } else {
                                                  KaidhaSubController
                                                      .update_isShow();
                                                  showCustomSnackBar(
                                                      'wallet_creation_error'
                                                          .tr);
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : const SizedBox(),

                          //
                        ],
                      ),

                      const SizedBox(height: 70),
                    ],
                  ),
          ),
        );
      },
    );
  }
}




