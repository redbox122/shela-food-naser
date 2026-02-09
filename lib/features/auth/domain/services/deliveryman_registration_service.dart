import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/auth/domain/models/status_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_data_model.dart';
import 'package:sixam_mart/features/auth/domain/models/delivery_man_body.dart';
import 'package:sixam_mart/features/auth/domain/models/delivery_man_vehicles_model.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/auth_repository_interface.dart';
import 'package:sixam_mart/features/auth/domain/reposotories/deliveryman_registration_repository_interface.dart';
import 'package:sixam_mart/features/auth/domain/services/deliveryman_registration_service_interface.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';

class DeliverymanRegistrationService implements DeliverymanRegistrationServiceInterface {
  final DeliverymanRegistrationRepositoryInterface deliverymanRegistrationRepoInterface;
  final AuthRepositoryInterface authRepositoryInterface;
  DeliverymanRegistrationService({required this.deliverymanRegistrationRepoInterface, required this.authRepositoryInterface});

  @override
  Future<List<ZoneDataModel>?> getZoneList() async {
    final result = await deliverymanRegistrationRepoInterface.getList();
    return result as List<ZoneDataModel>?;
  }

  @override
  Future<List<ModuleModel>?> getModules(int? zoneId) async {
    final result = await deliverymanRegistrationRepoInterface.getList(isZone: false, zoneId: zoneId);
    return result as List<ModuleModel>?;
  }

  @override
  Future<List<DeliveryManVehicleModel>?> getVehicleList() async {
    final result = await deliverymanRegistrationRepoInterface.getList(isZone: false, isVehicle: true);
    return result as List<DeliveryManVehicleModel>?;
  }

  @override
  int? prepareSelectedZoneIndex(List<int>? zoneIds, List<ZoneDataModel>? zoneList) {
    int? selectedZoneIndex = 0;
    for (int index = 0; index < zoneList!.length; index++) {
      if (zoneIds!.contains(zoneList[index].id)) {
        selectedZoneIndex = index;
        break;
      }
    }
    return selectedZoneIndex;
  }

  @override
  List<int?>? prepareVehicleIds(List<DeliveryManVehicleModel>? vehicleList) {
    final List<int?> vehicleIds = [];
    vehicleIds.add(0);
    for (final vehicle in vehicleList!) {
      vehicleIds.add(vehicle.id);
    }
    return vehicleIds;
  }

  @override
  Future<void> registerDeliveryMan(List<XFile> driverLicenseImages, List<XFile> vehicleLicenseImages, List<XFile> identityImages,
      DeliveryManBody deliveryManBody) async {
    final bool success = await deliverymanRegistrationRepoInterface.registerDeliveryMan(
      driverLicenseImages,
      vehicleLicenseImages,
      identityImages,
      deliveryManBody,
    );
    if (success) {
      Get.offAllNamed(RouteHelper.getInitialRoute());
      showCustomSnackBar('delivery_man_registration_successful'.tr, isError: false);
    } else {
      showCustomSnackBar('delivery_man_registration_failed'.tr);
    }
  }

  @override
  List<MultipartBody> prepareMultipart(XFile? pickedImage, List<XFile> pickedIdentities) {
    final List<MultipartBody> multiParts = [];
    multiParts.add(MultipartBody('image', pickedImage));
    for (final XFile file in pickedIdentities) {
      multiParts.add(MultipartBody('identity_image[]', file));
    }
    return multiParts;
  }

  @override
  Future<StatusModel> getStatus(String? phone) async {
    return await deliverymanRegistrationRepoInterface.getStatus(phone);
  }

  @override
  Future<Map<String, dynamic>?> checkDeliveryManRegistration({
    String? phone,
    String? email,
    String? identityNumber,
  }) async {
    return await deliverymanRegistrationRepoInterface.checkDeliveryManRegistration(
      phone: phone,
      email: email,
      identityNumber: identityNumber,
    );
  }
}
