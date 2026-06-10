import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/auth/controllers/auth_controller.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/onboard/controllers/onboard_controller.dart';
import 'package:sixam_mart/helper/route_helper.dart';
import 'package:sixam_mart/features/onboard/widgets/onboarding_background.dart';
import 'package:sixam_mart/features/onboard/widgets/onboarding_page.dart';
import 'package:sixam_mart/features/onboard/widgets/onboarding_progress_button.dart';
import 'package:sixam_mart/features/onboard/widgets/onboarding_skip_button.dart';
import 'package:sixam_mart/features/onboard/widgets/pop_illustration.dart';
import 'package:sixam_mart/features/onboard/widgets/slide_illustration.dart';
import 'package:sixam_mart/helper/responsive_helper.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/no_data_screen.dart';

class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final PageController _pageController = PageController();

  // Assets to warm up so the intro animations and the background cross-fade
  // run smoothly the moment the screen appears.
  static const List<String> _assetsToPrecache = [
    ...onboardingBackgroundImages,
    Images.shella_bag,
    Images.ob_ic_food,
    Images.ob_ic_pharmacy,
    Images.ob_ic_grocery,
    Images.Exclusive_discounts,
    Images.discount_50,
    Images.discount_20,
    Images.discount_30,
    Images.oclock,
    Images.boxes,
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(_prepareOnboarding);
  }

  Future<void> _prepareOnboarding() async {
    final onboardingController = Get.find<OnBoardingController>();
    await onboardingController.getOnBoardingList();
    if (!mounted) {
      return;
    }
    for (final asset in _assetsToPrecache) {
      // ignore: use_build_context_synchronously
      await precacheImage(AssetImage(asset), context);
    }
  }

  void _finishOnboarding() {
    // After onboarding we land on the passwordless welcome screen. The guest
    // session is only created when the user explicitly chooses "Continue as
    // Guest" there — no auto guest login here anymore.
    Get.find<SplashController>().disableIntro();
    Get.offAllNamed(RouteHelper.getWelcomeRoute());
  }

  void _onNextTapped(bool isLast) {
    if (isLast) {
      _finishOnboarding();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  /// Builds the animated illustration for a page. Pages 1 & 2 pop their icons
  /// out of a center image; page 3 slides boxes in. [currentIndex] decides
  /// which page is active so its animation plays.
  Widget _illustrationFor(int pageIndex, int currentIndex, String fallback) {
    switch (pageIndex) {
      case 0:
        return PopIllustration(
          active: currentIndex == 0,
          centerAsset: Images.shella_bag,
          centerWidth: 217,
          centerLeft: (300 - 190) / 2,
          centerBottom: 10,
          icons: firstPageIcons,
          // Slow rise so the icons are clearly seen emerging from the bag.
          duration: const Duration(milliseconds: 2400),
        );
      case 1:
        return PopIllustration(
          active: currentIndex == 1,
          centerAsset: Images.Exclusive_discounts,
          centerWidth: 210,
          centerLeft: (300 - 210) / 2,
          centerBottom: 10,
          icons: secondPageIcons,
          // Slightly slower rise for the badges too.
          duration: const Duration(milliseconds: 2200),
        );
      case 2:
        return SlideIllustration(active: currentIndex == 2);
      default:
        return Image.asset(
          fallback,
          height: MediaQuery.of(context).size.height * 0.32,
          fit: BoxFit.contain,
        );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GetBuilder<OnBoardingController>(builder: (onBoardingController) {
        final pages = onBoardingController.onBoardingList;
        if (pages.isEmpty) {
          return NoDataScreen(text: 'no_data_found'.tr, showFooter: false);
        }

        final int total = pages.length;
        final int index = onBoardingController.selectedIndex;
        final bool isLast = index == total - 1;

        return Stack(
          children: [
            // Exact design background: blurred pastel gradient assets gently
            // cross-fading between variants for a calm animated feel.
            const Positioned.fill(child: OnboardingBackground()),
            // Gentle white fade over the lower area so the text stays crisp.
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.5, 0.92],
                    colors: [Color(0x00FFFFFF), Colors.white],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: !ResponsiveHelper.isDesktop(context),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding:
                          const EdgeInsets.all(Dimensions.paddingSizeSmall),
                      child: OnboardingSkipButton(onTap: _finishOnboarding),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      itemCount: total,
                      onPageChanged: onBoardingController.changeSelectIndex,
                      itemBuilder: (context, i) {
                        return OnboardingPage(
                          title: pages[i].title,
                          description: pages[i].description,
                          illustration:
                              _illustrationFor(i, index, pages[i].imageUrl),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: Dimensions.paddingSizeLarge),
                    child: GetBuilder<AuthController>(
                      builder: (authController) {
                        return OnboardingProgressButton(
                          progress: (index + 1) / total,
                          isLoading: authController.guestLoading,
                          onTap: () => _onNextTapped(isLast),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}
