import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../utils/l10n_helper.dart';

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
                    ? const Color(0xFF1565C0).withOpacity(0.1)
                    : const Color(0xFFE53935).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.isHome ? widget.homeTeamName : widget.awayTeamName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isHome
                      ? const Color(0xFF1565C0)
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
                  _showComparison ? const Color(0xFF1565C0) : Colors.grey[600],
            ),
            onPressed: () => setState(() => _showComparison = !_showComparison),
            tooltip: _showComparison ? tr(context, 'Vista singola') : tr(context, 'Confronta squadre'),
          ),
          // Toggle Zone Stats
          IconButton(
            icon: Icon(
              _showZoneStats ? Icons.grid_on : Icons.grid_off,
              color:
                  _showZoneStats ? const Color(0xFF1565C0) : Colors.grey[600],
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
          _buildPeriodChip(tr(context, '1° Tempo'), 'first_half', Icons.looks_one, isDark),
          const SizedBox(width: 8),
          _buildPeriodChip(tr(context, '2° Tempo'), 'second_half', Icons.looks_two, isDark),
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
                  colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
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
                        color: const Color(0xFF1565C0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.homeTeamName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
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
          Text(
            tr(context, 'Intensità Possesso'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildLegendItem(
                  0, 'Molto\nBasso', const Color(0xFF1565C0), isDark),
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
              tr(context, 'Zona Calda'),
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
              tr(context, 'Zona Fredda'),
              zoneData['cold']!['name']!,
              zoneData['cold']!['percent']!,
              Icons.ac_unit,
              const Color(0xFF1565C0),
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
  final String? playerPosition; // GK, CB, CM, LW, RW, ST, etc.
  final String? playerName;

  AdvancedHeatmapPainter({
    required this.isHome,
    required this.periodFilter,
    required this.showZoneStats,
    required this.animationValue,
    required this.selectedIntensities,
    this.isCompact = false,
    this.playerPosition,
    this.playerName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Field background
    final fieldPaint = Paint()..color = const Color(0xFFC5DFC5);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fieldPaint);

    // Draw field lines FIRST (under heatmap)
    _drawFieldLines(canvas, size);

    // Generate and draw smooth heatmap
    _drawSmoothHeatmap(canvas, size);
  }

  void _drawSmoothHeatmap(Canvas canvas, Size size) {
    // Heatmap di SQUADRA (no playerName) → hotspot di team
    // Heatmap di GIOCATORE → hotspot per posizione
    final hotspots = (playerName == null || playerName!.isEmpty)
        ? _getTeamHotspots(size)
        : _getPositionHotspots(size);

    // Generate many small, soft points around hotspots
    final seed = (playerName?.hashCode ?? (isHome ? 42 : 84)).abs();
    final rng = math.Random(seed);

    // Adjust point count: meno punti per heatmap squadra (evita saturazione)
    final isTeamView = playerName == null || playerName!.isEmpty;
    int numPoints = isTeamView ? 60 : 180;
    if (periodFilter == 'first_half') numPoints = isTeamView ? 38 : 110;
    if (periodFilter == 'second_half') numPoints = isTeamView ? 32 : 100;

    // Collect all heat points
    final points = <_SmoothHeatPoint>[];

    for (final hotspot in hotspots) {
      final count = (numPoints * hotspot.weight).round();
      for (int i = 0; i < count; i++) {
        // Gaussian-like distribution using Box-Muller transform
        final u1 = rng.nextDouble();
        final u2 = rng.nextDouble();
        final z0 = math.sqrt(-2 * math.log(u1 + 0.001)) * math.cos(2 * math.pi * u2);
        final z1 = math.sqrt(-2 * math.log(u1 + 0.001)) * math.sin(2 * math.pi * u2);

        final x = (hotspot.x + z0 * hotspot.spreadX).clamp(0.0, size.width);
        final y = (hotspot.y + z1 * hotspot.spreadY).clamp(0.0, size.height);

        // Distance from hotspot center affects intensity
        final dist = math.sqrt(math.pow(x - hotspot.x, 2) + math.pow(y - hotspot.y, 2));
        final maxDist = math.sqrt(math.pow(hotspot.spreadX * 3, 2) + math.pow(hotspot.spreadY * 3, 2));
        final normalizedDist = (dist / maxDist).clamp(0.0, 1.0);

        points.add(_SmoothHeatPoint(
          x: x,
          y: y,
          radius: 25.0 + rng.nextDouble() * 30.0,
          intensity: 1.0 - normalizedDist * 0.7,
        ));
      }
    }

    // Sort by intensity (draw low first, high on top)
    points.sort((a, b) => a.intensity.compareTo(b.intensity));

    // Draw with smooth blending — soglia più alta per heatmap squadra
    final alphaMax = isTeamView ? 0.55 : 0.5;
    final alphaMul = isTeamView ? 0.45 : 0.35;
    final minAlpha = isTeamView ? 0.10 : 0.02;
    for (final p in points) {
      final alpha = (p.intensity * alphaMul * animationValue).clamp(0.0, alphaMax);
      if (alpha < minAlpha) continue;

      // Color based on intensity: green → yellow → orange → red
      final Color color;
      if (p.intensity > 0.8) {
        color = Color.lerp(const Color(0xFFFF6D00), const Color(0xFFD50000), (p.intensity - 0.8) * 5)!;
      } else if (p.intensity > 0.5) {
        color = Color.lerp(const Color(0xFFFFD600), const Color(0xFFFF6D00), (p.intensity - 0.5) * 3.3)!;
      } else if (p.intensity > 0.25) {
        color = Color.lerp(const Color(0xFF76FF03), const Color(0xFFFFD600), (p.intensity - 0.25) * 4)!;
      } else {
        color = const Color(0xFF76FF03);
      }

      final gradient = ui.Gradient.radial(
        Offset(p.x, p.y),
        p.radius,
        [
          color.withOpacity(alpha),
          color.withOpacity(alpha * 0.4),
          color.withOpacity(0),
        ],
        [0.0, 0.45, 1.0],
      );

      canvas.drawCircle(
        Offset(p.x, p.y),
        p.radius,
        Paint()
          ..shader = gradient
          ..blendMode = BlendMode.screen,
      );
    }
  }

  List<_Hotspot> _getPositionHotspots(Size size) {
    final w = size.width;
    final h = size.height;

    // Determine position from playerPosition or infer from name
    String pos = playerPosition ?? _inferPosition();

    // Flip X for away team (they attack from right)
    double flipX(double x) => isHome ? x : w - x;

    switch (pos) {
      case 'GK':
        return [
          _Hotspot(flipX(w * 0.08), h * 0.5, w * 0.06, h * 0.12, 0.85),
          _Hotspot(flipX(w * 0.15), h * 0.5, w * 0.08, h * 0.18, 0.15),
        ];
      case 'CB':
      case 'RB':
      case 'LB':
        final yBias = pos == 'LB' ? 0.3 : pos == 'RB' ? 0.7 : 0.5;
        return [
          _Hotspot(flipX(w * 0.22), h * yBias, w * 0.10, h * 0.14, 0.55),
          _Hotspot(flipX(w * 0.32), h * 0.5, w * 0.12, h * 0.20, 0.30),
          _Hotspot(flipX(w * 0.15), h * yBias, w * 0.06, h * 0.10, 0.15),
        ];
      case 'CDM':
      case 'CM':
        return [
          _Hotspot(flipX(w * 0.40), h * 0.5, w * 0.14, h * 0.18, 0.50),
          _Hotspot(flipX(w * 0.30), h * 0.45, w * 0.10, h * 0.15, 0.30),
          _Hotspot(flipX(w * 0.50), h * 0.55, w * 0.10, h * 0.15, 0.20),
        ];
      case 'CAM':
      case 'LM':
      case 'RM':
        final yBias = pos == 'LM' ? 0.3 : pos == 'RM' ? 0.7 : 0.45;
        return [
          _Hotspot(flipX(w * 0.52), h * yBias, w * 0.13, h * 0.16, 0.50),
          _Hotspot(flipX(w * 0.42), h * 0.5, w * 0.10, h * 0.18, 0.30),
          _Hotspot(flipX(w * 0.62), h * yBias, w * 0.08, h * 0.12, 0.20),
        ];
      case 'LW':
      case 'RW':
        final yBias = pos == 'LW' ? 0.25 : 0.75;
        return [
          _Hotspot(flipX(w * 0.65), h * yBias, w * 0.12, h * 0.13, 0.50),
          _Hotspot(flipX(w * 0.55), h * yBias, w * 0.10, h * 0.16, 0.25),
          _Hotspot(flipX(w * 0.75), h * yBias * 1.1, w * 0.08, h * 0.10, 0.25),
        ];
      case 'ST':
      case 'CF':
      case 'FW':
      default:
        return [
          _Hotspot(flipX(w * 0.72), h * 0.5, w * 0.12, h * 0.16, 0.50),
          _Hotspot(flipX(w * 0.60), h * 0.45, w * 0.10, h * 0.18, 0.30),
          _Hotspot(flipX(w * 0.80), h * 0.5, w * 0.07, h * 0.10, 0.20),
        ];
    }
  }

  /// Hotspot di SQUADRA — distribuzione realistica delle azioni di gioco.
  /// Asimmetria: home attacca da sinistra a destra (caldi a destra),
  /// away da destra a sinistra (caldi a sinistra).
  List<_Hotspot> _getTeamHotspots(Size size) {
    final w = size.width;
    final h = size.height;
    // Flip X per away
    double fx(double x) => isHome ? x : w - x;
    return [
      // Difesa propria (intensità bassa, presenza minima)
      _Hotspot(fx(w * 0.18), h * 0.50, w * 0.10, h * 0.20, 0.18),
      // Esterno difensivo basso
      _Hotspot(fx(w * 0.22), h * 0.30, w * 0.09, h * 0.14, 0.12),
      _Hotspot(fx(w * 0.22), h * 0.70, w * 0.09, h * 0.14, 0.12),
      // Centrocampo basso (cuore difensivo)
      _Hotspot(fx(w * 0.40), h * 0.50, w * 0.13, h * 0.22, 0.45),
      // Centrocampo alto (zona costruzione)
      _Hotspot(fx(w * 0.55), h * 0.45, w * 0.12, h * 0.20, 0.55),
      _Hotspot(fx(w * 0.55), h * 0.60, w * 0.10, h * 0.16, 0.40),
      // Esterni offensivi (fasce)
      _Hotspot(fx(w * 0.68), h * 0.25, w * 0.10, h * 0.13, 0.40),
      _Hotspot(fx(w * 0.68), h * 0.75, w * 0.10, h * 0.13, 0.40),
      // Trequarti (zona pericolosa, alta intensità)
      _Hotspot(fx(w * 0.72), h * 0.50, w * 0.11, h * 0.18, 0.65),
      // Area avversaria (bassa frequenza ma alta intensità)
      _Hotspot(fx(w * 0.85), h * 0.50, w * 0.08, h * 0.15, 0.30),
    ];
  }

  String _inferPosition() {
    final name = playerName?.toLowerCase() ?? '';
    // Simple inference from well-known players
    if (name.contains('immobile') || name.contains('giroud') || name.contains('osimhen') ||
        name.contains('vlahovic') || name.contains('lautaro') || name.contains('zapata')) return 'ST';
    if (name.contains('zaccagni') || name.contains('leao') || name.contains('kvara') ||
        name.contains('anderson') || name.contains('chiesa') || name.contains('berardi')) return 'LW';
    if (name.contains('pedro') || name.contains('dybala') || name.contains('politano') ||
        name.contains('suso') || name.contains('di maria')) return 'RW';
    if (name.contains('alberto') || name.contains('milinkovic') || name.contains('barella') ||
        name.contains('tonali') || name.contains('lobotka') || name.contains('calhanoglu')) return 'CM';
    if (name.contains('cataldi') || name.contains('bennacer') || name.contains('brozovic')) return 'CDM';
    if (name.contains('provedel') || name.contains('maignan') || name.contains('meret') ||
        name.contains('szczesny') || name.contains('onana') || name.contains('maximiano')) return 'GK';
    if (name.contains('romagnoli') || name.contains('patric') || name.contains('tomori') ||
        name.contains('bremer') || name.contains('skriniar') || name.contains('smalling')) return 'CB';
    if (name.contains('marusic') || name.contains('calabria') || name.contains('dumfries') ||
        name.contains('hernandez') || name.contains('hysaj') || name.contains('spinazzola')) return 'LB';
    return 'CM'; // default
  }

  void _drawFieldLines(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Outer boundary
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), linePaint);

    // Center line
    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), linePaint);

    // Center circle
    canvas.drawCircle(Offset(w / 2, h / 2), h * 0.15, linePaint);

    // Center dot
    canvas.drawCircle(Offset(w / 2, h / 2), 2.5,
        Paint()..color = Colors.white.withOpacity(0.3));

    // Penalty areas
    final paW = w * 0.16;
    final paH = h * 0.55;
    final paY = (h - paH) / 2;
    canvas.drawRect(Rect.fromLTWH(0, paY, paW, paH), linePaint);
    canvas.drawRect(Rect.fromLTWH(w - paW, paY, paW, paH), linePaint);

    // Goal areas
    final gaW = w * 0.06;
    final gaH = h * 0.3;
    final gaY = (h - gaH) / 2;
    canvas.drawRect(Rect.fromLTWH(0, gaY, gaW, gaH), linePaint);
    canvas.drawRect(Rect.fromLTWH(w - gaW, gaY, gaW, gaH), linePaint);

    // Penalty spots
    final spotPaint = Paint()..color = Colors.white.withOpacity(0.2);
    canvas.drawCircle(Offset(w * 0.12, h / 2), 2, spotPaint);
    canvas.drawCircle(Offset(w * 0.88, h / 2), 2, spotPaint);
  }

  void _drawZoneStatistics(Canvas canvas, Size size) {
    // Zone stats overlay - simplified for clean look
    // Intentionally left minimal to not clutter the heatmap
  }

  @override
  bool shouldRepaint(covariant AdvancedHeatmapPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.isHome != isHome ||
      oldDelegate.periodFilter != periodFilter ||
      oldDelegate.selectedIntensities != selectedIntensities ||
      oldDelegate.playerName != playerName;
}

class _SmoothHeatPoint {
  final double x, y, radius, intensity;
  _SmoothHeatPoint({required this.x, required this.y, required this.radius, required this.intensity});
}

class _Hotspot {
  final double x, y, spreadX, spreadY, weight;
  _Hotspot(this.x, this.y, this.spreadX, this.spreadY, this.weight);
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
