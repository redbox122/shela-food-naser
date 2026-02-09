import 'package:sixam_mart/common/utils/json_parser.dart';

class OrderCancellationBody {
  int? totalSize;
  String? limit;
  String? offset;
  List<CancellationData>? reasons;

  OrderCancellationBody({this.totalSize, this.limit, this.offset, this.reasons});

  OrderCancellationBody.fromJson(Map<String, dynamic> json) {
    totalSize = json.parseInt('total_size');
    limit = json.parseString('limit');
    offset = json.parseString('offset');
    if (json['data'] != null && json['data'] is List) {
      reasons = <CancellationData>[];
      for (var v in (json['data'] as List)) {
        reasons!.add(CancellationData.fromJson(v as Map<String, dynamic>));
      }
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['total_size'] = totalSize;
    data['limit'] = limit;
    data['offset'] = offset;
    if (reasons != null) {
      data['data'] = reasons!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class CancellationData {
  int? id;
  String? reason;
  String? userType;
  int? status;
  String? createdAt;
  String? updatedAt;

  CancellationData(
      {this.id,
        this.reason,
        this.userType,
        this.status,
        this.createdAt,
        this.updatedAt});

  CancellationData.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    reason = json.parseString('reason');
    userType = json.parseString('user_type');
    status = json.parseInt('status');
    createdAt = json.parseString('created_at');
    updatedAt = json.parseString('updated_at');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['reason'] = reason;
    data['user_type'] = userType;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}