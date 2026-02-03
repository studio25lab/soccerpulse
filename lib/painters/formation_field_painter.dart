// CAMPO FORMAZIONI CON LINEA CENTRALE
// Entrambe le squadre orientate verso l'alto (porta in alto)
// lib/painters/formation_field_painter.dart

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

// ========================================
// CAMPO FORMAZIONI - ORIENTAMENTO FISSO
// Proporzioni: 1.5:1 (105m x 68m)
// CON linea centrale orizzontale
// SENZA porta in basso (squadre orientate sempre verso l'alto)
// ========================================
class FormationFieldPainter extends CustomPainter {
  final bool isDark;

  FormationFieldPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // Calcola dimensioni corrette con proporzioni 1.5:1
    final fieldHeight = size.height * 0.95;
    final fieldWidth = fieldHeight * 1.5;

    // Centra il campo
    final offsetX = (size.width - fieldWidth) / 2;
    final offsetY = (size.height - fieldHeight) / 2;

    // 1. Erba con strisce verticali
    _drawGrass(canvas, offsetX, offsetY, fieldWidth, fieldHeight);

    // 2. Linee campo con linea centrale
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

    // 1. BORDO CAMPO
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            x + margin, y + margin, width - margin * 2, height - margin * 2),
        const Radius.circular(6),
      ),
      linePaint,
    );

    // 2. LINEA CENTRALE ORIZZONTALE
    final centerY = y + height / 2;
    canvas.drawLine(
      Offset(x + margin, centerY),
      Offset(x + width - margin, centerY),
      linePaint,
    );

    // 3. AREA RIGORE TOP (porta in alto)
    final penaltyWidth = width * 0.6;
    final penaltyHeight = height * 0.18;
    final penaltyX = x + (width - penaltyWidth) / 2;

    canvas.drawRect(
      Rect.fromLTWH(penaltyX, y + margin, penaltyWidth, penaltyHeight),
      linePaint,
    );

    // 4. AREA PICCOLA TOP
    final smallWidth = width * 0.35;
    final smallHeight = height * 0.09;
    final smallX = x + (width - smallWidth) / 2;

    canvas.drawRect(
      Rect.fromLTWH(smallX, y + margin, smallWidth, smallHeight),
      linePaint,
    );

    // 5. PORTA TOP
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

    // 6. AREA RIGORE BOTTOM (porta propria in basso)
    canvas.drawRect(
      Rect.fromLTWH(penaltyX, y + height - margin - penaltyHeight, penaltyWidth,
          penaltyHeight),
      linePaint,
    );

    // 7. AREA PICCOLA BOTTOM
    canvas.drawRect(
      Rect.fromLTWH(
          smallX, y + height - margin - smallHeight, smallWidth, smallHeight),
      linePaint,
    );

    // 8. PORTA BOTTOM
    canvas.drawLine(
      Offset(goalX, y + height - margin),
      Offset(goalX + goalWidth, y + height - margin),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========================================
// WIDGET HELPER CON AUTO-SIZING
// ========================================
class FormationFieldWidget extends StatelessWidget {
  final bool isDark;
  final double? height;

  const FormationFieldWidget({
    Key? key,
    required this.isDark,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final calculatedHeight = height ?? (maxWidth / 1.5);

        return SizedBox(
          height: calculatedHeight,
          width: maxWidth,
          child: CustomPaint(
            painter: FormationFieldPainter(isDark: isDark),
          ),
        );
      },
    );
  }
}
