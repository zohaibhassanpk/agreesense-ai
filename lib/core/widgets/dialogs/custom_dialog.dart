import '../../theme/app_colors.dart';
import '../loaders/custom_loader.dart';
import 'package:flutter/material.dart';
import '../more/custom_image_widget.dart';
import '../../constants/app_constants.dart';
import '../../extensions/widget_extensions.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/responsive_extension.dart';

class CustomDialog extends StatefulWidget {
  final String? title;
  final Widget child;
  final bool dismissible;
  final double? width;
  final double? height;
  // final VoidCallback? onClose;
  final String? topIcon;
  final Color? topIconBgColor;
  final Color? topIconColor;

  const CustomDialog({
    super.key,
    this.title,
    required this.child,
    this.dismissible = true,
    this.width,
    this.height,
    // this.onClose,
    this.topIcon,
    this.topIconBgColor,
    this.topIconColor,
  });

  static Future<void> show(
    BuildContext context, {
    String? title,
    required Widget child,
    bool dismissible = true,
    double? width,
    double? height,
    // VoidCallback? onClose,
    String? topIcon,
    Color? topIconBgColor,
    Color? topIconColor,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: '',
      barrierColor: AppColors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (context, anim1, _, childWidget) {
        return Transform.scale(
          scale: Curves.easeOutBack.transform(anim1.value),
          child: CustomDialog(
            title: title,
            dismissible: dismissible,
            width: width,
            height: height,
            // onClose: onClose,
            topIcon: topIcon,
            topIconBgColor: topIconBgColor,
            topIconColor: topIconColor,
            child: child,
          ).center().opacity(anim1.value),
        );
      },
    );
  }

  @override
  State<CustomDialog> createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog> {
  bool isLoading = false;
  dynamic dialogValue;

  void showLoading(bool value) {
    setState(() => isLoading = value);
  }

  void updateValue(dynamic value) {
    setState(() => dialogValue = value);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      elevation: 12,
      shadowColor: AppColors.black.withValues(alpha: 0.1),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.width ?? context.sw * 0.8,
          minWidth: context.sw * 0.4,
          maxHeight: context.sh * 0.8,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            /// ---------- Dialog Body ----------
            Container(
              margin: EdgeInsets.only(top: widget.topIcon != null ? 30 : 0),
              padding: EdgeInsets.symmetric(
                horizontal: AppConstants.hPadding,
                vertical: AppConstants.vPadding,
              ),
              child: IntrinsicHeight(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// ---------- Header ----------
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.center,
                      //   children: [
                      // const SizedBox(width: 40),
                      if (widget.title != null)
                        Center(
                          child: Text(
                            widget.title!,
                            textAlign: TextAlign.center,
                            style: context.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      // CustomIconButton(
                      //   icon: Icons.close_rounded,
                      //   onPressed: () {
                      //     widget.onClose?.call();
                      //     Navigator.of(context).maybePop();
                      //   },
                      // ),
                      //   ],
                      // ),
                      20.ht,

                      /// ---------- Body ----------
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: isLoading
                            ? CustomLoader().center().paddingAll(30)
                            : widget.child,
                      ),
                    ],
                  ),
                ),
              ),
            ).decorated(
              color: context.theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),

            /// ---------- Top Icon ----------
            if (widget.topIcon != null)
              Positioned(
                top: -30,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    height: 55.w,
                    width: 55.w,
                    decoration: BoxDecoration(
                      color: widget.topIconBgColor ?? AppColors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surfaceDarkLight,
                        width: 2,
                      ),
                    ),
                    padding: EdgeInsets.all(12.w),
                    child: CustomImage(
                      image: widget.topIcon!,
                      color: widget.topIconColor ?? Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
