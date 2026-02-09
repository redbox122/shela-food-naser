import 'package:sixam_mart/common/utils/json_parser.dart';

class NotificationModel {
  int? id;
  Data? data;
  String? createdAt;
  String? updatedAt;
  String? imageFullUrl;
  int? status; // 0 = unread, 1 = read

  NotificationModel({this.id, this.data, this.createdAt, this.updatedAt, this.imageFullUrl, this.status});

  NotificationModel.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    data = json.parseMap('data') != null ? Data.fromJson(json.parseMap('data')!) : null;
    createdAt = json.parseString('created_at');
    updatedAt = json.parseString('updated_at');
    imageFullUrl = json.parseString('image_full_url');
    status = json.parseInt('status');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['image_full_url'] = imageFullUrl;
    data['status'] = status;
    return data;
  }
}

class Data {
  String? title;
  String? description;
  String? imageFullUrl;
  String? type;

  Data({this.title, this.description, this.imageFullUrl, this.type});

  Data.fromJson(Map<String, dynamic> json) {
    title = json['title']?.toString();
    description = json['description'].toString();
    imageFullUrl = json['image_full_url']?.toString();
    type = json['type']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['description'] = description;
    data['image_full_url'] = imageFullUrl;
    data['type'] = type;
    return data;
  }
}
