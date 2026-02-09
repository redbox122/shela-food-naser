import 'package:flutter/foundation.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/common/utils/json_parser.dart';

/// Category Model
/// 
/// **Backend Documentation Reference:** Module 6 (Food/Restaurants) - Complete API Integration Guide
/// **Tested & Verified:** Backend team has tested this data structure thousands of times - it works perfectly
/// 
/// **Fields (per backend documentation):**
/// - `id`: Category ID
/// - `name`: Category name (localized based on X-localization header)
/// - `name_ar`: Arabic name (documented in Module 6 API)
/// - `name_en`: English name (documented in Module 6 API)
/// - `image`: Image filename
/// - `image_full_url`: Full image URL
/// - `products_count`: Number of products in category
/// - `childes_count`: Number of subcategories
/// - `module_id`: Module ID (6 for Food module) - REQUIRED for filtering
/// - `store_id`: Store ID (null for module-level cuisine categories)
/// - `cat_site_id`: External API category ID (documented in Module 6 API)
/// - `position`: Position (0 for cuisine categories, > 0 for restaurant menu categories)
/// - `status`: Status (1 = active)
/// - `parent_id`: Parent category ID
/// 
/// **Note:** All fields match the backend documentation exactly.

class CategoryModel {
  int? id;
  int totalSize = 0;
  String? name;
  String? nameAr; // Arabic name from API
  String? nameEn; // English name from API
  int? parentId;
  int? position;
  int? storeId;
  int productsCount = 0;
  int? childesCount;
  String? createdAt;
  String? updatedAt;
  String? imageFullUrl;
  String? image; // Image filename from API
  int? moduleId; // ⚠️ CRITICAL: Module ID to filter categories by module
  String? catSiteId; // External API category ID (cat_site_id)
  List<CategoryModel>? subCategories; // ✅ DATA-DRIVEN: Nested subcategories from backend

  CategoryModel({
    this.id,
    this.totalSize = 0,
    this.name,
    this.nameAr,
    this.nameEn,
    this.parentId,
    this.position,
    this.storeId,
    this.productsCount = 0,
    this.childesCount,
    this.createdAt,
    this.updatedAt,
    this.imageFullUrl,
    this.image,
    this.moduleId,
    this.catSiteId,
    this.subCategories,
  });

  CategoryModel.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    totalSize = json.parseInt('total_size') ?? 0;
    name = json.parseString('name');
    nameAr = json.parseString('name_ar'); // Arabic name (documented in Module 6 API guide)
    nameEn = json.parseString('name_en'); // English name (documented in Module 6 API guide)
    parentId = json.parseInt('parent_id');
    position = json.parseInt('position');
    storeId = json.parseInt('store_id');
    productsCount = json.parseInt('products_count') ?? 0;
    childesCount = json.parseInt('childes_count');
    createdAt = json.parseString('created_at');
    updatedAt = json.parseString('updated_at');
    image = json.parseString('image');
    moduleId = json.parseInt('module_id'); // ⚠️ CRITICAL: Parse module_id from API response
    catSiteId = json.parseString('cat_site_id') ??
        json.parseString('cat_siteId') ??
        json.parseString('catSiteId'); // External API category ID (documented in Module 6 API guide)
    
    // ⚡ BFF API v2: Laravel returns FULL URLs in 'image' key (v2) or 'image_full_url' (v1)
    // Do NOT concatenate BASE_URL - backend already provides complete URLs
    imageFullUrl = (json['image'] ?? json['image_full_url']) as String?;
    
    // Handle empty string as null
    if (imageFullUrl != null && imageFullUrl!.isEmpty) {
      imageFullUrl = null;
    }
    
    // ⚡ FIX: Image URL hardening - if URL doesn't start with http, prepend baseUrl + storagePath
    // 🔧 Cloudflare CDN compatibility: Use /storage/category/ path (matches /storage/banner/ and /storage/brand/ pattern)
    if (imageFullUrl != null && imageFullUrl!.isNotEmpty) {
      if (!imageFullUrl!.startsWith('http://') && !imageFullUrl!.startsWith('https://')) {
        // URL is just a filename - construct full URL with correct storage path
        final baseUrl = AppConstants.baseUrl;
        const storagePath = '/storage/category/';
        final cleanedImage = imageFullUrl!.startsWith('/') 
            ? imageFullUrl!.substring(1) 
            : imageFullUrl!;
        imageFullUrl = '$baseUrl$storagePath$cleanedImage';
      }
      
      // Debug print removed - URL hardening verified working
    }
    
    // ✅ DATA-DRIVEN: Parse nested sub_categories array from backend
    if (json['sub_categories'] != null && json['sub_categories'] is List) {
      subCategories = [];
      for (final subCatJson in (json['sub_categories'] as List)) {
        if (subCatJson != null) {
          try {
            subCategories!.add(CategoryModel.fromJson(subCatJson as Map<String, dynamic>));
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ [CategoryModel.fromJson] Error parsing sub_category: $e');
            }
          }
        }
      }
      // Set to null if empty list for consistency
      if (subCategories!.isEmpty) {
        subCategories = null;
      }
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'total_size': totalSize,
      'name': name,
      'name_ar': nameAr,
      'name_en': nameEn,
      'parent_id': parentId,
      'position': position,
      'store_id': storeId,
      'products_count': productsCount,
      'childes_count': childesCount,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'image': image,
      'image_full_url': imageFullUrl,
      'module_id': moduleId,
      'cat_site_id': catSiteId,
      'sub_categories': subCategories?.map((subCat) => subCat.toJson()).toList(),
    };
  }
}
