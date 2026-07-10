import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_body_model.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/features/support/widgets/web_help_support_widget.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/footer_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _titleColor => _isDark ? Colors.white : const Color(0xFF2D3633);
  static const Color _subtitleColor = Color(0xFF8A9199);
  // Field cards grouped inside a container. Dark: slate + border; light: white.
  Color get _cardColor => _isDark ? const Color(0xFF1E293B) : Colors.white;

  bool _hasChatAccess() {
    return AuthHelper.isLoggedIn() &&
        !Get.find<AuthController>().isGuestLoggedIn();
  }

  Future<void> _openLiveChat() async {
    if (_hasChatAccess()) {
      // Open a DIRECT support chat (not the conversation list). Fixed support
      // identity: user_type=admin, user_id=0. ChatScreen's admin branch loads
      // /message/details?user_type=admin&user_id=0 and sends to /message/send
      // with the same identity — the first message creates the conversation.
      await Get.toNamed(RouteHelper.getChatRoute(
        notificationBody: NotificationBodyModel(
          adminId: 0,
          name: 'الدعم الفني',
        ),
      ));
      return;
    }
    showCustomSnackBar(
      'service_requires_login'.tr,
      isError: false,
      showDuration: 1,
    );
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) {
      return;
    }
    await Get.toNamed(
        RouteHelper.getSignInRoute(RouteHelper.getSupportRoute()));
  }

  Future<void> _call(String phone) async {
    if (phone.isEmpty) {
      return;
    }
    if (await canLaunchUrlString('tel:$phone')) {
      launchUrlString('tel:$phone');
    } else {
      showCustomSnackBar('${'can_not_launch'.tr} $phone');
    }
  }

  void _email(String email) {
    if (email.isEmpty) {
      return;
    }
    final Uri uri = Uri(scheme: 'mailto', path: email);
    launchUrlString(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context)) {
      return Scaffold(
        backgroundColor: AppColors.wtColor,
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: FooterView(
              child: const SizedBox(
                width: double.infinity,
                height: 650,
                child: WebSupportScreen(),
              ),
            ),
          ),
        ),
      );
    }

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
          'help_and_technical_support'.tr,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _titleColor,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: _titleColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GetBuilder<SplashController>(builder: (splash) {
        // Read config reactively so contact details appear as soon as the
        // config finishes loading (they were blank when the screen built
        // before the config was ready).
        final config = splash.configModel;
        final String address = config?.address ?? '';
        final String phone = config?.phone ?? '';
        final String email = config?.email ?? '';
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            child: Column(
              children: <Widget>[
                Image.asset(Images.shellaLogo,
                    width: 165, height: 118, fit: BoxFit.contain),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(10, 14, 10, 6),
                  decoration: BoxDecoration(
                    color: _isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF6F7F9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _supportRow(
                        image: Images.messages_v2,
                        title: 'live_chat'.tr,
                        value: 'المساعدة والدعم',
                        showChevron: true,
                        onTap: _openLiveChat,
                      ),
                      _supportRow(
                        image: Images.location_new,
                        title: 'address'.tr,
                        value: address,
                      ),
                      _supportRow(
                        image: Images.call,
                        title: 'support_number'.tr,
                        value: phone,
                        onTap: () => _call(phone),
                      ),
                      _supportRow(
                        image: Images.sms,
                        title: 'email_us'.tr,
                        value: email,
                        onTap: () => _email(email),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _supportRow({
    required String image,
    required String title,
    required String value,
    bool showChevron = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: <Widget>[
                Image.asset(image, width: 22, height: 22, fit: BoxFit.contain),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _titleColor,
                        ),
                      ),
                      if (value.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        Text(
                          value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 12,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                            color: _subtitleColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showChevron) ...<Widget>[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios,
                      size: 15, color: Color(0xFFBFC6CC)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
