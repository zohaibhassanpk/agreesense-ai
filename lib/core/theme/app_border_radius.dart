import 'package:flutter/material.dart';

class AppBorderRadius {
  AppBorderRadius._();

  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double circular = 999;

  /// Buttons, inputs — rounded-2xl (16px).
  static const BorderRadius button = BorderRadius.all(Radius.circular(s16));
  static const BorderRadius input = button;

  /// Chips, genre pills — rounded-full.
  static const BorderRadius chip = BorderRadius.all(Radius.circular(circular));

  /// Cards, panels — rounded-3xl (24px).
  static const BorderRadius card = BorderRadius.all(Radius.circular(s24));

  /// Dialogs — rounded-3xl (24px).
  static const BorderRadius dialog = BorderRadius.all(Radius.circular(s24));

  /// Bottom sheets.
  static const BorderRadius bottomSheet = BorderRadius.vertical(
    top: Radius.circular(s32),
  );
}
