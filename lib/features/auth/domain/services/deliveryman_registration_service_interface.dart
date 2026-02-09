import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/features/auth/domain/models/status_model.dart';
import 'package:sixam_mart/features/location/domain/models/zone_data_model.dart';
import 'package:sixam_mart/features/auth/domain/models/delivery_man_body.dart';
import 'package:sixam_mart/features/auth/domain/models/delivery_man_vehicles_model.dart';

abstract class DeliverymanRegistrationServiceInterface {
  Future<List<ZoneDataModel>?> getZoneList();
  Future<List<ModuleModel>?> getModules(int? zoneId);
  int? prepareSelectedZoneIndex(List<int>? zoneIds, List<ZoneDataModel>? zoneList);
  Future<List<DeliveryManVehicleModel>?> getVehicleList();
  List<int?>? prepareVehicleIds(List<DeliveryManVehicleModel>? vehicleList);
  Future<void> registerDeliveryMan(
    List<XFile> driverLicenseImages,
    List<XFile> vehicleLicenseImages,
    List<XFile> identityImages,
    DeliveryManBody deliveryManBody,
  );
  List<MultipartBody> prepareMultipart(XFile? pickedImage, List<XFile> pickedIdentities);

  Future<StatusModel> getStatus(String? phone);
  Future<Map<String, dynamic>?> checkDeliveryManRegistration({
    String? phone,
    String? email,
    String? identityNumber,
  });
}
