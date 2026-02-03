// WIDGET ANIMATI STATISTICHE AVANZATE
// lib/widgets/animated_advanced_stats_widgets.dart

import 'package:flutter/material.dart';
import '../painters/advanced_stats_painters.dart';

// ========================================
// SHOT MAP ANIMATO
// ========================================
class AnimatedShotMapWidget extends StatefulWidget {
  final bool isHome;
  final bool isDark;
  final String homeName;
  final String awayName;

  const AnimatedShotMapWidget({
    Key? key,
    required this.isHome,
    required this.isDark,
    required this.homeName,
    required this.awayName,
  }) : super(key: key);

  @override
  State<AnimatedShotMapWidget> createState() => _AnimatedShotMapWidgetState();
}

class _AnimatedShotMapWidgetState extends State<AnimatedShotMapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

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
  void didUpdateWidget(AnimatedShotMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isHome != widget.isHome) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con statistiche
        _buildStatsHeader(),
        const SizedBox(height: 16),

        // Campo con animazione
        Container(
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: AnimatedShotMapPainter(
                    isHome: widget.isHome,
                    isDark: widget.isDark,
                    animationValue: _animation.value,
                  ),
                  child: Container(),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Legenda
        _buildLegend(),
      ],
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.isHome ? const Color(0xFF2196F3) : const Color(0xFFE53935),
            widget.isHome ? const Color(0xFF1976D2) : const Color(0xFFC62828),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (widget.isHome
                    ? const Color(0xFF2196F3)
                    : const Color(0xFFE53935))
                .withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_soccer,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isHome ? widget.homeName : widget.awayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mappa Tiri',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          _buildStatBadge('12', 'Totali'),
          const SizedBox(width: 12),
          _buildStatBadge('5', 'In porta'),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(Colors.green, 'Goal', '3'),
        _buildLegendItem(Colors.orange, 'In porta', '5'),
        _buildLegendItem(Colors.red, 'Fuori', '7'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                count,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========================================
// PASS NETWORK ANIMATO
// ========================================
class AnimatedPassNetworkWidget extends StatefulWidget {
  final bool isHome;
  final bool isDark;
  final String teamName;

  const AnimatedPassNetworkWidget({
    Key? key,
    required this.isHome,
    required this.isDark,
    required this.teamName,
  }) : super(key: key);

  @override
  State<AnimatedPassNetworkWidget> createState() =>
      _AnimatedPassNetworkWidgetState();
}

class _AnimatedPassNetworkWidgetState extends State<AnimatedPassNetworkWidget>
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
      curve: Curves.easeInOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedPassNetworkWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isHome != widget.isHome) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(),
        const SizedBox(height: 16),

        // Campo animato
        Container(
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: GradientPassNetworkPainter(
                    isHome: widget.isHome,
                    isDark: widget.isDark,
                    animationValue: _animation.value,
                  ),
                  child: Container(),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Top passatori
        _buildTopPassers(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00BCD4), Color(0xFF0097A7)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BCD4).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.hub, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.teamName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Network Passaggi',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: const [
                Text(
                  '487',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Passaggi',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPassers() {
    final passers = [
      {'name': 'Barella', 'number': 23, 'passes': 78, 'accuracy': 92},
      {'name': 'Brozovic', 'number': 77, 'passes': 71, 'accuracy': 89},
      {'name': 'Calhanoglu', 'number': 20, 'passes': 65, 'accuracy': 87},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00BCD4).withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber[700]),
              const SizedBox(width: 8),
              const Text(
                'Top Passatori',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...passers.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            return _buildPasserRow(
              index + 1,
              player['name'] as String,
              player['number'] as int,
              player['passes'] as int,
              player['accuracy'] as int,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPasserRow(
      int rank, String name, int number, int passes, int accuracy) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF00BCD4).withOpacity(0.1),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF00BCD4),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '#$number',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$passes',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00BCD4),
                ),
              ),
              Text(
                '$accuracy%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========================================
// HEATMAP ANIMATA
// ========================================
class AnimatedHeatmapWidget extends StatefulWidget {
  final bool isHome;
  final bool isDark;
  final String teamName;

  const AnimatedHeatmapWidget({
    Key? key,
    required this.isHome,
    required this.isDark,
    required this.teamName,
  }) : super(key: key);

  @override
  State<AnimatedHeatmapWidget> createState() => _AnimatedHeatmapWidgetState();
}

class _AnimatedHeatmapWidgetState extends State<AnimatedHeatmapWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedHeatmapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isHome != widget.isHome) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(),
        const SizedBox(height: 16),

        // Campo animato
        Container(
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: Advanced3DHeatmapPainter(
                    isHome: widget.isHome,
                    isDark: widget.isDark,
                    animationValue: _animation.value,
                  ),
                  child: Container(),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Legenda gradient
        _buildGradientLegend(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6F00), Color(0xFFE65100)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6F00).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.whatshot, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.teamName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Heatmap Possesso',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: const [
                Text(
                  '58%',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Possesso',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Intensità Possesso',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Basso',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1E88E5),
                        Color(0xFF43A047),
                        Color(0xFFFDD835),
                        Color(0xFFFF6F00),
                        Color(0xFFD32F2F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Alto',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ========================================
// DEFENSIVE ACTIONS ANIMATA
// ========================================
class AnimatedDefensiveActionsWidget extends StatefulWidget {
  final bool isDark;

  const AnimatedDefensiveActionsWidget({
    Key? key,
    required this.isDark,
  }) : super(key: key);

  @override
  State<AnimatedDefensiveActionsWidget> createState() =>
      _AnimatedDefensiveActionsWidgetState();
}

class _AnimatedDefensiveActionsWidgetState
    extends State<AnimatedDefensiveActionsWidget>
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
      curve: Curves.easeOutBack,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _buildHeader(),
        const SizedBox(height: 16),

        // Campo animato
        Container(
          height: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  painter: DetailedDefensiveActionsPainter(
                    isDark: widget.isDark,
                    animationValue: _animation.value,
                  ),
                  child: Container(),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Statistiche azioni
        _buildActionsStats(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFC62828)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.shield, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Azioni Difensive',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: const [
                Text(
                  '18',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Totali',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsStats() {
    return Row(
      children: [
        Expanded(
            child:
                _buildStatCard('Tackle', 8, Icons.sports_kabaddi, Colors.red)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard('Intercetti', 6, Icons.block, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildStatCard(
                'Clearance', 4, Icons.clear_all, Colors.yellow[700]!)),
      ],
    );
  }

  Widget _buildStatCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
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
      ),
    );
  }
}
