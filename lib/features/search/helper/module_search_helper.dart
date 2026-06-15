import 'package:sixam_mart/common/models/module_model.dart';
import 'package:sixam_mart/util/app_constants.dart';

/// Pure business rules for ordering and classifying modules on the search
/// screen. Kept out of the widget layer so the UI only renders decisions.
class ModuleSearchHelper {
  const ModuleSearchHelper._();

  /// Modules that are visible but not yet usable (shown with a "coming soon"
  /// badge and blocked from selection).
  static bool isComingSoon(ModuleModel module) {
    final String moduleType = _normalized(module.moduleType);
    final String moduleName = _normalized(module.moduleName);

    final bool isPharmacy = moduleType == AppConstants.pharmacy ||
        moduleName.contains('صيدلي') ||
        moduleName.contains('pharmacy') ||
        moduleName.contains('pharm');
    final bool isCommercialStores = moduleName.contains('المحلات التجارية') ||
        moduleName.contains('محلات تجارية') ||
        moduleName.contains('commercial') ||
        moduleName.contains('shop');

    return isPharmacy || isCommercialStores;
  }

  /// Lower value = shown earlier. Hyper first, restaurants, cafes, then the
  /// rest, with "coming soon" modules pushed near the end.
  static int sortPriority(ModuleModel module) {
    final String moduleType = _normalized(module.moduleType);
    final String moduleName = _normalized(module.moduleName);

    if (isComingSoon(module)) return 90;
    if (moduleType == AppConstants.ecommerce ||
        moduleName.contains('هايبر') ||
        moduleName.contains('hyper')) {
      return 1;
    }
    if (moduleName.contains('مطعم') || moduleName.contains('restaurant')) {
      return 2;
    }
    if (moduleName.contains('مقهى') ||
        moduleName.contains('كاف') ||
        moduleName.contains('cafe') ||
        moduleName.contains('coffee')) {
      return 3;
    }
    return 10;
  }

  static bool isRestaurant(ModuleModel module) {
    final String moduleType = _normalized(module.moduleType);
    final String moduleName = _normalized(module.moduleName);
    return moduleName.contains('مطعم') ||
        moduleName.contains('restaurant') ||
        (moduleType.isNotEmpty && moduleType != AppConstants.ecommerce);
  }

  /// Returns a new list sorted by [sortPriority], then by id as a tie-breaker.
  static List<ModuleModel> sortedByPriority(List<ModuleModel>? modules) {
    final List<ModuleModel> sorted =
        List<ModuleModel>.from(modules ?? <ModuleModel>[]);
    sorted.sort((a, b) {
      final int p = sortPriority(a).compareTo(sortPriority(b));
      if (p != 0) return p;
      return (a.id ?? 0).compareTo(b.id ?? 0);
    });
    return sorted;
  }

  static String _normalized(String? value) =>
      (value ?? '').toString().trim().toLowerCase();
}
