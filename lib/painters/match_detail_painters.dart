// lib/painters/match_detail_painters.dart
//
// Painter e classi-modello estratti da match_detail_screen.dart.
// Tutti pubblici (senza underscore) per essere accessibili dal monolite.
// Includono painter per formazioni, heatmap, donut, momentum, mini-heatmap.
//
// // [FAV-extract-painters]

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'advanced_stats_painters.dart';

class FormationPitchPainter extends CustomPainter {
  final bool isDark;
  FormationPitchPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Green field with subtle stripes
    const stripeCount = 12;
    final stripeH = h / stripeCount;
    for (int i = 0; i < stripeCount; i++) {
      final shade =
          i.isEven ? const Color(0xFF2D6B30) : const Color(0xFF327535);
      canvas.drawRect(Rect.fromLTWH(0, i * stripeH, w, stripeH + 0.5),
          Paint()..color = shade);
    }

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.50)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.50);

    // Margins — generous for visual breathing room
    final mx = w * 0.08;
    final my = h * 0.05;
    final fL = mx;
    final fT = my;
    final fW = w - mx * 2;
    final fH = h - my * 2;
    final cX = w / 2;
    final cY = fT + fH / 2;

    // Outline
    canvas.drawRect(Rect.fromLTWH(fL, fT, fW, fH), linePaint);

    // Center line
    canvas.drawLine(Offset(fL, cY), Offset(fL + fW, cY), linePaint);

    // Center circle — visually prominent
    final cR = fH * 0.14;
    canvas.drawCircle(Offset(cX, cY), cR, linePaint);
    canvas.drawCircle(Offset(cX, cY), 2, dotPaint);

    // Penalty area: width = 44% of fW, depth = 13.5% of fH (visually balanced)
    final paW = fW * 0.44;
    final paH = fH * 0.135;
    final paL = fL + (fW - paW) / 2;
    canvas.drawRect(Rect.fromLTWH(paL, fT + fH - paH, paW, paH), linePaint);
    canvas.drawRect(Rect.fromLTWH(paL, fT, paW, paH), linePaint);

    // Goal area: width = 20% of fW, depth = 4.5% of fH
    final gaW = fW * 0.20;
    final gaH = fH * 0.045;
    final gaL = fL + (fW - gaW) / 2;
    canvas.drawRect(Rect.fromLTWH(gaL, fT + fH - gaH, gaW, gaH), linePaint);
    canvas.drawRect(Rect.fromLTWH(gaL, fT, gaW, gaH), linePaint);

    // Penalty spot: 9% of fH from goal line
    final psD = fH * 0.09;
    final psBot = fT + fH - psD;
    final psTop = fT + psD;
    canvas.drawCircle(Offset(cX, psBot), 2, dotPaint);
    canvas.drawCircle(Offset(cX, psTop), 2, dotPaint);

    // Penalty arc — same radius as center circle
    final parc = fH * 0.14;
    // Bottom
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(fL, fT + fH - paH - parc, fW, parc));
    canvas.drawCircle(Offset(cX, psBot), parc, linePaint);
    canvas.restore();
    // Top
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(fL, fT + paH, fW, parc));
    canvas.drawCircle(Offset(cX, psTop), parc, linePaint);
    canvas.restore();

    // Corner arcs
    final coR = fH * 0.012;
    if (coR > 2) {
      canvas.drawArc(Rect.fromLTWH(fL - coR, fT - coR, coR * 2, coR * 2), 0,
          math.pi / 2, false, linePaint);
      canvas.drawArc(Rect.fromLTWH(fL + fW - coR, fT - coR, coR * 2, coR * 2),
          math.pi / 2, math.pi / 2, false, linePaint);
      canvas.drawArc(Rect.fromLTWH(fL - coR, fT + fH - coR, coR * 2, coR * 2),
          -math.pi / 2, math.pi / 2, false, linePaint);
      canvas.drawArc(
          Rect.fromLTWH(fL + fW - coR, fT + fH - coR, coR * 2, coR * 2),
          math.pi,
          math.pi / 2,
          false,
          linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PassFieldLinePainter extends CustomPainter {
  final bool isDark;
  PassFieldLinePainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final lineColor = isDark
        ? Colors.white.withOpacity(0.35)
        : Colors.white.withOpacity(0.55);
    final lp = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Bordo esterno (leggermente arrotondato agli angoli)
    final outerRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
        const Radius.circular(2));
    canvas.drawRRect(outerRect, lp);

    // Linea mediana
    final midX = size.width / 2;
    canvas.drawLine(Offset(midX, 0), Offset(midX, size.height), lp);

    // Cerchio centrocampo
    canvas.drawCircle(Offset(midX, size.height / 2), size.width * 0.075, lp);
    // Punto centrale
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(midX, size.height / 2), 2.5, dotPaint);

    // Divisione terzi (tratteggiata)
    final thirdW = size.width / 3;
    final dashPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.white).withOpacity(0.2)
      ..strokeWidth = 1;
    _drawDashedLine(canvas, Offset(thirdW, 0), Offset(thirdW, size.height),
        dashPaint, 6, 4);
    _drawDashedLine(canvas, Offset(thirdW * 2, 0),
        Offset(thirdW * 2, size.height), dashPaint, 6, 4);

    // Aree di rigore
    final areaH = size.height * 0.55;
    final areaW = size.width * 0.12;
    final areaTop = (size.height - areaH) / 2;
    canvas.drawRect(Rect.fromLTWH(0, areaTop, areaW, areaH), lp);
    canvas.drawRect(
        Rect.fromLTWH(size.width - areaW, areaTop, areaW, areaH), lp);

    // Aree piccole
    final smallH = size.height * 0.28;
    final smallW = size.width * 0.045;
    final smallTop = (size.height - smallH) / 2;
    canvas.drawRect(Rect.fromLTWH(0, smallTop, smallW, smallH), lp);
    canvas.drawRect(
        Rect.fromLTWH(size.width - smallW, smallTop, smallW, smallH), lp);

    // Punti di rigore
    final penaltyX = size.width * 0.09;
    canvas.drawCircle(Offset(penaltyX, size.height / 2), 2, dotPaint);
    canvas.drawCircle(
        Offset(size.width - penaltyX, size.height / 2), 2, dotPaint);

    // Semi-archi area di rigore (clippati fuori dall'area)
    final arcR = size.width * 0.055;
    // Arco sinistro — solo la parte a destra dell'area
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(areaW, 0, size.width - areaW, size.height));
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(penaltyX, size.height / 2),
          width: arcR * 2,
          height: arcR * 2),
      -math.pi / 2,
      math.pi,
      false,
      lp,
    );
    canvas.restore();
    // Arco destro — solo la parte a sinistra dell'area
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width - areaW, size.height));
    canvas.drawArc(
      Rect.fromCenter(
          center: Offset(size.width - penaltyX, size.height / 2),
          width: arcR * 2,
          height: arcR * 2),
      math.pi / 2,
      math.pi,
      false,
      lp,
    );
    canvas.restore();
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint,
      double dashLen, double gapLen) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    final unitDx = dx / distance;
    final unitDy = dy / distance;
    double drawn = 0;
    bool drawing = true;
    while (drawn < distance) {
      final len = drawing ? dashLen : gapLen;
      final segEnd = math.min(drawn + len, distance);
      if (drawing) {
        canvas.drawLine(
          Offset(start.dx + unitDx * drawn, start.dy + unitDy * drawn),
          Offset(start.dx + unitDx * segEnd, start.dy + unitDy * segEnd),
          paint,
        );
      }
      drawn = segEnd;
      drawing = !drawing;
    }
  }

  @override
  bool shouldRepaint(covariant PassFieldLinePainter oldDelegate) =>
      isDark != oldDelegate.isDark;
}

class DonutSegment {
  final double value;
  final Color color;
  DonutSegment({required this.value, required this.color});
}

class DonutChartPainter extends CustomPainter {
  final List<DonutSegment> segments;
  final double strokeWidth;
  final bool isDark;

  DonutChartPainter(
      {required this.segments, this.strokeWidth = 14, this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final total = segments.fold(0.0, (sum, s) => sum + s.value);

    // Track background
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = (isDark ? Colors.white : Colors.grey).withOpacity(0.08)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth);

    double startAngle = -math.pi / 2; // 12 o'clock
    const gapAngle = 0.04; // piccolo gap tra segmenti

    for (final seg in segments) {
      final sweepAngle = (seg.value / total) * (2 * math.pi) - gapAngle;
      final arcPaint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + gapAngle / 2,
        sweepAngle,
        false,
        arcPaint,
      );
      startAngle += sweepAngle + gapAngle;
    }
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter old) => true;
}

class HeatSource {
  final double x, y, value, weight;
  const HeatSource(this.x, this.y, this.value, this.weight);
}

class CombinedHeatmapPainter extends CustomPainter {
  final List<int> homeZones;
  final List<int> awayZones;
  final int gridCols;
  final int gridRows;
  final bool isDark;
  final double animationValue;

  CombinedHeatmapPainter({
    required this.homeZones,
    required this.awayZones,
    this.gridCols = 4,
    this.gridRows = 5,
    this.isDark = false,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    RealisticSoccerFieldPainter(isDark: isDark).paint(canvas, size);

    final total = gridCols * gridRows;
    final combinedZones = List<int>.generate(
        total,
        (i) =>
            (i < homeZones.length ? homeZones[i] : 0) +
            (i < awayZones.length ? awayZones[i] : 0));

    paintHeatmap(
        canvas, size, combinedZones, gridCols, gridRows, animationValue,
        opacity: 0.72);

    RealisticSoccerFieldPainter(isDark: isDark, linesOnly: true)
        .paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant CombinedHeatmapPainter old) =>
      animationValue != old.animationValue;
}

class SingleTeamHeatmapPainter extends CustomPainter {
  final List<int> zones;
  final int gridCols;
  final int gridRows;
  final bool isHome;
  final bool isDark;
  final double animationValue;
  final int globalRefMax;

  SingleTeamHeatmapPainter({
    required this.zones,
    this.gridCols = 4,
    this.gridRows = 5,
    required this.isHome,
    this.isDark = false,
    this.animationValue = 1.0,
    this.globalRefMax = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    RealisticSoccerFieldPainter(isDark: isDark).paint(canvas, size);

    paintHeatmap(canvas, size, zones, gridCols, gridRows, animationValue,
        opacity: 0.78, refMax: globalRefMax > 0 ? globalRefMax : null);

    RealisticSoccerFieldPainter(isDark: isDark, linesOnly: true)
        .paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant SingleTeamHeatmapPainter old) =>
      animationValue != old.animationValue || zones != old.zones;
}

class AttackStat {
  final String label;
  final int homeVal, awayVal;
  final bool higherIsBetter;
  const AttackStat(
      this.label, this.homeVal, this.awayVal, this.higherIsBetter);
}

class AttackHeatmapPainter extends CustomPainter {
  final List<List<double>> zones; // 2 rows x 3 cols for selected team
  final bool isHome;
  final bool isDark;

  AttackHeatmapPainter(
      {required this.zones, required this.isHome, required this.isDark});

  // SofaScore-style: subtle green levels, solid colors
  // Light sage background → medium green for high concentration
  Color _zoneColor(double t) {
    t = t.clamp(0.0, 1.0);
    if (t < 0.20) return const Color(0xFFDCEDC8); // very light sage
    if (t < 0.40) return const Color(0xFFC5E1A5); // light lime-green
    if (t < 0.55) return const Color(0xFFA5D6A7); // medium-light
    if (t < 0.70) return const Color(0xFF81C784); // medium green
    return const Color(0xFF66BB6A); // bright medium green (NOT dark)
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Draw 6 solid zones — sharp edges, no blending
    final cellW = w / 3;
    final cellH = h / 2;

    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 3; col++) {
        final intensity = zones[row][col].clamp(0.0, 1.0);
        final color = _zoneColor(intensity);
        canvas.drawRect(
          Rect.fromLTWH(col * cellW, row * cellH, cellW + 1.0, cellH + 1.0),
          Paint()..color = color,
        );
      }
    }

    // Field markings
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.65)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Outline
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), linePaint);
    // Center line
    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), linePaint);
    // Center circle
    canvas.drawCircle(Offset(w / 2, h / 2), h * 0.18, linePaint);
    // Center dot
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.65);
    canvas.drawCircle(Offset(w / 2, h / 2), 3, dotPaint);

    // Penalty boxes
    final penW = w * 0.16;
    final penH = h * 0.55;
    final penTop = (h - penH) / 2;
    canvas.drawRect(Rect.fromLTWH(0, penTop, penW, penH), linePaint);
    canvas.drawRect(Rect.fromLTWH(w - penW, penTop, penW, penH), linePaint);

    // Small boxes (porta)
    final sW = w * 0.06;
    final sH = h * 0.3;
    final sTop = (h - sH) / 2;
    canvas.drawRect(Rect.fromLTWH(0, sTop, sW, sH), linePaint);
    canvas.drawRect(Rect.fromLTWH(w - sW, sTop, sW, sH), linePaint);

    // Penalty dots
    canvas.drawCircle(Offset(penW * 0.75, h / 2), 2.5, dotPaint);
    canvas.drawCircle(Offset(w - penW * 0.75, h / 2), 2.5, dotPaint);

    // Mezzelune (penalty arcs)
    final arcRadius = h * 0.12;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(penW, penTop, arcRadius * 2, penH));
    canvas.drawCircle(Offset(penW * 0.75, h / 2), arcRadius, linePaint);
    canvas.restore();
    canvas.save();
    canvas.clipRect(
        Rect.fromLTWH(w - penW - arcRadius * 2, penTop, arcRadius * 2, penH));
    canvas.drawCircle(Offset(w - penW * 0.75, h / 2), arcRadius, linePaint);
    canvas.restore();

    // Direction arrows
    final arrowPaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isHome) {
      _drawArrow(canvas, arrowPaint, Offset(w * 0.38, h * 0.28),
          Offset(w * 0.78, h * 0.28));
      _drawArrow(canvas, arrowPaint, Offset(w * 0.42, h * 0.72),
          Offset(w * 0.75, h * 0.72));
    } else {
      _drawArrow(canvas, arrowPaint, Offset(w * 0.62, h * 0.28),
          Offset(w * 0.22, h * 0.28));
      _drawArrow(canvas, arrowPaint, Offset(w * 0.58, h * 0.72),
          Offset(w * 0.25, h * 0.72));
    }
  }

  void _drawArrow(Canvas canvas, Paint paint, Offset from, Offset to) {
    canvas.drawLine(from, to, paint);
    final dx = to.dx - from.dx;
    final sign = dx > 0 ? -1.0 : 1.0;
    final tipSize = 12.0;
    canvas.drawLine(
        to, Offset(to.dx + sign * tipSize, to.dy - tipSize * 0.5), paint);
    canvas.drawLine(
        to, Offset(to.dx + sign * tipSize, to.dy + tipSize * 0.5), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class StatItem {
  final String label;
  final int home;
  final int away;
  const StatItem(this.label, this.home, this.away);
}

class PossessionBarPainter extends CustomPainter {
  final double homePercent;
  final Color homeColor;
  final Color awayColor;
  final bool isDark;

  PossessionBarPainter({
    required this.homePercent,
    required this.homeColor,
    required this.awayColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    final barHeight = 8.0;
    final barY = (h - barHeight) / 2;
    final radius = Radius.circular(barHeight / 2);
    final gap = 3.0;
    final splitX = w * homePercent;

    // Home bar
    final homePaint = Paint()
      ..shader = LinearGradient(
        colors: [homeColor.withOpacity(0.6), homeColor],
      ).createShader(Rect.fromLTWH(0, barY, splitX - gap / 2, barHeight));

    final homeRect = RRect.fromLTRBR(
      0, barY, splitX - gap / 2, barY + barHeight, radius,
    );
    canvas.drawRRect(homeRect, homePaint);

    // Home glow
    if (homePercent > 0.5) {
      final glowPaint = Paint()
        ..color = homeColor.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(homeRect, glowPaint);
    }

    // Away bar
    final awayPaint = Paint()
      ..shader = LinearGradient(
        colors: [awayColor, awayColor.withOpacity(0.6)],
      ).createShader(Rect.fromLTWH(splitX + gap / 2, barY, w - splitX - gap / 2, barHeight));

    final awayRect = RRect.fromLTRBR(
      splitX + gap / 2, barY, w, barY + barHeight, radius,
    );
    canvas.drawRRect(awayRect, awayPaint);

    // Away glow
    if (homePercent < 0.5) {
      final glowPaint = Paint()
        ..color = awayColor.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawRRect(awayRect, glowPaint);
    }

    // Center divider dot
    final dotPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3);
    canvas.drawCircle(Offset(splitX, h / 2), 2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant PossessionBarPainter oldDelegate) {
    return oldDelegate.homePercent != homePercent;
  }
}

class MomentumGridPainter extends CustomPainter {
  final bool isDark;
  final Color dividerColor;

  MomentumGridPainter({required this.isDark, required this.dividerColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dividerColor
      ..strokeWidth = 0.5;

    // Center line (stronger)
    final centerPaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.12) : Colors.grey.withOpacity(0.18)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      centerPaint,
    );

    // Subtle horizontal grid lines at 25% and 75%
    canvas.drawLine(Offset(0, size.height * 0.25), Offset(size.width, size.height * 0.25), paint);
    canvas.drawLine(Offset(0, size.height * 0.75), Offset(size.width, size.height * 0.75), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MomentumCurvePainter extends CustomPainter {
  final List<List<dynamic>> data;
  final Color homeColor;
  final Color awayColor;
  final bool isDark;

  MomentumCurvePainter({
    required this.data,
    required this.homeColor,
    required this.awayColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final w = size.width;
    final h = size.height;
    final midY = h / 2;
    final segWidth = w / data.length;
    final maxBarH = midY - 4;

    // Build home and away paths
    final homePath = Path();
    final awayPath = Path();
    final homeStrokePath = Path();
    final awayStrokePath = Path();

    homePath.moveTo(0, midY);
    awayPath.moveTo(0, midY);
    homeStrokePath.moveTo(0, midY);
    awayStrokePath.moveTo(0, midY);

    for (int i = 0; i < data.length; i++) {
      final x = segWidth * i + segWidth / 2;
      final isHome = data[i][1] as bool;
      final intensity = (data[i][2] as double).clamp(0.0, 1.0);
      final barH = intensity * maxBarH;

      if (isHome) {
        final y = midY - barH;
        if (i == 0 || !(data[i - 1][1] as bool)) {
          homePath.lineTo(x - segWidth / 2, midY);
          homeStrokePath.lineTo(x - segWidth / 2, midY);
        }
        homePath.lineTo(x, y);
        homeStrokePath.lineTo(x, y);

        // Away stays at center
        awayPath.lineTo(x, midY);
        awayStrokePath.lineTo(x, midY);
      } else {
        final y = midY + barH;
        if (i == 0 || (data[i - 1][1] as bool)) {
          awayPath.lineTo(x - segWidth / 2, midY);
          awayStrokePath.lineTo(x - segWidth / 2, midY);
        }
        awayPath.lineTo(x, y);
        awayStrokePath.lineTo(x, y);

        // Home stays at center
        homePath.lineTo(x, midY);
        homeStrokePath.lineTo(x, midY);
      }
    }

    // Close paths for fill
    homePath.lineTo(w, midY);
    awayPath.lineTo(w, midY);
    homeStrokePath.lineTo(w, midY);
    awayStrokePath.lineTo(w, midY);

    homePath.lineTo(w, midY);
    homePath.lineTo(0, midY);
    homePath.close();

    awayPath.lineTo(w, midY);
    awayPath.lineTo(0, midY);
    awayPath.close();

    // Draw home fill with gradient
    final homeFillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, midY),
        [homeColor.withOpacity(0.45), homeColor.withOpacity(0.05)],
      );
    canvas.drawPath(homePath, homeFillPaint);

    // Draw away fill with gradient
    final awayFillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, midY),
        Offset(0, h),
        [awayColor.withOpacity(0.05), awayColor.withOpacity(0.45)],
      );
    canvas.drawPath(awayPath, awayFillPaint);

    // Draw home stroke
    final homeStrokePaint = Paint()
      ..color = homeColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(homeStrokePath, homeStrokePaint);

    // Draw away stroke
    final awayStrokePaint = Paint()
      ..color = awayColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(awayStrokePath, awayStrokePaint);

    // Home glow
    final homeGlowPaint = Paint()
      ..color = homeColor.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(homeStrokePath, homeGlowPaint);

    // Away glow
    final awayGlowPaint = Paint()
      ..color = awayColor.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawPath(awayStrokePath, awayGlowPaint);
  }

  @override
  bool shouldRepaint(covariant MomentumCurvePainter oldDelegate) {
    return oldDelegate.data != data;
  }
}

class MiniHeatmapPainter extends CustomPainter {
  final String position;
  final Color teamColor;

  MiniHeatmapPainter({required this.position, required this.teamColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Campo
    final fieldPaint = Paint()..color = Colors.white.withOpacity(0.15)..style = PaintingStyle.stroke..strokeWidth = 0.5;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fieldPaint);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), fieldPaint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.height * 0.2, fieldPaint);

    // Hotspot basato su posizione
    double cx, cy;
    switch (position) {
      case 'GK': cx = 0.08; cy = 0.5; break;
      case 'CB': cx = 0.2; cy = 0.5; break;
      case 'LB': cx = 0.22; cy = 0.2; break;
      case 'RB': cx = 0.22; cy = 0.8; break;
      case 'DM': cx = 0.35; cy = 0.5; break;
      case 'CM': cx = 0.45; cy = 0.5; break;
      case 'AM': cx = 0.6; cy = 0.5; break;
      case 'LW': cx = 0.7; cy = 0.15; break;
      case 'RW': cx = 0.7; cy = 0.85; break;
      case 'CF': cx = 0.75; cy = 0.5; break;
      case 'ST': cx = 0.82; cy = 0.5; break;
      default: cx = 0.5; cy = 0.5;
    }

    // Gradient radiale
    final center = Offset(size.width * cx, size.height * cy);
    final radius = size.width * 0.3;
    final gradient = RadialGradient(
      center: Alignment(cx * 2 - 1, cy * 2 - 1),
      radius: 0.5,
      colors: [teamColor.withOpacity(0.6), teamColor.withOpacity(0.15), Colors.transparent],
      stops: const [0.0, 0.5, 1.0],
    );
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawCircle(center, radius, paint);

    // Punto centrale
    final dotPaint = Paint()..color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(center, 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PreMatchFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Grass stripes first (background)
    final stripePaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.fill;
    final stripeH = h / 14;
    for (int i = 0; i < 14; i += 2) {
      canvas.drawRect(Rect.fromLTWH(0, i * stripeH, w, stripeH), stripePaint);
    }

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Field border
    final margin = 4.0;
    final fieldRect = Rect.fromLTWH(margin, margin, w - margin * 2, h - margin * 2);
    canvas.drawRect(fieldRect, paint);

    final fw = fieldRect.width;
    final fh = fieldRect.height;
    final fl = fieldRect.left;
    final ft = fieldRect.top;

    // Center line
    canvas.drawLine(Offset(fl, ft + fh / 2), Offset(fl + fw, ft + fh / 2), paint);

    // Center circle - proportional to field width
    final centerR = fw * 0.07;
    canvas.drawCircle(Offset(fl + fw / 2, ft + fh / 2), centerR, paint);

    // Center dot
    canvas.drawCircle(Offset(fl + fw / 2, ft + fh / 2), 3, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;

    // Penalty areas
    final paW = fw * 0.62;
    final paH = fh * 0.20;

    // Top penalty area
    canvas.drawRect(Rect.fromLTWH(fl + (fw - paW) / 2, ft, paW, paH), paint);

    // Goal area
    final gaW = fw * 0.34;
    final gaH = fh * 0.065;
    canvas.drawRect(Rect.fromLTWH(fl + (fw - gaW) / 2, ft, gaW, gaH), paint);

    // Top penalty arc - attached to penalty area
    final arcR = fw * 0.055;
    final topArcRect = Rect.fromCenter(center: Offset(fl + fw / 2, ft + paH), width: arcR * 2, height: arcR * 2);
    // Only draw the part outside the penalty area
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(fl, ft + paH, fw, arcR));
    canvas.drawOval(topArcRect, paint);
    canvas.restore();

    // Bottom penalty area
    canvas.drawRect(Rect.fromLTWH(fl + (fw - paW) / 2, ft + fh - paH, paW, paH), paint);

    // Bottom goal area
    canvas.drawRect(Rect.fromLTWH(fl + (fw - gaW) / 2, ft + fh - gaH, gaW, gaH), paint);

    // Bottom penalty arc - attached to penalty area
    final botArcRect = Rect.fromCenter(center: Offset(fl + fw / 2, ft + fh - paH), width: arcR * 2, height: arcR * 2);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(fl, ft + fh - paH - arcR, fw, arcR));
    canvas.drawOval(botArcRect, paint);
    canvas.restore();

    // Penalty spots
    canvas.drawCircle(Offset(fl + fw / 2, ft + paH * 0.72), 2.5, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(fl + fw / 2, ft + fh - paH * 0.72), 2.5, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;

    // Corner arcs
    final cR = 8.0;
    canvas.drawArc(Rect.fromLTWH(fl - cR, ft - cR, cR * 2, cR * 2), 0, 1.5708, false, paint);
    canvas.drawArc(Rect.fromLTWH(fl + fw - cR, ft - cR, cR * 2, cR * 2), 1.5708, 1.5708, false, paint);
    canvas.drawArc(Rect.fromLTWH(fl - cR, ft + fh - cR, cR * 2, cR * 2), 4.7124, 1.5708, false, paint);
    canvas.drawArc(Rect.fromLTWH(fl + fw - cR, ft + fh - cR, cR * 2, cR * 2), 3.1416, 1.5708, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// // [FAV-painters-fix] Funzioni helper di rendering heatmap,
// spostate qui da match_detail_screen.dart.
// Sono pubbliche (senza underscore) per essere accessibili
// dai painter di questo file.

Color thermalColor(double t) {
  // ── Palette PRO stile SofaScore ──
  // Zone fredde: TRASPARENTE (campo verde si vede al 100%)
  // Zone calde: giallo → arancio → rosso (no verde, già nel campo)
  if (t < 0.30) return const Color(0x00FFFFFF); // trasparente puro
  if (t < 0.45) {
    // Trasparente → giallo (fade-in graduale)
    final ratio = (t - 0.30) / 0.15;
    return Color.lerp(
        const Color(0x00FFEE58), const Color(0xFFFFEE58), ratio)!;
  } else if (t < 0.58) {
    // Giallo → giallo-arancio
    return Color.lerp(
        const Color(0xFFFFEE58), const Color(0xFFFFB300), (t - 0.45) / 0.13)!;
  } else if (t < 0.70) {
    // Giallo-arancio → arancio pieno
    return Color.lerp(
        const Color(0xFFFFB300), const Color(0xFFFF9800), (t - 0.58) / 0.12)!;
  } else if (t < 0.82) {
    // Arancio → rosso-arancio
    return Color.lerp(
        const Color(0xFFFF9800), const Color(0xFFFF5722), (t - 0.70) / 0.12)!;
  } else if (t < 0.92) {
    // Rosso-arancio → rosso
    return Color.lerp(
        const Color(0xFFFF5722), const Color(0xFFF44336), (t - 0.82) / 0.10)!;
  } else {
    // Rosso → rosso vivo (solo picchi estremi)
    return Color.lerp(
        const Color(0xFFF44336), const Color(0xFFE53935), (t - 0.92) / 0.08)!;
  }
}

double sCurve(double x) {
  return 1.0 / (1.0 + math.exp(-8.0 * (x - 0.50)));
}

List<HeatSource> generateSubSources(
  List<int> zones,
  int srcCols,
  int srcRows,
  double normMax,
) {
  final sources = <HeatSource>[];
  final seed = zones.fold(0, (s, v) => s + v);
  int hash = seed;
  double nextRandom() {
    hash = (hash * 1103515245 + 12345) & 0x7fffffff;
    return (hash % 10000) / 10000.0;
  }

  for (int r = 0; r < srcRows; r++) {
    for (int c = 0; c < srcCols; c++) {
      final idx = r * srcCols + c;
      if (idx >= zones.length) break;
      final baseVal = (zones[idx] / normMax).clamp(0.0, 1.0);
      final cx = (c + 0.5) / srcCols;
      final cy = (r + 0.5) / srcRows;
      final cellW = 1.0 / srcCols;
      final cellH = 1.0 / srcRows;

      // Centro principale
      sources.add(HeatSource(cx, cy, baseVal, 1.0));

      // 4 sub-sorgenti jitter
      for (int s = 0; s < 4; s++) {
        final jx = cx + (nextRandom() - 0.5) * cellW * 0.7;
        final jy = cy + (nextRandom() - 0.5) * cellH * 0.7;
        final jv = (baseVal * (0.85 + nextRandom() * 0.30)).clamp(0.0, 1.0);
        sources
            .add(HeatSource(jx.clamp(0.0, 1.0), jy.clamp(0.0, 1.0), jv, 0.6));
      }
    }
  }
  return sources;
}

List<List<double>> interpolateHeatGridV4(
    List<int> zones, int srcCols, int srcRows, int outCols, int outRows,
    {int? refMax}) {
  final localMax = zones.reduce((a, b) => a > b ? a : b).toDouble();
  if (localMax <= 0) {
    return List.generate(outRows, (_) => List.filled(outCols, 0.0));
  }
  final normMax = (refMax ?? localMax).toDouble();

  final sources = generateSubSources(zones, srcCols, srcRows, normMax);

  // Sigma largo per base liscia, stretto per picchi
  const sigmaWide = 0.30;
  const sigmaNarrow = 0.12;
  final inv2sW = 1.0 / (2.0 * sigmaWide * sigmaWide);
  final inv2sN = 1.0 / (2.0 * sigmaNarrow * sigmaNarrow);

  final grid = List.generate(outRows, (_) => List.filled(outCols, 0.0));

  for (int row = 0; row < outRows; row++) {
    final py = (row + 0.5) / outRows;
    for (int col = 0; col < outCols; col++) {
      final px = (col + 0.5) / outCols;

      double wSumW = 0.0, vSumW = 0.0;
      double wSumN = 0.0, vSumN = 0.0;

      for (final src in sources) {
        final dx = px - src.x;
        final dy = py - src.y;
        final d2 = dx * dx + dy * dy;

        final wW = math.exp(-d2 * inv2sW) * src.weight;
        wSumW += wW;
        vSumW += wW * src.value;

        final wN = math.exp(-d2 * inv2sN) * src.weight;
        wSumN += wN;
        vSumN += wN * src.value;
      }

      final valWide = wSumW > 0 ? vSumW / wSumW : 0.0;
      final valNarrow = wSumN > 0 ? vSumN / wSumN : 0.0;

      // Mix: 50/50 wide e narrow
      final mixed = (valWide * 0.50 + valNarrow * 0.50).clamp(0.0, 1.0);

      // Edge falloff
      double edgeFade = 1.0;
      if (px < 0.04) edgeFade *= px / 0.04;
      if (px > 0.96) edgeFade *= (1.0 - px) / 0.04;
      if (py < 0.03) edgeFade *= py / 0.03;
      if (py > 0.97) edgeFade *= (1.0 - py) / 0.03;

      grid[row][col] = (mixed * edgeFade).clamp(0.0, 1.0);
    }
  }
  return grid;
}

void paintHeatmap(Canvas canvas, Size size, List<int> zones, int srcCols,
    int srcRows, double animVal,
    {double opacity = 0.55, int? refMax}) {
  if (zones.isEmpty) return;

  const outCols = 64;
  const outRows = 42;

  final grid = interpolateHeatGridV4(zones, srcCols, srcRows, outCols, outRows,
      refMax: refMax);

  final cellW = size.width / outCols;
  final cellH = size.height / outRows;

  // ═══ CLIP: tutto il rendering heatmap resta dentro il campo ═══
  canvas.save();
  canvas.clipRRect(RRect.fromRectAndRadius(
    Rect.fromLTWH(0, 0, size.width, size.height),
    const Radius.circular(4),
  ));

  // ── Pass 1: blur stretto per dettaglio ──
  canvas.saveLayer(
    Rect.fromLTWH(0, 0, size.width, size.height),
    Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
  );

  for (int row = 0; row < outRows; row++) {
    for (int col = 0; col < outCols; col++) {
      final val = grid[row][col] * animVal;
      if (val < 0.30) continue;  // soglia PRO: solo zone medio-calde disegnate

      final color = thermalColor(val);
      final contrast = sCurve(val);
      final alpha = (contrast * opacity).clamp(0.0, 0.85);

      canvas.drawRect(
        Rect.fromLTWH(col * cellW, row * cellH, cellW + 1.0, cellH + 1.0),
        Paint()..color = color.withOpacity(alpha),
      );
    }
  }

  canvas.restore(); // blur 1

  // ── Pass 2: blur largo per fusione morbida ──
  canvas.saveLayer(
    Rect.fromLTWH(0, 0, size.width, size.height),
    Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
  );

  for (int row = 0; row < outRows; row += 2) {
    for (int col = 0; col < outCols; col += 2) {
      final val = grid[row][col] * animVal;
      if (val < 0.40) continue;  // soglia PRO pass 2: solo zone calde

      final color = thermalColor(val);
      final alpha = (sCurve(val) * opacity * 0.30).clamp(0.0, 0.30);

      canvas.drawRect(
        Rect.fromLTWH(
            col * cellW, row * cellH, cellW * 2 + 1.0, cellH * 2 + 1.0),
        Paint()..color = color.withOpacity(alpha),
      );
    }
  }

  canvas.restore(); // blur 2
  canvas.restore(); // clip
}
