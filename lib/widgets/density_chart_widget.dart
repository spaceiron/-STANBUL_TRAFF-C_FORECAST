// lib/widgets/density_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class DensityChartWidget extends StatelessWidget {
  final PredictionResult prediction;
  final double height;

  const DensityChartWidget({
    super.key,
    required this.prediction,
    this.height = 160,
  });

  Color _barColor(double score) {
    if (score < 0.33) return const Color(0xFF10B981);
    if (score < 0.66) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  List<BarChartGroupData> _buildBars() {
    final points = [
      (0, prediction.densityScore),
      if (prediction.forecast.isNotEmpty)
        (prediction.forecast[0].minutesAhead,
            prediction.forecast[0].densityScore),
      if (prediction.forecast.length > 1)
        (prediction.forecast[1].minutesAhead,
            prediction.forecast[1].densityScore),
    ];

    return List.generate(points.length, (i) {
      final score = points[i].$2;
      final color = _barColor(score);
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY:          score,
            color:        color,
            width:        28,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            backDrawRodData: BackgroundBarChartRodData(
              show:  true,
              toY:   1.0,
              color: color.withOpacity(0.08),
            ),
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white54 : Colors.black38;

    final timeLabels = ['Şimdi'];
    for (final f in prediction.forecast) {
      timeLabels.add('+${f.minutesAhead} dk');
    }

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY:      1.0,
          minY:      0.0,
          barGroups: _buildBars(),
          gridData: FlGridData(
            show:               true,
            drawVerticalLine:   false,
            horizontalInterval: 0.33,
            getDrawingHorizontalLine: (_) => FlLine(
              color:       labelColor.withOpacity(0.3),
              strokeWidth: 0.8,
              dashArray:   [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:   true,
                interval:     0.33,
                reservedSize: 36,
                getTitlesWidget: (value, _) {
                  final label = switch (value) {
                    0.0  => 'Boş',
                    0.33 => 'Orta',
                    0.66 => 'Dolu',
                    _    => '',
                  };
                  return Text(label,
                      style: TextStyle(fontSize: 10, color: labelColor));
                },
              ),
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles:   true,
                reservedSize: 28,
                getTitlesWidget: (value, _) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= timeLabels.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(timeLabels[idx],
                        style:
                            TextStyle(fontSize: 11, color: labelColor)),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final pct = (rod.toY * 100).round();
                return BarTooltipItem(
                  '%$pct',
                  TextStyle(
                    color:      _barColor(rod.toY),
                    fontWeight: FontWeight.bold,
                    fontSize:   13,
                  ),
                );
              },
            ),
          ),
        ),
        duration: const Duration(milliseconds: 400),
        curve:    Curves.easeOutCubic,
      ),
    );
  }
}

class DensityMiniIndicator extends StatelessWidget {
  final double score;
  final String label;
  final double size;

  const DensityMiniIndicator({
    super.key,
    required this.score,
    required this.label,
    this.size = 56,
  });

  Color get _color {
    if (score < 0.33) return const Color(0xFF10B981);
    if (score < 0.66) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width:  size,
          height: size,
          child: Stack(
            fit: StackFit.expand,
            children: [
              CircularProgressIndicator(
                value:           score,
                strokeWidth:     5,
                backgroundColor: _color.withOpacity(0.12),
                valueColor:      AlwaysStoppedAnimation(_color),
              ),
              Center(
                child: Text(
                  '${(score * 100).round()}%',
                  style: TextStyle(
                    fontSize:   size * 0.22,
                    fontWeight: FontWeight.bold,
                    color:      _color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize:   11,
            color:      _color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class DensityGradientBar extends StatelessWidget {
  final double score;
  final double height;
  final BorderRadius? borderRadius;

  const DensityGradientBar({
    super.key,
    required this.score,
    this.height = 6,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final color = score < 0.33
        ? const Color(0xFF10B981)
        : score < 0.66
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(3),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Flexible(
              flex:  (score * 100).round(),
              child: Container(color: color),
            ),
            Flexible(
              flex:  100 - (score * 100).round(),
              child: Container(color: color.withOpacity(0.12)),
            ),
          ],
        ),
      ),
    );
  }
}
