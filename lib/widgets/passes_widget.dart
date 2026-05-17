import 'package:flutter/material.dart';
import '../../utils/l10n_helper.dart';

/// Modello dati per le statistiche dei passaggi
class PassesData {
  final int accuratePasses;
  final int throwIns;
  final int finalThirdEntries;
  final int finalThirdPasses;
  final int finalThirdTotal;
  final int longBalls;
  final int longBallsTotal;
  final int crosses;
  final int crossesTotal;
  final int leftZonePercentage;
  final int centerZonePercentage;
  final int rightZonePercentage;

  PassesData({
    required this.accuratePasses,
    required this.throwIns,
    required this.finalThirdEntries,
    required this.finalThirdPasses,
    required this.finalThirdTotal,
    required this.longBalls,
    required this.longBallsTotal,
    required this.crosses,
    required this.crossesTotal,
    required this.leftZonePercentage,
    required this.centerZonePercentage,
    required this.rightZonePercentage,
  });
}

/// Widget principale per la visualizzazione delle statistiche dei passaggi
class PassesWidget extends StatelessWidget {
  final PassesData homeTeam;
  final PassesData awayTeam;

  const PassesWidget({
    Key? key,
    required this.homeTeam,
    required this.awayTeam,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              tr(context, 'Passaggi'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
          ),

          // Heatmap Campo - ANCORA PIÙ GRANDE
          Container(
            height: 600, // ✅ MOLTO PIÙ ALTO! (da 520 → 600px) +15%
            margin: const EdgeInsets.symmetric(horizontal: 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CustomPaint(
                painter: FieldHeatmapPainter(
                  leftPercentage: homeTeam.leftZonePercentage,
                  centerPercentage: homeTeam.centerZonePercentage +
                      awayTeam.centerZonePercentage,
                  rightPercentage: awayTeam.rightZonePercentage,
                ),
                child: Stack(
                  children: [
                    // Label sinistra
                    if (homeTeam.leftZonePercentage > 0)
                      Positioned(
                        left: 90,
                        top: 285,
                        child: _buildPercentageLabel(
                            '${homeTeam.leftZonePercentage}%'),
                      ),
                    // Label centro
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 285,
                      child: Center(
                        child: _buildPercentageLabel(
                          '${homeTeam.centerZonePercentage + awayTeam.centerZonePercentage}%',
                        ),
                      ),
                    ),
                    // Label destra
                    if (awayTeam.rightZonePercentage > 0)
                      Positioned(
                        right: 90,
                        top: 285,
                        child: _buildPercentageLabel(
                            '${awayTeam.rightZonePercentage}%'),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Bar Comparisons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildBarComparison(
                  tr(context, 'Passaggi precisi'),
                  homeTeam.accuratePasses,
                  awayTeam.accuratePasses,
                ),
                const SizedBox(height: 16),
                _buildBarComparison(
                  'Rimesse laterali',
                  homeTeam.throwIns,
                  awayTeam.throwIns,
                ),
                SizedBox(height: 16),
                _buildBarComparison(
                  'Ingressi terzo offensivo',
                  homeTeam.finalThirdEntries,
                  awayTeam.finalThirdEntries,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Circular Progress Statistics
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCircularStat(
                  'Terzo offensivo',
                  homeTeam.finalThirdPasses,
                  homeTeam.finalThirdTotal,
                  awayTeam.finalThirdPasses,
                  awayTeam.finalThirdTotal,
                ),
                _buildCircularStat(
                  'Palle lunghe',
                  homeTeam.longBalls,
                  homeTeam.longBallsTotal,
                  awayTeam.longBalls,
                  awayTeam.longBallsTotal,
                ),
                _buildCircularStat(
                  'Cross',
                  homeTeam.crosses,
                  homeTeam.crossesTotal,
                  awayTeam.crosses,
                  awayTeam.crossesTotal,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPercentageLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildBarComparison(String label, int homeValue, int awayValue) {
    final total = homeValue + awayValue;
    final homePercentage = total > 0 ? homeValue / total : 0.5;
    final awayPercentage = total > 0 ? awayValue / total : 0.5;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              homeValue.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            Text(
              awayValue.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: Row(
              children: [
                Expanded(
                  flex: (homePercentage * 100).round(),
                  child: Container(
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                Expanded(
                  flex: (awayPercentage * 100).round(),
                  child: Container(
                    color: const Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircularStat(
    String label,
    int homeValue,
    int homeTotal,
    int awayValue,
    int awayTotal,
  ) {
    final homePercentage = homeTotal > 0 ? homeValue / homeTotal : 0.0;
    final awayPercentage = awayTotal > 0 ? awayValue / awayTotal : 0.0;

    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Home team
              Column(
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(70, 70),
                          painter: CircularProgressPainter(
                            percentage: homePercentage,
                            color: const Color(0xFF4CAF50),
                          ),
                        ),
                        Text(
                          '${(homePercentage * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$homeValue/$homeTotal',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              // Away team
              Column(
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(70, 70),
                          painter: CircularProgressPainter(
                            percentage: awayPercentage,
                            color: const Color(0xFF1565C0),
                          ),
                        ),
                        Text(
                          '${(awayPercentage * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$awayValue/$awayTotal',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Painter per l'heatmap del campo da calcio - COLORI MIGLIORATI
class FieldHeatmapPainter extends CustomPainter {
  final int leftPercentage;
  final int centerPercentage;
  final int rightPercentage;

  FieldHeatmapPainter({
    required this.leftPercentage,
    required this.centerPercentage,
    required this.rightPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ✅ COLORI CON GRADIENTE FORTE E DISTINGUIBILE
    // ── Palette verde unificata (= Attacco / Mappa Tiri) ──
    final veryLightYellow = const Color(0xFFE8F5E9); // verde chiarissimo
    final lightYellow = const Color(0xFFC8E6C9); // verde chiaro
    final mediumYellow = const Color(0xFFA5D6A7); // verde medio chiaro
    final darkYellow = const Color(0xFF81C784); // verde medio
    final veryDarkYellow = const Color(0xFF66BB6A); // verde scuro

    // Calcola intensità con gradiente più forte
    final leftIntensity = (leftPercentage / 40.0)
        .clamp(0.0, 1.0); // ✅ /40 invece di /50 per più contrasto
    final centerIntensity = (centerPercentage / 40.0).clamp(0.0, 1.0);
    final rightIntensity = (rightPercentage / 40.0).clamp(0.0, 1.0);

    // ✅ COLORI PIÙ DISTINGUIBILI
    Color leftColor;
    Color centerColor;
    Color rightColor;

    // Zona sinistra - Gradiente da molto chiaro a scuro
    if (leftIntensity < 0.3) {
      leftColor =
          Color.lerp(veryLightYellow, lightYellow, leftIntensity / 0.3)!;
    } else if (leftIntensity < 0.7) {
      leftColor =
          Color.lerp(lightYellow, mediumYellow, (leftIntensity - 0.3) / 0.4)!;
    } else {
      leftColor =
          Color.lerp(mediumYellow, darkYellow, (leftIntensity - 0.7) / 0.3)!;
    }

    // Zona centrale - Usa colori diversi per distinguerla
    if (centerIntensity < 0.3) {
      centerColor =
          Color.lerp(lightYellow, mediumYellow, centerIntensity / 0.3)!;
    } else if (centerIntensity < 0.7) {
      centerColor =
          Color.lerp(mediumYellow, darkYellow, (centerIntensity - 0.3) / 0.4)!;
    } else {
      centerColor = Color.lerp(
          darkYellow, veryDarkYellow, (centerIntensity - 0.7) / 0.3)!;
    }

    // Zona destra - Gradiente come sinistra
    if (rightIntensity < 0.3) {
      rightColor =
          Color.lerp(veryLightYellow, lightYellow, rightIntensity / 0.3)!;
    } else if (rightIntensity < 0.7) {
      rightColor =
          Color.lerp(lightYellow, mediumYellow, (rightIntensity - 0.3) / 0.4)!;
    } else {
      rightColor =
          Color.lerp(mediumYellow, darkYellow, (rightIntensity - 0.7) / 0.3)!;
    }

    final zoneWidth = size.width / 3;

    // Sfondo colorato
    canvas.drawRect(
      Rect.fromLTWH(0, 0, zoneWidth, size.height),
      Paint()..color = leftColor,
    );

    canvas.drawRect(
      Rect.fromLTWH(zoneWidth, 0, zoneWidth, size.height),
      Paint()..color = centerColor,
    );

    canvas.drawRect(
      Rect.fromLTWH(zoneWidth * 2, 0, zoneWidth, size.height),
      Paint()..color = rightColor,
    );

    // ✅ LINEE BIANCHE - MOLTO SPESSE
    final thickLinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0;

    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    // Bordo campo
    canvas.drawRect(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      thickLinePaint,
    );

    // Linea centrale
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      thickLinePaint,
    );

    // Cerchio di centrocampo
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final circleRadius = size.height * 0.30;

    canvas.drawCircle(
      Offset(centerX, centerY),
      circleRadius,
      linePaint,
    );

    // Punto centrale
    canvas.drawCircle(
      Offset(centerX, centerY),
      7,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // ✅ AREE DI RIGORE - MOLTO GRANDI
    final penaltyWidth = size.width * 0.23; // ✅ 23% (da 22%)
    final penaltyHeight = size.height * 0.66; // ✅ 66% (da 65%)
    final penaltyY = (size.height - penaltyHeight) / 2;

    // Area sinistra
    canvas.drawRect(
      Rect.fromLTWH(0, penaltyY, penaltyWidth, penaltyHeight),
      linePaint,
    );

    // Area destra
    canvas.drawRect(
      Rect.fromLTWH(
        size.width - penaltyWidth,
        penaltyY,
        penaltyWidth,
        penaltyHeight,
      ),
      linePaint,
    );

    // Area piccola
    final smallBoxWidth = size.width * 0.085; // ✅ 8.5%
    final smallBoxHeight = size.height * 0.33; // ✅ 33%
    final smallBoxY = (size.height - smallBoxHeight) / 2;

    canvas.drawRect(
      Rect.fromLTWH(0, smallBoxY, smallBoxWidth, smallBoxHeight),
      linePaint,
    );

    canvas.drawRect(
      Rect.fromLTWH(
        size.width - smallBoxWidth,
        smallBoxY,
        smallBoxWidth,
        smallBoxHeight,
      ),
      linePaint,
    );

    // Punti di rigore
    final penaltySpotX = penaltyWidth * 0.48;

    canvas.drawCircle(
      Offset(penaltySpotX, centerY),
      6,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      Offset(size.width - penaltySpotX, centerY),
      6,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // ✅ SEMICERCHI - COLLEGATI
    final arcRadius = penaltyHeight * 0.24;

    // Semicerchio sinistro
    final leftArcPath = Path();
    leftArcPath.moveTo(penaltyWidth, centerY - arcRadius);
    leftArcPath.arcToPoint(
      Offset(penaltyWidth, centerY + arcRadius),
      radius: Radius.circular(arcRadius),
      clockwise: true,
    );
    canvas.drawPath(leftArcPath, linePaint);

    // Semicerchio destro
    final rightArcPath = Path();
    rightArcPath.moveTo(size.width - penaltyWidth, centerY - arcRadius);
    rightArcPath.arcToPoint(
      Offset(size.width - penaltyWidth, centerY + arcRadius),
      radius: Radius.circular(arcRadius),
      clockwise: false,
    );
    canvas.drawPath(rightArcPath, linePaint);
  }

  @override
  bool shouldRepaint(FieldHeatmapPainter oldDelegate) {
    return oldDelegate.leftPercentage != leftPercentage ||
        oldDelegate.centerPercentage != centerPercentage ||
        oldDelegate.rightPercentage != rightPercentage;
  }
}

/// Painter per i progress circolari
class CircularProgressPainter extends CustomPainter {
  final double percentage;
  final Color color;

  CircularProgressPainter({
    required this.percentage,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Cerchio di sfondo
    final backgroundPaint = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - 4, backgroundPaint);

    // Arco di progresso
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.14159 * percentage;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -3.14159 / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.percentage != percentage;
  }
}
