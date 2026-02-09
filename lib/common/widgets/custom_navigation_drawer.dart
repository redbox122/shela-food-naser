import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';

class CustomNavigationDrawer extends StatefulWidget {
  final Color selectedColor;
  final Color? backgroundColor;
  final TextStyle defaultTextStyle;
  final TextStyle selectedTextStyle;
  final Widget child;

  const CustomNavigationDrawer({
    super.key,
    this.selectedColor = const Color(0xFF4AC8EA),
    this.backgroundColor,
    required this.child,
    this.defaultTextStyle = const TextStyle(
      color: Colors.white70,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    this.selectedTextStyle = const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  });

  @override
  State<CustomNavigationDrawer> createState() =>
      CustomNavigationDrawerState();
}

class CustomNavigationDrawerState extends State<CustomNavigationDrawer>
    with SingleTickerProviderStateMixin {
  double maxWidth = 200;
  double minWidth = 45;
  bool isCollapsed = true;

  late AnimationController _animationController;
  late Animation<double> widthAnimation;

  int currentSelectedIndex = -1;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    widthAnimation = Tween<double>(
      begin: maxWidth,
      end: minWidth,
    ).animate(_animationController);

    _animationController.forward();

    if (Get.find<SplashController>().moduleList == null &&
        (!mounted ? ResponsiveHelper.isDesktop(context) : true)) {
      Get.find<SplashController>().getModules();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SplashController>(
      builder: (splashController) {
        return Stack(
          children: [
            widget.child,
            if (splashController.moduleList != null)
              Positioned(
                top: 100,
                right: 0,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return _buildDrawer(
                      context,
                      widget.backgroundColor,
                      splashController,
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  /// ⭐ هنا كان أصل كل الأخطاء – والآن صار مضبوط
  Widget _buildDrawer(
    BuildContext context,
    Color? backgroundColor,
    SplashController splashController,
  ) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          isCollapsed = false;
          _animationController.reverse();
        });
      },
      onExit: (_) {
        setState(() {
          isCollapsed = true;
          _animationController.forward();
        });
      },
      child: Material(
        elevation: 80,
        color: Colors.transparent,
        child: Container(
          width: widthAnimation.value,
          decoration: BoxDecoration(
            color: backgroundColor ?? Theme.of(context).primaryColor,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(Dimensions.radiusDefault),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            vertical: Dimensions.paddingSizeSmall,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (_, __) =>
                const Divider(height: 12),
            itemCount: splashController.moduleList!.length,
            itemBuilder: (context, index) {
              return CollapsingListTile(
                onTap: () {
                  setState(() {
                    currentSelectedIndex = index;
                  });
                },
                isSelected: currentSelectedIndex == index,
                moduleModel: splashController.moduleList![index],
                animationController: _animationController,
                selectedColor: widget.selectedColor,
                defaultTextStyle: widget.defaultTextStyle,
                selectedTextStyle: widget.selectedTextStyle,
              );
            },
          ),
        ),
      ),
    );
  }
}

class CollapsingListTile extends StatefulWidget {
  final ModuleModel moduleModel;
  final Color selectedColor;
  final TextStyle defaultTextStyle;
  final TextStyle selectedTextStyle;
  final AnimationController animationController;
  final bool isSelected;
  final VoidCallback? onTap;

  const CollapsingListTile({
    super.key,
    required this.moduleModel,
    required this.selectedColor,
    required this.defaultTextStyle,
    required this.selectedTextStyle,
    required this.animationController,
    this.isSelected = false,
    this.onTap,
  });

  @override
  State<CollapsingListTile> createState() =>
      CollapsingListTileState();
}

class CollapsingListTileState extends State<CollapsingListTile> {
  late Animation<double> widthAnimation;
  late Animation<double> sizedBoxAnimation;

  @override
  void initState() {
    super.initState();

    widthAnimation = Tween<double>(
      begin: 200,
      end: 70,
    ).animate(widget.animationController);

    sizedBoxAnimation = Tween<double>(
      begin: 10,
      end: 0,
    ).animate(widget.animationController);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Container(
        width: widthAnimation.value,
        margin: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeExtraSmall,
        ),
        padding: const EdgeInsets.all(
          Dimensions.paddingSizeExtraSmall,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: widget.isSelected
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(Dimensions.radiusSmall),
              child: CustomImage(
                image: widget.moduleModel.iconFullUrl ?? '',
                width: 25,
                height: 25,
              ),
            ),
            SizedBox(width: sizedBoxAnimation.value),
            if (widthAnimation.value >= 190)
              Text(
                widget.moduleModel.moduleName ?? '',
                style: widget.isSelected
                    ? widget.selectedTextStyle
                    : widget.defaultTextStyle,
              ),
          ],
        ),
      ),
    );
  }
}

class NavigationModel {
  final String? title;
  final IconData? icon;
  final VoidCallback? onTap;

  NavigationModel({this.title, this.icon, this.onTap});
}
