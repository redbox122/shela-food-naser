// ignore_for_file: avoid_print
/// 4. STORE DETAILS TRACE (The Bottleneck)
/// 
/// Tests the store details screen - historically the slowest endpoint.
/// 
/// Expected Endpoints:
/// - /api/v1/stores/details/{store_id}
/// - /api/v1/items/latest?store_id={store_id}
/// - /api/v1/banners/{store_id}
/// 
/// Critical Checks:
/// - IS THE LATENCY STILL 4.4s? (Known bottleneck)
/// - Does this crash if no token is present (Guest)?
/// - Are categories and items loaded correctly?
library;


import 'api_traffic_tracer.dart';

/// 4. Store Details Screen Trace
Future<ScreenTraceReport> traceStoreDetails({
  required int storeId,
  required int moduleId,
  String storeName = 'Unknown Store',
  bool asGuest = true,
  String? userToken,
}) async {
  final tracer = ApiTrafficTracer();
  final startTime = DateTime.now();
  final apiCalls = <ApiTraceResult>[];
  final logicChecks = <String, dynamic>{};

  TraceTestUtils.printSection('4. STORE DETAILS (The Bottleneck) - Store $storeId');
  print('Testing store details for: $storeName');
  print('Module ID: $moduleId | Guest: $asGuest');
  print('');

  // ─────────────────────────────────────────────────────────────────
  // STEP 1: Store Details API (The main bottleneck)
  // ─────────────────────────────────────────────────────────────────
  print('📡 Calling /api/v1/stores/details/$storeId...');
  print('⏱️ Starting latency measurement (known bottleneck)...');
  
  final detailsResult = await tracer.traceGet(
    '/api/v1/stores/details/$storeId',
    headers: tracer.getDefaultHeaders(
      moduleId: moduleId,
      token: asGuest ? null : userToken,
    ),
  );
  apiCalls.add(detailsResult);
  
  print(detailsResult);
  
  // CRITICAL CHECK: Is the latency still 4.4s?
  final detailsLatency = detailsResult.latencyMs;
  logicChecks['store_details_latency_ms'] = detailsLatency;
  logicChecks['latency_still_4400ms'] = detailsLatency >= 4000 ? 'YES - STILL SLOW!' : 'NO - Improved';
  logicChecks['latency_acceptable'] = detailsLatency < 2000 ? 'GOOD (<2s)' : (detailsLatency < 4000 ? 'ACCEPTABLE (2-4s)' : 'BAD (>4s)');
  
  // GUEST CHECK: Does it crash without token?
  if (asGuest) {
    logicChecks['guest_crash_check'] = detailsResult.statusCode == 200 
      ? 'PASS - Works without token'
      : 'FAIL - Status ${detailsResult.statusCode}';
  }
  
  // Parse store details
  if (detailsResult.statusCode == 200 && detailsResult.responseBody != null) {
    final store = detailsResult.responseBody!;
    
    logicChecks['store_details_success'] = true;
    logicChecks['store_id_match'] = store['id'] == storeId;
    logicChecks['store_name'] = store['name'] ?? 'N/A';
    logicChecks['store_module_id'] = store['module_id'];
    logicChecks['store_active'] = store['active'] == 1 || store['active'] == true;
    
    // Check for important fields
    logicChecks['has_logo'] = store['logo'] != null;
    logicChecks['has_cover_photo'] = store['cover_photo'] != null;
    logicChecks['has_categories'] = store['category_ids'] != null;
    logicChecks['has_schedule'] = store['schedules'] != null;
    logicChecks['has_discount'] = store['discount'] != null;
    
    // Count categories
    if (store['category_ids'] != null) {
      final categories = store['category_ids'] as List?;
      logicChecks['categories_count'] = categories?.length ?? 0;
    }
  } else {
    logicChecks['store_details_success'] = false;
    logicChecks['store_details_error'] = detailsResult.errorMessage ?? 'Status: ${detailsResult.statusCode}';
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 2: Store Items (Products in the store)
  // ─────────────────────────────────────────────────────────────────
  print('');
  print('📡 Calling /api/v1/items/latest?store_id=$storeId...');
  
  final itemsResult = await tracer.traceGet(
    '/api/v1/items/latest',
    headers: tracer.getDefaultHeaders(
      moduleId: moduleId,
      token: asGuest ? null : userToken,
    ),
    queryParams: {
      'store_id': storeId.toString(),
      'offset': '1',
      'limit': '20',
      'type': 'all',
    },
  );
  apiCalls.add(itemsResult);
  
  print(itemsResult);
  
  if (itemsResult.statusCode == 200 && itemsResult.responseBody != null) {
    final body = itemsResult.responseBody!;
    logicChecks['items_success'] = true;
    logicChecks['items_count'] = (body['items'] as List?)?.length ?? 0;
    logicChecks['items_total_size'] = body['total_size'] ?? 0;
    
    // Check if items belong to correct store
    final items = body['items'] as List?;
    if (items != null && items.isNotEmpty) {
      final firstItem = items.first;
      logicChecks['items_correct_store'] = firstItem['store_id'] == storeId;
    }
  } else {
    logicChecks['items_success'] = false;
    logicChecks['items_error'] = itemsResult.errorMessage ?? 'Status: ${itemsResult.statusCode}';
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 3: Store Banners (promotional banners for the store)
  // ─────────────────────────────────────────────────────────────────
  print('');
  print('📡 Calling /api/v1/banners/$storeId...');
  
  final bannersResult = await tracer.traceGet(
    '/api/v1/banners/$storeId',
    headers: tracer.getDefaultHeaders(
      moduleId: moduleId,
      token: asGuest ? null : userToken,
    ),
  );
  apiCalls.add(bannersResult);
  
  print(bannersResult);
  
  if (bannersResult.statusCode == 200) {
    final banners = bannersResult.responseBody as List?;
    logicChecks['banners_success'] = true;
    logicChecks['banners_count'] = banners?.length ?? 0;
  } else {
    logicChecks['banners_success'] = false;
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 4: Categories for this store
  // ─────────────────────────────────────────────────────────────────
  print('');
  print('📡 Calling /api/v1/categories (for store categories)...');
  
  final categoriesResult = await tracer.traceGet(
    '/api/v1/categories',
    headers: tracer.getDefaultHeaders(
      moduleId: moduleId,
      token: asGuest ? null : userToken,
    ),
  );
  apiCalls.add(categoriesResult);
  
  print(categoriesResult);
  
  if (categoriesResult.statusCode == 200 && categoriesResult.responseBody != null) {
    final categories = categoriesResult.responseBody as List?;
    logicChecks['categories_api_success'] = true;
    logicChecks['categories_available'] = categories?.length ?? 0;
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 5: Recommended Items
  // ─────────────────────────────────────────────────────────────────
  print('');
  print('📡 Calling /api/v1/items/recommended?store_id=$storeId...');
  
  final recommendedResult = await tracer.traceGet(
    '/api/v1/items/recommended',
    headers: tracer.getDefaultHeaders(
      moduleId: moduleId,
      token: asGuest ? null : userToken,
    ),
    queryParams: {
      'store_id': storeId.toString(),
      'offset': '1',
      'limit': '10',
    },
  );
  apiCalls.add(recommendedResult);
  
  print(recommendedResult);
  
  if (recommendedResult.statusCode == 200 && recommendedResult.responseBody != null) {
    final body = recommendedResult.responseBody!;
    logicChecks['recommended_success'] = true;
    logicChecks['recommended_count'] = (body['items'] as List?)?.length ?? 0;
  }

  final endTime = DateTime.now();
  
  // FINAL SUMMARY
  final totalLatency = apiCalls.fold<int>(0, (sum, c) => sum + c.latencyMs);
  logicChecks['total_latency_ms'] = totalLatency;
  
  // Highlight the bottleneck
  logicChecks['BOTTLENECK_ANALYSIS'] = {
    'store_details_ms': detailsLatency,
    'percentage_of_total': '${((detailsLatency / totalLatency) * 100).toStringAsFixed(1)}%',
    'is_main_bottleneck': detailsLatency > (totalLatency * 0.5),
  };

  tracer.dispose();

  return ScreenTraceReport(
    screenName: '4. Store Details (The Bottleneck)',
    description: 'Store $storeId - $storeName | Module $moduleId',
    apiCalls: apiCalls,
    startTime: startTime,
    endTime: endTime,
    logicChecks: logicChecks,
  );
}

/// Run standalone test with multiple stores
void main() async {
  print('');
  print('╔═══════════════════════════════════════════════════════════════════╗');
  print('║         STORE DETAILS API TRAFFIC TRACE                          ║');
  print('╚═══════════════════════════════════════════════════════════════════╝');
  
  // Test Store ID 1 (هايبر شله - known store)
  final store1Report = await traceStoreDetails(
    storeId: 1,
    moduleId: TraceConfig.ecommerceModuleId,
    storeName: 'هايبر شله',
  );
  print(store1Report.toReport());
  
  // Test another store if available
  final store2Report = await traceStoreDetails(
    storeId: 2,
    moduleId: TraceConfig.foodModuleId,
    storeName: 'Store 2 (Food)',
  );
  print(store2Report.toReport());
  
  print('✅ Store details trace complete!');
  
  // Summary
  print('');
  print('═══════════════════════════════════════════════════════════════════');
  print('📊 BOTTLENECK SUMMARY');
  print('═══════════════════════════════════════════════════════════════════');
  print('Store 1 latency: ${store1Report.apiCalls.first.latencyMs}ms');
  print('Store 2 latency: ${store2Report.apiCalls.first.latencyMs}ms');
  print('═══════════════════════════════════════════════════════════════════');
}

