import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/util/app_colors.dart';
import 'package:sixam_mart/features/home/screens/multi_module/widgets/module_widget.dart';

class ModuleView extends StatefulWidget {
  final List<ModuleModel> modules;

  const ModuleView({super.key, required this.modules});

  @override
  State<ModuleView> createState() => _ModuleViewState();
}

class _ModuleViewState extends State<ModuleView> {
  // State management for draggable modules
  Map<String, Offset> modulePositions = {};
  Map<String, Offset> initialPositions = {};
  String? draggedModuleId;
  bool isDragging = false;

  @override
  Widget build(BuildContext context) {
    // Find Module 3 (eCommerce) to place in center
    ModuleModel? centerModule;
    List<ModuleModel> otherModules = [];

    for (final module in widget.modules) {
      if (module.id == 3) {
        centerModule = module;
      } else {
        otherModules.add(module);
      }
    }

    // Fallback if Module 3 not found
    if (centerModule == null && widget.modules.isNotEmpty) {
      centerModule = widget.modules.first;
      otherModules = widget.modules.skip(1).toList();
    }

    // Limit surrounding modules to 6
    if (otherModules.length > 6) {
      otherModules = otherModules.take(6).toList();
    }

    // All modules list for collision detection
    final allModules = <ModuleModel>[];
    if (centerModule != null) allModules.add(centerModule);
    allModules.addAll(otherModules);
    final moduleIndexById = <int, int>{};
    for (var i = 0; i < allModules.length; i++) {
      final id = allModules[i].id ?? i;
      moduleIndexById[id] = i;
    }

    return Container(
      width: double.infinity,
      height: 400, // Fixed height for the grid area
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          
          // Glovo-style fixed sizes
          const itemSize = 110.0;
          const centerItemSize = 140.0;

          // Initialize positions
          if (initialPositions.isEmpty || initialPositions.length != allModules.length) {
            // Schedule position calculation
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  initialPositions = _calculateInitialPositions(
                    screenWidth,
                    screenHeight,
                    centerModule,
                    otherModules,
                    itemSize,
                    centerItemSize,
                  );
                  if (modulePositions.isEmpty) {
                    modulePositions = Map.from(initialPositions);
                  }
                });
              }
            });
          }

          return Stack(
            children: [
              // Center Module
              if (centerModule != null)
                _buildDraggableModuleItem(
                  context,
                  centerModule,
                  centerItemSize,
                  true,
                  screenWidth,
                  screenHeight,
                  allModules,
                  moduleIndexById,
                ),

              // Surrounding Modules
              ...otherModules.map((module) => _buildDraggableModuleItem(
                    context,
                    module,
                    itemSize,
                    false,
                    screenWidth,
                    screenHeight,
                    allModules,
                    moduleIndexById,
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDraggableModuleItem(
    BuildContext context,
    ModuleModel module,
    double size,
    bool isCenter,
    double screenWidth,
    double screenHeight,
    List<ModuleModel> allModules,
    Map<int, int> moduleIndexById,
  ) {
    final moduleId = module.id.toString();
    final position = modulePositions[moduleId] ?? initialPositions[moduleId] ?? Offset.zero;
    final isDragged = draggedModuleId == moduleId;
    
    // Animate unless dragging
    final shouldAnimate = !(isDragging && draggedModuleId == moduleId);

    return AnimatedPositioned(
      duration: shouldAnimate ? const Duration(milliseconds: 400) : Duration.zero,
      curve: shouldAnimate ? Curves.easeInOut : Curves.linear,
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            draggedModuleId = moduleId;
            isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            final currentPos = modulePositions[moduleId] ?? position;
            final newX = (currentPos.dx + details.delta.dx).clamp(0.0, screenWidth - size);
            final newY = (currentPos.dy + details.delta.dy).clamp(0.0, screenHeight - size);
            
            final adjustedPos = Offset(newX, newY);
            
            // Simple collision check
            for (final other in allModules) {
              if (other.id.toString() != moduleId) {
                final otherPos = modulePositions[other.id.toString()] ?? initialPositions[other.id.toString()];
                if (otherPos != null) {
                  final otherSize = other.id == 3 ? 140.0 : 110.0;
                  if (_checkCollision(adjustedPos, size, otherPos, otherSize)) {
                     // Basic resolve: don't move if colliding (simplified)
                     // Or implement full resolve logic if needed
                     // For now, let's just allow overlap slightly or implement simple push
                  }
                }
              }
            }
            
            modulePositions[moduleId] = adjustedPos;
          });
        },
        onPanEnd: (_) {
          setState(() {
            isDragging = false;
            draggedModuleId = null;
          });
          // Snap to grid
          _applyMagneticSnapping(moduleId, size, screenWidth, screenHeight);
        },
        onTap: () => _onModuleTap(context, module),
        child: ModuleWidget(
          module: module,
          size: size,
          heroTag:
              'module_icon_multi_${module.id ?? moduleIndexById.length}_${moduleIndexById[module.id ?? moduleIndexById.length] ?? 0}',
          isCenter: isCenter,
          isDragged: isDragged,
        ),
      ),
    );
  }

  Map<String, Offset> _calculateInitialPositions(
    double screenWidth,
    double screenHeight,
    ModuleModel? centerModule,
    List<ModuleModel> otherModules,
    double itemSize,
    double centerItemSize,
  ) {
    final positions = <String, Offset>{};
    final centerX = screenWidth / 2;
    final centerY = screenHeight / 2;

    // Center module
    if (centerModule != null) {
      positions[centerModule.id.toString()] = Offset(
        centerX - centerItemSize / 2,
        centerY - centerItemSize / 2,
      );
    }

    // Surrounding modules in circle
    final count = otherModules.length;
    if (count > 0) {
      const radius = 130.0; // Distance from center
      final angleStep = (2 * math.pi) / count;

      for (int i = 0; i < count; i++) {
        // Start from top (-pi/2)
        final angle = i * angleStep - (math.pi / 2);
        
        final x = centerX + radius * math.cos(angle) - itemSize / 2;
        final y = centerY + radius * math.sin(angle) - itemSize / 2;
        
        positions[otherModules[i].id.toString()] = Offset(x, y);
      }
    }

    return positions;
  }

  bool _checkCollision(Offset pos1, double size1, Offset pos2, double size2) {
    final center1 = Offset(pos1.dx + size1 / 2, pos1.dy + size1 / 2);
    final center2 = Offset(pos2.dx + size2 / 2, pos2.dy + size2 / 2);
    final distance = (center1 - center2).distance;
    final minDistance = (size1 + size2) / 2 * 0.85; // Allow slight overlap
    return distance < minDistance;
  }

  void _applyMagneticSnapping(String moduleId, double size, double w, double h) {
    const gridSize = 20.0;
    final current = modulePositions[moduleId] ?? Offset.zero;
    
    final snappedX = (current.dx / gridSize).round() * gridSize;
    final snappedY = (current.dy / gridSize).round() * gridSize;
    
    setState(() {
      modulePositions[moduleId] = Offset(
        snappedX.clamp(0.0, w - size),
        snappedY.clamp(0.0, h - size),
      );
    });
  }

  void _onModuleTap(BuildContext context, ModuleModel module) async {
    try {
      final splashController = Get.find<SplashController>();
      final index = splashController.moduleList?.indexWhere((m) => m.id == module.id) ?? -1;
      
      if (index >= 0) {
        // 🏗️ MODULE-FIRST ARCHITECTURE: Use selectModule for explicit module selection
        // This updates Single Source of Truth and persists selection
        await splashController.selectModule(module, context: context);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ModuleView: Error during module switch: $e');
      debugPrint('Stack trace: $stackTrace');
      if (context.mounted) {
        Get.snackbar(
          'Error',
          'Failed to switch module. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    }
  }

}
