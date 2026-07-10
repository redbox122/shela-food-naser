import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 REDESIGN: White home header — personalised greeting on the leading side,
/// notification bell (with an unread dot) and search on the trailing side.
class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  @override
  void initState() {
    super.initState();
    // Ensure the logged-in user's name is loaded so the greeting can show it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !AuthHelper.isLoggedIn() ||
          !Get.isRegistered<ProfileController>()) {
        return;
      }
      final profile = Get.find<ProfileController>();
      final name = profile.userInfoModel?.fName;
      if (name == null || name.trim().isEmpty) {
        profile.getUserInfo();
      }
    });
  }

  String _greeting() {
    if (AuthHelper.isLoggedIn() && Get.isRegistered<ProfileController>()) {
      final name = Get.find<ProfileController>().userInfoModel?.fName;
      if (name != null && name.trim().isNotEmpty) {
        return '${'greeting_hi'.tr} ${name.trim()}';
      }
    }
    return 'greeting_welcome'.tr;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (_) => Container(
        color: Theme.of(context).colorScheme.surface,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + Dimensions.paddingSizeSmall,
          bottom: Dimensions.paddingSizeSmall,
          left: Dimensions.paddingSizeDefault,
          right: Dimensions.paddingSizeDefault,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _greeting(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  height: 1.2,
                  color: Color(0xFF121C19),
                ),
              ),
            ),
            // Search lens hidden on the HOME screen (per request). The code is
            // kept for easy restore; the module storefronts keep their own search.
            // _HeaderIconButton(
            //   image: Images.search,
            //   icon: CupertinoIcons.search,
            //   onTap: () => Get.to<void>(() => HomeSearchScreen(
            //         moduleId: Get.isRegistered<SplashController>()
            //             ? Get.find<SplashController>().module?.id
            //             : null,
            //       )),
            // ),
            // const SizedBox(width: Dimensions.paddingSizeSmall),
            const _NotificationBell(),
          ],
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell();

  void _open() => Get.toNamed(RouteHelper.getNotificationRoute());

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<NotificationController>()) {
      return _HeaderIconButton(icon: CupertinoIcons.bell, onTap: _open);
    }
    return Obx(() {
      final bool hasUnread =
          Get.find<NotificationController>().hasUnread.value;
      // Unread → solid black (filled) bell + green dot; otherwise outline.
      return _HeaderIconButton(
        image: hasUnread ? Images.unread_notification : Images.bell,
        icon: hasUnread ? CupertinoIcons.bell_fill : CupertinoIcons.bell,
        iconColor: hasUnread ? const Color(0xFF121C19) : null,
        onTap: _open,
        badge: hasUnread
            ? Container(
                height: 10,
                width: 10,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 1.5,
                  ),
                ),
              )
            : null,
      );
    });
  }
}

/// Circular grey button. Shows [image] (asset) when given — falling back to
/// [icon] if the asset is missing — otherwise renders [icon] directly.
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String? image;
  final Color? iconColor;
  final VoidCallback onTap;
  final Widget? badge;

  static const double _size = 40;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    this.image,
    this.iconColor,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = iconColor ??
        Theme.of(context).textTheme.bodyLarge?.color ??
        const Color(0xFF121C19);
    final Widget glyph = image != null
        ? Image.asset(
            image!,
            width: 22,
            height: 22,
            color: color,
            errorBuilder: (_, __, ___) => Icon(icon, size: 22, color: color),
          )
        : Icon(icon, size: 22, color: color);

    return InkResponse(
      onTap: onTap,
      radius: _size / 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(
                    alpha: 0.06,
                  ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: glyph,
          ),
          if (badge != null) Positioned(top: 8, right: 9, child: badge!),
        ],
      ),
    );
  }
}
