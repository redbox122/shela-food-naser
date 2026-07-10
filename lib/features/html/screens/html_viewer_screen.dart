import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:sixam_mart/features/html/controllers/html_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/html_type.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:sixam_mart/common/widgets/web_page_title_widget.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HtmlViewerScreen extends StatefulWidget {
  final HtmlType htmlType;
  const HtmlViewerScreen({super.key, required this.htmlType});

  @override
  State<HtmlViewerScreen> createState() => _HtmlViewerScreenState();
}

class _HtmlViewerScreenState extends State<HtmlViewerScreen> {
  static const Color _titleColor = Color(0xFF111B18);

  @override
  void initState() {
    super.initState();

    Get.find<HtmlController>().getHtmlText(widget.htmlType);
  }

  String get _title {
    switch (widget.htmlType) {
      case HtmlType.termsAndCondition:
        return 'terms_conditions'.tr;
      case HtmlType.aboutUs:
        return 'about_us'.tr;
      case HtmlType.privacyPolicy:
        return 'privacy_policy'.tr;
      case HtmlType.shippingPolicy:
        return 'shipping_policy'.tr;
      case HtmlType.refund:
        return 'refund_policy'.tr;
      case HtmlType.cancellation:
        return 'cancellation_policy'.tr;
      default:
        return 'no_data_found'.tr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color onSurface = isDark ? Colors.white : _titleColor;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          _title,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 18, color: onSurface),
          onPressed: () => Get.back(),
        ),
      ),
      body: GetBuilder<HtmlController>(builder: (htmlController) {
        return Center(
          child: htmlController.isLoading
              ? const CircularProgressIndicator()
              : (htmlController.htmlText ?? '').isNotEmpty
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: <Widget>[
                          WebScreenTitleWidget(title: _title),
                          FooterView(
                            child: Container(
                              width: Dimensions.webMaxWidth,
                              color: Theme.of(context).scaffoldBackgroundColor,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              child: HtmlWidget(
                                htmlController.htmlText ?? '',
                                key: Key(widget.htmlType.toString()),
                                // Light theme: keep each element's own colour from
                                // the server HTML. Dark theme: force a light text
                                // colour so black server text stays readable.
                                textStyle: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontSize: 18,
                                  height: 2.0,
                                  color: isDark ? const Color(0xFFE2E8F0) : null,
                                ),
                                customStylesBuilder: (element) {
                                  return <String, String>{
                                    'font-family': 'Tajawal',
                                    if (isDark) 'color': '#E2E8F0',
                                  };
                                },
                                onTapUrl: (String url) {
                                  return launchUrlString(url);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Text('no_data_found'.tr),
        );
      }),
    );
  }
}
