import 'package:sixam_mart/common/utils/json_parser.dart';

class CashBackModel {
  int? id;
  String? title;
  String? customerId;
  String? cashbackType;
  int? sameUserLimit;
  int? totalUsed;
  double? cashbackAmount;
  double? minPurchase;
  double? maxDiscount;
  String? startDate;
  String? endDate;
  bool? status;
  String? createdAt;
  String? updatedAt;
  List<Translations>? translations;

  CashBackModel(
      {this.id,
        this.title,
        this.customerId,
        this.cashbackType,
        this.sameUserLimit,
        this.totalUsed,
        this.cashbackAmount,
        this.minPurchase,
        this.maxDiscount,
        this.startDate,
        this.endDate,
        this.status,
        this.createdAt,
        this.updatedAt,
        this.translations});

  CashBackModel.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    title = json['title']?.toString();
    customerId = json['customer_id']?.toString();
    cashbackType = json['cashback_type']?.toString();
    sameUserLimit = json.parseInt('same_user_limit');
    totalUsed = json.parseInt('total_used');
    cashbackAmount = json.parseDouble('cashback_amount');
    minPurchase = json.parseDouble('min_purchase');
    maxDiscount = json.parseDouble('max_discount');
    startDate = json['start_date']?.toString();
    endDate = json['end_date']?.toString();
    status = json.parseBool('status');
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    if (json['translations'] != null) {
      translations = <Translations>[];
      for (var v in (json['translations'] as List)) {
        translations!.add(Translations.fromJson(v as Map<String, dynamic>));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['customer_id'] = customerId;
    data['cashback_type'] = cashbackType;
    data['same_user_limit'] = sameUserLimit;
    data['total_used'] = totalUsed;
    data['cashback_amount'] = cashbackAmount;
    data['min_purchase'] = minPurchase;
    data['max_discount'] = maxDiscount;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
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

  Translations(
      {this.id,
        this.translationableType,
        this.translationableId,
        this.locale,
        this.key,
        this.value,
        this.createdAt,
        this.updatedAt});

  Translations.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    translationableType = json['translationable_type']?.toString();
    translationableId = json.parseInt('translationable_id');
    locale = json['locale']?.toString();
    key = json['key']?.toString();
    value = json['value']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
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