import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 🎯 Screen Logger Mixin
/// 
/// Automatically logs screen lifecycle events (init, build, dispose)
/// to help debug navigation and screen state issues.
/// 
/// Usage:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with ScreenLogger {
///   @override
///   Widget buildScreen(BuildContext context) {
///     return Scaffold(...);
///   }
/// }
/// ```
mixin ScreenLogger<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('📄 SCREEN INIT: ${widget.runtimeType}');
    }
  }

  @override
  void dispose() {
    if (kDebugMode) {
      debugPrint('🗑️ SCREEN DISPOSE: ${widget.runtimeType}');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint('🧱 SCREEN BUILD: ${widget.runtimeType}');
    }
    return buildScreen(context);
  }

  /// Override this method instead of build()
  Widget buildScreen(BuildContext context);
}

