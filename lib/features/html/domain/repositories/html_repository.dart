import 'package:sixam_mart/features/language/controllers/language_controller.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/core/cache/hive_home_cache_service.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/util/html_type.dart';
import 'package:sixam_mart/features/html/domain/repositories/html_repository_interface.dart';

class HtmlRepository implements HtmlRepositoryInterface {
  final ApiClient apiClient;
  HtmlRepository({required this.apiClient});

  @override
  Future<Response> getHtmlText(HtmlType htmlType) async {
    final String languageCode =
        Get.find<LocalizationController>().locale.languageCode;
    final String uri = htmlType == HtmlType.termsAndCondition
        ? AppConstants.termsAndConditionUri
        : htmlType == HtmlType.privacyPolicy
            ? AppConstants.privacyPolicyUri
            : htmlType == HtmlType.aboutUs
                ? AppConstants.aboutUsUri
                : htmlType == HtmlType.shippingPolicy
                    ? AppConstants.shippingPolicyUri
                    : htmlType == HtmlType.cancellation
                        ? AppConstants.cancellationUri
                        : AppConstants.refundUri;

    final Map<String, String> headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
      AppConstants.localizationKey: languageCode,
    };

    // Force-disable any stale ETag for HTML CMS endpoints.
    await HiveHomeCacheService().clearETagForUri(uri);

    return await apiClient.getData(
      uri,
      headers: headers,
      useEtag: false,
    );
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
