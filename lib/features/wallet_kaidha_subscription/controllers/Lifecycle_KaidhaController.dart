// ignore_for_file: avoid_print, camel_case_types, file_names

import 'dart:async';
import 'package:get/get.dart';
import 'package:lifecycle_controller/lifecycle_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';

class Lifecycle_KaidhaController extends LifecycleController {
  final KaidhaSubscription_Controller kaidhaController =
      Get.find<KaidhaSubscription_Controller>();
  Timer? _pauseTimer;

  // -------------------------------------------------------------------------------

  void _sendState(String state, String messageAr) {
    kaidhaController.SendState_kaidha(state);

    print('📤 الحالة الحالية: $messageAr ($state)');
  }

  // ==================================================

  @override
  void onDispose() {
    super.onDispose();
    _pauseTimer?.cancel();
    _sendState('abandoned', 'تم إغلاق الصفحة بدون إكمال');
  }

  @override
  void onResumed() {
    super.onResumed();
    _pauseTimer?.cancel();
    _sendState('in_progress', 'تم الرجوع إلى التطبيق');
  }

  @override
  void onPaused() {
    super.onPaused();
    _pauseTimer?.cancel();
    _pauseTimer = Timer(const Duration(seconds: 5), () {
      _sendState('background_for_nafath', 'تم الانتقال مؤقتًا لتطبيق نفاذ');
    });
  }

  @override
  void onDetached() {
    super.onDetached();
    _pauseTimer?.cancel();
    _sendState('abandoned', 'تم إغلاق التطبيق نهائيًا');
  }
}
