// ignore_for_file: avoid_print
/// Run All API Traffic Traces
/// 
/// This script runs all trace tests and generates a comprehensive report.
/// 
/// Usage:
///   dart run test/api_traffic_trace/run_all_traces.dart
/// 
/// Options:
///   --guest-only     Run only guest tests
///   --user-token     Provide a user token for authenticated tests
///   --module-id      Test specific module (1=Food, 2=Grocery, 3=Ecommerce, 4=Pharmacy)
///   --store-id       Test specific store
///   --export-json    Export results to JSON file
///   --verbose        Show detailed logs
library;

import 'dart:io';

import '01_splash_trace_test.dart';
import '02_home_trace_test.dart';
import '03_store_details_trace_test.dart';
import '04_cart_checkout_trace_test.dart';
import '05_full_session_trace_test.dart';
import 'api_traffic_tracer.dart';

void main(List<String> args) async {
  final startTime = DateTime.now();
  
  print('''
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║   █████╗ ██████╗ ██╗    ████████╗██████╗  █████╗ ███████╗███████╗██╗ ██████╗  ║
║  ██╔══██╗██╔══██╗██║    ╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██╔════╝██║██╔════╝  ║
║  ███████║██████╔╝██║       ██║   ██████╔╝███████║█████╗  █████╗  ██║██║       ║
║  ██╔══██║██╔═══╝ ██║       ██║   ██╔══██╗██╔══██║██╔══╝  ██╔══╝  ██║██║       ║
║  ██║  ██║██║     ██║       ██║   ██║  ██║██║  ██║██║     ██║     ██║╚██████╗  ║
║  ╚═╝  ╚═╝╚═╝     ╚═╝       ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝     ╚═╝ ╚═════╝  ║
║                                                                               ║
║   LIVE TRAFFIC TRACER - Cold Start to Checkout                               ║
║   Base URL: ${TraceConfig.baseUrl.padRight(54)}║
║   Timestamp: ${startTime.toIso8601String().padRight(52)}║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
''');

  // Parse arguments
  final guestOnly = args.contains('--guest-only');
  final exportJson = args.contains('--export-json');
  final verbose = args.contains('--verbose');
  String? userToken;
  int? moduleId;
  int? storeId;
  
  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--user-token' && i + 1 < args.length) {
      userToken = args[i + 1];
    }
    if (args[i] == '--module-id' && i + 1 < args.length) {
      moduleId = int.tryParse(args[i + 1]);
    }
    if (args[i] == '--store-id' && i + 1 < args.length) {
      storeId = int.tryParse(args[i + 1]);
    }
  }

  if (userToken == null || userToken.isEmpty) {
    final String? envToken = Platform.environment['SHELLA_API_TOKEN'];
    if (envToken != null && envToken.trim().isNotEmpty) {
      userToken = envToken.trim();
      print('🔑 Using bearer token from SHELLA_API_TOKEN');
    }
  }

  final allReports = <ScreenTraceReport>[];

  // ═══════════════════════════════════════════════════════════════════
  // PHASE 1: GUEST SESSION
  // ═══════════════════════════════════════════════════════════════════
  print('');
  print('═══════════════════════════════════════════════════════════════════');
  print('📱 PHASE 1: GUEST SESSION TRACE');
  print('═══════════════════════════════════════════════════════════════════');
  
  // 1. Splash Screen
  print('');
  print('▶ Running Splash Screen trace...');
  final splashReport = await traceSplashScreen();
  allReports.add(splashReport);
  if (verbose) print(splashReport.toReport());
  print('✅ Splash: ${splashReport.apiCalls.length} calls, ${splashReport.totalLatencyMs}ms');
  
  // 2. Multi-Module Home
  print('');
  print('▶ Running Multi-Module Home trace...');
  final hubReport = await traceMultiModuleHome();
  allReports.add(hubReport);
  if (verbose) print(hubReport.toReport());
  print('✅ Multi-Module Home: ${hubReport.apiCalls.length} calls, ${hubReport.totalLatencyMs}ms');
  
  // 3. Module-Specific Home (test all or specific)
  if (moduleId != null) {
    print('');
    print('▶ Running Module $moduleId Home trace...');
    final moduleReport = await traceModuleSpecificHome(
      moduleId: moduleId,
      moduleName: 'Module $moduleId',
    );
    allReports.add(moduleReport);
    if (verbose) print(moduleReport.toReport());
    print('✅ Module $moduleId: ${moduleReport.apiCalls.length} calls, ${moduleReport.totalLatencyMs}ms');
  } else {
    // Test all modules
    for (final mod in [
      {'id': 1, 'name': 'Food'},
      {'id': 2, 'name': 'Grocery'},
      {'id': 3, 'name': 'Ecommerce'},
    ]) {
      print('');
      print('▶ Running ${mod['name']} Module Home trace...');
      final moduleReport = await traceModuleSpecificHome(
        moduleId: mod['id'] as int,
        moduleName: mod['name'] as String,
      );
      allReports.add(moduleReport);
      if (verbose) print(moduleReport.toReport());
      print('✅ ${mod['name']}: ${moduleReport.apiCalls.length} calls, ${moduleReport.totalLatencyMs}ms');
    }
  }
  
  // 4. Store Details
  final testStoreId = storeId ?? 1;
  print('');
  print('▶ Running Store Details trace (Store $testStoreId)...');
  final storeReport = await traceStoreDetails(
    storeId: testStoreId,
    moduleId: moduleId ?? TraceConfig.ecommerceModuleId,
  );
  allReports.add(storeReport);
  if (verbose) print(storeReport.toReport());
  print('✅ Store Details: ${storeReport.apiCalls.length} calls, ${storeReport.totalLatencyMs}ms');
  print('   ⚡ Store Details Latency: ${storeReport.apiCalls.first.latencyMs}ms');
  
  // 5. Cart & Checkout
  print('');
  print('▶ Running Cart & Checkout trace...');
  final cartReport = await traceCartAndCheckout(
    moduleId: moduleId ?? TraceConfig.ecommerceModuleId,
    storeId: testStoreId,
    guestId: TraceConfig.guestId,
  );
  allReports.add(cartReport);
  if (verbose) print(cartReport.toReport());
  print('✅ Cart & Checkout: ${cartReport.apiCalls.length} calls, ${cartReport.totalLatencyMs}ms');

  // ═══════════════════════════════════════════════════════════════════
  // PHASE 2: AUTHENTICATED SESSION (if token provided)
  // ═══════════════════════════════════════════════════════════════════
  if (!guestOnly && userToken != null) {
    print('');
    print('═══════════════════════════════════════════════════════════════════');
    print('👤 PHASE 2: AUTHENTICATED USER SESSION TRACE');
    print('═══════════════════════════════════════════════════════════════════');
    
    // Similar trace flow for authenticated user...
    final authReports = await runAuthenticatedSessionTrace(userToken: userToken);
    allReports.addAll(authReports);
  }

  // ═══════════════════════════════════════════════════════════════════
  // FINAL REPORT
  // ═══════════════════════════════════════════════════════════════════
  final endTime = DateTime.now();
  final totalDuration = endTime.difference(startTime);
  
  print('');
  print('╔═══════════════════════════════════════════════════════════════════╗');
  print('║                      FINAL REPORT                                 ║');
  print('╚═══════════════════════════════════════════════════════════════════╝');
  print('');
  
  int totalCalls = 0;
  int totalLatency = 0;
  int totalErrors = 0;
  int cacheHits = 0;
  int cacheMisses = 0;
  final bottlenecks = <String>[];
  final issues = <String>[];
  
  for (final report in allReports) {
    totalCalls += report.apiCalls.length;
    totalLatency += report.totalLatencyMs;
    totalErrors += report.errors;
    cacheHits += report.cacheHits;
    cacheMisses += report.cacheMisses;
    
    // Find bottlenecks
    for (final call in report.apiCalls) {
      if (call.latencyMs > 3000) {
        bottlenecks.add('${call.endpoint}: ${call.latencyMs}ms');
      }
      if (call.cacheStatus == '304_LOOP') {
        issues.add('304 LOOP: ${call.endpoint}');
      }
      if (call.statusCode >= 400) {
        issues.add('ERROR ${call.statusCode}: ${call.endpoint}');
      }
    }
    
    // Find logic issues
    report.logicChecks.forEach((key, value) {
      if (value == false || 
          (value is String && (value.contains('FAIL') || value.contains('WASTE') || value.contains('BAD')))) {
        issues.add('[${report.screenName}] $key: $value');
      }
    });
  }
  
  print('📊 SUMMARY METRICS:');
  print('─' * 60);
  print('   Total Screens Tested:    ${allReports.length}');
  print('   Total API Calls:         $totalCalls');
  print('   Total Network Latency:   ${totalLatency}ms');
  print('   Total Test Duration:     ${totalDuration.inMilliseconds}ms');
  print('   Cache Hits / Misses:     $cacheHits / $cacheMisses');
  print('   Errors:                  $totalErrors');
  print('');
  
  if (bottlenecks.isNotEmpty) {
    print('⚠️ BOTTLENECKS (>3000ms):');
    print('─' * 60);
    for (final b in bottlenecks) {
      print('   🐢 $b');
    }
    print('');
  }
  
  if (issues.isNotEmpty) {
    print('❌ ISSUES FOUND:');
    print('─' * 60);
    for (final issue in issues) {
      print('   ⚠️ $issue');
    }
    print('');
  } else {
    print('✅ NO CRITICAL ISSUES FOUND');
    print('');
  }
  
  print('═══════════════════════════════════════════════════════════════════');
  
  // Export to JSON if requested
  if (exportJson) {
    final tracer = ApiTrafficTracer();
    final jsonPath = 'test/api_traffic_trace/trace_results_${DateTime.now().millisecondsSinceEpoch}.json';
    await tracer.exportToJson(jsonPath);
    tracer.dispose();
  }
  
  print('');
  print('✅ All traces complete!');
  print('');
}

