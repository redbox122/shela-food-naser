import 'package:image_picker/image_picker.dart';
import 'package:sixam_mart/features/auth/domain/models/delivery_man_body.dart';
import 'package:sixam_mart/features/auth/domain/models/status_model.dart';
import 'package:sixam_mart/interfaces/repository_interface.dart';

abstract class DeliverymanRegistrationRepositoryInterface extends RepositoryInterface {
  @override
  Future getList({int? offset, int? zoneId, bool isZone = true, bool isVehicle = false});
  Future<bool> registerDeliveryMan(
      List<XFile> driverLicenseImages, List<XFile> vehicleLicenseImages, List<XFile> identityImages, DeliveryManBody deliveryManBody);

  Future<StatusModel> getStatus(String? phone);
  Future<Map<String, dynamic>?> checkDeliveryManRegistration({
    String? phone,
    String? email,
    String? identityNumber,
  });
}
