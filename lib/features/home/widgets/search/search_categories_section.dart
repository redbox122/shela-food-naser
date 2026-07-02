import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/core/cache/simple_json_cache.dart';
import 'package:sixam_mart/features/home/screens/category_results_screen.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// 🗂️ "Browse categories" section shown at the top of the search screen. Tapping
/// a category opens [CategoryResultsScreen] with that category's stores and
/// products. Fetches `/api/v2/categories` (module-scoped) with a stale-while-
/// revalidate cache so it paints instantly.
class SearchCategoriesSection extends StatefulWidget {
  final int? moduleId;
  const SearchCategoriesSection({super.key, this.moduleId});

  @override
  State<SearchCategoriesSection> createState() =>
      _SearchCategoriesSectionState();
}

class _SearchCategoriesSectionState extends State<SearchCategoriesSection> {
  List<_Cat> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  String get _cacheKey => 'search_cats_${widget.moduleId ?? 0}';

  List<_Cat> _parse(dynamic body) {
    final List raw = body is List
        ? body
        : (body is Map && body['data'] is List)
            ? body['data'] as List
            : (body is Map && body['categories'] is List)
                ? body['categories'] as List
                : const [];
    return raw
        .whereType<Map>()
        .map((e) => _Cat.fromJson(Map<String, dynamic>.from(e)))
        .where((c) => c.id != null && (c.name ?? '').isNotEmpty)
        .toList();
  }

  Future<void> _fetch() async {
    if (!Get.isRegistered<ApiClient>()) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    // Instant paint from cache.
    final cached = SimpleJsonCache.read(_cacheKey);
    if (cached != null) {
      final items = _parse(cached);
      if (mounted && items.isNotEmpty) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    }
    try {
      final r = await Get.find<ApiClient>().getData(
        '/api/v2/categories',
        headers: {
          AppConstants.localizationKey: 'ar',
          if (widget.moduleId != null)
            AppConstants.moduleId: widget.moduleId.toString(),
        },
        useEtag: false,
      );
      if (!mounted) return;
      final items = _parse(r.body);
      setState(() {
        if (items.isNotEmpty) _items = items;
        _loading = false;
      });
      SimpleJsonCache.write(_cacheKey, r.body);
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _items.isEmpty) return _shimmer();
    if (_items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              top: Dimensions.paddingSizeDefault,
              bottom: Dimensions.paddingSizeSmall),
          child: Text('تصفّح الأقسام',
              textAlign: TextAlign.right,
              style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (_, i) => _CategoryCard(
            category: _items[i],
            moduleId: widget.moduleId,
          ),
        ),
      ],
    );
  }

  Widget _shimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(
              top: Dimensions.paddingSizeDefault,
              bottom: Dimensions.paddingSizeSmall),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade100,
            child: Container(height: 16, width: 120, color: Colors.white),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.82,
          ),
          itemBuilder: (_, __) => Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade100,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Rounded category tile: image on a soft-green disc + name below.
class _CategoryCard extends StatelessWidget {
  final _Cat category;
  final int? moduleId;
  const _CategoryCard({required this.category, this.moduleId});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Get.to<void>(() => CategoryResultsScreen(
            categoryId: category.id!,
            categoryName: category.name ?? '',
            moduleId: moduleId,
          )),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6EC),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(12),
              child: CustomImage(
                image: category.image ?? '',
                fit: BoxFit.contain,
                placeholder: Images.placeholder,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            category.name ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: robotoMedium.copyWith(fontSize: Dimensions.fontSizeSmall),
          ),
        ],
      ),
    );
  }
}

class _Cat {
  final int? id;
  final String? name;
  final String? image;
  _Cat({this.id, this.name, this.image});

  factory _Cat.fromJson(Map<String, dynamic> j) => _Cat(
        id: int.tryParse('${j['id'] ?? ''}'),
        name: j['name']?.toString(),
        image: (j['image_full_url'] ?? j['image'])?.toString(),
      );
}
