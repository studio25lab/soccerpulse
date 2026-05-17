import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../utils/l10n_helper.dart';
import 'package:fl_chart/fl_chart.dart';

enum DefensiveActionType {
  tackleWon,
  interception,
  clearance,
  tackleLost,
}

class DefensiveAction {
  final double x;
  final double y;
  final DefensiveActionType type;
  final int minute;
  final String player;
  final String opponent;
  final String zone;

  DefensiveAction({
    required this.x,
    required this.y,
    required this.type,
    required this.minute,
    required this.player,
    required this.opponent,
    required this.zone,
  });
}

class TopPerformer {
  final String name;
  final String number;
  final int tackles;
  final int tacklesTotal;
  final int interceptions;
  final int aerialDuels;
  final double rating;

  double get tacklePercentage =>
      tacklesTotal > 0 ? (tackles / tacklesTotal * 100) : 0;

  TopPerformer({
    required this.name,
    required this.number,
    required this.tackles,
    required this.tacklesTotal,
    required this.interceptions,
    required this.aerialDuels,
    required this.rating,
  });
}

class DuelsWidget extends StatefulWidget {
  final bool isHome;
  final String homeTeamName;
  final String awayTeamName;

  const DuelsWidget({
    Key? key,
    required this.isHome,
    required this.homeTeamName,
    required this.awayTeamName,
  }) : super(key: key);

  @override
  State<DuelsWidget> createState() => _DuelsWidgetState();
}

class _DuelsWidgetState extends State<DuelsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  String _periodFilter = 'all';
  bool _showComparison = false;
  Set<DefensiveActionType> _visibleActions = DefensiveActionType.values.toSet();
  DefensiveAction? _hoveredAction;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DuelsWidget oldWidget) {
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
          _buildHeader(isDark),
          _buildPeriodFilters(isDark),
          const SizedBox(height: 16),
          _showComparison
              ? _buildComparisonView(isDark)
              : _buildSingleView(isDark),
          const SizedBox(height: 16),
          _buildLegend(isDark),
          const SizedBox(height: 24),
          _buildTopPerformers(isDark),
          const SizedBox(height: 24),
          _buildTimeline(isDark),
          const SizedBox(height: 24),
          _buildDetailedStats(isDark),
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
          Icon(Icons.sports_martial_arts,
              color: Color(0xFFE53935), size: 24),
          SizedBox(width: 8),
          Text(tr(context, 'Duelli'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
          IconButton(
            icon: Icon(
              _showComparison ? Icons.view_agenda : Icons.compare,
              color:
                  _showComparison ? Color(0xFF2196F3) : Colors.grey[600],
            ),
            onPressed: () => setState(() => _showComparison = !_showComparison),
            tooltip: _showComparison ? tr(context, 'Vista singola') : tr(context, 'Confronta squadre'),
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
                  colors: [Color(0xFFE53935), Color(0xFFC62828)])
              : null,
          color: isSelected
              ? null
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16, color: isSelected ? Colors.white : Colors.grey[600]),
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
    final actions = _generateMockActions(widget.isHome, _periodFilter);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Stack(
            children: [
              Container(
                height: 700,
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
                      return MouseRegion(
                        onHover: (event) {
                          final localPos = event.localPosition;
                          DefensiveAction? found;
                          double minDist = 20;

                          for (final action in actions) {
                            if (!_visibleActions.contains(action.type))
                              continue;
                            final actionX = action.x * constraints.maxWidth;
                            final actionY = action.y * constraints.maxHeight;
                            final dist = math.sqrt(
                                math.pow(actionX - localPos.dx, 2) +
                                    math.pow(actionY - localPos.dy, 2));
                            if (dist < minDist) {
                              minDist = dist;
                              found = action;
                            }
                          }

                          if (found != _hoveredAction) {
                            setState(() => _hoveredAction = found);
                          }
                        },
                        onExit: (event) =>
                            setState(() => _hoveredAction = null),
                        child: CustomPaint(
                          size:
                              Size(constraints.maxWidth, constraints.maxHeight),
                          painter: DuelsFieldPainter(
                            actions: actions,
                            animationValue: _animation.value,
                            visibleActions: _visibleActions,
                            hoveredAction: _hoveredAction,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_hoveredAction != null)
                Positioned(
                  left: 32,
                  top: 16,
                  child: _buildTooltip(_hoveredAction!, isDark),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTooltip(DefensiveAction action, bool isDark) {
    String typeLabel = '';
    Color typeColor = Colors.grey;

    switch (action.type) {
      case DefensiveActionType.tackleWon:
        typeLabel = 'Contrasto vinto';
        typeColor = const Color(0xFF4CAF50);
        break;
      case DefensiveActionType.interception:
        typeLabel = 'Intercetto';
        typeColor = const Color(0xFF2196F3);
        break;
      case DefensiveActionType.clearance:
        typeLabel = 'Rinvio';
        typeColor = const Color(0xFFFFEB3B);
        break;
      case DefensiveActionType.tackleLost:
        typeLabel = 'Contrasto perso';
        typeColor = const Color(0xFFE53935);
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: typeColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: typeColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                typeLabel,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: typeColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          _buildTooltipRow(
              Icons.access_time, 'Tempo', "${action.minute}'", isDark),
          _buildTooltipRow(Icons.person, tr(context, 'Giocatore'), action.player, isDark),
          _buildTooltipRow(
              Icons.sports_soccer, 'Avversario', action.opponent, isDark),
          _buildTooltipRow(Icons.location_on, tr(context, 'Zona'), action.zone, isDark),
          if (action.type == DefensiveActionType.tackleWon)
            _buildTooltipRow(
                Icons.trending_up, 'Risultato', 'Recupero palla ✅', isDark),
          if (action.type == DefensiveActionType.tackleLost)
            _buildTooltipRow(
                Icons.trending_down, 'Risultato', 'Dribblato ❌', isDark),
        ],
      ),
    );
  }

  Widget _buildTooltipRow(
      IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text('$label: ',
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          Text(value,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
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
              Expanded(child: _buildCompactField(true, isDark)),
              Expanded(child: _buildCompactField(false, isDark)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactField(bool isHome, bool isDark) {
    final actions = _generateMockActions(isHome, _periodFilter);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isHome
                ? const Color(0xFF2196F3).withOpacity(0.1)
                : const Color(0xFFE53935).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            isHome ? widget.homeTeamName : widget.awayTeamName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isHome ? const Color(0xFF2196F3) : const Color(0xFFE53935),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 500,
          margin: EdgeInsets.only(left: isHome ? 8 : 4, right: isHome ? 4 : 8),
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
                  painter: DuelsFieldPainter(
                    actions: actions,
                    animationValue: _animation.value,
                    visibleActions: _visibleActions,
                    isCompact: true,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(context, 'Azioni Difensive'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildLegendItem(DefensiveActionType.tackleWon,
                  tr(context, '🔺 Contrasti vinti'), Color(0xFF4CAF50), isDark),
              _buildLegendItem(DefensiveActionType.interception, tr(context, '⚫ Intercetti'),
                  Color(0xFF2196F3), isDark),
              _buildLegendItem(DefensiveActionType.clearance, tr(context, '🔷 Rinvii'),
                  Color(0xFFFFEB3B), isDark),
              _buildLegendItem(DefensiveActionType.tackleLost,
                  tr(context, '❌ Contrasti persi'), Color(0xFFE53935), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
      DefensiveActionType type, String label, Color color, bool isDark) {
    final isSelected = _visibleActions.contains(type);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _visibleActions.remove(type);
          } else {
            _visibleActions.add(type);
          }
        });
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isSelected ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? color : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopPerformers(bool isDark) {
    final performers = _getMockTopPerformers();
    final best = performers.first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events,
                  color: Color(0xFFFFD700), size: 20),
              const SizedBox(width: 8),
              Text(tr(context, 'Top Performers'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFFD700).withOpacity(0.2),
                  const Color(0xFFFFA000).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD700), width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.military_tech,
                        color: Color(0xFFFFD700), size: 24),
                    SizedBox(width: 8),
                    Text(
                      tr(context, 'MIGLIOR DIFENSORE'),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${best.number}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(best.name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            best.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildPerformerStat(
                        Icons.sports_kabaddi,
                        'Contrasti',
                        '${best.tackles}/${best.tacklesTotal}',
                        '${best.tacklePercentage.round()}%',
                        const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPerformerStat(
                        Icons.block,
                        'Intercetti',
                        best.interceptions.toString(),
                        '',
                        const Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPerformerStat(
                        Icons.flight_takeoff,
                        'Duelli aerei',
                        best.aerialDuels.toString(),
                        'vinti',
                        const Color(0xFF9C27B0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🔝 TOP 3',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                ...performers.take(3).map((p) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text(
                            '${performers.indexOf(p) + 1}.',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(p.name, style: const TextStyle(fontSize: 14)),
                          const Spacer(),
                          Text(
                            '${p.tacklePercentage.round()}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: p.tacklePercentage >= 75
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFFF9800),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformerStat(
      IconData icon, String label, String value, String suffix, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        if (suffix.isNotEmpty)
          Text(suffix, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildTimeline(bool isDark) {
    final actions = _generateMockActions(widget.isHome, _periodFilter);
    final timelineData = _generateTimelineData(actions);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: Color(0xFF2196F3), size: 20),
              const SizedBox(width: 8),
              Text(tr(context, 'Timeline Azioni'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  horizontalInterval: 2,
                  verticalInterval: 15,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                        color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                        color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[600]),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 15,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          "${value.toInt()}'",
                          style:
                              TextStyle(fontSize: 10, color: Colors.grey[600]),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 90,
                minY: 0,
                maxY: timelineData.map((e) => e.y).reduce(math.max) + 2,
                lineBarsData: [
                  LineChartBarData(
                    spots: timelineData,
                    isCurved: true,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF1976D2)]),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: const Color(0xFF2196F3),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF2196F3).withOpacity(0.3),
                          const Color(0xFF2196F3).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                'Numero di azioni difensive per intervallo di 15 minuti',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(bool isDark) {
    final stats = _getMockStats(widget.isHome);
    final oppStats = _getMockStats(!widget.isHome);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(context, 'Statistiche Dettagliate'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildContrastsBar(stats, oppStats, isDark),
          const SizedBox(height: 16),
          _buildBallsLostRow(stats, oppStats, isDark),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  tr(context, 'Contrasti a terra'),
                  stats['groundTackles']!,
                  stats['groundTacklesTotal']!,
                  const Color(0xFF4CAF50),
                  isDark,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  tr(context, 'Duelli aerei'),
                  stats['aerialDuels']!,
                  stats['aerialDuelsTotal']!,
                  const Color(0xFF2196F3),
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  tr(context, 'Dribbling subiti'),
                  stats['dribbledPast']!,
                  stats['dribbledPastTotal']!,
                  const Color(0xFFFF9800),
                  isDark,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildInterceptionsCard(
                  tr(context, 'Intercetti'),
                  stats['interceptions']!,
                  const Color(0xFF9C27B0),
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContrastsBar(
      Map<String, int> stats, Map<String, int> oppStats, bool isDark) {
    final totalTackles = stats['tacklesWon']! + oppStats['tacklesWon']!;
    final homePercent = totalTackles > 0
        ? (stats['tacklesWon']! / totalTackles * 100).round()
        : 50;
    final awayPercent = 100 - homePercent;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$homePercent%',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
            Text(tr(context, 'Contrasti'),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$awayPercent%',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              if (homePercent > 0)
                Expanded(
                    flex: homePercent,
                    child:
                        Container(height: 12, color: const Color(0xFF4CAF50))),
              if (awayPercent > 0)
                Expanded(
                    flex: awayPercent,
                    child:
                        Container(height: 12, color: const Color(0xFF2196F3))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBallsLostRow(
      Map<String, int> stats, Map<String, int> oppStats, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            stats['ballsLost'].toString(),
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50)),
          ),
          Text(tr(context, 'Palle perse'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text(
            oppStats['ballsLost'].toString(),
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2196F3)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, int won, int total, Color color, bool isDark) {
    final percent = total > 0 ? (won / total * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('$won/$total',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              SizedBox(
                width: 50,
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 50,
                      height: 50,
                      child: CircularProgressIndicator(
                        value: percent / 100,
                        strokeWidth: 5,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInterceptionsCard(
      String title, int count, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                count.toString(),
                style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<FlSpot> _generateTimelineData(List<DefensiveAction> actions) {
    final intervals = <int, int>{};

    for (int i = 0; i <= 90; i += 15) {
      intervals[i] = 0;
    }

    for (final action in actions) {
      final interval = (action.minute ~/ 15) * 15;
      intervals[interval] = (intervals[interval] ?? 0) + 1;
    }

    return intervals.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();
  }

  List<DefensiveAction> _generateMockActions(bool isHome, String period) {
    final random = math.Random(isHome ? 123 : 456);
    final actions = <DefensiveAction>[];

    int numActions = 30;
    if (period == 'first_half') numActions = 18;
    if (period == 'second_half') numActions = 15;

    final players = ['Romagnoli', 'Tomori', 'Kalulu', 'Theo', 'Calabria'];
    final opponents = ['Immobile', 'Anderson', 'Pedro', 'Luis Alberto'];
    final zones = ['SX-Alto', 'Centro', 'DX-Basso', 'SX-Medio'];

    for (int i = 0; i < numActions; i++) {
      double x, y;
      DefensiveActionType type;

      if (isHome) {
        x = random.nextDouble() * 0.6;
        y = 0.15 + random.nextDouble() * 0.7;
      } else {
        x = 0.4 + random.nextDouble() * 0.6;
        y = 0.15 + random.nextDouble() * 0.7;
      }

      final typeRand = random.nextInt(100);
      if (typeRand < 40) {
        type = DefensiveActionType.tackleWon;
      } else if (typeRand < 60) {
        type = DefensiveActionType.interception;
      } else if (typeRand < 80) {
        type = DefensiveActionType.clearance;
      } else {
        type = DefensiveActionType.tackleLost;
      }

      final minute = period == 'first_half'
          ? random.nextInt(45) + 1
          : period == 'second_half'
              ? random.nextInt(45) + 46
              : random.nextInt(90) + 1;

      actions.add(DefensiveAction(
        x: x,
        y: y,
        type: type,
        minute: minute,
        player:
            '#${random.nextInt(90) + 1} ${players[random.nextInt(players.length)]}',
        opponent:
            '#${random.nextInt(90) + 1} ${opponents[random.nextInt(opponents.length)]}',
        zone: zones[random.nextInt(zones.length)],
      ));
    }

    return actions;
  }

  List<TopPerformer> _getMockTopPerformers() {
    return [
      TopPerformer(
        name: 'Romagnoli',
        number: '23',
        tackles: 12,
        tacklesTotal: 15,
        interceptions: 8,
        aerialDuels: 3,
        rating: 8.5,
      ),
      TopPerformer(
        name: 'Tomori',
        number: '28',
        tackles: 9,
        tacklesTotal: 12,
        interceptions: 6,
        aerialDuels: 5,
        rating: 8.2,
      ),
      TopPerformer(
        name: 'Kalulu',
        number: '20',
        tackles: 8,
        tacklesTotal: 11,
        interceptions: 4,
        aerialDuels: 2,
        rating: 7.8,
      ),
    ];
  }

  Map<String, int> _getMockStats(bool isHome) {
    if (isHome) {
      return {
        'tacklesWon': 45,
        'groundTackles': 45,
        'groundTacklesTotal': 84,
        'aerialDuels': 15,
        'aerialDuelsTotal': 38,
        'dribbledPast': 6,
        'dribbledPastTotal': 13,
        'interceptions': 18,
        'ballsLost': 11,
      };
    } else {
      return {
        'tacklesWon': 48,
        'groundTackles': 39,
        'groundTacklesTotal': 84,
        'aerialDuels': 23,
        'aerialDuelsTotal': 38,
        'dribbledPast': 6,
        'dribbledPastTotal': 21,
        'interceptions': 15,
        'ballsLost': 9,
      };
    }
  }
}

class DuelsFieldPainter extends CustomPainter {
  final List<DefensiveAction> actions;
  final double animationValue;
  final Set<DefensiveActionType> visibleActions;
  final bool isCompact;
  final DefensiveAction? hoveredAction;

  DuelsFieldPainter({
    required this.actions,
    required this.animationValue,
    required this.visibleActions,
    this.isCompact = false,
    this.hoveredAction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fieldPaint = Paint()..color = const Color(0xFF1B5E20);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fieldPaint);

    _drawFieldLines(canvas, size);
    _drawActions(canvas, size);
  }

  void _drawFieldLines(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCompact ? 2.5 : 4.0;

    final thickLinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCompact ? 3.5 : 6.0;

    final borderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
      const Radius.circular(8),
    );
    canvas.drawRRect(borderRect, thickLinePaint);

    canvas.drawLine(
      Offset(size.width / 2, 1),
      Offset(size.width / 2, size.height - 1),
      thickLinePaint,
    );

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final circleRadius = isCompact ? size.height * 0.15 : size.height * 0.18;

    canvas.drawCircle(Offset(centerX, centerY), circleRadius, linePaint);
    canvas.drawCircle(
      Offset(centerX, centerY),
      isCompact ? 4 : 6,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    final penaltyWidth = isCompact ? size.width * 0.20 : size.width * 0.25;
    final penaltyHeight = isCompact ? size.height * 0.50 : size.height * 0.60;
    final penaltyY = (size.height - penaltyHeight) / 2;

    canvas.drawRect(
        Rect.fromLTWH(1, penaltyY, penaltyWidth, penaltyHeight), linePaint);
    canvas.drawRect(
      Rect.fromLTWH(
          size.width - penaltyWidth - 1, penaltyY, penaltyWidth, penaltyHeight),
      linePaint,
    );

    final smallBoxWidth = isCompact ? size.width * 0.08 : size.width * 0.10;
    final smallBoxHeight = isCompact ? size.height * 0.25 : size.height * 0.30;
    final smallBoxY = (size.height - smallBoxHeight) / 2;

    canvas.drawRect(
        Rect.fromLTWH(1, smallBoxY, smallBoxWidth, smallBoxHeight), linePaint);
    canvas.drawRect(
      Rect.fromLTWH(size.width - smallBoxWidth - 1, smallBoxY, smallBoxWidth,
          smallBoxHeight),
      linePaint,
    );

    final arcRadius = isCompact ? penaltyHeight * 0.18 : penaltyHeight * 0.20;

    final leftArcPath = Path();
    leftArcPath.addArc(
      Rect.fromCircle(center: Offset(penaltyWidth, centerY), radius: arcRadius),
      -math.pi / 2,
      math.pi,
    );
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(penaltyWidth, 0, size.width, size.height));
    canvas.drawPath(leftArcPath, linePaint);
    canvas.restore();

    final rightArcPath = Path();
    rightArcPath.addArc(
      Rect.fromCircle(
          center: Offset(size.width - penaltyWidth, centerY),
          radius: arcRadius),
      math.pi / 2,
      math.pi,
    );
    canvas.save();
    canvas
        .clipRect(Rect.fromLTWH(0, 0, size.width - penaltyWidth, size.height));
    canvas.drawPath(rightArcPath, linePaint);
    canvas.restore();

    final cornerRadius = isCompact ? 6.0 : 8.0;
    canvas.drawArc(Rect.fromLTWH(1, 1, cornerRadius * 2, cornerRadius * 2),
        math.pi, math.pi / 2, false, linePaint);
    canvas.drawArc(
        Rect.fromLTWH(size.width - cornerRadius * 2 - 1, 1, cornerRadius * 2,
            cornerRadius * 2),
        -math.pi / 2,
        math.pi / 2,
        false,
        linePaint);
    canvas.drawArc(
        Rect.fromLTWH(1, size.height - cornerRadius * 2 - 1, cornerRadius * 2,
            cornerRadius * 2),
        math.pi / 2,
        math.pi / 2,
        false,
        linePaint);
    canvas.drawArc(
        Rect.fromLTWH(
            size.width - cornerRadius * 2 - 1,
            size.height - cornerRadius * 2 - 1,
            cornerRadius * 2,
            cornerRadius * 2),
        0,
        math.pi / 2,
        false,
        linePaint);
  }

  void _drawActions(Canvas canvas, Size size) {
    for (int i = 0; i < actions.length; i++) {
      final action = actions[i];
      if (!visibleActions.contains(action.type)) continue;

      final actionProgress =
          ((animationValue * actions.length) - i).clamp(0.0, 1.0);
      if (actionProgress <= 0) continue;

      final x = action.x * size.width;
      final y = action.y * size.height;
      final isHovered = action == hoveredAction;

      _drawAction(canvas, action, Offset(x, y), actionProgress, isHovered);
    }
  }

  void _drawAction(Canvas canvas, DefensiveAction action, Offset position,
      double progress, bool isHovered) {
    final baseSize = isCompact ? 14.0 : 20.0;
    final size = baseSize * progress * (isHovered ? 1.5 : 1.0);

    switch (action.type) {
      case DefensiveActionType.tackleWon:
        _drawTriangle(canvas, position, size, const Color(0xFF4CAF50), progress,
            isHovered);
        break;
      case DefensiveActionType.interception:
        _drawCircle(canvas, position, size, const Color(0xFF2196F3), progress,
            isHovered);
        break;
      case DefensiveActionType.clearance:
        _drawSquare(canvas, position, size, const Color(0xFFFFEB3B), progress,
            isHovered);
        break;
      case DefensiveActionType.tackleLost:
        _drawCross(canvas, position, size, const Color(0xFFE53935), progress,
            isHovered);
        break;
    }
  }

  void _drawTriangle(Canvas canvas, Offset center, double size, Color color,
      double progress, bool isHovered) {
    final path = Path();
    path.moveTo(center.dx, center.dy - size / 2);
    path.lineTo(center.dx - size / 2, center.dy + size / 2);
    path.lineTo(center.dx + size / 2, center.dy + size / 2);
    path.close();

    canvas.drawPath(
      path.shift(const Offset(1, 1)),
      Paint()
        ..color = Colors.black.withOpacity(0.3 * progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.drawPath(path, Paint()..color = color.withOpacity(0.9 * progress));
    canvas.drawPath(
      path,
      Paint()
        ..color = isHovered ? Colors.white : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 3 : (isCompact ? 2 : 2.5),
    );
  }

  void _drawCircle(Canvas canvas, Offset center, double size, Color color,
      double progress, bool isHovered) {
    canvas.drawCircle(
      center.translate(1, 1),
      size / 2,
      Paint()
        ..color = Colors.black.withOpacity(0.3 * progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.drawCircle(
        center, size / 2, Paint()..color = color.withOpacity(0.9 * progress));
    canvas.drawCircle(
      center,
      size / 2,
      Paint()
        ..color = isHovered ? Colors.white : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 3.5 : (isCompact ? 2.5 : 3.0),
    );
  }

  void _drawSquare(Canvas canvas, Offset center, double size, Color color,
      double progress, bool isHovered) {
    final rect = Rect.fromCenter(center: center, width: size, height: size);

    canvas.drawRect(
      rect.shift(const Offset(1, 1)),
      Paint()
        ..color = Colors.black.withOpacity(0.3 * progress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    canvas.drawRect(rect, Paint()..color = color.withOpacity(0.9 * progress));
    canvas.drawRect(
      rect,
      Paint()
        ..color = isHovered ? Colors.white : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHovered ? 3 : (isCompact ? 2 : 2.5),
    );
  }

  void _drawCross(Canvas canvas, Offset center, double size, Color color,
      double progress, bool isHovered) {
    final strokeWidth = isHovered ? 3.5 : (isCompact ? 2.5 : 3.0);
    final paint = Paint()
      ..color = (isHovered ? Colors.white : color).withOpacity(progress)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3 * progress)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final half = size / 2;

    canvas.drawLine(center.translate(-half + 1, -half + 1),
        center.translate(half + 1, half + 1), shadowPaint);
    canvas.drawLine(center.translate(half + 1, -half + 1),
        center.translate(-half + 1, half + 1), shadowPaint);
    canvas.drawLine(
        center.translate(-half, -half), center.translate(half, half), paint);
    canvas.drawLine(
        center.translate(half, -half), center.translate(-half, half), paint);
  }

  @override
  bool shouldRepaint(DuelsFieldPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.visibleActions != visibleActions ||
      oldDelegate.hoveredAction != hoveredAction;
}
