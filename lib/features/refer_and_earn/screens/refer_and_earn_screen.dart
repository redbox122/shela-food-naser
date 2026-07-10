import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/helper/auth_helper.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/images.dart';
import 'package:sixam_mart/common/widgets/custom_snackbar.dart';
import 'package:sixam_mart/common/widgets/custom_image.dart';
import 'package:sixam_mart/common/widgets/error_state_view.dart';
import 'package:sixam_mart/common/widgets/not_logged_in_screen.dart';
import 'package:sixam_mart/features/refer_and_earn/controllers/referral_controller.dart';
import 'package:sixam_mart/features/refer_and_earn/domain/models/invited_friends_model.dart';

const Color _primary = Color(0xFF31A342);
const Color _title = Color(0xFF2D3633);

TextStyle _tajawal(double size, FontWeight weight, {Color color = _title}) {
  return TextStyle(
    fontFamily: 'Tajawal',
    fontSize: size,
    fontWeight: weight,
    color: color,
  );
}

class ReferAndEarnScreen extends StatefulWidget {
  const ReferAndEarnScreen({super.key});

  @override
  State<ReferAndEarnScreen> createState() => _ReferAndEarnScreenState();
}

class _ReferAndEarnScreenState extends State<ReferAndEarnScreen> {
  // 0 = رابط الدعوة , 1 = الأصدقاء المدعوين
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _initCall();
  }

  void _initCall() {
    if (!AuthHelper.isLoggedIn()) {
      return;
    }
    final profileController = Get.find<ProfileController>();
    final String currentRefCode =
        profileController.userInfoModel?.refCode?.trim() ?? '';
    if (profileController.userInfoModel == null || currentRefCode.isEmpty) {
      profileController.getUserInfo();
    }
  }

  String _resolveStoreLink() {
    final config = Get.find<SplashController>().configModel;
    final List<String?> candidates = <String?>[
      GetPlatform.isAndroid ? config?.appUrlAndroid : config?.appUrlIos,
      GetPlatform.isAndroid
          ? config?.landingPageLinks?.appUrlAndroid
          : config?.landingPageLinks?.appUrlIos,
      config?.appUrlAndroid,
      config?.appUrlIos,
      config?.landingPageLinks?.appUrlAndroid,
      config?.landingPageLinks?.appUrlIos,
    ];
    for (final link in candidates) {
      final String value = (link ?? '').trim();
      if (value.isNotEmpty) {
        return value;
      }
    }
    return '';
  }

  /// رابط الدعوة المعروض والذي يُنسخ/يُشارك (يتضمّن رمز الإحالة إن وُجد)
  String _referralLink(String refCode) {
    final String storeLink = _resolveStoreLink();
    if (storeLink.isEmpty) return refCode;
    if (refCode.isEmpty) return storeLink;
    final String sep = storeLink.contains('?') ? '&' : '?';
    return '$storeLink${sep}ref=$refCode';
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = AuthHelper.isLoggedIn();
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text('refer_invite_friends'.tr, style: _tajawal(18, FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _title, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: isLoggedIn
          ? GetBuilder<ProfileController>(builder: (profileController) {
              if (profileController.userInfoModel == null &&
                  profileController.hasProfileError) {
                return ErrorStateView(
                  onRetry: () => profileController.getUserInfo(),
                );
              }
              final String referralCode =
                  profileController.userInfoModel?.refCode?.trim() ?? '';
              return Column(
                children: [
                  _buildTabs(),
                  Expanded(
                    child: _tab == 0
                        ? _InviteLinkTab(
                            referralCode: referralCode,
                            referralLink: _referralLink(referralCode),
                            onRefresh: () => profileController.getUserInfo(),
                          )
                        : const _InvitedFriendsTab(),
                  ),
                ],
              );
            })
          : NotLoggedInScreen(callBack: (value) {
              _initCall();
              setState(() {});
            }),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F5F8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(child: _segment('refer_invited_friends'.tr, 1)),
            Expanded(child: _segment('refer_invite_link'.tr, 0)),
          ],
        ),
      ),
    );
  }

  Widget _segment(String label, int index) {
    final bool selected = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: _tajawal(16, FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF082E0A)),
        ),
      ),
    );
  }
}

// ==== تبويب: رابط الدعوة ====
class _InviteLinkTab extends StatelessWidget {
  final String referralCode;
  final String referralLink;
  final VoidCallback onRefresh;
  const _InviteLinkTab({
    required this.referralCode,
    required this.referralLink,
    required this.onRefresh,
  });

  void _copy() {
    if (referralLink.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: referralLink));
      showCustomSnackBar('referral_code_copied'.tr, isError: false);
    } else {
      onRefresh();
      showCustomSnackBar('Referral code is not available yet');
    }
  }

  @override
  Widget build(BuildContext context) {
    final double refRate = Get.find<SplashController>()
            .configModel
            ?.refEarningExchangeRate
            ?.toDouble() ??
        0.0;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // الصورة
                Center(
                  child: Image.asset(
                    Images.invite_friends,
                    width: 203,
                    height: 210,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                // العنوان
                Text('refer_invite_friends_and_businesses'.tr,
                    textAlign: TextAlign.center,
                    style: _tajawal(20, FontWeight.w700)),
                const SizedBox(height: 8),
                // الوصف
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      Images.star_v2,
                      width: 25,
                      height: 25,
                      // If the asset is ever missing, show a fixed-size box
                      // instead of the giant error placeholder that squeezes the
                      // text next to it into a broken vertical column.
                      errorBuilder: (_, __, ___) =>
                          const SizedBox(width: 25, height: 25),
                    ),
                    const SizedBox(width: 6),
                    // Flexible so a long description wraps instead of overflowing.
                    Flexible(
                      child: Text(
                        'copy_your_code_share_it_with_your_friends'.tr,
                        textAlign: TextAlign.center,
                        style: _tajawal(16, FontWeight.w500,
                            color: const Color(0xFF111B18)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 1 الإحالة = السعر
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      Images.coin_doller,
                      width: 18,
                      height: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${'one_referral'.tr} = ',
                      style: _tajawal(18, FontWeight.w500,
                          color: Color(0xff111B18)),
                    ),
                    PriceConverter.convertPrice2(
                      refRate,
                      textStyle: _tajawal(
                        18,
                        FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // الرمز الشخصي الخاص بك
                Text('your_personal_code'.tr,
                    style: _tajawal(14, FontWeight.w700)),
                const SizedBox(height: 8),
                // حقل الرابط مع زر النسخ
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F5F8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          referralLink.isNotEmpty ? referralLink : '--',
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _tajawal(16, FontWeight.w700,
                              color: const Color(0xFF000000)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: _copy,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Image.asset(
                            Images.copyCoupon,
                            width: 25,
                            height: 25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // كيف يعمل ؟
                _HowItWorksBox(),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ==== صندوق: كيف يعمل ؟ ====
class _HowItWorksBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<String> steps = AppConstants.dataList;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xffEBFEEB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('how_it_works'.tr, style: _tajawal(16, FontWeight.w700)),
          const SizedBox(height: 12),
          ...List.generate(steps.length, (int i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${i + 1}- ',
                      style: _tajawal(
                        13,
                        FontWeight.w700,
                      )),
                  Expanded(
                    child: Text(steps[i], style: _tajawal(16, FontWeight.w700)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ==== تبويب: الأصدقاء المدعوين (بيانات حقيقية من الـ API) ====
class _InvitedFriendsTab extends StatefulWidget {
  const _InvitedFriendsTab();

  @override
  State<_InvitedFriendsTab> createState() => _InvitedFriendsTabState();
}

class _InvitedFriendsTabState extends State<_InvitedFriendsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.find<ReferralController>().getInvitedFriends();
    });
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            Images.no_one_invite,
            width: 204,
            height: 210,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          Text('refer_no_invited_friends'.tr,
              textAlign: TextAlign.center,
              style: _tajawal(15, FontWeight.w600, color: _title)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ReferralController>(builder: (controller) {
      if (controller.isLoading && controller.invitedFriends == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.hasError && controller.invitedFriends == null) {
        return ErrorStateView(
          onRetry: () => controller.getInvitedFriends(),
        );
      }

      final InvitedFriendsModel? model = controller.invitedFriends;
      final List<InvitedFriendItem> friends = model?.friends ?? const [];

      if (friends.isEmpty) {
        return RefreshIndicator(
          onRefresh: () => controller.getInvitedFriends(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              _emptyState(),
            ],
          ),
        );
      }

      final ReferralSummary? summary = model?.summary;
      return RefreshIndicator(
        onRefresh: () => controller.getInvitedFriends(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SummaryCard(
                totalRewards: summary?.totalRewards ?? 0,
                invitesCount: summary?.totalInvites ?? friends.length,
              ),
              const SizedBox(height: 16),
              ..._buildGrouped(friends),
            ],
          ),
        ),
      );
    });
  }

  List<Widget> _buildGrouped(List<InvitedFriendItem> list) {
    final List<Widget> widgets = [];
    String? currentLabel;
    for (final InvitedFriendItem f in list) {
      final String label = f.dateGroupLabel;
      if (label.isNotEmpty && label != currentLabel) {
        currentLabel = label;
        widgets.add(Padding(
          padding: EdgeInsets.only(top: widgets.isEmpty ? 0 : 14, bottom: 10),
          child: Text(label,
              style: _tajawal(16, FontWeight.w700,
                  color: const Color(0xFF707784))),
        ));
      }
      widgets.add(_FriendRow(friend: f));
    }
    return widgets;
  }
}

// ==== بطاقة الملخّص الخضراء ====
class _SummaryCard extends StatelessWidget {
  final double totalRewards;
  final int invitesCount;
  const _SummaryCard({required this.totalRewards, required this.invitesCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage(Images.card_quidha),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // إجمالي المكافآت
          Expanded(
            child: Column(
              children: [
                Text('$invitesCount',
                    style: _tajawal(26, FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text('refer_invites_count'.tr,
                    style: _tajawal(12, FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),

          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(totalRewards.toStringAsFixed(0),
                        style:
                            _tajawal(26, FontWeight.w700, color: Colors.white)),
                    const SizedBox(width: 5),
                    Image.asset(Images.sar,
                        width: 18, height: 18, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 4),
                Text('refer_total_rewards'.tr,
                    style: _tajawal(12, FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==== صف الصديق المدعو ====
class _FriendRow extends StatelessWidget {
  final InvitedFriendItem friend;
  const _FriendRow({required this.friend});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // الأفاتار (صورة الصديق من الـ API)
          ClipOval(
            child: friend.avatarFullUrl.isNotEmpty
                ? CustomImage(
                    image: friend.avatarFullUrl,
                    width: 38,
                    height: 38,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 38,
                    height: 38,
                    color: const Color(0xFFF6F5F8),
                    alignment: Alignment.center,
                    child:
                        Image.asset(Images.navProfile, width: 20, height: 20),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              friend.name,
              style: _tajawal(16, FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          friend.isRegistered
              ? _RegisteredBadge(reward: friend.rewardAmount)
              : const _PendingBadge(),
        ],
      ),
    );
  }
}

class _PendingBadge extends StatelessWidget {
  const _PendingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFDFD3F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            Images.pending_v2,
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 4),
          Text('refer_status_pending'.tr,
              style: _tajawal(12, FontWeight.w600,
                  color: const Color(0xFF111B18))),
        ],
      ),
    );
  }
}

class _RegisteredBadge extends StatelessWidget {
  final double reward;
  const _RegisteredBadge({required this.reward});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('+ ${reward.toStringAsFixed(0)}',
                style: _tajawal(13, FontWeight.w700, color: _primary)),
            const SizedBox(width: 3),
            Image.asset(Images.sar, width: 12, height: 12, color: _primary),
          ],
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFEBFEEB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check,
                size: 12,
              ),
              const SizedBox(width: 3),
              Text('refer_status_registered'.tr,
                  style:
                      _tajawal(12, FontWeight.w500, color: Color(0xFF111B18))),
            ],
          ),
        ),
      ],
    );
  }
}
