import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/api/api_client.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/images.dart';

/// Result of the offers "فلتر" bottom sheet.
class OffersFilter {
  /// Selected shipping option — 'free_delivery' or 'fast_delivery' (single
  /// choice; null = any).
  final String? shipping;

  /// Selected store-category id (null = all).
  final int? categoryId;

  const OffersFilter({this.shipping, this.categoryId});
}

/// Opens the offers filter as a modal bottom sheet and returns the chosen
/// [OffersFilter] when the user taps "تم" (or null if dismissed).
Future<OffersFilter?> showOffersFilterSheet(
  BuildContext context, {
  int? moduleId,
  OffersFilter initial = const OffersFilter(),
}) {
  return showModalBottomSheet<OffersFilter>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => Directionality(
      textDirection: TextDirection.rtl,
      child: _OffersFilterSheet(moduleId: moduleId, initial: initial),
    ),
  );
}

/// Lightweight store-category option.
class _Cat {
  final int? id;
  final String? name;
  _Cat({this.id, this.name});
  factory _Cat.fromJson(Map<String, dynamic> j) => _Cat(
        id: int.tryParse('${j['id']}'),
        name: j['name']?.toString(),
      );
}

class _OffersFilterSheet extends StatefulWidget {
  final int? moduleId;
  final OffersFilter initial;

  const _OffersFilterSheet({required this.moduleId, required this.initial});

  @override
  State<_OffersFilterSheet> createState() => _OffersFilterSheetState();
}

class _OffersFilterSheetState extends State<_OffersFilterSheet> {
  late String? _shipping = widget.initial.shipping;
  late int? _categoryId = widget.initial.categoryId;

  List<_Cat> _categories = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchCategories());
  }

  Future<void> _fetchCategories() async {
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
      final dynamic body = response.body;
      final List raw = body is List
          ? body
          : (body is Map && body['data'] is List)
              ? body['data'] as List
              : (body is Map && body['categories'] is List)
                  ? body['categories'] as List
                  : const [];
      if (!mounted) return;
      setState(() {
        _categories = raw
            .whereType<Map>()
            .map((e) => _Cat.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Single-select: tapping the chosen option again clears it.
  void _selectShipping(String key) {
    setState(() => _shipping = _shipping == key ? null : key);
  }

  void _selectCategory(int? id) {
    setState(() => _categoryId = _categoryId == id ? null : id);
  }

  void _apply() {
    Navigator.of(context).pop(
      OffersFilter(shipping: _shipping, categoryId: _categoryId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header: title + close.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child:
                          Icon(Icons.close, size: 22, color: Color(0xFF121C19)),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'filter'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Color(0xFF121C19),
                      ),
                    ),
                  ),
                  // Spacer to balance the close icon and keep the title centered.
                  const SizedBox(width: 30),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('shipping'.tr),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _ShippingChip(
                          label: 'free_delivery'.tr,
                          icon: Images.truck_delivery_v2,
                          selected: _shipping == 'free_delivery',
                          onTap: () => _selectShipping('free_delivery'),
                        ),
                        const SizedBox(width: 10),
                        _ShippingChip(
                          label: 'fast_delivery'.tr,
                          icon: Images.time_v2,
                          selected: _shipping == 'fast_delivery',
                          onTap: () => _selectShipping('fast_delivery'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _sectionTitle('store_category'.tr),
                    const SizedBox(height: 4),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else
                      ..._categories.map(
                        (c) => _CategoryRow(
                          label: c.name ?? '',
                          selected: c.id == _categoryId,
                          onTap: () => _selectCategory(c.id),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // "تم" action.
            Padding(
              padding: EdgeInsets.fromLTRB(16, 6, 16, 16 + bottomInset),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _apply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F7A35),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'done'.tr,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: Color(0xFF121C19),
        ),
      );
}

/// Selectable shipping chip (green outline + tint when selected).
class _ShippingChip extends StatelessWidget {
  final String label;
  final String icon;
  final bool selected;
  final VoidCallback onTap;

  const _ShippingChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg =
        selected ? const Color(0xFF1F7A35) : const Color(0xFF121C19);
    final radius = BorderRadius.circular(10);
    return Material(
      // Active background: design token hsba(120, 7%, 100%) ≈ #EDFFED.
      color: selected ? const Color(0xFFEDFFED) : const Color(0xFFF6F5F8),
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected ? const Color(0xFF1F7A35) : Colors.transparent,
            ),
          ),
          child: Row(
            textDirection: TextDirection.rtl,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                icon,
                width: 18,
                height: 18,
                color: fg,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single-select store-category row (radio on the left, label on the right).
class _CategoryRow extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            Image.asset(
              selected ? Images.radio_active : Images.radio_not_active,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                  color: const Color(0xFF121C19),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
