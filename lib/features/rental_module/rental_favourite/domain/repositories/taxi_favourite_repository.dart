import 'package:shared_preferences/shared_preferences.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/rental_module/rental_favourite/domain/repositories/taxi_favourite_repository_interface.dart';

class TaxiFavouriteRepository implements TaxiFavouriteRepositoryInterface {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;
  TaxiFavouriteRepository({required this.sharedPreferences, required this.apiClient});
  

  @override
  Future get(String? id) {
    // Note: implement get
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    // Note: implement update
    throw UnimplementedError();
  }

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
  Future getList({int? offset}) {
    // Note: implement getList
    throw UnimplementedError();
  }
}