// DEEP STATS WIDGETS - Da aggiungere nelle schermate giocatore
// lib/widgets/deep_stats_widgets.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

class DeepStatsSection extends StatelessWidget {
  final String playerName;
  final bool isDark;

  const DeepStatsSection({
    Key? key,
    required this.playerName,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Deep Stats', Icons.analytics_outlined),
        const SizedBox(height: 16),
        _buildExpectedGoalsCard(),
        const SizedBox(height: 16),
        _buildExpectedAssistsCard(),
        const SizedBox(height: 16),
        _buildPassCompletionZones(),
        const SizedBox(height: 16),
        _buildDefensiveActionsMap(),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue[700], size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // 1. EXPECTED GOALS (xG)
  Widget _buildExpectedGoalsCard() {
    final xG = 2.8; // Mock data
    final actualGoals = 3;
    final difference = actualGoals - xG;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple[700]!,
            Colors.purple[500]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.sports_soccer,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Expected Goals (xG)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'xG',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      xG.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 2,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Goal Effettivi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      actualGoals.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: difference > 0
                  ? Colors.green.withOpacity(0.2)
                  : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: difference > 0 ? Colors.green : Colors.red,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  difference > 0 ? Icons.trending_up : Icons.trending_down,
                  color: difference > 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  difference > 0
                      ? '+${difference.toStringAsFixed(2)} rispetto all\'xG'
                      : '${difference.toStringAsFixed(2)} rispetto all\'xG',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: difference > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sta sovraperformando le aspettative! 🔥',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // 2. EXPECTED ASSISTS (xA)
  Widget _buildExpectedAssistsCard() {
    final xA = 1.5; // Mock data
    final actualAssists = 2;
    final difference = actualAssists - xA;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal[700]!,
            Colors.teal[500]!,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.assist_walker,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Expected Assists (xA)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'xA',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      xA.toStringAsFixed(2),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 2,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assist Effettivi',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      actualAssists.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: difference > 0
                  ? Colors.green.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: difference > 0 ? Colors.green : Colors.orange,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  difference > 0 ? Icons.trending_up : Icons.trending_flat,
                  color: difference > 0 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  difference > 0
                      ? '+${difference.toStringAsFixed(2)} rispetto all\'xA'
                      : '${difference.toStringAsFixed(2)} rispetto all\'xA',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: difference > 0 ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. PASS COMPLETION BY ZONE
  Widget _buildPassCompletionZones() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_on, color: Colors.blue[700]),
              SizedBox(width: 8),
              Text(
                'Precisione Passaggi per Zona',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: CustomPaint(
              painter: PassCompletionZonesPainter(isDark: isDark),
              child: Container(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem(Colors.green, '80%+', 'Ottimo'),
              _buildLegendItem(Colors.orange, '60-79%', 'Buono'),
              _buildLegendItem(Colors.red, '<60%', 'Da migliorare'),
            ],
          ),
        ],
      ),
    );
  }

  // 4. DEFENSIVE ACTIONS MAP
  Widget _buildDefensiveActionsMap() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield, color: Colors.red[700]),
              SizedBox(width: 8),
              Text(
                'Mappa Azioni Difensive',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: CustomPaint(
              painter: DefensiveActionsMapPainter(isDark: isDark),
              child: Container(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDefensiveStat('Tackle', 12, Icons.sports_kabaddi),
              _buildDefensiveStat('Intercetti', 8, Icons.block),
              _buildDefensiveStat('Clearance', 5, Icons.clear_all),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String range, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              range,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDefensiveStat(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.red[700]),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// PAINTER: Pass Completion Zones
class PassCompletionZonesPainter extends CustomPainter {
  final bool isDark;

  PassCompletionZonesPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final fieldPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Campo
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      fieldPaint,
    );

    // Dividi campo in 9 zone (3x3)
    final zoneWidth = size.width / 3;
    final zoneHeight = size.height / 3;

    // Linee verticali
    canvas.drawLine(
      Offset(zoneWidth, 0),
      Offset(zoneWidth, size.height),
      linePaint,
    );
    canvas.drawLine(
      Offset(zoneWidth * 2, 0),
      Offset(zoneWidth * 2, size.height),
      linePaint,
    );

    // Linee orizzontali
    canvas.drawLine(
      Offset(0, zoneHeight),
      Offset(size.width, zoneHeight),
      linePaint,
    );
    canvas.drawLine(
      Offset(0, zoneHeight * 2),
      Offset(size.width, zoneHeight * 2),
      linePaint,
    );

    // Mock data: percentuali per zona
    final zones = [
      [92, 85, 78],
      [88, 91, 82],
      [75, 80, 87],
    ];

    // Disegna zone colorate
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final percentage = zones[row][col];
        Color zoneColor;

        if (percentage >= 80) {
          zoneColor = Colors.green.withOpacity(0.4);
        } else if (percentage >= 60) {
          zoneColor = Colors.orange.withOpacity(0.4);
        } else {
          zoneColor = Colors.red.withOpacity(0.4);
        }

        final zonePaint = Paint()
          ..color = zoneColor
          ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromLTWH(
            col * zoneWidth,
            row * zoneHeight,
            zoneWidth,
            zoneHeight,
          ),
          zonePaint,
        );

        // Testo percentuale
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$percentage%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            col * zoneWidth + (zoneWidth - textPainter.width) / 2,
            row * zoneHeight + (zoneHeight - textPainter.height) / 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// PAINTER: Defensive Actions Map
class DefensiveActionsMapPainter extends CustomPainter {
  final bool isDark;

  DefensiveActionsMapPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final fieldPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Campo
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      fieldPaint,
    );

    // Linea mediana
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      linePaint,
    );

    // Cerchio centrale
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      30,
      linePaint,
    );

    // Mock data: azioni difensive
    final random = math.Random(42);
    final tackleColor = Colors.red[700]!;
    final interceptColor = Colors.orange[700]!;
    final clearanceColor = Colors.yellow[700]!;

    // Tackle (cerchi rossi)
    for (int i = 0; i < 8; i++) {
      final x = size.width * (0.3 + random.nextDouble() * 0.4);
      final y = size.height * (0.2 + random.nextDouble() * 0.6);

      canvas.drawCircle(
        Offset(x, y),
        8,
        Paint()
          ..color = tackleColor.withOpacity(0.7)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        Offset(x, y),
        8,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Intercetti (triangoli arancioni)
    for (int i = 0; i < 6; i++) {
      final x = size.width * (0.2 + random.nextDouble() * 0.6);
      final y = size.height * (0.1 + random.nextDouble() * 0.8);

      final path = Path()
        ..moveTo(x, y - 8)
        ..lineTo(x - 7, y + 6)
        ..lineTo(x + 7, y + 6)
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..color = interceptColor.withOpacity(0.7)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Clearance (quadrati gialli)
    for (int i = 0; i < 4; i++) {
      final x = size.width * (0.1 + random.nextDouble() * 0.3);
      final y = size.height * (0.2 + random.nextDouble() * 0.6);

      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 14, height: 14),
        Paint()
          ..color = clearanceColor.withOpacity(0.7)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: 14, height: 14),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
