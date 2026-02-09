import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/util/app_constants.dart';

class HeaderHelper {
  static Map<String, String> featuredHeader() {
    final SharedPreferences sharedPreferences = Get.find<SharedPreferences>();
    AddressModel? addressModel;
    try {
      addressModel = AddressModel.fromJson(
          jsonDecode(sharedPreferences.getString(AppConstants.userAddress)!) as Map<String, dynamic>);
    } catch (_) {}
    
    // ❌ IMPORTANT: Do NOT include moduleId for featured content
    // Featured banners/items are cross-module and should not be filtered by module
    
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      AppConstants.zoneId: addressModel?.zoneIds != null
          ? jsonEncode(addressModel?.zoneIds)
          : '',
      // ❌ NO moduleId for featured content - it's cross-module
      AppConstants.localizationKey:
          sharedPreferences.getString(AppConstants.languageCode) ??
              AppConstants.languages[0].languageCode!,
      AppConstants.latitude: addressModel?.latitude != null
          ? jsonEncode(addressModel?.latitude)
          : '',
      AppConstants.longitude: addressModel?.longitude != null
          ? jsonEncode(addressModel?.longitude)
          : '',
      // 'Authorization': 'Bearer $token'
    };
  }
}
