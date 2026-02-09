import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ResponsiveHelper {
  // -------- Platform --------
  static bool isWeb() => kIsWeb;

  static bool isMobilePhone() => !kIsWeb;

  // -------- Screen Size --------
  static bool isMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < 650;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 650 && width < 1300;
  }

  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 1300;
  }
}
