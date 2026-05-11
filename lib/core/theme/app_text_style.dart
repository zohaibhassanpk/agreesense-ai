import 'package:flutter/material.dart';
import '../extensions/responsive_extension.dart';
import 'app_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  // --- Display (Poppins SemiBold) ---
  static TextStyle displayLarge = TextStyle(
    fontFamily: AppFonts.poppinsFamily,
    fontSize: 30.sp,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = TextStyle(
    fontFamily: AppFonts.poppinsFamily,
    fontSize: 26.sp,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle displaySmall = TextStyle(
    fontFamily: AppFonts.poppinsFamily,
    fontSize: 24.sp,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.5,
  );

  // --- Headings (Poppins SemiBold) ---
  static TextStyle headingLarge = TextStyle(
    fontFamily: AppFonts.poppinsFamily,
    fontSize: 22.sp,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static TextStyle headingMedium = TextStyle(
    fontFamily: AppFonts.poppinsFamily,
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static TextStyle headingSmall = TextStyle(
    fontFamily: AppFonts.poppinsFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.2,
  );

  // --- Title (Poppins SemiBold) ---
  static TextStyle titleLarge = TextStyle(
    fontFamily: AppFonts.poppinsFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle titleMedium = TextStyle(
    fontFamily: AppFonts.poppinsFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle titleSmall = TextStyle(
    fontFamily: AppFonts.poppinsFamily,
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // --- Body (Poppins Medium) ---
  static TextStyle bodyLarge = TextStyle(
    fontFamily: AppFonts.poppinsFamily,
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodyMedium = TextStyle(
    fontFamily: AppFonts.poppinsFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle bodySmall = TextStyle(
    fontFamily: AppFonts.poppinsFamily,
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // --- Label ---
  static TextStyle labelLarge = TextStyle(
    fontFamily: AppFonts.poppinsFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.1,
  );

  static TextStyle labelMedium = TextStyle(
    fontFamily: AppFonts.poppinsFamily,
    fontSize: 12.sp,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static TextStyle labelSmall = TextStyle(
    fontFamily: AppFonts.poppinsFamily,
    fontSize: 10.sp,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.5,
  );

  /// Default button text — SemiBold to match design.
  static TextStyle button = TextStyle(
    fontFamily: AppFonts.poppinsFamily,
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );
}
