// ignore_for_file: deprecated_member_use, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/util/app_constants.dart';

ThemeData light({Color color = const Color(0xFF31A342)}) => ThemeData(
      fontFamily: AppConstants.fontFamily,
      primaryColor: color,
      secondaryHeaderColor: const Color(0xFF31A342),
      disabledColor: const Color(0xFFBABFC4),
      brightness: Brightness.light,
      hintColor: const Color(0xFF9F9F9F),
      cardColor: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.03),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: color)),
      colorScheme: ColorScheme.light(primary: color, secondary: color)
          .copyWith(surface: const Color(0xFFFCFCFC))
          .copyWith(error: const Color(0xFFE84D4F)),
      popupMenuTheme: const PopupMenuThemeData(
          color: Colors.white, surfaceTintColor: Colors.white),
      dialogTheme: const DialogThemeData(surfaceTintColor: Colors.white),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(500))),
      bottomAppBarTheme: const BottomAppBarThemeData(
        surfaceTintColor: Colors.white,
        height: 60,
        padding: EdgeInsets.symmetric(vertical: 5),
      ),
      dividerTheme:
          const DividerThemeData(thickness: 0.2, color: Color(0xFFA0A4A8)),
      tabBarTheme: const TabBarThemeData(dividerColor: Colors.transparent),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.black87),
      ),
      // ضبط ألوان النص والـ input صراحةً لتفادي اللون البنفسجي الافتراضي على iOS
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: color,
        selectionColor: color.withValues(alpha: 0.3),
        selectionHandleColor: color,
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: color),
        ),
      ),

      //

      extensions: <ThemeExtension<dynamic>>[
        const AppColorTokens(
          surfaceSoft: Color(0xFFF5F7FA),
          outlineSoft: Color(0xFFDADFE5),
          successSoft: Color(0x2231A342),
          warningSoft: Color(0xFFFFF3E0),
          warningText: Color(0xFF8A4B00),
        ),
        CustomThemeExtension(
          yellow_Color: const Color(0xFFFA9D2B),
          white_Color: Colors.white,
        ), // لون الإطار
      ],
    );

// كلاس مخصص لإضافة اللون الجديد
class CustomThemeExtension extends ThemeExtension<CustomThemeExtension> {
  final Color yellow_Color;
  final Color white_Color;

  CustomThemeExtension({
    required this.yellow_Color,
    required this.white_Color,
  });

  @override
  CustomThemeExtension copyWith({Color? yellow_Color, Color? white_Color}) {
    return CustomThemeExtension(
      yellow_Color: yellow_Color ?? this.yellow_Color,
      white_Color: white_Color ?? this.white_Color,
    );
  }

  @override
  CustomThemeExtension lerp(CustomThemeExtension? other, double t) {
    if (other == null) return this;
    return CustomThemeExtension(
      yellow_Color: Color.lerp(yellow_Color, other.yellow_Color, t)!,
      white_Color: Color.lerp(white_Color, other.white_Color, t)!,
    );
  }
}


// Theme.of(context).extension<CustomThemeExtension>()!.white_Color
