import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/address/domain/repositories/address_repository_interface.dart';
import 'package:sixam_mart/features/address/domain/services/address_service_interface.dart';

class AddressService implements AddressServiceInterface {
  final AddressRepositoryInterface<AddressModel> addressRepoInterface;

  AddressService({required this.addressRepoInterface});

  @override
  Future<List<AddressModel>?> getAllAddress() async {
    final result = await addressRepoInterface.getList();
    return result as List<AddressModel>?;
  }

  @override
  Future<ResponseModel> removeAddressByID(int? id) async {
    final result = await addressRepoInterface.delete(id);
    return result as ResponseModel;
  }

  @override
  Future<ResponseModel> addAddress(AddressModel addressModel) async {
    final result = await addressRepoInterface.add(addressModel);
    return result as ResponseModel;
  }

  @override
  Future<ResponseModel> updateAddress(
    AddressModel addressModel,
    int? addressId,
  ) async {
    final result = await addressRepoInterface.update(
      addressModel.toJson(),
      addressId,
    );
    return result as ResponseModel;
  }
}
