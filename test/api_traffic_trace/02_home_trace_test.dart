// ignore_for_file: avoid_print
/// 2. HOME SCREEN TRACE (The Hub)
/// 
/// Tests both Multi-Module Home and Module-Specific Home screens.
/// 
/// A) Multi-Module Home (No module selected):
/// - /api/v2/home-unified (without moduleId - promotional content)
/// - Waste Check: Did we download categories/brands for unselected modules?
/// 
/// B) Module-Specific Home (e.g., Food Module 1):
/// - /api/v2/home-unified?module_id=1
/// - Payload Check: Is it fetching too much data?
/// - Visual Check: Banner flicker?
library;


import 'api_traffic_tracer.dart';

/// 2A. Multi-Module Home Screen (The Hub)
Future<ScreenTraceReport> traceMultiModuleHome({
  bool asGuest = true,
  String? userToken,
}) async {
  final tracer = ApiTrafficTracer();
  final startTime = DateTime.now();
  final apiCalls = <ApiTraceResult>[];
  final logicChecks = <String, dynamic>{};

  TraceTestUtils.printSection('2A. MULTI-MODULE HOME (The Hub)');
  print('Testing multi-module home screen with no module selected...');
  print('');

  // ─────────────────────────────────────────────────────────────────
  // STEP 1: Home-Unified without moduleId (for promotional banners)
  // ─────────────────────────────────────────────────────────────────
  print('📡 Calling /api/v2/home-unified (no moduleId)...');
  
  final homeResult = await tracer.traceGet(
    '/api/v2/home-unified',
    headers: tracer.getDefaultHeaders(
      // No moduleId - multi-module view
      token: asGuest ? null : userToken,
    ),
    queryParams: {
      'include': 'banners,offers', // Only promotional content for hub
    },
  );
  apiCalls.add(homeResult);
  
  print(homeResult);
  
  // Analyze response for waste
  if (homeResult.statusCode == 200 && homeResult.responseBody != null) {
    final body = homeResult.responseBody!;
    final data = body['data'] ?? body;
    
    logicChecks['home_unified_success'] = true;
    
    // Check for data waste - we should NOT have module-specific data without moduleId
    final hasBanners = data['banners'] != null;
    final hasOffers = data['offers'] != null;
    final hasCategories = data['categories'] != null;
    final hasBrands = data['brands'] != null;
    final hasStores = data['popular_stores'] != null;
    
    logicChecks['has_banners'] = hasBanners;
    logicChecks['has_offers'] = hasOffers;
    
    // WASTE CHECK: Categories, Brands, Stores should NOT be in multi-module view
    logicChecks['waste_categories'] = hasCategories ? 'WASTE: Downloaded categories without module' : 'OK';
    logicChecks['waste_brands'] = hasBrands ? 'WASTE: Downloaded brands without module' : 'OK';
    logicChecks['waste_stores'] = hasStores ? 'WASTE: Downloaded stores without module' : 'OK';
    
    // Count items if present
    if (hasBanners) logicChecks['banners_count'] = (data['banners'] as List?)?.length ?? 0;
    if (hasOffers) logicChecks['offers_count'] = (data['offers'] as List?)?.length ?? 0;
    if (hasCategories) logicChecks['categories_count'] = (data['categories'] as List?)?.length ?? 0;
    if (hasBrands) logicChecks['brands_count'] = (data['brands'] as List?)?.length ?? 0;
    if (hasStores) logicChecks['stores_count'] = (data['popular_stores'] as List?)?.length ?? 0;
    
  } else if (homeResult.statusCode == 304) {
    logicChecks['home_unified_from_cache'] = true;
    logicChecks['banner_instant_from_hive'] = 'YES (304 response)';
  } else {
    logicChecks['home_unified_success'] = false;
    logicChecks['home_unified_error'] = homeResult.errorMessage ?? 'Status: ${homeResult.statusCode}';
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 2: Module List (to show available modules)
  // ─────────────────────────────────────────────────────────────────
  print('');
  print('📡 Calling /api/v1/module...');
  
  final modulesResult = await tracer.traceGet(
    '/api/v1/module',
    headers: tracer.getDefaultHeaders(
      token: asGuest ? null : userToken,
    ),
  );
  apiCalls.add(modulesResult);
  
  print(modulesResult);
  
  if (modulesResult.statusCode == 200 && modulesResult.responseBody != null) {
    final modules = modulesResult.responseBody as List?;
    logicChecks['modules_loaded'] = true;
    logicChecks['modules_available'] = modules?.length ?? 0;
  } else if (modulesResult.statusCode == 304) {
    logicChecks['modules_from_cache'] = true;
  }

  final endTime = DateTime.now();
  tracer.dispose();

  return ScreenTraceReport(
    screenName: '2A. Multi-Module Home (The Hub)',
    description: 'Home screen with no module selected - promotional content only',
    apiCalls: apiCalls,
    startTime: startTime,
    endTime: endTime,
    logicChecks: logicChecks,
  );
}

/// 2B. Module-Specific Home Screen (e.g., Food)
Future<ScreenTraceReport> traceModuleSpecificHome({
  required int moduleId,
  required String moduleName,
  bool asGuest = true,
  String? userToken,
}) async {
  final tracer = ApiTrafficTracer();
  final startTime = DateTime.now();
  final apiCalls = <ApiTraceResult>[];
  final logicChecks = <String, dynamic>{};

  TraceTestUtils.printSection('3. MODULE-SPECIFIC HOME ($moduleName - Module $moduleId)');
  print('Testing module-specific home screen...');
  print('');

  // ─────────────────────────────────────────────────────────────────
  // STEP 1: Home-Unified with moduleId (full data for module)
  // ─────────────────────────────────────────────────────────────────
  print('📡 Calling /api/v2/home-unified?module_id=$moduleId...');
  
  final homeResult = await tracer.traceGet(
    '/api/v2/home-unified',
    headers: tracer.getDefaultHeaders(
      moduleId: moduleId,
      token: asGuest ? null : userToken,
    ),
    // No include param - get full data
  );
  apiCalls.add(homeResult);
  
  print(homeResult);
  
  // Analyze payload
  if (homeResult.statusCode == 200 && homeResult.responseBody != null) {
    final body = homeResult.responseBody!;
    final data = body['data'] ?? body;
    
    logicChecks['home_unified_success'] = true;
    
    // Count all data types
    final bannersCount = (data['banners'] as List?)?.length ?? 0;
    final campaignsCount = (data['campaigns'] as List?)?.length ?? 0;
    final categoriesCount = (data['categories'] as List?)?.length ?? 0;
    final storesCount = (data['popular_stores'] as List?)?.length ?? 0;
    final brandsCount = (data['brands'] as List?)?.length ?? 0;
    final offersCount = (data['offers'] as List?)?.length ?? 0;
    
    logicChecks['banners_count'] = bannersCount;
    logicChecks['campaigns_count'] = campaignsCount;
    logicChecks['categories_count'] = categoriesCount;
    logicChecks['stores_count'] = storesCount;
    logicChecks['brands_count'] = brandsCount;
    logicChecks['offers_count'] = offersCount;
    
    // PAYLOAD CHECK: Is it too heavy?
    final totalItems = bannersCount + campaignsCount + categoriesCount + storesCount + brandsCount + offersCount;
    logicChecks['total_items'] = totalItems;
    logicChecks['payload_size'] = totalItems > 100 ? 'HEAVY (>100 items)' : 'OK';
    
    // Check meta for server-side metrics
    if (data['meta'] != null) {
      logicChecks['server_execution_ms'] = data['meta']['execution_time_ms'];
      logicChecks['server_cache_hit'] = data['meta']['cache_hit'];
    }
    
  } else if (homeResult.statusCode == 304) {
    logicChecks['home_unified_from_cache'] = true;
    logicChecks['visual_check_banner_flicker'] = 'NO (instant from cache)';
  } else {
    logicChecks['home_unified_success'] = false;
    logicChecks['home_unified_error'] = homeResult.errorMessage ?? 'Status: ${homeResult.statusCode}';
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 2: Stores List (if not included in unified)
  // ─────────────────────────────────────────────────────────────────
  print('');
  print('📡 Calling /api/v1/stores/get-stores/all...');
  
  final storesResult = await tracer.traceGet(
    '/api/v1/stores/get-stores/all',
    headers: tracer.getDefaultHeaders(
      moduleId: moduleId,
      token: asGuest ? null : userToken,
    ),
    queryParams: {
      'store_type': 'all',
      'offset': '1',
      'limit': '12',
    },
  );
  apiCalls.add(storesResult);
  
  print(storesResult);
  
  if (storesResult.statusCode == 200 && storesResult.responseBody != null) {
    final body = storesResult.responseBody!;
    logicChecks['stores_api_success'] = true;
    logicChecks['stores_from_api'] = (body['stores'] as List?)?.length ?? 0;
    logicChecks['stores_total_size'] = body['total_size'] ?? 0;
    
    // Check if stores match module
    final stores = body['stores'] as List?;
    if (stores != null && stores.isNotEmpty) {
      final firstStore = stores.first;
      final storeModuleId = firstStore['module_id'];
      logicChecks['stores_correct_module'] = storeModuleId == moduleId;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 3: Items/Latest (store items)
  // ─────────────────────────────────────────────────────────────────
  print('');
  print('📡 Calling /api/v1/items/latest...');
  
  final itemsResult = await tracer.traceGet(
    '/api/v1/items/latest',
    headers: tracer.getDefaultHeaders(
      moduleId: moduleId,
      token: asGuest ? null : userToken,
    ),
    queryParams: {
      'offset': '1',
      'limit': '12',
      'type': 'all',
    },
  );
  apiCalls.add(itemsResult);
  
  print(itemsResult);
  
  if (itemsResult.statusCode == 200 && itemsResult.responseBody != null) {
    final body = itemsResult.responseBody!;
    logicChecks['items_api_success'] = true;
    logicChecks['items_count'] = (body['items'] as List?)?.length ?? 0;
  }

  final endTime = DateTime.now();
  
  // Final latency check
  final totalLatency = apiCalls.fold<int>(0, (sum, c) => sum + c.latencyMs);
  logicChecks['total_latency_ms'] = totalLatency;
  logicChecks['latency_acceptable'] = totalLatency < 3000;

  tracer.dispose();

  return ScreenTraceReport(
    screenName: '3. Module-Specific Home ($moduleName)',
    description: 'Home screen for module $moduleId with full data',
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
  print('║         HOME SCREEN API TRAFFIC TRACE                            ║');
  print('╚═══════════════════════════════════════════════════════════════════╝');
  
  // Test Multi-Module Home
  final multiModuleReport = await traceMultiModuleHome();
  print(multiModuleReport.toReport());
  
  // Test Food Module Home
  final foodReport = await traceModuleSpecificHome(
    moduleId: TraceConfig.foodModuleId,
    moduleName: 'Food',
  );
  print(foodReport.toReport());
  
  // Test Ecommerce Module Home
  final ecommerceReport = await traceModuleSpecificHome(
    moduleId: TraceConfig.ecommerceModuleId,
    moduleName: 'Ecommerce',
  );
  print(ecommerceReport.toReport());
  
  // Test Grocery Module Home
  final groceryReport = await traceModuleSpecificHome(
    moduleId: TraceConfig.groceryModuleId,
    moduleName: 'Grocery',
  );
  print(groceryReport.toReport());
  
  print('✅ Home screen trace complete!');
}

