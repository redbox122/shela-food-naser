/// Home Data Source Enum
/// 
/// Defines the source of home screen data:
/// - unified: Uses /api/v2/home-unified endpoint (preferred)
/// - partial: Uses individual API endpoints (fallback)
enum HomeDataSource {
  /// Unified endpoint - single API call for all home data
  unified,
  
  /// Partial endpoints - individual API calls (fallback)
  partial,
}

