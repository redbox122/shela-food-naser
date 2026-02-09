# 🎯 Zone API Contract Documentation

## 📋 Overview

This document defines the **required API contract** for zone endpoints to support polygon rendering on Google Maps.

---

## 1️⃣ Endpoint: `/api/v1/zone/list`

### Purpose
Get all active zones with **polygon coordinates** for rendering on map.

### Request
```http
GET /api/v1/zone/list
Headers:
  - Authorization: Bearer {token} (optional)
  - X-Module-Id: {module_id} (optional)
```

### ✅ Required Response Format

```json
{
  "zones": [
    {
      "id": 2,
      "name": "غرب الرياض",
      "slug": "riyadh-west",
      "status": 1,
      "formated_coordinates": [
        {"lat": 24.60, "lng": 46.55},
        {"lat": 24.62, "lng": 46.58},
        {"lat": 24.58, "lng": 46.60},
        {"lat": 24.60, "lng": 46.55}
      ],
      "minimum_shipping_charge": 5.0,
      "per_km_shipping_charge": 1.5,
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

### Alternative Response Format (also supported)

```json
[
  {
    "id": 2,
    "name": "غرب الرياض",
    "formated_coordinates": [
      {"lat": 24.60, "lng": 46.55},
      {"lat": 24.62, "lng": 46.58}
    ]
  }
]
```

### ⚠️ Critical Fields

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `id` | ✅ | `int` | Zone ID |
| `formated_coordinates` | ✅ | `Array<{lat, lng}>` | **Polygon points for rendering** |
| `name` | ⚠️ | `string` | Zone name (optional but recommended) |
| `status` | ⚠️ | `int` | Zone status (1=active, 0=inactive) |

### ❌ What's NOT Enough

```json
{
  "zones": [
    {
      "id": 2,
      "name": "غرب الرياض"
      // ❌ Missing formated_coordinates → NO GREEN POLYGON
    }
  ]
}
```

---

## 2️⃣ Endpoint: `/api/v1/config/get-zone-id`

### Purpose
**Validation only** - Check if coordinates are inside a zone.

### Request
```http
GET /api/v1/config/get-zone-id?lat=24.60&lng=46.55
Headers:
  - X-Zone-Id: [2] (optional)
  - X-Latitude: "24.60" (optional)
  - X-Longitude: "46.55" (optional)
```

### Response
```json
{
  "zone_id": [2],
  "zone_data": [
    {
      "id": 2,
      "status": 1,
      "cash_on_delivery": true,
      "digital_payment": true
    }
  ]
}
```

### ⚠️ Important
- This endpoint **does NOT return polygon coordinates**
- Use it **only for validation**
- **Do NOT use it for rendering polygons**

---

## 3️⃣ Backend Implementation Checklist

### ✅ Required Changes

1. **Update `/api/v1/zone/list` endpoint:**
   - Include `formated_coordinates` in response
   - Ensure coordinates are in format: `[{lat, lng}, ...]`
   - Return at least 3 points per zone (minimum for polygon)

2. **Database Schema:**
   - Ensure `zones` table has `formated_coordinates` column
   - Or compute from `coordinates` (GeoJSON) field

3. **Response Format:**
   - Support both `{zones: [...]}` and `[...]` formats
   - Include all active zones (status = 1)

---

## 4️⃣ Flutter Implementation

### Current Status
- ✅ `getAllZones()` method exists
- ✅ `ZoneDataModel` supports `formatedCoordinates`
- ✅ Polygon building logic exists
- ❌ **Backend not returning `formated_coordinates`**

### Expected Behavior

```dart
// After backend fix:
final zones = await locationServiceInterface.getAllZones();
// zones[0].formatedCoordinates = [
//   FormatedCoordinates(lat: 24.60, lng: 46.55),
//   FormatedCoordinates(lat: 24.62, lng: 46.58),
//   ...
// ]

// Polygons will be built automatically:
final polygons = buildZonePolygons(zones);
// polygons = Set<Polygon> with green fillColor
```

---

## 5️⃣ Testing

### Test Case 1: Valid Response
```bash
curl -X GET "https://api.example.com/api/v1/zone/list" \
  -H "Authorization: Bearer {token}"

# Expected: 200 OK with formated_coordinates
```

### Test Case 2: Missing Coordinates
```bash
# If response has zones but no formated_coordinates:
# → Flutter will log warning
# → No polygons rendered
# → Validation still works via get-zone-id
```

---

## 6️⃣ Migration Path

### Phase 1: Backend Update (Required)
1. Update `/api/v1/zone/list` to include `formated_coordinates`
2. Test with Postman/curl
3. Verify response format matches contract

### Phase 2: Flutter Fallback (Temporary)
- If `formated_coordinates` missing → show warning
- Allow user to proceed (validation via `get-zone-id` still works)
- Log diagnostic info for debugging

### Phase 3: Production
- Remove fallback warnings
- Ensure all zones have coordinates
- Monitor polygon rendering success rate

---

## 7️⃣ Troubleshooting

### Problem: "No zones available - allowing all locations"
**Cause:** `getAllZones()` returned empty list or zones without coordinates

**Solution:**
1. Check backend logs for `/api/v1/zone/list` calls
2. Verify `formated_coordinates` in database
3. Test endpoint directly: `curl https://api.example.com/api/v1/zone/list`

### Problem: "Zones exist but no polygons"
**Cause:** Zones returned but `formated_coordinates` is null/empty

**Solution:**
1. Check response: `debugPrint('RAW ZONES RESPONSE => ${jsonEncode(response.body)}')`
2. Verify `formated_coordinates` field exists in response
3. Check `ZoneDataModel.fromJson()` parsing logic

---

## 8️⃣ Summary

| Component | Status | Action Required |
|-----------|--------|-----------------|
| Flutter Model | ✅ Ready | None |
| Flutter Repository | ✅ Ready | None |
| Flutter Polygon Builder | ✅ Ready | None |
| **Backend Endpoint** | ❌ **Missing coordinates** | **Update `/api/v1/zone/list`** |

---

**Last Updated:** 2024-01-XX  
**Maintainer:** Flutter Team

