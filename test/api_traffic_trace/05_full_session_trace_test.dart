// ignore_for_file: avoid_print
/// FULL SESSION TRACE
/// 
/// Complete trace from Cold Start to Checkout for both Guest and Authenticated User.
/// 
/// Flow:
/// 1. Splash Screen (The Gatekeeper)
/// 2. Multi-Module Home (The Hub)
/// 3. Module-Specific Home (e.g., Food)
/// 4. Store Details (The Bottleneck)
/// 5. Cart & Checkout (The Money)
/// 
/// This runs all screens sequentially to simulate a real user journey.
library;


import '01_splash_trace_test.dart';
import '02_home_trace_test.dart';
import '03_store_details_trace_test.dart';
import '04_cart_checkout_trace_test.dart';
import 'api_traffic_tracer.dart';

/// Run full session trace for Guest user
Future<List<ScreenTraceReport>> runGuestSessionTrace() async {
  final reports = <ScreenTraceReport>[];
  
  print('');
  print('╔═══════════════════════════════════════════════════════════════════╗');
  print('║         FULL SESSION TRACE - GUEST USER                          ║');
  print('╚═══════════════════════════════════════════════════════════════════╝');
  print('');
  print('Starting cold boot simulation...');
  print('');

  // Step 1: Splash Screen
  final splashReport = await traceSplashScreen();
  reports.add(splashReport);
  print(splashReport.toReport());
  
  // Get guest ID from splash if available
  final guestId = TraceConfig.guestId;
  
  // Step 2: Multi-Module Home
  final multiModuleReport = await traceMultiModuleHome();
  reports.add(multiModuleReport);
  print(multiModuleReport.toReport());
  
  // Step 3: Module-Specific Home (Food)
  final foodHomeReport = await traceModuleSpecificHome(
    moduleId: TraceConfig.foodModuleId,
    moduleName: 'Food',
  );
  reports.add(foodHomeReport);
  print(foodHomeReport.toReport());
  
  // Step 4: Store Details
  final storeReport = await traceStoreDetails(
    storeId: 1,
    moduleId: TraceConfig.ecommerceModuleId,
    storeName: 'هايبر شله',
  );
  reports.add(storeReport);
  print(storeReport.toReport());
  
  // Step 5: Cart & Checkout
  final cartReport = await traceCartAndCheckout(
    moduleId: TraceConfig.ecommerceModuleId,
    storeId: 1,
    guestId: guestId,
  );
  reports.add(cartReport);
  print(cartReport.toReport());

  return reports;
}

/// Run full session trace for Authenticated user
Future<List<ScreenTraceReport>> runAuthenticatedSessionTrace({
  required String userToken,
  int userId = 431,
}) async {
  final reports = <ScreenTraceReport>[];
  
  print('');
  print('╔═══════════════════════════════════════════════════════════════════╗');
  print('║         FULL SESSION TRACE - USER $userId                          ║');
  print('╚═══════════════════════════════════════════════════════════════════╝');
  print('');
  print('Starting authenticated session simulation...');
  print('');

  // Step 1: Splash Screen (Authenticated)
  final splashReport = await traceSplashScreen(
    asGuest: false,
    userToken: userToken,
  );
  reports.add(splashReport);
  print(splashReport.toReport());
  
  // Step 2: Multi-Module Home
  final multiModuleReport = await traceMultiModuleHome(
    asGuest: false,
    userToken: userToken,
  );
  reports.add(multiModuleReport);
  print(multiModuleReport.toReport());
  
  // Step 3: Module-Specific Home (Food)
  final foodHomeReport = await traceModuleSpecificHome(
    moduleId: TraceConfig.foodModuleId,
    moduleName: 'Food',
    asGuest: false,
    userToken: userToken,
  );
  reports.add(foodHomeReport);
  print(foodHomeReport.toReport());
  
  // Step 4: Store Details
  final storeReport = await traceStoreDetails(
    storeId: 1,
    moduleId: TraceConfig.ecommerceModuleId,
    storeName: 'هايبر شله',
    asGuest: false,
    userToken: userToken,
  );
  reports.add(storeReport);
  print(storeReport.toReport());
  
  // Step 5: Cart & Checkout
  final cartReport = await traceCartAndCheckout(
    moduleId: TraceConfig.ecommerceModuleId,
    storeId: 1,
    asGuest: false,
    userToken: userToken,
  );
  reports.add(cartReport);
  print(cartReport.toReport());

  return reports;
}

/// Generate consolidated report
void printConsolidatedReport(List<ScreenTraceReport> guestReports, List<ScreenTraceReport>? userReports) {
  print('');
  print('╔═══════════════════════════════════════════════════════════════════╗');
  print('║         CONSOLIDATED SESSION COMPARISON                          ║');
  print('╚═══════════════════════════════════════════════════════════════════╝');
  print('');
  
  // Guest Summary
  print('📱 GUEST SESSION SUMMARY:');
  print('─' * 60);
  int guestTotalCalls = 0;
  int guestTotalLatency = 0;
  int guestErrors = 0;
  
  for (final report in guestReports) {
    guestTotalCalls += report.apiCalls.length;
    guestTotalLatency += report.totalLatencyMs;
    guestErrors += report.errors;
    print('   ${report.screenName}');
    print('      └─ Calls: ${report.apiCalls.length} | Latency: ${report.totalLatencyMs}ms | Errors: ${report.errors}');
  }
  print('');
  print('   TOTAL: $guestTotalCalls calls | ${guestTotalLatency}ms latency | $guestErrors errors');
  print('');
  
  // User Summary (if available)
  if (userReports != null && userReports.isNotEmpty) {
    print('👤 USER SESSION SUMMARY:');
    print('─' * 60);
    int userTotalCalls = 0;
    int userTotalLatency = 0;
    int userErrors = 0;
    
    for (final report in userReports) {
      userTotalCalls += report.apiCalls.length;
      userTotalLatency += report.totalLatencyMs;
      userErrors += report.errors;
      print('   ${report.screenName}');
      print('      └─ Calls: ${report.apiCalls.length} | Latency: ${report.totalLatencyMs}ms | Errors: ${report.errors}');
    }
    print('');
    print('   TOTAL: $userTotalCalls calls | ${userTotalLatency}ms latency | $userErrors errors');
    print('');
    
    // Comparison
    print('📊 COMPARISON:');
    print('─' * 60);
    print('   API Calls:  Guest: $guestTotalCalls | User: $userTotalCalls | Diff: ${userTotalCalls - guestTotalCalls}');
    print('   Latency:    Guest: ${guestTotalLatency}ms | User: ${userTotalLatency}ms | Diff: ${userTotalLatency - guestTotalLatency}ms');
    print('   Errors:     Guest: $guestErrors | User: $userErrors');
  }
  
  print('');
  print('═══════════════════════════════════════════════════════════════════');
  
  // Critical Findings
  print('');
  print('🔍 CRITICAL FINDINGS:');
  print('─' * 60);
  
  // Check for bottlenecks
  for (final report in guestReports) {
    for (final call in report.apiCalls) {
      if (call.latencyMs > 3000) {
        print('   ⚠️ BOTTLENECK: ${call.endpoint} took ${call.latencyMs}ms');
      }
      if (call.cacheStatus == '304_LOOP') {
        print('   ❌ 304 LOOP: ${call.endpoint} stuck in retry loop');
      }
      if (call.statusCode >= 400) {
        print('   ❌ ERROR: ${call.endpoint} returned ${call.statusCode}');
      }
    }
    
    // Check logic issues
    report.logicChecks.forEach((key, value) {
      if (value == false || 
          (value is String && (value.contains('FAIL') || value.contains('WASTE') || value.contains('BAD')))) {
        print('   ⚠️ ${report.screenName}: $key = $value');
      }
    });
  }
  
  print('');
  print('═══════════════════════════════════════════════════════════════════');
}

/// Run all module tests
Future<void> runAllModuleTests() async {
  print('');
  print('╔═══════════════════════════════════════════════════════════════════╗');
  print('║         ALL MODULE TESTS                                         ║');
  print('╚═══════════════════════════════════════════════════════════════════╝');
  
  final modules = [
    {'id': TraceConfig.foodModuleId, 'name': 'Food'},
    {'id': TraceConfig.ecommerceModuleId, 'name': 'Ecommerce'},
    {'id': TraceConfig.groceryModuleId, 'name': 'Grocery'},
    {'id': TraceConfig.pharmacyModuleId, 'name': 'Pharmacy'},
  ];
  
  for (final module in modules) {
    final report = await traceModuleSpecificHome(
      moduleId: module['id'] as int,
      moduleName: module['name'] as String,
    );
    print(report.toReport());
  }
}

/// Main entry point
void main() async {
  print('');
  print('╔═══════════════════════════════════════════════════════════════════╗');
  print('║         FULL SESSION API TRAFFIC TRACE                           ║');
  print('║         Cold Start → Checkout                                    ║');
  print('║         Generated: ${DateTime.now().toIso8601String()}                ║');
  print('╚═══════════════════════════════════════════════════════════════════╝');
  print('');
  
  // Run Guest Session
  final guestReports = await runGuestSessionTrace();
  
  // Run Authenticated Session (uncomment and add token)
  // final userReports = await runAuthenticatedSessionTrace(
  //   userToken: 'YOUR_USER_431_TOKEN_HERE',
  //   userId: 431,
  // );
  
  // Print consolidated report
  printConsolidatedReport(guestReports, null);
  
  // Optionally run all module tests
  // await runAllModuleTests();
  
  print('');
  print('✅ Full session trace complete!');
  print('');
  print('To test authenticated flow, add a user token and uncomment the authenticated section.');
}

