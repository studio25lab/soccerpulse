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

  RealisticSoccerFieldPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. ERBA CON PATTERN STRISCE PROFESSIONALI
    _drawEnhancedGrassPattern(canvas, size);

    // 2. LINEE CAMPO DETTAGLIATE
    _drawDetailedFieldLines(canvas, size);

    // 3. OMBREGGIATURE E PROFONDITÀ
    _drawFieldDepth(canvas, size);
  }

  void _drawEnhancedGrassPattern(Canvas canvas, Size size) {
    // Colori erba più realistici
    final darkGreen = const Color(0xFF1B5E20);
    final lightGreen = const Color(0xFF2E7D32);

    final stripeWidth = size.width / 14; // 14 strisce per più dettaglio

    for (int i = 0; i < 14; i++) {
      final paint = Paint()
        ..color = i % 2 == 0 ? darkGreen : lightGreen
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height),
        paint,
      );
    }

    // Overlay gradiente multiplo per profondità 3D
    final gradients = [
      // Gradiente dall'alto
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, 0),
          Offset(size.width / 2, size.height * 0.3),
          [
            Colors.black.withOpacity(0.25),
            Colors.transparent,
          ],
        ),
      // Gradiente centrale per cerchio di luce
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(size.width / 2, size.height / 2),
          size.width * 0.4,
          [
            Colors.white.withOpacity(0.08),
            Colors.transparent,
          ],
        ),
      // Gradiente dal basso
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(size.width / 2, size.height * 0.7),
          Offset(size.width / 2, size.height),
          [
            Colors.transparent,
            Colors.black.withOpacity(0.15),
          ],
        ),
    ];

    for (var gradientPaint in gradients) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        gradientPaint,
      );
    }
  }

  void _drawDetailedFieldLines(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Bordo esterno con angoli arrotondati
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(15, 15, size.width - 30, size.height - 30),
        const Radius.circular(12),
      ),
      linePaint,
    );

    // Linea centrale con ombra
    final centerLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width / 2, 15),
      Offset(size.width / 2, size.height - 15),
      centerLinePaint,
    );

    // Cerchio centrale con ombra interna
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      50,
      linePaint,
    );

    // Punto centrale più grande
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Aree di rigore con dettagli
    final penaltyWidth = size.width * 0.22;
    final penaltyHeight = size.height * 0.45;

    // Area rigore sinistra
    canvas.drawRect(
      Rect.fromLTWH(
        15,
        (size.height - penaltyHeight) / 2,
        penaltyWidth,
        penaltyHeight,
      ),
      linePaint,
    );

    // Area rigore destra
    canvas.drawRect(
      Rect.fromLTWH(
        size.width - 15 - penaltyWidth,
        (size.height - penaltyHeight) / 2,
        penaltyWidth,
        penaltyHeight,
      ),
      linePaint,
    );

    // Aree piccole
    final smallBoxWidth = size.width * 0.1;
    final smallBoxHeight = size.height * 0.22;

    canvas.drawRect(
      Rect.fromLTWH(
        15,
        (size.height - smallBoxHeight) / 2,
        smallBoxWidth,
        smallBoxHeight,
      ),
      linePaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        size.width - 15 - smallBoxWidth,
        (size.height - smallBoxHeight) / 2,
        smallBoxWidth,
        smallBoxHeight,
      ),
      linePaint,
    );

    // Dischetti rigore più visibili
    final penaltySpotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(15 + penaltyWidth * 0.6, size.height / 2),
      4,
      penaltySpotPaint,
    );

    canvas.drawCircle(
      Offset(size.width - 15 - penaltyWidth * 0.6, size.height / 2),
      4,
      penaltySpotPaint,
    );

    // Semicerchi area rigore
    final arcRadius = 50.0;

    // Sinistra
    final leftArcRect = Rect.fromCircle(
      center: Offset(15 + penaltyWidth * 0.6, size.height / 2),
      radius: arcRadius,
    );
    canvas.drawArc(
      leftArcRect,
      -math.pi / 2,
      math.pi,
      false,
      linePaint,
    );

    // Destra
    final rightArcRect = Rect.fromCircle(
      center: Offset(size.width - 15 - penaltyWidth * 0.6, size.height / 2),
      radius: arcRadius,
    );
    canvas.drawArc(
      rightArcRect,
      math.pi / 2,
      math.pi,
      false,
      linePaint,
    );
  }

  void _drawFieldDepth(Canvas canvas, Size size) {
    // Ombra vignette ai bordi
    final vignettePaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(size.width / 2, size.height / 2),
        size.width * 0.7,
        [
          Colors.transparent,
          Colors.black.withOpacity(0.15),
        ],
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      vignettePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========================================
// SHOT MAP CON ANIMAZIONI
// ========================================
// PAINTERS CORRETTI - Da sostituire in advanced_stats_painters.dart
// Sostituisci da riga 116 (AnimatedShotMapPainter) fino a riga 570 (fine GradientPassNetworkPainter)

// ========================================
// SHOT MAP CON METÀ CAMPO OFFENSIVA
// ========================================
// SHOT MAP CORRETTO - METÀ CAMPO CON PORTA IN ALTO
// Sostituisci la classe AnimatedShotMapPainter (riga ~200-330) con questa:

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
    // Metà campo verticale con porta in alto
    _drawHalfFieldVertical(canvas, size);

    // Tiri animati
    _drawAnimatedShots(canvas, size);
  }

  void _drawHalfFieldVertical(Canvas canvas, Size size) {
    // 1. ERBA con strisce VERTICALI (metà campo)
    final darkGreen = const Color(0xFF2E7D32);
    final lightGreen = const Color(0xFF43A047);
    final stripeWidth = size.width / 12;

    for (int i = 0; i < 12; i++) {
      final paint = Paint()
        ..color = i % 2 == 0 ? darkGreen : lightGreen
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height),
        paint,
      );
    }

    // Gradient profondità
    final gradientPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        [
          Colors.black.withOpacity(0.2),
          Colors.transparent,
          Colors.black.withOpacity(0.05),
        ],
        [0.0, 0.3, 1.0],
      );

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      gradientPaint,
    );

    // 2. LINEE CAMPO
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Bordo campo (solo 3 lati, quello in alto è dove c'è la porta)
    // Lato sinistro
    canvas.drawLine(
      const Offset(10, 10),
      Offset(10, size.height - 10),
      linePaint,
    );

    // Lato destro
    canvas.drawLine(
      Offset(size.width - 10, 10),
      Offset(size.width - 10, size.height - 10),
      linePaint,
    );

    // Lato basso (linea centrocampo)
    canvas.drawLine(
      Offset(10, size.height - 10),
      Offset(size.width - 10, size.height - 10),
      linePaint,
    );

    // 3. PORTA IN ALTO (ben visibile)
    final goalWidth = size.width * 0.3;
    final goalX = (size.width - goalWidth) / 2;
    final goalDepth = 15.0;

    // Pali porta (bianchi spessi)
    final goalPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    // Rettangolo porta
    final goalRect = Rect.fromLTWH(goalX, 5, goalWidth, goalDepth);
    canvas.drawRect(goalRect, goalPaint);

    // Rete porta (pattern linee)
    final netPaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Linee verticali rete
    for (double i = 0; i <= goalWidth; i += 12) {
      canvas.drawLine(
        Offset(goalX + i, 5),
        Offset(goalX + i, 20),
        netPaint,
      );
    }

    // Linee orizzontali rete
    for (double i = 5; i <= 20; i += 8) {
      canvas.drawLine(
        Offset(goalX, i),
        Offset(goalX + goalWidth, i),
        netPaint,
      );
    }

    // 4. AREA DI RIGORE GRANDE
    final penaltyBoxWidth = size.width * 0.65;
    final penaltyBoxDepth = size.height * 0.22;
    final penaltyBoxX = (size.width - penaltyBoxWidth) / 2;

    canvas.drawRect(
      Rect.fromLTWH(
        penaltyBoxX,
        10,
        penaltyBoxWidth,
        penaltyBoxDepth,
      ),
      linePaint,
    );

    // 5. AREA DI RIGORE PICCOLA
    final smallBoxWidth = size.width * 0.4;
    final smallBoxDepth = size.height * 0.1;
    final smallBoxX = (size.width - smallBoxWidth) / 2;

    canvas.drawRect(
      Rect.fromLTWH(
        smallBoxX,
        10,
        smallBoxWidth,
        smallBoxDepth,
      ),
      linePaint,
    );

    // 6. DISCHETTO DI RIGORE
    final penaltySpotY = 10 + penaltyBoxDepth * 0.6;

    canvas.drawCircle(
      Offset(size.width / 2, penaltySpotY),
      4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // 7. SEMICERCHIO AREA RIGORE
    final arcRadius = size.width * 0.12;
    final arcRect = Rect.fromCenter(
      center: Offset(size.width / 2, penaltySpotY),
      width: arcRadius * 2,
      height: arcRadius * 2,
    );

    canvas.drawArc(
      arcRect,
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
      final glowPaint = Paint()
        ..color = shotColor.withOpacity(0.3 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(
        shot['position'],
        14 * scale,
        glowPaint,
      );

      // Cerchio principale con gradient radiale
      final shotPaint = Paint()
        ..shader = ui.Gradient.radial(
          shot['position'],
          11 * scale,
          [
            shotColor.withOpacity(opacity),
            shotColor.withOpacity(0.7 * opacity),
          ],
        )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        shot['position'],
        11 * scale,
        shotPaint,
      );

      // Bordo bianco spesso
      canvas.drawCircle(
        shot['position'],
        11 * scale,
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );

      // Icona goal (stella)
      if (shot['goal'] == true) {
        _drawGoalStar(canvas, shot['position'], scale * opacity);
      }
    }
  }

  void _drawGoalStar(Canvas canvas, Offset position, double scale) {
    final starPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

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

    canvas.drawPath(starPath, starPaint);
  }

  List<Map<String, dynamic>> _generateMockShots(Size size) {
    final random = math.Random(42);
    final shots = <Map<String, dynamic>>[];

    // Genera 15 tiri distribuiti nella metà campo offensiva
    for (int i = 0; i < 15; i++) {
      // X: sparso su tutta la larghezza (con margini)
      final x = size.width * (0.12 + random.nextDouble() * 0.76);

      // Y: dalla porta verso il centrocampo
      // Bias verso la porta (più tiri vicino all'area)
      final yBias = math.pow(random.nextDouble(), 1.8);
      final y = size.height * 0.08 + (yBias * size.height * 0.75);

      // Probabilità goal basata su distanza dalla porta
      final distanceFromGoal = y / size.height;
      final goalProb = 0.22 - (distanceFromGoal * 0.18);
      final isGoal = random.nextDouble() < goalProb;

      // Probabilità in porta
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
    return animationValue != oldDelegate.animationValue;
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
    // Campo realistico
    RealisticSoccerFieldPainter(isDark: isDark).paint(canvas, size);

    // Network passaggi VISIBILE
    _drawPassNetwork(canvas, size);
  }

  void _drawPassNetwork(Canvas canvas, Size size) {
    final players = _generatePlayerPositions(size);

    // Disegna linee passaggi PRIMA (sotto i giocatori)
    for (int i = 0; i < players.length; i++) {
      for (int j = i + 1; j < players.length; j++) {
        final pos1 = players[i]['pos'] as Offset;
        final pos2 = players[j]['pos'] as Offset;
        final distance = (pos1 - pos2).distance;

        // Connetti giocatori vicini
        if (distance < size.width * 0.35) {
          final passes = ((200 - distance) / 15).clamp(5, 20).toInt();
          _drawPassLine(canvas, pos1, pos2, passes);
        }
      }
    }

    // Disegna giocatori SOPRA le linee
    for (var player in players) {
      _drawPlayer(canvas, player['pos'], player['number']);
    }
  }

  void _drawPassLine(Canvas canvas, Offset from, Offset to, int passes) {
    final thickness = (passes / 20 * 8).clamp(2.0, 8.0);
    final opacity = (animationValue * 0.8).clamp(0.0, 0.8);

    // Linea principale BLU BRILLANTE
    final paint = Paint()
      ..color = Colors.blue[400]!.withOpacity(opacity)
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(from, to, paint);

    // Glow effect BIANCO
    final glowPaint = Paint()
      ..color = Colors.white.withOpacity(0.3 * animationValue)
      ..strokeWidth = thickness + 6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawLine(from, to, glowPaint);
  }

  void _drawPlayer(Canvas canvas, Offset position, int number) {
    final scale = animationValue;

    // Ombra NERA forte
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5 * scale)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(position + const Offset(3, 3), 22 * scale, shadowPaint);

    // Cerchio giocatore BLU BRILLANTE
    final playerPaint = Paint()
      ..color = const Color(0xFF2196F3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 22 * scale, playerPaint);

    // Bordo BIANCO spesso
    canvas.drawCircle(
      position,
      22 * scale,
      Paint()
        ..color = Colors.white.withOpacity(scale)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Numero BIANCO grande
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

    // Margini dal bordo
    final marginX = size.width * 0.1;
    final marginY = size.height * 0.1;
    final usableWidth = size.width - (marginX * 2);
    final usableHeight = size.height - (marginY * 2);

    // FORMAZIONE 4-3-3 ben VISIBILE

    // Portiere (sinistra)
    positions.add({
      'pos': Offset(marginX + usableWidth * 0.05, size.height / 2),
      'number': 1,
    });

    // 4 Difensori (verticale sinistra)
    for (int i = 0; i < 4; i++) {
      positions.add({
        'pos': Offset(
          marginX + usableWidth * 0.25,
          marginY + (i * usableHeight / 3),
        ),
        'number': 2 + i,
      });
    }

    // 3 Centrocampisti (verticale centro)
    for (int i = 0; i < 3; i++) {
      positions.add({
        'pos': Offset(
          marginX + usableWidth * 0.55,
          marginY + usableHeight * 0.15 + (i * usableHeight * 0.35),
        ),
        'number': 6 + i,
      });
    }

    // 3 Attaccanti (verticale destra)
    for (int i = 0; i < 3; i++) {
      positions.add({
        'pos': Offset(
          marginX + usableWidth * 0.85,
          marginY + usableHeight * 0.15 + (i * usableHeight * 0.35),
        ),
        'number': 9 + i,
      });
    }

    return positions;
  }

  @override
  bool shouldRepaint(GradientPassNetworkPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
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
    // Campo realistico
    RealisticSoccerFieldPainter(isDark: isDark).paint(canvas, size);

    // Heatmap con gradient 3D
    _drawHeatmap(canvas, size);
  }

  void _drawHeatmap(Canvas canvas, Size size) {
    final gridSize = 15;
    final cellWidth = size.width / gridSize;
    final cellHeight = size.height / gridSize;

    final random = math.Random(42);

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final x = col * cellWidth;
        final y = row * cellHeight;

        // Genera intensità basata su posizione
        double intensity;
        if (isHome) {
          intensity = 1.0 - (col / gridSize);
        } else {
          intensity = col / gridSize;
        }

        // Aggiungi variazione random
        intensity = (intensity + random.nextDouble() * 0.3).clamp(0.0, 1.0);

        // Animazione fade-in
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
      const Color(0xFF1E88E5), // Blu
      const Color(0xFF43A047), // Verde
      const Color(0xFFFDD835), // Giallo
      const Color(0xFFFF6F00), // Arancio
      const Color(0xFFD32F2F), // Rosso
    ];

    final colorIndex = (intensity * (colors.length - 1)).floor();
    final nextColorIndex = (colorIndex + 1).clamp(0, colors.length - 1);
    final t = (intensity * (colors.length - 1)) - colorIndex;

    final color = Color.lerp(colors[colorIndex], colors[nextColorIndex], t)!;

    // Gradient radiale per effetto 3D
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        position + Offset(width / 2, height / 2),
        width / 2,
        [
          color.withOpacity(intensity * 0.7),
          color.withOpacity(intensity * 0.3),
          Colors.transparent,
        ],
        [0.0, 0.7, 1.0],
      );

    canvas.drawCircle(
      position + Offset(width / 2, height / 2),
      width / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(Advanced3DHeatmapPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}

// ========================================
// DEFENSIVE ACTIONS CON ICONE MIGLIORATE
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
    // Campo realistico
    RealisticSoccerFieldPainter(isDark: isDark).paint(canvas, size);

    // Azioni difensive con icone dettagliate
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
    // Glow rosso
    final glowPaint = Paint()
      ..color = Colors.red.withOpacity(0.4 * scale)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(position, 12 * scale, glowPaint);

    // Cerchio principale con gradient
    final circlePaint = Paint()
      ..shader = ui.Gradient.radial(
        position,
        10 * scale,
        [
          Colors.red.withOpacity(scale),
          Colors.red[700]!.withOpacity(scale),
        ],
      );

    canvas.drawCircle(position, 10 * scale, circlePaint);

    // Bordo bianco
    canvas.drawCircle(
      position,
      10 * scale,
      Paint()
        ..color = Colors.white.withOpacity(scale)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Icona X
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
    // Glow arancio
    final glowPaint = Paint()
      ..color = Colors.orange.withOpacity(0.4 * scale)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

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

    canvas.drawPath(path, glowPaint);

    // Triangolo principale con gradient
    final trianglePaint = Paint()
      ..shader = ui.Gradient.linear(
        position + Offset(0, -10 * scale),
        position + Offset(0, 10 * scale),
        [
          Colors.orange.withOpacity(scale),
          Colors.orange[700]!.withOpacity(scale),
        ],
      );

    canvas.drawPath(path, trianglePaint);

    // Bordo bianco
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(scale)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawClearanceIcon(Canvas canvas, Offset position, double scale) {
    // Glow giallo
    final glowPaint = Paint()
      ..color = Colors.yellow.withOpacity(0.4 * scale)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawRect(
      Rect.fromCenter(center: position, width: 20 * scale, height: 20 * scale),
      glowPaint,
    );

    // Quadrato principale con gradient
    final squarePaint = Paint()
      ..shader = ui.Gradient.linear(
        position + Offset(-10 * scale, 0),
        position + Offset(10 * scale, 0),
        [
          Colors.yellow[700]!.withOpacity(scale),
          Colors.yellow.withOpacity(scale),
        ],
      );

    canvas.drawRect(
      Rect.fromCenter(center: position, width: 16 * scale, height: 16 * scale),
      squarePaint,
    );

    // Bordo bianco
    canvas.drawRect(
      Rect.fromCenter(center: position, width: 16 * scale, height: 16 * scale),
      Paint()
        ..color = Colors.white.withOpacity(scale)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Freccia up
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
