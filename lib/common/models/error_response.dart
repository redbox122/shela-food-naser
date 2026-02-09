class ErrorResponse {
  List<Errors>? _errors;

  List<Errors>? get errors => _errors;

  ErrorResponse({List<Errors>? errors}) {
    _errors = errors;
  }

  ErrorResponse.fromJson(Map<String, dynamic> json) {
    if (json['errors'] is List) {
      _errors = [];

      final errorsList = json['errors'] as List;

      for (final v in errorsList) {
        if (v is Map<String, dynamic>) {
          _errors!.add(Errors.fromJson(v));
        }
      }
    }
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (_errors != null) {
      map['errors'] = _errors!.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class Errors {
  String? _code;
  String? _message;

  String? get code => _code;
  String? get message => _message;

  Errors({String? code, String? message}) {
    _code = code;
    _message = message;
  }

  Errors.fromJson(Map<String, dynamic> json) {
    _code = json['code']?.toString();
    _message = json['message']?.toString();
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['code'] = _code;
    map['message'] = _message;
    return map;
  }
}
