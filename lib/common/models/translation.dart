class Translation {
  int? id;
  String? locale;
  String? key;
  String? value;

  Translation({
    this.id,
    this.locale,
    this.key,
    this.value,
  });

  Translation.fromJson(Map<String, dynamic> json) {
    id = json['id'] as int?;
    locale = json['locale']?.toString();
    key = json['key']?.toString();
    value = json['value']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['locale'] = locale;
    data['key'] = key;
    data['value'] = value;
    return data;
  }
}
