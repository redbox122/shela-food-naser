import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/auth/controllers/store_registration_controller.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_dropdown.dart';
import 'package:sixam_mart/util/styles.dart';

class ModuleViewWidget extends StatelessWidget {
  const ModuleViewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveHelper.isDesktop(context);

    return GetBuilder<StoreRegistrationController>(builder: (storeRegController) {
      final modules = storeRegController.moduleList;
      if (modules == null) {
        return const SizedBox.shrink();
      }

      final List<DropdownItem<int>> moduleItems = [];
      for (int index = 0; index < modules.length; index++) {
        if (modules[index].moduleType != 'parcel') {
          moduleItems.add(
            DropdownItem<int>(
              value: index,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('${modules[index].moduleName}'),
              ),
            ),
          );
        }
      }

      final int? selectedIndex = storeRegController.selectedModuleIndex;
      final bool hasValidSelected = selectedIndex != null &&
          selectedIndex >= 0 &&
          selectedIndex < modules.length &&
          modules[selectedIndex].moduleType != 'parcel';

      return Stack(clipBehavior: Clip.none, children: [

        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
            color: Theme.of(context).cardColor,
            border: Border.all(color: Theme.of(context).disabledColor, width: 0.3),
          ),
          child: moduleItems.isEmpty
              ? SizedBox(
                  height: 50,
                  child: Center(
                    child: Text('not_available_module'.tr),
                  ),
                )
              : CustomDropdown<int>(
                  onChange: (int? value, int index) {
                    if (value == null) return;
                    storeRegController.selectModuleIndex(value);
                    Get.find<StoreRegistrationController>()
                        .getPackageList(moduleId: modules[value].id);
                  },
                  dropdownButtonStyle: DropdownButtonStyle(
                    height: 50,
                    padding: const EdgeInsets.symmetric(
                      vertical: Dimensions.paddingSizeExtraSmall,
                      horizontal: Dimensions.paddingSizeExtraSmall,
                    ),
                    primaryColor: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                  iconColor: Theme.of(context).disabledColor,
                  dropdownStyle: DropdownStyle(
                    elevation: 10,
                    borderRadius: BorderRadius.circular(Dimensions.radiusDefault),
                    padding: const EdgeInsets.all(Dimensions.paddingSizeExtraSmall),
                  ),
                  items: moduleItems,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      hasValidSelected
                          ? modules[selectedIndex].moduleName.toString()
                          : 'select_module_type'.tr,
                    ),
                  ),
                ),
        ),

        Positioned(
          left: 10, top: -15,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
            ),
            padding: const EdgeInsets.all(5),
            child: Text('select_module'.tr, style: robotoRegular.copyWith(color: Theme.of(context).disabledColor, fontSize: isDesktop ? Dimensions.fontSizeExtraSmall : Dimensions.fontSizeDefault)),
          ),
        ),

      ]);

    });
  }
}
