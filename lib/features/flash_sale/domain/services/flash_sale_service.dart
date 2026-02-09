import 'package:sixam_mart/common/enums/data_source_enum.dart';
import 'package:sixam_mart/features/flash_sale/domain/models/flash_sale_model.dart';
import 'package:sixam_mart/features/flash_sale/domain/models/product_flash_sale.dart';
import 'package:sixam_mart/features/flash_sale/domain/repositories/flash_sale_repository_interface.dart';
import 'package:sixam_mart/features/flash_sale/domain/services/flash_sale_service_interface.dart';

class FlashSaleService implements FlashSaleServiceInterface{
  final FlashSaleRepositoryInterface flashSaleRepositoryInterface;
  FlashSaleService({required this.flashSaleRepositoryInterface});

  @override
  Future<FlashSaleModel?> getFlashSale(DataSourceEnum source) async {
    final result = await flashSaleRepositoryInterface.getFlashSale(source: source);
    return result is FlashSaleModel? ? result : null;
  }

  @override
  Future<ProductFlashSale?> getFlashSaleWithId(int id, int offset) async {
    final result = await flashSaleRepositoryInterface.getFlashSaleWithId(id, offset);
    return result is ProductFlashSale? ? result : null;
  }

}