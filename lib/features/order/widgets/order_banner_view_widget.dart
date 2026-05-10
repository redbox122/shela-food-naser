import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';

enum _OrderBannerCandidateType { cover, logo, asset }

class _OrderBannerCandidate {
  final _OrderBannerCandidateType type;
  final String? url;

  const _OrderBannerCandidate({required this.type, this.url});
}

class _OrderBannerFailoverImage extends StatefulWidget {
  final int? orderId;
  final double height;
  final String? coverUrl;
  final String? logoUrl;
  final String fallbackAssetPath;
  final bool Function(String? url) isUsableUrl;

  const _OrderBannerFailoverImage({
    super.key,
    required this.orderId,
    required this.height,
    required this.coverUrl,
    required this.logoUrl,
    required this.fallbackAssetPath,
    required this.isUsableUrl,
  });

  @override
  State<_OrderBannerFailoverImage> createState() =>
      _OrderBannerFailoverImageState();
}

class _OrderBannerFailoverImageState extends State<_OrderBannerFailoverImage> {
  static final Set<String> _failedBannerUrls = <String>{};
  late List<_OrderBannerCandidate> _candidates;
  int _candidateIndex = 0;
  int? _lastLoggedIndex;
  int? _scheduledCandidateIndex;

  static String? _normalizeUrl(String? url) {
    if (url == null) {
      return null;
    }
    final String normalized = url.trim();
    if (normalized.isEmpty) {
      return null;
    }
    return normalized;
  }

  static bool isFailedUrl(String? url) {
    final String? normalized = _normalizeUrl(url);
    if (normalized == null) {
      return false;
    }
    return _failedBannerUrls.contains(normalized);
  }

  static void markUrlAsFailed(String? url) {
    final String? normalized = _normalizeUrl(url);
    if (normalized == null) {
      return;
    }
    _failedBannerUrls.add(normalized);
  }

  @override
  void initState() {
    super.initState();
    _rebuildCandidates(resetIndex: true);
  }

  @override
  void didUpdateWidget(covariant _OrderBannerFailoverImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderId != widget.orderId ||
        oldWidget.coverUrl != widget.coverUrl ||
        oldWidget.logoUrl != widget.logoUrl ||
        oldWidget.height != widget.height ||
        oldWidget.fallbackAssetPath != widget.fallbackAssetPath) {
      _rebuildCandidates(resetIndex: true);
    }
  }

  void _rebuildCandidates({required bool resetIndex}) {
    final List<_OrderBannerCandidate> candidates = <_OrderBannerCandidate>[];
    final bool isCoverUsable = widget.isUsableUrl(widget.coverUrl);
    final bool isLogoUsable = widget.isUsableUrl(widget.logoUrl);
    final bool skipCover = isCoverUsable && isFailedUrl(widget.coverUrl);
    final bool skipLogo = isLogoUsable && isFailedUrl(widget.logoUrl);

    if (skipCover && kDebugMode) {
      debugPrint(
          '[ORDER_BANNER_SKIP_FAILED_URL] orderId=${widget.orderId} type=cover');
    }
    if (skipLogo && kDebugMode) {
      debugPrint(
          '[ORDER_BANNER_SKIP_FAILED_URL] orderId=${widget.orderId} type=logo');
    }

    if (isCoverUsable && !skipCover) {
      candidates.add(
          _OrderBannerCandidate(type: _OrderBannerCandidateType.cover, url: widget.coverUrl));
    }
    if (isLogoUsable && !skipLogo) {
      candidates
          .add(_OrderBannerCandidate(type: _OrderBannerCandidateType.logo, url: widget.logoUrl));
    }
    candidates.add(const _OrderBannerCandidate(type: _OrderBannerCandidateType.asset));
    _candidates = candidates;
    if (resetIndex) {
      _candidateIndex = 0;
      _lastLoggedIndex = null;
    } else if (_candidateIndex >= _candidates.length) {
      _candidateIndex = _candidates.length - 1;
    }
    if (kDebugMode) {
      debugPrint(
          '[ORDER_BANNER_CANDIDATES] orderId=${widget.orderId} cover=${isCoverUsable && !skipCover} logo=${isLogoUsable && !skipLogo} fallback=asset count=${_candidates.length}');
    }
  }

  String _candidateTypeLabel(_OrderBannerCandidateType type) {
    switch (type) {
      case _OrderBannerCandidateType.cover:
        return 'cover';
      case _OrderBannerCandidateType.logo:
        return 'logo';
      case _OrderBannerCandidateType.asset:
        return 'asset';
    }
  }

  void _logCandidateShown(_OrderBannerCandidate candidate) {
    if (_lastLoggedIndex == _candidateIndex) {
      return;
    }
    _lastLoggedIndex = _candidateIndex;
    if (kDebugMode) {
      final String typeLabel = _candidateTypeLabel(candidate.type);
      debugPrint(
          '[ORDER_BANNER_SHOW_CANDIDATE] orderId=${widget.orderId} index=$_candidateIndex type=$typeLabel');
      if (candidate.type == _OrderBannerCandidateType.asset) {
        debugPrint('[ORDER_BANNER_ASSET_USED] orderId=${widget.orderId}');
      }
    }
  }

  void _handleCandidateError(_OrderBannerCandidate candidate, String url) {
    if (!mounted) {
      return;
    }
    final int failedIndex = _candidateIndex;
    final String fromType = _candidateTypeLabel(candidate.type);
    if (kDebugMode) {
      debugPrint(
          '[ORDER_BANNER_CANDIDATE_ERROR] orderId=${widget.orderId} index=$failedIndex type=$fromType url=$url');
    }
    if (candidate.type != _OrderBannerCandidateType.asset) {
      markUrlAsFailed(candidate.url ?? url);
    }
    _rebuildCandidates(resetIndex: false);
    int nextIndex = _candidateIndex;
    if (nextIndex < _candidates.length &&
        _candidates[nextIndex].type == candidate.type) {
      nextIndex++;
    }
    if (nextIndex >= _candidates.length) {
      return;
    }
    final String toType = _candidateTypeLabel(_candidates[nextIndex].type);
    if (kDebugMode) {
      debugPrint(
          '[ORDER_BANNER_FAILOVER] orderId=${widget.orderId} from=$fromType to=$toType');
      debugPrint(
          '[ORDER_BANNER_FAILOVER_SCHEDULED] orderId=${widget.orderId} from=$fromType to=$toType');
    }
    if (_scheduledCandidateIndex == nextIndex) {
      return;
    }
    _scheduledCandidateIndex = nextIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (_candidateIndex >= nextIndex) {
        _scheduledCandidateIndex = null;
        return;
      }
      setState(() {
        _candidateIndex = nextIndex;
        _lastLoggedIndex = null;
        _scheduledCandidateIndex = null;
      });
      if (kDebugMode) {
        debugPrint(
            '[ORDER_BANNER_FAILOVER_APPLIED] orderId=${widget.orderId} from=$fromType to=$toType');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final _OrderBannerCandidate candidate = _candidates[_candidateIndex];
    _logCandidateShown(candidate);
    if (candidate.type == _OrderBannerCandidateType.asset) {
      return Image.asset(
        widget.fallbackAssetPath,
        key: ValueKey<String>(
            'order_banner_${widget.orderId}_asset_${_candidateIndex}_${widget.height.toStringAsFixed(0)}'),
        height: widget.height,
        width: double.infinity,
        fit: BoxFit.contain,
      );
    }
    final String imageUrl = candidate.url ?? '';
    final String typeLabel = _candidateTypeLabel(candidate.type);
    return CustomImage(
      key: ValueKey<String>(
          'order_banner_${widget.orderId}_${typeLabel}_${_candidateIndex}_$imageUrl'),
      image: imageUrl,
      height: widget.height,
      width: double.infinity,
      onImageError: (url, error) {
        _handleCandidateError(candidate, url);
      },
      errorWidget: Image.asset(
        widget.fallbackAssetPath,
        height: widget.height,
        width: double.infinity,
        fit: BoxFit.contain,
      ),
    );
  }
}

class OrderBannerViewWidget extends StatelessWidget {
  final OrderModel order;
  final bool ongoing;
  final bool parcel;
  final bool prescriptionOrder;
  final OrderController orderController;

  const OrderBannerViewWidget({
    super.key,
    required this.order,
    required this.ongoing,
    required this.parcel,
    required this.prescriptionOrder,
    required this.orderController,
  });

  String getOrderImage() {
    switch (order.orderStatus) {
      case 'pending':
        return Images.pendingOrder;
      case 'confirmed':
        return Images.confirmedOrder;
      case 'processing':
        return Images.preparingOrder;
      case 'delivered':
        return Images.deliveredOrder;
      case 'handover':
        return Images.handoverOrder;
      default:
        return Images.pendingOrder;
    }
  }

  bool _isUsableUrl(String? url) {
    if (url == null) return false;
    final String trimmed = url.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') return false;
    return trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('/');
  }

  Widget _buildStatusFallback(double height) {
    return Image.asset(
      getOrderImage(),
      height: height,
      width: double.infinity,
      fit: BoxFit.contain,
    );
  }

  Widget _buildStoreCover({
    required double height,
    String? primaryUrl,
    String? secondaryUrl,
  }) {
    final String candidateSignature = _buildCandidateSignature(
      coverUrl: primaryUrl,
      logoUrl: secondaryUrl,
    );
    return _OrderBannerFailoverImage(
      key: ValueKey<String>(
          'order_banner_failover_${order.id}_$candidateSignature'),
      orderId: order.id,
      height: height,
      coverUrl: primaryUrl,
      logoUrl: secondaryUrl,
      fallbackAssetPath: getOrderImage(),
      isUsableUrl: _isUsableUrl,
    );
  }

  String _buildCandidateSignature({
    required String? coverUrl,
    required String? logoUrl,
  }) {
    final List<String> signatureParts = <String>[];
    if (_isUsableUrl(coverUrl) &&
        !_OrderBannerFailoverImageState.isFailedUrl(coverUrl)) {
      signatureParts.add('cover:${coverUrl ?? ''}');
    }
    if (_isUsableUrl(logoUrl) &&
        !_OrderBannerFailoverImageState.isFailedUrl(logoUrl)) {
      signatureParts.add('logo:${logoUrl ?? ''}');
    }
    signatureParts.add('asset:asset');
    return signatureParts.join('|');
  }

  Widget buildImageOrCover({required bool condition, double height = 160}) {
    if (condition) {
      if (kDebugMode) {
        debugPrint('[ORDER_BANNER_RENDER_PATH] fallback');
        debugPrint('[ORDER_BANNER_FALLBACK_USED] reason=condition_status_asset');
      }
      return _buildStatusFallback(height);
    }
    return _buildStoreCover(
      height: height,
      primaryUrl: order.store?.coverPhotoFullUrl,
      secondaryUrl: order.store?.logoFullUrl,
    );
  }

  Widget _buildParcelImage({required double height}) {
    final String? url = order.parcelCategory?.imageFullUrl;
    if (!_isUsableUrl(url)) {
      if (kDebugMode) {
        debugPrint('[ORDER_BANNER_RENDER_PATH] fallback');
        debugPrint(
            '[ORDER_BANNER_FALLBACK_USED] reason=parcel_image_missing');
      }
      return Image.asset(
        Images.pendingOrderDetails,
        height: height,
        width: double.infinity,
        fit: BoxFit.contain,
      );
    }
    return CustomImage(
      key: ValueKey<String>('order_parcel_banner_${order.id}_$url'),
      image: url!,
      height: height,
      errorWidget: Image.asset(
        Images.pendingOrderDetails,
        height: height,
        width: double.infinity,
        fit: BoxFit.contain,
      ),
    );
  }

  /// Resolves the module type for the order regardless of whether the details
  /// list has been populated yet. This is critical because on the second entry
  /// to the order details screen `trackOrder()` synchronously resets the
  /// `_orderDetails` list before `getOrderDetails()` can read it; if the
  /// subsequent fetch returns null the controller falls back to an empty list,
  /// which would otherwise hide the banner branches below.
  static String? resolveOrderModuleType(
    OrderModel order,
    OrderController orderController,
  ) {
    final List<dynamic>? details = orderController.orderDetails;
    if (details != null && details.isNotEmpty) {
      final String? fromDetails =
          orderController.orderDetails![0].itemDetails?.moduleType;
      if (fromDetails != null && fromDetails.isNotEmpty) {
        return fromDetails;
      }
    }
    return order.moduleType;
  }

  static String _normalizeModuleType(String? moduleType) {
    if (moduleType == null) {
      return '';
    }
    return moduleType.trim().toLowerCase().replaceAll('_', '').replaceAll('-', '');
  }

  static bool _isModuleCoverType(String? moduleType) {
    final String normalized = _normalizeModuleType(moduleType);
    return normalized == 'grocery' ||
        normalized == 'pharmacy' ||
        normalized == 'ecommerce';
  }

  @override
  Widget build(BuildContext context) {
    final splashController = Get.find<SplashController>();
    final moduleConfig = splashController.getModuleConfig(order.moduleType);
    final String? resolvedModuleType =
        resolveOrderModuleType(order, orderController);
    final bool hasModuleBanner = _isModuleCoverType(resolvedModuleType);
    final bool isStoreNull = order.store == null;
    if (kDebugMode) {
      debugPrint(
        '[ORDER_BANNER_BUILD] orderId=${order.id} status=${order.orderStatus} '
        'parcel=$parcel prescription=$prescriptionOrder ongoing=$ongoing '
        'detailsCount=${orderController.orderDetails?.length ?? 0} '
        'resolvedModuleType=$resolvedModuleType',
      );
      debugPrint(
        '[ORDER_BANNER_ORDER_ID] orderId=${order.id}',
      );
      debugPrint(
        '[ORDER_BANNER_COVER] hasCover=${(order.store?.coverPhotoFullUrl ?? '').isNotEmpty} '
        'usable=${_isUsableUrl(order.store?.coverPhotoFullUrl)}',
      );
      debugPrint(
        '[ORDER_BANNER_LOGO] hasLogo=${(order.store?.logoFullUrl ?? '').isNotEmpty} '
        'usable=${_isUsableUrl(order.store?.logoFullUrl)}',
      );
      debugPrint('[ORDER_BANNER_STORE_NULL] $isStoreNull');
      debugPrint(
          '[ORDER_BANNER_SECOND_OPEN] detailsCount=${orderController.orderDetails?.length ?? 0} hasModuleBanner=$hasModuleBanner');
    }

    return Column(children: [
      if (DateConverter.isBeforeTime(order.scheduleAt) && (moduleConfig.newVariation ?? false))
        ongoing
            ? Column(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildStatusFallback(200),
                ),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                Text(
                  'your_food_will_delivered_within'.tr,
                  style: robotoRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateConverter.differenceInMinute(
                                    order.store!.deliveryTime, order.createdAt, order.processingTime, order.scheduleAt) <
                                5
                            ? '1 - 5'
                            : '${DateConverter.differenceInMinute(order.store!.deliveryTime, order.createdAt, order.processingTime, order.scheduleAt) - 5} - '
                                '${DateConverter.differenceInMinute(order.store!.deliveryTime, order.createdAt, order.processingTime, order.scheduleAt)}',
                        style: robotoBold.copyWith(fontSize: Dimensions.fontSizeExtraLarge),
                        textDirection: TextDirection.ltr,
                      ),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      Text(
                        'min'.tr,
                        style: robotoMedium.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraLarge),
              ])
            : _buildStoreCover(
                height: 150,
                primaryUrl: order.store?.coverPhotoFullUrl,
                secondaryUrl: order.store?.logoFullUrl,
              ),
      if (parcel)
        (ongoing && order.orderStatus == 'pending')
            ? Builder(builder: (_) {
                if (kDebugMode) {
                  debugPrint('[ORDER_BANNER_RENDER_PATH] fallback');
                  debugPrint(
                      '[ORDER_BANNER_FALLBACK_USED] reason=parcel_pending_asset');
                }
                return Image.asset(
                  Images.pendingOrderDetails,
                  height: 160,
                  width: double.infinity,
                );
              })
            : _buildParcelImage(height: 160),
      if (prescriptionOrder) buildImageOrCover(condition: ongoing, height: 180),
      // 🔧 FIX: Use the resolved module type so the banner still renders on
      // re-entry when `orderController.orderDetails` is briefly empty (the
      // controller nulls and refetches it on every open). Falls back to
      // `order.moduleType` from the track model.
      if (hasModuleBanner && _normalizeModuleType(resolvedModuleType) == 'grocery')
        buildImageOrCover(
            condition: ongoing && order.orderStatus == 'pending', height: 180),
      if (hasModuleBanner && _normalizeModuleType(resolvedModuleType) == 'pharmacy')
        buildImageOrCover(
            condition: ongoing && order.orderStatus == 'pending', height: 180),
      if (hasModuleBanner && _normalizeModuleType(resolvedModuleType) == 'ecommerce')
        buildImageOrCover(
            condition: ongoing && order.orderStatus == 'pending', height: 180),
      if (!DateConverter.isBeforeTime(order.scheduleAt) &&
          !parcel &&
          !prescriptionOrder &&
          !hasModuleBanner)
        _buildStoreCover(
          height: 150,
          primaryUrl: order.store?.coverPhotoFullUrl,
          secondaryUrl: order.store?.logoFullUrl,
        ),
    ]);
  }
}
