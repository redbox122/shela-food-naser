// ignore_for_file: deprecated_member_use

import 'package:sixam_mart/common/widgets/custom_ink_well.dart';
import 'package:sixam_mart/features/order/controllers/order_controller.dart';
import 'package:sixam_mart/features/order/widgets/order_view_widget.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/helper/taxi_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/features/order/widgets/guest_track_order_input_view_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

class OrderScreen extends StatefulWidget {
  final int? index;
  const OrderScreen({super.key, this.index = 0});

  @override
  OrderScreenState createState() => OrderScreenState();
}

class OrderScreenState extends State<OrderScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoggedIn = AuthHelper.isLoggedIn();
  final List<String> type = ['orders', 'trips'];
  late int selectTypeIndex;
  bool haveTaxiModule = false;

  @override
  void initState() {
    super.initState();
    selectTypeIndex = (widget.index ?? 0).clamp(0, 2);
    _tabController =
        TabController(length: 3, vsync: this, initialIndex: selectTypeIndex);
    haveTaxiModule = TaxiHelper.haveTaxiModule();
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          selectTypeIndex = _tabController.index;
        });
        _loadOrdersForSelectedTab();
        if (kDebugMode) {
          appLogger.debug('Selected tab index: $selectTypeIndex');
        }
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        initCall();
      }
    });
  }

  void _loadOrdersForSelectedTab() {
    if (!_isLoggedIn) return;
    if (selectTypeIndex == 1 || selectTypeIndex == 2) {
      debugPrint(
          '[OrderTab] loading history/canceled for tab=$selectTypeIndex');
      Get.find<OrderController>().getHistoryOrders(1, isUpdate: true);
    } else {
      debugPrint('[OrderTab] loading running for tab=$selectTypeIndex');
      Get.find<OrderController>().getRunningOrders(1, isUpdate: true);
    }
  }

  void initCall() {
    debugPrint(
        '[OrderTab] initCall loggedIn=$_isLoggedIn selectedTab=$selectTypeIndex haveTaxi=$haveTaxiModule');
    if (_isLoggedIn) {
      // Always fetch order data for this screen.
      debugPrint('[OrderTab] initial load running + history orders');
      Get.find<OrderController>().getRunningOrders(1);
      Get.find<OrderController>().getHistoryOrders(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    _isLoggedIn = AuthHelper.isLoggedIn();
    debugPrint(
        '[OrderTab] build loggedIn=$_isLoggedIn selectedTab=$selectTypeIndex');
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: haveTaxiModule && !ResponsiveHelper.isDesktop(context)
          ? null
          : CustomAppBar(
              title: 'my_orders'.tr,
              img: Images.orderSelect,
              backButton: true,
              onBackPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Get.offAllNamed(RouteHelper.getMainRoute('home'));
                }
              }),
      endDrawerEnableOpenDragGesture: false,
      body: SafeArea(
        child: GetBuilder<OrderController>(
          builder: (orderController) {
            return Column(
              children: [
                if (haveTaxiModule && !ResponsiveHelper.isDesktop(context))
                  _buildTaxiModuleHeader(context),
                _isLoggedIn
                    ? Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 17),
                          child: Column(
                            children: [
                              const SizedBox(
                                  height: Dimensions.paddingSizeDefault),
                              _buildStyledTabBar(context),
                              Expanded(
                                child: TabBarView(
                                    controller: _tabController,
                                    children: const [
                                      OrderViewWidget(isRunning: 0),
                                      OrderViewWidget(isRunning: 1),
                                      OrderViewWidget(isRunning: 2),
                                    ]),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GuestTrackOrderInputViewWidget(
                        selectType: selectTypeIndex),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStyledTabBar(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            width: 3.0,
            color: Theme.of(context).primaryColor,
          ),
          insets: const EdgeInsets.symmetric(horizontal: 70),
        ),
        tabs: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('running'.tr, style: robotoBold),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('order_tab_cancelled'.tr, style: robotoBold),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text('history'.tr, style: robotoBold),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxiModuleHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_sharp),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Get.offAllNamed(RouteHelper.getMainRoute('home'));
                  }
                },
              ),
              Text('my_orders'.tr, style: robotoMedium),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          SizedBox(
            height: 30,
            child: ListView.builder(
              itemCount: type.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final bool selected = index == selectTypeIndex;
                return Container(
                  decoration: BoxDecoration(
                    color: selected
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusLarge),
                    border: Border.all(
                        color: Theme.of(context).disabledColor, width: 0.3),
                  ),
                  alignment: Alignment.center,
                  margin:
                      const EdgeInsets.only(right: Dimensions.paddingSizeSmall),
                  child: CustomInkWell(
                    onTap: () {
                      setState(() {
                        selectTypeIndex = index;
                      });
                      debugPrint(
                          '[OrderTab] header switch -> $selectTypeIndex (${type[index]})');
                      initCall();
                    },
                    radius: Dimensions.radiusLarge,
                    padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault),
                    child: Text(
                      type[index].tr,
                      style: robotoMedium.copyWith(
                        fontSize: Dimensions.fontSizeLarge,
                        color: selected
                            ? Colors.white
                            : Theme.of(context)
                                .textTheme
                                .bodyLarge!
                                .color!
                                .withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
