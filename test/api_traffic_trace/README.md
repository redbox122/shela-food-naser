# API Traffic Trace Tests

## Overview

These test scripts trace live API traffic for every screen in the app, from Cold Start to Checkout. They help identify:

- **Bottlenecks**: Slow API calls (e.g., store details at 4.4s)
- **Cache Issues**: 304 loops, cache misses, stale data
- **Logic Errors**: Wrong routing, missing data, auth issues
- **Data Waste**: Unnecessary API calls or heavy payloads

## Test Structure

```
test/api_traffic_trace/
├── api_traffic_tracer.dart          # Core tracer class
├── 01_splash_trace_test.dart        # Splash screen trace
├── 02_home_trace_test.dart          # Home screen trace (multi-module + specific)
├── 03_store_details_trace_test.dart # Store details trace (bottleneck)
├── 04_cart_checkout_trace_test.dart # Cart & checkout trace
├── 05_full_session_trace_test.dart  # Complete session trace
├── run_all_traces.dart              # Runner script for all tests
└── README.md                        # This file
```

## Running Tests

### Quick Start

```bash
# Run all traces (guest mode)
dart run test/api_traffic_trace/run_all_traces.dart

# Run with verbose output
dart run test/api_traffic_trace/run_all_traces.dart --verbose

# Run specific screen trace
dart run test/api_traffic_trace/01_splash_trace_test.dart
dart run test/api_traffic_trace/02_home_trace_test.dart
dart run test/api_traffic_trace/03_store_details_trace_test.dart
dart run test/api_traffic_trace/04_cart_checkout_trace_test.dart
dart run test/api_traffic_trace/05_full_session_trace_test.dart
```

### Advanced Options

```bash
# Test authenticated user (User 431)
dart run test/api_traffic_trace/run_all_traces.dart --user-token "YOUR_TOKEN_HERE"

# Test specific module
dart run test/api_traffic_trace/run_all_traces.dart --module-id 1  # Food
dart run test/api_traffic_trace/run_all_traces.dart --module-id 2  # Grocery
dart run test/api_traffic_trace/run_all_traces.dart --module-id 3  # Ecommerce
dart run test/api_traffic_trace/run_all_traces.dart --module-id 4  # Pharmacy

# Test specific store
dart run test/api_traffic_trace/run_all_traces.dart --store-id 5

# Export results to JSON
dart run test/api_traffic_trace/run_all_traces.dart --export-json
```

## Screen Traces

### 1. Splash Screen (The Gatekeeper)

**Endpoints Called:**
- `/api/v1/app-init` - Consolidated startup data
- `/api/v2/home-unified?include=banners,offers` - Pre-fetch promotional content
- `/api/qidha-wallet/get-wallet` - Wallet (authenticated only)
- `/api/v1/auth/guest/request` - Guest ID (guest only)

**Logic Checks:**
- Did it get stuck in 304 retry-loop?
- Did it route correctly based on GuestID vs Token?
- Total latency < 2000ms?

### 2. Multi-Module Home (The Hub)

**Endpoints Called:**
- `/api/v2/home-unified` (without moduleId)
- `/api/v1/module` - Available modules

**Waste Checks:**
- Did we download Categories for modules not selected? (Should NOT)
- Did we download Brands for modules not selected? (Should NOT)
- Did we download Stores for modules not selected? (Should NOT)

**Visual Check:**
- Did banners appear instantly from Hive? (304 = instant)

### 3. Module-Specific Home (e.g., Food)

**Endpoints Called:**
- `/api/v2/home-unified?module_id=1` - Full home data
- `/api/v1/stores/get-stores/all` - Store list
- `/api/v1/items/latest` - Items list

**Payload Check:**
- Total items > 100? Too heavy!
- Server execution time (from meta)?
- Cache hit status?

### 4. Store Details (The Bottleneck)

**Endpoints Called:**
- `/api/v1/stores/details/{id}` - THE BOTTLENECK
- `/api/v1/items/latest?store_id={id}` - Store items
- `/api/v1/banners/{id}` - Store banners
- `/api/v1/categories` - Categories
- `/api/v1/items/recommended` - Recommended items

**Critical Checks:**
- **IS THE LATENCY STILL 4.4s?**
- Does this crash without token (Guest)?
- Items belong to correct store?

### 5. Cart & Checkout (The Money)

**Endpoints Called:**
- `/api/v1/customer/cart/list` - Get cart
- `/api/v1/customer/cart/add` - Add item
- `/api/v1/customer/cart/update` - Update quantity
- `/api/v1/customer/cart/remove-item` - Remove item
- `/api/v1/coupon/list` - Coupons
- `/api/v1/customer/address/list` - Addresses (auth only)
- `/api/v2/checkout/store-summary/{id}` - BFF store summary

**Sync Checks:**
- Does adding an item trigger home reload? (Should NOT)
- Cart synced between local and server?

## Report Format

Each screen generates a report with:

```
═══════════════════════════════════════════════════════════════════
📱 [Screen Name]
   [Description]
═══════════════════════════════════════════════════════════════════

📊 SUMMARY:
   - Total API Calls: X
   - Total Latency: Xms
   - Cache Hits: X | Misses: X
   - Errors: X
   - Duration: Xms

📡 ENDPOINTS CALLED:
   ✅ GET /api/v1/... 
      └─ Status: 200 | Latency: Xms | Cache: HIT
   🔄 GET /api/v1/...
      └─ Status: 200 | Latency: Xms | Cache: MISS
   ❌ GET /api/v1/...
      └─ Status: 500 | Latency: Xms | Cache: ERROR

🔍 LOGIC CHECKS:
   ✅ check_name: PASS
   ❌ check_name: FAIL
   ⚠️ check_name: WARNING
```

## Module IDs

| ID | Module     | Description          |
|----|------------|----------------------|
| 1  | Food       | Restaurants/Food     |
| 2  | Grocery    | Grocery stores       |
| 3  | Ecommerce  | General shopping     |
| 4  | Pharmacy   | Medical supplies     |

## Key Metrics to Watch

1. **Store Details Latency**: Should be < 2000ms (was 4400ms!)
2. **Home Screen Load**: Should be < 1500ms total
3. **304 Loops**: Should be 0 (indicates ETag issues)
4. **Unnecessary Calls**: Cart should NOT reload home/store data
5. **Cache Hit Rate**: Should be > 50% for repeat visits

## Troubleshooting

### "Connection refused" errors
- Check if you're on the correct network
- Verify base URL in `api_traffic_tracer.dart`

### 401 Unauthorized
- Token expired, get a fresh token

### 304 Loop detected
- ETag cache issue, clear local cache

### Tests taking too long
- Check network connectivity
- Some endpoints (store details) are known slow

