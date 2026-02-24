import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/services/app_version_service.dart';
import 'package:sixam_mart/widgets/update_dialog.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class UpdateController extends GetxController with WidgetsBindingObserver {
  final AppVersionService _versionService = AppVersionService();

  bool _isChecking = false;
  bool get isChecking => _isChecking;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Check for updates when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      checkForUpdates();
    }
  }

  /// Check for app updates
  Future<void> checkForUpdates({bool showLoading = true}) async {
    if (kDebugMode) {
      appLogger.debug('🎯 checkForUpdates called with showLoading: $showLoading');
    }

    if (_isChecking) {
      if (kDebugMode) {
        appLogger.debug('⏭️ Already checking for updates, skipping...');
      }
      return;
    }

    try {
      _isChecking = true;
      update();

      // Only check if enough time has passed
      final shouldCheck = await _versionService.shouldCheckForUpdates();
      if (kDebugMode) {
        appLogger.debug('⏰ Should check for updates: $shouldCheck');
      }

      if (!shouldCheck) {
        if (kDebugMode) {
          appLogger.debug('⏭️ Skipping update check - 24 hours not elapsed');
        }
        return;
      }

      if (showLoading) {
        _showLoadingDialog();
      }

      final result = await _versionService.checkForUpdates();

      if (showLoading) {
        Get.back(); // Close loading dialog
      }

      if (result.updateAvailable && Get.context != null) {
        // Save check time
        await _versionService.saveLastCheckTime();

        // Show notification if should show
        if (await _versionService.shouldShowNotification()) {
          await _versionService.showUpdateNotification(result);
          await _versionService.saveNotificationShownTime();
        }

        // Show update dialog
        _showUpdateDialog(result);
      } else if (showLoading) {
        // Show "up to date" message
        _showUpToDateMessage();
      }
    } catch (e) {
      if (showLoading) {
        Get.back(); // Close loading dialog
      }
      if (kDebugMode) {
        appLogger.error('Error checking for updates: $e', e);
      }
      if (showLoading) {
        _showErrorMessage();
      }
    } finally {
      _isChecking = false;
      update();
    }
  }

  /// Show loading dialog
  void _showLoadingDialog() {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('checking_for_updates'.tr),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Show update dialog
  void _showUpdateDialog(VersionCheckResult result) {
    Get.dialog(
      UpdateDialog(
        versionResult: result,
        onDismiss: () {
          // Optional: Handle dismiss action
        },
      ),
      barrierDismissible: !result.isForceUpdate,
    );
  }

  /// Show up to date message
  void _showUpToDateMessage() {
    Get.snackbar(
      'update_available'.tr,
      'you_have_latest_version'.tr,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Show error message
  void _showErrorMessage() {
    Get.snackbar(
      'update_check_failed'.tr,
      'update_check_failed'.tr,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  /// Manual check for updates (from settings or menu)
  Future<void> manualCheckForUpdates() async {
    await checkForUpdates();
  }

  /// Check for updates on app start
  Future<void> checkForUpdatesOnStart() async {
    if (kDebugMode) {
      appLogger.debug('🚀 UpdateController.checkForUpdatesOnStart() called');
    }
    // Add a small delay to ensure app is fully loaded
    Timer(const Duration(seconds: 2), () {
      if (kDebugMode) {
        appLogger.debug('⏰ Timer fired, calling checkForUpdates...');
      }
      checkForUpdates(showLoading: false);
    });
  }

  /// Force immediate update check (bypass 24-hour restriction)
  Future<void> forceCheckForUpdates() async {
    // Clear last check time to bypass 24-hour restriction
    await _versionService.clearLastCheckTime();
    // Now check for updates
    await checkForUpdates();
  }
}
