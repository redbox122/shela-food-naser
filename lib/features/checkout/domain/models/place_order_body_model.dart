import 'dart:convert';
import 'dart:io';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/common/utils/json_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/util/app_constants.dart';

class PlaceOrderBodyModel {
  List<OnlineCart>? _cart;
  double? _couponDiscountAmount;
  double? _orderAmount;
  String? _orderType;
  String? _paymentMethod;
  String? _orderNote;
  String? _couponCode;
  int? _storeId;
  int? _branchId;
  double? _distance;
  String? _scheduleAt;
  double? _discountAmount;
  double? _taxAmount;
  String? _address;
  String? _latitude;
  String? _longitude;
  int? _senderZoneId;
  String? _contactPersonName;
  String? _contactPersonNumber;
  AddressModel? _receiverDetails;
  String? _addressType;
  String? _parcelCategoryId;
  String? _chargePayer;
  String? _streetNumber;
  String? _house;
  String? _floor;
  String? _dmTips;
  String? _unavailableItemNote;
  String? _deliveryInstruction;
  int? _cutlery;
  int? _partialPayment;
  int? _guestId;
  int? _isBuyNow;
  String? _guestEmail;
  double? _extraPackagingAmount;
  int? _createNewUser;
  String? _password;
  String? _couponDiscountTitle;
  int? _couponCreatedBy;
  // Removed _paymentConfirmation and _walletQidhaStatus as they cause 500 errors

  PlaceOrderBodyModel({
    required List<OnlineCart> cart,
    required double? couponDiscountAmount,
    required String? couponCode,
    required double orderAmount,
    required String? orderType,
    required String? paymentMethod,
    required int? storeId,
    required int? branchId,
    required double? distance,
    required String? scheduleAt,
    required double? discountAmount,
    required double taxAmount,
    required String orderNote,
    required String? address,
    required AddressModel? receiverDetails,
    required String? latitude,
    required String? longitude,
    required int? senderZoneId,
    required String contactPersonName,
    required String? contactPersonNumber,
    required String? addressType,
    required String? parcelCategoryId,
    required String? chargePayer,
    required String streetNumber,
    required String house,
    required String floor,
    required String dmTips,
    required String unavailableItemNote,
    required String deliveryInstruction,
    required int cutlery,
    required int partialPayment,
    required int guestId,
    required int isBuyNow,
    required String? guestEmail,
    required double? extraPackagingAmount,
    required int? createNewUser,
    required String? password,
    String? couponDiscountTitle,
    int? couponCreatedBy,
    // Removed paymentConfirmation and walletQidhaStatus as they cause 500 errors
  }) {
    _cart = cart;
    _couponDiscountAmount = couponDiscountAmount;
    _orderAmount = orderAmount;
    _orderType = orderType;
    _paymentMethod = paymentMethod;
    _orderNote = orderNote;
    _couponCode = couponCode;
    _storeId = storeId;
    _branchId = branchId;
    _distance = distance;
    _scheduleAt = scheduleAt;
    _discountAmount = discountAmount;
    _taxAmount = taxAmount;
    _address = address;
    _receiverDetails = receiverDetails;
    _latitude = latitude;
    _longitude = longitude;
    _senderZoneId = senderZoneId;
    _contactPersonName = contactPersonName;
    _contactPersonNumber = contactPersonNumber;
    _addressType = addressType;
    _parcelCategoryId = parcelCategoryId;
    _chargePayer = chargePayer;
    _streetNumber = streetNumber;
    _house = house;
    _floor = floor;
    _dmTips = dmTips;
    _unavailableItemNote = unavailableItemNote;
    _deliveryInstruction = deliveryInstruction;
    _cutlery = cutlery;
    _partialPayment = partialPayment;
    _guestId = guestId;
    _isBuyNow = isBuyNow;
    _guestEmail = guestEmail;
    _extraPackagingAmount = extraPackagingAmount;
    _createNewUser = createNewUser;
    _password = password;
    _couponDiscountTitle = couponDiscountTitle;
    _couponCreatedBy = couponCreatedBy;
    // Removed paymentConfirmation and walletQidhaStatus assignments
  }

  List<OnlineCart>? get cart => _cart;
  double? get couponDiscountAmount => _couponDiscountAmount;
  double? get orderAmount => _orderAmount;
  String? get orderType => _orderType;
  String? get paymentMethod => _paymentMethod;
  String? get orderNote => _orderNote;
  String? get couponCode => _couponCode;
  int? get storeId => _storeId;
  int? get branchId => _branchId;
  double? get distance => _distance;
  String? get scheduleAt => _scheduleAt;
  double? get discountAmount => _discountAmount;
  double? get taxAmount => _taxAmount;
  String? get address => _address;
  AddressModel? get receiverDetails => _receiverDetails;
  String? get latitude => _latitude;
  String? get longitude => _longitude;
  int? get senderZoneId => _senderZoneId;
  String? get contactPersonName => _contactPersonName;
  String? get contactPersonNumber => _contactPersonNumber;
  String? get parcelCategoryId => _parcelCategoryId;
  String? get chargePayer => _chargePayer;
  String? get streetNumber => _streetNumber;
  String? get house => _house;
  String? get floor => _floor;
  String? get dmTips => _dmTips;
  String? get unavailableItemNote => _unavailableItemNote;
  String? get deliveryInstruction => _deliveryInstruction;
  int? get cutlery => _cutlery;
  int? get partialPayment => _partialPayment;
  int? get guestId => _guestId;
  int? get isBuyNow => _isBuyNow;
  String? get guestEmail => _guestEmail;
  double? get extraPackagingAmount => _extraPackagingAmount;
  int? get createNewUser => _createNewUser;
  String? get password => _password;
  String? get couponDiscountTitle => _couponDiscountTitle;
  int? get couponCreatedBy => _couponCreatedBy;
  // Removed paymentConfirmation and walletQidhaStatus getters

  PlaceOrderBodyModel.fromJson(Map<String, dynamic> json) {
    final cartData = json['cart'];
    if (cartData != null) {
      _cart = [];
      final decodedCart = cartData is String ? jsonDecode(cartData) : cartData;
      if (decodedCart is List) {
        for (final v in decodedCart) {
          if (v is Map<String, dynamic>) {
            _cart!.add(OnlineCart.fromJson(v));
          }
        }
      }
    }
    _couponDiscountAmount = json.parseDouble('coupon_discount_amount') ?? 0.0;
    _orderAmount = json.parseDouble('order_amount') ?? 0.0;
    _orderType = json.parseString('order_type');
    _paymentMethod = json.parseString('payment_method');
    _orderNote = json.parseString('order_note');
    _couponCode = json.parseString('coupon_code');
    _storeId = json.parseInt('store_id');
    _branchId = json.parseInt('branch_id');
    _distance = json.parseDouble('distance') ?? 0.0;
    _scheduleAt = json.parseString('schedule_at');
    _discountAmount = json.parseDouble('discount_amount') ?? 0.0;
    _taxAmount = json.parseDouble('tax_amount') ?? 0.0;
    _address = json.parseString('address');
    final receiverDetailsData = json['receiver_details'];
    if (receiverDetailsData != null) {
      final receiverMap = receiverDetailsData is String
          ? jsonDecode(receiverDetailsData) as Map<String, dynamic>
          : receiverDetailsData as Map<String, dynamic>;
      _receiverDetails = AddressModel.fromJson(receiverMap);
    }
    _latitude = json.parseString('latitude');
    _longitude = json.parseString('longitude');
    _senderZoneId = json.parseInt('sender_zone_id');
    _contactPersonName = json.parseString('contact_person_name');
    _contactPersonNumber = json.parseString('contact_person_number');
    _addressType = json.parseString('address_type');
    _parcelCategoryId = json.parseString('parcel_category_id');
    _chargePayer = json.parseString('charge_payer');
    _streetNumber = json.parseString('road');
    _house = json.parseString('apartment');
    _floor = json.parseString('floor');
    _dmTips = json.parseString('dm_tips');
    _unavailableItemNote = json.parseString('unavailable_item_note');
    _deliveryInstruction = json.parseString('delivery_instruction');
    _cutlery = json.parseInt('cutlery');
    _partialPayment = json.parseInt('partial_payment');
    _guestId = json.parseInt('guest_id');
    _isBuyNow = json.parseInt('is_buy_now') ?? 0;
    _guestEmail = json.parseString('contact_person_email');
    final extraPackagingValue = json['extra_packaging_amount'];
    _extraPackagingAmount =
        extraPackagingValue != null && extraPackagingValue != 'null'
            ? json.parseDouble('extra_packaging_amount')
            : null;
    _createNewUser = json.parseInt('create_new_user');
    _password = json.parseString('password');
    // Removed paymentConfirmation and walletQidhaStatus assignments
  }

  Map<String, String> toJson() {
    final Map<String, String> data = <String, String>{};
    if (_cart != null) {
      data['cart'] = jsonEncode(_cart!.map((v) => v.toJson()).toList());
    }
    if (_couponDiscountAmount != null) {
      data['coupon_discount_amount'] = _couponDiscountAmount.toString();
    }
    data['order_amount'] = _orderAmount.toString();
    data['order_type'] = _orderType!;
    data['payment_method'] = _paymentMethod!;
    if (_orderNote != null && _orderNote!.isNotEmpty) {
      data['order_note'] = _orderNote!;
    }
    if (_couponCode != null) {
      data['coupon_code'] = _couponCode!;
    }
    if (_couponDiscountTitle != null &&
        _couponDiscountTitle!.trim().isNotEmpty) {
      data['coupon_discount_title'] = _couponDiscountTitle!;
    }
    if (_couponCreatedBy != null) {
      data['coupon_created_by'] = _couponCreatedBy.toString();
    }
    if (_storeId != null) {
      data['store_id'] = _storeId.toString();
    }
    if (_branchId != null) {
      data['branch_id'] = _branchId.toString();
    }
    data['distance'] = _distance.toString();
    if (_scheduleAt != null) {
      data['schedule_at'] = _scheduleAt!;
    }
    data['discount_amount'] = _discountAmount.toString();
    data['tax_amount'] = _taxAmount.toString();
    data['address'] = _address ?? '';
    if (_receiverDetails != null) {
      data['receiver_details'] = jsonEncode(_receiverDetails!.toJson());
    }
    if (_latitude != null && _latitude!.trim().isNotEmpty) {
      data['latitude'] = _latitude!;
    }
    if (_longitude != null && _longitude!.trim().isNotEmpty) {
      data['longitude'] = _longitude!;
    }
    if (_senderZoneId != null) {
      data['sender_zone_id'] = _senderZoneId.toString();
    }
    data['contact_person_name'] = _contactPersonName!;
    data['contact_person_number'] = _contactPersonNumber!;
    data['address_type'] = _addressType ?? '';
    if (_parcelCategoryId != null) {
      data['parcel_category_id'] = _parcelCategoryId!;
    }
    if (_chargePayer != null) {
      data['charge_payer'] = _chargePayer!;
    }
    data['road'] = _streetNumber.toString();
    data['house'] = _house.toString();
    data['floor'] = _floor.toString();
    data['dm_tips'] = _dmTips.toString();
    data['unavailable_item_note'] = _unavailableItemNote.toString();
    data['delivery_instruction'] = _deliveryInstruction.toString();
    if (_cutlery != null) {
      data['cutlery'] = _cutlery.toString();
    }
    data['partial_payment'] = _partialPayment.toString();
    if (_guestId != 0) {
      data['guest_id'] = _guestId.toString();
    }
    data['is_buy_now'] = _isBuyNow.toString();
    if (_guestEmail != null) {
      data['contact_person_email'] = _guestEmail!;
    }
    data['extra_packaging_amount'] = _extraPackagingAmount.toString();
    data['create_new_user'] = _createNewUser.toString();
    if (_password != null) {
      data['password'] = _password!;
    }
    // Remove these fields as they cause 500 errors in the API
    // if (_paymentConfirmation != null) {
    //   data['payment_confirmation'] = _paymentConfirmation!;
    // }
    // if (_walletQidhaStatus != null) {
    //   data['wallet_qidha_status'] = _walletQidhaStatus!;
    // }
    return data;
  }

  /// Convert to JSON format for API calls (returns Map<String, dynamic> instead of Map<String, String>)
  Map<String, dynamic> toJsonForApi() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (_cart != null && _cart!.isNotEmpty) {
      data['use_cart'] = false;
      data['cart'] = _cart!.map((v) => v.toJson()).toList();
    }
    if (_couponDiscountAmount != null) {
      data['coupon_discount_amount'] = _couponDiscountAmount;
    }
    data['order_amount'] = _orderAmount;
    data['order_type'] = _orderType;
    data['payment_method'] = _paymentMethod;
    if (_orderNote != null && _orderNote!.isNotEmpty) {
      data['order_note'] = _orderNote;
    }
    if (_couponCode != null) {
      data['coupon_code'] = _couponCode;
    }
    if (_couponDiscountTitle != null &&
        _couponDiscountTitle!.trim().isNotEmpty) {
      data['coupon_discount_title'] = _couponDiscountTitle;
    }
    if (_couponCreatedBy != null) {
      data['coupon_created_by'] = _couponCreatedBy;
    }
    if (_storeId != null) {
      data['store_id'] = _storeId;
    }
    if (_branchId != null) {
      data['branch_id'] = _branchId;
    }
    data['distance'] = _distance;
    if (_scheduleAt != null) {
      data['schedule_at'] = _scheduleAt;
    }
    data['discount_amount'] = _discountAmount;
    data['tax_amount'] = _taxAmount;
    data['address'] = _address ?? '';
    if (_receiverDetails != null) {
      data['receiver_details'] = _receiverDetails!.toJson();
    }
    if (_latitude != null && _latitude!.trim().isNotEmpty) {
      data['latitude'] = _latitude;
    }
    if (_longitude != null && _longitude!.trim().isNotEmpty) {
      data['longitude'] = _longitude;
    }
    if (_senderZoneId != null) {
      data['sender_zone_id'] = _senderZoneId;
    }
    data['contact_person_name'] = _contactPersonName;
    data['contact_person_number'] = _contactPersonNumber;
    data['address_type'] = _addressType ?? '';
    if (_parcelCategoryId != null) {
      data['parcel_category_id'] = _parcelCategoryId;
    }
    if (_chargePayer != null) {
      data['charge_payer'] = _chargePayer;
    }
    data['road'] = _streetNumber;
    data['house'] = _house;
    data['floor'] = _floor;
    data['dm_tips'] = _dmTips;
    data['unavailable_item_note'] = _unavailableItemNote;
    data['delivery_instruction'] = _deliveryInstruction;
    if (_cutlery != null) {
      data['cutlery'] = _cutlery;
    }
    data['partial_payment'] = _partialPayment;
    // Always include guest_id field as string (set to "0" for logged-in users)
    data['guest_id'] = (_guestId ?? 0).toString();
    data['is_buy_now'] = _isBuyNow;
    // Remove contact_person_email field as it's not required and causes issues
    // The working PHP test doesn't send this field at all
    // data['contact_person_email'] = _guestEmail?.isNotEmpty == true
    //     ? _guestEmail!
    //     : 'user@example.com';
    data['extra_packaging_amount'] = _extraPackagingAmount;
    data['create_new_user'] = _createNewUser;
    if (_password != null) {
      data['password'] = _password;
    }
    // Remove these fields as they cause 500 errors in the API
    // if (_paymentConfirmation != null) {
    //   data['payment_confirmation'] = _paymentConfirmation;
    // }
    // if (_walletQidhaStatus != null) {
    //   data['wallet_qidha_status'] = _walletQidhaStatus;
    // }
    return data;
  }
}

class OnlineCart {
  int? _cartId;
  int? _itemId;
  int? _itemCampaignId;
  String? _price;
  String? _variant;
  List<Variation>? _variation;
  List<OrderVariation>? _variations;
  int? _quantity;
  List<int?>? _addOnIds;
  List<AddOns>? _addOns;
  List<int?>? _addOnQtys;
  String? _model;
  String? _itemType;
  int? _storeId;

  OnlineCart(
      int? cartId,
      int? itemId,
      int? itemCampaignId,
      String price,
      String variant,
      List<Variation>? variation,
      List<OrderVariation>? variations,
      int? quantity,
      List<int?> addOnIds,
      List<AddOns>? addOns,
      List<int?> addOnQtys,
      String model,
      {String? itemType,
      int? storeId}) {
    _cartId = cartId;
    _itemId = itemId;
    _itemCampaignId = itemCampaignId;
    _price = price;
    _variant = variant;
    _variation = variation;
    _variations = variations;
    _quantity = quantity;
    _addOnIds = addOnIds;
    _addOns = addOns;
    _addOnQtys = addOnQtys;
    _model = model;
    _itemType = itemType;
    _storeId = storeId;
  }

  int? get cartId => _cartId;
  int? get itemId => _itemId;
  int? get itemCampaignId => _itemCampaignId;
  String? get price => _price;
  String? get variant => _variant;
  List<Variation>? get variation => _variation;
  int? get quantity => _quantity;
  List<int?>? get addOnIds => _addOnIds;
  List<AddOns>? get addOns => _addOns;
  List<int?>? get addOnQtys => _addOnQtys;
  String? get model => _model;
  String? get itemType => _itemType;
  int? get storeId => _storeId;

  OnlineCart.fromJson(Map<String, dynamic> json) {
    _cartId = json.parseInt('cart_id');
    _itemId = json.parseInt('item_id');
    _itemCampaignId = json.parseInt('item_campaign_id');
    _price = json.parseString('price');
    _variant = json.parseString('variant');
    final variationList = json['variation'];
    if (variationList != null &&
        variationList is List &&
        variationList.isNotEmpty) {
      final firstVariation = variationList[0];
      if (firstVariation is Map && firstVariation['price'] != null) {
        _variation = json.parseList<Variation>(
            'variation', (v) => Variation.fromJson(v as Map<String, dynamic>));
      } else {
        _variations = json.parseList<OrderVariation>('variation',
            (v) => OrderVariation.fromJson(v as Map<String, dynamic>));
      }
    }
    _quantity = json.parseInt('quantity');
    _addOnIds =
        json.parseList<int>('add_on_ids', (v) => JsonParser.parseInt(v) ?? 0);
    _addOns = json.parseList<AddOns>(
        'add_ons', (v) => AddOns.fromJson(v as Map<String, dynamic>));
    _addOnQtys = (json['add_on_qtys'] as List?)?.cast<int?>();
    _model = json['model']?.toString();
    final itemTypeValue = json['item_type'];
    if (itemTypeValue != null && itemTypeValue != 'null') {
      _itemType = json.parseString('item_type');
    }
    _storeId = json.parseInt('store_id');
  }

  Map<String, dynamic> toJson() {
    const bool logEnabled = kDebugMode && AppConstants.enableVerboseLogs;
    final Map<String, dynamic> data = <String, dynamic>{};
    // Required by update-cart endpoint
    if (_cartId != null && _cartId! > 0) {
      data['cart_id'] = _cartId;
    }
    data['item_id'] = _itemId;
    final String rawModel = (_model ?? 'Item').trim();
    // Backend cart endpoints validate against short model names (e.g. "Item"),
    // not fully-qualified class names.
    data['model'] =
        rawModel.contains('\\') ? rawModel.split('\\').last : rawModel;
    data['price'] = _price;
    // Add variant field as string "none" to prevent backend error - backend expects this field
    data['variant'] = 'none';

    // #region agent log - toJson variations
    if (logEnabled) {
      debugPrint('🔍 [OnlineCart.toJson] Variation check:');
      debugPrint('   - _variations is null: ${_variations == null}');
      debugPrint('   - _variations length: ${_variations?.length ?? 0}');
      debugPrint('   - _variation is null: ${_variation == null}');
      debugPrint('   - _variation length: ${_variation?.length ?? 0}');
    }
    // #endregion

    // #region agent log - H_D
    if (logEnabled) {
      try {
        File('c:\\Users\\pc\\Desktop\\clone\\app-test\\.cursor\\debug.log')
            .writeAsStringSync(
                '${jsonEncode({
                      'location': 'place_order_body_model.dart:463',
                      'message': 'Before variation serialization',
                      'data': {
                        'variationsIsNull': _variations == null,
                        'variationsLength': _variations?.length ?? 0,
                        'variationIsNull': _variation == null,
                        'variationLength': _variation?.length ?? 0
                      },
                      'timestamp': DateTime.now().millisecondsSinceEpoch,
                      'sessionId': 'debug-session',
                      'hypothesisId': 'D'
                    })}\n',
                mode: FileMode.append);
      } catch (e) { if (kDebugMode) debugPrint('$e'); }
    }
    // #endregion

    // ✅ FIX: Properly serialize variations based on type (NOT always empty!)
    if (_variations != null && _variations!.isNotEmpty) {
      // Food variations (new format) - has name and values with label
      data['variation'] = _variations!.map((v) => v.toJson()).toList();
      // #region agent log - H_D
      if (logEnabled) {
        try {
          File('c:\\Users\\pc\\Desktop\\clone\\app-test\\.cursor\\debug.log')
              .writeAsStringSync(
                  '${jsonEncode({
                        'location': 'place_order_body_model.dart:466',
                        'message': 'Serializing food variations',
                        'data': {
                          'count': _variations!.length,
                          'firstVariation': _variations!.isNotEmpty
                              ? {
                                  'name': _variations!.first.name,
                                  'optionsCount': _variations!
                                          .first.values?.options?.length ??
                                      0
                                }
                              : null
                        },
                        'timestamp': DateTime.now().millisecondsSinceEpoch,
                        'sessionId': 'debug-session',
                        'hypothesisId': 'D'
                      })}\n',
                  mode: FileMode.append);
        } catch (e) { if (kDebugMode) debugPrint('$e'); }
      }
      // #endregion
      if (logEnabled) {
        debugPrint(
            '🔍 [OnlineCart.toJson] Sending ${_variations!.length} food variations to cart API');
        for (final v in _variations!) {
          debugPrint(
              '   - ${v.name}: ${v.values?.options?.length ?? 0} selected options');
        }
      }
    } else if (_variation != null && _variation!.isNotEmpty) {
      // Product variations (old format) - has type and price
      data['variation'] = _variation!.map((v) => v.toJson()).toList();
      // #region agent log - H_D
      if (logEnabled) {
        try {
          File('c:\\Users\\pc\\Desktop\\clone\\app-test\\.cursor\\debug.log')
              .writeAsStringSync(
                  '${jsonEncode({
                        'location': 'place_order_body_model.dart:473',
                        'message': 'Serializing product variations',
                        'data': {'count': _variation!.length},
                        'timestamp': DateTime.now().millisecondsSinceEpoch,
                        'sessionId': 'debug-session',
                        'hypothesisId': 'D'
                      })}\n',
                  mode: FileMode.append);
        } catch (e) { if (kDebugMode) debugPrint('$e'); }
      }
      // #endregion
      if (logEnabled) {
        debugPrint(
            '🔍 [OnlineCart.toJson] Sending ${_variation!.length} product variations to cart API');
      }
    } else {
      // No variations selected
      data['variation'] = [];
      // #region agent log - H_D
      if (logEnabled) {
        try {
          File('c:\\Users\\pc\\Desktop\\clone\\app-test\\.cursor\\debug.log')
              .writeAsStringSync(
                  '${jsonEncode({
                        'location': 'place_order_body_model.dart:477',
                        'message': 'No variations - sending empty array',
                        'data': {},
                        'timestamp': DateTime.now().millisecondsSinceEpoch,
                        'sessionId': 'debug-session',
                        'hypothesisId': 'D'
                      })}\n',
                  mode: FileMode.append);
        } catch (e) { if (kDebugMode) debugPrint('$e'); }
      }
      // #endregion
      if (logEnabled) {
        debugPrint(
            '🔍 [OnlineCart.toJson] No variations selected - sending empty array');
      }
    }

    data['quantity'] = _quantity;
    data['add_on_ids'] = _addOnIds ?? [];
    data['add_ons'] = [];
    data['add_on_qtys'] = _addOnQtys ?? [];
    // Include store_id to allow backend to verify all items are from the same store
    if (_storeId != null) {
      data['store_id'] = _storeId;
    }
    return data;
  }
}

class OrderVariation {
  String? name;
  OrderVariationValue? values;

  OrderVariation({this.name, this.values});

  OrderVariation.fromJson(Map<String, dynamic> json) {
    name = json['name']?.toString();
    values = json['values'] != null
        ? OrderVariationValue.fromJson(json['values'])
        : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (values != null) {
      data['values'] = values!.toJson();
    }
    return data;
  }
}

class OrderVariationValue {
  List<VariationOption>? options;

  OrderVariationValue({this.options});

  // Support both old format (list of strings) and new format (list of objects)
  OrderVariationValue.fromJson(dynamic json) {
    if (json is List) {
      // New format: array of {label, optionPrice} objects
      options = (json)
          .map((e) => VariationOption.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json is Map && json['label'] != null) {
      // Old format: {label: ["option1", "option2"]}
      final List<String> labels = (json['label'] as List).cast<String>();
      options = labels
          .map((label) => VariationOption(label: label, optionPrice: 0.0))
          .toList();
    }
  }

  // Returns array of {label, optionPrice} objects (backend format)
  dynamic toJson() {
    return options?.map((o) => o.toJson()).toList() ?? [];
  }
}

/// Individual variation option with label and price
class VariationOption {
  String? label;
  double? optionPrice;

  VariationOption({this.label, this.optionPrice});

  VariationOption.fromJson(Map<String, dynamic> json) {
    label = json['label']?.toString();
    optionPrice = json.parseDouble('optionPrice') ?? 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'optionPrice': optionPrice ?? 0.0,
    };
  }
}
