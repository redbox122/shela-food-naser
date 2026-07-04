import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/responsive_size.dart';

/// Full-screen language picker. Selecting a language applies and persists it
/// immediately, then pops back.
class LanguageSelectScreen extends StatefulWidget {
  const LanguageSelectScreen({super.key});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen> {
  static const Color _titleColor = Color(0xFF111B18);
  static const Color _radioColor = Color(0xFF1A1A1A);

  @override
  void initState() {
    super.initState();
    // Sync the selected index with the currently active locale.
    Get.find<LocalizationController>().searchSelectedLanguage();
  }

  String _displayName(int index) {
    final String code =
        (AppConstants.languages[index].languageCode ?? '').toLowerCase();
    if (code == 'ar') {
      return 'العربية';
    }
    if (code == 'en') {
      return 'English (US)';
    }
    return AppConstants.languages[index].languageName ?? '';
  }

  void _selectLanguage(LocalizationController controller, int index) {
    final Locale locale = Locale(
      AppConstants.languages[index].languageCode!,
      AppConstants.languages[index].countryCode,
    );
    controller.setLanguage(context, locale);
    controller.setSelectLanguageIndex(index);
    controller.saveCacheLanguage(locale);
  }

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
          'اللغة',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 17.r(context),
            fontWeight: FontWeight.w700,
            color: _titleColor,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Get.back<void>(),
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Icon(Icons.arrow_back_ios_new,
                size: 18.r(context), color: _titleColor),
          ),
        ),
      ),
      body: SafeArea(
        child: GetBuilder<LocalizationController>(
          builder: (LocalizationController controller) {
            return ListView.separated(
              padding: EdgeInsets.symmetric(
                  horizontal: 20.r(context), vertical: 8.r(context)),
              itemCount: AppConstants.languages.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFF1F2F4),
              ),
              itemBuilder: (BuildContext context, int index) {
                final bool selected = controller.selectedLanguageIndex == index;
                return InkWell(
                  onTap: () => _selectLanguage(controller, index),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.r(context)),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _displayName(index),
                            textAlign: TextAlign.start,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14.r(context),
                              fontWeight: FontWeight.w700,
                              color: _titleColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.r(context)),
                        _radio(context, selected),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _radio(BuildContext context, bool selected) {
    return Container(
      width: 22.r(context),
      height: 22.r(context),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? _radioColor : AppColors.gryColor_4,
          width: 6.r(context),
        ),
      ),
    );
  }
}
