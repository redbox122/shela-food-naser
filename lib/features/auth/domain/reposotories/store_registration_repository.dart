import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/auth/domain/models/store_body_model.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/store_registration_repository_interface.dart';
import 'package:sixam_mart/features/business/domain/models/package_model.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:sixam_mart/common/security/certificate_pinning.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class StoreRegistrationRepository
    implements StoreRegistrationRepositoryInterface {
  final ApiClient apiClient;
  StoreRegistrationRepository({required this.apiClient});

  @override
  Future<Response> registerStore(
      StoreBodyModel store, XFile? logo, XFile? cover) async {
    if (apiClient.token == null || apiClient.token!.isEmpty) {
      if (kDebugMode) {
        appLogger.warning('⚠️ لا يوجد توكن.');
      }
      showCustomSnackBar('الرجاء تسجيل الدخول أولاً');
      return const Response(
          statusCode: 401, statusText: 'Unauthorized: Missing token');
    }

    final url = AppConstants.baseUrl + AppConstants.storeRegisterUri;
    final formData = dio_pkg.FormData();
    formData.fields.addAll([
      MapEntry('f_name', store.fName!),
      MapEntry('l_name', store.lName!),
      MapEntry('latitude', store.lat!),
      MapEntry('longitude', store.lng!),
      MapEntry('email', store.email!),
      MapEntry('phone', store.phone!),
      MapEntry('minimum_delivery_time', store.minDeliveryTime!),
      MapEntry('maximum_delivery_time', store.maxDeliveryTime!),
      MapEntry('delivery_time_type', store.deliveryTimeType!),
      MapEntry('password', store.password!),
      MapEntry('zone_id', store.zoneId!),
      MapEntry('module_id', store.moduleId!),
      MapEntry('tax', store.tax!),
      MapEntry('tax_cal', 'percent'),
      MapEntry('translations', store.translation!),
    ]);
    if (kDebugMode) {
      final maskedPhone = store.phone != null && store.phone!.length > 4
          ? '${store.phone!.substring(0, 4)}***'
          : store.phone;
      appLogger.info('[StoreRegistration] Request payload:');
      appLogger.info('  - zone_id: ${store.zoneId}');
      appLogger.info('  - module_id: ${store.moduleId}');
      appLogger.info('  - lat/lng: ${store.lat}, ${store.lng}');
      appLogger.info('  - email: ${store.email}');
      appLogger.info('  - phone: $maskedPhone');
      appLogger.info('  - min/max delivery: ${store.minDeliveryTime}/${store.maxDeliveryTime}');
      appLogger.info('  - delivery_time_type: ${store.deliveryTimeType}');
      appLogger.info('  - has_logo: ${logo != null}, has_cover: ${cover != null}');
    }

    if (logo != null) {
      formData.files.add(MapEntry(
        'logo',
        await dio_pkg.MultipartFile.fromFile(logo.path),
      ));
    }
    if (cover != null) {
      formData.files.add(MapEntry(
        'cover_photo',
        await dio_pkg.MultipartFile.fromFile(cover.path),
      ));
    }

    try {
      final dio = dio_pkg.Dio();
      CertificatePinning.apply(dio);
      final dioResponse = await dio.post<dynamic>(
        url,
        data: formData,
        options: dio_pkg.Options(
          headers: {
            'Accept': 'application/json',
            'X-localization': 'en',
            'Authorization': 'Bearer ${apiClient.token}',
          },
          validateStatus: (s) => s != null,
        ),
      );

      if (kDebugMode) {
        appLogger.info('[StoreRegistration] Response status=${dioResponse.statusCode}');
      }
      if (kDebugMode && AppConstants.enableVerboseLogs) {
        appLogger.debug('📩 Response: ${dioResponse.data}');
      }

      final Map<String, dynamic> jsonResponse =
          (dioResponse.data is Map<String, dynamic>)
              ? dioResponse.data as Map<String, dynamic>
              : {};
      final bool hasErrors = jsonResponse['errors'] is List &&
          (jsonResponse['errors'] as List).isNotEmpty;

      debugPrint('\x1B[32m  /${dioResponse.statusCode}   \x1B[0m');

      if ((dioResponse.statusCode == 200 || dioResponse.statusCode == 201) &&
          !hasErrors) {
        Get.back();
        showCustomSnackBar('✅ تم إرسال الطلب بنجاح', isError: false);
      } else if (dioResponse.statusCode == 500) {
        final String message = jsonResponse['message']?.toString().trim() ?? '';
        if (message.isNotEmpty) {
          showCustomSnackBar(message);
        } else {
          showCustomSnackBar('حدث خطأ داخلي من الخادم، الرجاء المحاولة لاحقًا');
        }
      } else if (jsonResponse.containsKey('message') &&
          jsonResponse['message'].toString().contains('Duplicate entry')) {
        showCustomSnackBar('  رقم الهاتف او البريد الاكتروني تم الحفظ مسبقا ');
      } else if (jsonResponse.containsKey('errors')) {
        // عرض كل الأخطاء بالعربية
        String errorMessages = '';
        for (var error in (jsonResponse['errors'] as List)) {
          switch (error['code']) {
            case 'phone':
              errorMessages += '📞 رقم الجوال مستخدم مسبقاً.\n';
              break;
            case 'password':
              final dynamic backendMessage = error['message'];
              final String passwordMessage =
                  backendMessage?.toString().trim().isNotEmpty == true
                      ? backendMessage.toString().trim()
                      : '🔐 كلمة المرور غير مقبولة من النظام. الرجاء استخدام كلمة مرور مختلفة.';
              errorMessages += '$passwordMessage\n';
              break;
            case 'tax_cal':
              errorMessages +=
                  '💰 يرجى تحديد نوع الضريبة (نسبة أو قيمة ثابتة).\n';
              break;
            case 'latitude':
              errorMessages += '📍 الموقع خارج النطاق المسموح به.\n';
              break;
            default:
              errorMessages += '⚠️ ${error['message']}\n';
          }
        }
        final String userMessage = errorMessages.trim();
        if (userMessage.isNotEmpty) {
          showCustomSnackBar(userMessage);
        } else {
          showCustomSnackBar('قم بمراجعه البيانات ');
        }

        debugPrint(
            '\x1B[32m  / ${dioResponse.statusCode}    ${errorMessages.trim()}  \x1B[0m');
      } else if (jsonResponse.containsKey('message')) {
        // في حال كان الرد يحتوي فقط على رسالة عامة
        final String message = jsonResponse['message']?.toString() ?? '';
        if (message.isNotEmpty) {
          showCustomSnackBar(message);
        } else {
          showCustomSnackBar('قم بمراجعه البيانات ');
        }
        debugPrint('\x1B[32m  ////////////  \x1B[0m');
      }

      return Response(
        body: jsonResponse,
        statusCode: dioResponse.statusCode,
        statusText: dioResponse.statusMessage,
      );
    } catch (e) {
      showCustomSnackBar('❌ حدث خطأ أثناء الاتصال بالخادم');
      if (kDebugMode) {
        appLogger.error('❌ Exception occurred: $e', e);
      }
      return const Response(statusCode: 500, statusText: 'Server Error');
    }
  }

  @override
  Future<bool> checkInZone(String? lat, String? lng, int zoneId) async {
    final Response response = await apiClient.getData(
        '${AppConstants.checkZoneUri}?lat=$lat&lng=$lng&zone_id=$zoneId');

    if (response.statusCode == 200) {
      try {
        final data = response.body;
        // The API returns a boolean directly, not a JSON object
        if (data is bool) {
          return data;
        }
        // Fallback for JSON object format
        if (data is Map<String, dynamic>) {
          return data['in_zone'] as bool? ?? false;
        }
        return false;
      } catch (e) {
        debugPrint('❌ checkInZone error: $e');
        return false;
      }
    } else {
      return false;
    }
  }

  @override
  Future<PackageModel?> getPackageList({int? moduleId}) async {
    PackageModel? packageModel;
    final Response response = await apiClient
        .getData('${AppConstants.storePackagesUri}?module_id=$moduleId');
    if (response.statusCode == 200) {
      packageModel = PackageModel.fromJson(response.body as Map<String, dynamic>);
    }
    return packageModel;
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
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) {
    throw UnimplementedError();
  }
}
