import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import '../data/network_info.dart';
import '../data/api/analytics_api_client.dart';
import '../data/api/qidha_wallet_api_client.dart';
import '../data/repositories/analytics_repository_impl.dart';
import '../data/repositories/qidha_wallet_repository_impl.dart';
import '../domain/repositories/analytics_repository.dart';
import '../domain/repositories/qidha_wallet_repository.dart';
import '../controllers/analytics_controller.dart';
import '../controllers/qidha_wallet_controller.dart';

void initAnalyticsDependencies() {
  // Register NetworkInfo first
  Get.lazyPut<NetworkInfo>(() => NetworkInfo());

  // Register Analytics API Client
  Get.lazyPut<AnalyticsApiClient>(
    () => AnalyticsApiClient(apiClient: Get.find<ApiClient>()),
  );

  // Register Qidha Wallet API Client
  Get.lazyPut<QidhaWalletApiClient>(
    () => QidhaWalletApiClient(apiClient: Get.find<ApiClient>()),
  );

  // Register Analytics Repository
  Get.lazyPut<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(
      analyticsApiClient: Get.find<AnalyticsApiClient>(),
      networkInfo: Get.find<NetworkInfo>(),
    ),
  );

  // Register Qidha Wallet Repository
  Get.lazyPut<QidhaWalletRepository>(
    () => QidhaWalletRepositoryImpl(
      qidhaWalletApiClient: Get.find<QidhaWalletApiClient>(),
      networkInfo: Get.find<NetworkInfo>(),
    ),
  );

  // Register Analytics Controller
  Get.lazyPut<AnalyticsController>(
    () => AnalyticsController(repository: Get.find<AnalyticsRepository>()),
  );

  // Register Qidha Wallet Controller
  Get.lazyPut<QidhaWalletController>(
    () => QidhaWalletController(repository: Get.find<QidhaWalletRepository>()),
  );
}

// Helper function to get analytics controller
AnalyticsController getAnalyticsController() {
  return Get.find<AnalyticsController>();
}

// Helper function to get analytics repository
AnalyticsRepository getAnalyticsRepository() {
  return Get.find<AnalyticsRepository>();
}

// Helper function to get Qidha wallet controller
QidhaWalletController getQidhaWalletController() {
  return Get.find<QidhaWalletController>();
}

// Helper function to get Qidha wallet repository
QidhaWalletRepository getQidhaWalletRepository() {
  return Get.find<QidhaWalletRepository>();
}
