// lib/pages/player_finished_match_internals.dart
//
// Classi interne (modelli + painters) di player_finished_match_screen.dart,
// estratte per ridurre la dimensione del file.
//
// // [FAV-extract-pfm-internals]

import 'package:flutter/material.dart';
import 'dart:math' as math;

class PMPassData {
  final Offset from;
  final Offset to;
  final bool isAccurate;
  PMPassData({required this.from, required this.to, required this.isAccurate});
}

class PMShotData {
  final Offset position;
  final bool onTarget;
  final bool isGoal;
  PMShotData(
      {required this.position, required this.onTarget, required this.isGoal});
}

class PMDribbleData {
  final Offset from;
  final Offset to;
  final bool successful;
  PMDribbleData(
      {required this.from, required this.to, required this.successful});
}

enum PMDefenseType { tackle, interception, clearance }

class PMDefenseData {
  final Offset position;
  final PMDefenseType type;
  final bool successful;
  PMDefenseData(
      {required this.position, required this.type, required this.successful});
}

// HEATMAP PAINTER (mantieni invariato - TUTTO IL TUO CODICE)

class CompleteFieldHeatmapPainter extends CustomPainter {
  final List<Offset> positions;
  final bool isDark;

  CompleteFieldHeatmapPainter({required this.positions, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    _drawField(canvas, size);
    _drawHeatmap(canvas, size);
  }

  void _drawField(Canvas canvas, Size size) {
    final fieldPaint = Paint()..color = const Color(0xFFB8E6B8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fieldPaint);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final margin = 8.0;

    canvas.drawRect(
      Rect.fromLTWH(
          margin, margin, size.width - margin * 2, size.height - margin * 2),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width / 2, margin),
      Offset(size.width / 2, size.height - margin),
      linePaint,
    );

    final centerCircleRadius = size.width * 0.0915;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      centerCircleRadius,
      linePaint,
    );

    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      3.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    final penaltyWidth = size.width * 0.165;
    final penaltyHeight = size.height * 0.42;
    final penaltyY = (size.height - penaltyHeight) / 2;

    canvas.drawRect(
      Rect.fromLTWH(margin, penaltyY, penaltyWidth, penaltyHeight),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - margin - penaltyWidth, penaltyY, penaltyWidth,
          penaltyHeight),
      linePaint,
    );

    final penaltySpotDist = size.width * 0.11;
    final leftPenaltyX = margin + penaltySpotDist;
    final rightPenaltyX = size.width - margin - penaltySpotDist;
    final penaltySpotY = size.height / 2;
    final arcRadius = size.width * 0.0915;

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(leftPenaltyX, penaltySpotY),
        radius: arcRadius,
      ),
      -0.9273,
      1.8546,
      false,
      linePaint,
    );

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(rightPenaltyX, penaltySpotY),
        radius: arcRadius,
      ),
      math.pi - 0.9273,
      1.8546,
      false,
      linePaint,
    );

    canvas.drawCircle(
      Offset(leftPenaltyX, penaltySpotY),
      3.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(rightPenaltyX, penaltySpotY),
      3.5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    final sixYardWidth = size.width * 0.055;
    final sixYardHeight = size.height * 0.19;
    final sixYardY = (size.height - sixYardHeight) / 2;

    canvas.drawRect(
      Rect.fromLTWH(margin, sixYardY, sixYardWidth, sixYardHeight),
      linePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - margin - sixYardWidth, sixYardY, sixYardWidth,
          sixYardHeight),
      linePaint,
    );

    final goalPaint = Paint()..color = const Color(0xFF2E7D32);
    final goalWidth = 5.0;
    final goalHeight = size.height * 0.13;
    final goalY = (size.height - goalHeight) / 2;

    canvas.drawRect(
      Rect.fromLTWH(0, goalY, goalWidth, goalHeight),
      goalPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - goalWidth, goalY, goalWidth, goalHeight),
      goalPaint,
    );

    final cornerRadius = size.width * 0.010;

    canvas.drawArc(
      Rect.fromLTWH(
        margin - cornerRadius,
        margin - cornerRadius,
        cornerRadius * 2,
        cornerRadius * 2,
      ),
      0,
      math.pi / 2,
      false,
      linePaint,
    );

    canvas.drawArc(
      Rect.fromLTWH(
        size.width - margin - cornerRadius,
        margin - cornerRadius,
        cornerRadius * 2,
        cornerRadius * 2,
      ),
      math.pi / 2,
      math.pi / 2,
      false,
      linePaint,
    );

    canvas.drawArc(
      Rect.fromLTWH(
        margin - cornerRadius,
        size.height - margin - cornerRadius,
        cornerRadius * 2,
        cornerRadius * 2,
      ),
      -math.pi / 2,
      math.pi / 2,
      false,
      linePaint,
    );

    canvas.drawArc(
      Rect.fromLTWH(
        size.width - margin - cornerRadius,
        size.height - margin - cornerRadius,
        cornerRadius * 2,
        cornerRadius * 2,
      ),
      math.pi,
      math.pi / 2,
      false,
      linePaint,
    );
  }

  void _drawHeatmap(Canvas canvas, Size size) {
    const resolution = 90;
    final densityMap = List.generate(
      resolution,
      (_) => List.filled(resolution, 0.0),
    );

    for (int py = 0; py < resolution; py++) {
      for (int px = 0; px < resolution; px++) {
        final x = px / resolution;
        final y = py / resolution;
        double density = 0.0;

        for (final pos in positions) {
          final dx = x - pos.dx;
          final dy = y - pos.dy;
          final distSq = dx * dx + dy * dy;

          final sigma = 0.028;
          density += math.exp(-distSq / (2 * sigma * sigma));
        }

        densityMap[py][px] = density;
      }
    }

    double maxDensity = 0;
    for (final row in densityMap) {
      for (final d in row) {
        if (d > maxDensity) maxDensity = d;
      }
    }

    for (int py = 0; py < resolution; py++) {
      for (int px = 0; px < resolution; px++) {
        final density = densityMap[py][px] / maxDensity;

        if (density < 0.70) continue;

        final centerX = (px + 0.5) / resolution * size.width;
        final centerY = (py + 0.5) / resolution * size.height;
        final center = Offset(centerX, centerY);

        final pixelSize = size.width / resolution * 1.1;

        Color color;
        double opacity;

        if (density >= 0.95) {
          color = const Color(0xFFE53935);
          opacity = 0.96;
        } else if (density >= 0.88) {
          final t = (density - 0.88) / 0.07;
          color = Color.lerp(
            const Color(0xFFFF5722),
            const Color(0xFFE53935),
            t,
          )!;
          opacity = 0.78 + t * 0.18;
        } else if (density >= 0.80) {
          final t = (density - 0.80) / 0.08;
          color = Color.lerp(
            const Color(0xFFFF9800),
            const Color(0xFFFF5722),
            t,
          )!;
          opacity = 0.65 + t * 0.13;
        } else {
          final t = (density - 0.70) / 0.10;
          color = Color.lerp(
            const Color(0xFFFFEB3B),
            const Color(0xFFFF9800),
            t,
          )!;
          opacity = 0.52 + t * 0.13;
        }

        final paint = Paint()
          ..color = color.withOpacity(opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

        canvas.drawCircle(center, pixelSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ANIMATED STATS MAP PAINTER (mantieni invariato - TUTTO IL TUO CODICE CON REPLAY)

class AnimatedStatsMapPainter extends CustomPainter {
  final String type;
  final dynamic data;
  final bool isDark;
  final int replayIndex;
  final Animation<double> animation;
  final dynamic selectedEvent;

  AnimatedStatsMapPainter({
    required this.type,
    required this.data,
    required this.isDark,
    required this.replayIndex,
    required this.animation,
    this.selectedEvent,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    _drawField(canvas, size);

    if (data is List && data.isNotEmpty) {
      final events = data as List;

      switch (type) {
        case 'Shot':
          _drawShots(canvas, size, events.cast<PMShotData>());
          break;
        case 'Pass':
          _drawPasses(canvas, size, events.cast<PMPassData>());
          break;
        case 'Drib':
          _drawDribbles(canvas, size, events.cast<PMDribbleData>());
          break;
        case 'Def':
          _drawDefensiveActions(canvas, size, events.cast<PMDefenseData>());
          break;
      }
    }
  }

  void _drawField(Canvas canvas, Size size) {
    final fieldGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF2E7D32),
        const Color(0xFF388E3C),
        const Color(0xFF2E7D32)
      ],
    );
    final fieldPaint = Paint()
      ..shader = fieldGradient
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fieldPaint);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(
        Rect.fromLTWH(4, 4, size.width - 8, size.height - 8), linePaint);
    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height), linePaint);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width * 0.1, linePaint);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 2,
        Paint()..color = Colors.white);

    final penaltyWidth = size.width * 0.16;
    final penaltyHeight = size.height * 0.4;
    canvas.drawRect(
        Rect.fromLTWH(
            4, (size.height - penaltyHeight) / 2, penaltyWidth, penaltyHeight),
        linePaint);
    canvas.drawRect(
        Rect.fromLTWH(size.width - penaltyWidth - 4,
            (size.height - penaltyHeight) / 2, penaltyWidth, penaltyHeight),
        linePaint);

    final sixYardWidth = size.width * 0.06;
    final sixYardHeight = size.height * 0.18;
    canvas.drawRect(
        Rect.fromLTWH(
            4, (size.height - sixYardHeight) / 2, sixYardWidth, sixYardHeight),
        linePaint);
    canvas.drawRect(
        Rect.fromLTWH(size.width - sixYardWidth - 4,
            (size.height - sixYardHeight) / 2, sixYardWidth, sixYardHeight),
        linePaint);

    final goalPaint = Paint()..color = const Color(0xFF1B5E20);
    final goalWidth = 4.0;
    final goalHeight = size.height * 0.12;
    canvas.drawRect(
        Rect.fromLTWH(0, (size.height - goalHeight) / 2, goalWidth, goalHeight),
        goalPaint);
    canvas.drawRect(
        Rect.fromLTWH(size.width - goalWidth, (size.height - goalHeight) / 2,
            goalWidth, goalHeight),
        goalPaint);
  }

  void _drawShots(Canvas canvas, Size size, List<PMShotData> shots) {
    print('🎨 PAINTER: Drawing ${shots.length} shots');
    for (int i = 0; i < shots.length; i++) {
      final shot = shots[i];
      final color =
          shot.isGoal ? 'VERDE' : (shot.onTarget ? 'GIALLO' : 'ROSSO');
      print(
          '   Shot #$i: isGoal=${shot.isGoal}, onTarget=${shot.onTarget} → Color: $color');
    }

    for (int i = 0; i < shots.length; i++) {
      final shot = shots[i];

      double opacity = 1.0;
      if (replayIndex >= 0) {
        if (i < replayIndex) {
          opacity = 0.3;
        } else if (i == replayIndex) {
          opacity = animation.value;
        } else {
          opacity = 0.0;
        }
      }

      if (opacity == 0.0) continue;

      final pos =
          Offset(shot.position.dx * size.width, shot.position.dy * size.height);

      late Offset targetPoint;

      if (shot.onTarget || shot.isGoal) {
        final goalY = size.height / 2;
        targetPoint = Offset(size.width - 10, goalY);
      } else {
        final goalCenterY = size.height / 2;
        final goalHeight = size.height * 0.12;
        final goalTop = goalCenterY - goalHeight / 2;
        final goalBottom = goalCenterY + goalHeight / 2;

        final isHighShot = pos.dy < goalCenterY;
        final isWideShot = (pos.dy - goalCenterY).abs() > goalHeight;

        if (isWideShot) {
          if (pos.dy < goalCenterY) {
            targetPoint = Offset(size.width - 5, goalTop - 20);
          } else {
            targetPoint = Offset(size.width - 5, goalBottom + 20);
          }
        } else if (isHighShot) {
          targetPoint = Offset(size.width - 8, goalTop - 15);
        } else {
          targetPoint = Offset(size.width - 8, goalBottom + 15);
        }
      }

      final linePaint = Paint()
        ..color = (shot.isGoal
                ? const Color(0xFF4CAF50)
                : (shot.onTarget
                    ? const Color(0xFFFFEB3B)
                    : const Color(0xFFE53935)))
            .withOpacity(0.7 * opacity)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      canvas.drawLine(pos, targetPoint, linePaint);

      final shotPaint = Paint()
        ..color = (shot.isGoal
                ? const Color(0xFF4CAF50)
                : (shot.onTarget
                    ? const Color(0xFFFFEB3B)
                    : const Color(0xFFE53935)))
            .withOpacity(opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, shot.isGoal ? 10 : 8, shotPaint);
      canvas.drawCircle(
          pos,
          shot.isGoal ? 10 : 8,
          Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);

      if (shot.isGoal) {
        final textStyle = TextStyle(
            color: Colors.white.withOpacity(opacity),
            fontSize: 16,
            fontWeight: FontWeight.bold);
        final textSpan = TextSpan(text: '⚽', style: textStyle);
        final textPainter =
            TextPainter(text: textSpan, textDirection: TextDirection.ltr);
        textPainter.layout();
        textPainter.paint(canvas, Offset(pos.dx - 8, pos.dy - 8));
      }
    }
  }

  void _drawPasses(Canvas canvas, Size size, List<PMPassData> passes) {
    for (int i = 0; i < passes.length; i++) {
      final pass = passes[i];

      double opacity = 1.0;
      if (replayIndex >= 0) {
        if (i < replayIndex) {
          opacity = 0.3;
        } else if (i == replayIndex) {
          opacity = animation.value;
        } else {
          opacity = 0.0;
        }
      }

      if (opacity == 0.0) continue;

      final from =
          Offset(pass.from.dx * size.width, pass.from.dy * size.height);
      final to = Offset(pass.to.dx * size.width, pass.to.dy * size.height);
      final passPaint = Paint()
        ..color = (pass.isAccurate
                ? const Color(0xFF4CAF50)
                : const Color(0xFFE53935))
            .withOpacity(0.7 * opacity)
        ..strokeWidth = pass.isAccurate ? 2.5 : 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(from, to, passPaint);

      final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
      final arrowSize = 8.0;
      final path = Path()
        ..moveTo(to.dx, to.dy)
        ..lineTo(to.dx - arrowSize * math.cos(angle - math.pi / 6),
            to.dy - arrowSize * math.sin(angle - math.pi / 6))
        ..moveTo(to.dx, to.dy)
        ..lineTo(to.dx - arrowSize * math.cos(angle + math.pi / 6),
            to.dy - arrowSize * math.sin(angle + math.pi / 6));
      canvas.drawPath(path, passPaint);

      canvas.drawCircle(
          to,
          4,
          Paint()
            ..color = (pass.isAccurate
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFE53935))
                .withOpacity(opacity));
    }
  }

  void _drawDribbles(Canvas canvas, Size size, List<PMDribbleData> dribbles) {
    for (int i = 0; i < dribbles.length; i++) {
      final dribble = dribbles[i];

      double opacity = 1.0;
      if (replayIndex >= 0) {
        if (i < replayIndex) {
          opacity = 0.3;
        } else if (i == replayIndex) {
          opacity = animation.value;
        } else {
          opacity = 0.0;
        }
      }

      if (opacity == 0.0) continue;

      final from =
          Offset(dribble.from.dx * size.width, dribble.from.dy * size.height);
      final to =
          Offset(dribble.to.dx * size.width, dribble.to.dy * size.height);
      final dribblePaint = Paint()
        ..color = (dribble.successful
                ? const Color(0xFF9C27B0)
                : const Color(0xFFFF9800))
            .withOpacity(0.7 * opacity)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(from.dx, from.dy);
      final steps = 8;
      for (int j = 0; j <= steps; j++) {
        final t = j / steps;
        final x = from.dx + (to.dx - from.dx) * t;
        final y =
            from.dy + (to.dy - from.dy) * t + math.sin(t * math.pi * 3) * 10;
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, dribblePaint);

      canvas.drawCircle(from, 6,
          Paint()..color = const Color(0xFF9C27B0).withOpacity(opacity));
      canvas.drawCircle(
          from,
          6,
          Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
      canvas.drawCircle(
          to,
          6,
          Paint()
            ..color = (dribble.successful
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFFF5722))
                .withOpacity(opacity));
      canvas.drawCircle(
          to,
          6,
          Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  void _drawDefensiveActions(
      Canvas canvas, Size size, List<PMDefenseData> actions) {
    for (int i = 0; i < actions.length; i++) {
      final action = actions[i];

      double opacity = 1.0;
      if (replayIndex >= 0) {
        if (i < replayIndex) {
          opacity = 0.3;
        } else if (i == replayIndex) {
          opacity = animation.value;
        } else {
          opacity = 0.0;
        }
      }

      if (opacity == 0.0) continue;

      final pos = Offset(
          action.position.dx * size.width, action.position.dy * size.height);
      Color color;
      String label;
      switch (action.type) {
        case PMDefenseType.tackle:
          color = const Color(0xFF2196F3);
          label = 'T';
          break;
        case PMDefenseType.interception:
          color = const Color(0xFF4CAF50);
          label = 'I';
          break;
        case PMDefenseType.clearance:
          color = const Color(0xFFFF9800);
          label = 'C';
          break;
      }

      canvas.drawCircle(
          pos,
          16,
          Paint()
            ..color =
                color.withOpacity((action.successful ? 0.3 : 0.15) * opacity)
            ..style = PaintingStyle.fill);
      canvas.drawCircle(
          pos,
          12,
          Paint()
            ..color = color.withOpacity(opacity)
            ..style = PaintingStyle.fill);
      canvas.drawCircle(
          pos,
          12,
          Paint()
            ..color = Colors.white.withOpacity(opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = action.successful ? 3 : 2);

      final textStyle = TextStyle(
          color: Colors.white.withOpacity(opacity),
          fontSize: 10,
          fontWeight: FontWeight.bold);
      final textSpan = TextSpan(text: label, style: textStyle);
      final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center);
      textPainter.layout();
      textPainter.paint(
          canvas,
          Offset(
              pos.dx - textPainter.width / 2, pos.dy - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant AnimatedStatsMapPainter oldDelegate) {
    return oldDelegate.replayIndex != replayIndex ||
        oldDelegate.animation != animation ||
        oldDelegate.selectedEvent != selectedEvent;
  }
}
