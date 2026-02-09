// ignore_for_file: file_names

class NafathCheckStatusModel {
  final String? status;
  final int? random;
  final String? nationalId;
  final String? requestId;
  final String? createdAt;
  final String? fullNameAr;
  final dynamic signedFileUrl;
  final String? failReason;
  final bool? canInitiate;

  NafathCheckStatusModel({
    this.status,
    this.random,
    this.nationalId,
    this.requestId,
    this.createdAt,
    this.fullNameAr,
    this.signedFileUrl,
    this.failReason,
    this.canInitiate,
  });

  factory NafathCheckStatusModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data =
        json['data'] is Map<String, dynamic>
            ? (json['data'] as Map<String, dynamic>)
            : json;
    final dynamic rawRandom = data['random'];
    final int? parsedRandom = rawRandom == null
        ? null
        : int.tryParse(rawRandom.toString());
    return NafathCheckStatusModel(
      status: data['status']?.toString(),
      random: parsedRandom,
      nationalId: data['national_id']?.toString(),
      requestId: data['request_id']?.toString(),
      createdAt: data['created_at']?.toString(),
      fullNameAr: data['full_name_ar']?.toString(),
      signedFileUrl: data['signed_file_url'], // ???? String ?? null ?? ?? ??
      failReason: data['fail_reason']?.toString(),
      canInitiate: data['can_initiate'] is bool
          ? data['can_initiate'] as bool
          : (data['can_initiate']?.toString().toLowerCase() == 'true'),
    );
  }
}
