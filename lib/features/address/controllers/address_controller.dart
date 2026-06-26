import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/address/domain/models/address_v2_model.dart';
import 'package:sixam_mart/features/address/domain/services/address_service_interface.dart';
import 'package:sixam_mart/features/address/domain/services/address_v2_api.dart';
import 'package:sixam_mart/features/checkout/controllers/checkout_controller.dart';
import 'package:sixam_mart/features/store/controllers/store_controller.dart';
import 'package:sixam_mart/helper/address_helper.dart';

class AddressController extends GetxController implements GetxService {
  final AddressServiceInterface addressServiceInterface;

  AddressController({required this.addressServiceInterface});

  List<AddressModel>? _addressList;
  List<AddressModel>? get addressList => _addressList;

  late List<AddressModel> _allAddressList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _hasError = false;
  bool get hasError => _hasError;

  Future<ResponseModel> addAddress(AddressModel addressModel, bool fromCheckout, int? storeZoneId) async {
    _isLoading = true;
    update();
    ResponseModel responseModel = await addressServiceInterface.addAddress(addressModel);
    responseModel = await _processSuccessResponse(responseModel, fromCheckout, storeZoneId);
    _isLoading = false;
    update();
    return responseModel;
  }

  Future<ResponseModel> updateAddress(AddressModel addressModel, int? addressId) async {
    _isLoading = true;
    update();
    
    // 🔒 TASK 2: LOCATION-CHANGE CACHE PURGE
    // Calculate distance between new and old coordinates
    // If distance > 500 meters, clear all module state and Hive cache
    try {
      final oldAddress = AddressHelper.getUserAddressFromSharedPref();
      if (oldAddress != null && 
          oldAddress.latitude != null && 
          oldAddress.longitude != null &&
          addressModel.latitude != null &&
          addressModel.longitude != null) {
        final oldLat = double.tryParse(oldAddress.latitude!) ?? 0.0;
        final oldLng = double.tryParse(oldAddress.longitude!) ?? 0.0;
        final newLat = double.tryParse(addressModel.latitude!) ?? 0.0;
        final newLng = double.tryParse(addressModel.longitude!) ?? 0.0;
        
        // Calculate distance in meters
        final distanceInMeters = Geolocator.distanceBetween(
          oldLat, oldLng, newLat, newLng
        );
        
        if (distanceInMeters > 500) {
          if (Get.isRegistered<StoreController>()) {
            final storeController = Get.find<StoreController>();
            await storeController.clearAllModuleState(reload: true);
            if (kDebugMode) {
              debugPrint('🧹 AddressController: Location changed by ${distanceInMeters.toStringAsFixed(0)}m (>500m) - Cleared all module state and Hive cache');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ AddressController: Error calculating distance for cache purge: $e');
      }
      // Don't fail the update if distance calculation fails
    }
    
    final ResponseModel responseModel = await addressServiceInterface.updateAddress(addressModel, addressId);
    if (responseModel.isSuccess) {
      getAddressList();
    }
    _isLoading = false;
    update();
    return responseModel;
  }

  Future<void> getAddressList() async {
    _isLoading = true;
    _hasError = false;
    update();
    try {
      final List<AddressModel>? addressList =
          await addressServiceInterface.getAllAddress();
      // Always set lists to avoid infinite loaders when API returns null (empty/error).
      _addressList = <AddressModel>[];
      _allAddressList = <AddressModel>[];
      if (addressList != null) {
        final List<AddressModel> sorted = List<AddressModel>.from(addressList)
          ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
        _addressList!.addAll(sorted);
        _allAddressList.addAll(sorted);
        if (kDebugMode) {
          debugPrint(
              '📍 AddressController.getAddressList: loaded=${sorted.length}, ids=${sorted.map((e) => e.id).toList()}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ AddressController.getAddressList: Failed to load addresses: $e');
      }
      _hasError = true;
      _addressList = <AddressModel>[];
      _allAddressList = <AddressModel>[];
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<ResponseModel> deleteUserAddressByID(int? id, int index) async {
    _isLoading = true;
    update();
    final ResponseModel responseModel = await addressServiceInterface.removeAddressByID(id);
    if(responseModel.isSuccess) {
      // Bounds-check before removing (mirrors the safe V2 path).
      if (_addressList != null && index >= 0 && index < _addressList!.length) {
        _addressList!.removeAt(index);
      }
    }
    _isLoading = false;
    update();
    return responseModel;
  }

  // ───────────────────────── v2 address flow ─────────────────────────
  // Backed by the new /api/v2/address endpoints; reuses [_addressList] so the
  // existing list UI keeps working with mapped models.

  Future<void> getAddressListV2() async {
    _isLoading = true;
    _hasError = false;
    update();
    try {
      final List<AddressV2Model> v2 = await AddressV2Api().list();
      final List<AddressModel> mapped = v2.map(_mapV2ToAddress).toList()
        ..sort((a, b) => (b.id ?? 0).compareTo(a.id ?? 0));
      _addressList = mapped;
      _allAddressList = List<AddressModel>.from(mapped);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ AddressController.getAddressListV2 failed: $e');
      }
      _hasError = true;
      _addressList = <AddressModel>[];
      _allAddressList = <AddressModel>[];
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<ResponseModel> deleteAddressV2(int? id, int index) async {
    if (id == null) return ResponseModel(false, null);
    _isLoading = true;
    update();
    final AddAddressV2Result result = await AddressV2Api().delete(id);
    if (result.success &&
        _addressList != null &&
        index >= 0 &&
        index < _addressList!.length) {
      _addressList!.removeAt(index);
    }
    _isLoading = false;
    update();
    return ResponseModel(result.success, result.message);
  }

  AddressModel _mapV2ToAddress(AddressV2Model v) => AddressModel(
        id: v.id,
        addressType: v.addressLabel,
        address: v.displayText,
        latitude: v.latitude?.toString(),
        longitude: v.longitude?.toString(),
        streetNumber: v.streetName,
        house: v.buildingNumber,
        floor: v.floorNumber,
      );

  Future<ResponseModel> _processSuccessResponse(ResponseModel responseModel, bool fromCheckout, int? storeZoneId) async {
    if (responseModel.isSuccess) {
      if(fromCheckout && !(responseModel.zoneIds?.contains(storeZoneId) ?? false)) {
        responseModel = ResponseModel(false, (Get.find<SplashController>().configModel!.moduleConfig!.module!.showRestaurantText! ? 'your_selected_location_is_from_different_zone'.tr : 'your_selected_location_is_from_different_zone_store'.tr));
      }else {
        await getAddressList();
        // Always select the first item after reload (newest address appears first).
        Get.find<CheckoutController>().setAddressIndex(0);
        if (kDebugMode) {
          debugPrint(
              '✅ AddressController.addAddress: selectedIndex=0, selectedAddressId=${_addressList?.isNotEmpty == true ? _addressList!.first.id : null}');
        }
        responseModel = ResponseModel(true, responseModel.message);
      }
    }
    return responseModel;
  }

}
