import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sixam_mart/features/notification/controllers/notification_controller.dart';
import 'package:sixam_mart/features/notification/domain/models/notification_model.dart';
import 'package:sixam_mart/features/notification/helpers/notification_navigation_helper.dart';
import 'package:sixam_mart/features/notification/helpers/notification_type_icon.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';

/// 🔔 Redesigned notifications screen — grouped (today / this week / this month
/// / older), unread green dot, time on the left, title + description on the
/// right, and a type icon at the far edge. RTL + dark-mode aware, with
/// mark-all-read, pull-to-refresh, shimmer loading and an empty state.
class NotificationScreen extends StatefulWidget {
  final bool fromNotification;
  const NotificationScreen({super.key, this.fromNotification = false});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('ar', timeago.ArMessages());
    Get.find<NotificationController>().getNotificationList(true);
  }

  bool get _isArabic => Get.locale?.languageCode == 'ar';

  Future<void> _refresh() async {
    await Get.find<NotificationController>().getNotificationList(true);
  }

  void _markAllRead(NotificationController c) {
    final list = c.notificationList ?? [];
    c.saveSeenNotificationCount(list.length);
    c.hasUnread.value = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Theme.of(context).cardColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 20, color: Theme.of(context).textTheme.bodyLarge?.color),
          onPressed: () => Get.back<void>(),
        ),
        title: Text(_isArabic ? 'الإشعارات' : 'Notifications',
            style: robotoBold.copyWith(fontSize: Dimensions.fontSizeLarge)),
        actions: [
          GetBuilder<NotificationController>(builder: (c) {
            final hasItems = (c.notificationList?.isNotEmpty ?? false);
            if (!hasItems) return const SizedBox();
            return TextButton(
              onPressed: () => _markAllRead(c),
              child: Text(
                _isArabic ? 'تحديد الكل كمقروء' : 'Mark all read',
                style: robotoMedium.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontSize: Dimensions.fontSizeSmall),
              ),
            );
          }),
        ],
      ),
      body: GetBuilder<NotificationController>(builder: (c) {
        final List<NotificationModel>? list = c.notificationList;

        // First load → shimmer.
        if (list == null) return const _NotificationShimmer();

        // Empty state — the bell illustration + friendly copy.
        if (list.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(children: [
              SizedBox(height: context.height * 0.18),
              Center(
                child: Image.asset(
                  Images.no_notification,
                  width: context.width * 0.55,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                      Icons.notifications_off_outlined,
                      size: 64,
                      color: Theme.of(context).disabledColor),
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeLarge),
              Center(
                child: Text(
                  _isArabic
                      ? 'لا يوجد لديك إشعارات\nفي الوقت الحالي'
                      : 'You have no notifications\nat the moment',
                  textAlign: TextAlign.center,
                  style: robotoBold.copyWith(
                      fontSize: Dimensions.fontSizeLarge, height: 1.5),
                ),
              ),
            ]),
          );
        }

        // Unread = the newest (length - seenCount) items.
        final int seen = c.getSeenNotificationCount() ?? 0;
        final int unread = (list.length - seen).clamp(0, list.length);
        final groups = _groupByDate(list);

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
            itemCount: groups.length,
            itemBuilder: (_, gi) {
              final group = groups[gi];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _GroupHeader(title: group.label),
                  ...group.items.map((entry) {
                    final int globalIndex = list.indexOf(entry);
                    return _NotificationItem(
                      model: entry,
                      isUnread: globalIndex < unread,
                      onTap: () {
                        _markAllRead(c);
                        NotificationNavigationHelper.open(entry);
                      },
                    );
                  }),
                ],
              );
            },
          ),
        );
      }),
    );
  }

  // ─── grouping ────────────────────────────────────────────────────────────────

  List<_Group> _groupByDate(List<NotificationModel> list) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday % 7));
    final monthStart = DateTime(now.year, now.month, 1);

    final Map<String, List<NotificationModel>> buckets = {
      'today': [],
      'week': [],
      'month': [],
      'older': [],
    };

    for (final n in list) {
      final dt = DateTime.tryParse(n.createdAt ?? '')?.toLocal();
      if (dt == null) {
        buckets['older']!.add(n);
        continue;
      }
      final d = DateTime(dt.year, dt.month, dt.day);
      if (!d.isBefore(today)) {
        buckets['today']!.add(n);
      } else if (!d.isBefore(weekStart)) {
        buckets['week']!.add(n);
      } else if (!d.isBefore(monthStart)) {
        buckets['month']!.add(n);
      } else {
        buckets['older']!.add(n);
      }
    }

    String label(String key) {
      switch (key) {
        case 'today':
          return _isArabic ? 'اليوم' : 'Today';
        case 'week':
          return _isArabic ? 'هذا الأسبوع' : 'This week';
        case 'month':
          return _isArabic ? 'هذا الشهر' : 'This month';
        default:
          return _isArabic ? 'أقدم' : 'Older';
      }
    }

    return buckets.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => _Group(label(e.key), e.value))
        .toList();
  }
}

class _Group {
  final String label;
  final List<NotificationModel> items;
  _Group(this.label, this.items);
}

class _GroupHeader extends StatelessWidget {
  final String title;
  const _GroupHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimensions.paddingSizeDefault,
          Dimensions.paddingSizeDefault, Dimensions.paddingSizeDefault, 6),
      child: Text(title,
          textAlign: TextAlign.right,
          style: robotoMedium.copyWith(
              color: Theme.of(context).disabledColor,
              fontSize: Dimensions.fontSizeSmall)),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationModel model;
  final bool isUnread;
  final VoidCallback onTap;
  const _NotificationItem(
      {required this.model, required this.isUnread, required this.onTap});

  String _timeText() {
    final dt = DateTime.tryParse(model.createdAt ?? '')?.toLocal();
    if (dt == null) return '';
    return timeago.format(dt,
        locale: Get.locale?.languageCode == 'ar' ? 'ar' : 'en');
  }

  @override
  Widget build(BuildContext context) {
    final title = model.data?.title ?? '';
    final desc = model.data?.description ?? '';
    final iconData = NotificationTypeIcon.fromModel(model);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Dimensions.paddingSizeDefault,
            vertical: Dimensions.paddingSizeSmall),
        // RTL row: dot + time on the left, text in the middle, icon on the right.
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconData.color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData.icon, size: 22, color: iconData.color),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      textAlign: TextAlign.right,
                      style: robotoBold.copyWith(
                          fontSize: Dimensions.fontSizeDefault)),
                  if (desc.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(desc,
                        textAlign: TextAlign.right,
                        style: robotoRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).disabledColor)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Column(
              children: [
                if (isUnread)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                Text(_timeText(),
                    style: robotoRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).disabledColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationShimmer extends StatelessWidget {
  const _NotificationShimmer();

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).shadowColor.withValues(alpha: 0.08);
    return ListView.builder(
      itemCount: 8,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: base,
        highlightColor: Theme.of(context).cardColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              const CircleAvatar(radius: 21, backgroundColor: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: 140, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 10, width: 200, color: Colors.white),
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
