import 'package:flutter/material.dart';

class AppColorTokens extends ThemeExtension<AppColorTokens> {
  final Color surfaceSoft;
  final Color outlineSoft;
  final Color successSoft;
  final Color warningSoft;
  final Color warningText;

  const AppColorTokens({
    required this.surfaceSoft,
    required this.outlineSoft,
    required this.successSoft,
    required this.warningSoft,
    required this.warningText,
  });

  @override
  AppColorTokens copyWith({
    Color? surfaceSoft,
    Color? outlineSoft,
    Color? successSoft,
    Color? warningSoft,
    Color? warningText,
  }) {
    return AppColorTokens(
      surfaceSoft: surfaceSoft ?? this.surfaceSoft,
      outlineSoft: outlineSoft ?? this.outlineSoft,
      successSoft: successSoft ?? this.successSoft,
      warningSoft: warningSoft ?? this.warningSoft,
      warningText: warningText ?? this.warningText,
    );
  }

  @override
  AppColorTokens lerp(AppColorTokens? other, double t) {
    if (other == null) return this;
    return AppColorTokens(
      surfaceSoft: Color.lerp(surfaceSoft, other.surfaceSoft, t)!,
      outlineSoft: Color.lerp(outlineSoft, other.outlineSoft, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
    );
  }
}
