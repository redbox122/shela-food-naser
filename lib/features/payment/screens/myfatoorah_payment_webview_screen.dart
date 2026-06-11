import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';

/// WebView screen used to complete a MyFatoorah payment flow.
///
/// Returns `'success'` via [Get.back] when [successUrlContains] is detected
/// in the loaded URL, or `'error'` when [errorUrlContains] is detected.
class MyFatoorahPaymentWebViewScreen extends StatefulWidget {
  final String initialUrl;
  final String successUrlContains;
  final String errorUrlContains;

  const MyFatoorahPaymentWebViewScreen({
    super.key,
    required this.initialUrl,
    required this.successUrlContains,
    required this.errorUrlContains,
  });

  @override
  State<MyFatoorahPaymentWebViewScreen> createState() =>
      _MyFatoorahPaymentWebViewScreenState();
}

class _MyFatoorahPaymentWebViewScreenState
    extends State<MyFatoorahPaymentWebViewScreen> {
  bool _isLoading = true;
  bool _hasRedirected = false;
  InAppWebViewController? _webViewController;
  PullToRefreshController? _pullToRefreshController;
  final GlobalKey _webViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pullToRefreshController = GetPlatform.isWeb ||
            ![TargetPlatform.iOS, TargetPlatform.android]
                .contains(defaultTargetPlatform)
        ? null
        : PullToRefreshController(
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                _webViewController?.reload();
              } else {
                _webViewController?.loadUrl(
                  urlRequest: URLRequest(
                    url: await _webViewController?.getUrl(),
                  ),
                );
              }
            },
          );
  }

  void _handleUrl(String? url) {
    if (url == null || _hasRedirected) return;

    if (url.contains(widget.successUrlContains)) {
      _hasRedirected = true;
      Get.back(result: 'success');
    } else if (url.contains(widget.errorUrlContains)) {
      _hasRedirected = true;
      Get.back(result: 'error');
    }
  }

  /// Back guard: a payment may be mid-processing, so confirm before leaving so
  /// the user never thinks the order was lost. The order's real status is
  /// re-verified by the checkout controller after this screen returns.
  Future<void> _confirmExit() async {
    // Gateway already redirected to success/error — just let it return.
    if (_hasRedirected) {
      Get.back(result: 'cancelled');
      return;
    }

    debugPrint('[PaymentRecovery][BACK_DIALOG] shown');
    final String? choice = await Get.dialog<String>(
      AlertDialog(
        title: const Text('الدفع قيد المعالجة'),
        content: const Text(
          'الرجوع الآن قد يترك الطلب غير مكتمل. يمكنك متابعة الحالة من طلباتي.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: 'stay'),
            child: const Text('متابعة الدفع'),
          ),
          TextButton(
            onPressed: () => Get.back(result: 'orders'),
            child: const Text('الذهاب إلى طلباتي'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (choice == 'orders') {
      debugPrint('[PaymentRecovery][BACK_DIALOG] choice=orders');
      debugPrint('[QidhaRepayDialog] action=go_to_orders');
      Get.back(result: 'go_to_orders');
    } else {
      // 'stay' (or dismissed) → remain in the WebView to continue paying.
      // Only "متابعة الدفع" continues the MyFatoorah flow.
      debugPrint('[PaymentRecovery][BACK_DIALOG] choice=stay');
      debugPrint('[QidhaRepayDialog] action=continue_payment');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmExit();
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'payment'.tr,
          onBackPressed: () => _confirmExit(),
        ),
        body: Stack(
          children: [
            InAppWebView(
              key: _webViewKey,
              initialUrlRequest:
                  URLRequest(url: WebUri(widget.initialUrl)),
              initialUserScripts: UnmodifiableListView([]),
              pullToRefreshController: _pullToRefreshController,
              initialSettings: InAppWebViewSettings(
                isInspectable: kDebugMode,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },
              onLoadStart: (controller, url) {
                _handleUrl(url?.toString());
                setState(() => _isLoading = true);
              },
              onLoadStop: (controller, url) {
                _pullToRefreshController?.endRefreshing();
                _handleUrl(url?.toString());
                setState(() => _isLoading = false);
              },
              onProgressChanged: (controller, progress) {
                if (progress == 100) {
                  _pullToRefreshController?.endRefreshing();
                }
              },
            ),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
