
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/rental_module/vendor/domain/repositories/taxi_vendor_repository_interface.dart';

class TaxiVendorRepository implements TaxiVendorRepositoryInterface {
  final ApiClient apiClient;

  TaxiVendorRepository({required this.apiClient});


  @override
  Future add(value) {
    // Note: implement add
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    // Note: implement delete
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    // Note: implement get
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) {
    // Note: implement getList
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    // Note: implement update
    throw UnimplementedError();
  }


}