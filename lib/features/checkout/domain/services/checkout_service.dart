import 'package:get/get_connect/http/src/response/response.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/store/domain/models/store_model.dart';
import 'package:sixam_mart/features/payment/domain/models/offline_method_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/checkout/domain/models/timeslote_model.dart';
import 'package:sixam_mart/features/checkout/domain/repositories/checkout_repository_interface.dart';
import 'package:sixam_mart/features/checkout/domain/services/checkout_service_interface.dart';
import 'package:sixam_mart/helper/date_converter.dart';

class CheckoutService implements CheckoutServiceInterface {
  final CheckoutRepositoryInterface checkoutRepositoryInterface;
  CheckoutService({required this.checkoutRepositoryInterface});

  @override
  Future<List<OfflineMethodModel>?> getOfflineMethodList() async {
    final result = await checkoutRepositoryInterface.getList();
    return result is List<OfflineMethodModel>? ? result : null;
  }

  @override
  Future<int> getDmTipMostTapped() async {
    return await checkoutRepositoryInterface.getDmTipMostTapped();
  }

  @override
  String getSharedPrefDmTipIndex() {
    return checkoutRepositoryInterface.getSharedPrefDmTipIndex();
  }

  @override
  Future<bool> saveSharedPrefDmTipIndex(String index) async {
    return await checkoutRepositoryInterface.saveSharedPrefDmTipIndex(index);
  }

  @override
  Future<List<TimeSlotModel>?> initializeTimeSlot(Store store, int? scheduleOrderSlotDuration) async{
    // 🔧 FIX: Handle null store or schedules gracefully (user out of zone)
    if (store.schedules == null || store.schedules!.isEmpty) {
      return [];
    }
    if (scheduleOrderSlotDuration == null || scheduleOrderSlotDuration <= 0) {
      return [];
    }
    
    final List<TimeSlotModel> timeSlots = [];
    int minutes = 0;
    final DateTime now = DateTime.now();
    for(int index=0; index<store.schedules!.length; index++) {
      final DateTime openTime = DateTime(
        now.year, now.month, now.day, DateConverter.convertStringTimeToDate(store.schedules![index].openingTime!).hour,
        DateConverter.convertStringTimeToDate(store.schedules![index].openingTime!).minute,
      );
      final DateTime closeTime = DateTime(
        now.year, now.month, now.day, DateConverter.convertStringTimeToDate(store.schedules![index].closingTime!).hour,
        DateConverter.convertStringTimeToDate(store.schedules![index].closingTime!).minute,
      );
      if(closeTime.difference(openTime).isNegative) {
        minutes = openTime.difference(closeTime).inMinutes;
      }else {
        minutes = closeTime.difference(openTime).inMinutes;
      }
      if(minutes > scheduleOrderSlotDuration) {
        DateTime time = openTime;
        for(;;) {
          if(time.isBefore(closeTime)) {
            final DateTime start = time;
            DateTime end = start.add(Duration(minutes: scheduleOrderSlotDuration));
            if(end.isAfter(closeTime)) {
              end = closeTime;
            }
            timeSlots.add(TimeSlotModel(day: store.schedules![index].day, startTime: start, endTime: end));
            time = time.add(Duration(minutes: scheduleOrderSlotDuration));
          }else {
            break;
          }
        }
      }else {
        timeSlots.add(TimeSlotModel(day: store.schedules![index].day, startTime: openTime, endTime: closeTime));
      }
    }
    return timeSlots;
  }

  @override
  List<TimeSlotModel>? validateTimeSlot(List<TimeSlotModel> slots, int dateIndex, int? interval, bool? orderPlaceToScheduleInterval) {
    final List<TimeSlotModel> timeSlots = [];

    DateTime now = DateTime.now();
    if(orderPlaceToScheduleInterval!) {
      now = now.add(Duration(minutes: interval ?? 30));
    }
    int day = 0;
    if(dateIndex == 0) {
      day = DateTime.now().weekday;
    }else {
      day = DateTime.now().add(const Duration(days: 1)).weekday;
    }
    if(day == 7) {
      day = 0;
    }
    for (final slot in slots) {
      if (day == slot.day && (dateIndex == 0 ? slot.endTime!.isAfter(now) : true)) {
        timeSlots.add(slot);
      }
    }
    return timeSlots;
  }

  @override
  Future<Response> getDistanceInMeter(LatLng originLatLng, LatLng destinationLatLng) async {
    return await checkoutRepositoryInterface.getDistanceInMeter(originLatLng, destinationLatLng);
  }
  @override
  Future<Response> getDistanceInMeterNew(LatLng originLatLng, LatLng destinationLatLng) async {
    return await checkoutRepositoryInterface.getDistanceInMeterNew(originLatLng, destinationLatLng);
  }

  @override
  Future<double> getExtraCharge(double? distance) async {
    return await checkoutRepositoryInterface.getExtraCharge(distance);
  }

  @override
  Future<Response> placeOrder(PlaceOrderBodyModel orderBody, List<MultipartBody> orderAttachment) async {
    return await checkoutRepositoryInterface.placeOrder(orderBody, orderAttachment);
  }

  @override
  Future<Response> placePrescriptionOrder(
    int? storeId,
    double? distance,
    String address,
    String longitude,
    String latitude,
    String note,
    List<MultipartBody> orderAttachment,
    String dmTips,
    String deliveryInstruction, {
    double orderAmount = 0,
    String? cartItemsJson,
  }) async {
    return await checkoutRepositoryInterface.placePrescriptionOrder(
        storeId,
        distance,
        address,
        longitude,
        latitude,
        note,
        orderAttachment,
        dmTips,
        deliveryInstruction,
        orderAmount: orderAmount,
        cartItemsJson: cartItemsJson);
  }

  @override
  Future<Response> processPayment(int orderId, String paymentMethod, double amount) async {
    return await checkoutRepositoryInterface.processPayment(orderId, paymentMethod, amount);
  }

  @override
  Future<Response> editOrderAddress(int orderId, String address, String latitude, String longitude) async {
    return await checkoutRepositoryInterface.editOrderAddress(orderId, address, latitude, longitude);
  }

}
