enum DeepLinkType {
  restaurant,
  cuisine,
  category,
}

class DeepLinkBody {
  DeepLinkType? deepLinkType;
  int? id;
  String? name;

  DeepLinkBody({this.deepLinkType, this.id, this.name});

  factory DeepLinkBody.fromJson(Map<String, dynamic> json) {
    final DeepLinkType deepLinkType =
        _convertToEnum(json['deepLinkType']?.toString());
    final dynamic rawId = json['id'];
    final int? id =
        rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '');
    final String? name = json['name']?.toString();
    return DeepLinkBody(deepLinkType: deepLinkType, id: id, name: name);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['deepLinkType'] = deepLinkType?.toString();
    data['id'] = id;
    data['name'] = name;
    return data;
  }

  static DeepLinkType _convertToEnum(String? enumString) {
    if (enumString == DeepLinkType.restaurant.toString()) {
      return DeepLinkType.restaurant;
    } else if (enumString == DeepLinkType.cuisine.toString()) {
      return DeepLinkType.cuisine;
    } else {
      return DeepLinkType.category;
    }
  }
}
