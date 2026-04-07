import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

/// 🔥 Priority-based API Loading
///
/// Manages API calls with priority levels:
/// - HIGH: Current screen (gets all resources)
/// - MEDIUM: Next expected screens (loads when idle)
/// - LOW: Prefetch/sync/analytics (runs if time permits)
enum ApiPriority {
  high,
  medium,
  low,
}

/// 🔥 Smart API Request Scheduler
///
/// Executes API calls based on priority:
/// 1. HIGH priority always runs first
/// 2. MEDIUM runs when HIGH queue is empty
/// 3. LOW runs only when both HIGH and MEDIUM are empty
///
/// Features:
/// - Non-blocking execution
/// - Automatic queue processing
/// - Cancellation support for low/medium priority
class ApiScheduler {
  static final ApiScheduler _instance = ApiScheduler._internal();
  factory ApiScheduler() => _instance;
  ApiScheduler._internal();

  final Queue<_Task> _high = Queue<_Task>();
  final Queue<_Task> _medium = Queue<_Task>();
  final Queue<_Task> _low = Queue<_Task>();

  bool _busy = false;
  final Set<CancellationToken> _cancellationTokens = {};

  /// Add a task to the scheduler with priority
  ///
  /// Returns a CancellationToken that can be used to cancel the task
  CancellationToken add(
    Future<void> Function() task, {
    required ApiPriority priority,
    String? tag, // Optional tag for debugging
  }) {
    final token = CancellationToken();
    _cancellationTokens.add(token);

    final apiTask = _Task(
      task: task,
      priority: priority,
      tag: tag ?? 'untagged',
      token: token,
    );

    switch (priority) {
      case ApiPriority.high:
        _high.add(apiTask);
        break;
      case ApiPriority.medium:
        _medium.add(apiTask);
        break;
      case ApiPriority.low:
        _low.add(apiTask);
        break;
    }

    _run();
    return token;
  }

  /// Clear all low priority tasks (called when user navigates away)
  void clearLowPriority() {
    _low.clear();
    _cancellationTokens.clear(); // Clear all tokens for low priority
  }

  /// Clear all medium and low priority tasks
  void clearNonCritical() {
    _medium.clear();
    _low.clear();
    // Note: We don't clear all tokens here, only high priority tasks keep their tokens
    // This allows high priority tasks to continue if they're currently running
  }

  /// Cancel a specific task by token
  void cancel(CancellationToken token) {
    token.cancel();
    // Remove from queues
    _high.removeWhere((task) => task.token == token);
    _medium.removeWhere((task) => task.token == token);
    _low.removeWhere((task) => task.token == token);
    _cancellationTokens.remove(token);
  }

  /// Get current queue sizes (for debugging)
  Map<String, int> getQueueSizes() {
    return {
      'high': _high.length,
      'medium': _medium.length,
      'low': _low.length,
    };
  }

  /// Execute tasks in priority order
  Future<void> _run() async {
    if (_busy) return;
    _busy = true;

    try {
      while (_high.isNotEmpty || _medium.isNotEmpty || _low.isNotEmpty) {
        // Select task based on priority
        _Task? task;
        if (_high.isNotEmpty) {
          task = _high.removeFirst();
        } else if (_medium.isNotEmpty) {
          task = _medium.removeFirst();
        } else if (_low.isNotEmpty) {
          task = _low.removeFirst();
        }

        // Task selection ensures non-null, but add safety check
        if (task == null) {
          break;
        }

        // Check if cancelled before execution
        if (task.token.isCancelled) {
          _cancellationTokens.remove(task.token);
          continue;
        }

        try {
          // Execute task
          await task.task();
        } catch (e) {
          // Log error but don't break the queue
          // Errors should be handled by the task itself
          debugPrint('ApiScheduler: Task "${task.tag}" failed: $e');
        } finally {
          _cancellationTokens.remove(task.token);
        }
      }
    } finally {
      _busy = false;
    }
  }
}

/// Internal task wrapper
class _Task {
  final Future<void> Function() task;
  final ApiPriority priority;
  final String tag;
  final CancellationToken token;

  _Task({
    required this.task,
    required this.priority,
    required this.tag,
    required this.token,
  });
}

/// Cancellation token for API tasks
class CancellationToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}
