// lib/widgets/stats_chart_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class StatsChartWidget extends StatefulWidget {
  final Map<String, double> homeStats;
  final Map<String, double> awayStats;
  final String homeTeamName;
  final String awayTeamName;
  final Color homeColor;
  final Color awayColor;

  const StatsChartWidget({
    Key? key,
    required this.homeStats,
    required this.awayStats,
    required this.homeTeamName,
    required this.awayTeamName,
    this.homeColor = Colors.blue,
    this.awayColor = Colors.red,
  }) : super(key: key);

  @override
  State<StatsChartWidget> createState() => _StatsChartWidgetState();
}

class _StatsChartWidgetState extends State<StatsChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedStat = 'Possesso palla';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Selezione tipo di grafico
        Container(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _buildChartTypeChip('Radar', Icons.radar, true, theme),
              _buildChartTypeChip('Barre', Icons.bar_chart, false, theme),
              _buildChartTypeChip('Torta', Icons.pie_chart, false, theme),
              _buildChartTypeChip('Linee', Icons.show_chart, false, theme),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Grafico Radar
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: CustomPaint(
            size: const Size(double.infinity, 300),
            painter: RadarChartPainter(
              homeStats: widget.homeStats,
              awayStats: widget.awayStats,
              homeColor: widget.homeColor,
              awayColor: widget.awayColor,
              animation: _animationController,
              isDark: isDark,
            ),
          ),
        )
            .animate()
            .scale(
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
            )
            .fadeIn(),

        // Legenda
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(widget.homeTeamName, widget.homeColor),
              const SizedBox(width: 32),
              _buildLegendItem(widget.awayTeamName, widget.awayColor),
            ],
          ),
        ),

        // Statistiche dettagliate
        Container(
          height: 200,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.homeStats.length,
            itemBuilder: (context, index) {
              final key = widget.homeStats.keys.elementAt(index);
              final homeValue = widget.homeStats[key]!;
              final awayValue = widget.awayStats[key]!;

              return _buildDetailedStat(
                key,
                homeValue,
                awayValue,
                theme,
                isDark,
              )
                  .animate()
                  .slideX(
                    begin: 0.2,
                    end: 0,
                    delay: Duration(milliseconds: index * 50),
                  )
                  .fadeIn();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChartTypeChip(
      String label, IconData icon, bool isSelected, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        selectedColor: theme.primaryColor,
        onSelected: (selected) {
          // Cambia tipo di grafico
        },
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStat(
    String label,
    double homeValue,
    double awayValue,
    ThemeData theme,
    bool isDark,
  ) {
    final total = homeValue + awayValue;
    final homePercentage = total > 0 ? (homeValue / total) : 0.5;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                homeValue.toStringAsFixed(0),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.homeColor,
                ),
              ),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: 8,
                      width: (MediaQuery.of(context).size.width - 120) *
                          homePercentage,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [widget.homeColor, widget.awayColor],
                          stops: [homePercentage, homePercentage],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                awayValue.toStringAsFixed(0),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.awayColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Painter per il grafico Radar
class RadarChartPainter extends CustomPainter {
  final Map<String, double> homeStats;
  final Map<String, double> awayStats;
  final Color homeColor;
  final Color awayColor;
  final Animation<double> animation;
  final bool isDark;

  RadarChartPainter({
    required this.homeStats,
    required this.awayStats,
    required this.homeColor,
    required this.awayColor,
    required this.animation,
    required this.isDark,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 20;
    final angle = (math.pi * 2) / homeStats.length;

    // Disegna griglia
    final gridPaint = Paint()
      ..color = isDark ? Colors.white24 : Colors.black26
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Cerchi concentrici
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, radius * i / 5, gridPaint);
    }

    // Linee radiali
    for (int i = 0; i < homeStats.length; i++) {
      final x = center.dx + radius * math.cos(angle * i - math.pi / 2);
      final y = center.dy + radius * math.sin(angle * i - math.pi / 2);
      canvas.drawLine(center, Offset(x, y), gridPaint);

      // Etichette
      final labelOffset = Offset(
        center.dx + (radius + 20) * math.cos(angle * i - math.pi / 2),
        center.dy + (radius + 20) * math.sin(angle * i - math.pi / 2),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: homeStats.keys
              .elementAt(i)
              .substring(0, math.min(3, homeStats.keys.elementAt(i).length)),
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(labelOffset.dx - textPainter.width / 2,
            labelOffset.dy - textPainter.height / 2),
      );
    }

    // Disegna poligoni dati
    _drawDataPolygon(canvas, center, radius, angle, homeStats, homeColor, 0.3);
    _drawDataPolygon(canvas, center, radius, angle, awayStats, awayColor, 0.3);
  }

  void _drawDataPolygon(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    Map<String, double> stats,
    Color color,
    double opacity,
  ) {
    final paint = Paint()
      ..color = color.withOpacity(opacity * animation.value)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    for (int i = 0; i < stats.length; i++) {
      final value = stats.values.elementAt(i);
      final normalizedValue = value / 100; // Assumendo valori 0-100
      final r = radius * normalizedValue * animation.value;
      final x = center.dx + r * math.cos(angle * i - math.pi / 2);
      final y = center.dy + r * math.sin(angle * i - math.pi / 2);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);

    // Punti sui vertici
    for (int i = 0; i < stats.length; i++) {
      final value = stats.values.elementAt(i);
      final normalizedValue = value / 100;
      final r = radius * normalizedValue * animation.value;
      final x = center.dx + r * math.cos(angle * i - math.pi / 2);
      final y = center.dy + r * math.sin(angle * i - math.pi / 2);

      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
