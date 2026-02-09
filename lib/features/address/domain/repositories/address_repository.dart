import 'package:get/get_connect/connect.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/features/address/domain/models/address_model.dart';
import 'package:sixam_mart/features/address/domain/repositories/address_repository_interface.dart';
import 'package:sixam_mart/util/app_constants.dart';

class AddressRepository implements AddressRepositoryInterface<AddressModel> {
  final ApiClient apiClient;

  AddressRepository({required this.apiClient});

  @override
  Future add(AddressModel addressModel) async {
    return await _addAddress(addressModel);
  }

  Future<ResponseModel> _addAddress(AddressModel addressModel) async {
    final Response response = await apiClient.postData(
      AppConstants.addAddressUri,
      addressModel.toJson(),
      handleError: false,
    );

    if (response.statusCode == 200) {
      final String? message = response.body['message']?.toString();

      final List<int> zoneIds = [];
      if (response.body['zone_ids'] != null && response.body['zone_ids'] is List) {
        for (final z in response.body['zone_ids'] as List) {
          zoneIds.add(int.parse(z.toString()));
        }
      }

      return ResponseModel(true, message, zoneIds: zoneIds);
    } else {
      return ResponseModel(
        false,
        response.statusText == 'Out of coverage!'
            ? 'service_not_available_in_this_area'.tr
            : response.statusText,
      );
    }
  }

  @override
  Future delete(int? id) async {
    return await _removeAddressByID(id);
  }

  Future<ResponseModel> _removeAddressByID(int? id) async {
    final Response response = await apiClient.postData(
      '${AppConstants.removeAddressUri}$id',
      {'_method': 'delete'},
      handleError: false,
    );

    if (response.statusCode == 200) {
      return ResponseModel(
        true,
        response.body['message']?.toString(),
      );
    } else {
      return ResponseModel(false, response.statusText);
    }
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) async {
    return await _getAllAddress();
  }

  Future<List<AddressModel>?> _getAllAddress() async {
    List<AddressModel>? addressList;

    final Response response = await apiClient.getData(
      AppConstants.addressListUri,
      useEtag: false,
    );

    if (response.statusCode == 200) {
      addressList = [];

      if (response.body['addresses'] != null && response.body['addresses'] is List) {
        for (final address in response.body['addresses'] as List) {
          addressList.add(
            AddressModel.fromJson(address as Map<String, dynamic>),
          );
        }
      }
    }

    return addressList;
  }

  @override
  Future update(Map<String, dynamic> body, int? id) async {
    return await _updateAddress(body, id);
  }

  Future<ResponseModel> _updateAddress(
    Map<String, dynamic> addressBody,
    int? addressId,
  ) async {
    final Response response = await apiClient.putData(
      '${AppConstants.updateAddressUri}$addressId',
      addressBody,
    );

    if (response.statusCode == 200) {
      return ResponseModel(
        true,
        response.body['message']?.toString(),
      );
    } else {
      return ResponseModel(false, response.statusText);
    }
  }
}
