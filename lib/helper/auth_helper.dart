import 'package:get/get.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';

class AuthHelper {
  static bool isGuestLoggedIn() {
    if (!Get.isRegistered<AuthController>()) {
      return false;
    }
    return Get.find<AuthController>().isGuestLoggedIn();
  }

  static String getGuestId() {
    if (!Get.isRegistered<AuthController>()) {
      return '';
    }
    return Get.find<AuthController>().getGuestId();
  }

  static bool isLoggedIn() {
    if (!Get.isRegistered<AuthController>()) {
      return false;
    }
    return Get.find<AuthController>().isLoggedIn();
  }
}
