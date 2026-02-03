// FASE 1 WIDGETS - STILE SOFASCORE
// lib/widgets/player_performance_widgets.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

// ========================================
// 1. GRAFICO RADAR PERFORMANCE
// ========================================
class RadarPerformanceWidget extends StatefulWidget {
  final Color teamColor;
  final bool isDark;
  final String playerName;

  const RadarPerformanceWidget({
    Key? key,
    required this.teamColor,
    required this.isDark,
    required this.playerName,
  }) : super(key: key);

  @override
  State<RadarPerformanceWidget> createState() => _RadarPerformanceWidgetState();
}

class _RadarPerformanceWidgetState extends State<RadarPerformanceWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.isDark ? Colors.grey[850]! : Colors.white,
            widget.isDark ? Colors.grey[900]! : Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.teamColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.teamColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header compatto
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.teamColor.withOpacity(0.1),
                  widget.teamColor.withOpacity(0.05),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.teamColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.radar,
                    color: widget.teamColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Performance Radar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.teamColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Live',
                    style: TextStyle(
                      color: widget.teamColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Radar Chart più piccolo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 220,
                    maxWidth: 220,
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(
                      painter: RadarChartPainter(
                        teamColor: widget.teamColor,
                        isDark: widget.isDark,
                        animationValue: _animation.value,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Legenda compatta
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
            child: Wrap(
              spacing: 10,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _buildLegendItem('Attacco', 85, Colors.red[400]!),
                _buildLegendItem('Difesa', 70, Colors.blue[400]!),
                _buildLegendItem('Passaggi', 90, Colors.green[400]!),
                _buildLegendItem('Tecnica', 80, Colors.orange[400]!),
                _buildLegendItem('Fisico', 75, Colors.purple[400]!),
                _buildLegendItem('Tattica', 82, Colors.teal[400]!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 3,
                spreadRadius: 0.5,
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '$label $value',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: widget.isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }
}

// Painter per Radar Chart
class RadarChartPainter extends CustomPainter {
  final Color teamColor;
  final bool isDark;
  final double animationValue;

  RadarChartPainter({
    required this.teamColor,
    required this.isDark,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 * 0.8;
    final categories = 6;

    // Dati giocatore (mock)
    final values = [85, 70, 90, 80, 75, 82];
    final colors = [
      Colors.red[400]!,
      Colors.blue[400]!,
      Colors.green[400]!,
      Colors.orange[400]!,
      Colors.purple[400]!,
      Colors.teal[400]!,
    ];

    // Griglia esagono
    _drawGrid(canvas, center, radius, categories);

    // Area giocatore
    _drawPlayerArea(canvas, center, radius, categories, values, animationValue);

    // Punti e valori
    _drawPoints(
        canvas, center, radius, categories, values, colors, animationValue);
  }

  void _drawGrid(Canvas canvas, Offset center, double radius, int categories) {
    final gridPaint = Paint()
      ..color =
          (isDark ? Colors.grey[700]! : Colors.grey[300]!).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // 5 livelli: 20%, 40%, 60%, 80%, 100%
    for (int level = 1; level <= 5; level++) {
      final levelRadius = radius * (level / 5);
      final path = Path();

      for (int i = 0; i <= categories; i++) {
        final angle = (i * 2 * math.pi / categories) - math.pi / 2;
        final x = center.dx + levelRadius * math.cos(angle);
        final y = center.dy + levelRadius * math.sin(angle);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, gridPaint);
    }

    // Linee radiali
    for (int i = 0; i < categories; i++) {
      final angle = (i * 2 * math.pi / categories) - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      canvas.drawLine(center, Offset(x, y), gridPaint);
    }
  }

  void _drawPlayerArea(Canvas canvas, Offset center, double radius,
      int categories, List<int> values, double animation) {
    final path = Path();

    for (int i = 0; i <= categories; i++) {
      final angle = (i * 2 * math.pi / categories) - math.pi / 2;
      final value = values[i % categories] / 100;
      final currentRadius = radius * value * animation;
      final x = center.dx + currentRadius * math.cos(angle);
      final y = center.dy + currentRadius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Riempimento con gradient
    final gradient = RadialGradient(
      colors: [
        teamColor.withOpacity(0.3 * animation),
        teamColor.withOpacity(0.1 * animation),
      ],
    );

    final paint = Paint()
      ..shader =
          gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    // Bordo
    final borderPaint = Paint()
      ..color = teamColor.withOpacity(0.8 * animation)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawPath(path, borderPaint);
  }

  void _drawPoints(Canvas canvas, Offset center, double radius, int categories,
      List<int> values, List<Color> colors, double animation) {
    for (int i = 0; i < categories; i++) {
      final angle = (i * 2 * math.pi / categories) - math.pi / 2;
      final value = values[i] / 100;
      final currentRadius = radius * value * animation;
      final x = center.dx + currentRadius * math.cos(angle);
      final y = center.dy + currentRadius * math.sin(angle);

      // Alone
      final glowPaint = Paint()
        ..color = colors[i].withOpacity(0.4 * animation)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(Offset(x, y), 8, glowPaint);

      // Punto
      final pointPaint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), 5 * animation, pointPaint);

      // Bordo bianco
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(Offset(x, y), 5 * animation, borderPaint);
    }
  }

  @override
  bool shouldRepaint(RadarChartPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}

// ========================================
// 2. TIMELINE EVENTI MATCH
// ========================================
class MatchTimelineWidget extends StatefulWidget {
  final Color teamColor;
  final bool isDark;
  final String playerName;

  const MatchTimelineWidget({
    Key? key,
    required this.teamColor,
    required this.isDark,
    required this.playerName,
  }) : super(key: key);

  @override
  State<MatchTimelineWidget> createState() => _MatchTimelineWidgetState();
}

class _MatchTimelineWidgetState extends State<MatchTimelineWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<Map<String, dynamic>> events = [
    {
      'minute': 15,
      'type': 'goal',
      'icon': Icons.sports_soccer,
      'label': 'GOL',
      'color': Colors.green
    },
    {
      'minute': 23,
      'type': 'assist',
      'icon': Icons.insights,
      'label': 'ASSIST',
      'color': Colors.blue
    },
    {
      'minute': 45,
      'type': 'shot',
      'icon': Icons.adjust,
      'label': 'Tiro',
      'color': Colors.orange
    },
    {
      'minute': 67,
      'type': 'yellow',
      'icon': Icons.square,
      'label': 'Ammonito',
      'color': Colors.yellow[700]
    },
    {
      'minute': 78,
      'type': 'key_pass',
      'icon': Icons.arrow_forward,
      'label': 'Passaggio chiave',
      'color': Colors.purple
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.isDark ? Colors.grey[850]! : Colors.white,
            widget.isDark ? Colors.grey[900]! : Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.teamColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.teamColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.teamColor.withOpacity(0.1),
                  widget.teamColor.withOpacity(0.05),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.teamColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.timeline,
                    color: widget.teamColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Timeline Match',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      '5 eventi chiave',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Timeline
          Padding(
            padding: const EdgeInsets.all(20),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Column(
                  children: [
                    // Linea temporale
                    _buildTimelineBar(),
                    const SizedBox(height: 30),
                    // Eventi
                    ...events.map((event) => _buildEventCard(event)).toList(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineBar() {
    return Column(
      children: [
        // Indicatori minuti
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildMinuteLabel("0'"),
            _buildMinuteLabel("30'"),
            _buildMinuteLabel("60'"),
            _buildMinuteLabel("90'"),
          ],
        ),
        const SizedBox(height: 8),
        // Barra
        Stack(
          children: [
            // Barra background
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Barra progress
            FractionallySizedBox(
              widthFactor: _animation.value,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.teamColor,
                      widget.teamColor.withOpacity(0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: widget.teamColor.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
            // Eventi sulla barra
            ...events.map((event) {
              final position = event['minute'] / 90;
              return Positioned(
                left: MediaQuery.of(context).size.width * 0.85 * position - 12,
                top: -6,
                child: AnimatedScale(
                  scale: _animation.value,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: event['color'],
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: (event['color'] as Color).withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildMinuteLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: widget.isDark ? Colors.white70 : Colors.black54,
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    return AnimatedOpacity(
      opacity: _animation.value,
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (event['color'] as Color).withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icona
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (event['color'] as Color).withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                event['icon'],
                color: event['color'],
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event['label'],
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: widget.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    'Minuto ${event['minute']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Minuto badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: event['color'],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${event['minute']}'",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========================================
// 3. BARRE STATISTICHE COLORATE
// ========================================
class ColoredStatsBarWidget extends StatefulWidget {
  final Color teamColor;
  final bool isDark;

  const ColoredStatsBarWidget({
    Key? key,
    required this.teamColor,
    required this.isDark,
  }) : super(key: key);

  @override
  State<ColoredStatsBarWidget> createState() => _ColoredStatsBarWidgetState();
}

class _ColoredStatsBarWidgetState extends State<ColoredStatsBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final List<Map<String, dynamic>> stats = [
    {'label': 'Passaggi riusciti', 'value': 87, 'icon': Icons.check_circle},
    {'label': 'Dribbling completati', 'value': 60, 'icon': Icons.sports},
    {'label': 'Duelli vinti', 'value': 75, 'icon': Icons.sports_martial_arts},
    {'label': 'Contrasti', 'value': 42, 'icon': Icons.block},
    {'label': 'Intercetti', 'value': 80, 'icon': Icons.pan_tool},
    {'label': 'Precisione tiri', 'value': 55, 'icon': Icons.adjust},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.isDark ? Colors.grey[850]! : Colors.white,
            widget.isDark ? Colors.grey[900]! : Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.teamColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.teamColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.teamColor.withOpacity(0.1),
                  widget.teamColor.withOpacity(0.05),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.teamColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.bar_chart,
                    color: widget.teamColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance Stats',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      'Metriche dettagliate',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Stats bars
          Padding(
            padding: const EdgeInsets.all(20),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Column(
                  children: stats
                      .map((stat) => _buildStatBar(
                            stat['label'],
                            stat['value'],
                            stat['icon'],
                          ))
                      .toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, int value, IconData icon) {
    final color = _getColorForValue(value);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label e valore
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.5), width: 1),
                ),
                child: Text(
                  '$value%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Barra
          Stack(
            children: [
              // Background
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              // Progress
              FractionallySizedBox(
                widthFactor: (value / 100) * _animation.value,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorForValue(int value) {
    if (value >= 75) return Colors.green[500]!;
    if (value >= 50) return Colors.yellow[700]!;
    if (value >= 25) return Colors.orange[500]!;
    return Colors.red[500]!;
  }
}
