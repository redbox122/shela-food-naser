import 'package:sixam_mart/common/utils/json_parser.dart';

class TimeSlotModel {
  int? day;
  DateTime? startTime;
  DateTime? endTime;

  TimeSlotModel({required this.day, required this.startTime, required this.endTime});

  TimeSlotModel.fromJson(Map<String, dynamic> json) {
    day = json.parseInt('day');
    startTime = json.parseDateTime('start_time');
    endTime = json.parseDateTime('end_time');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['day'] = day;
    data['start_time'] = startTime;
    data['end_time'] = endTime;
    return data;
  }
}
