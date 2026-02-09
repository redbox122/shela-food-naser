import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/common/utils/json_parser.dart';

class BasicCampaignModel {
  int? id;
  String? title;
  String? imageFullUrl;
  String? description;
  String? availableDateStarts;
  String? availableDateEnds;
  String? startTime;
  String? endTime;
  List<Store>? store;

  BasicCampaignModel({
    this.id,
    this.title,
    this.imageFullUrl,
    this.description,
    this.availableDateStarts,
    this.availableDateEnds,
    this.startTime,
    this.endTime,
    this.store,
  });

  BasicCampaignModel.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    title = json['title']?.toString();
    imageFullUrl = json['image_full_url']?.toString();
    description = json['description']?.toString();
    availableDateStarts = json['available_date_starts']?.toString();
    availableDateEnds = json['available_date_ends']?.toString();
    startTime = json['start_time']?.toString();
    endTime = json['end_time']?.toString();
    if (json['stores'] != null) {
      store = [];
      json['stores'].forEach((v) {
        store!.add(Store.fromJson(v as Map<String, dynamic>));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['image_full_url'] = imageFullUrl;
    data['description'] = description;
    data['available_date_starts'] = availableDateStarts;
    data['available_date_ends'] = availableDateEnds;
    data['start_time'] = startTime;
    data['end_time'] = endTime;
    if (store != null) {
      data['stores'] = store!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}
