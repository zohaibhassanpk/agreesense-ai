import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class RefreshIconButton extends StatefulWidget {
  const RefreshIconButton({
    super.key,
    required this.isAnimating,
    this.onPressed,
  });

  final bool isAnimating;
  final VoidCallback? onPressed;

  @override
  State<RefreshIconButton> createState() => _RefreshIconButtonState();
}

class _RefreshIconButtonState extends State<RefreshIconButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant RefreshIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isAnimating && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isAnimating && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: widget.onPressed,
      radius: AppSpacing.xl.r,
      child: RotationTransition(
        turns: _controller,
        child: SvgPicture.asset(
          AppAssets.refresh,
          width: AppSpacing.xl.w,
          height: AppSpacing.xl.w,
          colorFilter: const ColorFilter.mode(
            AppColors.primary,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
