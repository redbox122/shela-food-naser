// ignore_for_file: depend_on_referenced_packages

import 'package:flutter_test/flutter_test.dart';
import 'package:sixam_mart/common/cache/loading_state_manager.dart';

void main() {
  group('LoadingStateManager Tests', () {
    late LoadingStateManager loadingManager;

    setUp(() {
      loadingManager = LoadingStateManager();
      loadingManager.resetTimestamps();
    });

    test('should prevent duplicate splash loading', () {
      // Start splash loading
      expect(loadingManager.startSplashLoading(), isTrue);
      expect(loadingManager.isSplashLoading, isTrue);

      // Try to start another splash loading
      expect(loadingManager.startSplashLoading(), isFalse);
      expect(loadingManager.isSplashLoading, isTrue);

      // Complete splash loading
      loadingManager.completeSplashLoading();
      expect(loadingManager.isSplashLoading, isFalse);
    });

    test('should prevent duplicate home loading', () {
      // Start home loading
      expect(loadingManager.startHomeLoading(), isTrue);
      expect(loadingManager.isHomeLoading, isTrue);

      // Try to start another home loading
      expect(loadingManager.startHomeLoading(), isFalse);
      expect(loadingManager.isHomeLoading, isTrue);

      // Complete home loading
      loadingManager.completeHomeLoading();
      expect(loadingManager.isHomeLoading, isFalse);
    });

    test('should prevent comprehensive loading when splash is loading', () {
      // Start splash loading
      loadingManager.startSplashLoading();
      expect(loadingManager.isSplashLoading, isTrue);

      // Try to start comprehensive loading
      expect(loadingManager.canStartComprehensiveLoading(), isFalse);
      expect(loadingManager.startComprehensiveLoading(), isFalse);

      // Complete splash loading
      loadingManager.completeSplashLoading();
      expect(loadingManager.canStartComprehensiveLoading(), isTrue);
    });

    test('should prevent home loading when splash is loading', () {
      // Start splash loading
      loadingManager.startSplashLoading();
      expect(loadingManager.isSplashLoading, isTrue);

      // Try to start home loading
      expect(loadingManager.canStartHomeLoading(), isFalse);
      expect(loadingManager.startHomeLoading(), isFalse);

      // Complete splash loading
      loadingManager.completeSplashLoading();
      expect(loadingManager.canStartHomeLoading(), isTrue);
    });

    test('should track loading status correctly', () {
      final status = loadingManager.getLoadingStatus();

      expect(status['isSplashLoading'], isFalse);
      expect(status['isHomeLoading'], isFalse);
      expect(status['isBackgroundRefreshing'], isFalse);
      expect(status['isComprehensiveLoading'], isFalse);
      expect(status['isAnyLoading'], isFalse);

      // Start splash loading
      loadingManager.startSplashLoading();
      final statusAfterSplash = loadingManager.getLoadingStatus();

      expect(statusAfterSplash['isSplashLoading'], isTrue);
      expect(statusAfterSplash['isAnyLoading'], isTrue);
    });

    test('should force stop all loading operations', () {
      // Start multiple loading operations
      loadingManager.startSplashLoading();
      loadingManager.startHomeLoading();
      loadingManager.startBackgroundRefresh();
      loadingManager.startComprehensiveLoading();

      expect(loadingManager.isAnyLoading, isTrue);

      // Force stop all
      loadingManager.forceStopAllLoading();

      expect(loadingManager.isSplashLoading, isFalse);
      expect(loadingManager.isHomeLoading, isFalse);
      expect(loadingManager.isBackgroundRefreshing, isFalse);
      expect(loadingManager.isComprehensiveLoading, isFalse);
      expect(loadingManager.isAnyLoading, isFalse);
    });
  });
}
