// TUTTI I PAINTER CORRETTI - PROPORZIONI PERFETTE
// lib/painters/soccer_field_painters.dart
// USO: Copia questo file e usa questi painter in TUTTE le sezioni

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

// ========================================
// 1. CAMPO FORMAZIONI - PROPORZIONI CORRETTE 1.5:1
// ========================================
class FormationFieldPainter extends CustomPainter {
  final bool isDark;

  FormationFieldPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Calcola dimensioni corrette con proporzioni 1.5:1 (105m x 68m)
    final fieldHeight = size.height * 0.95;
    final fieldWidth = fieldHeight * 1.5; // Rapporto corretto!

    // Centra il campo
    final offsetX = (size.width - fieldWidth) / 2;
    final offsetY = (size.height - fieldHeight) / 2;

    // 1. Erba con strisce verticali
    _drawGrass(canvas, offsetX, offsetY, fieldWidth, fieldHeight);

    // 2. Linee campo accurate
    _drawFieldLines(canvas, offsetX, offsetY, fieldWidth, fieldHeight);
  }

  void _drawGrass(
      Canvas canvas, double x, double y, double width, double height) {
    final darkGreen = const Color(0xFF1B5E20);
    final lightGreen = const Color(0xFF2E7D32);
    final stripeWidth = width / 14;

    // 14 strisce verticali
    for (int i = 0; i < 14; i++) {
      canvas.drawRect(
        Rect.fromLTWH(x + i * stripeWidth, y, stripeWidth, height),
        Paint()..color = i % 2 == 0 ? darkGreen : lightGreen,
      );
    }

    // Gradient ombra top
    canvas.drawRect(
      Rect.fromLTWH(x, y, width, height),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(x + width / 2, y),
          Offset(x + width / 2, y + height * 0.2),
          [Colors.black.withOpacity(0.15), Colors.transparent],
        ),
    );

    // Gradient ombra bottom
    canvas.drawRect(
      Rect.fromLTWH(x, y, width, height),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(x + width / 2, y + height * 0.8),
          Offset(x + width / 2, y + height),
          [Colors.transparent, Colors.black.withOpacity(0.1)],
        ),
    );
  }

  void _drawFieldLines(
      Canvas canvas, double x, double y, double width, double height) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final margin = 8.0;

    // Bordo campo
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            x + margin, y + margin, width - margin * 2, height - margin * 2),
        const Radius.circular(6),
      ),
      linePaint,
    );

    // Linea centrale orizzontale
    final centerY = y + height / 2;
    canvas.drawLine(
      Offset(x + margin, centerY),
      Offset(x + width - margin, centerY),
      linePaint,
    );

    // Cerchio centrale (proporzioni corrette)
    final circleRadius = height * 0.12;
    canvas.drawCircle(
      Offset(x + width / 2, centerY),
      circleRadius,
      linePaint,
    );

    // Punto centrale
    canvas.drawCircle(
      Offset(x + width / 2, centerY),
      3,
      Paint()..color = Colors.white,
    );

    // Area rigore SINISTRA (porta in alto)
    _drawPenaltyArea(canvas, x, y, width, height, margin, linePaint, true);

    // Area rigore DESTRA (porta in basso)
    _drawPenaltyArea(canvas, x, y, width, height, margin, linePaint, false);
  }

  void _drawPenaltyArea(Canvas canvas, double x, double y, double width,
      double height, double margin, Paint paint, bool isTop) {
    // Dimensioni realistiche aree rigore
    final penaltyWidth = width * 0.6; // 60% larghezza campo
    final penaltyHeight = height * 0.18; // 18% altezza campo
    final smallWidth = width * 0.35; // 35% larghezza campo
    final smallHeight = height * 0.09; // 9% altezza campo

    final penaltyX = x + (width - penaltyWidth) / 2;
    final smallX = x + (width - smallWidth) / 2;

    if (isTop) {
      // Area grande top
      canvas.drawRect(
        Rect.fromLTWH(penaltyX, y + margin, penaltyWidth, penaltyHeight),
        paint,
      );

      // Area piccola top
      canvas.drawRect(
        Rect.fromLTWH(smallX, y + margin, smallWidth, smallHeight),
        paint,
      );

      // Dischetto
      final spotY = y + margin + penaltyHeight * 0.65;
      canvas.drawCircle(
        Offset(x + width / 2, spotY),
        3,
        Paint()..color = Colors.white,
      );

      // Semicerchio area rigore
      canvas.drawArc(
        Rect.fromCircle(
            center: Offset(x + width / 2, spotY), radius: height * 0.12),
        0,
        math.pi,
        false,
        paint,
      );

      // Porta
      final goalWidth = width * 0.25;
      final goalX = x + (width - goalWidth) / 2;
      canvas.drawLine(
        Offset(goalX, y + margin),
        Offset(goalX + goalWidth, y + margin),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    } else {
      // Area grande bottom
      canvas.drawRect(
        Rect.fromLTWH(penaltyX, y + height - margin - penaltyHeight,
            penaltyWidth, penaltyHeight),
        paint,
      );

      // Area piccola bottom
      canvas.drawRect(
        Rect.fromLTWH(
            smallX, y + height - margin - smallHeight, smallWidth, smallHeight),
        paint,
      );

      // Dischetto
      final spotY = y + height - margin - penaltyHeight * 0.65;
      canvas.drawCircle(
        Offset(x + width / 2, spotY),
        3,
        Paint()..color = Colors.white,
      );

      // Semicerchio area rigore
      canvas.drawArc(
        Rect.fromCircle(
            center: Offset(x + width / 2, spotY), radius: height * 0.12),
        math.pi,
        math.pi,
        false,
        paint,
      );

      // Porta
      final goalWidth = width * 0.25;
      final goalX = x + (width - goalWidth) / 2;
      canvas.drawLine(
        Offset(goalX, y + height - margin),
        Offset(goalX + goalWidth, y + height - margin),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========================================
// 2. CAMPO STATISTICHE - PROPORZIONI CORRETTE
// ========================================
class StatsFieldPainter extends CustomPainter {
  final bool isDark;

  StatsFieldPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final fieldHeight = size.height * 0.95;
    final fieldWidth = fieldHeight * 1.5;
    final offsetX = (size.width - fieldWidth) / 2;
    final offsetY = (size.height - fieldHeight) / 2;

    _drawGrass(canvas, offsetX, offsetY, fieldWidth, fieldHeight);
    _drawSimpleLines(canvas, offsetX, offsetY, fieldWidth, fieldHeight);
  }

  void _drawGrass(
      Canvas canvas, double x, double y, double width, double height) {
    final darkGreen = const Color(0xFF1B5E20);
    final lightGreen = const Color(0xFF2E7D32);
    final stripeWidth = width / 14;

    for (int i = 0; i < 14; i++) {
      canvas.drawRect(
        Rect.fromLTWH(x + i * stripeWidth, y, stripeWidth, height),
        Paint()..color = i % 2 == 0 ? darkGreen : lightGreen,
      );
    }
  }

  void _drawSimpleLines(
      Canvas canvas, double x, double y, double width, double height) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Bordo
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 8, y + 8, width - 16, height - 16),
        const Radius.circular(6),
      ),
      linePaint,
    );

    // Linea centrale
    canvas.drawLine(
      Offset(x + width / 2, y + 8),
      Offset(x + width / 2, y + height - 8),
      linePaint,
    );

    // Cerchio centrale
    canvas.drawCircle(
      Offset(x + width / 2, y + height / 2),
      height * 0.12,
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========================================
// 3. CAMPO EVENTI - PROPORZIONI CORRETTE
// ========================================
class EventsFieldPainter extends CustomPainter {
  final bool isDark;

  EventsFieldPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final fieldHeight = size.height * 0.95;
    final fieldWidth = fieldHeight * 1.5;
    final offsetX = (size.width - fieldWidth) / 2;
    final offsetY = (size.height - fieldHeight) / 2;

    _drawGrass(canvas, offsetX, offsetY, fieldWidth, fieldHeight);
    _drawMinimalLines(canvas, offsetX, offsetY, fieldWidth, fieldHeight);
  }

  void _drawGrass(
      Canvas canvas, double x, double y, double width, double height) {
    final darkGreen = const Color(0xFF1B5E20);
    final lightGreen = const Color(0xFF2E7D32);
    final stripeWidth = width / 14;

    for (int i = 0; i < 14; i++) {
      canvas.drawRect(
        Rect.fromLTWH(x + i * stripeWidth, y, stripeWidth, height),
        Paint()..color = i % 2 == 0 ? darkGreen : lightGreen,
      );
    }
  }

  void _drawMinimalLines(
      Canvas canvas, double x, double y, double width, double height) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Solo bordo e linea centrale
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 8, y + 8, width - 16, height - 16),
        const Radius.circular(6),
      ),
      linePaint,
    );

    canvas.drawLine(
      Offset(x + width / 2, y + 8),
      Offset(x + width / 2, y + height - 8),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========================================
// HELPER: Wrapper Widget per campo con proporzioni corrette
// ========================================
class SoccerFieldWidget extends StatelessWidget {
  final CustomPainter painter;
  final double? height;

  const SoccerFieldWidget({
    Key? key,
    required this.painter,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcola altezza basata su larghezza disponibile
        final maxWidth = constraints.maxWidth;
        final calculatedHeight = height ?? (maxWidth / 1.5); // Rapporto 1.5:1

        return SizedBox(
          height: calculatedHeight,
          width: maxWidth,
          child: CustomPaint(
            painter: painter,
          ),
        );
      },
    );
  }
}
