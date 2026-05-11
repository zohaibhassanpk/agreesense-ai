import 'package:flutter/material.dart';
import '../../extensions/widget_extensions.dart';
import '../../extensions/responsive_extension.dart';

class ShimmerLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerLoader({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<ShimmerLoader> createState() => _ShimmerLoaderState();
}

class _ShimmerLoaderState extends State<ShimmerLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(width: widget.width, height: widget.height).decorated(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8.r),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              const Color(0xFFE5E5E5),
              const Color(0xFFF5F5F5),
              const Color(0xFFE5E5E5),
            ],
            stops: [
              _animation.value - 0.3,
              _animation.value,
              _animation.value + 0.3,
            ].map((e) => e.clamp(0.0, 1.0)).toList(),
          ),
        );
      },
    );
  }
}
