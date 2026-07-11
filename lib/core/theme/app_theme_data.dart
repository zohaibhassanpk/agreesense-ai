import 'app_colors.dart';
import 'app_fonts.dart';
import 'app_spacing.dart';
import 'app_text_style.dart';
import 'app_border_radius.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../extensions/responsive_extension.dart';

class AppThemeData {
  AppThemeData._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: AppFonts.poppinsFamily,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.white,
      secondary: AppColors.darkGreen,
      onSecondary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surface,
      outline: AppColors.border,
      shadow: AppColors.overlayDark,
    ),
    textTheme: TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(
        color: AppColors.textPrimary,
      ),
      displayMedium: AppTextStyles.displayMedium.copyWith(
        color: AppColors.textPrimary,
      ),
      displaySmall: AppTextStyles.displaySmall.copyWith(
        color: AppColors.textPrimary,
      ),
      headlineLarge: AppTextStyles.headingLarge.copyWith(
        color: AppColors.textPrimary,
      ),
      headlineMedium: AppTextStyles.headingMedium.copyWith(
        color: AppColors.textPrimary,
      ),
      headlineSmall: AppTextStyles.headingSmall.copyWith(
        color: AppColors.textPrimary,
      ),
      titleLarge: AppTextStyles.titleLarge.copyWith(
        color: AppColors.textPrimary,
      ),
      titleMedium: AppTextStyles.titleMedium.copyWith(
        color: AppColors.textPrimary,
      ),
      titleSmall: AppTextStyles.titleSmall.copyWith(
        color: AppColors.textPrimary,
      ),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textPrimary,
      ),
      bodySmall: AppTextStyles.bodySmall.copyWith(
        color: AppColors.textSecondary,
      ),
      labelLarge: AppTextStyles.labelLarge.copyWith(
        color: AppColors.textPrimary,
      ),
      labelMedium: AppTextStyles.labelMedium.copyWith(
        color: AppColors.textSecondary,
      ),
      labelSmall: AppTextStyles.labelSmall.copyWith(
        color: AppColors.textSecondary,
      ),
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.textPrimary,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: AppTextStyles.headingSmall.copyWith(
        color: AppColors.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.card,
        side: const BorderSide(color: AppColors.borderLight, width: 1),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 1,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        disabledBackgroundColor: AppColors.border,
        disabledForegroundColor: AppColors.textTertiary,
        shadowColor: AppColors.primaryTint30,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.x2l.w,
          vertical: AppSpacing.lg.h,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.button),
        textStyle: AppTextStyles.button,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        disabledForegroundColor: AppColors.textTertiary,
        side: const BorderSide(color: AppColors.border, width: 1),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.x2l.w,
          vertical: AppSpacing.lg.h,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.button),
        textStyle: AppTextStyles.button,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.textTertiary,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg.w,
          vertical: AppSpacing.md.h,
        ),
        textStyle: AppTextStyles.button,
      ),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionColor: AppColors.primaryTint20,
      selectionHandleColor: AppColors.primary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceMuted,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl.w,
        vertical: AppSpacing.lg.h,
      ),
      border: OutlineInputBorder(
        borderRadius: AppBorderRadius.input,
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.input,
        borderSide: const BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.input,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.input,
        borderSide: const BorderSide(color: AppColors.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppBorderRadius.input,
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
      hintStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textTertiary,
      ),
      labelStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textSecondary,
      ),
      errorStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceMuted,
      selectedColor: AppColors.darkGreen,
      disabledColor: AppColors.border,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg.w,
        vertical: AppSpacing.sm.h,
      ),
      labelStyle: AppTextStyles.labelMedium,
      side: const BorderSide(color: AppColors.border, width: 1),
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.chip),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.navActive,
      unselectedItemColor: AppColors.navInactive,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: true,
      showUnselectedLabels: true,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      thickness: 1,
      space: 1,
    ),
    iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 24),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.dialog,
        side: const BorderSide(color: AppColors.borderLight, width: 1),
      ),
      titleTextStyle: AppTextStyles.headingMedium.copyWith(
        color: AppColors.textPrimary,
      ),
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.textSecondary,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorderRadius.bottomSheet,
        side: BorderSide(color: AppColors.borderLight, width: 1),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      contentTextStyle: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.white,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.button),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
