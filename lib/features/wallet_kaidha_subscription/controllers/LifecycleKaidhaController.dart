import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:lifecycle_controller/lifecycle_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/controllers/kaidhaSub_controller.dart';

class LifecycleKaidhaController extends LifecycleController {
  final KaidhaSubscriptionController kaidhaController =
      Get.find<KaidhaSubscriptionController>();
  Timer? _pauseTimer;

  // -------------------------------------------------------------------------------

  void _sendState(String state, String messageAr) {
    kaidhaController.SendState_kaidha(state);

    debugPrint('📤 الحالة الحالية: $messageAr ($state)');
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
