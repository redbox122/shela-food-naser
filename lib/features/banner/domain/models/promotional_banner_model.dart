class PromotionalBanner {
  String? basicSectionNearbyFullUrl;
  String? bottomSectionBannerFullUrl;
  String? bottomSectionBannerLink;
  String? basicSectionNearbyLink;

  PromotionalBanner({
    this.basicSectionNearbyFullUrl,
    this.bottomSectionBannerFullUrl,
    this.bottomSectionBannerLink,
    this.basicSectionNearbyLink,
  });

  PromotionalBanner.fromJson(Map<String, dynamic> json) {
    // ⚡ BFF API v2: Use 'image_full_url' if provided, otherwise fallback to specific keys
    basicSectionNearbyFullUrl = (json['image_full_url'] ?? json['basic_section_nearby_full_url'])?.toString();
    bottomSectionBannerFullUrl = (json['image_full_url'] ?? json['bottom_section_banner_full_url'])?.toString();
    bottomSectionBannerLink = (json['bottom_section_banner_link'] ?? json['link'])?.toString();
    basicSectionNearbyLink = json['basic_section_nearby_link']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['basic_section_nearby_full_url'] = basicSectionNearbyFullUrl;
    data['bottom_section_banner_full_url'] = bottomSectionBannerFullUrl;
    data['bottom_section_banner_link'] = bottomSectionBannerLink;
    data['basic_section_nearby_link'] = basicSectionNearbyLink;
    return data;
  }
}