import '../../theme/app_colors.dart';
import '../loaders/custom_loader.dart';
import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/responsive_extension.dart';

class AnimatedButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final double? width;
  final double? height;
  final bool enabled;
  final bool fitToContent;
  final double? fontSize;
  final FontWeight? fontWeight;

  const AnimatedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.width,
    this.height,
    this.enabled = true,
    this.fitToContent = false,
    this.fontSize,
    this.fontWeight,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  bool get _isInteractive =>
      widget.enabled && !widget.isLoading && widget.onPressed != null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (_isInteractive) _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (_isInteractive) _controller.reverse();
  }

  void _handleTapCancel() {
    if (_isInteractive) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final buttonChild = widget.isLoading
        ? CustomLoader(color: widget.foregroundColor ?? AppColors.white)
        : Row(
            mainAxisSize: widget.fitToContent
                ? MainAxisSize.min
                : MainAxisSize.max,
            children: [
              /// Left spacer for center alignment
              if (!widget.fitToContent) const Spacer(),

              /// Centered Text
              Text(
                widget.text,
                style: context.textTheme.titleMedium?.copyWith(
                  color: widget.foregroundColor ?? AppColors.white,
                  fontWeight: widget.fontWeight ?? FontWeight.w600,
                  fontSize: widget.fontSize,
                ),
              ),

              /// Push icon to the right
              if (widget.icon != null) ...[
                10.wt,
                Icon(
                  widget.icon,
                  color: widget.foregroundColor ?? AppColors.white,
                  size: 20.sp,
                ),
              ],

              /// Right spacer for full width
              if (!widget.fitToContent) const Spacer(),
            ],
          );

    final container = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: widget.height ?? 60.h,
      width: widget.fitToContent ? null : (widget.width ?? double.infinity),
      padding: widget.fitToContent
          ? EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: _isInteractive
            ? widget.backgroundColor ?? context.theme.colorScheme.primary
            : context.theme.disabledColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: _isInteractive
            ? [
                BoxShadow(
                  color:
                      (widget.backgroundColor ??
                              context.theme.colorScheme.primary)
                          .withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Center(child: buttonChild),
    );

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _isInteractive ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _isInteractive ? _scaleAnimation.value : 1,
            child: widget.fitToContent
                ? IntrinsicWidth(child: IntrinsicHeight(child: container))
                : container,
          );
        },
      ),
    );
  }
}
