# App Logging System Documentation

## Overview

The app logging system provides comprehensive logging functionality including:
- **Log filtering and throttling** for system logs (EGL_emulation, etc.)
- **Page lifecycle tracking** - automatic logging when pages are entered/exited
- **API call tracking** - detailed logging of all API calls with timing and response info
- **Performance metrics** - track page duration and API call counts

## Features

### 1. Log Filtering & Throttling

The logger automatically filters and throttles frequent system logs (like EGL_emulation) to appear once every 20 seconds instead of continuously.

**Note:** EGL_emulation logs are Android system-level logs that come directly from the emulator. While we can't completely suppress them, our logger throttles them when they pass through our logging system.

### 2. Page Lifecycle Tracking

Automatically track when pages are entered and exited, including:
- Page name
- Time spent on page
- Number of API calls made on the page
- List of API calls made

### 3. API Call Logging

Every API call is logged with:
- HTTP method (GET, POST, etc.)
- Full URI
- Query parameters
- Headers (keys only for privacy)
- Response status code
- Response time in milliseconds
- Response size
- Error details (if any)

## Usage

### Basic Logging

```dart
import 'package:sixam_mart/common/utils/app_logger.dart';

// Debug log
appLogger.debug('Debug message');

// Info log
appLogger.info('Info message');

// Warning log
appLogger.warning('Warning message');

// Error log
appLogger.error('Error message', error, stackTrace);
```

### Page Lifecycle Tracking

Use the `PageLifecycleMixin` in your StatefulWidget State classes:

```dart
import 'package:sixam_mart/common/utils/page_lifecycle_mixin.dart';

class _MyPageState extends State<MyPage> with PageLifecycleMixin {
  @override
  void initState() {
    super.initState();
    initializePageLifecycle('MyPage'); // Automatically logs page entry
  }
  
  // Page exit is automatically logged in dispose()
}
```

### API Call Logging

API calls are automatically logged by the `ApiClient`. No additional code needed!

The logger will show:
```
[12:34:56][MyPage] 🌐 API → GET /api/v1/stores
[12:34:57][MyPage] 🌐 API ✓ GET /api/v1/stores | Status: 200 | Time: 234ms | Size: 1234B
```

### Custom Page Events

```dart
class _MyPageState extends State<MyPage> with PageLifecycleMixin {
  void _onButtonClick() {
    logPageEvent('Button Clicked', {'button': 'submit'});
  }
}
```

## Log Format

All logs follow this format:
```
[HH:MM:SS][PageName] LEVEL Message
```

Example:
```
[12:34:56][HomeScreen] 📱 PAGE Entered page: HomeScreen
[12:34:57][HomeScreen] 🌐 API → GET /api/v1/stores
[12:34:58][HomeScreen] 🌐 API ✓ GET /api/v1/stores | Status: 200 | Time: 234ms
[12:35:10][HomeScreen] 📱 PAGE Exited page: HomeScreen | Duration: 14s | API Calls: 3
```

## Log Levels

- 🔍 **DEBUG** - Detailed debugging information
- ℹ️ **INFO** - General information
- ⚠️ **WARN** - Warning messages
- ❌ **ERROR** - Error messages
- 🌐 **API** - API call logs
- 📱 **PAGE** - Page lifecycle logs

## Configuration

The logger is initialized in `main.dart` with these defaults:
- `enableLogging: true` - Enable/disable all logging
- `filterEGLLogs: true` - Filter EGL_emulation logs
- `enablePageLogging: true` - Enable page lifecycle logging
- `enableApiLogging: true` - Enable API call logging

## API Call History

You can retrieve API call history:

```dart
// Get API calls for current page
final currentCalls = appLogger.getCurrentPageApiCalls();

// Get API calls for specific page
final pageCalls = appLogger.getPageApiCalls('HomeScreen');

// Clear history
appLogger.clearApiCallHistory();
```

## Example: Complete Page Implementation

```dart
import 'package:flutter/material.dart';
import 'package:sixam_mart/common/utils/page_lifecycle_mixin.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with PageLifecycleMixin {
  @override
  void initState() {
    super.initState();
    initializePageLifecycle('MyPage');
    
    // Your initialization code
    _loadData();
  }
  
  Future<void> _loadData() async {
    appLogger.info('Loading data for MyPage');
    // Your API calls will be automatically logged
    // ...
  }
  
  void _onAction() {
    logPageEvent('Action Performed', {'action': 'click'});
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Your UI
    );
  }
  
  // dispose() automatically logs page exit
}
```

## Benefits

1. **Better Debugging** - See exactly what's happening in your app
2. **Performance Monitoring** - Track page load times and API call performance
3. **Issue Tracking** - Identify which pages make which API calls
4. **Cleaner Logs** - Filtered and throttled logs reduce noise
5. **Automatic Tracking** - No need to manually add logging code for API calls

## Notes

- Logging is automatically disabled in release builds (`kDebugMode` check)
- EGL_emulation logs are system-level and may still appear, but are throttled
- API call logging includes timing information for performance analysis
- Page tracking helps identify performance bottlenecks











