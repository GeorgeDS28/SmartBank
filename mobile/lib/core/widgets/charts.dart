import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:smartbank/core/theme/app_theme.dart';

class ChartSeries {
  final String label;
  final Color color;

  const ChartSeries({required this.label, required this.color});
}

/// One group of bars, e.g. a month with its inflow and outflow values.
class BarGroup {
  final String label;
  final List<double> values;

  const BarGroup({required this.label, required this.values});
}

/// Paired bars per group, used for monthly inflow versus outflow.
class GroupedBarChart extends StatelessWidget {
  final List<BarGroup> groups;
  final List<ChartSeries> series;

  const GroupedBarChart({
    super.key,
    required this.groups,
    required this.series,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChartLegend(series: series),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 220,
              child: CustomPaint(
                painter: _GroupedBarPainter(groups: groups, series: series),
                size: Size.infinite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupedBarPainter extends CustomPainter {
  final List<BarGroup> groups;
  final List<ChartSeries> series;

  const _GroupedBarPainter({required this.groups, required this.series});

  static const double _labelHeight = 26;

  @override
  void paint(Canvas canvas, Size size) {
    if (groups.isEmpty || series.isEmpty) return;

    final chartHeight = size.height - _labelHeight;
    final maxValue = groups.expand((g) => g.values).fold<double>(0, math.max);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    final groupWidth = size.width / groups.length;
    final barWidth = (groupWidth * 0.7) / series.length;
    final groupPadding = groupWidth * 0.15;

    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.10)
        ..strokeWidth = 1,
    );

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var g = 0; g < groups.length; g++) {
      final group = groups[g];

      for (var s = 0; s < series.length; s++) {
        final value = s < group.values.length ? group.values[s] : 0.0;
        final barHeight = (value / safeMax) * (chartHeight - 12);
        final left = g * groupWidth + groupPadding + s * barWidth;

        canvas.drawRRect(
          RRect.fromRectAndCorners(
            Rect.fromLTWH(
              left + 1,
              chartHeight - barHeight,
              barWidth - 2,
              barHeight,
            ),
            topLeft: const Radius.circular(4),
            topRight: const Radius.circular(4),
          ),
          Paint()
            ..color = value <= 0
                ? series[s].color.withValues(alpha: 0.15)
                : series[s].color,
        );
      }

      textPainter.text = TextSpan(
        text: group.label,
        style: const TextStyle(fontSize: 11, color: Colors.black54),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          g * groupWidth + groupWidth / 2 - textPainter.width / 2,
          chartHeight + 6,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_GroupedBarPainter old) =>
      old.groups != groups || old.series != series;
}

class ChartLegend extends StatelessWidget {
  final List<ChartSeries> series;

  const ChartLegend({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    final unique = <String, Color>{for (final s in series) s.label: s.color};

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final entry in unique.entries)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: entry.value,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(entry.key, style: const TextStyle(fontSize: 13)),
            ],
          ),
      ],
    );
  }
}

/// Donut chart for a small set of parts of a whole.
class DonutSlice {
  final String label;
  final double value;
  final Color color;

  const DonutSlice({
    required this.label,
    required this.value,
    required this.color,
  });
}

class DonutChart extends StatelessWidget {
  final List<DonutSlice> slices;
  final String centerLabel;
  final String centerValue;

  const DonutChart({
    super.key,
    required this.slices,
    required this.centerLabel,
    required this.centerValue,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ChartLegend(
              series: [
                for (final slice in slices)
                  ChartSeries(label: slice.label, color: slice.color),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(200, 200),
                    painter: _DonutPainter(slices: slices),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        centerValue,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        centerLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSlice> slices;

  const _DonutPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold<double>(0, (sum, s) => sum + s.value);
    if (total <= 0) {
      canvas.drawCircle(
        size.center(Offset.zero),
        size.width / 2 - 10,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..color = Colors.black.withValues(alpha: 0.08),
      );
      return;
    }

    final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    var startAngle = -math.pi / 2;

    for (final slice in slices) {
      if (slice.value <= 0) continue;
      final sweep = (slice.value / total) * math.pi * 2;

      canvas.drawArc(
        rect,
        startAngle,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 22
          ..strokeCap = StrokeCap.butt
          ..color = slice.color,
      );

      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => old.slices != slices;
}
