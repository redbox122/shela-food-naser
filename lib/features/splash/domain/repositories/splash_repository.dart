import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/local_client.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/splash/domain/models/landing_model.dart';
import 'dart:convert';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/domain/repositories/splash_repository_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class SplashRepository implements SplashRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  SplashRepository({required this.apiClient, required this.sharedPreferences});

  @override
  Future<Response> getConfigData({required DataSourceEnum source}) async {
    Response responseData = const Response(statusCode: 00);
    const String cacheId = AppConstants.configUri;

    switch (source) {
      case DataSourceEnum.client:
        final Response response =
            await apiClient.getData(AppConstants.configUri);
        if (response.statusCode == 200) {
          responseData = Response(
              statusCode: 200, body: response.body as Map<String, dynamic>);
          LocalClient.organize(source, cacheId, jsonEncode(response.body),
              apiClient.getHeader());
        } else if (response.statusCode == 304 || response.body == null) {
          final String? cacheResponseData = await LocalClient.organize(
              DataSourceEnum.local, cacheId, null, null);
          if (cacheResponseData != null) {
            responseData = Response(
                statusCode: 200,
                body: jsonDecode(cacheResponseData) as Map<String, dynamic>);
          } else {
            debugPrint(
                '\x1B[33m⚠️ Config API 304/NULL with cache miss - forcing non-ETag fetch\x1B[0m');
            final Response forcedResponse = await apiClient.getData(
              AppConstants.configUri,
              useEtag: false,
            );
            if (forcedResponse.statusCode == 200 &&
                forcedResponse.body != null) {
              responseData = Response(
                  statusCode: 200,
                  body: forcedResponse.body as Map<String, dynamic>);
              LocalClient.organize(source, cacheId,
                  jsonEncode(forcedResponse.body), apiClient.getHeader());
            }
          }
        }

      case DataSourceEnum.local:
        final String? cacheResponseData =
            await LocalClient.organize(source, cacheId, null, null);
        if (cacheResponseData != null) {
          responseData = Response(
              statusCode: 200,
              body: jsonDecode(cacheResponseData) as Map<String, dynamic>);
        }
    }
    return responseData;
  }

  @override
  Future<LandingModel?> getLandingPageData(
      {required DataSourceEnum source}) async {
    LandingModel? landingModel;
    const String cacheId = AppConstants.landingPageUri;

    switch (source) {
      case DataSourceEnum.client:
        final Response response =
            await apiClient.getData(AppConstants.landingPageUri);
        if (response.statusCode == 200) {
          landingModel =
              LandingModel.fromJson(response.body as Map<String, dynamic>);
          LocalClient.organize(source, cacheId, jsonEncode(response.body),
              apiClient.getHeader());
        }

      case DataSourceEnum.local:
        final String? cacheResponseData =
            await LocalClient.organize(source, cacheId, null, null);
        if (cacheResponseData != null) {
          landingModel = LandingModel.fromJson(
              jsonDecode(cacheResponseData) as Map<String, dynamic>);
        }
    }
    return landingModel;
  }

  @override
  Future<ModuleModel?> initSharedData() async {
    // Check if this is a fresh install by looking for a unique install key
    const String installKey = 'app_install_timestamp';
    final bool isFreshInstall = !sharedPreferences.containsKey(installKey);

    if (isFreshInstall) {
      // This is a fresh install, set install timestamp and ensure onboarding shows
      await sharedPreferences.setInt(
          installKey, DateTime.now().millisecondsSinceEpoch);
      await sharedPreferences.setBool(AppConstants.intro, true);
      // Ensure the very first run starts in light mode by default.
      await sharedPreferences.setBool(AppConstants.theme, false);
      debugPrint('🆕 Fresh install detected - onboarding will be shown');
    }

    if (!sharedPreferences.containsKey(AppConstants.theme)) {
      await sharedPreferences.setBool(AppConstants.theme, false);
    }
    if (!sharedPreferences.containsKey(AppConstants.countryCode)) {
      sharedPreferences.setString(
          AppConstants.countryCode, AppConstants.languages[0].countryCode!);
    }
    if (!sharedPreferences.containsKey(AppConstants.languageCode)) {
      sharedPreferences.setString(
          AppConstants.languageCode, AppConstants.languages[0].languageCode!);
    }
    if (!sharedPreferences.containsKey(AppConstants.cartList)) {
      sharedPreferences.setStringList(AppConstants.cartList, []);
    }
    if (!sharedPreferences.containsKey(AppConstants.searchHistory)) {
      sharedPreferences.setStringList(AppConstants.searchHistory, []);
    }
    if (!sharedPreferences.containsKey(AppConstants.notification)) {
      sharedPreferences.setBool(AppConstants.notification, true);
    }
    if (!sharedPreferences.containsKey(AppConstants.intro)) {
      sharedPreferences.setBool(AppConstants.intro, true);
    }
    if (!sharedPreferences.containsKey(AppConstants.notificationCount)) {
      sharedPreferences.setInt(AppConstants.notificationCount, 0);
    }
    if (!sharedPreferences.containsKey(AppConstants.suggestedLocation)) {
      sharedPreferences.setBool(AppConstants.suggestedLocation, false);
    }
    if (!sharedPreferences.containsKey(AppConstants.referBottomSheet)) {
      sharedPreferences.setBool(AppConstants.referBottomSheet, true);
    }

    ModuleModel? module;
    if (sharedPreferences.containsKey(AppConstants.moduleId)) {
      try {
        module = ModuleModel.fromJson(
            jsonDecode(sharedPreferences.getString(AppConstants.moduleId)!)
                as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Did not get shared Preferences module. Note: $e');
      }
    }
    return module;
  }

  @override
  void disableIntro() {
    sharedPreferences.setBool(AppConstants.intro, false);
  }

  @override
  bool? showIntro() {
    return sharedPreferences.getBool(AppConstants.intro);
  }

  @override
  Future<void> setStoreCategory(int storeCategoryID) async {
    AddressModel? addressModel;
    try {
      final rawAddress = sharedPreferences.getString(AppConstants.userAddress);
      if (rawAddress != null && rawAddress.isNotEmpty) {
        addressModel = AddressModel.fromJson(
            jsonDecode(rawAddress) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Did not get shared Preferences address . Note: $e');
    }
    apiClient.updateHeader(
      sharedPreferences.getString(AppConstants.token),
      addressModel?.zoneIds,
      addressModel?.areaIds,
      sharedPreferences.getString(AppConstants.languageCode),
      storeCategoryID,
      addressModel?.latitude,
      addressModel?.longitude,
    );
  }

  @override
  Future<List<ModuleModel>?> getModules(
      {Map<String, String>? headers, required DataSourceEnum source}) async {
    List<ModuleModel>? moduleList;
    const String cacheId = AppConstants.moduleUri;

    switch (source) {
      case DataSourceEnum.client:
        final Response response =
            await apiClient.getData(AppConstants.moduleUri, headers: headers);
        debugPrint('\x1B[32mModules API status: ${response.statusCode}\x1B[0m');

        if (response.statusCode == 200 && response.body is List) {
          moduleList = [];
          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.debug(
                'Modules API response: ${(response.body as List).length} modules returned');
          }

          for (var storeCategory in (response.body as List)) {
            final module =
                ModuleModel.fromJson(storeCategory as Map<String, dynamic>);
            moduleList.add(module);
            if (kDebugMode && AppConstants.enableVerboseLogs) {
              appLogger.debug(
                  'Module ${module.id}: ${module.moduleName} (${module.moduleType}) - ${module.storesCount} stores');
            }
          }

          if (kDebugMode && AppConstants.enableVerboseLogs) {
            appLogger.debug('Total modules loaded: ${moduleList.length}');
          }

          LocalClient.organize(source, cacheId, jsonEncode(response.body),
              apiClient.getHeader());
        } else if (response.statusCode == 304 || response.body == null) {
          debugPrint(
              '\x1B[33mModules API 304/NULL body - loading module list from cache\x1B[0m');

          final String? cacheResponseData = await LocalClient.organize(
              DataSourceEnum.local, cacheId, null, null);

          if (cacheResponseData != null) {
            moduleList = [];
            for (var storeCategory in (jsonDecode(cacheResponseData) as List)) {
              moduleList.add(
                  ModuleModel.fromJson(storeCategory as Map<String, dynamic>));
            }
            debugPrint(
                '\x1B[32mModules cache hydration success: ${moduleList.length} modules\x1B[0m');
          } else {
            debugPrint('\x1B[31mModules cache miss after 304/NULL body\x1B[0m');
            debugPrint(
                '\x1B[33mRetrying modules API with ETag disabled\x1B[0m');

            final Response forcedResponse = await apiClient.getData(
              AppConstants.moduleUri,
              headers: headers,
              useEtag: false,
            );

            if (forcedResponse.statusCode == 200 &&
                forcedResponse.body is List) {
              moduleList = [];
              for (var storeCategory in (forcedResponse.body as List)) {
                moduleList.add(ModuleModel.fromJson(
                    storeCategory as Map<String, dynamic>));
              }
              LocalClient.organize(source, cacheId,
                  jsonEncode(forcedResponse.body), apiClient.getHeader());
              debugPrint(
                  '\x1B[32mModules force-fetch success: ${moduleList.length} modules\x1B[0m');
            } else {
              debugPrint(
                  '\x1B[31mModules force-fetch failed: status=${forcedResponse.statusCode}\x1B[0m');
            }
          }
        } else {
          debugPrint(
              '\x1B[31mModules API error: status=${response.statusCode} body=${response.body}\x1B[0m');
        }

      case DataSourceEnum.local:
        final String? cacheResponseData =
            await LocalClient.organize(source, cacheId, null, null);
        if (cacheResponseData != null) {
          moduleList = [];
          for (var storeCategory in (jsonDecode(cacheResponseData) as List)) {
            moduleList.add(
                ModuleModel.fromJson(storeCategory as Map<String, dynamic>));
          }
        }
    }

    return moduleList;
  }

  @override
  Future<void> setModule(ModuleModel? module) async {
    AddressModel? addressModel;
    try {
      final rawAddress = sharedPreferences.getString(AppConstants.userAddress);
      if (rawAddress != null && rawAddress.isNotEmpty) {
        addressModel = AddressModel.fromJson(
            jsonDecode(rawAddress) as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Did not get shared Preferences address . Note: $e');
    }
    apiClient.updateHeader(
      sharedPreferences.getString(AppConstants.token),
      addressModel?.zoneIds,
      addressModel?.areaIds,
      sharedPreferences.getString(AppConstants.languageCode),
      module?.id,
      addressModel?.latitude,
      addressModel?.longitude,
    );
    if (module != null) {
      await sharedPreferences.setString(
          AppConstants.moduleId, jsonEncode(module.toJson()));
    } else {
      await sharedPreferences.remove(AppConstants.moduleId);
    }
  }

  @override
  Future<ModuleModel?> setCacheModule(ModuleModel? module) async {
    if (module != null) {
      await sharedPreferences.setString(
          AppConstants.cacheModuleId, jsonEncode(module.toJson()));
      return module;
    } else {
      await sharedPreferences.remove(AppConstants.cacheModuleId);
      return null;
    }
  }

  @override
  ModuleModel? getCacheModule() {
    ModuleModel? module;
    if (sharedPreferences.containsKey(AppConstants.cacheModuleId)) {
      try {
        module = ModuleModel.fromJson(
            jsonDecode(sharedPreferences.getString(AppConstants.cacheModuleId)!)
                as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Did not get shared Preferences cache module. Note: $e');
      }
    }
    return module;
  }

  @override
  ModuleModel? getModule() {
    ModuleModel? module;
    if (sharedPreferences.containsKey(AppConstants.moduleId)) {
      try {
        module = ModuleModel.fromJson(
            jsonDecode(sharedPreferences.getString(AppConstants.moduleId)!)
                as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Did not get shared Preferences module. Note: $e');
      }
    }
    return module;
  }

  @override
  Future<ResponseModel> subscribeEmail(String email) async {
    ResponseModel responseModel;
    final Response response = await apiClient.postData(
        AppConstants.subscriptionUri, {'email': email},
        handleError: false);
    if (response.statusCode == 200) {
      responseModel = ResponseModel(true, 'subscribed_successfully'.tr);
    } else {
      responseModel = ResponseModel(false, response.statusText);
    }
    return responseModel;
  }

  @override
  bool getSavedCookiesData() {
    return sharedPreferences.getBool(AppConstants.acceptCookies)!;
  }

  @override
  Future<void> saveCookiesData(bool data) async {
    try {
      await sharedPreferences.setBool(AppConstants.acceptCookies, data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void cookiesStatusChange(String? data) {
    if (data != null) {
      sharedPreferences.setString(AppConstants.cookiesManagement, data);
    }
  }

  @override
  bool getAcceptCookiesStatus(String data) {
    return sharedPreferences.getString(AppConstants.cookiesManagement) !=
            null &&
        sharedPreferences.getString(AppConstants.cookiesManagement) == data;
  }

  @override
  bool getSuggestedLocationStatus() {
    return sharedPreferences.getBool(AppConstants.suggestedLocation)!;
  }

  @override
  Future<void> saveSuggestedLocationStatus(bool data) async {
    try {
      await sharedPreferences.setBool(AppConstants.suggestedLocation, data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  bool getReferBottomSheetStatus() {
    return sharedPreferences.getBool(AppConstants.referBottomSheet) ?? true;
  }

  @override
  Future<void> saveReferBottomSheetStatus(bool data) async {
    try {
      await sharedPreferences.setBool(AppConstants.referBottomSheet, data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
}
