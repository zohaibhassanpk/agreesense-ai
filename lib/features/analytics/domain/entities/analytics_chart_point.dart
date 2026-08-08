class AnalyticsChartPoint {
  const AnalyticsChartPoint({
    required this.x,
    required this.y,
    this.breakBefore = false,
  });

  final double x;
  final double y;

  /// Starts a new visible line segment before this point.
  ///
  /// Calendar-month charts use this for months separated by missing data, so
  /// the painter does not imply readings existed throughout the gap.
  final bool breakBefore;
}
