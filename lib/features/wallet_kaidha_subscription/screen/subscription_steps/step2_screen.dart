import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:sixam_mart/common/widgets/labeled_input_field.dart';
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

  static const Color _fill = Color(0xFFF6F5F8);
  static const Color _labelColor = Color(0xFF111B18);

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(fn);
      }
    });
  }

  // ── ستايل موحّد لحقول التصميم (رمادي ممتلئ + Tajawal) ──
  InputBorder _fieldBorder(Color color, {double width = 0}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
      borderSide:
          width == 0 ? BorderSide.none : BorderSide(color: color, width: width),
    );
  }

  InputDecoration _fieldDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: tajawalMedium.copyWith(
          fontSize: Dimensions.fontSizeLarge, color: const Color(0xFF555555)),
      filled: true,
      fillColor: _fill,
      isDense: true,
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: _fieldBorder(_fill),
      enabledBorder: _fieldBorder(_fill),
      focusedBorder: _fieldBorder(AppColors.greenColor, width: 1),
      errorBorder: _fieldBorder(Colors.red, width: 1),
      focusedErrorBorder: _fieldBorder(Colors.red, width: 1),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(TextSpan(children: [
        TextSpan(
          text: text,
          style: tajawalBold.copyWith(
              fontSize: Dimensions.fontSizeMedim, color: _labelColor),
        ),
        TextSpan(
          text: ' *',
          style: tajawalBold.copyWith(
              fontSize: Dimensions.fontSizeExtraLarge, color: Colors.red),
        ),
      ])),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: tajawalBold.copyWith(
          fontSize: 17, fontWeight: FontWeight.w700, color: _labelColor),
    );
  }

  Widget _installmentOption(
      KaidhaSubscriptionController ctrl, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RadioTheme(
          data: RadioThemeData(
            fillColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.greenColor;
              }
              return AppColors.gryColor_3;
            }),
          ),
          // ignore: deprecated_member_use
          child: Radio<String>(
            value: value,
            // ignore: deprecated_member_use
            groupValue: ctrl.Installments,
            // ignore: deprecated_member_use
            onChanged: (v) {
              ctrl.updateInstallments(v!);
              ctrl.debouncedSaveState();
            },
          ),
        ),
        Text(label,
            style: tajawalMedium.copyWith(fontSize: Dimensions.fontSizeDefault)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<KaidhaSubscriptionController>(
        builder: (KaidhaSubController) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: KaidhaSubController.isLoading_OTP
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _sectionTitle('source_of_income'.tr),
                  const SizedBox(height: 6),
                  Text(
                    'select_main_income_source'.tr,
                    style: tajawalMedium.copyWith(
                      color: Theme.of(context).disabledColor,
                      fontSize: Dimensions.fontSizeSmall,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // اسم جهة العمل
                  LabeledInputField(
                    label: 'employer_name'.tr,
                    hint: 'employer_name'.tr,
                    required: true,
                    controller: KaidhaSubController.name_of_employer,
                    focusNode: KaidhaSubController.employerFocus,
                    onChanged: (_) => KaidhaSubController.debouncedSaveState(),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'هذا الحقل مطلوب' : null,
                  ),

                  const SizedBox(height: 16),

                  // إجمالي الراتب
                  _label('total_salary'.tr),
                  Container(
                    key: KaidhaSubscriptionController.totalSalaryKey,
                    child: Focus(
                      focusNode: KaidhaSubController.totalSalaryFocus,
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        cursorColor: AppColors.bgColor,
                        controller: KaidhaSubController.total_salary,
                        style: tajawalRegular.copyWith(
                            fontSize: Dimensions.fontSizeDefault),
                        decoration: _fieldDecoration('total_salary'.tr),
                        onChanged: (_) =>
                            KaidhaSubController.debouncedSaveState(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // التقسيط
                  _sectionTitle('installments'.tr),
                  Row(
                    children: [
                      _installmentOption(KaidhaSubController, 'yes'.tr, 'yes'),
                      _installmentOption(KaidhaSubController, 'no'.tr, 'no'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // اختر مصدر الدخل الرئيسي
                  const JobSpecification(),

                  const SizedBox(height: 16),

                  // ما هو يوم استلام راتبك
                  _label('what_is_your_salary_day'.tr),
                  Focus(
                    focusNode: KaidhaSubController.salaryDayFocus,
                    child: DropdownButtonFormField<int>(
                      decoration: _fieldDecoration('select_day'.tr),
                      // ignore: deprecated_member_use
                      value: selectedDay,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Color(0xFF9AA0A6)),
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
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _safeSetState(() {
                              KaidhaSubController.isSalaryDayEmpty = true;
                            });
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

                  const SizedBox(height: 16),

                  // الدخل الشهري
                  _label('monthly_income'.tr),
                  Focus(
                    focusNode: KaidhaSubController.monthlyIncomeFocus,
                    child: TextFormField(
                      key: KaidhaSubController.monthlyIncomeKey,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      cursorColor: AppColors.bgColor,
                      controller: KaidhaSubController.monthlyIncome,
                      style: tajawalRegular.copyWith(
                          fontSize: Dimensions.fontSizeDefault),
                      decoration:
                          _fieldDecoration('enter_approximate_monthly_income'.tr),
                      onChanged: (value) {
                        KaidhaSubController.debouncedSaveState();
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // المستندات
                  _sectionTitle('attach_documents'.tr),
                  const SizedBox(height: 8),
                  Text(
                    'attach_clear_documents_description'.tr,
                    style: tajawalMedium.copyWith(
                        color: AppColors.darkGreyColor,
                        fontSize: Dimensions.fontSizeSmall),
                  ),
                  const SizedBox(height: 16),

                  const FileUploadWithNameWidget(),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      buttonText: 'التالي',
                      onPressed: () async {
                        KaidhaSubController.validate_Fields_Screen_2(context,
                            KaidhaSubController.identity_card_number.text);
                      },
                    ),
                  ),
                ],
              ),
      );
    });
  }
}
