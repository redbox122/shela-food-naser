class BusinessSettingsModel {
  final dynamic categoriesSection;
  final dynamic bannersSection;
  final dynamic visitAgainSection;
  final dynamic popularProductsSection;
  final dynamic flashSalesSection;
  final dynamic campaignsBasicSection;
  final dynamic advertisementListSection;
  final dynamic popularStoresSection;
  final dynamic brandSection;
  final dynamic discountedProductsSection;
  final dynamic mostReviewedProductsSection;
  final dynamic topStoresOffersNearMeSection;
  final dynamic featuredProductsSection;
  // NEW: Module-specific sections (added in v2 API)
  final dynamic topRestaurantsSection;
  final dynamic allRestaurantsSection;
  final dynamic allStoresSection;
  final dynamic offersSection;

  BusinessSettingsModel({
    this.categoriesSection = 1,
    this.bannersSection = 1,
    this.visitAgainSection = 1,
    this.popularProductsSection = 1,
    this.flashSalesSection = 1,
    this.campaignsBasicSection = 1,
    this.advertisementListSection = 1,
    this.popularStoresSection = 1,
    this.brandSection = 1,
    this.discountedProductsSection = 1,
    this.mostReviewedProductsSection = 1,
    this.topStoresOffersNearMeSection = 1,
    this.featuredProductsSection = 1,
    this.topRestaurantsSection = 0,
    this.allRestaurantsSection = 0,
    this.allStoresSection = 0,
    this.offersSection = 0,
  });

  factory BusinessSettingsModel.fromJson(Map<String, dynamic> json) {
    // 🔧 FIX 2: Default to enabled (1) for core sections when API returns null
    // This ensures food and ecommerce modules show categories, banners, etc.
    // even if the backend doesn't explicitly return these flags
    return BusinessSettingsModel(
      categoriesSection: json['categories_section'] ?? 1,
      bannersSection: json['banners_section'] ?? 1,
      visitAgainSection: json['visit_again_section'] ?? 1,
      popularProductsSection: json['popular_products_section'] ?? 1,
      flashSalesSection: json['flash_sales_section'] ?? 1,
      campaignsBasicSection: json['campaigns_basic_section'] ?? 1,
      advertisementListSection: json['advertisement_list_section'] ?? 1,
      popularStoresSection: json['popular_stores_section'] ?? 1,
      brandSection: json['brand_section'] ?? 1,
      discountedProductsSection: json['discounted_products_section'] ?? 1,
      mostReviewedProductsSection: json['most_reviewed_products_section'] ?? 1,
      topStoresOffersNearMeSection: json['top_stores_offers_near_me_section'] ?? 1,
      featuredProductsSection: json['featured_products_section'] ?? 1,
      // NEW: Module-specific sections (v2 API) - default to 0 (disabled)
      topRestaurantsSection: json['top_restaurants_section'] ?? 0,
      allRestaurantsSection: json['all_restaurants_section'] ?? 0,
      allStoresSection: json['all_stores_section'] ?? 0,
      offersSection: json['offers_section'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories_section': categoriesSection,
      'banners_section': bannersSection,
      'visit_again_section': visitAgainSection,
      'popular_products_section': popularProductsSection,
      'flash_sales_section': flashSalesSection,
      'campaigns_basic_section': campaignsBasicSection,
      'advertisement_list_section': advertisementListSection,
      'popular_stores_section': popularStoresSection,
      'brand_section': brandSection,
      'discounted_products_section': discountedProductsSection,
      'most_reviewed_products_section': mostReviewedProductsSection,
      'top_stores_offers_near_me_section': topStoresOffersNearMeSection,
      'featured_products_section': featuredProductsSection,
      // NEW: Module-specific sections (v2 API)
      'top_restaurants_section': topRestaurantsSection,
      'all_restaurants_section': allRestaurantsSection,
      'all_stores_section': allStoresSection,
      'offers_section': offersSection,
    };
  }
}
