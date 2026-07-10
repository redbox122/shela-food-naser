import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:play_install_referrer/play_install_referrer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/auth/helper/qr_referral_token_storage.dart';

/// Reads Android Play Install Referrer and stores customer store-QR referral tokens.
class QrReferralInstallReferrerService {
  QrReferralInstallReferrerService._();

  static const String _customerReferralType = 'customer';
  static const String _referralTypeKey = 'referral_type';
  static const String _referralTokenKey = 'referral_token';

  static Future<void> captureFromInstallReferrer(
    SharedPreferences sharedPreferences,
  ) async {
    if (!(!kIsWeb && Platform.isAndroid)) {
      return;
    }
    debugPrint('[QR_REFERRAL_INSTALL_REFERRER_INIT]');
    final QrReferralTokenStorage storage =
        QrReferralTokenStorage(sharedPreferences);
    try {
      final ReferrerDetails referrerDetails =
          await PlayInstallReferrer.installReferrer;
      final String rawReferrer = referrerDetails.installReferrer?.trim() ?? '';
      debugPrint('[QR_REFERRAL_INSTALL_REFERRER_RAW] payload=$rawReferrer');
      if (rawReferrer.isEmpty) {
        _logIgnored('empty_referrer_payload');
        return;
      }
      final Map<String, String> parsed = _parseReferrerPayload(rawReferrer);
      debugPrint(
        '[QR_REFERRAL_INSTALL_REFERRER_PARSED] '
        'referral_type=${parsed[_referralTypeKey] ?? ''} '
        'has_referral_token=${(parsed[_referralTokenKey] ?? '').isNotEmpty}',
      );
      final String referralType = parsed[_referralTypeKey]?.trim() ?? '';
      final String referralToken = parsed[_referralTokenKey]?.trim() ?? '';
      if (referralType != _customerReferralType) {
        _logIgnored('referral_type_not_customer type=$referralType');
        return;
      }
      if (referralToken.isEmpty) {
        _logIgnored('missing_referral_token');
        return;
      }
      if (storage.hasStoredToken()) {
        _logIgnored(
          'already_stored token=${storage.getStoredToken()}',
        );
        return;
      }
      await storage.saveToken(referralToken);
    } catch (error) {
      _logIgnored('referrer_unavailable error=$error');
    }
  }

  static Map<String, String> _parseReferrerPayload(String rawReferrer) {
    try {
      final String normalized = rawReferrer.startsWith('?')
          ? rawReferrer.substring(1)
          : rawReferrer;
      return Uri.splitQueryString(normalized);
    } catch (_) {
      return <String, String>{};
    }
  }

  static void _logIgnored(String reason) {
    debugPrint('[QR_REFERRAL_INSTALL_REFERRER_IGNORED] reason=$reason');
  }
}
