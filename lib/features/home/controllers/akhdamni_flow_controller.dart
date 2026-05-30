import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/widgets/akhdamni/akhdamni_strings.dart';

enum AkhdamniFlowState {
  normalHome,
  serviceMeChooseType,
  serviceMePeopleServices,
  serviceMeCompanyServices,
  serviceMeWorkshopList,
}

enum AkhdamniServiceAudience {
  individuals,
  companies,
}

class AkhdamniPeopleServiceItem {
  const AkhdamniPeopleServiceItem({
    required this.id,
    required this.label,
    required this.icon,
    this.assetFileName,
  });

  final String id;
  final String label;
  final IconData icon;
  /// Optional file under [AkhdamniServiceIcon.assetsFolder], e.g. `shop_for_me.png`.
  final String? assetFileName;
}

class AkhdamniCompanyServiceItem {
  const AkhdamniCompanyServiceItem({
    required this.id,
    required this.label,
    required this.icon,
    this.assetFileName,
  });

  final String id;
  final String label;
  final IconData icon;
  final String? assetFileName;
}

class AkhdamniWorkshopItem {
  const AkhdamniWorkshopItem({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.rating,
    required this.reviewCount,
    required this.distanceKm,
  });

  final String id;
  final String name;
  final String description;
  final String location;
  final double rating;
  final int reviewCount;
  final double distanceKm;
}

class AkhdamniFlowController extends GetxController {
  static const int akhdamniChipId = -101;
  static const int pickupDeliveryChipId = -102;

  AkhdamniFlowState flowState = AkhdamniFlowState.normalHome;
  AkhdamniServiceAudience? selectedAudience;
  String? selectedPeopleServiceId;
  String? selectedCompanyServiceId;

  bool get isFlowActive => flowState != AkhdamniFlowState.normalHome;

  int? get activeLocalChipId {
    if (flowState != AkhdamniFlowState.normalHome) {
      return akhdamniChipId;
    }
    return null;
  }

  static const List<AkhdamniPeopleServiceItem> peopleServices = [
    AkhdamniPeopleServiceItem(
      id: 'shop_for_me',
      label: 'تسوقني',
      icon: Icons.shopping_bag_outlined,
    ),
    AkhdamniPeopleServiceItem(
      id: 'delivery',
      label: 'خدمة توصيل',
      icon: Icons.local_shipping_outlined,
    ),
    AkhdamniPeopleServiceItem(
      id: 'childcare',
      label: 'اصطحاب الأطفال',
      icon: Icons.child_care_outlined,
    ),
    AkhdamniPeopleServiceItem(
      id: 'furniture',
      label: 'نقل العفش',
      icon: Icons.weekend_outlined,
    ),
    AkhdamniPeopleServiceItem(
      id: 'daily_commute',
      label: 'التنقلات اليومية',
      icon: Icons.commute_outlined,
    ),
    AkhdamniPeopleServiceItem(
      id: 'travel',
      label: 'سفر',
      icon: Icons.flight_outlined,
    ),
    AkhdamniPeopleServiceItem(
      id: 'documents',
      label: 'نقل مستندات',
      icon: Icons.description_outlined,
    ),
    AkhdamniPeopleServiceItem(
      id: 'home_services',
      label: 'خدمات منزلية',
      icon: Icons.home_outlined,
    ),
    AkhdamniPeopleServiceItem(
      id: 'custom_route',
      label: 'تحديد مسار',
      icon: Icons.route_outlined,
    ),
  ];

  static const List<AkhdamniCompanyServiceItem> companyServices = [
    AkhdamniCompanyServiceItem(
      id: 'large_flatbed',
      label: 'سطحة كبيرة',
      icon: Icons.local_shipping_outlined,
    ),
    AkhdamniCompanyServiceItem(
      id: 'hydraulic_flatbed',
      label: 'سطحة هيدروليك',
      icon: Icons.precision_manufacturing_outlined,
    ),
    AkhdamniCompanyServiceItem(
      id: 'standard_flatbed',
      label: 'سطحة عادية',
      icon: Icons.directions_car_outlined,
    ),
    AkhdamniCompanyServiceItem(
      id: 'electric_winch',
      label: 'ونش كهربائي',
      icon: Icons.electric_bolt_outlined,
    ),
  ];

  static const List<AkhdamniWorkshopItem> placeholderWorkshops = [
    AkhdamniWorkshopItem(
      id: 'w1',
      name: 'ورشة النخيل',
      description: 'خدمات سطحة وونش مع فريق متخصص',
      location: 'حي النخيل، الرياض',
      rating: 4.8,
      reviewCount: 126,
      distanceKm: 2.4,
    ),
    AkhdamniWorkshopItem(
      id: 'w2',
      name: 'مركز الإنقاذ السريع',
      description: 'سطحة هيدروليك وونش كهربائي على مدار الساعة',
      location: 'طريق الملك فهد، الرياض',
      rating: 4.6,
      reviewCount: 89,
      distanceKm: 3.1,
    ),
    AkhdamniWorkshopItem(
      id: 'w3',
      name: 'ورشة الأمان للنقل',
      description: 'نقل آمن للمركبات والمعدات الثقيلة',
      location: 'حي العليا، الرياض',
      rating: 4.9,
      reviewCount: 204,
      distanceKm: 4.7,
    ),
  ];

  void enterAkhdamniFlow() {
    flowState = AkhdamniFlowState.serviceMeChooseType;
    selectedAudience = null;
    selectedPeopleServiceId = null;
    selectedCompanyServiceId = null;
    if (kDebugMode) {
      debugPrint('[AkhdamniFlow] enter -> serviceMeChooseType');
    }
    update();
  }

  void exitFlow() {
    if (flowState == AkhdamniFlowState.normalHome) {
      return;
    }
    flowState = AkhdamniFlowState.normalHome;
    selectedAudience = null;
    selectedPeopleServiceId = null;
    selectedCompanyServiceId = null;
    if (kDebugMode) {
      debugPrint('[AkhdamniFlow] exit -> normalHome');
    }
    update();
  }

  void selectAudience(AkhdamniServiceAudience audience) {
    selectedAudience = audience;
    update();
  }

  void selectPeopleService(String serviceId) {
    selectedPeopleServiceId = serviceId;
    update();
  }

  void selectCompanyService(String serviceId) {
    selectedCompanyServiceId = serviceId;
    update();
  }

  void proceedFromChooseType() {
    if (selectedAudience == null) {
      Get.rawSnackbar(message: AkhdamniStrings.selectServiceType);
      return;
    }
    if (selectedAudience == AkhdamniServiceAudience.individuals) {
      flowState = AkhdamniFlowState.serviceMePeopleServices;
      selectedPeopleServiceId = null;
    } else {
      flowState = AkhdamniFlowState.serviceMeCompanyServices;
      selectedCompanyServiceId = null;
    }
    if (kDebugMode) {
      debugPrint('[AkhdamniFlow] proceedFromChooseType -> $flowState');
    }
    update();
  }

  void proceedFromPeopleServices() {
    if (selectedPeopleServiceId == null) {
      Get.rawSnackbar(message: AkhdamniStrings.selectService);
      return;
    }
    if (kDebugMode) {
      debugPrint(
        '[AkhdamniFlow] people service selected: $selectedPeopleServiceId',
      );
    }
    Get.rawSnackbar(message: AkhdamniStrings.comingSoon);
  }

  void proceedFromCompanyServices() {
    if (selectedCompanyServiceId == null) {
      Get.rawSnackbar(message: AkhdamniStrings.selectVehicleType);
      return;
    }
    flowState = AkhdamniFlowState.serviceMeWorkshopList;
    if (kDebugMode) {
      debugPrint('[AkhdamniFlow] proceedFromCompanyServices -> workshopList');
    }
    update();
  }

  void proceedFromWorkshopList() {
    if (kDebugMode) {
      debugPrint('[AkhdamniFlow] workshop list next tapped');
    }
    Get.rawSnackbar(message: AkhdamniStrings.comingSoon);
  }

  /// Handles Android system back while the Akhdamni flow is active.
  /// Returns `true` when the back press was consumed.
  bool handleSystemBack() {
    switch (flowState) {
      case AkhdamniFlowState.normalHome:
        return false;
      case AkhdamniFlowState.serviceMeWorkshopList:
        flowState = AkhdamniFlowState.serviceMeCompanyServices;
        if (kDebugMode) {
          debugPrint('[AkhdamniFlow] back -> serviceMeCompanyServices');
        }
        update();
        return true;
      case AkhdamniFlowState.serviceMePeopleServices:
        flowState = AkhdamniFlowState.serviceMeChooseType;
        selectedPeopleServiceId = null;
        if (kDebugMode) {
          debugPrint('[AkhdamniFlow] back -> serviceMeChooseType');
        }
        update();
        return true;
      case AkhdamniFlowState.serviceMeCompanyServices:
        flowState = AkhdamniFlowState.serviceMeChooseType;
        selectedCompanyServiceId = null;
        if (kDebugMode) {
          debugPrint('[AkhdamniFlow] back -> serviceMeChooseType');
        }
        update();
        return true;
      case AkhdamniFlowState.serviceMeChooseType:
        exitFlow();
        return true;
    }
  }
}
