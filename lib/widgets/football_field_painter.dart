// lib/widgets/football_field_painter.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

class FootballFieldPainter extends CustomPainter {
  final double inset;

  FootballFieldPainter({this.inset = 10});

  @override
  void paint(Canvas canvas, Size size) {
    final safeInset = inset.clamp(0.0, size.shortestSide / 4);
    final fieldLeft = safeInset;
    final fieldTop = safeInset;
    final fieldWidth = size.width - safeInset * 2;
    final fieldHeight = size.height - safeInset * 2;

    // BACKGROUND NERO PURO
    final backgroundPaint = Paint()
      ..color = const Color(0xFF1E1E1E) // Nero puro
      ..style = PaintingStyle.fill;

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // LINEE GRIGIE APPENA VISIBILI
    final linePaint = Paint()
      ..color = Colors.grey[800]!
          .withOpacity(0.08) // Grigio scuro con opacity bassissima
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // BORDO ESTERNO
    canvas.drawRect(
      Rect.fromLTWH(fieldLeft, fieldTop, fieldWidth, fieldHeight),
      linePaint,
    );

    // LINEA CENTRALE ORIZZONTALE
    canvas.drawLine(
      Offset(fieldLeft, fieldTop + fieldHeight / 2),
      Offset(fieldLeft + fieldWidth, fieldTop + fieldHeight / 2),
      linePaint,
    );

    // CERCHIO CENTRALE
    final centerX = fieldLeft + fieldWidth / 2;
    final centerY = fieldTop + fieldHeight / 2;
    final centerCircleRadius = fieldWidth * 0.12;
    canvas.drawCircle(Offset(centerX, centerY), centerCircleRadius, linePaint);

    // PUNTO CENTRALE
    final centerDotPaint = Paint()
      ..color = Colors.grey[800]!.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 2, centerDotPaint);

    // AREA DI RIGORE SUPERIORE (porta in alto)
    final penaltyAreaWidth = fieldWidth * 0.4;
    final penaltyAreaHeight = fieldHeight * 0.18;
    final penaltyAreaLeft = fieldLeft + (fieldWidth - penaltyAreaWidth) / 2;

    canvas.drawRect(
      Rect.fromLTWH(
          penaltyAreaLeft, fieldTop, penaltyAreaWidth, penaltyAreaHeight),
      linePaint,
    );

    // AREA DI RIGORE INFERIORE (porta in basso)
    canvas.drawRect(
      Rect.fromLTWH(
        penaltyAreaLeft,
        fieldTop + fieldHeight - penaltyAreaHeight,
        penaltyAreaWidth,
        penaltyAreaHeight,
      ),
      linePaint,
    );

    // AREA DI PORTA SUPERIORE (area piccola)
    final goalAreaWidth = fieldWidth * 0.2;
    final goalAreaHeight = fieldHeight * 0.08;
    final goalAreaLeft = fieldLeft + (fieldWidth - goalAreaWidth) / 2;

    canvas.drawRect(
      Rect.fromLTWH(goalAreaLeft, fieldTop, goalAreaWidth, goalAreaHeight),
      linePaint,
    );

    // AREA DI PORTA INFERIORE (area piccola)
    canvas.drawRect(
      Rect.fromLTWH(
        goalAreaLeft,
        fieldTop + fieldHeight - goalAreaHeight,
        goalAreaWidth,
        goalAreaHeight,
      ),
      linePaint,
    );

    // PUNTO DI RIGORE SUPERIORE
    final penaltySpotTop = penaltyAreaHeight * 0.65;
    canvas.drawCircle(
        Offset(centerX, fieldTop + penaltySpotTop), 2, centerDotPaint);

    // PUNTO DI RIGORE INFERIORE
    final penaltySpotBottom = fieldTop + fieldHeight - (penaltyAreaHeight * 0.65);
    canvas.drawCircle(Offset(centerX, penaltySpotBottom), 2, centerDotPaint);

    // ARCO DI RIGORE SUPERIORE (mezzaluna!)
    _drawPenaltyArc(
      canvas,
      Offset(centerX, fieldTop + penaltyAreaHeight),
      centerCircleRadius,
      linePaint,
      true, // arc superiore
    );

    // ARCO DI RIGORE INFERIORE (mezzaluna!)
    _drawPenaltyArc(
      canvas,
      Offset(centerX, fieldTop + fieldHeight - penaltyAreaHeight),
      centerCircleRadius,
      linePaint,
      false, // arc inferiore
    );
  }

  void _drawPenaltyArc(
    Canvas canvas,
    Offset center,
    double radius,
    Paint paint,
    bool isTop,
  ) {
    // Disegno l'arco (mezzaluna) usando un Path
    final path = Path();

    // Angolo iniziale e finale per l'arco
    final startAngle = isTop ? math.pi * 0.25 : -math.pi * 0.75;
    final sweepAngle = math.pi * 0.5;

    // Creo l'arco
    final rect = Rect.fromCircle(center: center, radius: radius);
    path.addArc(rect, startAngle, sweepAngle);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
