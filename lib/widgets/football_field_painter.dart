// lib/widgets/football_field_painter.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

class FootballFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
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
      Rect.fromLTWH(0, 0, size.width, size.height),
      linePaint,
    );

    // LINEA CENTRALE ORIZZONTALE
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      linePaint,
    );

    // CERCHIO CENTRALE
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final centerCircleRadius = size.width * 0.12;
    canvas.drawCircle(Offset(centerX, centerY), centerCircleRadius, linePaint);

    // PUNTO CENTRALE
    final centerDotPaint = Paint()
      ..color = Colors.grey[800]!.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), 2, centerDotPaint);

    // AREA DI RIGORE SUPERIORE (porta in alto)
    final penaltyAreaWidth = size.width * 0.4;
    final penaltyAreaHeight = size.height * 0.18;
    final penaltyAreaLeft = (size.width - penaltyAreaWidth) / 2;

    canvas.drawRect(
      Rect.fromLTWH(penaltyAreaLeft, 0, penaltyAreaWidth, penaltyAreaHeight),
      linePaint,
    );

    // AREA DI RIGORE INFERIORE (porta in basso)
    canvas.drawRect(
      Rect.fromLTWH(
        penaltyAreaLeft,
        size.height - penaltyAreaHeight,
        penaltyAreaWidth,
        penaltyAreaHeight,
      ),
      linePaint,
    );

    // AREA DI PORTA SUPERIORE (area piccola)
    final goalAreaWidth = size.width * 0.2;
    final goalAreaHeight = size.height * 0.08;
    final goalAreaLeft = (size.width - goalAreaWidth) / 2;

    canvas.drawRect(
      Rect.fromLTWH(goalAreaLeft, 0, goalAreaWidth, goalAreaHeight),
      linePaint,
    );

    // AREA DI PORTA INFERIORE (area piccola)
    canvas.drawRect(
      Rect.fromLTWH(
        goalAreaLeft,
        size.height - goalAreaHeight,
        goalAreaWidth,
        goalAreaHeight,
      ),
      linePaint,
    );

    // PUNTO DI RIGORE SUPERIORE
    final penaltySpotTop = penaltyAreaHeight * 0.65;
    canvas.drawCircle(Offset(centerX, penaltySpotTop), 2, centerDotPaint);

    // PUNTO DI RIGORE INFERIORE
    final penaltySpotBottom = size.height - (penaltyAreaHeight * 0.65);
    canvas.drawCircle(Offset(centerX, penaltySpotBottom), 2, centerDotPaint);

    // ARCO DI RIGORE SUPERIORE (mezzaluna!)
    _drawPenaltyArc(
      canvas,
      Offset(centerX, penaltyAreaHeight),
      centerCircleRadius,
      linePaint,
      true, // arc superiore
    );

    // ARCO DI RIGORE INFERIORE (mezzaluna!)
    _drawPenaltyArc(
      canvas,
      Offset(centerX, size.height - penaltyAreaHeight),
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
