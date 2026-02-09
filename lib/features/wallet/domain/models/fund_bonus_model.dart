import 'package:sixam_mart/common/utils/json_parser.dart';

/// ---------- FundBonusModel ----------
class FundBonusModel {
  int? id;
  double? bonusAmount;
  double? minFundAmount;
  double? maxBonusAmount;
  int? isActive;
  String? createdAt;
  FundBonusType? bonusType;

  // 👇 getters للتوافق مع UI القديم
  String? get title => bonusType?.name;
  String? get endDate => createdAt;
  double? get minimumAddAmount => minFundAmount;

  FundBonusModel({
    this.id,
    this.bonusAmount,
    this.minFundAmount,
    this.maxBonusAmount,
    this.isActive,
    this.createdAt,
    this.bonusType,
  });

  FundBonusModel.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    bonusAmount = json.parseDouble('bonus_amount');
    minFundAmount = json.parseDouble('min_fund_amount');
    maxBonusAmount = json.parseDouble('max_bonus_amount');
    isActive = json.parseInt('is_active');
    createdAt = json.parseString('created_at');

    final bonusTypeMap = json.parseMap('bonus_type');
    bonusType =
        bonusTypeMap != null ? FundBonusType.fromJson(bonusTypeMap) : null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bonus_amount': bonusAmount,
        'min_fund_amount': minFundAmount,
        'max_bonus_amount': maxBonusAmount,
        'is_active': isActive,
        'created_at': createdAt,
        'bonus_type': bonusType?.toJson(),
      };
}

/// ---------- FundBonusType ----------
class FundBonusType {
  int? id;
  String? name;
  String? description;

  FundBonusType({
    this.id,
    this.name,
    this.description,
  });

  FundBonusType.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    name = json.parseString('name');
    description = json.parseString('description');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}
