import 'package:flutter/material.dart';

extension WidgetExtensions on Widget {
  // Padding
  Widget paddingAll(double padding) {
    return Padding(padding: EdgeInsets.all(padding), child: this);
  }

  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      child: this,
    );
  }

  Widget paddingOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
      ),
      child: this,
    );
  }

  // Margin (using Container)
  Widget marginAll(double margin) {
    return Container(margin: EdgeInsets.all(margin), child: this);
  }

  Widget marginSymmetric({double horizontal = 0, double vertical = 0}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      child: this,
    );
  }

  Widget marginOnly({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return Container(
      margin: EdgeInsets.only(
        left: left,
        top: top,
        right: right,
        bottom: bottom,
      ),
      child: this,
    );
  }

  // Center
  Widget center() {
    return Center(child: this);
  }

  // Align
  Widget align(Alignment alignment) {
    return Align(alignment: alignment, child: this);
  }

  // Expanded
  Widget expanded({int flex = 1}) {
    return Expanded(flex: flex, child: this);
  }

  // Flexible
  Widget flexible({int flex = 1, FlexFit fit = FlexFit.loose}) {
    return Flexible(flex: flex, fit: fit, child: this);
  }

  // Visibility
  Widget visible(bool visible) {
    return Visibility(visible: visible, child: this);
  }

  // Opacity
  Widget opacity(double opacity) {
    return Opacity(opacity: opacity, child: this);
  }

  // GestureDetector
  Widget onTap(VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: this);
  }

  // InkWell
  Widget inkWell({required VoidCallback onTap, BorderRadius? borderRadius}) {
    return InkWell(onTap: onTap, borderRadius: borderRadius, child: this);
  }

  // Card
  Widget card({
    Color? color,
    double elevation = 0,
    EdgeInsetsGeometry? margin,
    ShapeBorder? shape,
  }) {
    return Card(
      color: color,
      elevation: elevation,
      margin: margin,
      shape: shape,
      child: this,
    );
  }

  // Container decoration
  Widget decorated({
    Color? color,
    BorderRadius? borderRadius,
    Border? border,
    List<BoxShadow>? boxShadow,
    Gradient? gradient,
    BoxShape? shape,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius,
        border: border,
        boxShadow: boxShadow,
        gradient: gradient,
        shape: shape ?? BoxShape.rectangle,
      ),
      child: this,
    );
  }

  // SafeArea
  Widget safeArea({
    bool top = true,
    bool bottom = true,
    bool left = true,
    bool right = true,
  }) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: this,
    );
  }

  // Hero
  Widget hero(String tag) {
    return Hero(tag: tag, child: this);
  }

  // Tooltip
  Widget tooltip(String message) {
    return Tooltip(message: message, child: this);
  }

  // FittedBox
  Widget fitted({BoxFit fit = BoxFit.contain}) {
    return FittedBox(fit: fit, child: this);
  }

  // ClipRRect
  Widget clipRRect({required BorderRadius borderRadius}) {
    return ClipRRect(borderRadius: borderRadius, child: this);
  }

  // Rotate
  Widget rotate({required double angle}) {
    return Transform.rotate(angle: angle, child: this);
  }

  // Scale
  Widget scale({required double scale}) {
    return Transform.scale(scale: scale, child: this);
  }

  // Shimmer effect placeholder
  Widget shimmer({required bool isLoading, required Widget replacement}) {
    return isLoading ? replacement : this;
  }
}
