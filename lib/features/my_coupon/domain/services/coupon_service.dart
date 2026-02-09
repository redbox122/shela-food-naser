
import '../models/my_coupon_models.dart';
import '../repositories/coupon_repository_interface.dart';
import 'coupon_service_interface.dart';

class CouponService implements CouponServiceInterface{
  final CouponRepositoryInterface couponRepositoryInterface;
  CouponService({required this.couponRepositoryInterface});

  @override
  Future<List<CouponModel>?> getCouponList() async {
    final result = await couponRepositoryInterface.getList(couponList: true);
    return result is List<CouponModel>? ? result : null;
  }

  @override
  Future<List<CouponModel>?> getTaxiCouponList() async {
    final result = await couponRepositoryInterface.getList(taxiCouponList: true);
    return result is List<CouponModel>? ? result : null;
  }

  @override
  Future<CouponModel?> applyCoupon(String couponCode, int? storeID) async {
    final result = await couponRepositoryInterface.applyCoupon(couponCode, storeID);
    return result is CouponModel? ? result : null;
  }

  @override
  Future<CouponModel?> applyTaxiCoupon(String couponCode, int? providerId) async {
    final result = await couponRepositoryInterface.applyTaxiCoupon(couponCode, providerId);
    return result is CouponModel? ? result : null;
  }

}