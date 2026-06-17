import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 REDESIGN (Market): horizontal categories rail.
///
/// Wired to `GET /api/v2/categories`, scoped to the market (grocery) module via
/// the moduleId header. Each card shows the category image with its name.
class MarketCategoriesSection extends StatefulWidget {
  final int? moduleId;

  /// Currently selected category id (drives the active card state).
  final int? selectedId;

  /// Called when a card is tapped (passes null to clear when re-tapped).
  final ValueChanged<int?>? onSelect;

  const MarketCategoriesSection({
    super.key,
    this.moduleId,
    this.selectedId,
    this.onSelect,
  });

  static const double _railHeight = 94;
  static const double _cardWidth = 90;

  @override
  State<MarketCategoriesSection> createState() =>
      _MarketCategoriesSectionState();
}

/// Lightweight model for a row of the `/categories` response.
class _Cat {
  final int? id;
  final String? name;
  final String? image;

  _Cat({this.id, this.name, this.image});

  factory _Cat.fromJson(Map<String, dynamic> j) => _Cat(
        id: int.tryParse('${j['id']}'),
        name: j['name']?.toString(),
        // Tolerant: v2 *_full_url, else legacy image.
        image: (j['image_full_url'] ?? j['image'])?.toString(),
      );
}

class _MarketCategoriesSectionState extends State<MarketCategoriesSection> {
  List<_Cat> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    if (!Get.isRegistered<ApiClient>()) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final response = await Get.find<ApiClient>().getData(
        '/api/v2/categories',
        headers: {
          AppConstants.localizationKey: 'ar',
          if (widget.moduleId != null)
            AppConstants.moduleId: widget.moduleId.toString(),
        },
        useEtag: false,
      );
      if (!mounted) return;
      final dynamic body = response.body;
      final List raw = body is List
          ? body
          : (body is Map && body['data'] is List)
              ? body['data'] as List
              : (body is Map && body['categories'] is List)
                  ? body['categories'] as List
                  : const [];
      setState(() {
        _items = raw
            .whereType<Map>()
            .map((e) => _Cat.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: Dimensions.paddingSizeSmall),
      child: SizedBox(
        height: MarketCategoriesSection._railHeight,
        child: _loading
            ? _buildSkeleton(context)
            : ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final cat = _items[i];
                  final bool selected =
                      cat.id != null && cat.id == widget.selectedId;
                  return _CategoryCard(
                    cat: cat,
                    selected: selected,
                    onTap: () =>
                        widget.onSelect?.call(selected ? null : cat.id),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Shimmer.fromColors(
      baseColor:
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
      highlightColor:
          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.03),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => Container(
          width: MarketCategoriesSection._cardWidth,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final _Cat cat;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.cat,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(4);
    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: Container(
        width: MarketCategoriesSection._cardWidth,
        height: MarketCategoriesSection._cardWidth, // 90×90 square
        decoration: BoxDecoration(
          borderRadius: radius,
          // Active state: EBFEEB tint only (no border).
          color: selected ? const Color(0xFFEBFEEB) : null,
          image: selected
              ? null
              : const DecorationImage(
                  image: AssetImage(Images.background_category),
                  fit: BoxFit.cover,
                ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Product image at the bottom (over the green diagonal).
            Positioned(
              left: 6,
              right: 6,
              bottom: 4,
              child: CustomImage(
                image: cat.image ?? '',
                width: MarketCategoriesSection._cardWidth - 12,
                height: 46,
                fit: BoxFit.contain,
                placeholder: Images.placeholder,
              ),
            ),
            // Category name at the top, right-aligned (RTL).
            Positioned(
              top: 6,
              right: 6,
              left: 1,
              child: Text(
                cat.name ?? '',
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  height: 1.2,
                  color: Color(0xFF237D2E), // hsba(127,72%,49%,1)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
