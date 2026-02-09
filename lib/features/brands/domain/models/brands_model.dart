import 'package:sixam_mart/common/utils/json_parser.dart';
import 'package:sixam_mart/util/app_constants.dart';

class BrandModel {
  int? id;
  String? name;
  String? slug;
  String? imageFullUrl;
  int? status;
  String? createdAt;
  String? updatedAt;
  int? itemsCount;
  List<Translations>? translations;

  BrandModel({
    this.id,
    this.name,
    this.slug,
    this.imageFullUrl,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.itemsCount,
    this.translations,
  });

  BrandModel.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    name = json.parseString('name');
    slug = json.parseString('slug');
    
    // ⚡ BFF API v2: Prioritize image_full_url field (backend now provides full URLs)
    // The API now provides image_full_url as the primary field with complete URLs
    String? imageUrl = json.parseString('image_full_url');
    
    // Fallback to 'image' field if image_full_url is not provided (backward compatibility)
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = json.parseString('image');
    }
    
    // Handle empty string as null
    if (imageUrl == null || imageUrl.isEmpty) {
      imageFullUrl = null;
    } else {
      // ⚡ CRITICAL: Backend now provides FULL URLs - trust them completely
      // If URL starts with http/https, use as-is (backend provides complete URLs)
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        imageFullUrl = imageUrl;
      } else {
        // Relative path - construct full URL (fallback for old API responses)
        // Use /storage/brand/ path (Laravel symlink maps this correctly)
        final cleanedImage = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;
        imageFullUrl = '${AppConstants.baseUrl}/storage/brand/$cleanedImage';
      }
      
      // Debug print removed - URL hardening verified working
    }
    
    status = json.parseInt('status');
    createdAt = json.parseString('created_at');
    updatedAt = json.parseString('updated_at');
    itemsCount = json.parseInt('items_count');
    final List<Map<String, dynamic>> translationList = json.parseMapList('translations');
    if (translationList.isNotEmpty) {
      translations = translationList.map((Map<String, dynamic> v) => Translations.fromJson(v)).toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['slug'] = slug;
    data['image_full_url'] = imageFullUrl;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['items_count'] = itemsCount;
    if (translations != null) {
      data['translations'] = translations!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Translations {
  int? id;
  String? translationableType;
  int? translationableId;
  String? locale;
  String? key;
  String? value;
  String? createdAt;
  String? updatedAt;

  Translations({
    this.id,
    this.translationableType,
    this.translationableId,
    this.locale,
    this.key,
    this.value,
    this.createdAt,
    this.updatedAt,
  });

  Translations.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    translationableType = json.parseString('translationable_type');
    translationableId = json.parseInt('translationable_id');
    locale = json.parseString('locale');
    key = json.parseString('key');
    value = json.parseString('value');
    createdAt = json.parseString('created_at');
    updatedAt = json.parseString('updated_at');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['translationable_type'] = translationableType;
    data['translationable_id'] = translationableId;
    data['locale'] = locale;
    data['key'] = key;
    data['value'] = value;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}