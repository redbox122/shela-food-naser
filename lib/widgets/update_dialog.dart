import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
// import 'package:in_app_update/in_app_update.dart'; // DISABLED - causes crashes
import 'package:sixam_mart/services/app_version_service.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class UpdateDialog extends StatefulWidget {
  final VersionCheckResult versionResult;
  final VoidCallback? onDismiss;

  const UpdateDialog({
    super.key,
    required this.versionResult,
    this.onDismiss,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isUpdating = false;
  bool _autoUpdateAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkAutoUpdateAvailability();
  }

  Future<void> _checkAutoUpdateAvailability() async {
    // DISABLED: Play Store InAppUpdate causes crashes
    // Always show "Update" button instead of "Auto Update"
    setState(() {
      _autoUpdateAvailable = false;
    });
    if (kDebugMode) {
      appLogger.info('Auto update check disabled to prevent crashes');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.versionResult.isForceUpdate,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
        ),
        child: Container(
          padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      color: widget.versionResult.isForceUpdate
                          ? Colors.orange.withValues(alpha: 0.1)
                          : Colors.blue.withValues(alpha: 0.1),
                      borderRadius:
                          BorderRadius.circular(Dimensions.radiusSmall),
                    ),
                    child: Icon(
                      widget.versionResult.isForceUpdate
                          ? Icons.warning_rounded
                          : Icons.system_update_rounded,
                      color: widget.versionResult.isForceUpdate
                          ? Colors.orange
                          : Colors.blue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.versionResult.isForceUpdate
                              ? 'update_required'.tr
                              : 'update_available'.tr,
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeLarge,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                        Text(
                          'new_version_available'.tr,
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: Dimensions.paddingSizeLarge),

              // Version Info
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'current_version'.tr,
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                        Text(
                          widget.versionResult.currentVersion,
                          style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Dimensions.paddingSizeSmall),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'latest_version'.tr,
                          style: robotoMedium.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                          ),
                        ),
                        Text(
                          widget.versionResult.latestVersion,
                          style: robotoBold.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Release Notes
              if (widget.versionResult.releaseNotes.isNotEmpty) ...[
                const SizedBox(height: Dimensions.paddingSizeDefault),
                Text(
                  'whats_new'.tr,
                  style: robotoBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusSmall),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Text(
                    widget.versionResult.releaseNotes,
                    style: robotoRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      height: 1.4,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: Dimensions.paddingSizeLarge),

              // Action Buttons
              Row(
                children: [
                  // Later button (only for optional updates)
                  if (!widget.versionResult.isForceUpdate)
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onDismiss?.call();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: Dimensions.paddingSizeDefault,
                          ),
                        ),
                        child: Text(
                          'update_later'.tr,
                          style: robotoMedium.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ),
                    ),

                  if (!widget.versionResult.isForceUpdate)
                    const SizedBox(width: Dimensions.paddingSizeDefault),

                  // Update button
                  Expanded(
                    flex: widget.versionResult.isForceUpdate ? 1 : 2,
                    child: ElevatedButton(
                      onPressed: _isUpdating ? null : _handleUpdate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.paddingSizeDefault,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(Dimensions.radiusSmall),
                        ),
                        elevation: 0,
                      ),
                      child: _isUpdating
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'update_now'.tr,
                              style: robotoBold.copyWith(
                                color: Colors.white,
                                fontSize: Dimensions.fontSizeDefault,
                              ),
                            ),
                    ),
                  ),
                ],
              ),

              // Auto update option for Android
              if ((!kIsWeb && Platform.isAndroid) &&
                  _autoUpdateAvailable &&
                  !widget.versionResult.isForceUpdate) ...[
                const SizedBox(height: Dimensions.paddingSizeDefault),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isUpdating ? null : _handleAutoUpdate,
                    icon: const Icon(
                      Icons.download_rounded,
                      size: 18,
                    ),
                    label: Text('try_auto_update'.tr),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeDefault,
                      ),
                      side: BorderSide(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimensions.radiusSmall),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleUpdate() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final versionService = AppVersionService();
      await versionService.launchStore(widget.versionResult.storeUrl);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('update_check_failed'.tr),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _handleAutoUpdate() async {
    setState(() {
      _isUpdating = true;
    });

    try {
      // Skip Play Store InAppUpdate (causes crashes) and go directly to store
      await _handleUpdate();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open store: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }
}
