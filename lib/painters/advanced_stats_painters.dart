// PAINTERS PROFESSIONALI PER STATISTICHE AVANZATE
// lib/painters/advanced_stats_painters.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

// ========================================
// CAMPO DA CALCIO REALISTICO MIGLIORATO
// ========================================
class RealisticSoccerFieldPainter extends CustomPainter {
  final bool isDark;
  final bool linesOnly;

  RealisticSoccerFieldPainter({required this.isDark, this.linesOnly = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (!linesOnly) {
      _drawEnhancedGrassPattern(canvas, size);
    }
    _drawDetailedFieldLines(canvas, size);
    if (!linesOnly) {
      _drawFieldDepth(canvas, size);
    }
  }

  void _drawEnhancedGrassPattern(Canvas canvas, Size size) {
    // ── Palette unificata Avanzate (= Mappa Tiri) ──
    final darkGreen = const Color(0xFFC5DFC5);  // verde chiaro
    final lightGreen = const Color(0xFFD5ECD5); // verde chiarissimo
    final stripeWidth = size.width / 14;

    for (int i = 0; i < 14; i++) {
      final paint = Paint()
        ..color = i % 2 == 0 ? darkGreen : lightGreen
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height),
        paint,
      );
    }

    // Overlay gradiente per profondità 3D
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height * 0.3),
          [Colors.black.withOpacity(0.25), Colors.transparent],
        ),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width / 2, size.height / 2),
          size.width * 0.4,
          [Colors.white.withOpacity(0.08), Colors.transparent],
        ),
    );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, size.height * 0.7),
          Offset(size.width / 2, size.height),
          [Colors.transparent, Colors.black.withOpacity(0.15)],
        ),
    );
  }

  void _drawDetailedFieldLines(Canvas canvas, Size size) {
    // Linee bianche piene — alto contrasto su sfondo chiaro
    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    const m = 15.0; // margine campo

    // Bordo esterno
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(m, m, size.width - m * 2, size.height - m * 2),
        const Radius.circular(4),
      ),
      linePaint,
    );

    // Linea centrale
    canvas.drawLine(Offset(size.width / 2, m),
        Offset(size.width / 2, size.height - m), linePaint);

    // ═══ CERCHIO CENTRALE ═══
    final centerCircleR = size.width * 0.09;
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), centerCircleR, linePaint);
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        2.5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill);

    // ═══ AREE DI RIGORE ═══
    // Proporzioni reali: area 16.5m su campo 105m = ~15.7% della lunghezza
    //                    area 40.3m su campo 68m  = ~59.3% dell'altezza
    final penW = size.width * 0.157;
    final penH = size.height * 0.593;
    final penY = (size.height - penH) / 2;

    canvas.drawRect(Rect.fromLTWH(m, penY, penW, penH), linePaint);
    canvas.drawRect(
        Rect.fromLTWH(size.width - m - penW, penY, penW, penH), linePaint);

    // ═══ AREE PICCOLE ═══
    // Proporzioni reali: 5.5m / 105m = ~5.2%, 18.3m / 68m = ~27%
    final smallW = size.width * 0.052;
    final smallH = size.height * 0.27;
    final smallY = (size.height - smallH) / 2;

    canvas.drawRect(Rect.fromLTWH(m, smallY, smallW, smallH), linePaint);
    canvas.drawRect(
        Rect.fromLTWH(size.width - m - smallW, smallY, smallW, smallH),
        linePaint);

    // ═══ DISCHETTI RIGORE ═══
    // 11m dal fondo = 10.5% della lunghezza del campo
    final spotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final spotXL = m + size.width * 0.105;
    final spotXR = size.width - m - size.width * 0.105;
    canvas.drawCircle(Offset(spotXL, size.height / 2), 3.5, spotPaint);
    canvas.drawCircle(Offset(spotXR, size.height / 2), 3.5, spotPaint);

    // ═══ MEZZELUNE (penalty arcs) ═══
    // Raggio reale: 9.15m — proporzionato al campo
    final arcR = size.width * 0.087;
    final penEdgeL = m + penW;
    final penEdgeR = size.width - m - penW;

    // Mezzaluna sinistra — clip per mostrare SOLO la parte fuori dall'area
    final distL = penEdgeL - spotXL;
    if (arcR > distL) {
      final halfAngleL = math.acos((distL / arcR).clamp(-1.0, 1.0));
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(penEdgeL, 0, size.width, size.height));
      canvas.drawArc(
          Rect.fromCircle(
              center: Offset(spotXL, size.height / 2), radius: arcR),
          -halfAngleL,
          halfAngleL * 2,
          false,
          linePaint);
      canvas.restore();
    }

    // Mezzaluna destra
    final distR = spotXR - penEdgeR;
    if (arcR > distR) {
      final halfAngleR = math.acos((distR / arcR).clamp(-1.0, 1.0));
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, penEdgeR, size.height));
      canvas.drawArc(
          Rect.fromCircle(
              center: Offset(spotXR, size.height / 2), radius: arcR),
          math.pi - halfAngleR,
          halfAngleR * 2,
          false,
          linePaint);
      canvas.restore();
    }

    // ═══ CORNER ARCS ═══
    const cornerR = 10.0;
    canvas.drawArc(Rect.fromCircle(center: Offset(m, m), radius: cornerR), 0,
        math.pi / 2, false, linePaint);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(size.width - m, m), radius: cornerR),
        math.pi / 2,
        math.pi / 2,
        false,
        linePaint);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(m, size.height - m), radius: cornerR),
        -math.pi / 2,
        math.pi / 2,
        false,
        linePaint);
    canvas.drawArc(
        Rect.fromCircle(
            center: Offset(size.width - m, size.height - m), radius: cornerR),
        math.pi,
        math.pi / 2,
        false,
        linePaint);
  }

  void _drawFieldDepth(Canvas canvas, Size size) {
    // Depth overlay rimosso per coerenza con sfondo chiaro
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========================================
// SHOT MAP - METÀ CAMPO CON PORTA IN ALTO
// ========================================
class AnimatedShotMapPainter extends CustomPainter {
  final bool isHome;
  final bool isDark;
  final double animationValue;

  AnimatedShotMapPainter({
    required this.isHome,
    required this.isDark,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawHalfFieldVertical(canvas, size);
    _drawAnimatedShots(canvas, size);
  }

  void _drawHalfFieldVertical(Canvas canvas, Size size) {
    // Erba con strisce
    final darkGreen = const Color(0xFF2E7D32);
    final lightGreen = const Color(0xFF43A047);
    final stripeWidth = size.width / 12;

    for (int i = 0; i < 12; i++) {
      canvas.drawRect(
        Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height),
        Paint()..color = i % 2 == 0 ? darkGreen : lightGreen,
      );
    }

    // Gradient profondità
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height),
          [
            Colors.black.withOpacity(0.2),
            Colors.transparent,
            Colors.black.withOpacity(0.05)
          ],
          [0.0, 0.3, 1.0],
        ),
    );

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Lato sinistro
    canvas.drawLine(
        const Offset(10, 10), Offset(10, size.height - 10), linePaint);
    // Lato destro
    canvas.drawLine(Offset(size.width - 10, 10),
        Offset(size.width - 10, size.height - 10), linePaint);
    // Lato basso (linea centrocampo)
    canvas.drawLine(Offset(10, size.height - 10),
        Offset(size.width - 10, size.height - 10), linePaint);

    // Porta in alto
    final goalWidth = size.width * 0.3;
    final goalX = (size.width - goalWidth) / 2;
    final goalPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    canvas.drawRect(Rect.fromLTWH(goalX, 5, goalWidth, 15), goalPaint);

    // Rete porta
    final netPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (double i = 0; i <= goalWidth; i += 12) {
      canvas.drawLine(Offset(goalX + i, 5), Offset(goalX + i, 20), netPaint);
    }
    for (double i = 5; i <= 20; i += 8) {
      canvas.drawLine(Offset(goalX, i), Offset(goalX + goalWidth, i), netPaint);
    }

    // Area di rigore grande
    final penaltyBoxWidth = size.width * 0.65;
    final penaltyBoxDepth = size.height * 0.22;
    final penaltyBoxX = (size.width - penaltyBoxWidth) / 2;

    canvas.drawRect(
      Rect.fromLTWH(penaltyBoxX, 10, penaltyBoxWidth, penaltyBoxDepth),
      linePaint,
    );

    // Area di rigore piccola
    final smallBoxWidth = size.width * 0.4;
    final smallBoxDepth = size.height * 0.1;
    final smallBoxX = (size.width - smallBoxWidth) / 2;

    canvas.drawRect(
      Rect.fromLTWH(smallBoxX, 10, smallBoxWidth, smallBoxDepth),
      linePaint,
    );

    // Dischetto di rigore
    final penaltySpotY = 10 + penaltyBoxDepth * 0.6;
    canvas.drawCircle(
      Offset(size.width / 2, penaltySpotY),
      4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Semicerchio area rigore
    final arcRadius = size.width * 0.12;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width / 2, penaltySpotY),
        width: arcRadius * 2,
        height: arcRadius * 2,
      ),
      0,
      math.pi,
      false,
      linePaint,
    );
  }

  void _drawAnimatedShots(Canvas canvas, Size size) {
    final shots = _generateMockShots(size);

    for (var shot in shots) {
      final scale = 0.5 + (animationValue * 0.5);
      final opacity = animationValue;

      Color shotColor;
      if (shot['goal'] == true) {
        shotColor = Colors.green;
      } else if (shot['onTarget'] == true) {
        shotColor = Colors.orange;
      } else {
        shotColor = Colors.red;
      }

      // Glow effect
      canvas.drawCircle(
        shot['position'],
        14 * scale,
        Paint()
          ..color = shotColor.withOpacity(0.3 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );

      // Cerchio principale con gradient radiale
      canvas.drawCircle(
        shot['position'],
        11 * scale,
        Paint()
          ..shader = ui.Gradient.radial(
            shot['position'],
            11 * scale,
            [
              shotColor.withOpacity(opacity),
              shotColor.withOpacity(0.7 * opacity),
            ],
          ),
      );

      // Bordo bianco
      canvas.drawCircle(
        shot['position'],
        11 * scale,
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      // Stella per goal
      if (shot['goal'] == true) {
        _drawGoalStar(canvas, shot['position'], scale * opacity);
      }
    }
  }

  void _drawGoalStar(Canvas canvas, Offset position, double scale) {
    final starPath = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - math.pi / 2;
      final x = position.dx + math.cos(angle) * 6 * scale;
      final y = position.dy + math.sin(angle) * 6 * scale;
      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();
    canvas.drawPath(
        starPath,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill);
  }

  List<Map<String, dynamic>> _generateMockShots(Size size) {
    final random = math.Random(isHome ? 42 : 99);
    final shots = <Map<String, dynamic>>[];

    for (int i = 0; i < 15; i++) {
      final x = size.width * (0.12 + random.nextDouble() * 0.76);
      final yBias = math.pow(random.nextDouble(), 1.8);
      final y = size.height * 0.08 + (yBias * size.height * 0.75);

      final distanceFromGoal = y / size.height;
      final goalProb = 0.22 - (distanceFromGoal * 0.18);
      final isGoal = random.nextDouble() < goalProb;
      final onTargetProb = 0.55 - (distanceFromGoal * 0.25);
      final isOnTarget = isGoal || random.nextDouble() < onTargetProb;

      shots.add({
        'position': Offset(x, y),
        'goal': isGoal,
        'onTarget': isOnTarget,
      });
    }

    return shots;
  }

  @override
  bool shouldRepaint(AnimatedShotMapPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
        isHome != oldDelegate.isHome;
  }
}

// ========================================
// PASS NETWORK VISIBILE E CHIARO
// ========================================
class GradientPassNetworkPainter extends CustomPainter {
  final bool isHome;
  final bool isDark;
  final double animationValue;

  GradientPassNetworkPainter({
    required this.isHome,
    required this.isDark,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    RealisticSoccerFieldPainter(isDark: isDark).paint(canvas, size);
    _drawPassNetwork(canvas, size);
  }

  void _drawPassNetwork(Canvas canvas, Size size) {
    final players = _generatePlayerPositions(size);

    // Linee passaggi
    for (int i = 0; i < players.length; i++) {
      for (int j = i + 1; j < players.length; j++) {
        final pos1 = players[i]['pos'] as Offset;
        final pos2 = players[j]['pos'] as Offset;
        final distance = (pos1 - pos2).distance;

        if (distance < size.width * 0.35) {
          final passes = ((200 - distance) / 15).clamp(5, 20).toInt();
          final thickness = (passes / 20 * 8).clamp(2.0, 8.0);
          final opacity = (animationValue * 0.8).clamp(0.0, 0.8);

          canvas.drawLine(
            pos1,
            pos2,
            Paint()
              ..color = Colors.white.withOpacity(0.3 * animationValue)
              ..strokeWidth = thickness + 6
              ..strokeCap = StrokeCap.round
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );

          canvas.drawLine(
            pos1,
            pos2,
            Paint()
              ..color = Colors.blue[400]!.withOpacity(opacity)
              ..strokeWidth = thickness
              ..strokeCap = StrokeCap.round,
          );
        }
      }
    }

    // Giocatori sopra le linee
    for (var player in players) {
      _drawPlayer(canvas, player['pos'], player['number']);
    }
  }

  void _drawPlayer(Canvas canvas, Offset position, int number) {
    final scale = animationValue;
    final teamColor =
        isHome ? const Color(0xFF2196F3) : const Color(0xFFE53935);

    // Ombra
    canvas.drawCircle(
      position + const Offset(3, 3),
      22 * scale,
      Paint()
        ..color = Colors.black.withOpacity(0.5 * scale)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Cerchio giocatore
    canvas.drawCircle(position, 22 * scale, Paint()..color = teamColor);

    // Bordo bianco
    canvas.drawCircle(
      position,
      22 * scale,
      Paint()
        ..color = Colors.white.withOpacity(scale)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Numero
    final textPainter = TextPainter(
      text: TextSpan(
        text: number.toString(),
        style: TextStyle(
          color: Colors.white.withOpacity(scale),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      position - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  List<Map<String, dynamic>> _generatePlayerPositions(Size size) {
    final positions = <Map<String, dynamic>>[];
    final marginX = size.width * 0.1;
    final marginY = size.height * 0.1;
    final usableWidth = size.width - (marginX * 2);
    final usableHeight = size.height - (marginY * 2);

    // Portiere
    positions.add({
      'pos': Offset(marginX + usableWidth * 0.05, size.height / 2),
      'number': 1,
    });

    // 4 Difensori
    for (int i = 0; i < 4; i++) {
      positions.add({
        'pos': Offset(
            marginX + usableWidth * 0.25, marginY + (i * usableHeight / 3)),
        'number': 2 + i,
      });
    }

    // 3 Centrocampisti
    for (int i = 0; i < 3; i++) {
      positions.add({
        'pos': Offset(marginX + usableWidth * 0.55,
            marginY + usableHeight * 0.15 + (i * usableHeight * 0.35)),
        'number': 6 + i,
      });
    }

    // 3 Attaccanti
    for (int i = 0; i < 3; i++) {
      positions.add({
        'pos': Offset(marginX + usableWidth * 0.85,
            marginY + usableHeight * 0.15 + (i * usableHeight * 0.35)),
        'number': 9 + i,
      });
    }

    return positions;
  }

  @override
  bool shouldRepaint(GradientPassNetworkPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
        isHome != oldDelegate.isHome;
  }
}

// ========================================
// HEATMAP 3D CON GRADIENT AVANZATO
// ========================================
class Advanced3DHeatmapPainter extends CustomPainter {
  final bool isHome;
  final bool isDark;
  final double animationValue;

  Advanced3DHeatmapPainter({
    required this.isHome,
    required this.isDark,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    RealisticSoccerFieldPainter(isDark: isDark).paint(canvas, size);
    _drawHeatmap(canvas, size);
  }

  void _drawHeatmap(Canvas canvas, Size size) {
    final gridSize = 15;
    final cellWidth = size.width / gridSize;
    final cellHeight = size.height / gridSize;
    final random = math.Random(isHome ? 42 : 99);

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final x = col * cellWidth;
        final y = row * cellHeight;

        double intensity;
        if (isHome) {
          intensity = 1.0 - (col / gridSize);
        } else {
          intensity = col / gridSize;
        }

        intensity = (intensity + random.nextDouble() * 0.3).clamp(0.0, 1.0);
        intensity *= animationValue;

        if (intensity > 0.1) {
          _drawHeatCell(canvas, Offset(x, y), cellWidth, cellHeight, intensity);
        }
      }
    }
  }

  void _drawHeatCell(Canvas canvas, Offset position, double width,
      double height, double intensity) {
    final colors = [
      const Color(0xFF1E88E5),
      const Color(0xFF43A047),
      const Color(0xFFFDD835),
      const Color(0xFFFF6F00),
      const Color(0xFFD32F2F),
    ];

    final colorIndex = (intensity * (colors.length - 1)).floor();
    final nextColorIndex = (colorIndex + 1).clamp(0, colors.length - 1);
    final t = (intensity * (colors.length - 1)) - colorIndex;
    final color = Color.lerp(colors[colorIndex], colors[nextColorIndex], t)!;

    canvas.drawCircle(
      position + Offset(width / 2, height / 2),
      width / 2,
      Paint()
        ..shader = ui.Gradient.radial(
          position + Offset(width / 2, height / 2),
          width / 2,
          [
            color.withOpacity(intensity * 0.7),
            color.withOpacity(intensity * 0.3),
            Colors.transparent,
          ],
          [0.0, 0.7, 1.0],
        ),
    );
  }

  @override
  bool shouldRepaint(Advanced3DHeatmapPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
        isHome != oldDelegate.isHome;
  }
}

// ========================================
// DEFENSIVE ACTIONS CON ICONE
// ========================================
class DetailedDefensiveActionsPainter extends CustomPainter {
  final bool isDark;
  final double animationValue;

  DetailedDefensiveActionsPainter({
    required this.isDark,
    this.animationValue = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    RealisticSoccerFieldPainter(isDark: isDark).paint(canvas, size);
    _drawDefensiveActions(canvas, size);
  }

  void _drawDefensiveActions(Canvas canvas, Size size) {
    final random = math.Random(42);

    // Tackle (rossi)
    for (int i = 0; i < 8; i++) {
      final x = size.width * (0.1 + random.nextDouble() * 0.4);
      final y = size.height * (0.2 + random.nextDouble() * 0.6);
      _drawTackleIcon(canvas, Offset(x, y), animationValue);
    }

    // Intercetti (arancio)
    for (int i = 0; i < 6; i++) {
      final x = size.width * (0.2 + random.nextDouble() * 0.5);
      final y = size.height * (0.1 + random.nextDouble() * 0.8);
      _drawInterceptIcon(canvas, Offset(x, y), animationValue);
    }

    // Clearance (gialli)
    for (int i = 0; i < 4; i++) {
      final x = size.width * (0.05 + random.nextDouble() * 0.3);
      final y = size.height * (0.2 + random.nextDouble() * 0.6);
      _drawClearanceIcon(canvas, Offset(x, y), animationValue);
    }
  }

  void _drawTackleIcon(Canvas canvas, Offset position, double scale) {
    canvas.drawCircle(
      position,
      12 * scale,
      Paint()
        ..color = Colors.red.withOpacity(0.4 * scale)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawCircle(
      position,
      10 * scale,
      Paint()
        ..shader = ui.Gradient.radial(
          position,
          10 * scale,
          [Colors.red.withOpacity(scale), Colors.red[700]!.withOpacity(scale)],
        ),
    );

    canvas.drawCircle(
      position,
      10 * scale,
      Paint()
        ..color = Colors.white.withOpacity(scale)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final iconPaint = Paint()
      ..color = Colors.white.withOpacity(scale)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      position + Offset(-4 * scale, -4 * scale),
      position + Offset(4 * scale, 4 * scale),
      iconPaint,
    );
    canvas.drawLine(
      position + Offset(4 * scale, -4 * scale),
      position + Offset(-4 * scale, 4 * scale),
      iconPaint,
    );
  }

  void _drawInterceptIcon(Canvas canvas, Offset position, double scale) {
    final path = Path();
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * math.pi / 3) - math.pi / 2;
      final x = position.dx + math.cos(angle) * 12 * scale;
      final y = position.dy + math.sin(angle) * 12 * scale;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.orange.withOpacity(0.4 * scale)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(
          position + Offset(0, -10 * scale),
          position + Offset(0, 10 * scale),
          [
            Colors.orange.withOpacity(scale),
            Colors.orange[700]!.withOpacity(scale)
          ],
        ),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(scale)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawClearanceIcon(Canvas canvas, Offset position, double scale) {
    canvas.drawRect(
      Rect.fromCenter(center: position, width: 20 * scale, height: 20 * scale),
      Paint()
        ..color = Colors.yellow.withOpacity(0.4 * scale)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawRect(
      Rect.fromCenter(center: position, width: 16 * scale, height: 16 * scale),
      Paint()
        ..shader = ui.Gradient.linear(
          position + Offset(-10 * scale, 0),
          position + Offset(10 * scale, 0),
          [
            Colors.yellow[700]!.withOpacity(scale),
            Colors.yellow.withOpacity(scale)
          ],
        ),
    );

    canvas.drawRect(
      Rect.fromCenter(center: position, width: 16 * scale, height: 16 * scale),
      Paint()
        ..color = Colors.white.withOpacity(scale)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final arrowPaint = Paint()
      ..color = Colors.white.withOpacity(scale)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      position + Offset(0, 4 * scale),
      position + Offset(0, -4 * scale),
      arrowPaint,
    );
    canvas.drawLine(
      position + Offset(0, -4 * scale),
      position + Offset(-3 * scale, -1 * scale),
      arrowPaint,
    );
    canvas.drawLine(
      position + Offset(0, -4 * scale),
      position + Offset(3 * scale, -1 * scale),
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(DetailedDefensiveActionsPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
