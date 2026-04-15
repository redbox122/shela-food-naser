import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/helper/db_helper.dart';

class LocalClient {
  static Future<String?> organize(DataSourceEnum source, String cacheId,
      String? responseBody, Map<String, String>? header) async {
    final SharedPreferences sharedPreferences = Get.find();
    switch (source) {
      case DataSourceEnum.client:
        try {
          if (GetPlatform.isWeb) {
            await sharedPreferences.setString(cacheId, responseBody ?? '');
          } else {
            await DbHelper.insertOrUpdate(
              id: cacheId,
              data: responseBody ?? '',
            );
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('=====error occure in local_client write: $e');
          }
        }
        break;
      case DataSourceEnum.local:
        try {
          if (GetPlatform.isWeb) {
            return sharedPreferences.getString(cacheId);
          } else {
            return await DbHelper.getCacheById(cacheId);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('=====error occur in local_client read: $e');
          }
        }
        break;
    }
    return null;
  }
}
