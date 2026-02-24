import 'package:get/get.dart';
import 'package:sixam_mart/util/html_type.dart';
import 'package:sixam_mart/features/html/domain/services/html_service_interface.dart';

class HtmlController extends GetxController implements GetxService {
  final HtmlServiceInterface htmlServiceInterface;
  HtmlController({required this.htmlServiceInterface});

  String? _htmlText;
  String? get htmlText => _htmlText;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> getHtmlText(HtmlType htmlType) async {
    _isLoading = true;
    _htmlText = null;
    update();

    try {
      final Response response = await htmlServiceInterface.getHtmlText(htmlType);
      final dynamic body = response.body;

      // Accept both fresh responses (200) and cache-validated responses (304).
      if (response.statusCode == 200 || response.statusCode == 304) {
        _htmlText = _extractHtmlText(body);
      } else {
        // Fallback: if body still contains html, show it instead of blank page.
        _htmlText = _extractHtmlText(body);
      }

      if (_htmlText != null && _htmlText!.isNotEmpty) {
        _htmlText = _htmlText!.replaceAll('href=', 'target="_blank" href=');
      } else {
        _htmlText = '';
      }
    } catch (_) {
      _htmlText = '';
    } finally {
      _isLoading = false;
      update();
    }
  }

  String _extractHtmlText(dynamic body) {
    if (body == null) return '';

    if (body is String) {
      return body.trim();
    }

    if (body is Map<String, dynamic>) {
      // Common API/cache shapes for CMS pages.
      const directKeys = <String>[
        'content',
        'description',
        'html',
        'value',
        'data',
        'about_us',
        'privacy_policy',
        'terms_and_conditions',
        'shipping_policy',
        'refund_policy',
        'cancellation_policy',
        'cancelation_policy',
      ];

      for (final key in directKeys) {
        final value = body[key];
        final extracted = _extractHtmlText(value);
        if (extracted.isNotEmpty) return extracted;
      }

      // Last resort: scan any value for html-like content.
      for (final value in body.values) {
        final extracted = _extractHtmlText(value);
        if (extracted.isNotEmpty) return extracted;
      }
      return '';
    }

    if (body is List) {
      for (final item in body) {
        final extracted = _extractHtmlText(item);
        if (extracted.isNotEmpty) return extracted;
      }
      return '';
    }

    return '';
  }
}
