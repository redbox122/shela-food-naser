
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/widget/file_upload_widget.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/widget/job_specification.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class Step2Screen extends StatefulWidget {
  const Step2Screen({super.key});

  @override
  State<Step2Screen> createState() => _Step2ScreenState();
}

class _Step2ScreenState extends State<Step2Screen> {
  int? selectedDay;

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(fn);
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return GetBuilder<KaidhaSubscriptionController>(
        builder: (KaidhaSubController) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: KaidhaSubController.isLoading_OTP
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  Align(
                    alignment: Directionality.of(context) == TextDirection.rtl
                        ? Alignment.topRight
                        : Alignment.topLeft,
                    child: Text(
                      'source_of_income'.tr,
                      textAlign: Directionality.of(context) == TextDirection.rtl
                          ? TextAlign.right
                          : TextAlign.left,
                      style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeDefault),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Directionality.of(context) == TextDirection.rtl
                        ? Alignment.topRight
                        : Alignment.topLeft,
                    child: Text(
                      'select_main_income_source'.tr,
                      textAlign: Directionality.of(context) == TextDirection.rtl
                          ? TextAlign.right
                          : TextAlign.left,
                      style: robotoBold.copyWith(
                        color: Theme.of(context).disabledColor,
                        fontSize: Dimensions.fontSizeMedim,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  //

                  const JobSpecification(),

                  //

                  const SizedBox(height: 20),

                  Align(
                    alignment: Directionality.of(context) == TextDirection.rtl
                        ? Alignment.topRight
                        : Alignment.topLeft,
                    child: Text(
                      'what_is_your_salary_day'.tr,
                      textAlign: Directionality.of(context) == TextDirection.rtl
                          ? TextAlign.right
                          : TextAlign.left,
                      style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeMedim),
                    ),
                  ),

                  const SizedBox(height: 5),
                  Focus(
                    focusNode: KaidhaSubController.salaryDayFocus,
                    child: DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        hintText: 'select_day'.tr,
                        hintStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: KaidhaSubController.isSalaryDayEmpty
                                ? Colors.red
                                : AppColors.gryColor_3,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: KaidhaSubController.isSalaryDayEmpty
                                ? Colors.red
                                : AppColors.greenColor,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                      ),
                      // ignore: deprecated_member_use
                      value: selectedDay,
                      onChanged: (int? newDay) {
                        _safeSetState(() {
                          selectedDay = newDay;
                          KaidhaSubController.salary_day.text =
                              newDay.toString();
                          KaidhaSubController.isSalaryDayEmpty = false;
                        });

                        KaidhaSubController.debouncedSaveState();
                      },
                      items: List.generate(31, (index) {
                        final int day = index + 1;
                        return DropdownMenuItem(
                          value: day,
                          child: Text('$day'),
                        );
                      }),
                      validator: (value) {
                        if (value == null) {
                          // لتحديث اللون الأحمر
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _safeSetState(() {
                              KaidhaSubController.isSalaryDayEmpty = true;
                            });
                            // تحريك السحب إلى الحقل الفارغ
                            if (!KaidhaSubController.salaryDayFocus.hasFocus) {
                              KaidhaSubController.salaryDayFocus.requestFocus();
                              Scrollable.ensureVisible(
                                KaidhaSubController.salaryDayFocus.context!,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            }
                          });

                          return 'day_selection_required'.tr;
                        }

                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Directionality.of(context) == TextDirection.rtl
                        ? Alignment.topRight
                        : Alignment.topLeft,
                    child: Text(
                      'monthly_income'.tr,
                      textAlign: Directionality.of(context) == TextDirection.rtl
                          ? TextAlign.right
                          : TextAlign.left,
                      style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeMedim),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Focus(
                    focusNode: KaidhaSubController.monthlyIncomeFocus,
                    child: TextFormField(
                      key: KaidhaSubController.monthlyIncomeKey,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      cursorColor: AppColors.bgColor,
                      controller: KaidhaSubController.monthlyIncome,
                      decoration: InputDecoration(
                        hintText: 'enter_approximate_monthly_income'.tr,
                        hintStyle:
                            font10Grey500W(context, size: size_14(context)),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 20),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: KaidhaSubController.isMonthlyIncomeEmpty
                                ? Colors.red
                                : AppColors.gryColor_3,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: KaidhaSubController.isMonthlyIncomeEmpty
                                ? Colors.red
                                : AppColors.greenColor,
                          ),
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (value) {
                        KaidhaSubController.debouncedSaveState();
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  Align(
                    alignment: Directionality.of(context) == TextDirection.rtl
                        ? Alignment.topRight
                        : Alignment.topLeft,
                    child: Text(
                      'attach_documents'.tr,
                      textAlign: Directionality.of(context) == TextDirection.rtl
                          ? TextAlign.right
                          : TextAlign.left,
                      style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeMedim),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Align(
                    child: Text(
                      'attach_clear_documents_description'.tr,
                      textAlign: TextAlign.right,
                      style: robotoRegular.copyWith(
                          color: AppColors.darkGreyColor,
                          fontSize: Dimensions.fontSizeSmall),
                    ),
                  ),
                  const SizedBox(height: 20),

                  //

                  const FileUploadWithNameWidget(),

                  //

                  const SizedBox(height: 20),
                  Container(
                    width: 1170,
                    padding: EdgeInsets.all(Dimensions.fontSizeDefault),
                    child: CustomButton(
                      buttonText: 'التالي',
                      onPressed: () async {
                        //

                        KaidhaSubController.validate_Fields_Screen_2(context,
                            KaidhaSubController.identity_card_number.text);

                        //
                      },
                    ),
                  ),
                ],
              ),
      );
    });
  }
}
