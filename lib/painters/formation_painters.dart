// lib/painters/formation_painters.dart
//
// Painter custom per la sezione formazione (heatmap, line chart, bar chart,
// minutes chart). Estratti da tactical_formation_widget.dart per ridurre
// la dimensione del file e migliorare la separazione di responsabilita'.
//
// // [FAV-extract-painters]

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class SofaScoreHeatmapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // BACKGROUND VERDE MEDIO
    final backgroundPaint = Paint()
      ..color = const Color(0xFF3D5A3C) // Verde campo medio
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, backgroundPaint);

    // LINEE NERE CON OPACITY
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Bordo esterno
    canvas.drawRect(rect, linePaint);

    // Linea centrale orizzontale
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      linePaint,
    );

    // Cerchio centrale
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      30,
      linePaint,
    );

    // FRECCIA GRANDE NERA IN ALTO
    _drawBigArrow(canvas, size);

    // HEAT POINTS GRANDI E SFOCATI
    final random = math.Random(42);
    final points = <_HeatPoint>[];

    // Genero 55 punti di calore
    for (int i = 0; i < 55; i++) {
      double x, y;

      // 65% punti concentrati al centro, 35% sparsi
      if (random.nextDouble() < 0.65) {
        x = size.width * (0.35 + random.nextDouble() * 0.3);
        y = size.height * (0.25 + random.nextDouble() * 0.45);
      } else {
        x = size.width * (0.15 + random.nextDouble() * 0.7);
        y = size.height * (0.15 + random.nextDouble() * 0.7);
      }

      final intensity = 0.45 + random.nextDouble() * 0.5;
      final radius = 50.0 + random.nextDouble() * 40.0; // 50-90px GRANDI!

      points.add(_HeatPoint(x, y, intensity, radius));
    }

    // Disegno i punti sfocati
    for (final point in points) {
      final startColor = point.intensity < 0.6
          ? const Color(0xFFFDD835) // Giallo
          : const Color(0xFFFF9800); // Arancione

      final heatGradient = RadialGradient(
        colors: [
          startColor.withOpacity(point.intensity * 0.9),
          startColor.withOpacity(point.intensity * 0.6),
          startColor.withOpacity(point.intensity * 0.3),
          startColor.withOpacity(0.0),
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      );

      final heatPaint = Paint()
        ..shader = heatGradient.createShader(
          Rect.fromCircle(
            center: Offset(point.x, point.y),
            radius: point.radius,
          ),
        )
        ..blendMode = BlendMode.screen
        ..maskFilter =
            const ui.MaskFilter.blur(ui.BlurStyle.normal, 8); // BLUR!

      canvas.drawCircle(Offset(point.x, point.y), point.radius, heatPaint);
    }
  }

  void _drawBigArrow(Canvas canvas, Size size) {
    final arrowPaint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final path = Path();

    // Freccia grande e ben visibile
    path.moveTo(centerX, 15); // Punta
    path.lineTo(centerX - 20, 45); // Sinistra
    path.lineTo(centerX - 8, 45); // Interno sinistra
    path.lineTo(centerX - 8, 70); // Gambo sinistra
    path.lineTo(centerX + 8, 70); // Gambo destra
    path.lineTo(centerX + 8, 45); // Interno destra
    path.lineTo(centerX + 20, 45); // Destra
    path.close();

    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _HeatPoint {
  final double x;
  final double y;
  final double intensity;
  final double radius;

  _HeatPoint(this.x, this.y, this.intensity, this.radius);
}

// CUSTOM PAINTERS PER GRAFICI PRESTAZIONI

// LINE CHART PAINTER (Rating Trend)
class LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final bool isDark;

  LineChartPainter({
    required this.values,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxValue = 10.0;
    final minValue = 5.0;
    final range = maxValue - minValue;

    // Padding per assi
    final leftPadding = 40.0;
    final bottomPadding = 30.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    // ASSE Y - Rating scale (5.0 - 10.0)
    final textStyle = TextStyle(
      color: isDark ? Colors.white70 : Colors.black54,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    for (int i = 0; i <= 5; i++) {
      final value = minValue + (range * i / 5);
      final y = chartHeight - (chartHeight * i / 5);

      // Grid line
      final gridPaint = Paint()
        ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.1)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        gridPaint,
      );

      // Y label
      final textSpan =
          TextSpan(text: value.toStringAsFixed(1), style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    // ASSE X - Match numbers (1-10)
    final stepX = chartWidth / (values.length - 1);
    for (int i = 0; i < values.length; i++) {
      final x = leftPadding + (i * stepX);

      // X label (ogni 2 match per non sovraffollare)
      if (i % 2 == 0 || i == values.length - 1) {
        final textSpan = TextSpan(
          text: '${i + 1}',
          style: textStyle.copyWith(fontSize: 10),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, chartHeight + 8),
        );
      }
    }

    // Line path con nuovo padding
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = leftPadding + (i * stepX);
      final normalizedValue = (values[i] - minValue) / range;
      final y = chartHeight - (normalizedValue * chartHeight);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, chartHeight);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, chartHeight);
    fillPath.close();

    // Gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(leftPadding, 0, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = isDark ? Colors.grey[850]! : Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final x = leftPadding + (i * stepX);
      final normalizedValue = (values[i] - minValue) / range;
      final y = chartHeight - (normalizedValue * chartHeight);

      canvas.drawCircle(Offset(x, y), 5, pointBorderPaint);
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// BAR CHART PAINTER (Goal + Assist)
class BarChartPainter extends CustomPainter {
  final List<int> goalsData;
  final List<int> assistsData;
  final bool isDark;

  BarChartPainter({
    required this.goalsData,
    required this.assistsData,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (goalsData.isEmpty || assistsData.isEmpty) return;

    final maxValue = [
      ...goalsData,
      ...assistsData,
    ].reduce((a, b) => a > b ? a : b).toDouble();

    if (maxValue == 0) return;

    // Padding per assi
    final leftPadding = 40.0;
    final bottomPadding = 30.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    final textStyle = TextStyle(
      color: isDark ? Colors.white70 : Colors.black54,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    // ASSE Y - Goal/Assist count
    final ySteps = maxValue > 4 ? 4 : maxValue.toInt();
    for (int i = 0; i <= ySteps; i++) {
      final value = (maxValue * i / ySteps).round();
      final y = chartHeight - (chartHeight * i / ySteps);

      // Grid line
      final gridPaint = Paint()
        ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.1)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        gridPaint,
      );

      // Y label
      final textSpan = TextSpan(text: value.toString(), style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }

    // ASSE X - Match numbers
    final barWidth = (chartWidth / goalsData.length) * 0.35;
    final spacing = chartWidth / goalsData.length;

    for (int i = 0; i < goalsData.length; i++) {
      final x = leftPadding + (i * spacing) + (spacing / 2);

      // X label (ogni 2 match)
      if (i % 2 == 0 || i == goalsData.length - 1) {
        final textSpan = TextSpan(
          text: '${i + 1}',
          style: textStyle.copyWith(fontSize: 10),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, chartHeight + 8),
        );
      }
    }

    // Draw bars con nuovo padding
    for (int i = 0; i < goalsData.length; i++) {
      final x = leftPadding + (i * spacing) + (spacing / 2);

      // Goals bar
      final goalsHeight = (goalsData[i] / maxValue) * chartHeight * 0.95;
      final goalsRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
            x - barWidth, chartHeight - goalsHeight, barWidth, goalsHeight),
        const Radius.circular(4),
      );
      final goalsPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF00C853), Color(0xFF00E676)],
        ).createShader(goalsRect.outerRect);
      canvas.drawRRect(goalsRect, goalsPaint);

      // Assists bar
      final assistsHeight = (assistsData[i] / maxValue) * chartHeight * 0.95;
      final assistsRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chartHeight - assistsHeight, barWidth, assistsHeight),
        const Radius.circular(4),
      );
      final assistsPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
        ).createShader(assistsRect.outerRect);
      canvas.drawRRect(assistsRect, assistsPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// MINUTES CHART PAINTER
class MinutesChartPainter extends CustomPainter {
  final List<int> minutes;
  final Color color;
  final bool isDark;

  MinutesChartPainter({
    required this.minutes,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (minutes.isEmpty) return;

    final maxMinutes = 90.0;

    // Padding per assi
    final leftPadding = 40.0;
    final bottomPadding = 30.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    final textStyle = TextStyle(
      color: isDark ? Colors.white70 : Colors.black54,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    // ASSE Y - Minuti (0, 30, 60, 90)
    for (int i = 0; i <= 3; i++) {
      final value = i * 30;
      final y = chartHeight - (chartHeight * i / 3);

      // Grid line
      final gridPaint = Paint()
        ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.1)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        gridPaint,
      );

      // Y label
      final textSpan = TextSpan(text: value.toString(), style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }

    // Linea 90 min (full match) - evidenziata
    final fullMatchPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(leftPadding, chartHeight * 0.02),
      Offset(size.width, chartHeight * 0.02),
      fullMatchPaint,
    );

    // ASSE X - Match numbers
    final barWidth = chartWidth / minutes.length;
    for (int i = 0; i < minutes.length; i++) {
      final x = leftPadding + (i * barWidth) + (barWidth / 2);

      // X label (ogni 2 match)
      if (i % 2 == 0 || i == minutes.length - 1) {
        final textSpan = TextSpan(
          text: '${i + 1}',
          style: textStyle.copyWith(fontSize: 10),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, chartHeight + 8),
        );
      }
    }

    // Draw bars con nuovo padding
    for (int i = 0; i < minutes.length; i++) {
      final x = leftPadding + (i * barWidth);
      final barHeight = (minutes[i] / maxMinutes) * chartHeight * 0.95;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x + barWidth * 0.15,
          chartHeight - barHeight,
          barWidth * 0.7,
          barHeight,
        ),
        const Radius.circular(4),
      );

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withOpacity(0.7)],
        ).createShader(rect.outerRect);

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
