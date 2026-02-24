import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ResponsiveHelper {
  // ⚙️ إعداد: استخدام تصميم الموبايل على الويب
  // قم بتعيين هذا المتغير إلى true لاستخدام تصميم الموبايل على الويب
  // false = استخدام تصميم الويب المخصص (Desktop)
  // true = استخدام تصميم الموبايل على الويب
  static const bool useMobileDesignOnWeb = true;

  // -------- Platform --------
  /// يعيد true إذا كانت المنصة هي الويب
  static bool isWeb() => kIsWeb;

  /// يعيد true إذا كانت المنصة هي الموبايل (Android/iOS)
  static bool isMobilePhone() => !kIsWeb;

  /// يعيد true إذا كان يجب استخدام تصميم الموبايل
  /// يأخذ في الاعتبار إعداد useMobileDesignOnWeb
  static bool shouldUseMobileDesign(BuildContext context) {
    // إذا كان الموبايل الحقيقي، استخدم تصميم الموبايل
    if (!kIsWeb) return true;
    
    // إذا كان الويب واستخدام تصميم الموبايل مفعّل، استخدم تصميم الموبايل
    if (kIsWeb && useMobileDesignOnWeb) return true;
    
    // إذا كان الويب وعرض الشاشة صغير، استخدم تصميم الموبايل
    final width = MediaQuery.of(context).size.width;
    if (kIsWeb && width < 650) return true;
    
    // غير ذلك، استخدم تصميم Desktop
    return false;
  }

  // -------- Screen Size --------
  /// يعيد true إذا كان عرض الشاشة أقل من 650px
  static bool isMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < 650;
  }

  /// يعيد true إذا كان عرض الشاشة بين 650px و 1300px
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 650 && width < 1300;
  }

  /// يعيد true إذا كان يجب استخدام تصميم Desktop
  /// يأخذ في الاعتبار إعداد useMobileDesignOnWeb
  static bool isDesktop(BuildContext context) {
    // ⚙️ إذا كان الويب واستخدام تصميم الموبايل مفعّل، لا نعرض تصميم Desktop
    if (kIsWeb && useMobileDesignOnWeb) {
      return false;
    }
    final width = MediaQuery.of(context).size.width;
    return width >= 1300;
  }
}
