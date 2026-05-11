import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class HomeColorResolver {
  HomeColorResolver._();

  static Color byKey(String key) {
    switch (key) {
      case 'blue':
        return AppColors.accentBlue;
      case 'brown':
        return AppColors.accentBrown;
      case 'yellow':
        return AppColors.accentYellow;
      case 'primary':
      default:
        return AppColors.primary;
    }
  }
}
