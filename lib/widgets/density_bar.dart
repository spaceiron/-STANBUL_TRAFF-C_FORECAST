import 'package:flutter/material.dart';

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
              flex: (score * 100).round(),
              child: Container(color: color),
            ),
            Flexible(
              flex: 100 - (score * 100).round(),
              child: Container(color: color.withOpacity(0.12)),
            ),
          ],
        ),
      ),
    );
  }
}
