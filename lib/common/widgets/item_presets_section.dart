import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sixam_mart/features/item/domain/models/item_model.dart';
import 'package:sixam_mart/util/styles.dart';
import 'package:sixam_mart/helper/price_converter.dart';
import 'package:sixam_mart/common/utils/app_logger.dart';

/// Presets section widget displaying horizontal scrollable preset cards
class ItemPresetsSection extends StatelessWidget {
  final List<Preset> presets;
  final Preset? selectedPreset;
  final Function(Preset) onPresetSelected;

  const ItemPresetsSection({
    super.key,
    required this.presets,
    this.selectedPreset,
    required this.onPresetSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (presets.isEmpty) {
      return const SizedBox.shrink();
    }

    final isArabic = Get.locale?.languageCode == 'ar';
    
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Column(
        crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                Text(
                  'التركيبات الشائعة', // Popular Combinations
                  style: robotoBold.copyWith(
                    fontSize: 16,
                    color: const Color(0xFF2D3633),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate dynamic height based on content
              // Estimate: 20 (radio) + 12*2 (padding) + 20 (name) + 6 (spacing) +
              // (9 * lineHeight * numLines for description) + 8 (spacing) + 15 (price) + 12*2 (padding)
              // For now, use a reasonable max height that adapts
              return SizedBox(
                height:
                    140, // Adaptive height - will be adjusted by card content
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: presets.length,
                  padding: const EdgeInsets.only(bottom: 4),
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 12),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final preset = presets[index];
                    final isSelected = selectedPreset?.id == preset.id;
                    return _PresetCard(
                      preset: preset,
                      isSelected: isSelected,
                      onTap: () => onPresetSelected(preset),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final Preset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetCard({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  /// Build a description showing what's included in the preset
  String _buildPresetDescription(Preset preset) {
    if (preset.presetData?.choiceGroups == null ||
        preset.presetData!.choiceGroups!.isEmpty) {
      return '';
    }

    // Get current language from locale
    final isArabic = Get.locale?.languageCode == 'ar';

    if (kDebugMode) {
      appLogger.debug('🔍 [Preset Description] Building for: ${preset.name}');
      appLogger.debug('   - Language: ${isArabic ? "Arabic" : "English"}');
      appLogger.debug('   - Choice groups: ${preset.presetData!.choiceGroups!.length}');
    }

    final List<String> selections = [];
    for (final group in preset.presetData!.choiceGroups!) {
      for (final choice in group.choices) {
        // Debug what we're getting
        if (kDebugMode) {
          appLogger.debug(
              '   - Choice: name="${choice.name}", name_ar="${choice.nameAr}", name_en="${choice.nameEn}"');
        }

        // Use localized name
        final String? choiceName = isArabic
            ? (choice.nameAr ?? choice.name)
            : (choice.nameEn ?? choice.name);

        if (choiceName != null && choiceName.isNotEmpty) {
          selections.add(choiceName);
        }
      }
    }

    if (kDebugMode) {
      appLogger.debug('   - Total selections: ${selections.length}');
      appLogger.debug('   - Selections: $selections');
    }

    if (selections.isEmpty) return '';

    // Show ALL selections separated by bullet points
    return selections.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    // Get current language from locale
    final isArabic = Get.locale?.languageCode == 'ar';
    final presetName = isArabic
        ? (preset.nameAr ?? preset.name ?? '')
        : (preset.nameEn ?? preset.name ?? '');

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 200, // Fixed width for consistency
          constraints: const BoxConstraints(
            minHeight: 80, // Minimum height
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF31A342)
                  : const Color(0xFFEDEDED),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x1A31A342),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Use minimum space needed
            children: [
              // Preset name and radio button row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preset name (right side in RTL, left in LTR)
                  Expanded(
                    child: Text(
                      presetName,
                      style: robotoMedium.copyWith(
                        fontSize: 13,
                        color: const Color(0xFF2D3633),
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Radio button (left side in RTL, right in LTR)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF31A342)
                            : const Color(0xFFC6C6C6),
                        width: 2,
                      ),
                      color: Colors.white,
                    ),
                    child: isSelected
                        ? Center(
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF31A342),
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),

              // Preset details/description (what's included)
              if (preset.presetData?.choiceGroups != null &&
                  _buildPresetDescription(preset).isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _buildPresetDescription(preset),
                  style: robotoRegular.copyWith(
                    fontSize: 9,
                    color: const Color(0xFF9E9E9E),
                    height: 1.3,
                  ),
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                  overflow: TextOverflow.visible,
                ),
              ],

              // Bottom section - price
              if (preset.price != null && preset.price! > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '+${PriceConverter.convertPrice(preset.price)} ريال',
                  style: robotoRegular.copyWith(
                    fontSize: 11,
                    color: const Color(0xFF31A342),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: isArabic ? TextAlign.right : TextAlign.left,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
