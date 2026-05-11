import '../../theme/app_colors.dart';
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../extensions/widget_extensions.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/responsive_extension.dart';

class CustomBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: AppColors.transparent,
      builder: (context) => SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: context.sh * 0.8,
              maxWidth: context.sw,
              minWidth: context.sw,
            ),
            child:
                Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        12.ht,
                        Container(
                          width: 40.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: context.colorScheme.onSurface.withValues(
                              alpha: 0.3,
                            ),
                            borderRadius: BorderRadius.circular(2.w),
                          ),
                        ),
                        child,
                      ],
                    )
                    .decorated(
                      color: context.colorScheme.surface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppConstants.borderRadius),
                      ),
                    )
                    .marginSymmetric(
                      vertical: AppConstants.vPadding,
                      horizontal: AppConstants.hPadding,
                    ),
          ),
        ),
      ),
    );
  }
}
