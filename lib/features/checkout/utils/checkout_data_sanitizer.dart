/// 🥇 Checkout Data Sanitizer
/// 
/// قاعدة ذهبية: لا ترسل Request ناقص أبدًا
/// حتى لو الباك قال nullable.
/// 
/// هذا الملف يحتوي على دوال تطهير البيانات
/// لضمان عدم إرسال null أو string فاضي
library;

import 'package:sixam_mart/features/address/domain/models/address_model.dart';

class CheckoutDataSanitizer {
  /// ✅ تطهير اسم المستلم
  /// 
  /// Priority:
  /// 1. addressName (من العنوان)
  /// 2. profileName (من الملف الشخصي)
  /// 3. fallback آمن
  static String resolveContactPersonName({
    required bool isGuest,
    String? addressName,
    String? profileName,
  }) {
    // 1. جرب من العنوان أولاً
    if (addressName != null && addressName.trim().isNotEmpty) {
      return addressName.trim();
    }
    
    // 2. إذا كان مستخدم مسجل، جرب من الملف الشخصي
    if (!isGuest && profileName != null && profileName.trim().isNotEmpty) {
      return profileName.trim();
    }
    
    // 3. Fallback آمن
    return 'Guest User';
  }
  
  /// ✅ تطهير رقم الهاتف
  static String resolveContactPersonNumber({
    required bool isGuest,
    String? addressNumber,
    String? profileNumber,
    String? countryDialCode,
  }) {
    String? number;
    
    // 1. جرب من العنوان أولاً
    if (addressNumber != null && addressNumber.trim().isNotEmpty) {
      number = addressNumber.trim();
    }
    // 2. إذا كان مستخدم مسجل، جرب من الملف الشخصي
    else if (!isGuest && profileNumber != null && profileNumber.trim().isNotEmpty) {
      number = profileNumber.trim();
    }
    
    // 3. إذا لم يوجد رقم، ارجع fallback
    if (number == null || number.isEmpty) {
      return '';
    }
    
    // 4. تأكد من وجود country code
    if (countryDialCode != null &&
        countryDialCode.isNotEmpty &&
        !number.startsWith(countryDialCode)) {

      // إزالة + أو 00 من البداية بدون RegExp
      if (number.startsWith('+')) {
        number = number.substring(1);
      } else if (number.startsWith('00')) {
        number = number.substring(2);
      }

      return '$countryDialCode$number';
    }
    
    return number;
  }
  
  /// ✅ تطهير العنوان
  static String resolveAddress({
    required AddressModel? address,
    String? fallback,
  }) {
    if (address?.address != null && address!.address!.trim().isNotEmpty) {
      return address.address!.trim();
    }
    
    if (fallback != null && fallback.trim().isNotEmpty) {
      return fallback.trim();
    }
    
    return '';
  }
  
  /// ✅ تطهير Latitude
  static String resolveLatitude({
    required AddressModel? address,
    String? fallback,
  }) {
    if (address?.latitude != null && address!.latitude!.trim().isNotEmpty) {
      return address.latitude!.trim();
    }
    
    if (fallback != null && fallback.trim().isNotEmpty) {
      return fallback.trim();
    }
    
    return '';
  }
  
  /// ✅ تطهير Longitude
  static String resolveLongitude({
    required AddressModel? address,
    String? fallback,
  }) {
    if (address?.longitude != null && address!.longitude!.trim().isNotEmpty) {
      return address.longitude!.trim();
    }
    
    if (fallback != null && fallback.trim().isNotEmpty) {
      return fallback.trim();
    }
    
    return '';
  }
  
  /// ✅ تطهير Street Number
  static String resolveStreetNumber({
    required bool isGuest,
    String? addressStreetNumber,
    String? controllerValue,
  }) {
    if (isGuest) {
      if (addressStreetNumber != null && addressStreetNumber.trim().isNotEmpty) {
        return addressStreetNumber.trim();
      }
    } else {
      if (controllerValue != null && controllerValue.trim().isNotEmpty) {
        return controllerValue.trim();
      }
    }
    
    return '';
  }
  
  /// ✅ تطهير House
  static String resolveHouse({
    required bool isGuest,
    String? addressHouse,
    String? controllerValue,
  }) {
    if (isGuest) {
      if (addressHouse != null && addressHouse.trim().isNotEmpty) {
        return addressHouse.trim();
      }
    } else {
      if (controllerValue != null && controllerValue.trim().isNotEmpty) {
        return controllerValue.trim();
      }
    }
    
    return '';
  }
  
  /// ✅ تطهير Floor
  static String resolveFloor({
    required bool isGuest,
    String? addressFloor,
    String? controllerValue,
  }) {
    if (isGuest) {
      if (addressFloor != null && addressFloor.trim().isNotEmpty) {
        return addressFloor.trim();
      }
    } else {
      if (controllerValue != null && controllerValue.trim().isNotEmpty) {
        return controllerValue.trim();
      }
    }
    
    return '';
  }
  
  /// ✅ تطهير DM Tips
  static String resolveDmTips({
    required String orderType,
    String? tipValue,
  }) {
    // إذا كان take_away أو not_now، ارجع string فاضي
    if (orderType == 'take_away' || tipValue == 'not_now') {
      return '';
    }
    
    if (tipValue != null && tipValue.trim().isNotEmpty) {
      return tipValue.trim();
    }
    
    return '';
  }
  
  /// ✅ تطهير Order Note
  static String resolveOrderNote(String? note) {
    if (note != null && note.trim().isNotEmpty) {
      return note.trim();
    }
    
    return '';
  }
  
  /// ✅ تطهير Delivery Instruction
  static String resolveDeliveryInstruction({
    required int selectedInstruction,
    required List<String> instructionList,
  }) {
    if (selectedInstruction >= 0 && 
        selectedInstruction < instructionList.length) {
      return instructionList[selectedInstruction];
    }
    
    return '';
  }
  
  /// ✅ تطهير Email (للـ Guest)
  static String? resolveGuestEmail({
    required bool isGuest,
    String? addressEmail,
    String? profileEmail,
  }) {
    if (isGuest) {
      if (addressEmail != null && addressEmail.trim().isNotEmpty) {
        return addressEmail.trim();
      }
    } else {
      if (profileEmail != null && profileEmail.trim().isNotEmpty) {
        return profileEmail.trim();
      }
    }
    
    // لا ترجع null - إذا لم يوجد email، لا ترسله في Request
    return null;
  }
}

