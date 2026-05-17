import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// Persists the Play Install Referrer [referral_token] for customer sign-up only.
class QrReferralTokenStorage {
  QrReferralTokenStorage(this._sharedPreferences);

  final SharedPreferences _sharedPreferences;

  String? getStoredToken() {
    final String? token =
        _sharedPreferences.getString(AppConstants.qrReferralInstallToken);
    if (token == null || token.trim().isEmpty) {
      return null;
    }
    return token.trim();
  }

  bool hasStoredToken() => getStoredToken() != null;

  Future<bool> saveToken(String token) async {
    final String trimmed = token.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    final bool saved = await _sharedPreferences.setString(
      AppConstants.qrReferralInstallToken,
      trimmed,
    );
    if (saved) {
      debugPrint(
        '[QR_REFERRAL_INSTALL_REFERRER_STORED] token=$trimmed',
      );
    }
    return saved;
  }

  Future<bool> clearToken() async {
    final bool hadToken = hasStoredToken();
    final bool cleared =
        await _sharedPreferences.remove(AppConstants.qrReferralInstallToken);
    if (cleared && hadToken) {
      debugPrint('[QR_REFERRAL_SIGNUP_TOKEN_CLEARED]');
    }
    return cleared;
  }
}
