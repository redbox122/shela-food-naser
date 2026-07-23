// ignore_for_file: file_names, non_constant_identifier_names

class KaidhaSubModel {
  final String? first_name;
  final String? grandfather_name;
  final String? father_name;
  final String? last_name;
  final String? birth_date;
  final String? national_id;
  final String? nationality;
  final String? marital_status;
  final String? number_of_family_members;
  final String? identity_card_number;
  final String? end_date;
  final String? mobile;
  final String? house_type;
  final String? city;
  final String? neighborhood;
  final String? name_of_employer;
  final String? total_salary;
  final String? installments;
  final String? source_of_income;
  final String? monthly_amount;
  final String? salary_day;
  // Design-added fields (optional; only sent when non-empty).
  final String? installment_amount;
  final String? building_number;
  final String? street_name;
  final String? postal_code;
  final String? home_ownership;

  KaidhaSubModel({
    required this.first_name,
    required this.grandfather_name,
    required this.father_name,
    required this.last_name,
    required this.birth_date,
    required this.national_id,
    required this.nationality,
    required this.marital_status,
    required this.number_of_family_members,
    required this.identity_card_number,
    required this.end_date,
    required this.mobile,
    required this.house_type,
    required this.city,
    required this.neighborhood,
    required this.name_of_employer,
    required this.total_salary,
    required this.installments,
    required this.source_of_income,
    required this.monthly_amount,
    required this.salary_day,
    this.installment_amount,
    this.building_number,
    this.street_name,
    this.postal_code,
    this.home_ownership,
  });

  factory KaidhaSubModel.fromJson(Map<String, dynamic> json) {
    return KaidhaSubModel(
      first_name: json['first_name']?.toString(),
      grandfather_name: json['grandfather_name']?.toString(),
      father_name: json['father_name']?.toString(),
      last_name: json['last_name']?.toString(),
      birth_date: json['birth_date']?.toString(),
      national_id: json['national_id']?.toString(),
      nationality: json['nationality']?.toString(),
      marital_status: json['marital_status']?.toString(),
      number_of_family_members:
          json['number_of_family_members']?.toString(),
      identity_card_number:
          json['identity_card_number']?.toString(),
      end_date: json['end_date']?.toString(),
      mobile: json['mobile']?.toString(),
      house_type: json['house_type']?.toString(),
      city: json['city']?.toString(),
      neighborhood: json['neighborhood']?.toString(),
      name_of_employer: json['name_of_employer']?.toString(),
      total_salary: json['total_salary']?.toString(),
      installments: json['installments']?.toString(),
      source_of_income: json['source_of_income']?.toString(),
      monthly_amount: json['monthly_amount']?.toString(),
      salary_day: json['salary_day']?.toString(),
      installment_amount: json['installment_amount']?.toString(),
      building_number: json['building_number']?.toString(),
      street_name: json['street_name']?.toString(),
      postal_code: json['postal_code']?.toString(),
      home_ownership: json['home_ownership']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'first_name': first_name,
      'grandfather_name': grandfather_name,
      'father_name': father_name,
      'last_name': last_name,
      'birth_date': birth_date,
      'national_id': national_id,
      'nationality': nationality,
      'marital_status': marital_status,
      'number_of_family_members': number_of_family_members,
      'identity_card_number': identity_card_number,
      'end_date': end_date,
      'mobile': mobile,
      'house_type': house_type,
      'city': city,
      'neighborhood': neighborhood,
      'name_of_employer': name_of_employer,
      'total_salary': total_salary,
      'installments': installments,
      'source_of_income': source_of_income,
      'monthly_amount': monthly_amount,
      'salary_day': salary_day,
    };
    // Only include the optional design-added fields when they carry a value, so
    // the backend's `nullable` rules don't receive the literal string "null".
    void putIf(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) map[key] = value;
    }

    putIf('installment_amount', installment_amount);
    putIf('building_number', building_number);
    putIf('street_name', street_name);
    putIf('postal_code', postal_code);
    putIf('home_ownership', home_ownership);
    return map;
  }
}
