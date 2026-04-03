
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/rental_module/rental_order/domain/repository/taxi_order_repository_interface.dart';

class TaxiOrderRepository implements TaxiOrderRepositoryInterface {
  final ApiClient apiClient;

  TaxiOrderRepository({required this.apiClient});

  @override
  Future add(value) {
    // Note: implement add
    throw UnimplementedError();
  }

  Future<bool> addVehicleReview({required int tripId, required int vehicleId, required int vehicleIdentityId, required int rating, required String comment}) {
    // Note: implement addVehicleReview
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

  Future<dynamic> getTripDetails({required int id, String? phone}) {
    // Note: implement getTripDetails
    throw UnimplementedError();
  }

  Future<dynamic> getTripList({required int offset, required String type}) {
    // Note: implement getTripList
    throw UnimplementedError();
  }

  Future<Response> makeTripPayment({required int id, required String paymentMethod, String? paymentGateWayName}) {
    // Note: implement makeTripPayment
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    // Note: implement update
    throw UnimplementedError();
  }

  
}