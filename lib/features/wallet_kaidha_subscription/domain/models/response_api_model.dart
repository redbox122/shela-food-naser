class ResponseApiIncomeSourceModel {
  final String? message;
  final ResponseErrors? errors;

  ResponseApiIncomeSourceModel({this.message, this.errors});

  factory ResponseApiIncomeSourceModel.fromJson(Map<String, dynamic> json) {
    return ResponseApiIncomeSourceModel(
      message: json['message']?.toString(),
      errors: json['errors'] is Map<String, dynamic>
          ? ResponseErrors.fromJson(json['errors'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ResponseErrors {
  final List<String>? firstName;
  final List<String>? grandfatherName;
  final List<String>? fatherName;
  final List<String>? lastName;
  final List<String>? birthDate;
  final List<String>? nationalId;
  final List<String>? maritalStatus;
  final List<String>? numberOfFamilyMembers;
  final List<String>? identityCardNumber;
  final List<String>? endDate;
  final List<String>? mobile;
  final List<String>? houseType;
  final List<String>? city;
  final List<String>? neighborhood;
  final List<String>? nameOfEmployer;
  final List<String>? totalSalary;
  final List<String>? installments;

  ResponseErrors({
    this.firstName,
    this.grandfatherName,
    this.fatherName,
    this.lastName,
    this.birthDate,
    this.nationalId,
    this.maritalStatus,
    this.numberOfFamilyMembers,
    this.identityCardNumber,
    this.endDate,
    this.mobile,
    this.houseType,
    this.city,
    this.neighborhood,
    this.nameOfEmployer,
    this.totalSalary,
    this.installments,
  });

  factory ResponseErrors.fromJson(Map<String, dynamic> json) {
    List<String>? list(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : null;

    return ResponseErrors(
      firstName: list(json['first_name']),
      grandfatherName: list(json['grandfather_name']),
      fatherName: list(json['father_name']),
      lastName: list(json['last_name']),
      birthDate: list(json['birth_date']),
      nationalId: list(json['national_id']),
      maritalStatus: list(json['marital_status']),
      numberOfFamilyMembers: list(json['number_of_family_members']),
      identityCardNumber: list(json['identity_card_number']),
      endDate: list(json['end_date']),
      mobile: list(json['mobile']),
      houseType: list(json['house_type']),
      city: list(json['city']),
      neighborhood: list(json['neighborhood']),
      nameOfEmployer: list(json['name_of_employer']),
      totalSalary: list(json['total_salary']),
      installments: list(json['installments']),
    );
  }
}
