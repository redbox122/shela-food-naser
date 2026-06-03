import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio_pkg;
import 'package:sixam_mart/common/security/certificate_pinning.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
// import 'package:sixam_mart/common/widgets/dialog/wallet_dialog.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/NamedFile.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/contract_pdf_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/kaidhaSub_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/nafath_checkStatus_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/nafath_random_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/response_api_model.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/models/wallet_kaidha_model.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/features/wallet_kaidha_subscription/domain/reposotories/kaidhaSub_repository_interface.dart';
// import 'package:sixam_mart/features/wallet_kaidha_subscription/widget/dialog.dart/success_dialog.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/common/exceptions/validation_exception.dart';

class KaidhaSubRepository implements KaidhaSubRepositoryInterface {
  final ApiClient apiClient;
  dio_pkg.MultipartFile? signatureFile;

  KaidhaSubRepository({required this.apiClient, this.signatureFile});

  bool _isSuccessBody(dynamic body) {
    return body is Map<String, dynamic> && body['success'] == true;
  }

  String _extractMessage(dynamic body, String fallback) {
    if (body is Map<String, dynamic>) {
      return body['message']?.toString() ?? fallback;
    }
    return fallback;
  }

  Future<Map<String, dynamic>?> _buildNafathBody(String nationalId) async {
    final Map<String, dynamic> payload = {'national_id': nationalId};
    int? userId;

    if (Get.isRegistered<ProfileController>()) {
      final ProfileController profileController = Get.find<ProfileController>();
      userId = profileController.userInfoModel?.id;
      if (userId == null) {
        try {
          await profileController.getUserInfo();
          userId = profileController.userInfoModel?.id;
        } catch (e) {
          if (kDebugMode) debugPrint('$e');
        }
      }
    }

    if (userId != null) {
      payload['user_id'] = userId;
    }

    final bool hasToken =
        apiClient.token != null && apiClient.token!.isNotEmpty;
    if (!hasToken && userId == null) {
      showCustomSnackBar('لا يمكن تنفيذ طلب نفاذ بدون user_id عند غياب التوكن');
      return null;
    }

    return payload;
  }

  // -----------------------------
  @override
  Future<bool> Stor_info(
      context, KaidhaSubModel kaidhaSub, List<NamedFile> list_img,
      {bool isUpdate = false, String? walletId}) async {
    if (apiClient.token == null || apiClient.token!.isEmpty) {
      debugPrint('⚠️ لا يوجد توكن.  ');
      return false;
    }

    final url = AppConstants.baseUrl + AppConstants.store_qidhaUri;
    final formData = dio_pkg.FormData();

    debugPrint('📤 Sending fields to server:');
    kaidhaSub.toJson().forEach((key, value) {
      formData.fields.add(MapEntry(key, value.toString()));
      debugPrint('   $key: $value');
    });
    debugPrint('?? Final request fields: ${formData.fields}');

    if (list_img.isNotEmpty) {
      debugPrint('📁 Sending files:');
      for (final file in list_img) {
        if (file.file.path != null && file.file.path!.isNotEmpty) {
          debugPrint('   - ${file.name}: ${file.file.path}');
          formData.files.add(MapEntry(
            'attachments[]',
            await dio_pkg.MultipartFile.fromFile(file.file.path!),
          ));
        }
      }
    } else {
      debugPrint('❌ لا توجد ملفات مرفقة');
    }

    // ==========================================

    final dio = dio_pkg.Dio();
    CertificatePinning.apply(dio);
    final dioResponse = await dio.post<dynamic>(
      url,
      data: formData,
      options: dio_pkg.Options(
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${apiClient.token}',
        },
        validateStatus: (s) => s != null,
      ),
    );

    debugPrint('\x1B[32m   Stor_info:   ${dioResponse.statusCode}  \x1B[0m');
    debugPrint('📋 Response Body: ${dioResponse.data}');
    debugPrint('📋 Response Headers: ${dioResponse.headers}');

    if (dioResponse.statusCode == 200 || dioResponse.statusCode == 201) {
      final Map<String, dynamic> decodedJson =
          dioResponse.data is Map<String, dynamic>
              ? dioResponse.data as Map<String, dynamic>
              : {};
      final ResponseApiIncomeSourceModel model =
          ResponseApiIncomeSourceModel.fromJson(decodedJson);

      debugPrint('✅ تم الإرسال بنجاح: ${model.message}');
      // Suppress modal dialog to avoid interrupting flow; navigation handled in controller

      return true;
    } else {
      debugPrint('❌ Server error: ${dioResponse.statusCode}');
      debugPrint('📋 Error response body: ${dioResponse.data}');

      try {
        final Map<String, dynamic> decodedJson =
            dioResponse.data is Map<String, dynamic>
                ? dioResponse.data as Map<String, dynamic>
                : {};

        if (dioResponse.statusCode == 422 && decodedJson['errors'] is List) {
          final List<dynamic> errors = decodedJson['errors'] as List<dynamic>;
          final Map<String, String> fieldErrors = {};
          for (final item in errors) {
            if (item is Map<String, dynamic>) {
              final field = item['field']?.toString();
              final message = item['message']?.toString();
              if (field != null &&
                  field.isNotEmpty &&
                  message != null &&
                  message.isNotEmpty) {
                fieldErrors[field] = message;
              }
            }
          }
          if (fieldErrors.isNotEmpty) {
            debugPrint(
                '[QIDHA_WALLET_422_ERROR_PARSED] fields=${fieldErrors.keys.join(',')}');
            throw ValidationException(fieldErrors);
          }
        }

        final ResponseApiIncomeSourceModel model =
            ResponseApiIncomeSourceModel.fromJson(decodedJson);

        if (model.errors != null) {
          String firstError = '';

          if (model.errors?.firstName != null &&
              model.errors!.firstName!.isNotEmpty) {
            firstError = 'حقل الاسم الأول مطلوب';
          } else if (model.errors?.grandfatherName != null &&
              model.errors!.grandfatherName!.isNotEmpty) {
            firstError = 'حقل اسم الجد مطلوب';
          } else if (model.errors?.fatherName != null &&
              model.errors!.fatherName!.isNotEmpty) {
            firstError = 'حقل اسم الأب مطلوب';
          } else if (model.errors?.lastName != null &&
              model.errors!.lastName!.isNotEmpty) {
            firstError = 'حقل اسم العائلة مطلوب';
          } else if (model.errors?.birthDate != null &&
              model.errors!.birthDate!.isNotEmpty) {
            firstError = 'حقل تاريخ الميلاد مطلوب';
          } else if (model.errors?.nationalId != null &&
              model.errors!.nationalId!.isNotEmpty) {
            firstError = 'لديك حساب قيدها بالفعل';
          } else if (model.errors?.maritalStatus != null &&
              model.errors!.maritalStatus!.isNotEmpty) {
            firstError = 'حقل الحالة الاجتماعية مطلوب';
            //   } else if (model.errors?.numberOfFamilyMembers != null && model.errors!.numberOfFamilyMembers!.isNotEmpty) {
            //   firstError = 'حقل عدد أفراد الأسرة مطلوب';
          } else if (model.errors?.identityCardNumber != null &&
              model.errors!.identityCardNumber!.isNotEmpty) {
            firstError = 'لديك حساب قيدها بالفعل';
          } else if (model.errors?.endDate != null &&
              model.errors!.endDate!.isNotEmpty) {
            firstError = 'حقل تاريخ انتهاء البطاقة مطلوب';
          } else if (model.errors?.mobile != null &&
              model.errors!.mobile!.isNotEmpty) {
            firstError = 'حقل رقم الهاتف مطلوب';
          } else if (model.errors?.houseType != null &&
              model.errors!.houseType!.isNotEmpty) {
            firstError = 'حقل نوع المنزل مطلوب';
          } else if (model.errors?.city != null &&
              model.errors!.city!.isNotEmpty) {
            firstError = 'حقل المدينة مطلوب';
          } else if (model.errors?.neighborhood != null &&
              model.errors!.neighborhood!.isNotEmpty) {
            firstError = 'حقل الحي مطلوب';
          } else if (model.errors?.nameOfEmployer != null &&
              model.errors!.nameOfEmployer!.isNotEmpty) {
            firstError = 'حقل اسم صاحب العمل مطلوب';
          } else if (model.errors?.totalSalary != null &&
              model.errors!.totalSalary!.isNotEmpty) {
            firstError = 'حقل الراتب الإجمالي مطلوب';
          } else if (model.errors?.installments != null &&
              model.errors!.installments!.isNotEmpty) {
            firstError = 'حقل الأقساط مطلوب';
          } else {
            firstError = 'حدث خطأ غير معروف';
          }
          showCustomSnackBar(firstError);
          return false;
        } else {
          showCustomSnackBar('الرجاء أعد المحاوله في وقت أخر');
          return false;
        }
      } catch (e) {
        debugPrint('❌ Error parsing server response: $e');
        debugPrint('📋 Raw response: ${dioResponse.data}');
        showCustomSnackBar('خطأ في استجابة الخادم: ${dioResponse.statusCode}');
        return false;
      }
    }
  }

  // ---
  WalletKaidhaModel? _walletKaidhaCache;

  @override
  Future<WalletKaidhaModel?> getWalletKaidh({bool forceRefresh = false}) async {
    if (apiClient.token == null || apiClient.token!.isEmpty) {
      debugPrint('⚠️ لا يوجد توكن. لن يتم تنفيذ طلب المحفظة.');
      return null;
    }

    try {
      final Response<dynamic> response = await apiClient.getData(
        AppConstants.get_walletUri,
        useEtag: !forceRefresh, // forceRefresh=true bypasses ETag cache
      );

      // 🔧 DEBUG: Log raw response body if size < 100 bytes
      String rawResponseBody = '';
      int responseBodySize = 0;

      if (response.body != null) {
        // Convert response body to JSON string
        if (response.body is Map) {
          rawResponseBody = jsonEncode(response.body);
        } else if (response.body is String) {
          rawResponseBody = response.body as String;
        } else {
          rawResponseBody = response.body.toString();
        }

        // Get byte size of the response body
        responseBodySize = utf8.encode(rawResponseBody).length;

        // If response size is < 100 bytes, print the entire raw response body
        if (responseBodySize < 100) {
          debugPrint(
              '🔍 [53-BYTE DEBUG] Response size: $responseBodySize bytes');
          debugPrint('🔍 [53-BYTE DEBUG] Status Code: ${response.statusCode}');
          debugPrint(
              '🔍 [53-BYTE DEBUG] Raw Response Body (exact JSON string):');
          debugPrint(
              '═══════════════════════════════════════════════════════════');
          debugPrint(rawResponseBody);
          debugPrint(
              '═══════════════════════════════════════════════════════════');
          debugPrint(
              '🔍 [53-BYTE DEBUG] Response body type: ${response.body.runtimeType}');
        }
      }

      // ⚡ TASK 1: Nuclear ETag Purge - Handle 304 Loop Detection
      Response<dynamic>? responseToProcess = response;
      if (response.statusCode == 304) {
        if (kDebugMode) {
          debugPrint(
              '✅ Wallet Repository: 304 Not Modified - checking cache integrity');
        }

        // ⚡ TASK 1: 304 Loop Detection - If cache is null, we're in a loop
        if (_walletKaidhaCache == null) {
          // 🚨 CRITICAL: 304 Loop detected - cache is empty but server says unchanged
          if (kDebugMode) {
            appLogger.warning(
                '🚨 [CRITICAL] 304 Loop detected. Purging ETag for Qidha Wallet.');
          }

          // Nuclear option: Clear ETag and force fresh request with cache-busting headers
          await apiClient.clearEtag(AppConstants.get_walletUri);

          // Force fresh request with cache-busting headers
          responseToProcess = await apiClient.getData(
            AppConstants.get_walletUri,
            useEtag: false,
            headers: {
              'Cache-Control': 'no-cache',
              'If-None-Match': '', // Empty to bypass ETag check
            },
          );

          // If still 304 after purge, something is very wrong - return null to force retry
          if (responseToProcess.statusCode == 304) {
            if (kDebugMode) {
              appLogger.error(
                  '🚨 [CRITICAL] Still getting 304 after ETag purge - server issue');
            }
            return null;
          }
        } else {
          // Cache exists - check if it's skeleton data
          final cachedWallet = _walletKaidhaCache!.wallet;
          final hasUsedBalance = cachedWallet?.usedBalance != null &&
              cachedWallet!.usedBalance.toString().trim().isNotEmpty &&
              (cachedWallet.usedBalance is num ||
                  double.tryParse(cachedWallet.usedBalance.toString()) != null);
          final hasMinimumDueLimit = cachedWallet?.minimumDueLimit != null &&
              cachedWallet!.minimumDueLimit.toString().trim().isNotEmpty &&
              (cachedWallet.minimumDueLimit is num ||
                  double.tryParse(cachedWallet.minimumDueLimit.toString()) !=
                      null);

          // If skeleton data detected (missing critical fields), purge ETag and force 200 OK
          if (!hasUsedBalance || !hasMinimumDueLimit) {
            if (kDebugMode) {
              appLogger.warning(
                  '🚨 POISONED CACHE DETECTED: Cache missing used_balance or minimum_due_limit. Purging ETag...');
            }

            // Clear ETag to force fresh request
            await apiClient.clearEtag(AppConstants.get_walletUri);

            // Force a 200 OK retry with cache-busting headers
            if (kDebugMode) {
              debugPrint(
                  '🔄 Wallet Repository: Retrying with force refresh after cache purge');
            }
            responseToProcess = await apiClient.getData(
              AppConstants.get_walletUri,
              useEtag: false,
              headers: {
                'Cache-Control': 'no-cache',
                'If-None-Match': '',
              },
            );

            // If retry also fails, return null to force controller retry
            if (responseToProcess.statusCode != 200 &&
                responseToProcess.statusCode != 201) {
              if (kDebugMode) {
                debugPrint(
                    '⚠️ Wallet Repository: Retry after cache purge failed - returning null');
              }
              return null;
            }
          } else {
            // Cache is valid - return it
            if (kDebugMode) {
              appLogger.info('✅ Wallet Cache Validated | Full Data Present');
            }
            return _walletKaidhaCache;
          }
        }
      }

      if ((responseToProcess.statusCode == 200 ||
              responseToProcess.statusCode == 201) &&
          responseToProcess.body != null) {
        if (!_isSuccessBody(responseToProcess.body)) {
          final String message = _extractMessage(
            responseToProcess.body,
            'فشل استرجاع بيانات المحفظة',
          );
          showCustomSnackBar(message);
          return null;
        }

        // 🔧 FIX: Access response.data instead of response.body directly
        // Backend returns: { "success": true, "data": { "id": ..., "available_balance": ..., "status": ... } }
        final Map<String, dynamic> responseData =
            responseToProcess.body as Map<String, dynamic>;

        // New unified response: { data: { id, signature_status, has_wallet, ... } }
        // Always prefer the data map; do not rely on old wallet paths.
        Map<String, dynamic> walletData;
        if (responseData.containsKey('data') && responseData['data'] is Map) {
          walletData = responseData['data'] as Map<String, dynamic>;
        } else {
          walletData = responseData;
        }

        // Always log critical fields so signatureStatus issues can be debugged.
        debugPrint(
            '[Qidha][WALLET-RAW] statusCode=${responseToProcess.statusCode}'
            ' hasWallet=${walletData['has_wallet']}'
            ' userId=${walletData['user_id']}'
            ' walletStatus=${walletData['status']}'
            ' signatureStatus=${walletData['signature_status']}'
            ' signaturePath=${walletData['signature_path']}'
            ' availableBalance=${walletData['available_balance']}'
            ' creditLimit=${walletData['credit_limit']}');

        final dynamic hasWalletValue = walletData['has_wallet'];
        if (hasWalletValue == false) {
          if (kDebugMode) {
            debugPrint(
                'ℹ️ Wallet Repository: has_wallet=false - user has no wallet');
          }
          return null;
        }

        // Create wallet object with correct field names
        final Map<String, dynamic> walletJson = {
          'id': walletData['id'],
          'serial_number': walletData['serial_number'],
          'user_id': walletData['user_id'],
          'created_at': walletData['created_at'],
          'updated_at': walletData['updated_at'],
          'completed_at': walletData['completed_at'],
          'completed_by': walletData['completed_by'],
          'credit_limit': walletData['credit_limit'],
          'minimum_due':
              walletData['minimum_due'] ?? walletData['minimum_due_amount'],
          'available_balance': walletData['available_balance'], // Not "balance"
          'used_balance': walletData['used_balance'],
          'usage_percentage_limit': walletData['usage_percentage_limit'],
          'status': walletData['status'], // "Pending"/"Active", not "active"
          'auto_lock_day': walletData['auto_lock_day'],
          'manual_unlock_expiry_date': walletData['manual_unlock_expiry_date'],
          'usage_percentage_limit_by_monthly':
              walletData['usage_percentage_limit_by_monthly'],
          'signature_path': walletData['signature_path'],
          'signature_status': walletData['signature_status'],
          'lock_day': walletData['lock_day'],
          'minimum_due_limit': walletData['minimum_due_limit'],
          'purchase_limit': walletData['purchase_limit'],
          'used_percentage': walletData['used_percentage'],
          'total_avilable_balance': walletData['total_avilable_balance'],
        };

        final Map<String, dynamic> modelJson = {
          'message': responseData['message'] ?? 'Wallet retrieved successfully',
          'wallet': walletJson,
        };

        _walletKaidhaCache = WalletKaidhaModel.fromJson(modelJson);
        debugPrint('✅ محفظه قيدها: ${_walletKaidhaCache!.wallet?.status}');
        return _walletKaidhaCache;
      } else {
        // 🔧 FIX: Throw exception for 401/500 errors so controller can handle them
        if (response.statusCode == 401 || response.statusCode == 500) {
          debugPrint('❌ فشل استرجاع المحفظة: كود ${response.statusCode}');
          throw Exception('Wallet API error: ${response.statusCode}');
        }
        // 404 means user has no wallet (valid case - not an error)
        if (response.statusCode == 404) {
          if (kDebugMode) {
            debugPrint('ℹ️ Wallet Repository: 404 - user has no wallet');
          }
          return null;
        }
        if (kDebugMode) {
          debugPrint('❌ فشل استرجاع المحفظة: كود ${response.statusCode}');
        }
      }
    } catch (e) {
      debugPrint('❌ استثناء أثناء استرجاع المحفظة: $e');
      // Re-throw if it's a 401/500 error, otherwise return null
      if (e.toString().contains('401') || e.toString().contains('500')) {
        rethrow;
      }
    }

    return null;
  }

  // get_Pdf  ==========================================================================================================

  @override
  Future<ContractPdfModel> get_Pdf() async {
    //

    ContractPdfModel? Pdf_Model;

    final headers = {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${apiClient.token}'
    };

    try {
      // First, get wallet status to determine which PDF endpoint to use
      final WalletKaidhaModel? walletData = await getWalletKaidh();
      String pdfEndpoint =
          '/api/qidha-wallet/contract-pdf'; // Default to unsigned contract

      if (walletData?.wallet != null) {
        // Debug: Print wallet signature details
        debugPrint('🔍 Wallet Debug Info:');
        debugPrint(
            '   - signatureStatus: ${walletData!.wallet!.signatureStatus}');
        debugPrint('   - signaturePath: ${walletData.wallet!.signaturePath}');
        debugPrint(
            '   - signaturePath type: ${walletData.wallet!.signaturePath.runtimeType}');
        debugPrint(
            '   - signaturePath isEmpty: ${walletData.wallet!.signaturePath.toString().isEmpty}');

        // Check if contract is signed
        if (walletData.wallet!.signatureStatus == 1 &&
            walletData.wallet!.signaturePath != null &&
            walletData.wallet!.signaturePath.toString().isNotEmpty) {
          pdfEndpoint =
              '/api/qidha-wallet/signed-pdf'; // Use signed contract endpoint
          debugPrint('📄 العقد موثق - سيتم جلب العقد الموقع (6 صفحات)');
        } else {
          debugPrint('📄 العقد غير موثق - سيتم جلب العقد العادي (5 صفحات)');
          debugPrint(
              '   - Reason: signatureStatus=${walletData.wallet!.signatureStatus}, signaturePath=${walletData.wallet!.signaturePath}');
        }
      } else {
        debugPrint(
            '⚠️ لم يتم العثور على بيانات المحفظة - سيتم جلب العقد العادي');
      }

      debugPrint('📤 جاري جلب عقد PDF من الخادم... ($pdfEndpoint)');

      final dioPdf = dio_pkg.Dio();
      CertificatePinning.apply(dioPdf);
      final pdfResponse = await dioPdf.get<List<int>>(
        '${AppConstants.baseUrl}$pdfEndpoint',
        options: dio_pkg.Options(
          headers: headers,
          responseType: dio_pkg.ResponseType.bytes,
          validateStatus: (s) => s != null,
        ),
      );

      if (pdfResponse.statusCode == 200 || pdfResponse.statusCode == 201) {
        final bytes = pdfResponse.data ?? <int>[];

        if (bytes.isEmpty) {
          debugPrint('⚠️ تم استلام ملف فارغ');
          throw Exception('Empty PDF response body');
        }

        final dir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final filePath = '${dir.path}/contract_$timestamp.pdf';

        await File(filePath).writeAsBytes(bytes);

        debugPrint('✅ تم تنزيل العقد (${bytes.length} بايت)');
        debugPrint('📁 المسار: $filePath');
        debugPrint('🔗 النقطة المستخدمة: $pdfEndpoint');
        Pdf_Model =
            ContractPdfModel(filePath: filePath, fileSize: bytes.length);

        return Pdf_Model;
      } else {
        debugPrint('❌ فشل التنزيل - الرمز: ${pdfResponse.statusCode}');
        debugPrint('🔗 النقطة المستخدمة: $pdfEndpoint');
        throw Exception(
            'Failed to download PDF. Status: ${pdfResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ حدث خطأ غير متوقع أثناء تحميل PDF');
      debugPrint('🔍 التفاصيل: $e');
      rethrow;
    }
  }

  // ---

  // Credit شحن الرصيد ================================================================================================

  @override
  Future<Response<dynamic>> send_Pay_credit(context, double total) async {
    final Map<String, dynamic> data = {
      'amount': total,
    };

    final Response<dynamic> response =
        await apiClient.postData(AppConstants.pay_creditUri, data);

    if (response.statusCode == 200 || response.statusCode == 201) {
      getWalletKaidh();

      final Map<String, dynamic>? bodyMap =
          response.body as Map<String, dynamic>?;
      showCustomSnackBar("${bodyMap?["message"]}", isError: false);
    } else {
      showCustomSnackBar('فشل شحن المبلغ');
    }

    return response;
  }

  //  شراء  debi  =====================================================================================================

  @override
  Future<bool> send_Pay_debit(context, double total, {String? orderId}) async {
    final Map<String, dynamic> data = {
      'amount': total,
    };

    // Add order_id if provided (required for Qidha wallet debit)
    if (orderId != null) {
      data['order_id'] = orderId;
    }

    final Response<dynamic> response =
        await apiClient.postData(AppConstants.pay_debitUri, data);

    if (response.statusCode == 200 || response.statusCode == 201) {
      getWalletKaidh();
      return true;
    } else if (response.statusCode == 429) {
      //

      return false;
    } else {
      showCustomSnackBar('فشل الشراء ');
      return false;
    }
  }

  //
  // ==============

  // Nafath    ================================================================================================

  @override
  Future<NafathCheckStatusModel?> Nafath_send_checkStatus(
      BuildContext context, String nationalId) async {
    final Map<String, dynamic>? data = await _buildNafathBody(nationalId);
    if (data == null) return null;

    try {
      final Response<dynamic> response = await apiClient.postData(
        AppConstants.nafath_checkStatusUri,
        data,
        headers: const {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'If-None-Match': '',
        },
      );
      if (kDebugMode) {
        debugPrint(
            '?? Nafath checkStatus POST -> ${apiClient.appBaseUrl}${AppConstants.nafath_checkStatusUri}');
      }
      final dynamic body = response.body;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          body != null &&
          _isSuccessBody(body)) {
        return NafathCheckStatusModel.fromJson(body as Map<String, dynamic>);
      }

      showCustomSnackBar(
        _extractMessage(body, 'حدث خطأ أثناء التحقق من نافذ'),
      );
      return null;
    } catch (e) {
      debugPrint('? Nafath checkStatus failed: $e');
      return null;
    }
  }
  // send National Id   =========================

  @override
  Future<NafathRandomModel?> Nafath_send_National_Id(
      BuildContext context, String nationalId) async {
    NafathRandomModel model = NafathRandomModel();

    try {
      if (nationalId.length != 10 ||
          // ignore: deprecated_member_use
          !RegExp(r'^\d{10}$').hasMatch(nationalId)) {
        showCustomSnackBar('رقم الهوية غير صالح');
        return null;
      }

      final Map<String, dynamic>? data = await _buildNafathBody(nationalId);
      if (data == null) {
        return null;
      }
      final Response<dynamic> response = await apiClient.postData(
        AppConstants.nafath_initiateUri,
        data,
        headers: const {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'If-None-Match': '',
        },
      );
      if (kDebugMode) {
        debugPrint(
            '📡 Nafath initiate POST -> ${apiClient.appBaseUrl}${AppConstants.nafath_initiateUri}');
      }
      debugPrint('${response.body}');
      debugPrint('${response.request?.url}');
      final dynamic body = response.body;
      final bool isSuccess =
          body is Map<String, dynamic> && body['success'] == true;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          isSuccess) {
        final Map<String, dynamic> payload =
            body['data'] as Map<String, dynamic>;
        model = NafathRandomModel.fromJson(payload);
        return model;
      } else {
        final String message = body is Map<String, dynamic>
            ? (body['message']?.toString() ?? 'فشل إرسال رقم الهوية')
            : 'فشل إرسال رقم الهوية';
        showCustomSnackBar(message);
        debugPrint('❌ فشل إرسال رقم الهوية: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('❌ خطأ في إرسال رقم الهوية: $e');
      return null;
    }
  }

  @override
  Future<Response<dynamic>> Nafath_send_cancel(
      BuildContext context, String nationalId) async {
    final Map<String, dynamic>? data = await _buildNafathBody(nationalId);
    if (data == null) {
      return Response(statusCode: 400, statusText: 'Missing user_id');
    }

    try {
      final Response<dynamic> response = await apiClient.postData(
        AppConstants.nafath_cancelUri,
        data,
        headers: const {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'If-None-Match': '',
        },
      );
      if (kDebugMode) {
        debugPrint(
            '📡 Nafath cancel POST -> ${apiClient.appBaseUrl}${AppConstants.nafath_cancelUri}');
      }

      final dynamic body = response.body;
      final bool okHttp =
          response.statusCode == 200 || response.statusCode == 201;
      if (okHttp && !_isSuccessBody(body)) {
        final String message = _extractMessage(body, 'فشل إلغاء طلب نفاذ');
        showCustomSnackBar(message);
        return Response(statusCode: 400, statusText: message, body: body);
      }
      return response;
    } catch (e) {
      debugPrint('❌ Nafath cancel failed: $e');
      return Response(statusCode: 500, statusText: 'Cancel failed');
    }
  }

  @override
  Future<NafathRandomModel?> Nafath_send_retry(
      BuildContext context, String nationalId) async {
    try {
      if (nationalId.length != 10 ||
          !RegExp(r'^\d{10}$').hasMatch(nationalId)) {
        showCustomSnackBar('رقم الهوية غير صالح');
        return null;
      }

      final Map<String, dynamic>? data = await _buildNafathBody(nationalId);
      if (data == null) {
        return null;
      }
      final Response<dynamic> response = await apiClient.postData(
        AppConstants.nafath_retryUri,
        data,
        headers: const {
          'Accept': 'application/json',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
          'If-None-Match': '',
        },
      );
      if (kDebugMode) {
        debugPrint(
            '📡 Nafath retry POST -> ${apiClient.appBaseUrl}${AppConstants.nafath_retryUri}');
      }

      final dynamic body = response.body;
      final bool isSuccess =
          body is Map<String, dynamic> && body['success'] == true;
      if ((response.statusCode == 200 || response.statusCode == 201) &&
          isSuccess) {
        final Map<String, dynamic> payload =
            body['data'] as Map<String, dynamic>;
        return NafathRandomModel.fromJson(payload);
      }

      final String message = body is Map<String, dynamic>
          ? (body['message']?.toString() ?? 'فشل إعادة إرسال طلب نفاذ')
          : 'فشل إعادة إرسال طلب نفاذ';
      showCustomSnackBar(message);
      return null;
    } catch (e) {
      debugPrint('❌ Nafath retry failed: $e');
      return null;
    }
  }

  @override
  Future<Response<dynamic>> Nafath_send_All_Data(
    BuildContext context,
    String national_id,
    String city,
    String neighborhood,
    String house_type,
    KaidhaSubModel kaidhaSub,
    List<NamedFile> list_img,
  ) async {
    final Map<String, String> payload = {
      'national_id': national_id,
      'city': city,
      'neighborhood': neighborhood,
      'house_type': house_type,
    };
    final Response<dynamic> response = await apiClient.postData(
      AppConstants.nafath_signUri,
      payload,
      headers: const {
        'Accept': 'application/json',
        'Cache-Control': 'no-cache',
        'Pragma': 'no-cache',
        'If-None-Match': '',
      },
    );
    if (kDebugMode) {
      debugPrint(
          '📡 Nafath sign POST -> ${apiClient.appBaseUrl}${AppConstants.nafath_signUri}');
    }
    if ((response.statusCode == 200 || response.statusCode == 201) &&
        !_isSuccessBody(response.body)) {
      final String message =
          _extractMessage(response.body, 'فشل إرسال توقيع العقد');
      showCustomSnackBar(message);
      return Response(
          statusCode: 400, statusText: message, body: response.body);
    }
    return response;
  }

  // ==================================================================================================

  @override
  Future<Response<dynamic>> SendState_kaidha(
      int user_id, String status, Map<String, dynamic> data) async {
    //

    final Map<String, dynamic> req = {
      'user_id': user_id,
      'type': 'qidha',
      'status': status,
      'form_data': data,
    };

    if (kDebugMode) {
      debugPrint(
          '📡 SendState_kaidha POST -> ${apiClient.appBaseUrl}${AppConstants.registration_activityUri}');
      debugPrint('📦 Body: ${jsonEncode(req)}');
    }

    final Response<dynamic> response = await apiClient.postData(
      AppConstants.registration_activityUri,
      req,
      headers: const {'Accept': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    );

    if (kDebugMode) {
      debugPrint('✅ SendState_kaidha response status: ${response.statusCode}');
      try {
        debugPrint('🧾 Response body: ${jsonEncode(response.body)}');
      } catch (_) {
        debugPrint('🧾 Response body: ${response.body}');
      }
    }

    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 304) {
      debugPrint('SendState_kaidha failed: ${response.statusCode}');
    }

    return response;
  }

  @override
  void clearWalletCache() {
    _walletKaidhaCache = null;
  }
}
