import 'package:get/get.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/util/app_constants.dart';

import '../models/my_coupon_models.dart';
import 'coupon_repository_interface.dart';

class CouponRepository implements CouponRepositoryInterface {
  final ApiClient apiClient;
  CouponRepository({required this.apiClient});

  @override
  Future getList({int? offset, bool couponList = false, bool taxiCouponList = false}) async {
    if(couponList) {
      return await _getCouponList();
    } else if(taxiCouponList) {
      return await _getTaxiCouponList();
    }
  }

  Future<List<CouponModel>?> _getCouponList() async {
    List<CouponModel>? couponList;
    final Response response = await apiClient.getData(AppConstants.couponUri);
    if (response.statusCode == 200) {
      couponList = [];
      for (var category in (response.body as List)) {
        final CouponModel coupon = CouponModel.fromJson(category as Map<String, dynamic>);
        coupon.toolTip = JustTheController();
        couponList.add(coupon);
      }
    }
    return couponList;
  }

  Future<List<CouponModel>?> _getTaxiCouponList() async {
    List<CouponModel>? taxiCouponList;
    final Response response = await apiClient.getData(AppConstants.taxiCouponUri);
    if (response.statusCode == 200) {
      taxiCouponList = [];
      for (var category in (response.body as List)) {
        taxiCouponList.add(CouponModel.fromJson(category as Map<String, dynamic>));
      }
    }
    return taxiCouponList;
  }

  @override
  Future<CouponModel?> applyCoupon(String couponCode, int? storeID) async {
    CouponModel? couponModel;
    final Response response = await apiClient.getData('${AppConstants.couponApplyUri}$couponCode&store_id=$storeID');
    if (response.statusCode == 200) {
      couponModel = CouponModel.fromJson(response.body as Map<String, dynamic>);
    }
    return couponModel;
  }

  @override
  Future<CouponModel?> applyTaxiCoupon(String couponCode, int? providerId) async {
    CouponModel? taxiCouponModel;
    final Response response = await apiClient.getData('${AppConstants.taxiCouponApplyUri}$couponCode&provider_id=$providerId');
    if (response.statusCode == 200) {
      taxiCouponModel = CouponModel.fromJson(response.body as Map<String, dynamic>);
    }
    return taxiCouponModel;
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }

}