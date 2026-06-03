// ignore_for_file: file_names, non_constant_identifier_names, use_build_context_synchronously, depend_on_referenced_packages, annotate_overrides, unused_local_variable, empty_catches

import 'package:flutter/material.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:path/path.dart' as p;
import 'package:sixam_mart/common/security/certificate_pinning.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/features/add_delegate/domain/models/delegate_api_model.dart';
import 'package:sixam_mart/features/add_delegate/domain/reposotories/delegate_repository_interface.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/NamedFile.dart';
import 'package:sixam_mart/util/app_constants.dart';

class DelegateRepository implements DelegateRepositoryInterface {
  final ApiClient apiClient;

  DelegateRepository({required this.apiClient});

  @override
  Future<DelegateModel?> getDelegate() async {
    if (apiClient.token == null || apiClient.token!.isEmpty) {
      debugPrint('⚠️ لا يوجد توكن. لن يتم تنفيذ طلب المندوب.');
      return null;
    }

    DelegateModel? delegateModel;

    final url = AppConstants.baseUrl + AppConstants.get_delegateUri;

    try {
      final dio = dio_pkg.Dio();
      CertificatePinning.apply(dio);
      final dioResponse = await dio.get<dynamic>(
        url,
        options: dio_pkg.Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer ${apiClient.token}',
          },
          validateStatus: (s) => s != null,
        ),
      );

      if (dioResponse.statusCode == 200) {
        final Map<String, dynamic> decoded =
            dioResponse.data is Map<String, dynamic>
                ? dioResponse.data as Map<String, dynamic>
                : {};
        delegateModel = DelegateModel.fromJson(decoded);
        debugPrint('✅ مندوب: ${dioResponse.data}');
        return delegateModel;
      } else if (dioResponse.statusCode == 404) {
        return null;
      } else {
        debugPrint('❌ فشل في استرجاع بيانات المندوب. كود: ${dioResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ خطأ أثناء استرجاع بيانات المندوب: $e');
    }

    return delegateModel;
  }

  @override
  Future<bool> send_Delegate(
    BuildContext context,
    int id,
    String f_name,
    String L_name,
    String mobile,
    List<NamedFile> list_img,
  ) async {
    if (apiClient.token == null || apiClient.token!.isEmpty) {
      debugPrint('⚠️ لا يوجد توكن.');
      return false;
    }

    final url = AppConstants.baseUrl + AppConstants.send_delegateUri;
    final formData = dio_pkg.FormData();

    formData.fields.addAll([
      MapEntry('user_id', id.toString()),
      MapEntry('f_name', f_name),
      MapEntry('l_name', L_name),
      MapEntry('mobile', mobile),
    ]);

    if (list_img.isNotEmpty) {
      final file = list_img.first.file;
      final String? path = file.path;

      if (path != null && path.isNotEmpty) {
        formData.files.add(MapEntry(
          'id_photo',
          await dio_pkg.MultipartFile.fromFile(path),
        ));
      } else if (file.bytes != null) {
        formData.files.add(MapEntry(
          'id_photo',
          dio_pkg.MultipartFile.fromBytes(file.bytes!, filename: file.name),
        ));
      } else {
        showCustomSnackBar('تعذر قراءة الملف المرفق. اختر ملفًا آخر.');
        return false;
      }

      formData.fields.add(MapEntry('id_photo_name', p.basename(file.name)));
    } else {
      showCustomSnackBar('الرجاء إرفاق صورة الهوية');
      return false;
    }

    final dio = dio_pkg.Dio();
    CertificatePinning.apply(dio);
    final dioResponse = await dio.post<dynamic>(
      url,
      data: formData,
      options: dio_pkg.Options(
        headers: {
          'Accept': 'application/json',
          'X-localization': 'ar',
          'Authorization': 'Bearer ${apiClient.token}',
        },
        validateStatus: (s) => s != null,
      ),
    );

    if (dioResponse.statusCode == 200 || dioResponse.statusCode == 201) {
      debugPrint('✅ تم الإرسال بنجاح');
      showCustomSnackBar('تم الإرسال بنجاح', isError: false);
      return true;
    }

    debugPrint('❌ فشل في الإرسال: ${dioResponse.statusCode}');
    debugPrint('${dioResponse.data}');

    if (dioResponse.statusCode == 404) {
      showCustomSnackBar('الخدمة غير متاحة حالياً: مسار إرسال المندوب غير موجود على الخادم (404).');
      return false;
    }

    try {
      final decoded = dioResponse.data;
      if (decoded is Map && decoded.containsKey('message')) {
        showCustomSnackBar(decoded['message'].toString());
      } else if (decoded is Map && decoded.containsKey('errors')) {
        showCustomSnackBar(decoded['errors'].toString());
      } else {
        showCustomSnackBar('فشل في الإرسال، حاول مرة أخرى في وقت لاحق');
      }
    } catch (e) {
      debugPrint('❌ خطأ في فك الرد: $e');
      showCustomSnackBar('فشل في الإرسال، حاول مرة أخرى في وقت لاحق');
    }

    return false;
  }
}
