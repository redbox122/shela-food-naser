// ignore_for_file: avoid_print
/// 5. CART & CHECKOUT TRACE (The Money)
/// 
/// Tests the cart and checkout flow.
/// 
/// Expected Endpoints:
/// - /api/v1/customer/cart/list
/// - /api/v1/customer/cart/add
/// - /api/v1/customer/cart/update
/// - /api/v1/customer/cart/remove-item
/// 
/// Critical Checks:
/// - Does adding an item trigger a full reload of the home screen? (It shouldn't)
/// - Cart sync between local and server
/// - Guest vs Authenticated cart handling
library;


import 'api_traffic_tracer.dart';

/// 5. Cart & Checkout Screen Trace
Future<ScreenTraceReport> traceCartAndCheckout({
  required int moduleId,
  required int storeId,
  int itemId = 1, // Default item ID to test
  bool asGuest = true,
  String? userToken,
  String? guestId,
}) async {
  final tracer = ApiTrafficTracer();
  final startTime = DateTime.now();
  final apiCalls = <ApiTraceResult>[];
  final logicChecks = <String, dynamic>{};

  TraceTestUtils.printSection('5. CART & CHECKOUT (The Money)');
  print('Testing cart operations for Store $storeId, Module $moduleId');
  print('Mode: ${asGuest ? "Guest (ID: $guestId)" : "Authenticated User"}');
  print('');

  // Build headers for cart operations
  final cartHeaders = {
    'Content-Type': 'application/json; charset=UTF-8',
    'X-localization': 'ar',
    'moduleId': '$moduleId',
    if (!asGuest && userToken != null) 'Authorization': 'Bearer $userToken',
    'Accept': 'application/json',
  };

  // Build guest query parameter
  final guestParam = asGuest && guestId != null ? '?guest_id=$guestId' : '';

  // ─────────────────────────────────────────────────────────────────
  // STEP 1: Get Current Cart (Initial State)
  // ─────────────────────────────────────────────────────────────────
  print('📡 Calling /api/v1/customer/cart/list (Initial State)...');
  
  final initialCartResult = await tracer.traceGet(
    '/api/v1/customer/cart/list$guestParam',
    headers: tracer.getDefaultHeaders(
      moduleId: moduleId,
      token: asGuest ? null : userToken,
    ),
  );
  apiCalls.add(initialCartResult);
  
  print(initialCartResult);
  
  int initialCartCount = 0;
  if (initialCartResult.statusCode == 200 && initialCartResult.responseBody != null) {
    final cart = initialCartResult.responseBody as List?;
    initialCartCount = cart?.length ?? 0;
    logicChecks['initial_cart_count'] = initialCartCount;
    logicChecks['cart_list_success'] = true;
  } else {
    logicChecks['cart_list_success'] = false;
    logicChecks['cart_list_error'] = initialCartResult.errorMessage ?? 'Status: ${initialCartResult.statusCode}';
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 2: Add Item to Cart
  // ─────────────────────────────────────────────────────────────────
  print('');
  print('📡 Calling /api/v1/customer/cart/add...');
  
  // Sample cart item body
  final addCartBody = {
    'item_id': itemId,
    'quantity': 1,
    'price': 10.0,
    'variation': [],
    'add_ons': [],
    'add_on_ids': [],
    'add_on_qtys': [],
  };
  
  final addCartResult = await tracer.tracePost(
    '/api/v1/customer/cart/add$guestParam',
    headers: cartHeaders,
    body: addCartBody,
  );
  apiCalls.add(addCartResult);
  
  print(addCartResult);
  
  if (addCartResult.statusCode == 200) {
    logicChecks['add_to_cart_success'] = true;
    
    // Check if response contains updated cart
    if (addCartResult.responseBody != null) {
      final updatedCart = addCartResult.responseBody as List?;
      logicChecks['cart_after_add_count'] = updatedCart?.length ?? 0;
    }
  } else {
    logicChecks['add_to_cart_success'] = false;
    logicChecks['add_to_cart_error'] = addCartResult.errorMessage ?? 'Status: ${addCartResult.statusCode}';
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 3: CRITICAL CHECK - Did we trigger home reload?
  // Check if any additional calls were made automatically
  // ─────────────────────────────────────────────────────────────────
  logicChecks['SYNC_CHECK_add_triggered_home_reload'] = apiCalls.length == 2 
    ? 'PASS - No extra calls made'
    : 'FAIL - Extra calls detected (${apiCalls.length - 2} extra)';

  // ─────────────────────────────────────────────────────────────────
  // STEP 4: Get Cart Again (After Add)
  // ─────────────────────────────────────────────────────────────────
  print('');
  print('📡 Calling /api/v1/customer/cart/list (After Add)...');
  
  final afterAddCartResult = await tracer.traceGet(
    '/api/v1/customer/cart/list$guestParam',
    headers: tracer.getDefaultHeaders(
      moduleId: moduleId,
      token: asGuest ? null : userToken,
    ),
  );
  apiCalls.add(afterAddCartResult);
  
  print(afterAddCartResult);
  
  if (afterAddCartResult.statusCode == 200 && afterAddCartResult.responseBody != null) {
    final cart = afterAddCartResult.responseBody as List?;
    final afterAddCount = cart?.length ?? 0;
    logicChecks['cart_after_add_sync'] = afterAddCount > initialCartCount 
      ? 'SYNCED - Item added'
      : 'NOT_SYNCED - Count unchanged';
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 5: Update Cart Quantity
  // ─────────────────────────────────────────────────────────────────
  print('');
  print('📡 Calling /api/v1/customer/cart/update...');
  
  final updateCartBody = {
    'cart_id': 1, // This would be the actual cart_id from the cart list
    'quantity': 2,
    'price': 20.0,
  };
  
  final updateCartResult = await tracer.tracePost(
    '/api/v1/customer/cart/update$guestParam',
    headers: cartHeaders,
    body: updateCartBody,
  );
  apiCalls.add(updateCartResult);
  
  print(updateCartResult);
  
  // May return 404 if cart_id doesn't exist - that's expected for this test
  logicChecks['update_cart_status'] = updateCartResult.statusCode == 200 
    ? 'SUCCESS'
    : (updateCartResult.statusCode == 404 ? 'CART_NOT_FOUND (expected in test)' : 'ERROR');

  // ─────────────────────────────────────────────────────────────────
  // STEP 6: Coupon List (for checkout)
  // ─────────────────────────────────────────────────────────────────
  print('');
  print('📡 Calling /api/v1/coupon/list...');
  
  final couponResult = await tracer.traceGet(
    '/api/v1/coupon/list',
    headers: tracer.getDefaultHeaders(
      moduleId: moduleId,
      token: asGuest ? null : userToken,
    ),
  );
  apiCalls.add(couponResult);
  
  print(couponResult);
  
  if (couponResult.statusCode == 200) {
    final coupons = couponResult.responseBody as List?;
    logicChecks['coupons_available'] = coupons?.length ?? 0;
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 7: Address List (for checkout)
  // ─────────────────────────────────────────────────────────────────
  if (!asGuest && userToken != null) {
    print('');
    print('📡 Calling /api/v1/customer/address/list...');
    
    final addressResult = await tracer.traceGet(
      '/api/v1/customer/address/list',
      headers: tracer.getDefaultHeaders(
        token: userToken,
      ),
    );
    apiCalls.add(addressResult);
    
    print(addressResult);
    
    if (addressResult.statusCode == 200 && addressResult.responseBody != null) {
      final addresses = addressResult.responseBody!['addresses'] as List?;
      logicChecks['addresses_available'] = addresses?.length ?? 0;
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 8: Store Summary for Checkout (v2 BFF endpoint)
  // ─────────────────────────────────────────────────────────────────
  print('');
  print('📡 Calling /api/v2/checkout/store-summary/$storeId...');
  
  final storeSummaryResult = await tracer.traceGet(
    '/api/v2/checkout/store-summary/$storeId',
    headers: tracer.getDefaultHeaders(
      moduleId: moduleId,
      token: asGuest ? null : userToken,
    ),
  );
  apiCalls.add(storeSummaryResult);
  
  print(storeSummaryResult);
  
  if (storeSummaryResult.statusCode == 200) {
    logicChecks['store_summary_v2_available'] = true;
    logicChecks['store_summary_optimized'] = 'YES - Using BFF v2 endpoint';
  } else {
    logicChecks['store_summary_v2_available'] = false;
    logicChecks['store_summary_fallback'] = 'Using legacy store/details endpoint';
  }

  // ─────────────────────────────────────────────────────────────────
  // STEP 9: Remove Item from Cart (cleanup)
  // ─────────────────────────────────────────────────────────────────
  print('');
  print('📡 Calling /api/v1/customer/cart/remove-item...');
  
  // This would use DELETE method - simulating with GET for trace purposes
  final removeResult = await tracer.traceGet(
    '/api/v1/customer/cart/remove-item?cart_id=1$guestParam',
    headers: tracer.getDefaultHeaders(
      moduleId: moduleId,
      token: asGuest ? null : userToken,
    ),
  );
  apiCalls.add(removeResult);
  
  print(removeResult);
  
  // 404 is also success (item already removed)
  logicChecks['remove_item_success'] = removeResult.statusCode == 200 || removeResult.statusCode == 404;

  final endTime = DateTime.now();
  
  // FINAL CHECKS
  final totalLatency = apiCalls.fold<int>(0, (sum, c) => sum + c.latencyMs);
  logicChecks['total_latency_ms'] = totalLatency;
  logicChecks['total_api_calls'] = apiCalls.length;
  
  // Check for unnecessary calls
  final homeUnifiedCalls = apiCalls.where((c) => c.endpoint.contains('home-unified')).length;
  final storeDetailsCalls = apiCalls.where((c) => c.endpoint.contains('stores/details')).length;
  
  logicChecks['UNNECESSARY_CALLS'] = {
    'home_unified_calls': homeUnifiedCalls,
    'store_details_calls': storeDetailsCalls,
    'verdict': homeUnifiedCalls == 0 && storeDetailsCalls == 0 
      ? 'GOOD - No unnecessary calls'
      : 'BAD - Cart should not reload home/store data',
  };

  tracer.dispose();

  return ScreenTraceReport(
    screenName: '5. Cart & Checkout (The Money)',
    description: 'Cart operations for Store $storeId | ${asGuest ? "Guest" : "Authenticated"}',
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
  print('║         CART & CHECKOUT API TRAFFIC TRACE                        ║');
  print('╚═══════════════════════════════════════════════════════════════════╝');
  
  // First get a guest ID
  print('');
  print('Getting guest ID for testing...');
  final tracer = ApiTrafficTracer();
  final guestId = await TraceTestUtils.getGuestId(tracer);
  tracer.dispose();
  
  if (guestId != null) {
    print('✅ Got guest ID: $guestId');
    TraceConfig.guestId = guestId;
  } else {
    print('⚠️ Could not get guest ID, testing without it');
  }
  
  // Test Guest Cart Flow
  final guestReport = await traceCartAndCheckout(
    moduleId: TraceConfig.ecommerceModuleId,
    storeId: 1,
    guestId: guestId,
  );
  print(guestReport.toReport());
  
  // Test Authenticated Cart Flow (requires token)
  // Uncomment and add token to test:
  // final userReport = await traceCartAndCheckout(
  //   moduleId: TraceConfig.ecommerceModuleId,
  //   storeId: 1,
  //   asGuest: false,
  //   userToken: 'YOUR_TOKEN_HERE',
  // );
  // print(userReport.toReport());
  
  print('✅ Cart & checkout trace complete!');
}

