import 'package:sixam_mart/common/utils/json_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';
import 'package:sixam_mart/util/app_constants.dart';

class AdvertisementModel {
  int? id;
  int? storeId;
  String? addType;
  String? title;
  String? description;
  String? startDate;
  String? endDate;
  String? pauseNote;
  String? coverImage;
  String? profileImage;
  String? videoAttachment;
  int? isRatingActive;
  int? isReviewActive;
  int? isPaid;
  int? createdById;
  String? createdByType;
  String? status;
  String? createdAt;
  String? updatedAt;
  int? isUpdated;
  String? cancellationNote;
  String? coverImageFullUrl;
  String? profileImageFullUrl;
  String? videoAttachmentFullUrl;
  double? averageRating;
  int? reviewsCommentsCount;

  AdvertisementModel({
    this.id,
    this.storeId,
    this.addType,
    this.title,
    this.description,
    this.startDate,
    this.endDate,
    this.pauseNote,
    this.coverImage,
    this.profileImage,
    this.videoAttachment,
    this.isRatingActive,
    this.isReviewActive,
    this.isPaid,
    this.createdById,
    this.createdByType,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.isUpdated,
    this.cancellationNote,
    this.coverImageFullUrl,
    this.profileImageFullUrl,
    this.videoAttachmentFullUrl,
    this.averageRating,
    this.reviewsCommentsCount,
  });

  AdvertisementModel.fromJson(Map<String, dynamic> json) {
    if (kDebugMode && AppConstants.enableVerboseLogs) {
      appLogger.debug("${json['description']} json['description']");
    }
    id = json.parseInt('id');
    storeId = json.parseInt('store_id');
    addType = json['add_type']?.toString();
    title = json['title']?.toString();
    description = json['description']?.toString();
    startDate = json['start_date']?.toString();
    endDate = json['end_date']?.toString();
    pauseNote = json['pause_note']?.toString();
    coverImage = json['cover_image']?.toString();
    profileImage = json['profile_image']?.toString();
    videoAttachment = json['video_attachment']?.toString();
    //priority = json['priority']?.toString();
    isRatingActive = json.parseInt('is_rating_active');
    isReviewActive = json.parseInt('is_review_active');
    isPaid = json.parseInt('is_paid');
    createdById = json.parseInt('created_by_id');
    createdByType = json['created_by_type']?.toString();
    status = json['status']?.toString();
    createdAt = json['created_at']?.toString();
    updatedAt = json['updated_at']?.toString();
    isUpdated = json.parseInt('is_updated');
    cancellationNote = json['cancellation_note']?.toString();
    coverImageFullUrl = json['cover_image_full_url']?.toString();
    profileImageFullUrl = json['profile_image_full_url']?.toString();
    videoAttachmentFullUrl = json['video_attachment_full_url']?.toString();
    averageRating = json.parseDouble('average_rating');
    reviewsCommentsCount = json.parseInt('reviews_comments_count');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['store_id'] = storeId;
    data['add_type'] = addType;
    data['title'] = title;
    data['description'] = description;
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['pause_note'] = pauseNote;
    data['cover_image'] = coverImage;
    data['profile_image'] = profileImage;
    data['video_attachment'] = videoAttachment;
    //data['priority'] = priority;
    data['is_rating_active'] = isRatingActive;
    data['is_review_active'] = isReviewActive;
    data['is_paid'] = isPaid;
    data['created_by_id'] = createdById;
    data['created_by_type'] = createdByType;
    data['status'] = status;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['is_updated'] = isUpdated;
    data['cancellation_note'] = cancellationNote;
    data['cover_image_full_url'] = coverImageFullUrl;
    data['profile_image_full_url'] = profileImageFullUrl;
    data['video_attachment_full_url'] = videoAttachmentFullUrl;
    data['average_rating'] = averageRating;
    data['reviews_comments_count'] = reviewsCommentsCount;
    return data;
  }
}
