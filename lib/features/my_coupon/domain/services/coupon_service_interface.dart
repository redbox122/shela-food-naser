
import '../models/my_coupon_models.dart';

abstract class CouponServiceInterface{
  Future<List<CouponModel>?> getCouponList();
  Future<List<CouponModel>?> getTaxiCouponList();
  Future<CouponModel?> applyCoupon(String couponCode, int? storeID);
  Future<CouponModel?> applyTaxiCoupon(String couponCode, int? providerId);
}