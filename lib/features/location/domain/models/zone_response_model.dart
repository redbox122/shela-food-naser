import 'package:sixam_mart/common/utils/json_parser.dart';

class ZoneResponseModel {
  final bool _isSuccess;
  final List<int> _zoneIds;
  final String? _message;
  final List<ZoneData> _zoneData;
  final List<int> _areaIds;
  final int? statusCode;
  final Map<String, dynamic>? _metadata;

  ZoneResponseModel(
    this._isSuccess,
    this._message,
    this._zoneIds,
    this._zoneData,
    this._areaIds,
    this.statusCode, [
    this._metadata,
  ]);

  String? get message => _message;
  List<int> get zoneIds => _zoneIds;
  bool get isSuccess => _isSuccess;
  List<ZoneData> get zoneData => _zoneData;
  List<int> get areaIds => _areaIds;
  int? get status => statusCode;
  Map<String, dynamic>? get metadata => _metadata;
  
  // 🔥 Helper getters for metadata
  bool get shouldRedirect {
    if (_metadata == null) return true; // Default: allow redirect if no metadata
    return _metadata['should_redirect'] as bool? ?? true;
  }
  
  bool get requiresZonesLoaded {
    if (_metadata == null) return false; // Default: don't require zones if no metadata
    return _metadata['requires_zones_loaded'] as bool? ?? false;
  }
  
  bool get isInZone {
    if (_metadata == null) return _isSuccess && _zoneIds.isNotEmpty; // Fallback to old logic
    return _metadata['is_in_zone'] as bool? ?? (_isSuccess && _zoneIds.isNotEmpty);
  }
}

class ZoneData {
  int? id;
  int? status;
  bool? cashOnDelivery;
  bool? digitalPayment;
  bool? offlinePayment;
  double? increaseDeliveryFee;
  int? increaseDeliveryFeeStatus;
  String? increaseDeliveryFeeMessage;
  List<Modules>? modules;

  ZoneData({
    this.id,
    this.status,
    this.cashOnDelivery,
    this.digitalPayment,
    this.offlinePayment,
    this.increaseDeliveryFee,
    this.increaseDeliveryFeeStatus,
    this.increaseDeliveryFeeMessage,
    this.modules,
  });

  ZoneData.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    status = json.parseInt('status');
    cashOnDelivery = json.parseBool('cash_on_delivery');
    digitalPayment = json.parseBool('digital_payment');
    offlinePayment = json.parseBool('offline_payment');
    increaseDeliveryFee = json.parseDouble('increased_delivery_fee');
    increaseDeliveryFeeStatus = json.parseInt('increased_delivery_fee_status');
    increaseDeliveryFeeMessage = json.parseString('increase_delivery_charge_message');
    final List<Map<String, dynamic>> moduleList = json.parseMapList('modules');
    if (moduleList.isNotEmpty) {
      modules = moduleList.map((Map<String, dynamic> v) => Modules.fromJson(v)).toList();
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['status'] = status;
    data['cash_on_delivery'] = cashOnDelivery;
    data['digital_payment'] = digitalPayment;
    data['offline_payment'] = offlinePayment;
    data['increased_delivery_fee'] = increaseDeliveryFee;
    data['increased_delivery_fee_status'] = increaseDeliveryFeeStatus;
    data['increase_delivery_charge_message'] = increaseDeliveryFeeMessage;
    if (modules != null) {
      data['modules'] = modules!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Modules {
  int? id;
  String? moduleName;
  String? moduleType;
  String? thumbnail;
  String? status;
  int? storesCount;
  String? createdAt;
  String? updatedAt;
  String? icon;
  int? themeId;
  String? description;
  int? allZoneService;
  Pivot? pivot;

  Modules({
    this.id,
    this.moduleName,
    this.moduleType,
    this.thumbnail,
    this.status,
    this.storesCount,
    this.createdAt,
    this.updatedAt,
    this.icon,
    this.themeId,
    this.description,
    this.allZoneService,
    this.pivot,
  });

  Modules.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    moduleName = json.parseString('module_name');
    moduleType = json.parseString('module_type');
    thumbnail = json.parseString('thumbnail');
    status = json.parseString('status');
    storesCount = json.parseInt('stores_count');
    createdAt = json.parseString('created_at');
    updatedAt = json.parseString('updated_at');
    icon = json.parseString('icon');
    themeId = json.parseInt('theme_id');
    description = json.parseString('description');
    allZoneService = json.parseInt('all_zone_service');
    final Map<String, dynamic>? pivotMap = json.parseMap('pivot');
    pivot = pivotMap != null ? Pivot.fromJson(pivotMap) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['module_name'] = moduleName;
    data['module_type'] = moduleType;
    data['thumbnail'] = thumbnail;
    data['status'] = status;
    data['stores_count'] = storesCount;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['icon'] = icon;
    data['theme_id'] = themeId;
    data['description'] = description;
    data['all_zone_service'] = allZoneService;
    if (pivot != null) {
      data['pivot'] = pivot!.toJson();
    }
    return data;
  }
}

class Pivot {
  int? zoneId;
  int? moduleId;
  double? perKmShippingCharge;
  double? minimumShippingCharge;
  double? maximumShippingCharge;
  double? maximumCodOrderAmount;
  double? firstKmFee;
  double? firstKmDistance;

  Pivot({
    this.zoneId,
    this.moduleId,
    this.perKmShippingCharge,
    this.minimumShippingCharge,
    this.maximumShippingCharge,
    this.maximumCodOrderAmount,
    this.firstKmFee,
    this.firstKmDistance,
  });

  Pivot.fromJson(Map<String, dynamic> json) {
    zoneId = json.parseInt('zone_id');
    moduleId = json.parseInt('module_id');
    perKmShippingCharge = json.parseDouble('per_km_shipping_charge');
    minimumShippingCharge = json.parseDouble('minimum_shipping_charge');
    maximumShippingCharge = json.parseDouble('maximum_shipping_charge');
    maximumCodOrderAmount = json.parseDouble('maximum_cod_order_amount');
    firstKmFee = json.parseDouble('first_km_fee');
    firstKmDistance = json.parseDouble('first_km_distance');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['zone_id'] = zoneId;
    data['module_id'] = moduleId;
    data['per_km_shipping_charge'] = perKmShippingCharge;
    data['minimum_shipping_charge'] = minimumShippingCharge;
    data['maximum_shipping_charge'] = maximumShippingCharge;
    data['maximum_cod_order_amount'] = maximumCodOrderAmount;
    data['first_km_fee'] = firstKmFee;
    data['first_km_distance'] = firstKmDistance;
    return data;
  }
}
