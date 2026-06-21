// lib/painters/player_detail_painters.dart
//
// CustomPainters della schermata player_detail_screen.dart, estratti per
// ridurre la dimensione del file e migliorare la separazione di responsabilita'.
//
// // [FAV-extract-player-detail-painters]

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/player_detail.dart';

class HeatmapPainter extends CustomPainter {
  final List<Offset> positions;
  final bool isDark;

  HeatmapPainter({required this.positions, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw field
    final fieldPaint = Paint()
      ..color = const Color(0xFF3B7544)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fieldPaint);

    // Draw field lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Outer border
    canvas.drawRect(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      linePaint,
    );

    // Center line
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      linePaint,
    );

    // Center circle
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.08,
      linePaint,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      2,
      Paint()..color = Colors.white.withOpacity(0.5),
    );

    // Penalty areas
    final penaltyWidth = size.width * 0.14;
    final penaltyHeight = size.height * 0.35;
    canvas.drawRect(
      Rect.fromLTWH(
          2, (size.height - penaltyHeight) / 2, penaltyWidth, penaltyHeight),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - penaltyWidth - 2,
          (size.height - penaltyHeight) / 2, penaltyWidth, penaltyHeight),
      linePaint,
    );

    // 6-yard boxes
    final sixYardWidth = size.width * 0.06;
    final sixYardHeight = size.height * 0.18;
    canvas.drawRect(
      Rect.fromLTWH(
          2, (size.height - sixYardHeight) / 2, sixYardWidth, sixYardHeight),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - sixYardWidth - 2,
          (size.height - sixYardHeight) / 2, sixYardWidth, sixYardHeight),
      linePaint,
    );

    // Goal areas (dark rectangles)
    final goalPaint = Paint()..color = const Color(0xFF2B5A34);
    final goalWidth = 4.0;
    final goalHeight = size.height * 0.12;
    canvas.drawRect(
      Rect.fromLTWH(0, (size.height - goalHeight) / 2, goalWidth, goalHeight),
      goalPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - goalWidth, (size.height - goalHeight) / 2,
          goalWidth, goalHeight),
      goalPaint,
    );

    // Create heatmap grid
    final gridSize = 28;
    final cellWidth = size.width / gridSize;
    final cellHeight = size.height / gridSize;
    final heatGrid = List.generate(gridSize, (_) => List.filled(gridSize, 0));

    // Count positions
    for (final pos in positions) {
      final x = (pos.dx * gridSize).floor().clamp(0, gridSize - 1);
      final y = (pos.dy * gridSize).floor().clamp(0, gridSize - 1);
      heatGrid[x][y]++;
    }

    // Find max count
    int maxCount = 1;
    for (final row in heatGrid) {
      for (final count in row) {
        if (count > maxCount) maxCount = count;
      }
    }

    // Draw heatmap with blur
    for (int x = 0; x < gridSize; x++) {
      for (int y = 0; y < gridSize; y++) {
        final count = heatGrid[x][y];
        if (count > 0) {
          final intensity = count / maxCount;
          final color = _getHeatColor(intensity);

          final rect = Rect.fromLTWH(
            x * cellWidth,
            y * cellHeight,
            cellWidth,
            cellHeight,
          );

          final heatPaint = Paint()
            ..color = color
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

          canvas.drawRect(rect, heatPaint);
        }
      }
    }
  }

  Color _getHeatColor(double intensity) {
    // Gradiente giallo-arancione come screenshot
    if (intensity < 0.2) return const Color(0xFF4CAF50).withOpacity(0.2);
    if (intensity < 0.4) return const Color(0xFFCDDC39).withOpacity(0.4);
    if (intensity < 0.6) return const Color(0xFFFFEB3B).withOpacity(0.6);
    if (intensity < 0.8) return const Color(0xFFFF9800).withOpacity(0.75);
    return const Color(0xFFFF5722).withOpacity(0.85);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PassMapPainter extends CustomPainter {
  final List<PassData> passes;
  final bool isDark;

  PassMapPainter({required this.passes, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw field (same as heatmap)
    final fieldPaint = Paint()
      ..color = const Color(0xFF3B7544)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fieldPaint);

    // Draw field lines
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRect(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      linePaint,
    );

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.08,
      linePaint,
    );

    // Penalty areas
    final penaltyWidth = size.width * 0.14;
    final penaltyHeight = size.height * 0.35;
    canvas.drawRect(
      Rect.fromLTWH(
          2, (size.height - penaltyHeight) / 2, penaltyWidth, penaltyHeight),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - penaltyWidth - 2,
          (size.height - penaltyHeight) / 2, penaltyWidth, penaltyHeight),
      linePaint,
    );

    // Draw passes
    for (final pass in passes) {
      final from =
          Offset(pass.from.dx * size.width, pass.from.dy * size.height);
      final to = Offset(pass.to.dx * size.width, pass.to.dy * size.height);

      final passPaint = Paint()
        ..color = pass.isAccurate
            ? const Color(0xFF4CAF50).withOpacity(0.8)
            : const Color(0xFFE53935).withOpacity(0.7)
        ..strokeWidth = pass.isAccurate ? 2 : 1.5
        ..style = PaintingStyle.stroke;

      // Draw arrow line
      canvas.drawLine(from, to, passPaint);

      // Draw arrowhead
      final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
      final arrowSize = 7.0;
      final path = Path()
        ..moveTo(to.dx, to.dy)
        ..lineTo(
          to.dx - arrowSize * math.cos(angle - math.pi / 6),
          to.dy - arrowSize * math.sin(angle - math.pi / 6),
        )
        ..moveTo(to.dx, to.dy)
        ..lineTo(
          to.dx - arrowSize * math.cos(angle + math.pi / 6),
          to.dy - arrowSize * math.sin(angle + math.pi / 6),
        );
      canvas.drawPath(path, passPaint);

      // Draw endpoint dot
      canvas.drawCircle(
          to,
          3.5,
          Paint()
            ..color = pass.isAccurate
                ? const Color(0xFF4CAF50)
                : const Color(0xFFE53935));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
// PARTE 2 - Da appendere dopo la PARTE 1
// Questo codice va DOPO l'ultima riga della PARTE 1

class RadarChartPainter extends CustomPainter {
  final Map<String, double> skills;
  final Color color;

  RadarChartPainter({
    required this.skills,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 40;
    final skillNames = skills.keys.toList();
    final skillValues = skills.values.toList();
    final angleStep = (2 * math.pi) / skillNames.length;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 5; i++) {
      final levelRadius = radius * (i / 5);
      final path = Path();

      for (int j = 0; j < skillNames.length; j++) {
        final angle = j * angleStep - math.pi / 2;
        final x = center.dx + levelRadius * math.cos(angle);
        final y = center.dy + levelRadius * math.sin(angle);

        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (int i = 0; i < skillNames.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);
    }

    final skillPath = Path();
    for (int i = 0; i < skillNames.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final value = skillValues[i] / 100;
      final x = center.dx + radius * value * math.cos(angle);
      final y = center.dy + radius * value * math.sin(angle);

      if (i == 0) {
        skillPath.moveTo(x, y);
      } else {
        skillPath.lineTo(x, y);
      }
    }
    skillPath.close();

    final fillPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(skillPath, fillPaint);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(skillPath, strokePaint);

    for (int i = 0; i < skillNames.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final value = skillValues[i] / 100;
      final x = center.dx + radius * value * math.cos(angle);
      final y = center.dy + radius * value * math.sin(angle);

      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }

    final textStyle = TextStyle(
      color: Colors.grey[700],
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    for (int i = 0; i < skillNames.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final labelRadius = radius + 25;
      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);

      final textSpan = TextSpan(
        text: skillNames[i],
        style: textStyle,
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// COMPARISON DIALOG

class ComparisonRadarChartPainter extends CustomPainter {
  final Map<String, double> skills1;
  final Map<String, double> skills2;
  final Color color1;
  final Color color2;

  ComparisonRadarChartPainter({
    required this.skills1,
    required this.skills2,
    required this.color1,
    required this.color2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 40;
    final skillNames = skills1.keys.toList();
    final angleStep = (2 * math.pi) / skillNames.length;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 5; i++) {
      final levelRadius = radius * (i / 5);
      final path = Path();

      for (int j = 0; j < skillNames.length; j++) {
        final angle = j * angleStep - math.pi / 2;
        final x = center.dx + levelRadius * math.cos(angle);
        final y = center.dy + levelRadius * math.sin(angle);

        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    for (int i = 0; i < skillNames.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);
    }

    _drawSkillArea(canvas, center, radius, skills1.values.toList(),
        skillNames.length, angleStep, color1);

    _drawSkillArea(canvas, center, radius, skills2.values.toList(),
        skillNames.length, angleStep, color2);

    final textStyle = TextStyle(
      color: Colors.grey[700],
      fontSize: 11,
      fontWeight: FontWeight.bold,
    );

    for (int i = 0; i < skillNames.length; i++) {
      final angle = i * angleStep - math.pi / 2;
      final labelRadius = radius + 25;
      final x = center.dx + labelRadius * math.cos(angle);
      final y = center.dy + labelRadius * math.sin(angle);

      final textSpan = TextSpan(text: skillNames[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  void _drawSkillArea(Canvas canvas, Offset center, double radius,
      List<double> values, int count, double angleStep, Color color) {
    final path = Path();

    for (int i = 0; i < count; i++) {
      final angle = i * angleStep - math.pi / 2;
      final value = values[i] / 100;
      final x = center.dx + radius * value * math.cos(angle);
      final y = center.dy + radius * value * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final fillPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, strokePaint);

    for (int i = 0; i < count; i++) {
      final angle = i * angleStep - math.pi / 2;
      final value = values[i] / 100;
      final x = center.dx + radius * value * math.cos(angle);
      final y = center.dy + radius * value * math.sin(angle);

      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
