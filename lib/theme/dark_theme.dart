import 'package:flutter/material.dart';
import 'package:sixam_mart/theme/app_color_tokens.dart';
import 'package:sixam_mart/theme/light_theme.dart';
import 'package:sixam_mart/util/app_constants.dart';

ThemeData dark({Color color = const Color(0xFF31A342)}) => ThemeData(
      fontFamily: AppConstants.fontFamily,
      primaryColor: color,
      secondaryHeaderColor: const Color(0xFF31A342),
      disabledColor: const Color(0xffa2a7ad),
      brightness: Brightness.dark,
      hintColor: const Color(0xFFbebebe),
      cardColor: const Color(0xFF30313C),
      shadowColor: Colors.white.withValues(alpha: 0.03),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: Colors.white70),
      ),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: color)),
      colorScheme: ColorScheme.dark(primary: color, secondary: color)
          .copyWith(surface: const Color(0xFF191A26))
          .copyWith(error: const Color(0xFFdd3135)),
      popupMenuTheme: const PopupMenuThemeData(
          color: Color(0xFF29292D), surfaceTintColor: Color(0xFF29292D)),
      dialogTheme: const DialogThemeData(surfaceTintColor: Colors.white10),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(500))),
      bottomAppBarTheme: const BottomAppBarThemeData(
        surfaceTintColor: Colors.black,
        height: 60,
        padding: EdgeInsets.symmetric(vertical: 5),
      ),
      dividerTheme:
          const DividerThemeData(thickness: 0.5, color: Color(0xFFA0A4A8)),
      tabBarTheme: const TabBarThemeData(dividerColor: Colors.transparent),
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

      // ===============

      extensions: <ThemeExtension<dynamic>>[
        const AppColorTokens(
          surfaceSoft: Color(0xFF232634),
          outlineSoft: Color(0xFF3B3F52),
          successSoft: Color(0x2231A342),
          warningSoft: Color(0x332D1E05),
          warningText: Color(0xFFFFC980),
        ),
        CustomThemeExtension(
          yellow_Color: const Color(0xFFFA9D2B),
          white_Color: Colors.white,
        ), // لون الإطار
      ],
    );



// Theme.of(context).extension<CustomThemeExtension>()!.white_Color
