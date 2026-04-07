import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Performance Monitor Widget
/// Tracks API response times and identifies performance bottlenecks
class PerformanceMonitor extends StatefulWidget {
  final Widget child;

  const PerformanceMonitor({super.key, required this.child});

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  final Map<String, List<int>> _responseTimes = {};
  final Map<String, int> _errorCounts = {};
  Timer? _monitorTimer;

  @override
  void initState() {
    super.initState();
    _startMonitoring();
  }

  @override
  void dispose() {
    _monitorTimer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    // Monitor API calls every 10 seconds
    _monitorTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _printPerformanceReport();
      }
    });
  }
  
  void _printPerformanceReport() {
    if (_responseTimes.isEmpty) return;
    
    if (kDebugMode) {
      debugPrint('\n📊 PERFORMANCE REPORT 📊');
      
      _responseTimes.forEach((endpoint, times) {
        if (times.isNotEmpty) {
          final avgTime = times.reduce((a, b) => a + b) / times.length;
          final maxTime = times.reduce((a, b) => a > b ? a : b);
          final errorCount = _errorCounts[endpoint] ?? 0;
          
          debugPrint('🔗 $endpoint');
          debugPrint('   📈 Avg: ${avgTime.toStringAsFixed(0)}ms');
          debugPrint('   ⏱️  Max: ${maxTime}ms');
          debugPrint('   ❌ Errors: $errorCount');
          debugPrint('   📊 Calls: ${times.length}');
          debugPrint('');
        }
      });
    }
    
    // Clear old data
    _responseTimes.clear();
    _errorCounts.clear();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Performance tracking mixin for controllers
mixin PerformanceTracking {
  final Map<String, DateTime> _startTimes = {};
  
  void startTracking(String endpoint) {
    _startTimes[endpoint] = DateTime.now();
  }
  
  void endTracking(String endpoint, {bool isError = false}) {
    final startTime = _startTimes[endpoint];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      
      // Store response time for monitoring
      if (Get.isRegistered<PerformanceMonitor>()) {
        // This would be implemented with a proper service
        if (kDebugMode) debugPrint('⏱️  $endpoint: ${duration}ms ${isError ? '❌' : '✅'}');
      }
      
      _startTimes.remove(endpoint);
    }
  }
}
