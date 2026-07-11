import 'package:flutter/material.dart';
import '../../extensions/responsive_extension.dart';

/// A fully customizable shimmer widget that supports single container, list, and grid layouts
/// with customizable dimensions, shapes, and border radius
class CustomShimmerWidget extends StatefulWidget {
  /// Type of shimmer layout
  final ShimmerType type;

  /// Height of the shimmer container
  final double? height;

  /// Width of the shimmer container
  final double? width;

  /// Border radius for the shimmer container
  final double? borderRadius;

  /// Shape of the shimmer (rectangle or circle)
  final ShimmerShape shape;

  /// Number of items for list or grid layout
  final int itemCount;

  /// Cross axis count for grid layout
  final int crossAxisCount;

  /// Spacing between items in list/grid
  final double spacing;

  /// Cross axis spacing for grid
  final double crossAxisSpacing;

  /// Main axis spacing for grid
  final double mainAxisSpacing;

  /// Padding around the shimmer
  final EdgeInsets? padding;

  /// Margin around the shimmer
  final EdgeInsets? margin;

  /// Base color of the shimmer
  final Color baseColor;

  /// Highlight color of the shimmer
  final Color highlightColor;

  /// Duration of the shimmer animation
  final Duration duration;

  /// Aspect ratio for grid items
  final double? childAspectRatio;

  /// Custom child builder for advanced customization
  final Widget Function(BuildContext context, int index)? customChildBuilder;

  /// Scroll direction for list
  final Axis scrollDirection;

  /// Whether the shimmer should be scrollable
  final bool scrollable;

  const CustomShimmerWidget({
    super.key,
    this.type = ShimmerType.single,
    this.height,
    this.width,
    this.borderRadius,
    this.shape = ShimmerShape.rectangle,
    this.itemCount = 5,
    this.crossAxisCount = 2,
    this.spacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.padding,
    this.margin,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.duration = const Duration(milliseconds: 1500),
    this.childAspectRatio,
    this.customChildBuilder,
    this.scrollDirection = Axis.vertical,
    this.scrollable = false,
  });

  /// Factory constructor for single shimmer container
  factory CustomShimmerWidget.single({
    Key? key,
    double? height,
    double? width,
    double? borderRadius,
    ShimmerShape shape = ShimmerShape.rectangle,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return CustomShimmerWidget(
      key: key,
      type: ShimmerType.single,
      height: height,
      width: width,
      borderRadius: borderRadius,
      shape: shape,
      padding: padding,
      margin: margin,
      baseColor: baseColor,
      highlightColor: highlightColor,
      duration: duration,
    );
  }

  /// Factory constructor for list shimmer
  factory CustomShimmerWidget.list({
    Key? key,
    double? height,
    double? width,
    double? borderRadius,
    ShimmerShape shape = ShimmerShape.rectangle,
    int itemCount = 5,
    double spacing = 10.0,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
    Duration duration = const Duration(milliseconds: 1500),
    Axis scrollDirection = Axis.vertical,
    bool scrollable = false,
    Widget Function(BuildContext context, int index)? customChildBuilder,
  }) {
    return CustomShimmerWidget(
      key: key,
      type: ShimmerType.list,
      height: height,
      width: width,
      borderRadius: borderRadius,
      shape: shape,
      itemCount: itemCount,
      spacing: spacing,
      padding: padding,
      margin: margin,
      baseColor: baseColor,
      highlightColor: highlightColor,
      duration: duration,
      scrollDirection: scrollDirection,
      scrollable: scrollable,
      customChildBuilder: customChildBuilder,
    );
  }

  /// Factory constructor for grid shimmer
  factory CustomShimmerWidget.grid({
    Key? key,
    double? height,
    double? width,
    double? borderRadius,
    ShimmerShape shape = ShimmerShape.rectangle,
    int itemCount = 6,
    int crossAxisCount = 2,
    double crossAxisSpacing = 8.0,
    double mainAxisSpacing = 8.0,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
    Duration duration = const Duration(milliseconds: 1500),
    double? childAspectRatio,
    bool scrollable = false,
    Widget Function(BuildContext context, int index)? customChildBuilder,
  }) {
    return CustomShimmerWidget(
      key: key,
      type: ShimmerType.grid,
      height: height,
      width: width,
      borderRadius: borderRadius,
      shape: shape,
      itemCount: itemCount,
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      padding: padding,
      margin: margin,
      baseColor: baseColor,
      highlightColor: highlightColor,
      duration: duration,
      childAspectRatio: childAspectRatio,
      scrollable: scrollable,
      customChildBuilder: customChildBuilder,
    );
  }

  /// Factory constructor for circular shimmer (avatar/profile picture)
  factory CustomShimmerWidget.circle({
    Key? key,
    double size = 50.0,
    EdgeInsets? padding,
    EdgeInsets? margin,
    Color baseColor = const Color(0xFFE0E0E0),
    Color highlightColor = const Color(0xFFF5F5F5),
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    return CustomShimmerWidget(
      key: key,
      type: ShimmerType.single,
      height: size,
      width: size,
      shape: ShimmerShape.circle,
      padding: padding,
      margin: margin,
      baseColor: baseColor,
      highlightColor: highlightColor,
      duration: duration,
    );
  }

  @override
  State<CustomShimmerWidget> createState() => _CustomShimmerWidgetState();
}

class _CustomShimmerWidgetState extends State<CustomShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();

    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case ShimmerType.single:
        return _buildSingleShimmer();
      case ShimmerType.list:
        return _buildListShimmer();
      case ShimmerType.grid:
        return _buildGridShimmer();
    }
  }

  Widget _buildSingleShimmer() {
    return Container(
      padding: widget.padding,
      margin: widget.margin,
      child: _buildShimmerContainer(
        height: widget.height ?? 100,
        width: widget.width ?? double.infinity,
      ),
    );
  }

  Widget _buildListShimmer() {
    if (widget.scrollable) {
      return ListView.separated(
        padding: widget.padding,
        scrollDirection: widget.scrollDirection,
        itemCount: widget.itemCount,
        separatorBuilder: (context, index) => SizedBox(
          height: widget.scrollDirection == Axis.vertical ? widget.spacing : 0,
          width: widget.scrollDirection == Axis.horizontal ? widget.spacing : 0,
        ),
        itemBuilder: (context, index) {
          if (widget.customChildBuilder != null) {
            return widget.customChildBuilder!(context, index);
          }
          return _buildShimmerContainer(
            height: widget.height ?? 100,
            width:
                widget.width ??
                (widget.scrollDirection == Axis.horizontal
                    ? 150
                    : double.infinity),
          );
        },
      );
    }

    return Container(
      padding: widget.padding,
      child: widget.scrollDirection == Axis.vertical
          ? Column(
              children: List.generate(
                widget.itemCount,
                (index) => Column(
                  children: [
                    if (widget.customChildBuilder != null)
                      widget.customChildBuilder!(context, index)
                    else
                      _buildShimmerContainer(
                        height: widget.height ?? 100,
                        width: widget.width ?? double.infinity,
                      ),
                    if (index < widget.itemCount - 1)
                      SizedBox(height: widget.spacing),
                  ],
                ),
              ),
            )
          : Row(
              children: List.generate(
                widget.itemCount,
                (index) => Row(
                  children: [
                    if (widget.customChildBuilder != null)
                      widget.customChildBuilder!(context, index)
                    else
                      _buildShimmerContainer(
                        height: widget.height ?? 100,
                        width: widget.width ?? 150,
                      ),
                    if (index < widget.itemCount - 1)
                      SizedBox(width: widget.spacing),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildGridShimmer() {
    if (widget.scrollable) {
      return GridView.builder(
        padding: widget.padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          crossAxisSpacing: widget.crossAxisSpacing,
          mainAxisSpacing: widget.mainAxisSpacing,
          childAspectRatio: widget.childAspectRatio ?? 1.0,
        ),
        itemCount: widget.itemCount,
        itemBuilder: (context, index) {
          if (widget.customChildBuilder != null) {
            return widget.customChildBuilder!(context, index);
          }
          return _buildShimmerContainer(
            height: widget.height,
            width: widget.width,
          );
        },
      );
    }

    return Container(
      padding: widget.padding,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          crossAxisSpacing: widget.crossAxisSpacing,
          mainAxisSpacing: widget.mainAxisSpacing,
          childAspectRatio: widget.childAspectRatio ?? 1.0,
        ),
        itemCount: widget.itemCount,
        itemBuilder: (context, index) {
          if (widget.customChildBuilder != null) {
            return widget.customChildBuilder!(context, index);
          }
          return _buildShimmerContainer(
            height: widget.height,
            width: widget.width,
          );
        },
      ),
    );
  }

  Widget _buildShimmerContainer({double? height, double? width}) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: height,
          width: width,
          margin: widget.margin,
          decoration: widget.shape == ShimmerShape.circle
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment(_animation.value, 0),
                    end: Alignment(_animation.value + 1, 0),
                    colors: [
                      widget.baseColor,
                      widget.highlightColor,
                      widget.baseColor,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                )
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    widget.borderRadius ?? 15.r,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment(_animation.value, 0),
                    end: Alignment(_animation.value + 1, 0),
                    colors: [
                      widget.baseColor,
                      widget.highlightColor,
                      widget.baseColor,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
        );
      },
    );
  }
}

/// Type of shimmer layout
enum ShimmerType {
  /// Single shimmer container
  single,

  /// List of shimmer containers
  list,

  /// Grid of shimmer containers
  grid,
}

/// Shape of shimmer container
enum ShimmerShape {
  /// Rectangle shape
  rectangle,

  /// Circle shape (for avatars, profile pictures)
  circle,
}
