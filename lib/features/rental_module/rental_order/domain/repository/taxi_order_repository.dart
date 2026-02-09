
import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/rental_module/rental_order/domain/repository/taxi_order_repository_interface.dart';

class TaxiOrderRepository implements TaxiOrderRepositoryInterface {
  final ApiClient apiClient;

  TaxiOrderRepository({required this.apiClient});

  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future<bool> addVehicleReview({required int tripId, required int vehicleId, required int vehicleIdentityId, required int rating, required String comment}) {
    // TODO: implement addVehicleReview
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) {
    // TODO: implement getList
    throw UnimplementedError();
  }

  @override
  Future<dynamic> getTripDetails({required int id, String? phone}) {
    // TODO: implement getTripDetails
    throw UnimplementedError();
  }

  @override
  Future<dynamic> getTripList({required int offset, required String type}) {
    // TODO: implement getTripList
    throw UnimplementedError();
  }

  @override
  Future<Response> makeTripPayment({required int id, required String paymentMethod, String? paymentGateWayName}) {
    // TODO: implement makeTripPayment
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    // TODO: implement update
    throw UnimplementedError();
  }

  
}