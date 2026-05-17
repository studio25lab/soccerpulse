import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../utils/l10n_helper.dart';
import 'interactive_shot_map_widget.dart';
import 'Interactive_defensive_widget.dart';
import '../painters/advanced_stats_painters.dart';

// ═══════════════════════════════════════════════════════════════════
//  PLAYER HEATMAP CARD
// ═══════════════════════════════════════════════════════════════════

class PlayerHeatmapCard extends StatelessWidget {
  final String playerName;
  final String position;
  final int touches;
  final Color teamColor;
  final bool isDark;

  const PlayerHeatmapCard({
    super.key,
    this.playerName = '',
    required this.position,
    required this.touches,
    required this.teamColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Icon(Icons.whatshot_rounded, size: 18, color: teamColor),
            const SizedBox(width: 8),
            Text('Heatmap',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 70,
                  height: 16,
                  child: CustomPaint(
                    painter: _AttackArrowPainter(isDark: isDark),
                  ),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: CustomPaint(
                painter: _PlayerHeatmapPainter(
                  touchPoints: _generateTouchPoints(playerName, position, touches),
                  isDark: isDark,
                  isHome: true,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(tr(context, 'Bassa'), style: TextStyle(fontSize: 10, color: lb)),
            const SizedBox(width: 6),
            Container(
              width: 100,
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: const LinearGradient(colors: [
                  Color(0xFFA5D6A7),
                  Color(0xFFFFF176),
                  Color(0xFFFFB74D),
                  Color(0xFFFF5722),
                  Color(0xFFE53935),
                ]),
              ),
            ),
            const SizedBox(width: 6),
            Text(tr(context, 'Alta'), style: TextStyle(fontSize: 10, color: lb)),
          ]),
        ),
      ]),
    );
  }

  static List<List<double>> _generateTouchPoints(
      String name, String pos, int rawTouches) {
    final rng = Random(name.hashCode ^ pos.hashCode);
    final t = (rawTouches > 0 ? rawTouches : 95).clamp(50, 280);

    // Each cluster: [centerX, centerY, weight, spreadX, spreadY]
    // weight = proportion of total touches in this zone
    // spreadX/Y = how spread out (LARGER = more yellow, less red)
    //
    // LOGIC: A real player has:
    // - Primary zone (wide spread, moderate weight) → YELLOW
    // - Hot spots (tight spread, small weight) → RED  
    // - Movement corridors (wide spread, small weight) → GREEN/YELLOW
    // - Random roaming touches → scattered GREEN

    List<List<double>> clusters;
    switch (pos) {
      case 'GK':
        clusters = [
          // Primary: own goal area (wide)
          [0.07, 0.50, 0.35, 0.04, 0.18],
          // Distribution kicks
          [0.15, 0.45, 0.15, 0.06, 0.15],
          [0.15, 0.55, 0.15, 0.06, 0.15],
          // Occasional sweeping
          [0.22, 0.50, 0.10, 0.08, 0.20],
          // Goal kicks area
          [0.12, 0.35, 0.08, 0.03, 0.08],
          [0.12, 0.65, 0.08, 0.03, 0.08],
          // Roaming
          [0.18, 0.50, 0.09, 0.10, 0.25],
        ];
        break;
      case 'CB':
        clusters = [
          // Primary defensive zone (WIDE spread)
          [0.20, 0.50, 0.20, 0.08, 0.18],
          // Left-center defensive
          [0.22, 0.38, 0.12, 0.07, 0.12],
          // Right-center defensive
          [0.22, 0.62, 0.12, 0.07, 0.12],
          // Building up from back
          [0.30, 0.45, 0.12, 0.08, 0.15],
          [0.30, 0.55, 0.10, 0.08, 0.15],
          // Aerial duels - own box
          [0.12, 0.50, 0.10, 0.04, 0.15],
          // Pressing high occasionally
          [0.38, 0.50, 0.06, 0.10, 0.20],
          // Set pieces - opponent box
          [0.85, 0.45, 0.04, 0.04, 0.10],
          // Movement corridor
          [0.25, 0.50, 0.14, 0.12, 0.22],
        ];
        break;
      case 'LB':
        clusters = [
          // Primary zone - left flank defensive
          [0.25, 0.80, 0.18, 0.08, 0.10],
          // Overlapping runs up the left
          [0.45, 0.85, 0.12, 0.10, 0.08],
          [0.60, 0.88, 0.08, 0.08, 0.06],
          // Defensive positioning
          [0.18, 0.72, 0.12, 0.06, 0.12],
          // Tucking inside when defending
          [0.20, 0.55, 0.10, 0.06, 0.15],
          // Crossing zone
          [0.70, 0.90, 0.06, 0.06, 0.05],
          // Tracking back
          [0.15, 0.65, 0.08, 0.05, 0.10],
          // Central involvement
          [0.35, 0.65, 0.10, 0.12, 0.18],
          // Roaming
          [0.30, 0.75, 0.16, 0.15, 0.15],
        ];
        break;
      case 'RB':
        clusters = [
          [0.25, 0.20, 0.18, 0.08, 0.10],
          [0.45, 0.15, 0.12, 0.10, 0.08],
          [0.60, 0.12, 0.08, 0.08, 0.06],
          [0.18, 0.28, 0.12, 0.06, 0.12],
          [0.20, 0.45, 0.10, 0.06, 0.15],
          [0.70, 0.10, 0.06, 0.06, 0.05],
          [0.15, 0.35, 0.08, 0.05, 0.10],
          [0.35, 0.35, 0.10, 0.12, 0.18],
          [0.30, 0.25, 0.16, 0.15, 0.15],
        ];
        break;
      case 'CDM':
        clusters = [
          // Shield in front of defense (PRIMARY - wide)
          [0.33, 0.50, 0.14, 0.12, 0.20],
          // Left coverage
          [0.32, 0.32, 0.08, 0.10, 0.12],
          // Right coverage
          [0.32, 0.68, 0.08, 0.10, 0.12],
          // Dropping between CBs
          [0.20, 0.50, 0.08, 0.08, 0.16],
          // Pressing forward
          [0.45, 0.42, 0.06, 0.08, 0.12],
          [0.45, 0.58, 0.06, 0.08, 0.12],
          // Wide support
          [0.28, 0.22, 0.04, 0.08, 0.10],
          [0.28, 0.78, 0.04, 0.08, 0.10],
          // Movement corridor (wide roaming)
          [0.32, 0.50, 0.14, 0.18, 0.26],
          // Occasional forward runs
          [0.52, 0.50, 0.04, 0.10, 0.16],
          // Tracking back
          [0.18, 0.45, 0.05, 0.08, 0.18],
          [0.18, 0.55, 0.05, 0.08, 0.18],
          // Defensive line coverage
          [0.22, 0.35, 0.05, 0.10, 0.14],
          [0.22, 0.65, 0.05, 0.10, 0.14],
          // Transition
          [0.38, 0.50, 0.04, 0.14, 0.20],
        ];
        break;
      case 'CM':
        clusters = [
          // Central primary (WIDE - covers most of midfield)
          [0.42, 0.50, 0.12, 0.14, 0.22],
          // Left half involvement
          [0.38, 0.30, 0.07, 0.10, 0.12],
          // Right half involvement
          [0.38, 0.70, 0.07, 0.10, 0.12],
          // Pushing into final third
          [0.58, 0.45, 0.07, 0.10, 0.14],
          [0.58, 0.55, 0.06, 0.10, 0.14],
          // Dropping deep between CBs
          [0.25, 0.45, 0.06, 0.08, 0.14],
          [0.25, 0.55, 0.05, 0.08, 0.14],
          // Wide support left
          [0.42, 0.20, 0.04, 0.08, 0.10],
          // Wide support right
          [0.42, 0.80, 0.04, 0.08, 0.10],
          // Edge of box runs
          [0.68, 0.42, 0.04, 0.06, 0.10],
          [0.68, 0.58, 0.04, 0.06, 0.10],
          // HUGE movement corridor (box-to-box roaming)
          [0.40, 0.50, 0.16, 0.22, 0.28],
          // Defensive recovery runs
          [0.22, 0.50, 0.05, 0.10, 0.20],
          // Pressing high
          [0.55, 0.50, 0.05, 0.12, 0.18],
          // Transitional play
          [0.35, 0.40, 0.04, 0.12, 0.16],
          [0.35, 0.60, 0.04, 0.12, 0.16],
        ];
        break;
      case 'CAM':
      case 'AM':
        clusters = [
          // Between lines (PRIMARY)
          [0.58, 0.50, 0.15, 0.10, 0.16],
          // Drifting left
          [0.55, 0.32, 0.10, 0.08, 0.12],
          // Drifting right
          [0.55, 0.68, 0.10, 0.08, 0.12],
          // Dropping to receive
          [0.42, 0.50, 0.10, 0.10, 0.18],
          // Final third
          [0.70, 0.45, 0.08, 0.06, 0.12],
          [0.70, 0.55, 0.08, 0.06, 0.12],
          // Edge of box
          [0.78, 0.50, 0.06, 0.05, 0.10],
          // Wide involvement
          [0.50, 0.20, 0.04, 0.06, 0.08],
          [0.50, 0.80, 0.04, 0.06, 0.08],
          // Movement corridor (wide roaming)
          [0.52, 0.50, 0.18, 0.18, 0.22],
          // Pressing
          [0.65, 0.50, 0.07, 0.10, 0.16],
        ];
        break;
      case 'LW':
        clusters = [
          // Left wing primary zone
          [0.62, 0.82, 0.14, 0.10, 0.08],
          // Cutting inside
          [0.68, 0.65, 0.10, 0.08, 0.10],
          // Hugging touchline
          [0.55, 0.90, 0.08, 0.08, 0.05],
          // Pressing from front
          [0.72, 0.75, 0.06, 0.06, 0.08],
          // Coming short
          [0.48, 0.72, 0.08, 0.10, 0.12],
          // In the box
          [0.82, 0.55, 0.06, 0.05, 0.10],
          // Tracking back
          [0.35, 0.82, 0.06, 0.08, 0.08],
          // Central involvement
          [0.55, 0.55, 0.06, 0.08, 0.14],
          // Movement corridor (wide)
          [0.55, 0.78, 0.20, 0.18, 0.15],
          // Crossing area
          [0.75, 0.92, 0.05, 0.05, 0.04],
          // Defensive duty
          [0.30, 0.78, 0.05, 0.08, 0.10],
          // Roaming central
          [0.50, 0.60, 0.06, 0.12, 0.18],
        ];
        break;
      case 'RW':
        clusters = [
          [0.62, 0.18, 0.14, 0.10, 0.08],
          [0.68, 0.35, 0.10, 0.08, 0.10],
          [0.55, 0.10, 0.08, 0.08, 0.05],
          [0.72, 0.25, 0.06, 0.06, 0.08],
          [0.48, 0.28, 0.08, 0.10, 0.12],
          [0.82, 0.45, 0.06, 0.05, 0.10],
          [0.35, 0.18, 0.06, 0.08, 0.08],
          [0.55, 0.45, 0.06, 0.08, 0.14],
          [0.55, 0.22, 0.20, 0.18, 0.15],
          [0.75, 0.08, 0.05, 0.05, 0.04],
          [0.30, 0.22, 0.05, 0.08, 0.10],
          [0.50, 0.40, 0.06, 0.12, 0.18],
        ];
        break;
      case 'LM':
        clusters = [
          [0.42, 0.80, 0.15, 0.10, 0.10],
          [0.55, 0.82, 0.10, 0.08, 0.08],
          [0.30, 0.75, 0.10, 0.08, 0.10],
          [0.45, 0.60, 0.08, 0.08, 0.14],
          [0.60, 0.88, 0.06, 0.06, 0.05],
          [0.25, 0.82, 0.08, 0.06, 0.08],
          [0.40, 0.50, 0.06, 0.10, 0.18],
          [0.42, 0.75, 0.20, 0.18, 0.18],
          [0.35, 0.65, 0.10, 0.12, 0.15],
          [0.20, 0.78, 0.07, 0.06, 0.08],
        ];
        break;
      case 'RM':
        clusters = [
          [0.42, 0.20, 0.15, 0.10, 0.10],
          [0.55, 0.18, 0.10, 0.08, 0.08],
          [0.30, 0.25, 0.10, 0.08, 0.10],
          [0.45, 0.40, 0.08, 0.08, 0.14],
          [0.60, 0.12, 0.06, 0.06, 0.05],
          [0.25, 0.18, 0.08, 0.06, 0.08],
          [0.40, 0.50, 0.06, 0.10, 0.18],
          [0.42, 0.25, 0.20, 0.18, 0.18],
          [0.35, 0.35, 0.10, 0.12, 0.15],
          [0.20, 0.22, 0.07, 0.06, 0.08],
        ];
        break;
      case 'ST':
      case 'CF':
        clusters = [
          // Central attacking zone (PRIMARY - wide)
          [0.72, 0.50, 0.14, 0.08, 0.16],
          // Left channel
          [0.70, 0.35, 0.08, 0.08, 0.10],
          // Right channel
          [0.70, 0.65, 0.08, 0.08, 0.10],
          // In the box
          [0.85, 0.50, 0.08, 0.05, 0.12],
          // Dropping deep to link
          [0.58, 0.48, 0.10, 0.10, 0.16],
          // Pressing from front - left
          [0.78, 0.35, 0.05, 0.06, 0.08],
          // Pressing from front - right
          [0.78, 0.65, 0.05, 0.06, 0.08],
          // Left wing involvement
          [0.62, 0.22, 0.04, 0.06, 0.08],
          // Right wing involvement
          [0.62, 0.78, 0.04, 0.06, 0.08],
          // Movement corridor (wide)
          [0.65, 0.50, 0.20, 0.16, 0.22],
          // Near post runs
          [0.88, 0.40, 0.04, 0.04, 0.06],
          // Far post runs
          [0.88, 0.60, 0.04, 0.04, 0.06],
          // Dropping to midfield
          [0.48, 0.50, 0.06, 0.10, 0.18],
        ];
        break;
      default: // generic midfielder
        clusters = [
          [0.42, 0.50, 0.18, 0.12, 0.20],
          [0.35, 0.40, 0.10, 0.10, 0.15],
          [0.35, 0.60, 0.10, 0.10, 0.15],
          [0.50, 0.50, 0.12, 0.10, 0.16],
          [0.28, 0.50, 0.10, 0.08, 0.18],
          [0.55, 0.40, 0.06, 0.08, 0.12],
          [0.55, 0.60, 0.06, 0.08, 0.12],
          [0.40, 0.50, 0.18, 0.18, 0.24],
          [0.45, 0.30, 0.05, 0.08, 0.10],
          [0.45, 0.70, 0.05, 0.08, 0.10],
        ];
    }

    final totalW = clusters.fold<double>(0, (s, c) => s + c[2]);
    final points = <List<double>>[];

    for (final c in clusters) {
      final cx = c[0], cy = c[1], w = c[2], sx = c[3], sy = c[4];
      final n = (t * w / totalW).round().clamp(1, t);
      for (int i = 0; i < n; i++) {
        final u1 = rng.nextDouble();
        final u2 = rng.nextDouble();
        final z0 = sqrt(-2.0 * log(u1 + 1e-10)) * cos(2.0 * pi * u2);
        final z1 = sqrt(-2.0 * log(u1 + 1e-10)) * sin(2.0 * pi * u2);
        final px = (cx + z0 * sx).clamp(0.05, 0.95);
        final py = (cy + z1 * sy).clamp(0.05, 0.95);
        points.add([px, py]);
      }
    }
    return points;
  }
}


// ═══════════════════════════════════════════════════════════════════
//  PLAYER SHOT MAP CARD — interattivo, mezzo campo verticale
// ═══════════════════════════════════════════════════════════════════

class PlayerShotMapCard extends StatefulWidget {
  final List<ShotData> shots;
  final Color teamColor;
  final bool isDark;

  const PlayerShotMapCard({
    super.key,
    required this.shots,
    required this.teamColor,
    required this.isDark,
  });

  @override
  State<PlayerShotMapCard> createState() => _PlayerShotMapCardState();
}

class _PlayerShotMapCardState extends State<PlayerShotMapCard> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.shots.isEmpty) return const SizedBox.shrink();

    final tx = widget.isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = widget.isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = widget.isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final sel = _selectedIndex != null ? widget.shots[_selectedIndex!] : null;

    final goals = widget.shots.where((s) => s.type == 'goal').length;
    final onTarget = widget.shots.where((s) => s.type == 'on_target').length;
    final offTarget = widget.shots.where((s) => s.type == 'off_target').length;
    final blocked = widget.shots.where((s) => s.type == 'blocked').length;
    final totalXg = widget.shots.fold(0.0, (sum, s) => sum + s.xG);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Icon(Icons.gps_fixed_rounded, size: 18, color: widget.teamColor),
            SizedBox(width: 8),
            Text(tr(context, 'Mappa tiri'),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tx)),
            const Spacer(),
            // Minute chips
            ...List.generate(widget.shots.length, (i) {
              final s = widget.shots[i];
              final isSel = i == _selectedIndex;
              return Padding(
                padding: const EdgeInsets.only(left: 6),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedIndex = _selectedIndex == i ? null : i;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSel
                          ? _shotColor(s.type)
                          : (widget.isDark
                              ? Colors.white.withOpacity(0.08)
                              : Colors.black.withOpacity(0.06)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text("${s.minute}'",
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSel
                                ? (s.type == 'on_target' ? Colors.black : Colors.white)
                                : lb)),
                  ),
                ),
              );
            }),
          ]),
        ),
        const SizedBox(height: 10),

        // Goal frame + details (only when selected)
        if (sel != null) ...[
          _buildGoalFrame(sel),
          _buildShotDetails(sel, tx, lb),
        ],

        // Shot map
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 1.1,
              child: LayoutBuilder(builder: (ctx, constraints) {
                final fw = constraints.maxWidth;
                final fh = constraints.maxHeight;
                return GestureDetector(
                  onTapUp: (d) => _onTapShot(d, fw, fh),
                  child: CustomPaint(
                    painter: _PlayerShotMapPainter(
                      shots: widget.shots,
                      isDark: widget.isDark,
                      selectedIndex: _selectedIndex,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Stats summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            if (goals > 0)
              _statRow('Gol', '$goals', Color(0xFF4CAF50), tx, lb),
            _statRow('xG totale', totalXg.toStringAsFixed(2), widget.teamColor, tx, lb),
            _statRow(tr(context, 'Tiri in porta'), '${goals + onTarget}', Color(0xFF2196F3), tx, lb),
            if (offTarget > 0)
              _statRow(tr(context, 'Tiri fuori'), '$offTarget', Color(0xFFFF9800), tx, lb),
            if (blocked > 0)
              _statRow(tr(context, 'Tiri respinti'), '$blocked', Color(0xFF9E9E9E), tx, lb),
          ]),
        ),
        const SizedBox(height: 14),
      ]),
    );
  }

  Color _shotColor(String type) {
    switch (type) {
      case 'goal': return const Color(0xFF4CAF50);
      case 'on_target': return const Color(0xFFFFEB3B);
      case 'off_target': return const Color(0xFFFF5722);
      case 'blocked': return const Color(0xFF9E9E9E);
      default: return Colors.white;
    }
  }

  void _onTapShot(TapUpDetails details, double fw, double fh) {
    final tapX = details.localPosition.dx;
    final tapY = details.localPosition.dy;
    int? closest;
    double closestDist = 30;
    for (int i = 0; i < widget.shots.length; i++) {
      final s = widget.shots[i];
      final sx = s.startX * fw;
      final sy = (0.08 + s.startY * 0.82) * fh;
      final dist = sqrt(pow(tapX - sx, 2) + pow(tapY - sy, 2));
      if (dist < closestDist) {
        closestDist = dist;
        closest = i;
      }
    }
    setState(() {
      _selectedIndex = closest == _selectedIndex ? null : closest;
    });
  }

  Widget _buildGoalFrame(ShotData shot) {
    final goalX = (shot.goalX ?? 0.5).clamp(0.0, 1.0);
    final goalY = (shot.goalY ?? 0.5).clamp(0.0, 1.0);
    final isOnTarget = shot.type == 'goal' || shot.type == 'on_target';
    final dotColor = _shotColor(shot.type);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: widget.isDark
                ? Colors.white.withOpacity(0.04)
                : Colors.black.withOpacity(0.03),
          ),
          padding: const EdgeInsets.all(8),
          child: SizedBox(
            width: 220,
            height: 72,
            child: CustomPaint(
              painter: _GoalFramePainter(
                goalX: goalX,
                goalY: goalY,
                dotColor: dotColor,
                isDark: widget.isDark,
                isOnTarget: isOnTarget,
                shotType: shot.type,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShotDetails(ShotData shot, Color tx, Color lb) {
    final detailBg = widget.isDark ? const Color(0xFF262626) : const Color(0xFFEEEEEE);
    final col = _shotColor(shot.type);

    String esito;
    switch (shot.type) {
      case 'goal': esito = 'Gol'; break;
      case 'on_target': esito = 'Parato'; break;
      case 'off_target': esito = 'Fuori'; break;
      case 'blocked': esito = 'Respinto'; break;
      default: esito = shot.type;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: detailBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: col.withOpacity(0.25), width: 1),
        ),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: col.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text("${shot.minute}'",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: col)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    _detailChip('xG', shot.xG.toStringAsFixed(2), tx, lb),
                    if (shot.xGOT != null && shot.xGOT! > 0) ...[
                      const SizedBox(width: 10),
                      _detailChip('xGOT', shot.xGOT!.toStringAsFixed(2), tx, lb),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (shot.situation != null && shot.situation!.isNotEmpty) shot.situation!,
                      if (shot.shotType != null && shot.shotType!.isNotEmpty) shot.shotType!,
                    ].join(' · '),
                    style: TextStyle(fontSize: 11, color: lb),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: col.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: col.withOpacity(0.3), width: 1),
            ),
            child: Text(esito,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: col)),
          ),
        ]),
      ),
    );
  }

  Widget _detailChip(String label, String value, Color tx, Color lb) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$label ', style: TextStyle(fontSize: 11, color: lb)),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: tx)),
    ]);
  }

  Widget _statRow(String label, String value, Color vc, Color tx, Color lb) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Text(label, style: TextStyle(fontSize: 13, color: lb)),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: vc)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  GOAL FRAME — porta frontale con rete
//  Mostra pallino: DENTRO porta per goal/on_target,
//                  FUORI porta per off_target
// ═══════════════════════════════════════════════════════════════════

class _GoalFramePainter extends CustomPainter {
  final double goalX, goalY;
  final Color dotColor;
  final bool isDark, isOnTarget;
  final String shotType;

  _GoalFramePainter({
    required this.goalX,
    required this.goalY,
    required this.dotColor,
    required this.isDark,
    required this.isOnTarget,
    required this.shotType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // The goal frame is centered, with margin for off-target dots
    final margin = 28.0;
    final frameLeft = margin;
    final frameRight = w - margin;
    final frameW = frameRight - frameLeft;
    final frameTop = 6.0;
    final frameBottom = h - 6.0;
    final frameH = frameBottom - frameTop;
    final postW = 4.0;

    // Goal inner area
    final inner = Rect.fromLTWH(
        frameLeft + postW, frameTop + postW, frameW - postW * 2, frameH - postW);

    // Background
    canvas.drawRRect(
        RRect.fromRectAndCorners(inner,
            topLeft: const Radius.circular(2),
            topRight: const Radius.circular(2)),
        Paint()..color = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF0F0F0));

    // Net pattern
    final netPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.grey[500]!).withOpacity(0.12)
      ..strokeWidth = 0.5;
    for (double x = inner.left; x <= inner.right; x += 12) {
      canvas.drawLine(Offset(x, inner.top), Offset(x, inner.bottom), netPaint);
    }
    for (double y = inner.top; y <= inner.bottom; y += 10) {
      canvas.drawLine(Offset(inner.left, y), Offset(inner.right, y), netPaint);
    }

    // Goal frame (posts + crossbar)
    final framePaint = Paint()
      ..color = isDark ? Colors.white.withOpacity(0.85) : const Color(0xFF424242)
      ..strokeWidth = postW
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final framePath = Path()
      ..moveTo(frameLeft + postW / 2, frameBottom)
      ..lineTo(frameLeft + postW / 2, frameTop + postW / 2)
      ..lineTo(frameRight - postW / 2, frameTop + postW / 2)
      ..lineTo(frameRight - postW / 2, frameBottom);
    canvas.drawPath(framePath, framePaint);

    // Ground line
    canvas.drawLine(
        Offset(frameLeft - 8, frameBottom),
        Offset(frameRight + 8, frameBottom),
        Paint()
          ..color = isDark
              ? const Color(0xFF2E7D32).withOpacity(0.6)
              : const Color(0xFF4CAF50).withOpacity(0.4)
          ..strokeWidth = 3);

    // ── Impact dot ──
    if (isOnTarget) {
      // Goal / on-target: dot INSIDE the frame
      final dx = inner.left + goalX * inner.width;
      final dy = inner.top + goalY * inner.height;
      _drawDot(canvas, dx, dy, dotColor, shotType == 'goal');
    } else if (shotType == 'off_target') {
      // Off-target: dot OUTSIDE the frame
      // Determine where the shot went based on goalX/goalY
      double dx, dy;
      final rawX = goalX;
      final rawY = goalY;

      // If shot went wide (left or right)
      if (rawX <= 0.3) {
        // Went wide left — dot to the left of left post
        dx = frameLeft - 14;
        dy = inner.top + rawY * inner.height;
      } else if (rawX >= 0.7) {
        // Went wide right — dot to the right of right post
        dx = frameRight + 14;
        dy = inner.top + rawY * inner.height;
      } else {
        // Went over the bar — dot above crossbar
        dx = inner.left + rawX * inner.width;
        dy = frameTop - 10;
      }
      _drawDot(canvas, dx, dy, dotColor, false);
    }
  }

  void _drawDot(Canvas canvas, double dx, double dy, Color col, bool isGoal) {
    // Glow
    canvas.drawCircle(Offset(dx, dy), 11, Paint()..color = col.withOpacity(0.2));
    // Shadow
    canvas.drawCircle(Offset(dx, dy + 1), 6, Paint()..color = Colors.black26);
    // Fill
    canvas.drawCircle(Offset(dx, dy), 6, Paint()..color = col);
    // Border
    canvas.drawCircle(
        Offset(dx, dy),
        6,
        Paint()
          ..color = Colors.white.withOpacity(0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    if (isGoal) {
      canvas.drawCircle(Offset(dx, dy), 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _GoalFramePainter old) =>
      goalX != old.goalX || goalY != old.goalY ||
      dotColor != old.dotColor || shotType != old.shotType;
}

// ═══════════════════════════════════════════════════════════════════
//  HEATMAP PAINTER
// ═══════════════════════════════════════════════════════════════════





class _AttackArrowPainter extends CustomPainter {
  final bool isDark;
  _AttackArrowPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final y = h / 2;
    final color = isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF424242);

    // Shaft
    canvas.drawLine(
      Offset(4, y),
      Offset(w - 12, y),
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Filled triangle head
    final path = Path()
      ..moveTo(w - 2, y)
      ..lineTo(w - 14, y - 5.5)
      ..lineTo(w - 14, y + 5.5)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _AttackArrowPainter old) => false;
}

class _PlayerHeatmapPainter extends CustomPainter {
  final List<List<double>> touchPoints;
  final bool isDark;
  final bool isHome;
  // Ultra-high res grid: ~1px cells on typical screen
  static const _gridW = 400, _gridH = 267;

  _PlayerHeatmapPainter({
    required this.touchPoints,
    required this.isDark,
    this.isHome = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // 1. SofaScore light mint-green field
    _paintField(canvas, size);

    // 2. Clip & draw heatmap
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h), const Radius.circular(4)));

    // Build KDE density grid
    final grid = List<double>.filled(_gridW * _gridH, 0);
    final sigma = 15.0; // Large sigma = smooth, spread out heat
    final kernelR = (sigma * 2.5).ceil();

    for (final p in touchPoints) {
      final gx = (p[0] * _gridW).round().clamp(0, _gridW - 1);
      final gy = (p[1] * _gridH).round().clamp(0, _gridH - 1);
      for (int dy = -kernelR; dy <= kernelR; dy++) {
        for (int dx = -kernelR; dx <= kernelR; dx++) {
          final nx = gx + dx, ny = gy + dy;
          if (nx < 0 || nx >= _gridW || ny < 0 || ny >= _gridH) continue;
          final dist2 = (dx * dx + dy * dy).toDouble();
          grid[ny * _gridW + nx] += exp(-dist2 / (2 * sigma * sigma));
        }
      }
    }

    double maxVal = 0;
    for (final v in grid) { if (v > maxVal) maxVal = v; }
    if (maxVal < 0.001) maxVal = 0.001;

    final cellW = w / _gridW;
    final cellH = h / _gridH;

    // Render with overlapping ovals
    for (int r = 0; r < _gridH; r++) {
      for (int c = 0; c < _gridW; c++) {
        final v = grid[r * _gridW + c];
        if (v <= 0) continue;
        final t = (v / maxVal).clamp(0.0, 1.0);
        if (t < 0.05) continue; // Clean edges

        // Linear opacity, capped low for translucent watercolor look
        final alpha = (t * 0.72).clamp(0.0, 0.72);

        canvas.drawOval(
          Rect.fromLTWH(
            c * cellW - cellW * 0.5,
            r * cellH - cellH * 0.5,
            cellW * 2.0,
            cellH * 2.0,
          ),
          Paint()..color = _heatColor(t).withOpacity(alpha),
        );
      }
    }
    canvas.restore();

    // 3. Field lines on top
    _paintFieldLines(canvas, size);

    // Arrow moved to widget title row
  }

  Color _heatColor(double t) {
    // Vivid palette for dark green field:
    // lime → yellow → amber → orange → deep orange → red
    if (t < 0.10) {
      return Color.lerp(
        const Color(0xFFAED581), const Color(0xFFDCE775), t / 0.10)!;
    } else if (t < 0.28) {
      return Color.lerp(
        const Color(0xFFDCE775), const Color(0xFFFFF176), (t - 0.10) / 0.18)!;
    } else if (t < 0.45) {
      return Color.lerp(
        const Color(0xFFFFF176), const Color(0xFFFFD54F), (t - 0.28) / 0.17)!;
    } else if (t < 0.60) {
      return Color.lerp(
        const Color(0xFFFFD54F), const Color(0xFFFFB74D), (t - 0.45) / 0.15)!;
    } else if (t < 0.75) {
      return Color.lerp(
        const Color(0xFFFFB74D), const Color(0xFFFF8A65), (t - 0.60) / 0.15)!;
    } else if (t < 0.88) {
      return Color.lerp(
        const Color(0xFFFF8A65), const Color(0xFFFF5722), (t - 0.75) / 0.13)!;
    } else {
      return Color.lerp(
        const Color(0xFFFF5722), const Color(0xFFE53935), (t - 0.88) / 0.12)!;
    }
  }

  void _drawArrow(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final arrowY = h * 0.06;

    // SofaScore style: thick bold white arrow
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.70)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final startX = isHome ? w * 0.35 : w * 0.65;
    final endX = isHome ? w * 0.62 : w * 0.38;

    // Shaft
    canvas.drawLine(Offset(startX, arrowY), Offset(endX, arrowY), paint);

    // Arrowhead — filled triangle
    final dir = isHome ? 1.0 : -1.0;
    final tipX = endX + dir * 2;
    final headLen = 16.0;
    final headW = 9.0;
    final path = Path()
      ..moveTo(tipX, arrowY)
      ..lineTo(tipX - headLen * dir, arrowY - headW)
      ..lineTo(tipX - headLen * dir, arrowY + headW)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white.withOpacity(0.70));
  }

  void _paintField(Canvas canvas, Size size) {
    // SofaScore: light mint green, NOT dark forest green
    final bgColor = isDark
        ? const Color(0xFF1E3B1E)
        : const Color(0xFF388E3C); // Official dark green field
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = bgColor);

    // Subtle grass stripes
    final sH = size.height / 16;
    for (int i = 0; i < 16; i++) {
      if (i.isEven) {
        canvas.drawRect(Rect.fromLTWH(0, i * sH, size.width, sH),
            Paint()..color = Colors.white.withOpacity(isDark ? 0.015 : 0.025));
      }
    }
  }

  void _paintFieldLines(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final lp = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.30 : 0.40)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final dp = Paint()..color = Colors.white.withOpacity(isDark ? 0.30 : 0.40);

    // Boundary
    canvas.drawRect(Rect.fromLTWH(1, 1, w - 2, h - 2), lp);
    // Center line
    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), lp);
    // Center circle
    canvas.drawCircle(Offset(w / 2, h / 2), min(w, h) * 0.14, lp);
    canvas.drawCircle(Offset(w / 2, h / 2), 2.5, dp);

    // Penalty areas
    final penW = w * 0.15, penH = h * 0.54;
    final penTop = (h - penH) / 2;
    canvas.drawRect(Rect.fromLTWH(0, penTop, penW, penH), lp);
    canvas.drawRect(Rect.fromLTWH(w - penW, penTop, penW, penH), lp);

    // Goal areas
    final gaW = w * 0.055, gaH = h * 0.28;
    final gaTop = (h - gaH) / 2;
    canvas.drawRect(Rect.fromLTWH(0, gaTop, gaW, gaH), lp);
    canvas.drawRect(Rect.fromLTWH(w - gaW, gaTop, gaW, gaH), lp);

    // Penalty spots
    canvas.drawCircle(Offset(penW * 0.78, h / 2), 2, dp);
    canvas.drawCircle(Offset(w - penW * 0.78, h / 2), 2, dp);

    // Penalty arcs
    final penDotXL = penW * 0.78;
    final penDotXR = w - penDotXL;
    final arcR = penW * 0.55;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(penW, 0, w - penW * 2, h));
    canvas.drawArc(
        Rect.fromCircle(center: Offset(penDotXL, h / 2), radius: arcR),
        -pi / 2, pi, false, lp);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(penDotXR, h / 2), radius: arcR),
        pi / 2, pi, false, lp);
    canvas.restore();

    // Corner arcs
    final cR = w * 0.02;
    canvas.drawArc(Rect.fromCircle(center: const Offset(0, 0), radius: cR), 0, pi / 2, false, lp);
    canvas.drawArc(Rect.fromCircle(center: Offset(w, 0), radius: cR), pi / 2, pi / 2, false, lp);
    canvas.drawArc(Rect.fromCircle(center: Offset(0, h), radius: cR), -pi / 2, pi / 2, false, lp);
    canvas.drawArc(Rect.fromCircle(center: Offset(w, h), radius: cR), pi, pi / 2, false, lp);
  }

  @override
  bool shouldRepaint(covariant _PlayerHeatmapPainter old) => true;
}


// ═══════════════════════════════════════════════════════════════════
//  SHOT MAP PAINTER — traiettoria SOLO per il tiro selezionato
//
//  LOGICA TRAIETTORIE:
//  • goal / on_target → linea tratteggiata completa fino alla porta
//  • off_target → linea tratteggiata fino a y=0 (fuori specchio)
//  • blocked → linea interrotta al 40% + X nel punto blocco
// ═══════════════════════════════════════════════════════════════════

class _PlayerShotMapPainter extends CustomPainter {
  final List<ShotData> shots;
  final bool isDark;
  final int? selectedIndex;

  _PlayerShotMapPainter({
    required this.shots,
    required this.isDark,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Field background
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..color = isDark ? const Color(0xFF1A3A1A) : const Color(0xFF2E7D32));
    final stripeW = w / 8;
    for (int i = 0; i < 8; i++) {
      if (i.isEven) {
        canvas.drawRect(Rect.fromLTWH(i * stripeW, 0, stripeW, h),
            Paint()..color = Colors.white.withOpacity(0.025));
      }
    }

    final lp = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final dp = Paint()..color = Colors.white.withOpacity(0.35);

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), lp);

    // Penalty box
    final penBoxW = w * 0.593;
    final penBoxH = h * 0.24;
    final penBoxLeft = (w - penBoxW) / 2;
    canvas.drawRect(Rect.fromLTWH(penBoxLeft, 0, penBoxW, penBoxH), lp);

    // 6-yard box
    final sixW = w * 0.269;
    final sixH = h * 0.08;
    final sixLeft = (w - sixW) / 2;
    canvas.drawRect(Rect.fromLTWH(sixLeft, 0, sixW, sixH), lp);

    // Penalty dot + arc
    final penDotY = penBoxH * 0.72;
    canvas.drawCircle(Offset(w / 2, penDotY), 2.5, dp);
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, penBoxH, w, h - penBoxH));
    final arcR = penBoxH * 0.65;
    canvas.drawArc(Rect.fromCircle(center: Offset(w / 2, penDotY), radius: arcR),
        0, pi, false, lp);
    canvas.restore();

    // Goal
    final goalW = w * 0.12;
    final goalLeft = (w - goalW) / 2;
    final goalH = h * 0.03;
    canvas.drawRect(Rect.fromLTWH(goalLeft, -goalH, goalW, goalH),
        Paint()..color = Colors.white.withOpacity(0.2));
    canvas.drawRect(Rect.fromLTWH(goalLeft, -goalH, goalW, goalH), lp);

    // Half-way arc
    final centerR = h * 0.18;
    canvas.drawArc(Rect.fromCircle(center: Offset(w / 2, h), radius: centerR),
        pi, pi, false, lp);
    canvas.drawCircle(Offset(w / 2, h), 2, dp);

    // Corner arcs
    final cR = w * 0.025;
    canvas.drawArc(Rect.fromCircle(center: const Offset(0, 0), radius: cR), 0, pi / 2, false, lp);
    canvas.drawArc(Rect.fromCircle(center: Offset(w, 0), radius: cR), pi / 2, pi / 2, false, lp);

    // ══════════════════════════════════════════════════
    //  DRAW SHOTS
    // ══════════════════════════════════════════════════
    for (int i = 0; i < shots.length; i++) {
      final shot = shots[i];
      final sx = shot.startX * w;
      final sy = (0.08 + shot.startY * 0.82) * h;
      final isSel = i == selectedIndex;

      Color col;
      double radius;
      bool filled = true;

      switch (shot.type) {
        case 'goal':
          col = const Color(0xFF4CAF50);
          radius = isSel ? 16 : 14;
          break;
        case 'on_target':
          col = const Color(0xFFFFEB3B);
          radius = isSel ? 13 : 11;
          break;
        case 'off_target':
          col = const Color(0xFFFF5722);
          radius = isSel ? 12 : 10;
          filled = false;
          break;
        case 'blocked':
          col = const Color(0xFF9E9E9E);
          radius = isSel ? 12 : 10;
          break;
        default:
          col = Colors.white;
          radius = 9;
      }

      // ── Trajectory — ONLY for selected shot ──
      if (isSel) {
        final trajPaint = Paint()
          ..color = col.withOpacity(0.7)
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;

        if (shot.type == 'goal' || shot.type == 'on_target') {
          // Full dashed line to exact goal position
          final gx = goalLeft + goalW * (shot.goalX ?? 0.5);
          const gy = 0.0;
          canvas.drawPath(
              _dashPath(Path()..moveTo(sx, sy)..lineTo(gx, gy), 5, 3),
              trajPaint);
        } else if (shot.type == 'off_target') {
          // Full dashed line past the goal (misses wide/high)
          final rawGoalX = shot.goalX ?? 0.5;
          double missX;
          if (rawGoalX <= 0.3) {
            missX = rawGoalX - 0.3; // wide left
          } else if (rawGoalX >= 0.7) {
            missX = rawGoalX + 0.3; // wide right
          } else {
            missX = rawGoalX; // went over
          }
          final gx = goalLeft + goalW * missX;
          const gy = 0.0;
          canvas.drawPath(
              _dashPath(Path()..moveTo(sx, sy)..lineTo(gx, gy), 5, 3),
              trajPaint);
        } else if (shot.type == 'blocked') {
          // Dashed line stops at ~40% + X marker
          final gx = goalLeft + goalW * (shot.goalX ?? 0.5);
          const gy = 0.0;
          const endFrac = 0.4;
          final ex = sx + (gx - sx) * endFrac;
          final ey = sy + (gy - sy) * endFrac;
          canvas.drawPath(
              _dashPath(Path()..moveTo(sx, sy)..lineTo(ex, ey), 5, 3),
              trajPaint);
          // X at block point
          const xSz = 6.0;
          final xP = Paint()
            ..color = isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF333333)
            ..strokeWidth = 3.0
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(Offset(ex - xSz, ey - xSz), Offset(ex + xSz, ey + xSz), xP);
          canvas.drawLine(Offset(ex + xSz, ey - xSz), Offset(ex - xSz, ey + xSz), xP);
        }
      }

      // ── Selection ring ──
      if (isSel) {
        canvas.drawCircle(Offset(sx, sy), radius + 5,
            Paint()
              ..color = col.withOpacity(0.25)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
      }

      // ── Shot dot ──
      if (filled) {
        canvas.drawCircle(Offset(sx, sy + 1), radius, Paint()..color = Colors.black26);
        canvas.drawCircle(Offset(sx, sy), radius, Paint()..color = col);
        canvas.drawCircle(Offset(sx, sy), radius,
            Paint()
              ..color = Colors.white.withOpacity(0.8)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
        if (shot.type == 'goal') {
          canvas.drawCircle(Offset(sx, sy), 3.5, Paint()..color = Colors.white);
        }
      } else {
        // Off-target: open circle with X inside
        canvas.drawCircle(Offset(sx, sy), radius,
            Paint()
              ..color = col
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.5);
        final xS = radius * 0.45;
        final xP = Paint()
          ..color = col.withOpacity(0.8)
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(sx - xS, sy - xS), Offset(sx + xS, sy + xS), xP);
        canvas.drawLine(Offset(sx + xS, sy - xS), Offset(sx - xS, sy + xS), xP);
      }

      // ── xG label ──
      if (shot.xG > 0.05 && (selectedIndex == null || isSel)) {
        final tp = TextPainter(
          text: TextSpan(
              text: shot.xG.toStringAsFixed(2),
              style: TextStyle(
                  fontSize: isSel ? 12 : 10,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w600)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(sx + radius + 4, sy - tp.height / 2));
      }
    }

    // Legend
    final legendY = h - 18.0;
    final items = [
      ('Gol', Color(0xFF4CAF50)),
      ('In porta', Color(0xFFFFEB3B)),
      ('Fuori', const Color(0xFFFF5722)),
      ('Bloccato', const Color(0xFF9E9E9E)),
    ];
    final startX = w / 2 - (items.length * 56) / 2;
    for (int i = 0; i < items.length; i++) {
      final lx = startX + i * 56;
      canvas.drawCircle(Offset(lx, legendY), 4, Paint()..color = items[i].$2);
      final tp = TextPainter(
        text: TextSpan(text: items[i].$1,
            style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.75), fontWeight: FontWeight.w500)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(lx + 7, legendY - tp.height / 2));
    }
  }

  Path _dashPath(Path source, double dash, double gap) {
    final result = Path();
    for (final m in source.computeMetrics()) {
      double d = 0;
      bool draw = true;
      while (d < m.length) {
        final len = draw ? dash : gap;
        final next = (d + len).clamp(0.0, m.length);
        if (draw) result.addPath(m.extractPath(d, next), Offset.zero);
        d = next;
        draw = !draw;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _PlayerShotMapPainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════
//  PLAYER PASS MAP CARD — frecce passaggi da dati reali
//  Passaggi generati deterministicamente da stats giocatore
// ═══════════════════════════════════════════════════════════════════

class _PassArrow {
  final double startX, startY, endX, endY;
  final bool isCompleted;
  final bool isKeyPass;
  final bool isCross;
  _PassArrow({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.isCompleted,
    this.isKeyPass = false,
    this.isCross = false,
  });
}

class PlayerPassMapCard extends StatefulWidget {
  final String playerName;
  final String position;
  final int passes;
  final int passesCompleted;
  final int keyPasses;
  final int crosses;
  final int crossesCompleted;
  final Color teamColor;
  final bool isDark;

  const PlayerPassMapCard({
    super.key,
    required this.playerName,
    required this.position,
    required this.passes,
    required this.passesCompleted,
    this.keyPasses = 0,
    this.crosses = 0,
    this.crossesCompleted = 0,
    required this.teamColor,
    required this.isDark,
  });

  @override
  State<PlayerPassMapCard> createState() => _PlayerPassMapCardState();
}

class _PlayerPassMapCardState extends State<PlayerPassMapCard> {
  int _filter = 0; // 0=tutti, 1=accurato, 2=non accurato

  @override
  Widget build(BuildContext context) {
    if (widget.passes == 0) return const SizedBox.shrink();

    final tx = widget.isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = widget.isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg =
        widget.isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);
    final passAcc = ((widget.passesCompleted / widget.passes) * 100).round();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Icon(Icons.swap_calls_rounded, size: 18, color: widget.teamColor),
            SizedBox(width: 8),
            Text(tr(context, 'Mappa passaggi'),
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: tx)),
            const Spacer(),
            Text(
                '${widget.passesCompleted}/${widget.passes} ($passAcc%)',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: lb)),
          ]),
        ),
        const SizedBox(height: 8),

        // Filter chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            _filterChip(tr(context, 'Tutti i passaggi'), 0, tx, lb),
            const SizedBox(width: 6),
            _filterChip(tr(context, 'Accurato'), 1, tx, lb),
            const SizedBox(width: 6),
            _filterChip(tr(context, 'Non accurato'), 2, tx, lb),
          ]),
        ),
        const SizedBox(height: 8),

        // Pass map — campo orizzontale
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: 1.5,
              child: CustomPaint(
                painter: _PlayerPassMapPainter(
                  arrows: _generateArrows(),
                  isDark: widget.isDark,
                  filter: _filter,
                ),
              ),
            ),
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legendItem(tr(context, 'Accurato'), const Color(0xFF4CAF50)),
            const SizedBox(width: 16),
            _legendItem(tr(context, 'Non accurato'), Color(0xFFEF5350)),
            if (widget.keyPasses > 0) ...[
              SizedBox(width: 16),
              _legendItem(tr(context, 'Passaggio chiave'), Color(0xFFFF9800)),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _legendItem(String label, Color color) {
    final lb = widget.isDark ? Colors.grey[400]! : Colors.grey[600]!;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 14, height: 2.5, color: color),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 9, color: lb)),
    ]);
  }

  Widget _filterChip(String label, int value, Color tx, Color lb) {
    final sel = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel
              ? (widget.isDark ? Colors.white : const Color(0xFF1A1A1A))
              : (widget.isDark
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: sel
                    ? (widget.isDark ? Colors.black : Colors.white)
                    : lb)),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  Generazione deterministica dei passaggi
  //  basata su stats reali del giocatore
  // ══════════════════════════════════════════════════
  List<_PassArrow> _generateArrows() {
    final rng = Random(widget.playerName.hashCode);
    final arrows = <_PassArrow>[];

    // Limita frecce visibili per leggibilità
    final totalVisible = widget.passes.clamp(0, 35);
    if (totalVisible == 0) return [];

    final ratio = totalVisible / widget.passes;
    final completedVisible = (widget.passesCompleted * ratio).round();
    final incompleteVisible = totalVisible - completedVisible;
    final keyVisible = (widget.keyPasses * ratio).round().clamp(0, completedVisible);
    final crossVisible = (widget.crosses * ratio).round().clamp(0, totalVisible);
    final crossCompVisible = (widget.crossesCompleted * ratio).round().clamp(0, crossVisible);

    // Zone base in base alla posizione (campo orizzontale: x=0 porta propria, x=1 porta avversaria)
    double sxMin, sxMax, syMin, syMax; // start zone
    double exBias; // end zone x bias (quanto avanti vanno i passaggi)

    switch (widget.position) {
      case 'GK':
        sxMin = 0.03; sxMax = 0.12; syMin = 0.25; syMax = 0.75; exBias = 0.25;
        break;
      case 'CB':
        sxMin = 0.08; sxMax = 0.28; syMin = 0.15; syMax = 0.85; exBias = 0.30;
        break;
      case 'LB':
        sxMin = 0.08; sxMax = 0.40; syMin = 0.60; syMax = 0.95; exBias = 0.35;
        break;
      case 'RB':
        sxMin = 0.08; sxMax = 0.40; syMin = 0.05; syMax = 0.40; exBias = 0.35;
        break;
      case 'CDM':
        sxMin = 0.22; sxMax = 0.48; syMin = 0.20; syMax = 0.80; exBias = 0.25;
        break;
      case 'CM':
        sxMin = 0.25; sxMax = 0.55; syMin = 0.15; syMax = 0.85; exBias = 0.28;
        break;
      case 'CAM': case 'AM':
        sxMin = 0.38; sxMax = 0.65; syMin = 0.15; syMax = 0.85; exBias = 0.30;
        break;
      case 'LW':
        sxMin = 0.40; sxMax = 0.78; syMin = 0.55; syMax = 0.95; exBias = 0.25;
        break;
      case 'RW':
        sxMin = 0.40; sxMax = 0.78; syMin = 0.05; syMax = 0.45; exBias = 0.25;
        break;
      case 'ST': case 'CF':
        sxMin = 0.50; sxMax = 0.82; syMin = 0.18; syMax = 0.82; exBias = 0.18;
        break;
      default:
        sxMin = 0.20; sxMax = 0.60; syMin = 0.15; syMax = 0.85; exBias = 0.28;
    }

    double _r(double lo, double hi) => lo + rng.nextDouble() * (hi - lo);

    int keyCount = 0;
    int crossCount = 0;

    // Generate completed passes
    for (int i = 0; i < completedVisible; i++) {
      double sx = _r(sxMin, sxMax);
      double sy = _r(syMin, syMax);
      bool isKey = keyCount < keyVisible;
      bool isCross = crossCount < crossCompVisible;

      double ex, ey;
      if (isCross) {
        // Cross: dal lato verso area di rigore
        sx = _r(max(sxMin, 0.55), min(sxMax + 0.15, 0.92));
        sy = widget.position.contains('L') ? _r(0.70, 0.95) : _r(0.05, 0.30);
        ex = _r(0.75, 0.92);
        ey = _r(0.30, 0.70);
        crossCount++;
      } else if (isKey) {
        // Key pass: verso ultimo terzo
        ex = _r(max(sx + 0.05, 0.60), 0.95);
        ey = _r(0.20, 0.80);
        keyCount++;
      } else {
        // Pass normale completato
        ex = sx + _r(-0.12, exBias);
        ey = _r(max(0.05, sy - 0.35), min(0.95, sy + 0.35));
        ex = ex.clamp(0.02, 0.98);
      }
      ey = ey.clamp(0.03, 0.97);

      arrows.add(_PassArrow(
        startX: sx, startY: sy, endX: ex, endY: ey,
        isCompleted: true, isKeyPass: isKey && !isCross, isCross: isCross,
      ));
    }

    // Generate incomplete passes
    int crossIncCount = 0;
    final crossIncVisible = crossVisible - crossCompVisible;
    for (int i = 0; i < incompleteVisible; i++) {
      double sx = _r(sxMin, sxMax);
      double sy = _r(syMin, syMax);
      bool isCross = crossIncCount < crossIncVisible;

      double ex, ey;
      if (isCross) {
        sx = _r(max(sxMin, 0.55), min(sxMax + 0.15, 0.92));
        sy = widget.position.contains('L') ? _r(0.70, 0.95) : _r(0.05, 0.30);
        ex = _r(0.65, 0.90);
        ey = _r(0.25, 0.75);
        crossIncCount++;
      } else {
        ex = sx + _r(-0.15, exBias + 0.10);
        ey = _r(max(0.03, sy - 0.40), min(0.97, sy + 0.40));
        ex = ex.clamp(0.02, 0.98);
      }
      ey = ey.clamp(0.03, 0.97);

      arrows.add(_PassArrow(
        startX: sx, startY: sy, endX: ex, endY: ey,
        isCompleted: false, isCross: isCross,
      ));
    }

    return arrows;
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PASS MAP PAINTER — campo orizzontale con frecce
// ═══════════════════════════════════════════════════════════════════

class _PlayerPassMapPainter extends CustomPainter {
  final List<_PassArrow> arrows;
  final bool isDark;
  final int filter; // 0=all, 1=completed, 2=incomplete

  _PlayerPassMapPainter({
    required this.arrows,
    required this.isDark,
    required this.filter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Field background
    canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()
          ..color = isDark ? const Color(0xFF1A3A1A) : const Color(0xFF2E7D32));

    // Stripes
    final stripeH = h / 12;
    for (int i = 0; i < 12; i++) {
      if (i.isEven) {
        canvas.drawRect(Rect.fromLTWH(0, i * stripeH, w, stripeH),
            Paint()..color = Colors.white.withOpacity(0.025));
      }
    }

    _paintFieldLines(canvas, w, h);

    // Draw arrows
    for (final a in arrows) {
      if (filter == 1 && !a.isCompleted) continue;
      if (filter == 2 && a.isCompleted) continue;

      final sx = a.startX * w;
      final sy = a.startY * h;
      final ex = a.endX * w;
      final ey = a.endY * h;

      Color arrowColor;
      double strokeW;
      if (a.isKeyPass) {
        arrowColor = const Color(0xFFFF9800);
        strokeW = 2.5;
      } else if (a.isCompleted) {
        arrowColor = const Color(0xFF4CAF50);
        strokeW = 2.0;
      } else {
        arrowColor = const Color(0xFFEF5350);
        strokeW = 1.8;
      }

      final paint = Paint()
        ..color = arrowColor.withOpacity(0.8)
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      // Line
      canvas.drawLine(Offset(sx, sy), Offset(ex, ey), paint);

      // Arrowhead
      final angle = atan2(ey - sy, ex - sx);
      final headLen = a.isKeyPass ? 8.0 : 6.0;
      final headAngle = 0.45;
      final p1x = ex - headLen * cos(angle - headAngle);
      final p1y = ey - headLen * sin(angle - headAngle);
      final p2x = ex - headLen * cos(angle + headAngle);
      final p2y = ey - headLen * sin(angle + headAngle);

      final headPaint = Paint()
        ..color = arrowColor.withOpacity(0.8)
        ..strokeWidth = strokeW
        ..style = PaintingStyle.fill;
      final headPath = Path()
        ..moveTo(ex, ey)
        ..lineTo(p1x, p1y)
        ..lineTo(p2x, p2y)
        ..close();
      canvas.drawPath(headPath, headPaint);

      // Start dot
      canvas.drawCircle(
          Offset(sx, sy), 2.0, Paint()..color = arrowColor.withOpacity(0.6));
    }
  }

  void _paintFieldLines(Canvas canvas, double w, double h) {
    final lp = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    final dp = Paint()..color = Colors.white.withOpacity(0.35);

    // Border
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), lp);

    // Center line + circle
    canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), lp);
    canvas.drawCircle(Offset(w / 2, h / 2), min(w, h) * 0.14, lp);
    canvas.drawCircle(Offset(w / 2, h / 2), 2, dp);

    // Penalty areas
    final penW = w * 0.14;
    final penH = h * 0.52;
    final penTop = (h - penH) / 2;
    canvas.drawRect(Rect.fromLTWH(0, penTop, penW, penH), lp);
    canvas.drawRect(Rect.fromLTWH(w - penW, penTop, penW, penH), lp);

    // 6-yard boxes
    final sixW = w * 0.05;
    final sixH = h * 0.26;
    final sixTop = (h - sixH) / 2;
    canvas.drawRect(Rect.fromLTWH(0, sixTop, sixW, sixH), lp);
    canvas.drawRect(Rect.fromLTWH(w - sixW, sixTop, sixW, sixH), lp);

    // Penalty dots
    canvas.drawCircle(Offset(penW * 0.78, h / 2), 2, dp);
    canvas.drawCircle(Offset(w - penW * 0.78, h / 2), 2, dp);

    // Penalty arcs
    final penDotXL = penW * 0.78;
    final penDotXR = w - penDotXL;
    final arcR = penW * 0.55;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(penW, 0, w - penW * 2, h));
    canvas.drawArc(
        Rect.fromCircle(center: Offset(penDotXL, h / 2), radius: arcR),
        -pi / 2, pi, false, lp);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(penDotXR, h / 2), radius: arcR),
        pi / 2, pi, false, lp);
    canvas.restore();

    // Corner arcs
    final cR = w * 0.02;
    canvas.drawArc(Rect.fromCircle(center: const Offset(0, 0), radius: cR),
        0, pi / 2, false, lp);
    canvas.drawArc(Rect.fromCircle(center: Offset(w, 0), radius: cR),
        pi / 2, pi / 2, false, lp);
    canvas.drawArc(Rect.fromCircle(center: Offset(0, h), radius: cR),
        -pi / 2, pi / 2, false, lp);
    canvas.drawArc(Rect.fromCircle(center: Offset(w, h), radius: cR),
        pi, pi / 2, false, lp);
  }

  @override
  bool shouldRepaint(covariant _PlayerPassMapPainter old) =>
      filter != old.filter || arrows != old.arrows;
}

// ═══════════════════════════════════════════════════════════════════
//  PLAYER DEFENSIVE MAP CARD — stile identico a sezione Avanzate
//  Usa RealisticSoccerFieldPainter + marker tackle/intercept
// ═══════════════════════════════════════════════════════════════════

class PlayerDefensiveMapCard extends StatelessWidget {
  final List<DefensiveActionData> actions;
  final Color teamColor;
  final bool isDark;

  const PlayerDefensiveMapCard({
    super.key,
    required this.actions,
    required this.teamColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5);

    final tackles = actions.where((a) => a.type == 'tackle').length;
    final interceptions = actions.where((a) => a.type == 'interception').length;
    final clearances = actions.where((a) => a.type == 'clearance').length;
    final won = actions.where((a) => a.won).length;

    // Only show tackle + interception on field (like Avanzate)
    final fieldActions =
        actions.where((a) => a.type == 'tackle' || a.type == 'interception').toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(children: [
            Icon(Icons.shield_outlined, size: 18, color: teamColor),
            SizedBox(width: 8),
            Text(tr(context, 'Azioni difensive'),
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700, color: tx)),
            const Spacer(),
            Text('$won/${actions.length} ${tr(context, 'vinte')}',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: lb)),
          ]),
        ),
        const SizedBox(height: 10),

        // Field — orizzontale come in Avanzate
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: LayoutBuilder(builder: (ctx, box) {
            final w = box.maxWidth;
            final h = w * 0.64;
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: w,
                height: h,
                child: Stack(clipBehavior: Clip.hardEdge, children: [
                  Positioned.fill(
                      child: CustomPaint(
                    size: Size(w, h),
                    painter: RealisticSoccerFieldPainter(isDark: isDark),
                  )),
                  Positioned.fill(
                      child: CustomPaint(
                    size: Size(w, h),
                    painter: RealisticSoccerFieldPainter(
                        isDark: isDark, linesOnly: true),
                  )),
                  ...fieldActions.map((a) => _marker(a, w, h)),
                ]),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),

        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legendItem(
                _buildTackleIcon(14, false), 'Contrasto', lb),
            SizedBox(width: 16),
            _legendItem(
                _buildInterceptionIcon(14), tr(context, 'Intercetto'), lb),
            const SizedBox(width: 16),
            _legendVintoPeso(lb),
          ]),
        ),

        // Summary stats
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (tackles > 0)
                  _miniStat(tr(context, 'Contrasti'), '$tackles',
                      Color(0xFFE53935), tx, lb),
                if (interceptions > 0)
                  _miniStat(tr(context, 'Intercetti'), '$interceptions',
                      const Color(0xFFFF9800), tx, lb),
                if (clearances > 0)
                  _miniStat('Chiusure', '$clearances',
                      const Color(0xFFFDD835), tx, lb),
              ]),
        ),
      ]),
    );
  }

  Widget _marker(DefensiveActionData a, double fw, double fh) {
    final x = a.fieldX * fw;
    final y = a.fieldY * fh;
    const markerSize = 36.0;
    final resultBorderColor =
        a.won ? const Color(0xFF4CAF50) : const Color(0xFFE53935);

    return Positioned(
      left: x - markerSize / 2,
      top: y - markerSize / 2,
      child: SizedBox(
        width: markerSize,
        height: markerSize,
        child: Center(child: _markerIcon(a, resultBorderColor)),
      ),
    );
  }

  Widget _markerIcon(DefensiveActionData a, Color resultBorderColor) {
    final color = a.typeColor;
    const size = 22.0;
    const borderW = 2.0;

    switch (a.type) {
      case 'tackle':
        return Container(
          width: size + borderW * 2,
          height: size + borderW * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: resultBorderColor, width: borderW),
          ),
          child: Center(
              child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  RadialGradient(colors: [color, color.withOpacity(0.8)]),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.3), blurRadius: 5)
              ],
            ),
            child: const Center(
                child: Icon(Icons.close, color: Colors.white, size: 12)),
          )),
        );
      case 'interception':
        return SizedBox(
          width: size + borderW * 2,
          height: size + borderW * 2,
          child: CustomPaint(
            size: const Size(size + borderW * 2, size + borderW * 2),
            painter: _TriangleMarkerPainterLocal(
              color: color,
              borderColor: resultBorderColor,
              borderWidth: borderW,
            ),
          ),
        );
      default:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        );
    }
  }

  static Widget _buildTackleIcon(double size, bool filled) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE53935),
      ),
      child: Center(
          child:
              Icon(Icons.close, color: Colors.white, size: size * 0.6)),
    );
  }

  static Widget _buildInterceptionIcon(double size) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MiniTrianglePainterLocal(const Color(0xFFFF9800)),
      ),
    );
  }

  Widget _legendItem(Widget icon, String label, Color lb) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      icon,
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 9, color: lb)),
    ]);
  }

  Widget _legendVintoPeso(Color lb) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF4CAF50), width: 2),
        ),
      ),
      Text(' V ', style: TextStyle(fontSize: 9, color: lb)),
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE53935), width: 2),
        ),
      ),
      Text(' P', style: TextStyle(fontSize: 9, color: lb)),
    ]);
  }

  Widget _miniStat(
      String label, String value, Color color, Color tx, Color lb) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: TextStyle(fontSize: 10, color: lb)),
    ]);
  }
}

// ── Triangle painter locale (copia da Interactive_defensive_widget) ──

class _TriangleMarkerPainterLocal extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double borderWidth;

  _TriangleMarkerPainterLocal({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - borderWidth;
    final path = Path();
    for (int i = 0; i < 3; i++) {
      final angle = (i * 2 * pi / 3) - pi / 2;
      final x = cx + cos(angle) * r;
      final y = cy + sin(angle) * r;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
        path,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _TriangleMarkerPainterLocal old) =>
      borderColor != old.borderColor;
}

class _MiniTrianglePainterLocal extends CustomPainter {
  final Color color;
  _MiniTrianglePainterLocal(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
