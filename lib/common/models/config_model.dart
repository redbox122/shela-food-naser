import 'package:sixam_mart/common/models/module_model.dart';

class ConfigModel {
  String? businessName;
  String? logoFullUrl;
  String? address;
  String? phone;
  String? email;
  String? country;
  DefaultLocation? defaultLocation;
  String? currencySymbol;
  String? currencySymbolDirection;
  double? appMinimumVersionAndroid;
  String? appUrlAndroid;
  double? appMinimumVersionIos;
  String? appUrlIos;
  bool? customerVerification;
  bool? scheduleOrder;
  bool? orderDeliveryVerification;
  bool? cashOnDelivery;
  bool? digitalPayment;
  double? perKmShippingCharge;
  double? minimumShippingCharge;
  double? freeDeliveryOver;
  bool? demo;
  bool? maintenanceMode;
  String? orderConfirmationModel;
  bool? showDmEarning;
  bool? canceledByDeliveryman;
  String? timeformat;
  List<Language>? language;
  bool? toggleVegNonVeg;
  bool? toggleDmRegistration;
  bool? toggleStoreRegistration;
  int? scheduleOrderSlotDuration;
  int? digitAfterDecimalPoint;
  double? parcelPerKmShippingCharge;
  double? parcelMinimumShippingCharge;
  ModuleModel? module;
  ModuleConfig? moduleConfig;
  LandingPageSettings? landingPageSettings;
  List<SocialMedia>? socialMedia;
  String? footerText;
  LandingPageLinks? landingPageLinks;
  int? loyaltyPointExchangeRate;
  double? loyaltyPointItemPurchasePoint;
  int? loyaltyPointStatus;
  int? minimumPointToTransfer;
  int? customerWalletStatus;
  int? dmTipsStatus;
  int? refEarningStatus;
  double? refEarningExchangeRate;
  List<SocialLogin>? socialLogin;
  List<SocialLogin>? appleLogin;
  bool? refundActiveStatus;
  int? refundPolicyStatus;
  int? cancellationPolicyStatus;
  int? shippingPolicyStatus;
  bool? prescriptionStatus;
  int? taxIncluded;
  String? cookiesText;
  int? homeDeliveryStatus;
  int? takeawayStatus;
  bool? partialPaymentStatus;
  String? partialPaymentMethod;
  bool? additionalChargeStatus;
  String? additionalChargeName;
  double? additionCharge;
  List<PaymentBody>? activePaymentMethodList;
  DigitalPaymentInfo? digitalPaymentInfo;
  bool? addFundStatus;
  bool? offlinePaymentStatus;
  bool? guestCheckoutStatus;

  double? adminCommission;
  int? subscriptionFreeTrialDays;
  bool? subscriptionFreeTrialStatus;
  int? subscriptionBusinessModel;
  int? commissionBusinessModel;
  String? subscriptionFreeTrialType;
  bool? countryPickerStatus;
  bool? firebaseOtpVerification;
  CentralizeLoginSetup? centralizeLoginSetup;
  double? vehicleDistanceMinPrice;
  double? vehicleHourlyMinPrice;

  ConfigModel({
    this.businessName,
    this.logoFullUrl,
    this.address,
    this.phone,
    this.email,
    this.country,
    this.defaultLocation,
    this.currencySymbol,
    this.currencySymbolDirection,
    this.appMinimumVersionAndroid,
    this.appUrlAndroid,
    this.appMinimumVersionIos,
    this.appUrlIos,
    this.customerVerification,
    this.scheduleOrder,
    this.orderDeliveryVerification,
    this.cashOnDelivery,
    this.digitalPayment,
    this.perKmShippingCharge,
    this.minimumShippingCharge,
    this.freeDeliveryOver,
    this.demo,
    this.maintenanceMode,
    this.orderConfirmationModel,
    this.showDmEarning,
    this.canceledByDeliveryman,
    this.timeformat,
    this.language,
    this.toggleVegNonVeg,
    this.toggleDmRegistration,
    this.toggleStoreRegistration,
    this.scheduleOrderSlotDuration,
    this.digitAfterDecimalPoint,
    this.module,
    this.moduleConfig,
    this.parcelPerKmShippingCharge,
    this.parcelMinimumShippingCharge,
    this.landingPageSettings,
    this.socialMedia,
    this.footerText,
    this.landingPageLinks,
    this.loyaltyPointExchangeRate,
    this.loyaltyPointItemPurchasePoint,
    this.loyaltyPointStatus,
    this.minimumPointToTransfer,
    this.customerWalletStatus,
    this.dmTipsStatus,
    this.refEarningStatus,
    this.refEarningExchangeRate,
    this.socialLogin,
    this.appleLogin,
    this.refundActiveStatus,
    this.refundPolicyStatus,
    this.cancellationPolicyStatus,
    this.shippingPolicyStatus,
    this.prescriptionStatus,
    this.taxIncluded,
    this.cookiesText,
    this.homeDeliveryStatus,
    this.takeawayStatus,
    this.partialPaymentStatus,
    this.partialPaymentMethod,
    this.additionalChargeStatus,
    this.additionalChargeName,
    this.additionCharge,
    this.activePaymentMethodList,
    this.digitalPaymentInfo,
    this.addFundStatus,
    this.offlinePaymentStatus,
    this.guestCheckoutStatus,
    this.subscriptionFreeTrialDays,
    this.subscriptionFreeTrialStatus,
    this.subscriptionBusinessModel,
    this.commissionBusinessModel,
    this.subscriptionFreeTrialType,
    this.countryPickerStatus,
    this.firebaseOtpVerification,
    this.centralizeLoginSetup,
    this.vehicleDistanceMinPrice,
    this.vehicleHourlyMinPrice,
  });

  ConfigModel.fromJson(Map<String, dynamic> json) {
    businessName = json['business_name']?.toString();
    logoFullUrl = json['logo_full_url']?.toString();
    address = json['address']?.toString();
    phone = json['phone']?.toString();
    email = json['email']?.toString();
    country = json['country']?.toString();

    defaultLocation = json['default_location'] != null
        ? DefaultLocation.fromJson(
            json['default_location'] as Map<String, dynamic>)
        : null;

    currencySymbol = json['currency_symbol']?.toString();
    currencySymbolDirection = json['currency_symbol_direction']?.toString();

    appMinimumVersionAndroid = double.tryParse(
            json['app_minimum_version_android']?.toString() ?? '0') ??
        0.0;
    appUrlAndroid = json['app_url_android']?.toString();

    appMinimumVersionIos =
        double.tryParse(json['app_minimum_version_ios']?.toString() ?? '0') ??
            0.0;
    appUrlIos = json['app_url_ios']?.toString();

    final cv = json['customer_verification'];
    customerVerification = cv == true || cv == 1 || cv?.toString() == '1';

    final so = json['schedule_order'];
    scheduleOrder = so == true || so == 1 || so?.toString() == '1';

    final odv = json['order_delivery_verification'];
    orderDeliveryVerification = odv == true || odv == 1 || odv?.toString() == '1';

    final cod = json['cash_on_delivery'];
    cashOnDelivery = cod == true || cod == 1 || cod?.toString() == '1';

    final dp = json['digital_payment'];
    digitalPayment = dp == true || dp == 1 || dp?.toString() == '1';

    perKmShippingCharge =
        double.tryParse(json['per_km_shipping_charge']?.toString() ?? '');
    minimumShippingCharge =
        double.tryParse(json['minimum_shipping_charge']?.toString() ?? '');
    freeDeliveryOver =
        double.tryParse(json['free_delivery_over']?.toString() ?? '');

    demo = json['demo'] == true || json['demo'] == 1 || json['demo'] == '1';
    maintenanceMode = json['maintenance_mode'] == true ||
        json['maintenance_mode'] == 1 ||
        json['maintenance_mode'] == '1';

    orderConfirmationModel = json['order_confirmation_model']?.toString();
    showDmEarning = json['show_dm_earning'] == true ||
        json['show_dm_earning'] == 1 ||
        json['show_dm_earning'] == '1';

    canceledByDeliveryman = json['canceled_by_deliveryman'] == true ||
        json['canceled_by_deliveryman'] == 1 ||
        json['canceled_by_deliveryman'] == '1';

    timeformat = json['timeformat']?.toString();

    if (json['language'] is List) {
      language = (json['language'] as List)
          .map((v) => Language.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    toggleVegNonVeg = json['toggle_veg_non_veg'] == true ||
        json['toggle_veg_non_veg'] == 1 ||
        json['toggle_veg_non_veg'] == '1';

    toggleDmRegistration = json['toggle_dm_registration'] == true ||
        json['toggle_dm_registration'] == 1 ||
        json['toggle_dm_registration'] == '1';

    toggleStoreRegistration = json['toggle_store_registration'] == true ||
        json['toggle_store_registration'] == 1 ||
        json['toggle_store_registration'] == '1';

    scheduleOrderSlotDuration =
        int.tryParse(json['schedule_order_slot_duration']?.toString() ?? '') ??
            30;

    digitAfterDecimalPoint =
        int.tryParse(json['digit_after_decimal_point']?.toString() ?? '');

    module = json['module'] != null
        ? ModuleModel.fromJson(json['module'] as Map<String, dynamic>)
        : null;

    moduleConfig = json['module_config'] != null
        ? ModuleConfig.fromJson(json['module_config'] as Map<String, dynamic>)
        : null;

    parcelPerKmShippingCharge = double.tryParse(
        json['parcel_per_km_shipping_charge']?.toString() ?? '');
    parcelMinimumShippingCharge = double.tryParse(
        json['parcel_minimum_shipping_charge']?.toString() ?? '');

    landingPageSettings = json['landing_page_settings'] != null
        ? LandingPageSettings.fromJson(
            json['landing_page_settings'] as Map<String, dynamic>)
        : null;

    if (json['social_media'] is List) {
      socialMedia = (json['social_media'] as List)
          .map((v) => SocialMedia.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    footerText = json['footer_text']?.toString();

    landingPageLinks = json['landing_page_links'] != null
        ? LandingPageLinks.fromJson(
            json['landing_page_links'] as Map<String, dynamic>)
        : null;

    loyaltyPointExchangeRate =
        int.tryParse(json['loyalty_point_exchange_rate']?.toString() ?? '');

    loyaltyPointItemPurchasePoint = double.tryParse(
        json['loyalty_point_item_purchase_point']?.toString() ?? '');

    loyaltyPointStatus =
        int.tryParse(json['loyalty_point_status']?.toString() ?? '');

    minimumPointToTransfer =
        int.tryParse(json['loyalty_point_minimum_point']?.toString() ?? '');

    customerWalletStatus =
        int.tryParse(json['customer_wallet_status']?.toString() ?? '');

    dmTipsStatus = int.tryParse(json['dm_tips_status']?.toString() ?? '');
    refEarningStatus =
        int.tryParse(json['ref_earning_status']?.toString() ?? '');

    refundActiveStatus = json['refund_active_status'] == true ||
        json['refund_active_status'] == 1 ||
        json['refund_active_status'] == '1';

    refEarningExchangeRate =
        double.tryParse(json['ref_earning_exchange_rate']?.toString() ?? '');

    if (json['social_login'] is List) {
      socialLogin = (json['social_login'] as List)
          .map((v) => SocialLogin.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    if (json['apple_login'] is List) {
      appleLogin = (json['apple_login'] as List)
          .map((v) => SocialLogin.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    refundPolicyStatus = int.tryParse(json['refund_policy']?.toString() ?? '');
    cancellationPolicyStatus =
        int.tryParse(json['cancelation_policy']?.toString() ?? '');
    shippingPolicyStatus =
        int.tryParse(json['shipping_policy']?.toString() ?? '');

    prescriptionStatus = json['prescription_order_status'] == true ||
        json['prescription_order_status'] == 1 ||
        json['prescription_order_status'] == '1';

    taxIncluded = int.tryParse(json['tax_included']?.toString() ?? '');
    cookiesText = json['cookies_text']?.toString();
    homeDeliveryStatus =
        int.tryParse(json['home_delivery_status']?.toString() ?? '');
    takeawayStatus = int.tryParse(json['takeaway_status']?.toString() ?? '');

    partialPaymentStatus = json['partial_payment_status'] == true ||
        json['partial_payment_status'] == 1 ||
        json['partial_payment_status'] == '1';

    partialPaymentMethod = json['partial_payment_method']?.toString();

    final acs = json['additional_charge_status'];
    additionalChargeStatus = acs == true || acs == 1 || acs?.toString() == '1';

    additionalChargeName = json['additional_charge_name']?.toString();
    additionCharge =
        double.tryParse(json['additional_charge']?.toString() ?? '') ?? 0.0;

    if (json['active_payment_method_list'] is List) {
      activePaymentMethodList = (json['active_payment_method_list'] as List)
          .map((v) => PaymentBody.fromJson(v as Map<String, dynamic>))
          .toList();
    }

    digitalPaymentInfo = json['digital_payment_info'] != null
        ? DigitalPaymentInfo.fromJson(
            json['digital_payment_info'] as Map<String, dynamic>)
        : null;

    addFundStatus = json['add_fund_status'] == 1;
    offlinePaymentStatus = json['offline_payment_status'] == 1;
    guestCheckoutStatus = json['guest_checkout_status'] == 1;

    adminCommission =
        double.tryParse(json['admin_commission']?.toString() ?? '');

    subscriptionFreeTrialDays =
        int.tryParse(json['subscription_free_trial_days']?.toString() ?? '');

    subscriptionFreeTrialStatus = json['subscription_free_trial_status'] == 1;

    subscriptionBusinessModel =
        int.tryParse(json['subscription_business_model']?.toString() ?? '');

    commissionBusinessModel =
        int.tryParse(json['commission_business_model']?.toString() ?? '');

    subscriptionFreeTrialType =
        json['subscription_free_trial_type']?.toString();

    countryPickerStatus = json['country_picker_status'] == 1;
    firebaseOtpVerification = json['firebase_otp_verification'] == 1;

    centralizeLoginSetup = json['centralize_login'] != null
        ? CentralizeLoginSetup.fromJson(
            json['centralize_login'] as Map<String, dynamic>)
        : null;

    vehicleDistanceMinPrice =
        double.tryParse(json['vehicle_distance_min']?.toString() ?? '');
    vehicleHourlyMinPrice =
        double.tryParse(json['vehicle_hourly_min']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['business_name'] = businessName;
    data['logo_full_url'] = logoFullUrl;
    data['address'] = address;
    data['phone'] = phone;
    data['email'] = email;
    data['country'] = country;
    if (defaultLocation != null) {
      data['default_location'] = defaultLocation!.toJson();
    }
    data['currency_symbol'] = currencySymbol;
    data['currency_symbol_direction'] = currencySymbolDirection;
    data['app_minimum_version_android'] = appMinimumVersionAndroid;
    data['app_url_android'] = appUrlAndroid;
    data['app_minimum_version_ios'] = appMinimumVersionIos;
    data['app_url_ios'] = appUrlIos;
    data['customer_verification'] = customerVerification;
    data['schedule_order'] = scheduleOrder;
    data['order_delivery_verification'] = orderDeliveryVerification;
    data['cash_on_delivery'] = cashOnDelivery;
    data['digital_payment'] = digitalPayment;
    data['per_km_shipping_charge'] = perKmShippingCharge;
    data['minimum_shipping_charge'] = minimumShippingCharge;
    data['free_delivery_over'] = freeDeliveryOver;
    data['demo'] = demo;
    data['maintenance_mode'] = maintenanceMode;
    data['order_confirmation_model'] = orderConfirmationModel;
    data['show_dm_earning'] = showDmEarning;
    data['canceled_by_deliveryman'] = canceledByDeliveryman;
    data['timeformat'] = timeformat;
    if (language != null) {
      data['language'] = language!.map((v) => v.toJson()).toList();
    }
    data['toggle_veg_non_veg'] = toggleVegNonVeg;
    data['toggle_dm_registration'] = toggleDmRegistration;
    data['toggle_store_registration'] = toggleStoreRegistration;
    data['schedule_order_slot_duration'] = scheduleOrderSlotDuration;
    data['digit_after_decimal_point'] = digitAfterDecimalPoint;
    if (module != null) {
      data['module'] = module!.toJson();
    }
    if (moduleConfig != null) {
      data['module_config'] = moduleConfig!.toJson();
    }
    data['parcel_per_km_shipping_charge'] = parcelPerKmShippingCharge;
    data['parcel_minimum_shipping_charge'] = parcelMinimumShippingCharge;
    if (landingPageSettings != null) {
      data['landing_page_settings'] = landingPageSettings!.toJson();
    }
    if (socialMedia != null) {
      data['social_media'] = socialMedia!.map((v) => v.toJson()).toList();
    }
    data['footer_text'] = footerText;
    if (landingPageLinks != null) {
      data['landing_page_links'] = landingPageLinks!.toJson();
    }
    data['loyalty_point_exchange_rate'] = loyaltyPointExchangeRate;
    data['loyalty_point_item_purchase_point'] = loyaltyPointItemPurchasePoint;
    data['loyalty_point_status'] = loyaltyPointStatus;
    data['loyalty_point_minimum_point'] = minimumPointToTransfer;
    data['customer_wallet_status'] = customerWalletStatus;
    data['dm_tips_status'] = dmTipsStatus;
    data['ref_earning_status'] = refEarningStatus;
    data['ref_earning_exchange_rate'] = refEarningExchangeRate;
    data['refund_active_status'] = refundActiveStatus;
    if (socialLogin != null) {
      data['social_login'] = socialLogin!.map((v) => v.toJson()).toList();
    }
    if (appleLogin != null) {
      data['apple_login'] = appleLogin!.map((v) => v.toJson()).toList();
    }
    data['tax_included'] = taxIncluded;
    data['cookies_text'] = cookiesText;
    data['home_delivery_status'] = homeDeliveryStatus;
    data['takeaway_status'] = takeawayStatus;
    data['partial_payment_status'] = partialPaymentStatus;
    data['partial_payment_method'] = partialPaymentMethod;
    data['additional_charge_status'] = additionalChargeStatus;
    data['additional_charge_name'] = additionalChargeName;
    data['additional_charge'] = additionCharge;
    if (activePaymentMethodList != null) {
      data['active_payment_method_list'] =
          activePaymentMethodList!.map((v) => v.toJson()).toList();
    }
    if (digitalPaymentInfo != null) {
      data['digital_payment_info'] = digitalPaymentInfo!.toJson();
    }
    data['add_fund_status'] = addFundStatus;
    data['offline_payment_status'] = offlinePaymentStatus;
    data['guest_checkout_status'] = guestCheckoutStatus;
    data['admin_commission'] = adminCommission;
    data['subscription_free_trial_days'] = subscriptionFreeTrialDays;
    data['subscription_free_trial_status'] = subscriptionFreeTrialStatus;
    data['subscription_business_model'] = subscriptionBusinessModel;
    data['commission_business_model'] = commissionBusinessModel;
    data['subscription_free_trial_type'] = subscriptionFreeTrialType;
    data['country_picker_status'] = countryPickerStatus;
    data['firebase_otp_verification'] = firebaseOtpVerification;
    if (centralizeLoginSetup != null) {
      data['centralize_login'] = centralizeLoginSetup!.toJson();
    }
    data['vehicle_distance_min'] = vehicleDistanceMinPrice;
    data['vehicle_hourly_min'] = vehicleHourlyMinPrice;
    return data;
  }
}

class BaseUrls {
  String? itemImageUrl;
  String? customerImageUrl;
  String? bannerImageUrl;
  String? categoryImageUrl;
  String? reviewImageUrl;
  String? notificationImageUrl;
  String? vendorImageUrl;
  String? storeImageUrl;
  String? storeCoverPhotoUrl;
  String? deliveryManImageUrl;
  String? chatImageUrl;
  String? campaignImageUrl;
  String? moduleImageUrl;
  String? orderAttachmentUrl;
  String? parcelCategoryImageUrl;
  String? landingPageImageUrl;
  String? businessLogoUrl;
  String? refundImageUrl;
  String? vehicleImageUrl;
  String? vehicleBrandImageUrl;
  String? gatewayImageUrl;
  String? brandImageUrl;

  BaseUrls({
    this.itemImageUrl,
    this.customerImageUrl,
    this.bannerImageUrl,
    this.categoryImageUrl,
    this.reviewImageUrl,
    this.notificationImageUrl,
    this.vendorImageUrl,
    this.storeImageUrl,
    this.storeCoverPhotoUrl,
    this.deliveryManImageUrl,
    this.chatImageUrl,
    this.campaignImageUrl,
    this.moduleImageUrl,
    this.orderAttachmentUrl,
    this.parcelCategoryImageUrl,
    this.landingPageImageUrl,
    this.businessLogoUrl,
    this.refundImageUrl,
    this.vehicleImageUrl,
    this.vehicleBrandImageUrl,
    this.gatewayImageUrl,
    this.brandImageUrl,
  });

  BaseUrls.fromJson(Map<String, dynamic> json) {
    itemImageUrl = json['item_image_url']?.toString();
    customerImageUrl = json['customer_image_url']?.toString();
    bannerImageUrl = json['banner_image_url']?.toString();
    categoryImageUrl = json['category_image_url']?.toString();
    reviewImageUrl = json['review_image_url']?.toString();
    notificationImageUrl = json['notification_image_url']?.toString();
    vendorImageUrl = json['vendor_image_url']?.toString();
    storeImageUrl = json['store_image_url']?.toString();
    storeCoverPhotoUrl = json['store_cover_photo_url']?.toString();
    deliveryManImageUrl = json['delivery_man_image_url']?.toString();
    chatImageUrl = json['chat_image_url']?.toString();
    campaignImageUrl = json['campaign_image_url']?.toString();
    moduleImageUrl = json['module_image_url']?.toString();
    orderAttachmentUrl = json['order_attachment_url']?.toString();
    parcelCategoryImageUrl = json['parcel_category_image_url']?.toString();
    landingPageImageUrl = json['landing_page_image_url']?.toString();
    businessLogoUrl = json['business_logo_url']?.toString();
    refundImageUrl = json['refund_image_url']?.toString();
    vehicleImageUrl = json['vehicle_image_url']?.toString();
    vehicleBrandImageUrl = json['vehicle_brand_image_url']?.toString();
    gatewayImageUrl = json['gateway_image_url']?.toString();
    brandImageUrl = json['brand_image_url']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['item_image_url'] = itemImageUrl;
    data['customer_image_url'] = customerImageUrl;
    data['banner_image_url'] = bannerImageUrl;
    data['category_image_url'] = categoryImageUrl;
    data['review_image_url'] = reviewImageUrl;
    data['notification_image_url'] = notificationImageUrl;
    data['vendor_image_url'] = vendorImageUrl;
    data['store_image_url'] = storeImageUrl;
    data['store_cover_photo_url'] = storeCoverPhotoUrl;
    data['delivery_man_image_url'] = deliveryManImageUrl;
    data['chat_image_url'] = chatImageUrl;
    data['campaign_image_url'] = campaignImageUrl;
    data['module_image_url'] = moduleImageUrl;
    data['order_attachment_url'] = orderAttachmentUrl;
    data['parcel_category_image_url'] = parcelCategoryImageUrl;
    data['landing_page_image_url'] = landingPageImageUrl;
    data['business_logo_url'] = businessLogoUrl;
    data['refund_image_url'] = refundImageUrl;
    data['vehicle_image_url'] = vehicleImageUrl;
    data['vehicle_brand_image_url'] = vehicleBrandImageUrl;
    data['gateway_image_url'] = gatewayImageUrl;
    data['brand_image_url'] = brandImageUrl;
    return data;
  }
}

class DefaultLocation {
  String? lat;
  String? lng;

  DefaultLocation({this.lat, this.lng});

  DefaultLocation.fromJson(Map<String, dynamic> json) {
    lat = json['lat']?.toString();
    lng = json['lng']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['lat'] = lat;
    data['lng'] = lng;
    return data;
  }
}

class Language {
  String? key;
  String? value;

  Language({this.key, this.value});

  Language.fromJson(Map<String, dynamic> json) {
    key = json['key']?.toString();
    value = json['value']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['key'] = key;
    data['value'] = value;
    return data;
  }

  @override
  String toString() => 'Language(key: $key, value: $value)';
}

class ModuleConfig {
  List<String>? moduleType;
  Module? module;

  ModuleConfig({this.moduleType, this.module});

  ModuleConfig.fromJson(Map<String, dynamic> json) {
    // ✅ الحل 1: تحويل صريح للـ List
    moduleType = (json['module_type'] as List?)?.cast<String>();

    // ✅ الحل 2: تحويل صريح للـ Map
    module = json[moduleType?[0]] != null
        ? Module.fromJson(json[moduleType![0]] as Map<String, dynamic>)
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['module_type'] = moduleType;
    if (module != null) {
      data[moduleType![0]] = module!.toJson();
    }
    return data;
  }
}

class Module {
  int? orderPlaceToScheduleInterval; // ✅ رقم
  bool? addOn;
  bool? stock;
  bool? vegNonVeg;
  bool? unit;
  bool? orderAttachment;
  bool? showRestaurantText;
  bool? isParcel;
  bool? isTaxi;
  bool? newVariation;
  String? description;

  Module({
    this.orderPlaceToScheduleInterval,
    this.addOn,
    this.stock,
    this.vegNonVeg,
    this.unit,
    this.orderAttachment,
    this.showRestaurantText,
    this.isParcel,
    this.isTaxi,
    this.newVariation,
    this.description,
  });

  // ✅ دالة تحويل boolean
  bool? parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return null;
  }

  Module.fromJson(Map<String, dynamic> json) {
    // ✅ تحويل الرقم
final dynamic intervalValue = json['order_place_to_schedule_interval'];

if (intervalValue is int) {
  orderPlaceToScheduleInterval = intervalValue;
} else if (intervalValue is String) {
  orderPlaceToScheduleInterval = int.tryParse(intervalValue);
} else {
  orderPlaceToScheduleInterval = null;
}




    // ✅ كل القيم المنطقية
    addOn = parseBool(json['add_on']);
    stock = parseBool(json['stock']);
    vegNonVeg = parseBool(json['veg_non_veg']);
    unit = parseBool(json['unit']);
    orderAttachment = parseBool(json['order_attachment']);
    showRestaurantText = parseBool(json['show_restaurant_text']);
    isParcel = parseBool(json['is_parcel']);
    isTaxi = parseBool(json['is_taxi']) ?? false;
    newVariation = parseBool(json['new_variation']);

    // ✅ نص
    description = json['description']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['order_place_to_schedule_interval'] = orderPlaceToScheduleInterval;
    data['add_on'] = addOn;
    data['stock'] = stock;
    data['veg_non_veg'] = vegNonVeg;
    data['unit'] = unit;
    data['order_attachment'] = orderAttachment;
    data['show_restaurant_text'] = showRestaurantText;
    data['is_parcel'] = isParcel;
    data['is_taxi'] = isTaxi;
    data['new_variation'] = newVariation;
    data['description'] = description;
    return data;
  }
}


class OrderStatus {
  bool? accepted;

  OrderStatus({this.accepted});

  bool? parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return null;
  }

  OrderStatus.fromJson(Map<String, dynamic> json) {
    accepted = parseBool(json['accepted']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['accepted'] = accepted;
    return data;
  }
}


class LandingPageSettings {
  String? mobileAppSectionImage;
  String? topContentImage;

  LandingPageSettings({this.mobileAppSectionImage, this.topContentImage});

  LandingPageSettings.fromJson(Map<String, dynamic> json) {
    mobileAppSectionImage = json['mobile_app_section_image']?.toString();
    topContentImage = json['top_content_image']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['mobile_app_section_image'] = mobileAppSectionImage;
    data['top_content_image'] = topContentImage;
    return data;
  }
}


class SocialMedia {
  int? id;
  String? name;
  String? link;
  int? status;

  SocialMedia({
    this.id,
    this.name,
    this.link,
    this.status,
  });

  SocialMedia.fromJson(Map<String, dynamic> json) {
    id = json['id'] is int
        ? json['id'] as int
        : int.tryParse(json['id']?.toString() ?? '');

    name = json['name']?.toString();
    link = json['link']?.toString();

    status = json['status'] is int
        ? json['status'] as int
        : int.tryParse(json['status']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['link'] = link;
    data['status'] = status;
    return data;
  }
}


class LandingPageLinks {
  String? appUrlAndroidStatus;
  String? appUrlAndroid;
  String? appUrlIosStatus;
  String? appUrlIos;

  LandingPageLinks({
    this.appUrlAndroidStatus,
    this.appUrlAndroid,
    this.appUrlIosStatus,
    this.appUrlIos,
  });

  LandingPageLinks.fromJson(Map<String, dynamic> json) {
    appUrlAndroidStatus = json['app_url_android_status']?.toString();
    appUrlAndroid = json['app_url_android']?.toString();
    appUrlIosStatus = json['app_url_ios_status']?.toString();
    appUrlIos = json['app_url_ios']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['app_url_android_status'] = appUrlAndroidStatus;
    data['app_url_android'] = appUrlAndroid;
    data['app_url_ios_status'] = appUrlIosStatus;
    data['app_url_ios'] = appUrlIos;
    return data;
  }
}


class SocialLogin {
  String? loginMedium;
  bool? status;
  String? clientId;
  String? redirectUrl;
  bool? parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is int) return value == 1;
  if (value is String) {
    return value == '1' || value.toLowerCase() == 'true';
  }
  return null;
}


  SocialLogin({
    this.loginMedium,
    this.status,
    this.clientId,
    this.redirectUrl,
  });

  SocialLogin.fromJson(Map<String, dynamic> json) {
    loginMedium = json['login_medium']?.toString();
    status = parseBool(json['status']);
    clientId = json['client_id']?.toString();
    redirectUrl = json['redirect_url_flutter']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['login_medium'] = loginMedium;
    data['status'] = status;
    data['client_id'] = clientId;
    data['redirect_url_flutter'] = redirectUrl;
    return data;
  }
}


class PaymentBody {
  String? getWay;
  String? getWayTitle;
  String? getWayImageFullUrl;

  PaymentBody({
    this.getWay,
    this.getWayTitle,
    this.getWayImageFullUrl,
  });

  PaymentBody.fromJson(Map<String, dynamic> json) {
    getWay = json['gateway']?.toString();
    getWayTitle = json['gateway_title']?.toString();
    getWayImageFullUrl = json['gateway_image_full_url']?.toString() ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['gateway'] = getWay;
    data['gateway_title'] = getWayTitle;
    data['gateway_image_full_url'] = getWayImageFullUrl;
    return data;
  }
}


class DigitalPaymentInfo {
  bool? digitalPayment;
  bool? pluginPaymentGateways;
  bool? defaultPaymentGateways;

  DigitalPaymentInfo({
    this.digitalPayment,
    this.pluginPaymentGateways,
    this.defaultPaymentGateways,
  });

  // ✅ دالة تحويل boolean
  bool? parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return null;
  }

  DigitalPaymentInfo.fromJson(Map<String, dynamic> json) {
    digitalPayment = parseBool(json['digital_payment']);
    pluginPaymentGateways = parseBool(json['plugin_payment_gateways']);
    defaultPaymentGateways = parseBool(json['default_payment_gateways']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['digital_payment'] = digitalPayment;
    data['plugin_payment_gateways'] = pluginPaymentGateways;
    data['default_payment_gateways'] = defaultPaymentGateways;
    return data;
  }
}


class BusinessPlan {
  int? commission;
  int? subscription;

  BusinessPlan({this.commission, this.subscription});

  BusinessPlan.fromJson(Map<String, dynamic> json) {
    commission = json['commission'] is int
        ? json['commission'] as int
        : int.tryParse(json['commission']?.toString() ?? '');

    subscription = json['subscription'] is int
        ? json['subscription'] as int
        : int.tryParse(json['subscription']?.toString() ?? '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['commission'] = commission;
    data['subscription'] = subscription;
    return data;
  }
}


class CentralizeLoginSetup {
  bool? manualLoginStatus;
  bool? otpLoginStatus;
  bool? socialLoginStatus;
  bool? googleLoginStatus;
  bool? facebookLoginStatus;
  bool? appleLoginStatus;
  bool? emailVerificationStatus;
  bool? phoneVerificationStatus;

  CentralizeLoginSetup({
    this.manualLoginStatus,
    this.otpLoginStatus,
    this.socialLoginStatus,
    this.googleLoginStatus,
    this.facebookLoginStatus,
    this.appleLoginStatus,
    this.emailVerificationStatus,
    this.phoneVerificationStatus,
  });

  CentralizeLoginSetup.fromJson(Map<String, dynamic> json) {
    manualLoginStatus = json['manual_login_status'] == 1;
    otpLoginStatus = json['otp_login_status'] == 1;
    socialLoginStatus = json['social_login_status'] == 1;
    googleLoginStatus = json['google_login_status'] == 1;
    facebookLoginStatus = json['facebook_login_status'] == 1;
    appleLoginStatus = json['apple_login_status'] == 1;
    emailVerificationStatus = json['email_verification_status'] == 1;
    phoneVerificationStatus = json['phone_verification_status'] == 1;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['manual_login_status'] = manualLoginStatus;
    data['otp_login_status'] = otpLoginStatus;
    data['social_login_status'] = socialLoginStatus;
    data['google_login_status'] = googleLoginStatus;
    data['facebook_login_status'] = facebookLoginStatus;
    data['apple_login_status'] = appleLoginStatus;
    data['email_verification_status'] = emailVerificationStatus;
    data['phone_verification_status'] = phoneVerificationStatus;
    return data;
  }
}
