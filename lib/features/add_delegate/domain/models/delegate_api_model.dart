class DelegateModel {
  DelegateModel({required this.delegateStatus});

  final String? delegateStatus;

  factory DelegateModel.fromJson(Map<String, dynamic> json) {
    return DelegateModel(
      delegateStatus: json['delegate_status'] as String?,
    );
  }
}
