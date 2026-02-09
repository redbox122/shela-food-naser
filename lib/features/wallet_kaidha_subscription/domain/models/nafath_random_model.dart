class NafathRandomModel {
  String? status;
  String? requestId;
  String? createdAt;
  String? message;
  String? code;
  List<ExternalResponse>? externalResponse;

  NafathRandomModel({
    this.status,
    this.requestId,
    this.createdAt,
    this.message,
    this.code,
    this.externalResponse,
  });

  factory NafathRandomModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data =
        json['data'] is Map<String, dynamic>
            ? (json['data'] as Map<String, dynamic>)
            : json;
    return NafathRandomModel(
      status: data['status']?.toString(),
      requestId: data['request_id']?.toString(),
      createdAt: data['created_at']?.toString(),
      message: data['message']?.toString(),
      code: data['random']?.toString(),
      externalResponse: data['external_response'] is List
          ? (data['external_response'] as List)
              .map((e) =>
                  ExternalResponse.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'request_id': requestId,
      'created_at': createdAt,
      'message': message,
      'code': code,
      'external_response':
          externalResponse?.map((x) => x.toJson()).toList() ?? [],
    };
  }
}

class ExternalResponse {
  ExternalResponse({
    this.nationalId,
    this.error,
    this.transId,
    this.random,
    this.code,
    this.status,
    this.message,
  });

  final String? nationalId;
  final String? error;
  final String? transId;
  final String? random;
  final String? code;
  final String? status;
  final String? message;

  factory ExternalResponse.fromJson(Map<String, dynamic> json) {
    return ExternalResponse(
      nationalId: json['nationalId']?.toString(),
      error: json['error']?.toString(),
      transId: json['transId']?.toString(),
      random: json['random']?.toString(),
      code: json['code']?.toString(),
      status: json['status']?.toString(),
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nationalId': nationalId,
      'error': error,
      'transId': transId,
      'random': random,
      'code': code,
      'status': status,
      'message': message,
    };
  }
}
