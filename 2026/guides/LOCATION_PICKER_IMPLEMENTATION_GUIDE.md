# Location Picker Implementation Guide - Web Team

## Overview

This document explains how the location picker works, including map integration, zone polygon display, location selection methods, and zone validation API calls. This is specifically for the web/TypeScript implementation team.

## Google Maps API Setup

### API Key Required

**Important:** You need a **Google Maps API Key** to use Google Maps. The app uses Google Maps directly (not through backend API).

### How It's Configured in Mobile App

**Android:**
- API key configured in `AndroidManifest.xml` as meta-data
- Key: `com.google.android.geo.API_KEY`
- Value: `AIzaSyDwpl1O5yMBvB9JHtZz61I3P3uz_ClvXP8`

**iOS:**
- API key set in `AppDelegate.swift`
- Using: `GMSServices.provideAPIKey("AIzaSyDwpl1O5yMBvB9JHtZz61I3P3uz_ClvXP8")`

**Web (Current):**
- Loaded via script tag in HTML: `<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_MAP_KEY"></script>`
- Currently has placeholder `YOUR_MAP_KEY` - needs to be replaced

### For Next.js/Web Implementation

**Option 1: Load via Script Tag (Simple)**
```html
<!-- In your _document.tsx or index.html -->
<script 
  src={`https://maps.googleapis.com/maps/api/js?key=${process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY}&libraries=places,geometry`}
  async
  defer
></script>
```

**Option 2: Use @googlemaps/js-api-loader (Recommended)**
```typescript
import { Loader } from '@googlemaps/js-api-loader';

const loader = new Loader({
  apiKey: process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY!,
  version: 'weekly',
  libraries: ['places', 'geometry'], // Required for autocomplete and distance calculations
});

await loader.load();
```

### Required Google Maps APIs

Enable these APIs in Google Cloud Console:
1. **Maps JavaScript API** - For map display
2. **Places API** - For address autocomplete/search
3. **Geocoding API** - For reverse geocoding (coordinates → address)
4. **Distance Matrix API** - For calculating distances (optional, used in checkout)

### Environment Variable Setup

**Create `.env.local` file:**
```
NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

**Important Notes:**
- Use `NEXT_PUBLIC_` prefix for client-side environment variables in Next.js
- Never commit API keys to version control
- Restrict API key in Google Cloud Console to your domain
- Set up billing in Google Cloud Console (Google Maps requires billing)

### API Key Restrictions (Security)

**Recommended Restrictions:**
1. **Application restrictions:**
   - HTTP referrers (web sites)
   - Add your domain: `https://yourdomain.com/*`

2. **API restrictions:**
   - Restrict to only needed APIs:
     - Maps JavaScript API
     - Places API
     - Geocoding API
     - Distance Matrix API (if used)

### Google Maps Services Used

1. **Google Maps JavaScript API**
   - Map display
   - Map controls (zoom, pan)
   - Markers and polygons
   - Event listeners (camera idle, etc.)

2. **Google Places API**
   - Address autocomplete
   - Place details
   - Place search

3. **Google Geocoding API**
   - Reverse geocoding (lat/lng → address)
   - Forward geocoding (address → lat/lng)

4. **Google Distance Matrix API** (Optional)
   - Calculate distance between two points
   - Used in checkout for delivery charge calculation

---

## Table of Contents

1. [Google Maps API Setup](#1-google-maps-api-setup)
2. [Location Picker Flow Overview](#2-location-picker-flow-overview)
3. [Location Selection Methods](#3-location-selection-methods)
4. [Zone Polygon Display](#4-zone-polygon-display)
5. [Zone Validation API](#5-zone-validation-api)
6. [Complete Implementation Flow](#6-complete-implementation-flow)
7. [API Endpoints Reference](#7-api-endpoints-reference)
8. [Code Examples](#8-code-examples)

---

## 1. Google Maps API Setup

### Overview

**The location picker uses Google Maps directly (client-side), NOT through your backend API.**

You need:
- ✅ **Google Maps API Key** (required)
- ✅ **Google Cloud Console** account with billing enabled
- ✅ **Required APIs enabled** (Maps JavaScript API, Places API, Geocoding API)

### What Uses Google Maps API (Client-Side)

**Direct Google Maps API Calls:**
1. **Map Display** - Google Maps JavaScript API
2. **Address Autocomplete** - Google Places API
3. **Reverse Geocoding** - Google Geocoding API (coordinates → address)
4. **Distance Calculation** - Google Distance Matrix API (optional, for checkout)

**These are called directly from the browser and require Google Maps API key.**

### What Uses Your Backend API

**Your Backend API Calls:**
1. **Zone Polygons** - `GET /api/v1/config/get-zone-id` (no coordinates)
2. **Zone Validation** - `GET /api/v1/config/get-zone-id?lat={lat}&lng={lng}`
3. **Address Autocomplete (Alternative)** - `GET /api/v1/config/place-api-autocomplete?search_text={query}`

**These are your backend endpoints and don't require Google Maps API key.**

### How It's Configured in Mobile App

**Android:**
```xml
<!-- AndroidManifest.xml -->
<meta-data 
  android:name="com.google.android.geo.API_KEY" 
  android:value="AIzaSyDwpl1O5yMBvB9JHtZz61I3P3uz_ClvXP8"/>
```

**iOS:**
```swift
// AppDelegate.swift
GMSServices.provideAPIKey("AIzaSyDwpl1O5yMBvB9JHtZz61I3P3uz_ClvXP8")
```

**Web (Current - Placeholder):**
```html
<!-- index.html -->
<script src="https://maps.googleapis.com/maps/api/js?key=YOUR_MAP_KEY"></script>
```

### For Next.js/Web Implementation

#### Step 1: Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a project or select existing project
3. Enable these APIs:
   - **Maps JavaScript API** (required)
   - **Places API** (required for autocomplete)
   - **Geocoding API** (required for reverse geocoding)
   - **Distance Matrix API** (optional, for distance calculations)
4. Create API key
5. **Set up billing** (Google Maps requires billing to be enabled)

#### Step 2: Configure Environment Variable

**Create `.env.local` file:**
```bash
NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

**Important:**
- Use `NEXT_PUBLIC_` prefix for client-side variables in Next.js
- Never commit API keys to version control
- Add `.env.local` to `.gitignore`

#### Step 3: Load Google Maps in Your App

**Option A: Using @googlemaps/js-api-loader (Recommended)**

```typescript
import { Loader } from '@googlemaps/js-api-loader';

const loader = new Loader({
  apiKey: process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY!,
  version: 'weekly',
  libraries: ['places', 'geometry'], // Required libraries
});

await loader.load();
// Now you can use google.maps.*
```

**Option B: Load via Script Tag**

```html
<!-- In _document.tsx or public/index.html -->
<script 
  src={`https://maps.googleapis.com/maps/api/js?key=${process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY}&libraries=places,geometry`}
  async
  defer
></script>
```

#### Step 4: Secure Your API Key

**In Google Cloud Console, set restrictions:**

1. **Application Restrictions:**
   - Select "HTTP referrers (web sites)"
   - Add your domains:
     - `https://yourdomain.com/*`
     - `https://*.yourdomain.com/*`
     - `http://localhost:*` (for development)

2. **API Restrictions:**
   - Select "Restrict key"
   - Choose only needed APIs:
     - Maps JavaScript API
     - Places API
     - Geocoding API
     - Distance Matrix API (if used)

### Required Libraries

When loading Google Maps, include these libraries:

```typescript
libraries: ['places', 'geometry']
```

- **places** - For address autocomplete/search
- **geometry** - For distance calculations and polygon operations

### API Key Costs

**Important:** Google Maps has usage-based pricing:
- **Maps JavaScript API:** Free tier: $200/month credit
- **Places API:** Free tier: $200/month credit
- **Geocoding API:** Free tier: $200/month credit
- After free tier: Pay-as-you-go pricing

**Monitor usage in Google Cloud Console to avoid unexpected charges.**

### Testing Without API Key

**You CANNOT test the location picker without a valid Google Maps API key.**

The map will not load, and you'll see errors like:
- "This page can't load Google Maps correctly"
- "Google Maps API error: RefererNotAllowedMapError"

**Solution:** Get a valid API key and configure it properly.

---

## 2. Location Picker Flow Overview

### High-Level Flow

```
User Opens Location Picker
         ↓
Load Zone Polygons (Green Areas)
         ↓
Get Initial Location (GPS or Saved)
         ↓
Display Map with Polygons
         ↓
User Selects Location (3 methods)
         ↓
Validate Zone (API Call with lat/lng)
         ↓
Save Location & Navigate
```

### Key Points

1. **Zone polygons are loaded FIRST** - Before user interaction
2. **Location is obtained THEN validated** - We get coordinates first, then call validation API
3. **Validation happens on every location change** - When user pans map, searches, or uses GPS
4. **Green polygons are visual guides** - They show service areas but don't validate automatically

---

## 3. Location Selection Methods

### Method 1: Current Location (GPS)

**Flow:**
1. User clicks "Current Location" button
2. Request browser geolocation permission
3. Get GPS coordinates using `navigator.geolocation.getCurrentPosition()`
4. Move map camera to GPS location
5. **Call zone validation API with lat/lng**
6. Update UI based on validation result

**Implementation:**
```typescript
// Step 1: Request GPS location
navigator.geolocator.getCurrentPosition(
  (position) => {
    const lat = position.coords.latitude;
    const lng = position.coords.longitude;
    
    // Step 2: Move map to location
    map.setCenter({ lat, lng });
    map.setZoom(16);
    
    // Step 3: Validate zone with API
    validateZone(lat, lng);
  },
  (error) => {
    // Handle permission denied or error
  }
);
```

**When Zone Validation is Called:**
- **AFTER** GPS coordinates are obtained
- **BEFORE** user confirms location
- Uses coordinates from `position.coords.latitude` and `position.coords.longitude`

### Method 2: Map Pan/Drag

**Flow:**
1. User drags/pans map to desired location
2. Map camera moves, pick marker stays centered
3. When camera stops moving (`onCameraIdle` event):
   - Get coordinates from map center
   - **Call zone validation API with lat/lng**
   - Reverse geocode to get address
   - Update button state

**Implementation:**
```typescript
// Google Maps event listener
map.addListener('idle', () => {
  const center = map.getCenter();
  const lat = center.lat();
  const lng = center.lng();
  
  // Call zone validation with current map center coordinates
  validateZone(lat, lng);
  
  // Also get address for display
  reverseGeocode(lat, lng);
});
```

**When Zone Validation is Called:**
- **AFTER** map camera stops moving
- **ON EVERY** pan/drag completion
- Uses coordinates from `map.getCenter()`

### Method 3: Address Search

**Flow:**
1. User types in search input
2. Call autocomplete API
3. User selects address from suggestions
4. Get place details (coordinates) from Google Places API
5. Move map to selected location
6. **Call zone validation API with lat/lng**
7. Update UI

**Implementation:**
```typescript
// Step 1: Autocomplete
const autocomplete = new google.maps.places.Autocomplete(input);
autocomplete.addListener('place_changed', () => {
  const place = autocomplete.getPlace();
  
  if (!place.geometry) return;
  
  // Step 2: Get coordinates
  const lat = place.geometry.location.lat();
  const lng = place.geometry.location.lng();
  
  // Step 3: Move map
  map.setCenter({ lat, lng });
  map.setZoom(16);
  
  // Step 4: Validate zone
  validateZone(lat, lng);
});
```

**When Zone Validation is Called:**
- **AFTER** place coordinates are obtained
- **AFTER** map moves to selected location
- Uses coordinates from `place.geometry.location`

---

## 4. Zone Polygon Display

### Loading Zone Polygons

**API Endpoint:**
```
GET /api/v1/config/get-zone-id
```

**Important:** This endpoint is called WITHOUT coordinates to get ALL zones for polygon display.

**When Called:**
- On location picker screen initialization
- Before user interaction
- Used to display green polygons on map

**Response:**
```json
[
  {
    "id": 1,
    "name": "Riyadh Central",
    "status": 1,
    "formatedCoordinates": [
      {"lat": 24.6, "lng": 46.5},
      {"lat": 24.7, "lng": 46.6},
      {"lat": 24.8, "lng": 46.7}
    ]
  },
  {
    "id": 2,
    "name": "Riyadh North",
    "status": 1,
    "formatedCoordinates": [
      {"lat": 24.9, "lng": 46.8},
      {"lat": 25.0, "lng": 46.9}
    ]
  }
]
```

### Building Polygons for Map Display

**Technique:**
1. Filter zones where `status === 1` (active zones only)
2. Collect all coordinate points from all active zones
3. Compute convex hull of all points (creates single polygon covering all service areas)
4. Display on map with green stroke and semi-transparent fill

**Implementation:**
```typescript
async function loadZonePolygons() {
  // Step 1: Fetch all zones (NO coordinates needed)
  const response = await fetch('/api/v1/config/get-zone-id');
  const zones = await response.json();
  
  // Step 2: Filter active zones
  const activeZones = zones.filter(zone => zone.status === 1);
  
  // Step 3: Collect all points
  const allPoints = [];
  activeZones.forEach(zone => {
    if (zone.formatedCoordinates) {
      zone.formatedCoordinates.forEach(coord => {
        allPoints.push({ lat: coord.lat, lng: coord.lng });
      });
    }
  });
  
  // Step 4: Compute convex hull
  const hullPoints = computeConvexHull(allPoints);
  
  // Step 5: Create polygon
  const polygon = new google.maps.Polygon({
    paths: hullPoints,
    strokeColor: '#4CAF50', // Green
    strokeOpacity: 1.0,
    strokeWeight: 2,
    fillColor: '#4CAF50',
    fillOpacity: 0.2, // 20% opacity
  });
  
  // Step 6: Display on map
  polygon.setMap(map);
}
```

**Polygon Appearance:**
- **Stroke Color:** Green (#4CAF50 or primary theme color)
- **Fill Color:** Same green with 20% opacity
- **Stroke Width:** 2 pixels
- **Purpose:** Visual guide showing service delivery areas

**Important Notes:**
- Polygons are for **visual display only**
- They don't automatically validate location
- You MUST call validation API with coordinates to check if location is valid
- Polygons may not be 100% accurate - always validate with API

---

## 5. Zone Validation API

### API Endpoint

**Endpoint:** `GET /api/v1/config/get-zone-id`

**Required Query Parameters:**
- `lat` (latitude) - Required
- `lng` (longitude) - Required

**Alternative Parameter Names (Backend accepts both):**
- `lat` or `latitude`
- `lng` or `longitude`

**Full URL Example:**
```
GET /api/v1/config/get-zone-id?lat=24.604301879077966&lng=46.59593515098095
```

### When to Call This API

**Call validation API:**
1. ✅ After getting GPS coordinates
2. ✅ After user pans map (on camera idle)
3. ✅ After user selects address from search
4. ✅ Before allowing user to confirm location
5. ✅ When map center changes

**DO NOT call validation API:**
- ❌ On initial map load (use polygon endpoint without coordinates)
- ❌ While map is still panning (wait for idle event)
- ❌ Without valid coordinates

### Request Format

```typescript
async function validateZone(latitude: number, longitude: number) {
  const url = `/api/v1/config/get-zone-id?lat=${latitude}&lng=${longitude}`;
  
  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    });
    
    const data = await response.json();
    
    // Check if location is in service zone
    if (data.zone_ids && data.zone_ids.length > 0) {
      // Location is valid - enable "Pick Location" button
      setInZone(true);
      setZoneData(data);
    } else {
      // Location is outside service zone - disable button
      setInZone(false);
      setZoneData(null);
    }
  } catch (error) {
    console.error('Zone validation failed:', error);
    // Handle error - maybe show message to user
  }
}
```

### Response Format

**Response (Inside Zone):**
```json
{
  "zone_ids": [1, 2],
  "zone_data": [
    {
      "id": 1,
      "name": "Riyadh Central",
      "status": 1
    },
    {
      "id": 2,
      "name": "Riyadh North",
      "status": 1
    }
  ],
  "area_ids": [1]
}
```

**Response (Outside Zone):**
```json
{
  "zone_ids": [],
  "zone_data": [],
  "area_ids": []
}
```

### Validation Logic

```typescript
function isLocationInZone(zoneData: any): boolean {
  // Location is valid if zone_ids array is not empty
  return zoneData.zone_ids && zoneData.zone_ids.length > 0;
}

// Usage
const isValid = isLocationInZone(validationResponse);
if (isValid) {
  // Enable "Pick Location" button
  // Show "Pick Location" text
} else {
  // Disable "Pick Location" button
  // Show "Service not available in this area" text
}
```

---

## 6. Complete Implementation Flow

### Step-by-Step Flow

#### Step 1: Initialize Location Picker Screen

```typescript
async function initializeLocationPicker() {
  // 1. Load zone polygons for visual display (NO coordinates)
  await loadZonePolygons();
  
  // 2. Get initial location
  const savedAddress = localStorage.getItem('user_address');
  if (savedAddress) {
    const address = JSON.parse(savedAddress);
    setInitialLocation(address.latitude, address.longitude);
  } else {
    // Try to get GPS location or use default
    try {
      const position = await getCurrentPosition();
      setInitialLocation(position.coords.latitude, position.coords.longitude);
    } catch {
      // Use default location from config
      setInitialLocation(defaultLat, defaultLng);
    }
  }
  
  // 3. Initialize map
  initializeMap();
}
```

#### Step 2: User Selects Location (Any Method)

**Option A: GPS Location**
```typescript
async function handleCurrentLocationClick() {
  // 1. Request permission
  const position = await getCurrentPosition();
  
  // 2. Get coordinates
  const lat = position.coords.latitude;
  const lng = position.coords.longitude;
  
  // 3. Move map
  map.setCenter({ lat, lng });
  
  // 4. Validate zone (API call with lat/lng)
  await validateZone(lat, lng);
  
  // 5. Get address
  const address = await reverseGeocode(lat, lng);
  setSelectedAddress(address);
}
```

**Option B: Map Pan**
```typescript
function setupMapListeners() {
  // Listen for camera idle (when user stops panning)
  map.addListener('idle', async () => {
    const center = map.getCenter();
    const lat = center.lat();
    const lng = center.lng();
    
    // Validate zone (API call with lat/lng)
    await validateZone(lat, lng);
    
    // Get address
    const address = await reverseGeocode(lat, lng);
    setSelectedAddress(address);
  });
}
```

**Option C: Address Search**
```typescript
function setupSearchAutocomplete() {
  const autocomplete = new google.maps.places.Autocomplete(searchInput);
  
  autocomplete.addListener('place_changed', async () => {
    const place = autocomplete.getPlace();
    
    if (!place.geometry) return;
    
    // Get coordinates
    const lat = place.geometry.location.lat();
    const lng = place.geometry.location.lng();
    
    // Move map
    map.setCenter({ lat, lng });
    
    // Validate zone (API call with lat/lng)
    await validateZone(lat, lng);
    
    // Use place address
    setSelectedAddress(place.formatted_address);
  });
}
```

#### Step 3: Zone Validation

```typescript
async function validateZone(latitude: number, longitude: number) {
  // Show loading state
  setValidating(true);
  setButtonDisabled(true);
  
  try {
    // Call API with lat/lng query parameters
    const response = await fetch(
      `/api/v1/config/get-zone-id?lat=${latitude}&lng=${longitude}`
    );
    
    const data = await response.json();
    
    // Check validation result
    const isValid = data.zone_ids && data.zone_ids.length > 0;
    
    if (isValid) {
      // Location is in service zone
      setInZone(true);
      setZoneData(data);
      setButtonText('Pick Location');
      setButtonDisabled(false);
    } else {
      // Location is outside service zone
      setInZone(false);
      setZoneData(null);
      setButtonText('Service not available in this area');
      setButtonDisabled(true);
    }
  } catch (error) {
    console.error('Validation failed:', error);
    // Handle error - maybe allow user to proceed anyway or show error
  } finally {
    setValidating(false);
  }
}
```

#### Step 4: User Confirms Location

```typescript
async function handlePickLocationClick() {
  if (!inZone) {
    // Should not happen if button is disabled, but check anyway
    showError('Location is outside service area');
    return;
  }
  
  const center = map.getCenter();
  const lat = center.lat();
  const lng = center.lng();
  
  // Get zone data (we already have it from validation, but can re-fetch to be sure)
  const zoneData = await validateZone(lat, lng);
  
  // Create address object
  const address = {
    latitude: lat.toString(),
    longitude: lng.toString(),
    address: selectedAddress,
    addressType: 'others',
    zoneId: zoneData.zone_ids[0],
    zoneIds: zoneData.zone_ids,
    zoneData: zoneData.zone_data,
    areaIds: zoneData.area_ids,
  };
  
  // Save to local storage
  localStorage.setItem('user_address', JSON.stringify(address));
  
  // Navigate to home or checkout
  navigate('/home');
}
```

---

## 7. API Endpoints Reference

### Endpoint 1: Get Zone Polygons (For Display)

**Purpose:** Get all zones to display green polygons on map

**Endpoint:** `GET /api/v1/config/get-zone-id`

**Query Parameters:** None (or optional, but not required)

**When to Call:**
- On location picker screen initialization
- To display service area boundaries

**Response:**
```json
[
  {
    "id": 1,
    "name": "Riyadh Central",
    "status": 1,
    "formatedCoordinates": [
      {"lat": 24.6, "lng": 46.5},
      {"lat": 24.7, "lng": 46.6}
    ]
  }
]
```

### Endpoint 2: Validate Zone (For Validation)

**Purpose:** Check if specific coordinates are within service zone

**Endpoint:** `GET /api/v1/config/get-zone-id?lat={latitude}&lng={longitude}`

**Query Parameters:** 
- `lat` (required) - Latitude coordinate
- `lng` (required) - Longitude coordinate

**Alternative Parameters:**
- `latitude` (instead of `lat`)
- `longitude` (instead of `lng`)

**When to Call:**
- After getting GPS coordinates
- After user pans map (on camera idle)
- After user selects address from search
- Before allowing user to confirm location

**Request Example:**
```
GET /api/v1/config/get-zone-id?lat=24.604301879077966&lng=46.59593515098095
```

**Response (Inside Zone):**
```json
{
  "zone_ids": [1, 2],
  "zone_data": [
    {
      "id": 1,
      "name": "Riyadh Central",
      "status": 1
    }
  ],
  "area_ids": [1]
}
```

**Response (Outside Zone):**
```json
{
  "zone_ids": [],
  "zone_data": [],
  "area_ids": []
}
```

### Endpoint 3: Address Autocomplete

**Purpose:** Search for addresses using Google Places

**Endpoint:** `GET /api/v1/config/place-api-autocomplete?search_text={query}`

**Query Parameters:**
- `search_text` (required) - Search query

**When to Call:**
- As user types in search input
- To show address suggestions

**Request Example:**
```
GET /api/v1/config/place-api-autocomplete?search_text=Riyadh
```

**Response:**
```json
{
  "predictions": [
    {
      "description": "Riyadh, Saudi Arabia",
      "place_id": "ChIJ...",
      "structured_formatting": {
        "main_text": "Riyadh",
        "secondary_text": "Saudi Arabia"
      }
    }
  ]
}
```

---

## 8. Code Examples

### Google Maps API Key Configuration

**Before implementing the location picker, you must:**

1. **Get Google Maps API Key:**
   - Go to [Google Cloud Console](https://console.cloud.google.com/)
   - Create a project or select existing
   - Enable required APIs (Maps JavaScript API, Places API, Geocoding API)
   - Create API key
   - Set up billing (required for Google Maps)

2. **Configure in Next.js:**
   ```typescript
   // .env.local
   NEXT_PUBLIC_GOOGLE_MAPS_API_KEY=your_api_key_here
   ```

3. **Load Google Maps:**
   ```typescript
   import { Loader } from '@googlemaps/js-api-loader';
   
   const loader = new Loader({
     apiKey: process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY!,
     version: 'weekly',
     libraries: ['places', 'geometry'],
   });
   
   await loader.load();
   ```

### Complete Location Picker Component (React/TypeScript Example)

```typescript
import { useEffect, useState, useRef } from 'react';
import { Loader } from '@googlemaps/js-api-loader';

interface ZoneData {
  zone_ids: number[];
  zone_data: Array<{
    id: number;
    name: string;
    status: number;
  }>;
  area_ids: number[];
}

export function LocationPicker() {
  const mapRef = useRef<HTMLDivElement>(null);
  const [map, setMap] = useState<google.maps.Map | null>(null);
  const [inZone, setInZone] = useState(false);
  const [validating, setValidating] = useState(false);
  const [selectedAddress, setSelectedAddress] = useState('');
  const [zoneData, setZoneData] = useState<ZoneData | null>(null);
  const polygonRef = useRef<google.maps.Polygon | null>(null);

  // Initialize map
  useEffect(() => {
    const initMap = async () => {
      // Step 1: Load Google Maps JavaScript API
      const loader = new Loader({
        apiKey: process.env.NEXT_PUBLIC_GOOGLE_MAPS_API_KEY!, // Your Google Maps API key
        version: 'weekly',
        libraries: ['places', 'geometry'], // Required libraries
      });

      // Step 2: Wait for Google Maps to load
      await loader.load();

      if (mapRef.current) {
        const mapInstance = new google.maps.Map(mapRef.current, {
          center: { lat: 24.6043, lng: 46.5959 }, // Default location
          zoom: 16,
          mapTypeControl: false,
          streetViewControl: false,
        });

        setMap(mapInstance);

        // Load zone polygons
        await loadZonePolygons(mapInstance);

        // Setup map listeners
        setupMapListeners(mapInstance);
      }
    };

    initMap();
  }, []);

  // Load zone polygons for visual display
  async function loadZonePolygons(mapInstance: google.maps.Map) {
    try {
      const response = await fetch('/api/v1/config/get-zone-id');
      const zones = await response.json();

      // Filter active zones
      const activeZones = zones.filter((zone: any) => zone.status === 1);

      // Collect all points
      const allPoints: google.maps.LatLngLiteral[] = [];
      activeZones.forEach((zone: any) => {
        if (zone.formatedCoordinates) {
          zone.formatedCoordinates.forEach((coord: any) => {
            allPoints.push({ lat: coord.lat, lng: coord.lng });
          });
        }
      });

      // Compute convex hull (simplified - you may want to use a library)
      const hullPoints = computeConvexHull(allPoints);

      // Create polygon
      const polygon = new google.maps.Polygon({
        paths: hullPoints,
        strokeColor: '#4CAF50',
        strokeOpacity: 1.0,
        strokeWeight: 2,
        fillColor: '#4CAF50',
        fillOpacity: 0.2,
      });

      polygon.setMap(mapInstance);
      polygonRef.current = polygon;
    } catch (error) {
      console.error('Failed to load zone polygons:', error);
    }
  }

  // Setup map event listeners
  function setupMapListeners(mapInstance: google.maps.Map) {
    // Validate zone when camera stops moving
    mapInstance.addListener('idle', async () => {
      const center = mapInstance.getCenter();
      if (center) {
        const lat = center.lat();
        const lng = center.lng();

        // Validate zone with API
        await validateZone(lat, lng);

        // Get address
        const address = await reverseGeocode(lat, lng);
        setSelectedAddress(address);
      }
    });
  }

  // Validate zone with API
  async function validateZone(latitude: number, longitude: number) {
    setValidating(true);
    setInZone(false);

    try {
      // Call API with lat/lng query parameters
      const response = await fetch(
        `/api/v1/config/get-zone-id?lat=${latitude}&lng=${longitude}`
      );

      if (!response.ok) {
        throw new Error('Validation failed');
      }

      const data: ZoneData = await response.json();

      // Check if location is in zone
      const isValid = data.zone_ids && data.zone_ids.length > 0;

      setInZone(isValid);
      setZoneData(isValid ? data : null);
    } catch (error) {
      console.error('Zone validation error:', error);
      setInZone(false);
    } finally {
      setValidating(false);
    }
  }

  // Get current GPS location
  async function handleCurrentLocation() {
    if (!map) return;

    try {
      const position = await new Promise<GeolocationPosition>((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(resolve, reject);
      });

      const lat = position.coords.latitude;
      const lng = position.coords.longitude;

      // Move map to location
      map.setCenter({ lat, lng });
      map.setZoom(16);

      // Validate zone
      await validateZone(lat, lng);

      // Get address
      const address = await reverseGeocode(lat, lng);
      setSelectedAddress(address);
    } catch (error) {
      console.error('GPS error:', error);
      alert('Unable to get your location. Please select on map.');
    }
  }

  // Reverse geocode coordinates to address
  // Uses Google Maps Geocoding API (requires API key)
  async function reverseGeocode(lat: number, lng: number): Promise<string> {
    const geocoder = new google.maps.Geocoder();
    return new Promise((resolve, reject) => {
      geocoder.geocode({ location: { lat, lng } }, (results, status) => {
        if (status === 'OK' && results && results[0]) {
          resolve(results[0].formatted_address);
        } else {
          reject(new Error('Geocoding failed'));
        }
      });
    });
  }

  // Alternative: Use backend API for reverse geocoding (if you have one)
  async function reverseGeocodeViaBackend(lat: number, lng: number): Promise<string> {
    // If your backend has a geocoding endpoint, use it instead
    const response = await fetch(`/api/geocode?lat=${lat}&lng=${lng}`);
    const data = await response.json();
    return data.address;
  }

  // Handle location confirmation
  async function handlePickLocation() {
    if (!map || !inZone || !zoneData) return;

    const center = map.getCenter();
    if (!center) return;

    const lat = center.lat();
    const lng = center.lng();

    // Create address object
    const address = {
      latitude: lat.toString(),
      longitude: lng.toString(),
      address: selectedAddress,
      addressType: 'others',
      zoneId: zoneData.zone_ids[0],
      zoneIds: zoneData.zone_ids,
      zoneData: zoneData.zone_data,
      areaIds: zoneData.area_ids,
    };

    // Save to local storage
    localStorage.setItem('user_address', JSON.stringify(address));

    // Navigate away
    window.location.href = '/home';
  }

  return (
    <div className="location-picker">
      <div ref={mapRef} style={{ width: '100%', height: '400px' }} />
      
      <div className="controls">
        <button onClick={handleCurrentLocation}>
          Use Current Location
        </button>
        
        <button
          onClick={handlePickLocation}
          disabled={!inZone || validating}
        >
          {validating
            ? 'Validating...'
            : inZone
            ? 'Pick Location'
            : 'Service not available in this area'}
        </button>
      </div>
      
      {selectedAddress && (
        <div className="address-display">
          {selectedAddress}
        </div>
      )}
    </div>
  );
}

// Helper function to compute convex hull (simplified)
function computeConvexHull(points: google.maps.LatLngLiteral[]): google.maps.LatLngLiteral[] {
  // Use a convex hull algorithm library or implement Graham scan
  // This is a placeholder - implement proper convex hull algorithm
  return points; // Simplified
}
```

### Key Implementation Points

1. **Two Separate API Calls:**
   - One WITHOUT coordinates to get polygons for display
   - One WITH coordinates to validate specific location

2. **Validation Happens After Location is Obtained:**
   - GPS: After `getCurrentPosition()` returns coordinates
   - Map Pan: After `onCameraIdle` event fires
   - Search: After place coordinates are obtained

3. **Always Include lat/lng in Validation API:**
   ```typescript
   const url = `/api/v1/config/get-zone-id?lat=${lat}&lng=${lng}`;
   ```

4. **Check Response to Enable/Disable Button:**
   ```typescript
   const isValid = data.zone_ids && data.zone_ids.length > 0;
   ```

---

### Hybrid Approach: Google Maps + Backend API

**The location picker uses BOTH:**

1. **Google Maps API (Client-Side):**
   - Map display and interaction
   - Address autocomplete
   - Reverse geocoding
   - Requires Google Maps API key

2. **Your Backend API:**
   - Zone polygon data
   - Zone validation
   - Business logic
   - No Google Maps API key needed

**Example Flow:**
```typescript
// 1. User selects location (uses Google Maps)
const lat = map.getCenter().lat();
const lng = map.getCenter().lng();

// 2. Get address from Google (optional - for display)
const address = await reverseGeocode(lat, lng); // Google Maps API

// 3. Validate zone with YOUR backend API
const zoneData = await fetch(
  `/api/v1/config/get-zone-id?lat=${lat}&lng=${lng}`
); // Your backend API
```

## Summary

### Critical Points for Web Team

1. **Google Maps API Key Required:**
   - You MUST have a Google Maps API key
   - Configure it in environment variables: `NEXT_PUBLIC_GOOGLE_MAPS_API_KEY`
   - Enable required APIs in Google Cloud Console
   - Set up billing (Google Maps requires billing)

2. **Zone Polygon Loading:**
   - Call `GET /api/v1/config/get-zone-id` WITHOUT coordinates
   - Use response to draw green polygons on map
   - This is for visual display only
   - Uses YOUR backend API (not Google Maps)

3. **Zone Validation:**
   - Call `GET /api/v1/config/get-zone-id?lat={lat}&lng={lng}` WITH coordinates
   - Call this AFTER getting location (GPS, map pan, or search)
   - Use response to enable/disable "Pick Location" button
   - Uses YOUR backend API (not Google Maps)

4. **Location Flow:**
   - Get location first (GPS, map center, or search result)
   - Location obtained via Google Maps API (browser geolocation or map)
   - THEN call validation API with those coordinates
   - THEN update UI based on validation result

5. **Required Query Parameters:**
   - Validation API REQUIRES `lat` and `lng` query parameters
   - Backend accepts both `lat`/`lng` and `latitude`/`longitude`
   - Always include coordinates in validation calls

6. **Button State:**
   - Enabled: When `zone_ids` array is not empty
   - Disabled: When `zone_ids` array is empty or validation fails

7. **Google Maps Services:**
   - Map display: Google Maps JavaScript API
   - Address search: Google Places API (autocomplete)
   - Reverse geocoding: Google Geocoding API
   - All require Google Maps API key
   - Called directly from browser (client-side)

---

**Last Updated:** 2025-01-27
**Version:** 1.0.0
**Target Audience:** Web/TypeScript Development Team
