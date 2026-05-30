import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/home/controllers/akhdamni_flow_controller.dart';
import 'package:sixam_mart/features/home/widgets/akhdamni/akhdamni_shared_widgets.dart';
import 'package:sixam_mart/features/home/widgets/akhdamni/akhdamni_strings.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';

class AkhdamniFlowSection extends StatelessWidget {
  const AkhdamniFlowSection({super.key});

  static const double _moduleStripHeight = 60;
  static const double _appBarHeight = 140;
  static const double _bottomNavHeight = kBottomNavigationBarHeight;

  double _contentHeight(BuildContext context) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double screenHeight = mediaQuery.size.height;
    final double topInset = mediaQuery.padding.top;
    final double bottomInset = mediaQuery.padding.bottom;
    final double usedHeight =
        topInset + _appBarHeight + _moduleStripHeight + _bottomNavHeight + bottomInset;
    final double available = screenHeight - usedHeight;
    return available.clamp(320, screenHeight);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AkhdamniFlowController>(
      builder: (controller) {
        if (controller.flowState == AkhdamniFlowState.normalHome) {
          return const SizedBox.shrink();
        }
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) {
            if (didPop) {
              return;
            }
            controller.handleSystemBack();
          },
          child: SizedBox(
            height: _contentHeight(context),
            child: _buildStep(context, controller),
          ),
        );
      },
    );
  }

  Widget _buildStep(BuildContext context, AkhdamniFlowController controller) {
    switch (controller.flowState) {
      case AkhdamniFlowState.serviceMeChooseType:
        return _ChooseTypeStep(controller: controller);
      case AkhdamniFlowState.serviceMePeopleServices:
        return _PeopleServicesStep(controller: controller);
      case AkhdamniFlowState.serviceMeCompanyServices:
        return _CompanyServicesStep(controller: controller);
      case AkhdamniFlowState.serviceMeWorkshopList:
        return _WorkshopListStep(controller: controller);
      case AkhdamniFlowState.normalHome:
        return const SizedBox.shrink();
    }
  }
}

class _AkhdamniStepScaffold extends StatelessWidget {
  const _AkhdamniStepScaffold({
    required this.scrollContent,
    required this.bottomButton,
  });

  final Widget scrollContent;
  final Widget bottomButton;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeSmall,
              ),
              child: scrollContent,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeSmall,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
              ),
              child: bottomButton,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChooseTypeStep extends StatelessWidget {
  const _ChooseTypeStep({required this.controller});

  final AkhdamniFlowController controller;

  @override
  Widget build(BuildContext context) {
    return _AkhdamniStepScaffold(
      bottomButton: AkhdamniGreenButton(
        label: AkhdamniStrings.next,
        onPressed: controller.proceedFromChooseType,
        isEnabled: controller.selectedAudience != null,
      ),
      scrollContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AkhdamniSectionTitle(title: AkhdamniStrings.chooseTypeTitle),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Row(
            textDirection: TextDirection.rtl,
            children: [
              AkhdamniSelectableTypeCard(
                title: AkhdamniStrings.serviceIndividuals,
                icon: Icons.person_outline_rounded,
                assetFileName: 'individuals.png',
                isSelected: controller.selectedAudience ==
                    AkhdamniServiceAudience.individuals,
                onTap: () => controller.selectAudience(
                  AkhdamniServiceAudience.individuals,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              AkhdamniSelectableTypeCard(
                title: AkhdamniStrings.serviceCompanies,
                icon: Icons.business_outlined,
                assetFileName: 'companies.png',
                isSelected: controller.selectedAudience ==
                    AkhdamniServiceAudience.companies,
                onTap: () => controller.selectAudience(
                  AkhdamniServiceAudience.companies,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeopleServicesStep extends StatelessWidget {
  const _PeopleServicesStep({required this.controller});

  final AkhdamniFlowController controller;

  @override
  Widget build(BuildContext context) {
    return _AkhdamniStepScaffold(
      bottomButton: AkhdamniGreenButton(
        label: AkhdamniStrings.next,
        onPressed: controller.proceedFromPeopleServices,
        isEnabled: controller.selectedPeopleServiceId != null,
      ),
      scrollContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AkhdamniSectionTitle(
            title: AkhdamniStrings.peopleTitle,
            subtitle: AkhdamniStrings.peopleSubtitle,
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AkhdamniFlowController.peopleServices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              final item = AkhdamniFlowController.peopleServices[index];
              return AkhdamniServiceGridItem(
                label: item.label,
                icon: item.icon,
                assetFileName: item.assetFileName ?? '${item.id}.png',
                isSelected: controller.selectedPeopleServiceId == item.id,
                onTap: () => controller.selectPeopleService(item.id),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CompanyServicesStep extends StatelessWidget {
  const _CompanyServicesStep({required this.controller});

  final AkhdamniFlowController controller;

  @override
  Widget build(BuildContext context) {
    return _AkhdamniStepScaffold(
      bottomButton: AkhdamniGreenButton(
        label: AkhdamniStrings.next,
        onPressed: controller.proceedFromCompanyServices,
        isEnabled: controller.selectedCompanyServiceId != null,
      ),
      scrollContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AkhdamniSectionTitle(title: AkhdamniStrings.companyTitle),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: AkhdamniFlowController.companyServices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.28,
            ),
            itemBuilder: (context, index) {
              final item = AkhdamniFlowController.companyServices[index];
              return AkhdamniServiceGridItem(
                label: item.label,
                icon: item.icon,
                assetFileName: item.assetFileName ?? '${item.id}.png',
                isSelected: controller.selectedCompanyServiceId == item.id,
                onTap: () => controller.selectCompanyService(item.id),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WorkshopListStep extends StatelessWidget {
  const _WorkshopListStep({required this.controller});

  final AkhdamniFlowController controller;

  @override
  Widget build(BuildContext context) {
    const workshops = AkhdamniFlowController.placeholderWorkshops;
    return _AkhdamniStepScaffold(
      bottomButton: AkhdamniGreenButton(
        label: AkhdamniStrings.next,
        onPressed: controller.proceedFromWorkshopList,
      ),
      scrollContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AkhdamniSectionTitle(title: AkhdamniStrings.workshopTitle),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: workshops.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: Dimensions.paddingSizeDefault),
            itemBuilder: (context, index) {
              final workshop = workshops[index];
              return AkhdamniWorkshopCard(
                name: workshop.name,
                description: workshop.description,
                location: workshop.location,
                rating: workshop.rating,
                reviewCount: workshop.reviewCount,
                distanceKm: workshop.distanceKm,
                imageWidget: Image.asset(
                  Images.placeholder,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.storefront_outlined,
                      size: 48,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
