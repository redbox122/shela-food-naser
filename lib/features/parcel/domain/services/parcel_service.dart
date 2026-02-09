import 'package:get/get_connect/http/src/response/response.dart';
import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/checkout/domain/models/place_order_body_model.dart';
import 'package:sixam_mart/features/checkout/domain/repositories/checkout_repository_interface.dart';
import 'package:sixam_mart/features/parcel/domain/models/parcel_category_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/video_content_model.dart';
import 'package:sixam_mart/features/parcel/domain/models/why_choose_model.dart';
import 'package:sixam_mart/features/parcel/domain/repositories/parcel_repository_interface.dart';
import 'package:sixam_mart/features/parcel/domain/services/parcel_service_interface.dart';
import 'package:sixam_mart/features/payment/domain/models/offline_method_model.dart';

import '../models/parcel_instruction_model.dart';

class ParcelService implements ParcelServiceInterface{
  final ParcelRepositoryInterface parcelRepositoryInterface;
  final CheckoutRepositoryInterface checkoutRepositoryInterface;
  ParcelService({required this.parcelRepositoryInterface, required this.checkoutRepositoryInterface});

  @override
  Future<List<ParcelCategoryModel>?> getParcelCategory() async {
    final result = await parcelRepositoryInterface.getList();
    return result is List<ParcelCategoryModel>? ? result : null;
  }

  @override
  Future<List<Data>?> getParcelInstruction(int offset) async {
    final result = await parcelRepositoryInterface.getList(offset: offset, parcelCategory: false);
    return result is List<Data>? ? result : null;
  }

  @override
  Future<WhyChooseModel?> getWhyChooseDetails({required DataSourceEnum source}) async {
    final result = await parcelRepositoryInterface.get(null, isVideoDetails: false, source: source);
    return result is WhyChooseModel? ? result : null;
  }

  @override
  Future<VideoContentModel?> getVideoContentDetails({required DataSourceEnum source}) async {
    final result = await parcelRepositoryInterface.get(null, source: source);
    return result is VideoContentModel? ? result : null;
  }

  @override
  Future<Response> getPlaceDetails(String? placeID) async {
    return await parcelRepositoryInterface.getPlaceDetails(placeID);
  }

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
  Future<Response> placeOrder(PlaceOrderBodyModel orderBody) async {
    return await checkoutRepositoryInterface.placeOrder(orderBody, null);
  }

}