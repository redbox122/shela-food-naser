import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/profile/controllers/profile_controller.dart';
import 'package:sixam_mart/util/app_colors.dart';

/// Full-screen "delete account" confirmation. The destructive button stays
/// disabled until the user ticks the acknowledgement checkbox.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  static const Color _titleColor = Color(0xFF2D3633);
  static const Color _disabledColor = Color(0xFFE5E7EB);

  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final Color danger = Theme.of(context).colorScheme.error;
    return Scaffold(
      backgroundColor: AppColors.wtColor,
      appBar: AppBar(
        backgroundColor: AppColors.wtColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'pf_delete_account'.tr,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _titleColor,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: _titleColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'pf_review_before_delete'.tr,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 17,
                        height: 1.6,
                        fontWeight: FontWeight.w700,
                        color: _titleColor,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'pf_delete_warning'.tr,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 16,
                        height: 1.8,
                        fontWeight: FontWeight.w500,
                        color: _titleColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(Icons.warning_amber_rounded,
                            size: 25, color: danger),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'pf_action_irreversible'.tr,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                              height: 1.6,
                              fontWeight: FontWeight.w700,
                              color: danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _buildFooter(context, danger),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, Color danger) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          InkWell(
            onTap: () => setState(() => _agreed = !_agreed),
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: <Widget>[
                  _buildCheckbox(),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'pf_read_and_agree'.tr,
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _titleColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GetBuilder<ProfileController>(
            builder: (ProfileController pc) {
              final bool enabled = _agreed && !pc.isLoading;
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: Material(
                  color: enabled ? AppColors.primaryColor : _disabledColor,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: enabled ? () => pc.deleteUser(context) : null,
                    child: Center(
                      child: pc.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.wtColor),
                            )
                          : Text(
                              'pf_delete_account'.tr,
                              style: TextStyle(
                                fontFamily: 'Tajawal',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: enabled
                                    ? AppColors.wtColor
                                    : const Color(0xFF9AA0A6),
                              ),
                            ),
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

  Widget _buildCheckbox() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: _agreed ? AppColors.primaryColor : AppColors.wtColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _agreed ? AppColors.primaryColor : AppColors.gryColor_4,
          width: 1.6,
        ),
      ),
      child: _agreed
          ? const Icon(Icons.check, size: 15, color: AppColors.wtColor)
          : null,
    );
  }
}
