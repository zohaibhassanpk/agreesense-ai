import 'package:flutter/material.dart';
import '../../extensions/context_extensions.dart';
import '../../extensions/widget_extensions.dart';

class CustomLoader extends StatefulWidget {
  final double size;
  final Color? color;

  const CustomLoader({super.key, this.size = 40, this.color});

  @override
  State<CustomLoader> createState() => _CustomLoaderState();
}

class _CustomLoaderState extends State<CustomLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.colorScheme.primary;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            children: List.generate(3, (index) {
              final delay = index * 0.15;
              final value = (_controller.value - delay) % 1.0;

              return Transform.scale(
                scale: value < 0.5 ? value * 2 : (1 - value) * 2,
                child: SizedBox(width: widget.size, height: widget.size)
                    .decorated(
                      shape: BoxShape.circle,
                      border: Border.all(color: color, width: 2),
                    )
                    .opacity(value < 0.5 ? 1.0 : (1 - value) * 2),
              ).center();
            }),
          );
        },
      ),
    );
  }
}
