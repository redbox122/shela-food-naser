// ignore_for_file: avoid_print
/// 1. SPLASH SCREEN TRACE (The Gatekeeper)
/// 
/// Tests the splash screen API flow for both Guest and Authenticated users.
/// 
/// Expected Endpoints:
/// - /api/v1/app-init (consolidated startup data)
/// - /api/v2/home-unified?include=banners,offers (pre-fetch for splash)
/// - /api/qidha-wallet/get-wallet (for authenticated users)
/// 
/// Logic Checks:
/// - Does it get stuck in 304 retry-loop?
/// - Does it route correctly based on GuestID vs Token?
/// - Is the latency acceptable (<2s)?
library;


import 'api_traffic_tracer.dart';

Future<ScreenTraceReport> traceSplashScreen({
  bool asGuest = true,
  String? userToken,
}) async {
  final tracer = ApiTrafficTracer();
  final startTime = DateTime.now();
  final apiCalls = <ApiTraceResult>[];
  final logicChecks = <String, dynamic>{};

  TraceTestUtils.printSection('1. SPLASH SCREEN TRACE (${asGuest ? "GUEST" : "USER"})');
  print('Testing splash screen initialization flow...');
  print('');

  // ─────────────────────────────────────────────────────────────────
  // STEP 1: App-Init Endpoint (Phase 2 consolidated startup)
  // ─────────────────────────────────────────────────────────────────
  print('📡 Calling /api/v1/app-init...');
  
  final appInitResult = await tracer.traceGet(
    '/api/v1/app-init',
    headers: tracer.getDefaultHeaders(
      token: asGuest ? null : userToken,
    ),
  );
  apiCalls.add(appInitResult);
  
  print(appInitResult);
  
  // Check app-init response
  if (appInitResult.statusCode == 200 && appInitResult.responseBody != null) {
    final body = appInitResult.responseBody!;
    logicChecks['app-init_success'] = true;
    logicChecks['app-init_has_config'] = body.containsKey('config');
    logicChecks['app-init_has_modules'] = body.containsKey('modules');
    logicChecks['app-init_has_zones'] = body.containsKey('zones');
    
    // Check if config contains required fields
    if (body.containsKey('config')) {
      final config = body['config'];
      logicChecks['config_has_base_urls'] = config?['base_urls'] != null;
      logicChecks['config_has_active_modules'] = config?['module'] != null;
    }
    
    // Count modules
    if (body.containsKey('modules')) {
      final modules = body['modules'] as List?;
      logicChecks['modules_count'] = modules?.length ?? 0;
    }
  } else {
    logicChecks['app-init_success'] = false;
    logicChecks['app-init_error'] = appInitResult.errorMessage ?? 'Status: ${appInitResult.statusCode}';
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 2: Home-Unified Pre-fetch (banners + offers only)
  // ─────────────────────────────────────────────────────────────────
  print('');
  print('📡 Calling /api/v2/home-unified with lazy loading...');
  
  final homeUnifiedResult = await tracer.traceGet(
    '/api/v2/home-unified',
    headers: tracer.getDefaultHeaders(
      moduleId: TraceConfig.ecommerceModuleId, // Module 3 for promotional content
      token: asGuest ? null : userToken,
    ),
    queryParams: {
      'include': 'banners,offers', // Lazy loading - only banners and offers
    },
  );
  apiCalls.add(homeUnifiedResult);
  
  print(homeUnifiedResult);
  
  // Check home-unified response
  if (homeUnifiedResult.statusCode == 200 && homeUnifiedResult.responseBody != null) {
    final body = homeUnifiedResult.responseBody!;
    logicChecks['home-unified_success'] = true;
    
    // Check if it returns ONLY banners and offers (lazy loading working)
    final hasBanners = body.containsKey('banners') || body['data']?['banners'] != null;
    final hasOffers = body.containsKey('offers') || body['data']?['offers'] != null;
    final hasCategories = body.containsKey('categories') || body['data']?['categories'] != null;
    final hasStores = body.containsKey('popular_stores') || body['data']?['popular_stores'] != null;
    
    logicChecks['lazy_load_has_banners'] = hasBanners;
    logicChecks['lazy_load_has_offers'] = hasOffers;
    logicChecks['lazy_load_excludes_heavy_data'] = !hasCategories && !hasStores;
  } else if (homeUnifiedResult.statusCode == 304) {
    logicChecks['home-unified_304'] = true;
    logicChecks['home-unified_from_cache'] = true;
  } else {
    logicChecks['home-unified_success'] = false;
    logicChecks['home-unified_error'] = homeUnifiedResult.errorMessage ?? 'Status: ${homeUnifiedResult.statusCode}';
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 3: Wallet (for authenticated users only)
  // ─────────────────────────────────────────────────────────────────
  if (!asGuest && userToken != null) {
    print('');
    print('📡 Calling /api/qidha-wallet/get-wallet...');
    
    final walletResult = await tracer.traceGet(
      '/api/qidha-wallet/get-wallet',
      headers: tracer.getDefaultHeaders(token: userToken),
    );
    apiCalls.add(walletResult);
    
    print(walletResult);
    
    logicChecks['wallet_loaded'] = walletResult.statusCode == 200;
    if (walletResult.statusCode != 200) {
      logicChecks['wallet_error'] = walletResult.errorMessage ?? 'Status: ${walletResult.statusCode}';
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 4: Guest Login (for guest users only)
  // ─────────────────────────────────────────────────────────────────
  if (asGuest) {
    print('');
    print('📡 Calling /api/v1/auth/guest/request...');
    
    final guestResult = await tracer.tracePost(
      '/api/v1/auth/guest/request',
      headers: tracer.getDefaultHeaders(),
    );
    apiCalls.add(guestResult);
    
    print(guestResult);
    
    if (guestResult.statusCode == 200 && guestResult.responseBody != null) {
      logicChecks['guest_id_obtained'] = guestResult.responseBody!['guest_id'] != null;
      TraceConfig.guestId = guestResult.responseBody!['guest_id']?.toString();
    } else {
      logicChecks['guest_id_obtained'] = false;
      logicChecks['guest_error'] = guestResult.errorMessage ?? 'Status: ${guestResult.statusCode}';
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // FINAL CHECKS
  // ─────────────────────────────────────────────────────────────────
  final endTime = DateTime.now();
  final totalLatency = apiCalls.fold<int>(0, (sum, c) => sum + c.latencyMs);
  
  // Check for 304 loop
  final has304Loop = apiCalls.any((c) => c.cacheStatus == '304_LOOP');
  logicChecks['no_304_loop'] = !has304Loop;
  
  // Check total latency (<2000ms is acceptable)
  logicChecks['latency_acceptable'] = totalLatency < 2000;
  logicChecks['total_latency_ms'] = totalLatency;
  
  // Check routing logic
  logicChecks['correct_auth_flow'] = asGuest 
    ? logicChecks['guest_id_obtained'] == true
    : logicChecks['wallet_loaded'] == true;

  tracer.dispose();

  return ScreenTraceReport(
    screenName: '1. Splash Screen (The Gatekeeper)',
    description: 'Cold start initialization - ${asGuest ? "Guest" : "Authenticated User"}',
    apiCalls: apiCalls,
    startTime: startTime,
    endTime: endTime,
    logicChecks: logicChecks,
  );
}

/// Run standalone test
void main() async {
  print('');
  print('╔═══════════════════════════════════════════════════════════════════╗');
  print('║         SPLASH SCREEN API TRAFFIC TRACE                          ║');
  print('╚═══════════════════════════════════════════════════════════════════╝');
  
  // Test as Guest
  final guestReport = await traceSplashScreen();
  print(guestReport.toReport());
  
  // Test as User (requires token)
  // Uncomment and add token to test authenticated flow:
  // final userReport = await traceSplashScreen(asGuest: false, userToken: 'YOUR_TOKEN_HERE');
  // print(userReport.toReport());
  
  print('✅ Splash screen trace complete!');
}

