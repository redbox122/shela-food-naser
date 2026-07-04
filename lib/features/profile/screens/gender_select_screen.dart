import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/responsive_size.dart';

/// Full-screen gender picker. Returns the chosen value (via `Get.back`) when the
/// user taps "حفظ", or null if dismissed. UI-only — not sent to the backend.
class GenderSelectScreen extends StatefulWidget {
  final String? initial;

  const GenderSelectScreen({super.key, this.initial});

  @override
  State<GenderSelectScreen> createState() => _GenderSelectScreenState();
}

class _GenderSelectScreenState extends State<GenderSelectScreen> {
  static const Color _titleColor = Color(0xFF111B18);
  static const List<String> _options = <String>['ذكر', 'أنثى'];

  late String? _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.wtColor,
      appBar: AppBar(
        backgroundColor: AppColors.wtColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'pf_set_gender'.tr,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 17.r(context),
            fontWeight: FontWeight.w700,
            color: _titleColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 18.r(context), color: _titleColor),
          onPressed: () => Get.back<String>(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20.r(context), 14.r(context),
                    20.r(context), 20.r(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'pf_choose_your_gender'.tr,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 20.r(context),
                        fontWeight: FontWeight.w700,
                        color: _titleColor,
                      ),
                    ),
                    SizedBox(height: 6.r(context)),
                    Text(
                      'pf_gender_note'.tr,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16.r(context),
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                        color: _titleColor,
                      ),
                    ),
                    SizedBox(height: 18.r(context)),
                    for (final String option in _options) _optionRow(option),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.r(context), 8.r(context),
                  20.r(context), 16.r(context)),
              child: SizedBox(
                width: double.infinity,
                height: 52.r(context),
                child: Material(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => Get.back<String>(result: _selected),
                    child: Center(
                      child: Text(
                        'pf_save'.tr,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 15.r(context),
                          fontWeight: FontWeight.w700,
                          color: AppColors.wtColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionRow(String option) {
    final bool selected = _selected == option;
    return InkWell(
      onTap: () => setState(() => _selected = option),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.r(context)),
        child: Row(
          children: <Widget>[
            _radio(selected),
            SizedBox(width: 12.r(context)),
            Text(
              option,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 15.r(context),
                fontWeight: FontWeight.w500,
                color: _titleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _radio(bool selected) {
    return Container(
      width: 22.r(context),
      height: 22.r(context),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? const Color(0xFF1A1A1A) : AppColors.gryColor_4,
          width: 6.r(context),
        ),
      ),
    );
  }
}
