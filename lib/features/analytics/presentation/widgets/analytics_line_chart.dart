import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/responsive_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_style.dart';
import '../../domain/entities/analytics_chart_point.dart';
import '../../domain/entities/analytics_metric_series.dart';

/// Draws one or more normalized analytics series with shared axis labels.
class AnalyticsLineChart extends StatelessWidget {
  const AnalyticsLineChart({
    super.key,
    required this.series,
    required this.axisLabels,
  });

  final List<AnalyticsMetricSeries> series;
  final List<String> axisLabels;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 160.h,
          width: double.infinity,
          child: CustomPaint(
            painter: _AnalyticsLineChartPainter(series: series),
            child: const SizedBox.expand(),
          ),
        ),
        SizedBox(height: 12.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: axisLabels.map((String label) {
              return Text(
                label,
                style: (context.textTheme.bodySmall ?? AppTextStyles.bodySmall)
                    .copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                      fontSize: 10.sp,
                    ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _AnalyticsLineChartPainter extends CustomPainter {
  _AnalyticsLineChartPainter({required this.series});

  final List<AnalyticsMetricSeries> series;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint axisPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    final Paint gridPaint = Paint()
      ..color = AppColors.borderLight
      ..strokeWidth = 1;

    final Rect chartRect = Rect.fromLTWH(
      12.w,
      4.h,
      size.width - 12.w,
      size.height - 8.h,
    );

    for (int index = 0; index < 3; index++) {
      final double dy = chartRect.top + (chartRect.height / 3) * index;
      _drawDashedLine(
        canvas,
        Offset(chartRect.left, dy),
        Offset(chartRect.right, dy),
        gridPaint,
      );
    }

    canvas.drawLine(
      Offset(chartRect.left, chartRect.top),
      Offset(chartRect.left, chartRect.bottom),
      axisPaint,
    );
    canvas.drawLine(
      Offset(chartRect.left, chartRect.bottom),
      Offset(chartRect.right, chartRect.bottom),
      axisPaint,
    );

    for (final AnalyticsMetricSeries item in series) {
      if (item.points.isEmpty) {
        continue;
      }
      final Color color = _colorFromKey(item.colorKey);
      final Paint linePaint = Paint()
        ..color = color
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final Paint pointPaint = Paint()
        ..color = AppColors.surface
        ..style = PaintingStyle.fill;
      final Paint pointBorderPaint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      final Path path = _createSmoothPath(item.points, chartRect);
      canvas.drawPath(path, linePaint);

      final Offset lastPoint = _toOffset(item.points.last, chartRect);
      canvas.drawCircle(lastPoint, 4.5, pointPaint);
      canvas.drawCircle(lastPoint, 4.5, pointBorderPaint);
    }
  }

  Path _createSmoothPath(List<AnalyticsChartPoint> points, Rect chartRect) {
    final Path path = Path();
    if (points.isEmpty) {
      return path;
    }

    final List<Offset> offsets = points
        .map((AnalyticsChartPoint point) => _toOffset(point, chartRect))
        .toList();

    path.moveTo(offsets.first.dx, offsets.first.dy);

    for (int index = 0; index < offsets.length - 1; index++) {
      final Offset current = offsets[index];
      final Offset next = offsets[index + 1];
      final double controlX = (current.dx + next.dx) / 2;

      path.cubicTo(controlX, current.dy, controlX, next.dy, next.dx, next.dy);
    }

    return path;
  }

  Offset _toOffset(AnalyticsChartPoint point, Rect chartRect) {
    return Offset(
      chartRect.left + (chartRect.width * point.x),
      chartRect.top + (chartRect.height * point.y),
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 6;
    const double dashGap = 6;
    double distance = 0;
    final double totalWidth = end.dx - start.dx;

    while (distance < totalWidth) {
      final double currentDashEnd = (distance + dashWidth)
          .clamp(0, totalWidth)
          .toDouble();
      canvas.drawLine(
        Offset(start.dx + distance, start.dy),
        Offset(start.dx + currentDashEnd, start.dy),
        paint,
      );
      distance += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _AnalyticsLineChartPainter oldDelegate) {
    return oldDelegate.series != series;
  }
}

Color _colorFromKey(String colorKey) {
  switch (colorKey) {
    case 'blue':
      return AppColors.accentBlue;
    case 'red':
      return AppColors.error;
    case 'green':
      return AppColors.primary;
    case 'yellow':
      return AppColors.accentYellow;
    default:
      return AppColors.textPrimary;
  }
}
