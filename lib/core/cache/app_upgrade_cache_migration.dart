import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/common/cache/comprehensive_home_cache_manager.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// One-time cache cleanup that runs the first time the app launches after an
/// APK upgrade (installing a new build over an existing install).
///
/// Problem it solves: cached layout data from the previous version — the last
/// selected module id, the cached app config / module list, and cached home
/// data carrying old icons — used to survive an in-place update. The updated
/// app then rendered a hybrid of the old and new home design (new banners and
/// bottom tabs, but an old-style vertical services list), and only a full
/// delete-and-reinstall fixed it. This migration reproduces that reinstall —
/// but ONLY for disposable cache.
///
/// Auth token, guest id, saved address, theme and language live in
/// SharedPreferences under their own keys and are deliberately preserved, so the
/// user stays logged in and keeps their address/preferences across the upgrade.
class AppUpgradeCacheMigration {
  AppUpgradeCacheMigration._();

  /// SharedPreferences key holding the app version that last ran on this device.
  static const String _lastRunVersionKey =
      'last_run_app_version_for_cache_clear';

  /// SharedPreferences keys that cache the module selection / layout and must be
  /// dropped on upgrade. Auth/address/theme/language keys are intentionally
  /// NOT listed here so they survive the upgrade.
  static const List<String> _staleModuleKeys = <String>[
    AppConstants.moduleId,
    AppConstants.cacheModuleId,
  ];

  /// Clears stale layout cache if the stored version differs from the current
  /// [AppConstants.appVersion]. A no-op once the current version is recorded, so
  /// it is safe and cheap to call on every cold start (just one SharedPreferences
  /// read on the normal path — no Hive work).
  ///
  /// MUST be awaited early in startup, before any config/module is read, so the
  /// fresh data is fetched from the server on this same launch.
  static Future<void> runIfUpgraded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String currentVersion = AppConstants.appVersion.toString();
      final String? lastVersion = prefs.getString(_lastRunVersionKey);

      if (lastVersion == currentVersion) {
        return; // Same version already handled — fast path, no Hive work.
      }

      if (kDebugMode) {
        debugPrint(
            '♻️ AppUpgradeCacheMigration: app version ${lastVersion ?? 'fresh'} → $currentVersion, clearing stale layout cache');
      }

      // 1) Drop the cached module selection + cached config / module list /
      //    home data from Hive so the new design loads like a fresh install.
      await HiveHomeCacheService().wipeForUpgrade();

      // 2) Drop the legacy SharedPreferences module-selection keys so the
      //    SharedPreferences-based cache-module path also resets to "unselected".
      for (final key in _staleModuleKeys) {
        await prefs.remove(key);
      }

      // 3) Drop the SharedPreferences comprehensive home cache (banners,
      //    categories, brands, stores, offers) for every module.
      await ComprehensiveHomeCacheManager.clearComprehensiveCache();

      // Record the current version LAST so a failure above retries next launch.
      await prefs.setString(_lastRunVersionKey, currentVersion);

      if (kDebugMode) {
        debugPrint('✅ AppUpgradeCacheMigration: stale layout cache cleared');
      }
    } catch (e) {
      // Never block startup on a cache-clear failure — worst case the user sees
      // the old behaviour for one more launch and we retry next time.
      if (kDebugMode) {
        debugPrint('⚠️ AppUpgradeCacheMigration: skipped due to error — $e');
      }
    }
  }
}
