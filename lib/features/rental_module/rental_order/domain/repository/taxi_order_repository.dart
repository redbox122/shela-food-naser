
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/rental_module/rental_order/domain/repository/taxi_order_repository_interface.dart';

class TaxiOrderRepository implements TaxiOrderRepositoryInterface {
  final ApiClient apiClient;

  TaxiOrderRepository({required this.apiClient});

  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  Future<bool> addVehicleReview({required int tripId, required int vehicleId, required int vehicleIdentityId, required int rating, required String comment}) {
    // TODO: implement addVehicleReview
    throw UnimplementedError();
  }

  Future delete(int? id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  Future get(String? id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  Future getList({int? offset}) {
    // TODO: implement getList
    throw UnimplementedError();
  }

  Future<dynamic> getTripDetails({required int id, String? phone}) {
    // TODO: implement getTripDetails
    throw UnimplementedError();
  }

  Future<dynamic> getTripList({required int offset, required String type}) {
    // TODO: implement getTripList
    throw UnimplementedError();
  }

  Future<Response> makeTripPayment({required int id, required String paymentMethod, String? paymentGateWayName}) {
    // TODO: implement makeTripPayment
    throw UnimplementedError();
  }

  Future update(Map<String, dynamic> body, int? id) {
    // TODO: implement update
    throw UnimplementedError();
  }

  
}