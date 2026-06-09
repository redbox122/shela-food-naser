import 'package:sixam_mart/features/my_coupon/domain/models/my_coupon_models.dart';

/// True when [expireDate] is strictly before "now". Qidha with null/empty
/// [CouponModel.expireDate] is never expired by date.
bool couponIsExpiredByDate(CouponModel coupon) {
  final String? type = coupon.couponType?.toLowerCase();
  if (type == 'qidha') {
    final String? raw = coupon.expireDate;
    if (raw == null || raw.trim().isEmpty) {
      return false;
    }
  }
  // Per spec: a coupon is expired ONLY when expire_date exists AND is before
  // today. A missing/empty/unparseable expire_date means "no expiry" → NOT
  // expired (so it stays in the available list).
  final String? raw = coupon.expireDate;
  if (raw == null || raw.trim().isEmpty) {
    return false;
  }
  final DateTime? expires = DateTime.tryParse(raw);
  if (expires == null) {
    return false;
  }
  return expires.isBefore(DateTime.now());
}

bool couponIsNotExpiredByDate(CouponModel coupon) {
  return !couponIsExpiredByDate(coupon);
}

bool couponIsUsed(CouponModel coupon) {
  return coupon.isUsed;
}

/// Not expired by date and not used (per backend [CouponModel.isUsed]).
bool couponIsUsableAvailable(CouponModel coupon) {
  return couponIsNotExpiredByDate(coupon) && !couponIsUsed(coupon);
}

List<CouponModel> couponsNotExpiredByDate(List<CouponModel> coupons) {
  return coupons.where(couponIsNotExpiredByDate).toList();
}

List<CouponModel> couponsExpiredByDate(List<CouponModel> coupons) {
  return coupons.where(couponIsExpiredByDate).toList();
}

/// First tab: usable coupons first, then used-but-not-expired.
List<CouponModel> sortCouponsForFirstTab(List<CouponModel> coupons) {
  final List<CouponModel> usable =
      coupons.where(couponIsUsableAvailable).toList();
  final List<CouponModel> usedNotExpired = coupons
      .where(
        (CouponModel c) => couponIsUsed(c) && couponIsNotExpiredByDate(c),
      )
      .toList();
  return <CouponModel>[...usable, ...usedNotExpired];
}

int countNotExpiredByDateCoupons(List<CouponModel> coupons) {
  return coupons.where(couponIsNotExpiredByDate).length;
}

int countUsableCoupons(List<CouponModel> coupons) {
  return coupons.where(couponIsUsableAvailable).length;
}

int countUsedNotExpiredCoupons(List<CouponModel> coupons) {
  return coupons
      .where(
        (CouponModel c) => couponIsUsed(c) && couponIsNotExpiredByDate(c),
      )
      .length;
}

int countExpiredTabCoupons(List<CouponModel> coupons) {
  return coupons.where(couponIsExpiredByDate).length;
}
