import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Widget heatmap completo con tutte le funzionalità avanzate
class HeatmapWidget extends StatefulWidget {
  final bool isHome;
  final String homeTeamName;
  final String awayTeamName;

  const HeatmapWidget({
    Key? key,
    required this.isHome,
    required this.homeTeamName,
    required this.awayTeamName,
  }) : super(key: key);

  @override
  State<HeatmapWidget> createState() => _HeatmapWidgetState();
}

class _HeatmapWidgetState extends State<HeatmapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  String _periodFilter = 'all'; // all, first_half, second_half
  bool _showComparison = false;
  bool _showZoneStats = true;
  Set<int> _selectedIntensities = {0, 1, 2, 3, 4}; // Tutti attivi

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HeatmapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isHome != widget.isHome) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con controlli
          _buildHeader(isDark),

          // Filtri Periodo
          _buildPeriodFilters(isDark),

          const SizedBox(height: 16),

          // Campo/i Heatmap
          _showComparison
              ? _buildComparisonView(isDark)
              : _buildSingleView(isDark),

          const SizedBox(height: 24),

          // Legenda Interattiva
          _buildInteractiveLegend(isDark),

          const SizedBox(height: 24),

          // Mini Stats Cards
          _buildMiniStatsCards(isDark),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.whatshot, color: Color(0xFFFF5722), size: 24),
          const SizedBox(width: 8),
          const Text(
            'Heatmap',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (!_showComparison) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: widget.isHome
                    ? const Color(0xFF2196F3).withOpacity(0.1)
                    : const Color(0xFFE53935).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.isHome ? widget.homeTeamName : widget.awayTeamName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isHome
                      ? const Color(0xFF2196F3)
                      : const Color(0xFFE53935),
                ),
              ),
            ),
          ],
          const Spacer(),
          // Toggle Comparazione
          IconButton(
            icon: Icon(
              _showComparison ? Icons.view_agenda : Icons.compare,
              color:
                  _showComparison ? const Color(0xFF2196F3) : Colors.grey[600],
            ),
            onPressed: () => setState(() => _showComparison = !_showComparison),
            tooltip: _showComparison ? 'Vista singola' : 'Confronta squadre',
          ),
          // Toggle Zone Stats
          IconButton(
            icon: Icon(
              _showZoneStats ? Icons.grid_on : Icons.grid_off,
              color:
                  _showZoneStats ? const Color(0xFF2196F3) : Colors.grey[600],
            ),
            onPressed: () => setState(() => _showZoneStats = !_showZoneStats),
            tooltip:
                _showZoneStats ? 'Nascondi percentuali' : 'Mostra percentuali',
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodFilters(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildPeriodChip('Tutto', 'all', Icons.timer, isDark),
          const SizedBox(width: 8),
          _buildPeriodChip('1° Tempo', 'first_half', Icons.looks_one, isDark),
          const SizedBox(width: 8),
          _buildPeriodChip('2° Tempo', 'second_half', Icons.looks_two, isDark),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(
      String label, String value, IconData icon, bool isDark) {
    final isSelected = _periodFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _periodFilter = value);
        _animationController.reset();
        _animationController.forward();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleView(bool isDark) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.scale(
            scale: 0.95 + (_animation.value * 0.05),
            child: Container(
              height: 600,
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: AdvancedHeatmapPainter(
                        isHome: widget.isHome,
                        periodFilter: _periodFilter,
                        showZoneStats: _showZoneStats,
                        animationValue: _animation.value,
                        selectedIntensities: _selectedIntensities,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildComparisonView(bool isDark) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Row(
            children: [
              // Campo Casa
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.homeTeamName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 500,
                      margin: const EdgeInsets.only(left: 8, right: 4),
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
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return CustomPaint(
                              size: Size(
                                  constraints.maxWidth, constraints.maxHeight),
                              painter: AdvancedHeatmapPainter(
                                isHome: true,
                                periodFilter: _periodFilter,
                                showZoneStats: _showZoneStats,
                                animationValue: _animation.value,
                                selectedIntensities: _selectedIntensities,
                                isCompact: true,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Campo Ospite
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.awayTeamName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE53935),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 500,
                      margin: const EdgeInsets.only(left: 4, right: 8),
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
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return CustomPaint(
                              size: Size(
                                  constraints.maxWidth, constraints.maxHeight),
                              painter: AdvancedHeatmapPainter(
                                isHome: false,
                                periodFilter: _periodFilter,
                                showZoneStats: _showZoneStats,
                                animationValue: _animation.value,
                                selectedIntensities: _selectedIntensities,
                                isCompact: true,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInteractiveLegend(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Intensità Possesso',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendItem(
                  0, 'Molto\nBasso', const Color(0xFF2196F3), isDark),
              _buildLegendItem(1, 'Basso', const Color(0xFF4CAF50), isDark),
              _buildLegendItem(2, 'Medio', const Color(0xFFFFEB3B), isDark),
              _buildLegendItem(3, 'Alto', const Color(0xFFFF9800), isDark),
              _buildLegendItem(
                  4, 'Molto\nAlto', const Color(0xFFF44336), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(int index, String label, Color color, bool isDark) {
    final isSelected = _selectedIntensities.contains(index);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedIntensities.remove(index);
            } else {
              _selectedIntensities.add(index);
            }
          });
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isSelected ? 1.0 : 0.4,
          child: Column(
            children: [
              Container(
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? null : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStatsCards(bool isDark) {
    final zoneData = _getZoneDataForTeam(widget.isHome);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Zona Calda',
              zoneData['hot']!['name']!,
              zoneData['hot']!['percent']!,
              Icons.local_fire_department,
              const Color(0xFFF44336),
              isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Zona Fredda',
              zoneData['cold']!['name']!,
              zoneData['cold']!['percent']!,
              Icons.ac_unit,
              const Color(0xFF2196F3),
              isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Equilibrio',
              zoneData['balance']!['name']!,
              zoneData['balance']!['percent']!,
              Icons.balance,
              const Color(0xFFFFEB3B),
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String zone, String percent,
      IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            zone,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            percent,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Map<String, String>> _getZoneDataForTeam(bool isHome) {
    // Mock data - sostituire con dati reali
    if (isHome) {
      return {
        'hot': {'name': 'Att. Sx', 'percent': '35%'},
        'cold': {'name': 'Dif. Dx', 'percent': '8%'},
        'balance': {'name': 'Centro', 'percent': '52%'},
      };
    } else {
      return {
        'hot': {'name': 'Att. Dx', 'percent': '32%'},
        'cold': {'name': 'Dif. Sx', 'percent': '9%'},
        'balance': {'name': 'Centro', 'percent': '48%'},
      };
    }
  }
}

/// Painter avanzato per heatmap con punti di calore concentrati
class AdvancedHeatmapPainter extends CustomPainter {
  final bool isHome;
  final String periodFilter;
  final bool showZoneStats;
  final double animationValue;
  final Set<int> selectedIntensities;
  final bool isCompact;

  AdvancedHeatmapPainter({
    required this.isHome,
    required this.periodFilter,
    required this.showZoneStats,
    required this.animationValue,
    required this.selectedIntensities,
    this.isCompact = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Sfondo campo
    final fieldPaint = Paint()..color = const Color(0xFF1B5E20);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fieldPaint);

    // Genera punti di calore
    final heatPoints = _generateHeatPoints(size);

    // Disegna punti di calore con blur
    for (final point in heatPoints) {
      if (!selectedIntensities.contains(point.intensity)) continue;

      final opacity = animationValue * point.opacity;
      _drawHeatBlob(canvas, point, opacity);
    }

    // Disegna linee campo
    _drawFieldLines(canvas, size);

    // Disegna statistiche zone
    if (showZoneStats && !isCompact) {
      _drawZoneStatistics(canvas, size);
    }
  }

  List<HeatPoint> _generateHeatPoints(Size size) {
    final random = math.Random(isHome ? 42 : 84);
    final points = <HeatPoint>[];

    // Numero di punti basato sul periodo
    int numPoints = 50;
    if (periodFilter == 'first_half') numPoints = 30;
    if (periodFilter == 'second_half') numPoints = 25;

    for (int i = 0; i < numPoints; i++) {
      double x, y;
      int intensity;

      if (isHome) {
        // Casa: più concentrato a sinistra (attacco)
        x = size.width * (0.1 + random.nextDouble() * 0.5);
        y = size.height * (0.2 + random.nextDouble() * 0.6);

        // Intensità maggiore a sinistra
        if (x < size.width * 0.3) {
          intensity = 3 + random.nextInt(2); // 3-4 (alto/molto alto)
        } else if (x < size.width * 0.45) {
          intensity = 2 + random.nextInt(2); // 2-3 (medio/alto)
        } else {
          intensity = random.nextInt(3); // 0-2 (basso/medio)
        }
      } else {
        // Ospite: più concentrato a destra (attacco)
        x = size.width * (0.4 + random.nextDouble() * 0.5);
        y = size.height * (0.2 + random.nextDouble() * 0.6);

        // Intensità maggiore a destra
        if (x > size.width * 0.7) {
          intensity = 3 + random.nextInt(2); // 3-4 (alto/molto alto)
        } else if (x > size.width * 0.55) {
          intensity = 2 + random.nextInt(2); // 2-3 (medio/alto)
        } else {
          intensity = random.nextInt(3); // 0-2 (basso/medio)
        }
      }

      final radius = 40.0 + random.nextDouble() * 40.0;
      final opacity = 0.3 + random.nextDouble() * 0.4;

      points.add(HeatPoint(
        x: x,
        y: y,
        radius: radius,
        intensity: intensity,
        opacity: opacity,
      ));
    }

    return points;
  }

  void _drawHeatBlob(Canvas canvas, HeatPoint point, double opacity) {
    final colors = [
      const Color(0xFF2196F3), // Blu - Molto basso
      const Color(0xFF4CAF50), // Verde - Basso
      const Color(0xFFFFEB3B), // Giallo - Medio
      const Color(0xFFFF9800), // Arancione - Alto
      const Color(0xFFF44336), // Rosso - Molto alto
    ];

    final color = colors[point.intensity];

    final gradient = ui.Gradient.radial(
      Offset(point.x, point.y),
      point.radius,
      [
        color.withOpacity(opacity),
        color.withOpacity(opacity * 0.5),
        color.withOpacity(0),
      ],
      [0.0, 0.5, 1.0],
    );

    final paint = Paint()..shader = gradient;
    canvas.drawCircle(Offset(point.x, point.y), point.radius, paint);
  }

  void _drawFieldLines(Canvas canvas, Size size) {
    // Linee più spesse e visibili
    final thickLinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCompact ? 3.5 : 5.0;

    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCompact ? 2.5 : 4.0;

    // Bordo campo COMPLETO
    final borderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      const Radius.circular(8),
    );
    canvas.drawRRect(borderRect, thickLinePaint);

    // Linea centrale VERTICALE
    canvas.drawLine(
      Offset(size.width / 2, 1),
      Offset(size.width / 2, size.height - 1),
      thickLinePaint,
    );

    // Cerchio centrale
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final circleRadius = isCompact ? size.height * 0.15 : size.height * 0.20;

    canvas.drawCircle(Offset(centerX, centerY), circleRadius, linePaint);

    // Punto centrale
    canvas.drawCircle(
      Offset(centerX, centerY),
      isCompact ? 4 : 6,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // AREE DI RIGORE - Proporzioni corrette
    final penaltyWidth = size.width * 0.20;
    final penaltyHeight = size.height * 0.50;
    final penaltyY = (size.height - penaltyHeight) / 2;

    // Area rigore SINISTRA
    canvas.drawRect(
      Rect.fromLTWH(1, penaltyY, penaltyWidth, penaltyHeight),
      linePaint,
    );

    // Area rigore DESTRA
    canvas.drawRect(
      Rect.fromLTWH(
        size.width - penaltyWidth - 1,
        penaltyY,
        penaltyWidth,
        penaltyHeight,
      ),
      linePaint,
    );

    // AREA PICCOLA - Proporzioni corrette
    final smallBoxWidth = size.width * 0.08;
    final smallBoxHeight = size.height * 0.25;
    final smallBoxY = (size.height - smallBoxHeight) / 2;

    // Area piccola SINISTRA
    canvas.drawRect(
      Rect.fromLTWH(1, smallBoxY, smallBoxWidth, smallBoxHeight),
      linePaint,
    );

    // Area piccola DESTRA
    canvas.drawRect(
      Rect.fromLTWH(
        size.width - smallBoxWidth - 1,
        smallBoxY,
        smallBoxWidth,
        smallBoxHeight,
      ),
      linePaint,
    );

    // PUNTI DI RIGORE - RIMOSSI (non necessari per heatmap)
    // final penaltySpotX = penaltyWidth * 0.5;
    // canvas.drawCircle(...)

    // SEMICERCHI - FUORI DALL'AREA DI RIGORE (LUNETTE)
    final arcRadius = penaltyHeight * 0.18;

    // Semicerchio SINISTRO - FUORI dall'area
    final leftArcPath = Path();
    final leftArcCenter = Offset(penaltyWidth, centerY);

    // Arco che va FUORI dall'area (da -90° a +90°, verso destra)
    leftArcPath.addArc(
      Rect.fromCircle(
        center: leftArcCenter,
        radius: arcRadius,
      ),
      -math.pi / 2, // Inizio a -90° (alto)
      math.pi, // Arco di 180° verso destra (fuori)
    );

    // Disegna solo la parte che esce dall'area
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(penaltyWidth, 0, size.width, size.height));
    canvas.drawPath(leftArcPath, linePaint);
    canvas.restore();

    // Semicerchio DESTRO - FUORI dall'area
    final rightArcPath = Path();
    final rightArcCenter = Offset(size.width - penaltyWidth, centerY);

    // Arco che va FUORI dall'area (da 90° a 270°, verso sinistra)
    rightArcPath.addArc(
      Rect.fromCircle(
        center: rightArcCenter,
        radius: arcRadius,
      ),
      math.pi / 2, // Inizio a 90° (basso)
      math.pi, // Arco di 180° verso sinistra (fuori)
    );

    // Disegna solo la parte che esce dall'area
    canvas.save();
    canvas
        .clipRect(Rect.fromLTWH(0, 0, size.width - penaltyWidth, size.height));
    canvas.drawPath(rightArcPath, linePaint);
    canvas.restore();

    // ANGOLI DEL CAMPO (opzionale ma bello)
    final cornerRadius = isCompact ? 6.0 : 8.0;

    // Angolo in alto a sinistra
    canvas.drawArc(
      Rect.fromLTWH(1, 1, cornerRadius * 2, cornerRadius * 2),
      math.pi,
      math.pi / 2,
      false,
      linePaint,
    );

    // Angolo in alto a destra
    canvas.drawArc(
      Rect.fromLTWH(size.width - cornerRadius * 2 - 1, 1, cornerRadius * 2,
          cornerRadius * 2),
      -math.pi / 2,
      math.pi / 2,
      false,
      linePaint,
    );

    // Angolo in basso a sinistra
    canvas.drawArc(
      Rect.fromLTWH(1, size.height - cornerRadius * 2 - 1, cornerRadius * 2,
          cornerRadius * 2),
      math.pi / 2,
      math.pi / 2,
      false,
      linePaint,
    );

    // Angolo in basso a destra
    canvas.drawArc(
      Rect.fromLTWH(
        size.width - cornerRadius * 2 - 1,
        size.height - cornerRadius * 2 - 1,
        cornerRadius * 2,
        cornerRadius * 2,
      ),
      0,
      math.pi / 2,
      false,
      linePaint,
    );
  }

  void _drawZoneStatistics(Canvas canvas, Size size) {
    // Dividi campo in 9 zone (3x3)
    final zoneWidth = size.width / 3;
    final zoneHeight = size.height / 3;

    final random = math.Random(isHome ? 100 : 200);

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final x = col * zoneWidth + zoneWidth / 2;
        final y = row * zoneHeight + zoneHeight / 2;

        // Calcola percentuale basata su posizione
        int percent;
        if (isHome) {
          // Casa: più % a sinistra
          percent = col == 0
              ? 25 + random.nextInt(15)
              : col == 1
                  ? 15 + random.nextInt(15)
                  : 5 + random.nextInt(15);
        } else {
          // Ospite: più % a destra
          percent = col == 2
              ? 25 + random.nextInt(15)
              : col == 1
                  ? 15 + random.nextInt(15)
                  : 5 + random.nextInt(15);
        }

        // Disegna sfondo percentuale
        final bgPaint = Paint()..color = Colors.black.withOpacity(0.6);
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, y),
            width: 50,
            height: 30,
          ),
          const Radius.circular(8),
        );
        canvas.drawRRect(rect, bgPaint);

        // Disegna testo percentuale
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$percent%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            x - textPainter.width / 2,
            y - textPainter.height / 2,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(AdvancedHeatmapPainter oldDelegate) {
    return oldDelegate.isHome != isHome ||
        oldDelegate.periodFilter != periodFilter ||
        oldDelegate.showZoneStats != showZoneStats ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.selectedIntensities != selectedIntensities;
  }
}

/// Classe per rappresentare un punto di calore
class HeatPoint {
  final double x;
  final double y;
  final double radius;
  final int intensity; // 0-4 (molto basso -> molto alto)
  final double opacity;

  HeatPoint({
    required this.x,
    required this.y,
    required this.radius,
    required this.intensity,
    required this.opacity,
  });
}
