import 'dart:developer';
import 'package:flutter/widgets.dart';

/// Page Performance Tracker
/// 
/// Automatically tracks page performance metrics:
/// - Page load time
/// - Number of rebuilds
/// - Warns if page is slow (>500ms)
/// 
/// Usage:
/// ```dart
/// GetPage(
///   name: '/home',
///   page: () => PageTracker(
///     pageName: 'HomeScreen',
///     child: HomeScreen(),
///   ),
/// ),
/// ```
class PageTracker extends StatefulWidget {
  final String pageName;
  final Widget child;

  const PageTracker({
    super.key,
    required this.pageName,
    required this.child,
  });

  @override
  State<PageTracker> createState() => _PageTrackerState();
}

class _PageTrackerState extends State<PageTracker> {
  late final Stopwatch _sw;
  int buildCount = 0;

  @override
  void initState() {
    super.initState();
    _sw = Stopwatch()..start();
    log("📱 PAGE START → ${widget.pageName}");
  }

  @override
  Widget build(BuildContext context) {
    buildCount++;
    return widget.child;
  }

  @override
  void dispose() {
    _sw.stop();
    final ms = _sw.elapsedMilliseconds;

    if (ms > 500) {
      log(
        "⚠️ SLOW PAGE → ${widget.pageName} | ${ms}ms | rebuilds=$buildCount",
      );
    } else {
      log(
        "✅ PAGE OK → ${widget.pageName} | ${ms}ms | rebuilds=$buildCount",
      );
    }
    super.dispose();
  }
}
