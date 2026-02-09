import 'package:sixam_mart/common/models/response_model.dart';
import 'package:sixam_mart/features/review/domain/models/review_body_model.dart';
import 'package:sixam_mart/features/review/domain/models/review_model.dart';
import 'package:sixam_mart/features/review/domain/repositories/review_repository_interface.dart';
import 'package:sixam_mart/features/review/domain/services/review_service_interface.dart';

class ReviewService implements ReviewServiceInterface {
  final ReviewRepositoryInterface reviewRepositoryInterface;
  ReviewService({required this.reviewRepositoryInterface});

  @override
  Future<List<ReviewModel>?> getStoreReviewList(String? storeID) async {
    final result = await reviewRepositoryInterface.getList(storeID: storeID);
    return result;
  }


  @override
  Future<ResponseModel> submitReview(ReviewBodyModel reviewBody) async {
    final result = await reviewRepositoryInterface.submitReview(reviewBody);
    return result is ResponseModel ? result : ResponseModel(false, 'Error submitting review');
  }

  @override
  Future<ResponseModel> submitDeliveryManReview(ReviewBodyModel reviewBody) async {
    final result = await reviewRepositoryInterface.submitDeliveryManReview(reviewBody);
    return result is ResponseModel ? result : ResponseModel(false, 'Error submitting delivery man review');
  }


}