import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/loading/loading.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/domain/models/order_model.dart';
import 'package:sixam_mart/features/order/screens/order_details_screen.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/date_converter.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

/// 🎨 REDESIGN: "طلباتي" — the customer orders screen.
///
/// Replaces the tab-based [OrderScreen] layout with the new design language:
/// a centered header, horizontal module filter chips ("الكل" + per-module),
/// and orders grouped under date headers (اليوم / الأمس / full date). Empty
/// state shows the [Images.noOrders] illustration.
///
/// Data comes from [OrderController]: the running, history, and canceled lists
/// are merged, de-duplicated by id, and sorted newest-first.
class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  /// Selected module filter; null = "الكل" (all modules).
  String? _selectedModuleType;

  /// Active time/status filters set from the filter bottom sheet.
  _OrdersFilter _filter = const _OrdersFilter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !AuthHelper.isLoggedIn()) return;
      final OrderController controller = Get.find<OrderController>();
      controller.getRunningOrders(1);
      controller.getHistoryOrders(1);
    });
  }

  /// Merge running + history + canceled into a single newest-first list,
  /// de-duplicated by order id.
  List<OrderModel> _mergedOrders(OrderController c) {
    final Map<int, OrderModel> byId = <int, OrderModel>{};
    for (final PaginatedOrderModel? model in <PaginatedOrderModel?>[
      c.runningOrderModel,
      c.historyOrderModel,
      c.canceledOrderModel,
    ]) {
      for (final OrderModel order in model?.orders ?? const <OrderModel>[]) {
        if (order.id != null) byId[order.id!] = order;
      }
    }
    final List<OrderModel> orders = byId.values.toList();
    orders.sort((a, b) {
      final DateTime da = _orderDate(a) ?? DateTime(1970);
      final DateTime db = _orderDate(b) ?? DateTime(1970);
      return db.compareTo(da);
    });
    return orders;
  }

  static DateTime? _orderDate(OrderModel order) {
    final String raw = order.createdAt ?? '';
    if (raw.isEmpty) return null;
    try {
      return DateConverter.dateTimeStringToDate(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: Column(
        children: [
          _Header(
            title: 'my_orders'.tr,
            hasActiveFilter: _filter.isActive,
            onFilter: AuthHelper.isLoggedIn() ? _openFilterSheet : null,
          ),
          Expanded(
            child: !AuthHelper.isLoggedIn()
                ? const _EmptyOrders()
                : GetBuilder<OrderController>(
                    builder: (controller) {
                      final bool loading = controller.Order_isLoading ||
                          controller.isLoadingHistoryOrders;
                      // Both lists have completed their first fetch only once
                      // running has loaded AND the history model is populated
                      // (it is reset to null at the start of each load).
                      final bool loadedOnce =
                          controller.hasLoadedRunningOrders &&
                              controller.historyOrderModel != null;
                      final List<OrderModel> all = _mergedOrders(controller);

                      if (all.isEmpty) {
                        // Keep showing the loader until the first fetch settles,
                        // so the empty state never flashes before the data
                        // arrives.
                        if (loading ||
                            (!loadedOnce && !controller.hasOrderError)) {
                          return const Center(child: LoadingWidget());
                        }
                        return const _EmptyOrders();
                      }

                      final List<String> modules = _moduleTypes(all);
                      final List<OrderModel> filtered = all.where((o) {
                        if (_selectedModuleType != null &&
                            o.moduleType != _selectedModuleType) {
                          return false;
                        }
                        if (!_filter.matchesDate(_orderDate(o))) return false;
                        if (!_filter.matchesStatus(o.orderStatus)) return false;
                        return true;
                      }).toList();

                      return Column(
                        children: [
                          _ModuleFilterBar(
                            modules: modules,
                            selected: _selectedModuleType,
                            onSelect: (m) =>
                                setState(() => _selectedModuleType = m),
                          ),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () async {
                                await controller.getRunningOrders(1,
                                    isUpdate: true);
                                await controller.getHistoryOrders(1,
                                    isUpdate: true);
                              },
                              child: filtered.isEmpty
                                  ? const _EmptyOrders()
                                  : _OrdersList(orders: filtered),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Distinct module types present in the orders, ordered by first appearance.
  List<String> _moduleTypes(List<OrderModel> orders) {
    final List<String> seen = <String>[];
    for (final OrderModel o in orders) {
      final String? m = o.moduleType;
      if (m != null && m.isNotEmpty && !seen.contains(m)) seen.add(m);
    }
    return seen;
  }

  Future<void> _openFilterSheet() async {
    final _OrdersFilter? result = await showModalBottomSheet<_OrdersFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OrdersFilterSheet(initial: _filter),
    );
    if (result != null && mounted) {
      setState(() => _filter = result);
    }
  }
}

/// Header row: back chevron (RTL right), centered title, filter button (left).
class _Header extends StatelessWidget {
  final String title;

  /// When non-null, a filter button is shown on the trailing (left in RTL) side.
  final VoidCallback? onFilter;

  /// Shows a small dot on the filter button when any filter is applied.
  final bool hasActiveFilter;

  const _Header({
    required this.title,
    this.onFilter,
    this.hasActiveFilter = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Dimensions.paddingSizeSmall,
          vertical: Dimensions.paddingSizeSmall,
        ),
        child: Row(
          children: [
            Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Get.back<void>(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.arrow_back_ios_new,
                      size: 22, color: Color(0xFF121C19)),
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  height: 1.6,
                  color: Color(0xFF121C19),
                ),
              ),
            ),
            // Filter button (RTL: on the left). Reserves equal width even when
            // hidden so the title stays optically centered.
            SizedBox(
              width: 38,
              child: onFilter == null
                  ? null
                  : Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onFilter,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            hasActiveFilter
                                ? Images.filterCandleActive
                                : Images.filterCandle,
                            width: 22,
                            height: 22,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.tune,
                                size: 22,
                                color: Color(0xFF121C19)),
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
}

/// Horizontal module filter chips: "الكل" + one chip per module type.
class _ModuleFilterBar extends StatelessWidget {
  final List<String> modules;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _ModuleFilterBar({
    required this.modules,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault),
        itemCount: modules.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            return _Chip(
              label: 'orders_filter_all'.tr,
              selected: selected == null,
              onTap: () => onSelect(null),
            );
          }
          final String module = modules[i - 1];
          return _Chip(
            label: _moduleLabel(module),
            selected: selected == module,
            onTap: () => onSelect(module),
          );
        },
      ),
    );
  }

  /// Best-effort Arabic label for a module type; falls back to its `.tr` key,
  /// then the raw value.
  static String _moduleLabel(String moduleType) {
    final String translated = moduleType.tr;
    if (translated != moduleType) return translated;
    return moduleType;
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF31A342) : const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w700,
            fontSize: 13,
            height: 1.2,
            color: selected ? Colors.white : const Color(0xFF545454),
          ),
        ),
      ),
    );
  }
}

/// Date-grouped list of order cards.
class _OrdersList extends StatelessWidget {
  final List<OrderModel> orders;

  const _OrdersList({required this.orders});

  @override
  Widget build(BuildContext context) {
    // Group preserving the (already newest-first) order.
    final List<_DateGroup> groups = <_DateGroup>[];
    for (final OrderModel order in orders) {
      final DateTime? date = _MyOrdersScreenState._orderDate(order);
      final String key = date == null
          ? ''
          : '${date.year}-${date.month}-${date.day}';
      if (groups.isNotEmpty && groups.last.key == key) {
        groups.last.orders.add(order);
      } else {
        groups.add(_DateGroup(key: key, date: date)..orders.add(order));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        top: Dimensions.paddingSizeSmall,
        bottom: Dimensions.paddingSizeExtraLarge,
      ),
      itemCount: groups.length,
      itemBuilder: (context, i) {
        final _DateGroup group = groups[i];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeSmall,
              ),
              child: Text(
                _groupLabel(group.date),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  height: 1.6,
                  // Text-disable-input — hsba(219, 15%, 52%, 1).
                  color: Color(0xFF717885),
                ),
              ),
            ),
            ...group.orders.map((o) => _OrderCard(order: o)),
          ],
        );
      },
    );
  }

  /// "اليوم" / "أمس" / full readable date (e.g. الأربعاء، 26 فبراير، 2026).
  String _groupLabel(DateTime? date) {
    if (date == null) return '';
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime d = DateTime(date.year, date.month, date.day);
    final int diff = today.difference(d).inDays;
    if (diff == 0) return 'today'.tr;
    if (diff == 1) return 'yesterday'.tr;
    final String locale = Get.locale?.languageCode ?? 'ar';
    return DateFormat('EEEE، d MMMM، yyyy', locale).format(date);
  }
}

class _DateGroup {
  final String key;
  final DateTime? date;
  final List<OrderModel> orders = <OrderModel>[];

  _DateGroup({required this.key, required this.date});
}

/// A single order row (≈343×127) matching the redesign spec.
class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final bool isParcel = order.orderType == 'parcel';
    final String name =
        isParcel ? 'parcel'.tr : (order.store?.name ?? '');
    final String logo = isParcel
        ? (order.parcelCategory?.imageFullUrl ?? '')
        : (order.store?.logoFullUrl ?? '');
    final DateTime? date = _MyOrdersScreenState._orderDate(order);
    final _StatusStyle status = _StatusStyle.fromStatus(order.orderStatus);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.paddingSizeDefault,
        0,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeSmall,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Get.toNamed<void>(
            RouteHelper.getOrderDetailsRoute(order.id),
            arguments: OrderDetailsScreen(
              orderId: order.id,
              orderModel: order,
              contactNumber:
                  order.deliveryAddress?.contactPersonNumber ?? '',
            ),
          );
        },
        child: Container(
          height: 127,
          padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEDEFF1)),
          ),
          child: Row(
            children: [
              // Leading chevron (RTL → on the left).
              const Icon(Icons.arrow_forward_ios,
                  size: 16, color: Color(0xFFAEB4BC)),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              // Store / parcel image.
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomImage(
                  image: logo,
                  height: 92,
                  width: 92,
                  fit: BoxFit.cover,
                  placeholder: Images.placeholder,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              // Text content (right side in RTL).
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        height: 1.2,
                        color: Color(0xFF121C19),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusBadge(style: status),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'order_date_label'.tr,
                      value: date == null
                          ? ''
                          : DateConverter.dateToTimeOnly(date),
                    ),
                    const SizedBox(height: 4),
                    _InfoRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'order_total_label'.tr,
                      value: PriceConverter.convertPrice(order.orderAmount ?? 0),
                      valueIsHtml: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A "label value" info line with a leading icon.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  /// [PriceConverter.convertPrice] may return markup-ish currency; we render it
  /// as plain text either way, but strip simple tags when flagged.
  final bool valueIsHtml;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueIsHtml = false,
  });

  @override
  Widget build(BuildContext context) {
    final String cleanValue = valueIsHtml
        ? value.replaceAll(RegExp(r'<[^>]*>'), '').trim()
        : value;
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF8A9099)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$label $cleanValue',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w500,
              fontSize: 12,
              height: 1.2,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final _StatusStyle style;

  const _StatusBadge({required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w700,
          fontSize: 12,
          height: 1.2,
          color: style.foreground,
        ),
      ),
    );
  }
}

/// Maps a raw order status to a localized label + badge colors.
class _StatusStyle {
  final String label;
  final Color background;
  final Color foreground;

  const _StatusStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });

  factory _StatusStyle.fromStatus(String? status) {
    switch ((status ?? '').toLowerCase().trim()) {
      case 'handover':
      case 'picked_up':
      case 'out_for_delivery':
        return _StatusStyle(
          label: 'order_status_on_the_way'.tr,
          background: const Color(0xFF9DFCA3),
          foreground: const Color(0xFF1FA64A),
        );
      case 'delivered':
        return _StatusStyle(
          label: 'order_status_completed'.tr,
          background: const Color(0xFFEBFEEB),
          foreground: const Color(0xFF1FA64A),
        );
      case 'canceled':
      case 'cancelled':
      case 'failed':
      case 'expired':
        return _StatusStyle(
          label: 'order_status_canceled'.tr,
          background: const Color(0xFFFFDCDC),
          foreground: const Color(0xFFE5484D),
        );
      case 'refund_requested':
      case 'refunded':
        return _StatusStyle(
          label: 'order_status_refunded'.tr,
          background: const Color(0xFFFFF4E5),
          foreground: const Color(0xFFE08600),
        );
      case 'pending':
        return _StatusStyle(
          label: 'order_status_pending_label'.tr,
          background: const Color(0xFFEFEAFE),
          foreground: const Color(0xFF6B4EFF),
        );
      default:
        // confirmed / accepted / processing → "تحت الإعداد".
        return _StatusStyle(
          label: 'order_status_preparing'.tr,
          background: const Color(0xFFEFEAFE),
          foreground: const Color(0xFF6B4EFF),
        );
    }
  }
}

/// Buckets a raw order status into one of the three filter groups shown in the
/// filter sheet: 'preparing' / 'completed' / 'canceled'.
String _statusGroupOf(String? raw) {
  switch ((raw ?? '').toLowerCase().trim()) {
    case 'delivered':
      return 'completed';
    case 'canceled':
    case 'cancelled':
    case 'failed':
    case 'expired':
    case 'refund_requested':
    case 'refunded':
      return 'canceled';
    default:
      // pending / confirmed / accepted / processing / handover / picked_up.
      return 'preparing';
  }
}

/// Immutable time + status filter set chosen in the filter bottom sheet.
class _OrdersFilter {
  /// A specific selected day (mutually exclusive with [quickRange]).
  final DateTime? day;

  /// A quick relative range: 'today' | 'week' | 'month'.
  final String? quickRange;

  /// Selected status groups (subset of preparing/completed/canceled).
  final Set<String> statusGroups;

  const _OrdersFilter({
    this.day,
    this.quickRange,
    this.statusGroups = const <String>{},
  });

  bool get isActive =>
      day != null || quickRange != null || statusGroups.isNotEmpty;

  bool matchesDate(DateTime? date) {
    if (day == null && quickRange == null) return true;
    if (date == null) return false;
    final DateTime now = DateTime.now();
    if (day != null) {
      return date.year == day!.year &&
          date.month == day!.month &&
          date.day == day!.day;
    }
    switch (quickRange) {
      case 'today':
        return date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      case 'week':
        final DateTime start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        return !date.isBefore(start);
      case 'month':
        return date.year == now.year && date.month == now.month;
      default:
        return true;
    }
  }

  bool matchesStatus(String? raw) {
    if (statusGroups.isEmpty) return true;
    return statusGroups.contains(_statusGroupOf(raw));
  }
}

/// The "فلتر" bottom sheet: time period (date field + quick chips) and order
/// status chips, applied with the "تم" button.
class _OrdersFilterSheet extends StatefulWidget {
  final _OrdersFilter initial;

  const _OrdersFilterSheet({required this.initial});

  @override
  State<_OrdersFilterSheet> createState() => _OrdersFilterSheetState();
}

class _OrdersFilterSheetState extends State<_OrdersFilterSheet> {
  late DateTime? _day = widget.initial.day;
  late String? _quickRange = widget.initial.quickRange;
  late final Set<String> _statuses = <String>{...widget.initial.statusGroups};

  static const Color _green = Color(0xFF31A342);

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _day ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1, 12, 31),
      cancelText: 'orders_filter_cancel'.tr,
      confirmText: 'orders_filter_done'.tr,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _green,
            onPrimary: Colors.white,
            onSurface: Color(0xFF121C19),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _day = picked;
        _quickRange = null; // a specific day overrides the quick range
      });
    }
  }

  void _selectQuick(String range) {
    setState(() {
      _quickRange = _quickRange == range ? null : range;
      if (_quickRange != null) _day = null;
    });
  }

  void _toggleStatus(String group) {
    setState(() {
      if (!_statuses.add(group)) _statuses.remove(group);
    });
  }

  @override
  Widget build(BuildContext context) {
    final String dateText =
        DateFormat('dd/MM/yyyy').format(_day ?? DateTime.now());

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        Dimensions.paddingSizeLarge,
        Dimensions.paddingSizeDefault,
        Dimensions.paddingSizeLarge,
        Dimensions.paddingSizeLarge +
            MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title row: centered title with a close (X) on the leading side.
          Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  'orders_filter_title'.tr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    height: 1.2,
                    color: Color(0xFF121C19),
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close,
                      size: 22, color: Color(0xFF121C19)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          // الفترة الزمنية
          _label('orders_filter_time_period'.tr),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F5F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Image.asset(
                    Images.calender,
                    width: 22,
                    height: 22,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.calendar_month, size: 22, color: _green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dateText,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        height: 1.2,
                        color: Color(0xFF121C19),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SheetChip(
                label: 'today'.tr,
                selected: _quickRange == 'today',
                onTap: () => _selectQuick('today'),
              ),
              _SheetChip(
                label: 'orders_filter_this_week'.tr,
                selected: _quickRange == 'week',
                onTap: () => _selectQuick('week'),
              ),
              _SheetChip(
                label: 'orders_filter_this_month'.tr,
                selected: _quickRange == 'month',
                onTap: () => _selectQuick('month'),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          // حالة الأوردر
          _label('orders_filter_status'.tr),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SheetChip(
                label: 'order_status_preparing'.tr,
                selected: _statuses.contains('preparing'),
                onTap: () => _toggleStatus('preparing'),
              ),
              _SheetChip(
                label: 'order_status_completed'.tr,
                selected: _statuses.contains('completed'),
                onTap: () => _toggleStatus('completed'),
              ),
              _SheetChip(
                label: 'order_status_canceled'.tr,
                selected: _statuses.contains('canceled'),
                onTap: () => _toggleStatus('canceled'),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraLarge),

          // تم
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop(
                  _OrdersFilter(
                    day: _day,
                    quickRange: _quickRange,
                    statusGroups: _statuses,
                  ),
                );
              },
              child: Text(
                'orders_filter_done'.tr,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            height: 1.2,
            color: Color(0xFF121C19),
          ),
        ),
      );
}

/// A selectable pill used inside the filter sheet.
class _SheetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SheetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF31A342)
              : const Color(0xFFF4F5F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontWeight: FontWeight.w600,
            fontSize: 13,
            height: 1.2,
            color: selected ? Colors.white : const Color(0xFF545454),
          ),
        ),
      ),
    );
  }
}

/// Empty / logged-out state: the [Images.noOrders] illustration + message.
class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            Images.noOrders,
            width: 241,
            height: 210,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Text(
            'my_orders_empty'.tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              height: 1.6,
              color: Color(0xFF121C19),
            ),
          ),
        ],
      ),
    );
  }
}
