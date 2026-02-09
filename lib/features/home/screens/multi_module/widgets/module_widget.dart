import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/widgets/animated_module_icon.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';

class ModuleWidget extends StatelessWidget {
  final ModuleModel module;
  final double size;
  final bool isCenter;
  final bool isDragged;
  final VoidCallback? onTap;
  final String heroTag;

  const ModuleWidget({
    super.key,
    required this.module,
    required this.size,
    required this.heroTag,
    this.isCenter = false,
    this.isDragged = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Scale effect when dragging
    final scale = isDragged ? 1.05 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()
          ..setEntry(0, 0, scale)
          ..setEntry(1, 1, scale),
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Module Icon with 3D Effect
              Hero(
                tag: heroTag,
                child: Container(
                  width: size * 0.65,
                  height: size * 0.65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                    boxShadow: [
                      // Main shadow for depth
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDragged ? 0.3 : 0.25),
                        blurRadius: isDragged ? 28 : 22,
                        spreadRadius: isDragged ? 3 : 1,
                        offset: Offset(0, isDragged ? 12 : 10),
                      ),
                      // Subtle top highlight for 3D effect
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.1),
                        blurRadius: 8,
                        spreadRadius: -2,
                        offset: const Offset(0, -3),
                      ),
                      // Additional shadow layer for more depth
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: isDragged ? 16 : 12,
                        offset: Offset(0, isDragged ? 6 : 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Image layer with animated support
                      ClipOval(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: ClipOval(
                            child: AnimatedModuleIcon(
                              url: module.iconFullUrl,
                              width: size * 0.65,
                              height: size * 0.65,
                              clipToCircle: true,
                            ),
                          ),
                        ),
                      ),
                      // Gradient overlay for 3D depth
                      ClipOval(
                        child: Container(
                          width: size * 0.65,
                          height: size * 0.65,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: const Alignment(-0.3, -0.4),
                              radius: 0.8,
                              colors: [
                                Colors.white.withValues(alpha: 0.25),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.15),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Glossy shine effect
                      Positioned(
                        top: size * 0.08,
                        left: size * 0.08,
                        child: ClipOval(
                          child: Container(
                            width: size * 0.25,
                            height: size * 0.25,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.4),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Module Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  module.moduleName ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: robotoBold.copyWith(
                    fontSize: isCenter ? Dimensions.fontSizeDefault : Dimensions.fontSizeSmall,
                    color: Colors.black87,
                    height: 1.2,
                  ),
                ),
              ),
              
              // Optional: Store count for center module if available
              if (isCenter && module.storesCount != null && module.storesCount! > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${module.storesCount} ${'stores'.tr}',
                    style: robotoRegular.copyWith(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
