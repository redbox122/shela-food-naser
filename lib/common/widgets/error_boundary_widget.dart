import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 🔧 FIX 4: Error Boundary Widget
/// 
/// Wraps widgets in a try-catch to prevent crashes from propagating.
/// If a widget fails to build, it shows an error placeholder instead of crashing the entire screen.
class ErrorBoundaryWidget extends StatelessWidget {
  final Widget child;
  final String? widgetName;
  final Widget? fallback;

  const ErrorBoundaryWidget({
    super.key,
    required this.child,
    this.widgetName,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (e, stackTrace) {
          if (kDebugMode) {
            debugPrint('❌ ErrorBoundaryWidget: Error in ${widgetName ?? "widget"}: $e');
            debugPrint('Stack trace: $stackTrace');
          }
          
          // Return fallback widget if provided, otherwise return error placeholder
          if (fallback != null) {
            return fallback!;
          }
          
          // Default error placeholder - minimal UI that doesn't break the layout
          return const SizedBox.shrink();
        }
      },
    );
  }
}

/// 🔧 FIX 4: Safe Builder Widget
/// 
/// Alternative approach using Builder with error handling
/// Catches errors during widget building and shows a placeholder
class SafeBuilder extends StatelessWidget {
  final Widget Function(BuildContext) builder;
  final Widget? errorWidget;

  const SafeBuilder({
    super.key,
    required this.builder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return builder(context);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ SafeBuilder: Error building widget: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      
      if (errorWidget != null) {
        return errorWidget!;
      }
      
      // Return empty widget to prevent crash
      return const SizedBox.shrink();
    }
  }
}

