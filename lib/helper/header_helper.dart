import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/util/app_constants.dart';

class HeaderHelper {
  static Map<String, String> featuredHeader() {
    final SharedPreferences sharedPreferences = Get.find<SharedPreferences>();
    AddressModel? addressModel;
    try {
      final rawAddress = sharedPreferences.getString(AppConstants.userAddress);
      if (rawAddress != null && rawAddress.isNotEmpty) {
        addressModel = AddressModel.fromJson(
            jsonDecode(rawAddress) as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('$e');
    }

    // ❌ IMPORTANT: Do NOT include moduleId for featured content
    // Featured banners/items are cross-module and should not be filtered by module

    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      // ❌ NO moduleId for featured content - it's cross-module
      AppConstants.localizationKey:
          sharedPreferences.getString(AppConstants.languageCode) ??
              AppConstants.languages[0].languageCode!,
    };

    final zoneIds = addressModel?.zoneIds;
    if (zoneIds != null && zoneIds.isNotEmpty) {
      headers[AppConstants.zoneId] = jsonEncode(zoneIds);
    }

    final latitude = addressModel?.latitude;
    final longitude = addressModel?.longitude;
    if (latitude != null && latitude.isNotEmpty) {
      headers[AppConstants.latitude] = jsonEncode(latitude);
    }
    if (longitude != null && longitude.isNotEmpty) {
      headers[AppConstants.longitude] = jsonEncode(longitude);
    }

    final token = sharedPreferences.getString(AppConstants.token);
    if (token != null && token.isNotEmpty && token != 'null') {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}
