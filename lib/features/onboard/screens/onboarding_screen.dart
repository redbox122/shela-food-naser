//

import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/onboard/controllers/onboard_controller.dart';
import 'package:sixam_mart/features/location/controllers/location_controller.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/common/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();

    Get.find<OnBoardingController>().getOnBoardingList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GetBuilder<OnBoardingController>(builder: (onBoardingController) {
        return onBoardingController.onBoardingList.isNotEmpty
            ? Stack(
                children: [
                  SizedBox(
                    height: context.height,
                    width: context.width,
                    child: Image.asset(
                      onBoardingController
                          .onBoardingList[onBoardingController.selectedIndex]
                          .imageUrl,
                      fit: BoxFit.cover,
                      height: context.height,
                    ),
                  ),
                  Column(children: [
                    Expanded(
                        child: PageView.builder(
                      itemCount: onBoardingController.onBoardingList.length,
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  onBoardingController
                                      .onBoardingList[index].title,
                                  style: robotoBold.copyWith(
                                      fontSize: 24, color: Colors.white),
                                  textAlign: TextAlign.start,
                                ),
                                SizedBox(height: context.height * 0.025),
                                Text(
                                  onBoardingController
                                      .onBoardingList[index].description,
                                  style: robotoRegular.copyWith(
                                      fontSize: 15, color: Colors.white),
                                  textAlign: TextAlign.start,
                                ),
                              ]),
                        );
                      },
                      onPageChanged: (index) {
                        setState(() {
                          onBoardingController.changeSelectIndex(index);
                        });
                      },
                    )),
                    SizedBox(height: context.height * 0.05),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            _pageIndicators(onBoardingController, context),
                      ),
                    ),
                    SizedBox(height: context.height * 0.05),
                    Padding(
                      padding:
                          const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      child: Row(children: [
                        Expanded(
                          child: GetBuilder<AuthController>(
                            builder: (authController) {
                              return CustomButton(
                                buttonText:
                                    onBoardingController.selectedIndex !=
                                            onBoardingController
                                                    .onBoardingList.length -
                                                1
                                        ? 'next'.tr
                                        : 'get_started'.tr,
                                isLoading: authController.guestLoading,
                                onPressed: () async {
                                  if (onBoardingController.selectedIndex !=
                                      onBoardingController
                                              .onBoardingList.length -
                                          1) {
                                    _pageController.nextPage(
                                        duration: const Duration(seconds: 1),
                                        curve: Curves.ease);
                                  } else {
                                    Get.find<SplashController>().disableIntro();

                                    // Show loading state while guest login is processing
                                    try {
                                      await Get.find<AuthController>()
                                          .guestLogin();

                                      // Navigate to location selection
                                      if (!context.mounted) {
                                        return;
                                      }
                                      Get.find<LocationController>()
                                          .navigateToLocationScreen(
                                              context, 'onboarding',
                                              offNamed: true);
                                    } catch (e) {
                                      // Handle any errors during guest login
                                      debugPrint('Error during guest login: $e');
                                      // Still navigate to location screen even if guest login fails
                                      if (!context.mounted) {
                                        return;
                                      }
                                      Get.find<LocationController>()
                                          .navigateToLocationScreen(
                                              context, 'onboarding',
                                              offNamed: true);
                                    }
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ],
              )
            : const SizedBox();
      }),
    );
  }

  List<Widget> _pageIndicators(
      OnBoardingController onBoardingController, BuildContext context) {
    final List<Container> indicators = [];

    for (int i = 0; i < onBoardingController.onBoardingList.length; i++) {
      indicators.add(
        Container(
          width: context.width * .3,
          height: 3,
          margin: const EdgeInsets.only(right: 10),
          decoration: BoxDecoration(
            color: i == onBoardingController.selectedIndex
                ? Theme.of(context).primaryColor
                : Theme.of(context).disabledColor,
          ),
        ),
      );
    }
    return indicators;
  }

  //
}
