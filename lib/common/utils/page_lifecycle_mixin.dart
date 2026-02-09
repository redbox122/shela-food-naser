/*
 * Page Lifecycle Mixin
 * 
 * This mixin provides automatic page lifecycle tracking and logging.
 * Use this mixin in StatefulWidget State classes to automatically
 * log page entry/exit and track API calls.
 * 
 * Usage:
 * class _MyPageState extends State<MyPage> with PageLifecycleMixin {
 *   @override
 *   void initState() {
 *     super.initState();
 *     initializePageLifecycle('MyPage');
 *   }
 * }
 */

import 'package:flutter/material.dart';
import 'app_logger.dart';

mixin PageLifecycleMixin<T extends StatefulWidget> on State<T> {
  String? _pageName;
  
  /// Initialize page lifecycle tracking
  /// Call this in initState with the page name
  void initializePageLifecycle(String pageName) {
    _pageName = pageName;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      appLogger.logPageEntry(pageName);
    });
  }
  
  @override
  void dispose() {
    if (_pageName != null) {
      appLogger.logPageExit();
    }
    super.dispose();
  }
  
  /// Get current page name
  String? get pageName => _pageName;
  
  /// Log a custom page event
  void logPageEvent(String event, [Map<String, dynamic>? data]) {
    if (_pageName != null) {
      final dataStr = data != null ? ' | Data: ${data.toString()}' : '';
      appLogger.info('[$_pageName] Event: $event$dataStr');
    }
  }
}











