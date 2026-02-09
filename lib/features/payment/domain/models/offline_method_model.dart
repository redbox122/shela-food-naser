import 'package:sixam_mart/common/utils/json_parser.dart';

class OfflineMethodModel {
  int? id;
  String? methodName;
  List<MethodFields>? methodFields;
  List<MethodInformations>? methodInformations;
  int? status;
  String? createdAt;
  String? updatedAt;

  OfflineMethodModel({
    this.id,
    this.methodName,
    this.methodFields,
    this.methodInformations,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  OfflineMethodModel.fromJson(Map<String, dynamic> json) {
    id = json.parseInt('id');
    methodName = json.parseString('method_name');
    methodFields = json.parseList<MethodFields>('method_fields', (v) => MethodFields.fromJson(v as Map<String, dynamic>));
    methodInformations = json.parseList<MethodInformations>('method_informations', (v) => MethodInformations.fromJson(v as Map<String, dynamic>));
    status = json.parseInt('status');
    createdAt = json.parseString('created_at');
    updatedAt = json.parseString('updated_at');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['method_name'] = methodName;
    if (methodFields != null) {
      data['method_fields'] =
          methodFields!.map((v) => v.toJson()).toList();
    }
    if (methodInformations != null) {
      data['method_informations'] = methodInformations!.map((v) => v.toJson()).toList();
    }
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    return data;
  }
}

class MethodFields {
  String? inputName;
  String? inputData;

  MethodFields({this.inputName, this.inputData});

  MethodFields.fromJson(Map<String, dynamic> json) {
    inputName = json.parseString('input_name');
    inputData = json.parseString('input_data');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['input_name'] = inputName;
    data['input_data'] = inputData;
    return data;
  }
}

class MethodInformations {
  String? customerInput;
  String? customerPlaceholder;
  bool? isRequired;

  MethodInformations({this.customerInput, this.customerPlaceholder, this.isRequired});

  MethodInformations.fromJson(Map<String, dynamic> json) {
    customerInput = json.parseString('customer_input');
    customerPlaceholder = json.parseString('customer_placeholder');
    isRequired = json.parseInt('is_required') == 1;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['customer_input'] = customerInput;
    data['customer_placeholder'] = customerPlaceholder;
    data['is_required'] = isRequired;
    return data;
  }
}