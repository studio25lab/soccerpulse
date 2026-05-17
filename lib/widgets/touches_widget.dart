import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../utils/l10n_helper.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/player_detail.dart';
import '../pages/player_detail_screen.dart';

enum TouchType { pass, dribble, shot, control, duel }

enum FieldZone { defense, midfield, attack }

class TouchPoint {
  final double x, y;
  final TouchType type;
  final int minute;
  final String player;
  final FieldZone zone;
  final bool successful;
  TouchPoint(
      {required this.x,
      required this.y,
      required this.type,
      required this.minute,
      required this.player,
      required this.zone,
      required this.successful});
}

class TouchPlayer {
  final String name, number;
  final int totalTouches, successfulTouches, passes, dribbles, shots;
  double get successRate =>
      totalTouches > 0 ? (successfulTouches / totalTouches * 100) : 0;
  TouchPlayer(
      {required this.name,
      required this.number,
      required this.totalTouches,
      required this.successfulTouches,
      required this.passes,
      required this.dribbles,
      required this.shots});
}

class TouchesWidget extends StatefulWidget {
  final bool isHome;
  final String homeTeamName, awayTeamName;
  const TouchesWidget(
      {Key? key,
      required this.isHome,
      required this.homeTeamName,
      required this.awayTeamName})
      : super(key: key);
  @override
  State<TouchesWidget> createState() => _TouchesWidgetState();
}

class _TouchesWidgetState extends State<TouchesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  String _periodFilter = 'all';
  bool _showComparison = false, _showHeatmap = true, _advancedMode = false;
  Set<TouchType> _visibleTouches = TouchType.values.toSet();
  TouchPoint? _hoveredTouch, _selectedTouch;
  bool?
      _selectedFieldIsHome; // ✅ Traccia quale campo è stato cliccato (null = nessuno)

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
        duration: const Duration(milliseconds: 1200), vsync: this);
    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TouchesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isHome != widget.isHome) {
      _animationController.reset();
      _animationController.forward();
      setState(() {
        _selectedTouch = null;
        _hoveredTouch = null;
        _selectedFieldIsHome = null; // ✅ Reset
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(isDark),
          _buildModeSelector(isDark),
          const SizedBox(height: 8),
          _buildPeriodFilters(isDark),
          const SizedBox(height: 8),
          if (_advancedMode) _buildViewControls(isDark),
          const SizedBox(height: 16),
          _showComparison
              ? _buildComparisonView(isDark)
              : _buildSingleView(isDark),
          const SizedBox(height: 16),
          // ✅ LEGENDA CONDIZIONALE
          if (_advancedMode) ...[
            _buildLegend(isDark), // Legenda "Tipi di Tocco"
          ] else ...[
            _buildHeatmapLegend(isDark), // Legenda colori heatmap
          ],
          const SizedBox(height: 24),
          if (_advancedMode) ...[
            _buildZoneStats(isDark),
            const SizedBox(height: 24),
            _buildTopPlayers(isDark),
            const SizedBox(height: 24),
            _buildTimeline(isDark),
            const SizedBox(height: 24),
            _buildDetailedStats(isDark),
          ] else ...[
            _buildMinimalStats(isDark),
          ],
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
          Icon(Icons.touch_app, color: Color(0xFF9C27B0), size: 24),
          SizedBox(width: 8),
          Text(tr(context, 'Tocchi'),
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
                        : const Color(0xFFE53935)),
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            icon: Icon(_showComparison ? Icons.view_agenda : Icons.compare,
                color: _showComparison
                    ? Color(0xFF2196F3)
                    : Colors.grey[600]),
            onPressed: () => setState(() => _showComparison = !_showComparison),
            tooltip: _showComparison ? tr(context, 'Vista singola') : tr(context, 'Confronta squadre'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _advancedMode = false;
                  _selectedTouch = null;
                  _hoveredTouch = null;
                  _selectedFieldIsHome = null; // ✅ Reset
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      gradient: !_advancedMode
                          ? const LinearGradient(
                              colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)])
                          : null,
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.whatshot,
                          size: 18,
                          color:
                              !_advancedMode ? Colors.white : Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(tr(context, 'Heatmap'),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: !_advancedMode
                                  ? Colors.white
                                  : Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  _advancedMode = true;
                  _selectedTouch = null;
                  _hoveredTouch = null;
                  _selectedFieldIsHome = null; // ✅ Reset
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      gradient: _advancedMode
                          ? const LinearGradient(
                              colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)])
                          : null,
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.adjust,
                          size: 18,
                          color:
                              _advancedMode ? Colors.white : Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(tr(context, 'Avanzata'),
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: _advancedMode
                                  ? Colors.white
                                  : Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildViewControls(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showHeatmap = !_showHeatmap),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: _showHeatmap
                    ? const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)])
                    : null,
                color: _showHeatmap
                    ? null
                    : (isDark ? Colors.grey[800] : Colors.grey[200]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.whatshot,
                      size: 16,
                      color: _showHeatmap ? Colors.white : Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(tr(context, 'Heatmap'),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color:
                              _showHeatmap ? Colors.white : Colors.grey[600])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(
      String label, String value, IconData icon, bool isDark) {
    final isSelected = _periodFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _periodFilter = value;
          _selectedTouch = null;
          _hoveredTouch = null;
          _selectedFieldIsHome = null; // ✅ Reset
        });
        _animationController.reset();
        _animationController.forward();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)])
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
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleView(bool isDark) {
    final touches = _generateMockTouches(widget.isHome, _periodFilter);
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
                        offset: const Offset(0, 4))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (_advancedMode) {
                        return MouseRegion(
                          onHover: (event) {
                            final localPos = event.localPosition;
                            TouchPoint? found;
                            double minDist = 20;
                            for (final touch in touches) {
                              if (!_visibleTouches.contains(touch.type))
                                continue;
                              final touchX = touch.x * constraints.maxWidth;
                              final touchY = touch.y * constraints.maxHeight;
                              final dist = math.sqrt(
                                  math.pow(touchX - localPos.dx, 2) +
                                      math.pow(touchY - localPos.dy, 2));
                              if (dist < minDist) {
                                minDist = dist;
                                found = touch;
                              }
                            }
                            if (found != _hoveredTouch)
                              setState(() => _hoveredTouch = found);
                          },
                          onExit: (event) =>
                              setState(() => _hoveredTouch = null),
                          child: GestureDetector(
                            onTapUp: (details) {
                              final localPos = details.localPosition;
                              TouchPoint? found;
                              double minDist = 20;
                              for (final touch in touches) {
                                if (!_visibleTouches.contains(touch.type))
                                  continue;
                                final touchX = touch.x * constraints.maxWidth;
                                final touchY = touch.y * constraints.maxHeight;
                                final dist = math.sqrt(
                                    math.pow(touchX - localPos.dx, 2) +
                                        math.pow(touchY - localPos.dy, 2));
                                if (dist < minDist) {
                                  minDist = dist;
                                  found = touch;
                                }
                              }
                              if (found != null)
                                setState(() => _selectedTouch = found);
                            },
                            child: CustomPaint(
                              size: Size(
                                  constraints.maxWidth, constraints.maxHeight),
                              painter: TouchesFieldPainter(
                                touches: touches,
                                showHeatmap: _showHeatmap,
                                animationValue: _animation.value,
                                visibleTouches: _visibleTouches,
                                hoveredTouch: _hoveredTouch,
                                selectedTouch: _selectedTouch,
                                showIndividualTouches: true,
                              ),
                            ),
                          ),
                        );
                      }

                      return CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: TouchesFieldPainter(
                          touches: touches,
                          showHeatmap: true,
                          animationValue: _animation.value,
                          visibleTouches: _visibleTouches,
                          showIndividualTouches: false,
                        ),
                      );
                    },
                  ),
                ),
              ),
              if (_advancedMode &&
                  _hoveredTouch != null &&
                  _selectedTouch == null)
                Positioned(
                    left: 32,
                    top: 16,
                    child: _buildTooltip(_hoveredTouch!, isDark)),
              if (_advancedMode && _selectedTouch != null)
                Positioned(
                    left: 16,
                    top: 16,
                    child: _buildSideCard(_selectedTouch!, isDark)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTooltip(TouchPoint touch, bool isDark) {
    String typeLabel = '';
    Color typeColor = Colors.grey;
    switch (touch.type) {
      case TouchType.pass:
        typeLabel = tr(context, 'Passaggio');
        typeColor = const Color(0xFF2196F3);
        break;
      case TouchType.dribble:
        typeLabel = 'Dribbling';
        typeColor = const Color(0xFFFF9800);
        break;
      case TouchType.shot:
        typeLabel = 'Tiro';
        typeColor = const Color(0xFFE53935);
        break;
      case TouchType.control:
        typeLabel = 'Controllo';
        typeColor = const Color(0xFF4CAF50);
        break;
      case TouchType.duel:
        typeLabel = 'Duello';
        typeColor = const Color(0xFF9C27B0);
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
              offset: const Offset(0, 4))
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
                  decoration:
                      BoxDecoration(color: typeColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(typeLabel,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: typeColor)),
            ],
          ),
          SizedBox(height: 8),
          Text(tr(context, 'Click per dettagli'),
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildSideCard(TouchPoint touch, bool isDark) {
    String typeLabel = '';
    Color typeColor = Colors.grey;
    switch (touch.type) {
      case TouchType.pass:
        typeLabel = tr(context, 'Passaggio');
        typeColor = const Color(0xFF2196F3);
        break;
      case TouchType.dribble:
        typeLabel = 'Dribbling';
        typeColor = const Color(0xFFFF9800);
        break;
      case TouchType.shot:
        typeLabel = 'Tiro';
        typeColor = const Color(0xFFE53935);
        break;
      case TouchType.control:
        typeLabel = 'Controllo';
        typeColor = const Color(0xFF4CAF50);
        break;
      case TouchType.duel:
        typeLabel = 'Duello';
        typeColor = const Color(0xFF9C27B0);
        break;
    }
    final playerNameOnly = touch.player.split(' ').skip(1).join(' ');
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.grey[850]! : Colors.white,
            isDark ? Colors.grey[800]! : Colors.grey[50]!
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: typeColor, width: 3),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                  width: 12,
                  height: 12,
                  decoration:
                      BoxDecoration(color: typeColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(typeLabel,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: typeColor))),
              IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => setState(() {
                        _selectedTouch = null;
                        _selectedFieldIsHome =
                            null; // ✅ Reset campo selezionato
                      }),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints()),
            ],
          ),
          const SizedBox(height: 16),
          _buildSideCardRow(
              Icons.access_time, 'Tempo', "${touch.minute}'", isDark),
          SizedBox(height: 8),
          _buildSideCardRow(
              Icons.location_on, tr(context, 'Zona'), _getZoneName(touch.zone), isDark),
          const SizedBox(height: 8),
          _buildSideCardRow(
              touch.successful ? Icons.check_circle : Icons.cancel,
              'Esito',
              touch.successful ? 'Riuscito ✅' : tr(context, 'Fallito ❌'),
              isDark),
          SizedBox(height: 16),
          Divider(),
          SizedBox(height: 8),
          Text(tr(context, 'Giocatore'),
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                final playerDetail = _createMockPlayerDetail(
                    playerNameOnly,
                    widget.isHome ? widget.homeTeamName : widget.awayTeamName,
                    widget.isHome
                        ? const Color(0xFF2196F3)
                        : const Color(0xFFE53935));
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            PlayerDetailScreen(player: playerDetail)));
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: typeColor.withOpacity(0.3))),
                child: Row(
                  children: [
                    Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                            color: typeColor.withOpacity(0.2),
                            shape: BoxShape.circle),
                        child: Icon(Icons.person, color: typeColor, size: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(playerNameOnly,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(touch.player.split(' ').first,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios,
                        size: 16, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSideCardRow(
      IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text('$label: ',
            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600))),
      ],
    );
  }

  String _getZoneName(FieldZone zone) {
    switch (zone) {
      case FieldZone.defense:
        return tr(context, 'Difesa');
      case FieldZone.midfield:
        return tr(context, 'Centrocampo');
      case FieldZone.attack:
        return 'Attacco';
    }
  }

  PlayerDetail _createMockPlayerDetail(
      String name, String teamName, Color teamColor) {
    return PlayerDetail(
      number: 10,
      name: name,
      position: 'Forward',
      photo: null,
      teamName: teamName,
      teamColor: teamColor,
      matches: 25,
      goals: 8,
      assists: 5,
      minutes: 2100,
      shots: 45,
      shotsOnTarget: 28,
      dribbles: 32,
      tackles: 45,
      interceptions: 30,
      saves: 0,
      duelsWon: 58,
      yellowCards: 2,
      redCards: 0,
      fouls: 18,
      recentRatings: [7.2, 7.8, 6.9, 8.1, 7.5, 7.0, 8.3, 7.6, 7.9, 7.4],
      recentForm: ['W', 'W', 'D', 'W', 'L'],
      bestMatch: 'Serie A - 8.5',
      averageRating: 7.5,
      decisiveGoals: 3,
      skills: {
        tr(context, 'Velocità'): 85.0,
        'Tiro': 88.0,
        tr(context, 'Passaggio'): 82.0,
        'Dribbling': 87.0,
        tr(context, 'Difesa'): 68.0,
        'Fisico': 76.0
      },
      passingAccuracy: 87.5,
      shotsPerGoal: 3.8,
      minutesPerGoal: 175.0,
      birthDate: '15/03/1995',
      age: 28,
      nationality: 'Italia',
      height: 182,
      weight: 75,
      preferredFoot: 'Destro',
      careerHistory: [],
    );
  }

  Widget _buildComparisonView(bool isDark) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Row(children: [
            Expanded(child: _buildCompactField(true, isDark)),
            Expanded(child: _buildCompactField(false, isDark))
          ]),
        );
      },
    );
  }

  Widget _buildCompactField(bool isHome, bool isDark) {
    final touches = _generateMockTouches(isHome, _periodFilter);

    // ✅ Determina se questo campo deve mostrare tooltip/scheda
    final shouldShowTooltip = _hoveredTouch != null &&
        _selectedTouch == null &&
        _selectedFieldIsHome == isHome;
    final shouldShowSideCard =
        _selectedTouch != null && _selectedFieldIsHome == isHome;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
              color: isHome
                  ? const Color(0xFF2196F3).withOpacity(0.1)
                  : const Color(0xFFE53935).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Text(isHome ? widget.homeTeamName : widget.awayTeamName,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isHome
                      ? const Color(0xFF2196F3)
                      : const Color(0xFFE53935))),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 500,
              margin:
                  EdgeInsets.only(left: isHome ? 8 : 4, right: isHome ? 4 : 8),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4))
                  ]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // ✅ MODALITÀ AVANZATA: Interazioni attive
                    if (_advancedMode) {
                      return MouseRegion(
                        onHover: (event) {
                          final localPos = event.localPosition;
                          TouchPoint? found;
                          double minDist = 15;

                          for (final touch in touches) {
                            if (!_visibleTouches.contains(touch.type)) continue;
                            final touchX = touch.x * constraints.maxWidth;
                            final touchY = touch.y * constraints.maxHeight;
                            final dist = math.sqrt(
                                math.pow(touchX - localPos.dx, 2) +
                                    math.pow(touchY - localPos.dy, 2));
                            if (dist < minDist) {
                              minDist = dist;
                              found = touch;
                            }
                          }

                          if (found != _hoveredTouch) {
                            setState(() {
                              _hoveredTouch = found;
                              _selectedFieldIsHome =
                                  isHome; // ✅ Traccia quale campo
                            });
                          }
                        },
                        onExit: (event) {
                          setState(() {
                            _hoveredTouch = null;
                            if (_selectedTouch == null)
                              _selectedFieldIsHome = null;
                          });
                        },
                        child: GestureDetector(
                          onTapUp: (details) {
                            final localPos = details.localPosition;
                            TouchPoint? found;
                            double minDist = 15;

                            for (final touch in touches) {
                              if (!_visibleTouches.contains(touch.type))
                                continue;
                              final touchX = touch.x * constraints.maxWidth;
                              final touchY = touch.y * constraints.maxHeight;
                              final dist = math.sqrt(
                                  math.pow(touchX - localPos.dx, 2) +
                                      math.pow(touchY - localPos.dy, 2));
                              if (dist < minDist) {
                                minDist = dist;
                                found = touch;
                              }
                            }

                            if (found != null) {
                              setState(() {
                                _selectedTouch = found;
                                _selectedFieldIsHome =
                                    isHome; // ✅ Traccia quale campo
                              });
                            }
                          },
                          child: CustomPaint(
                            size: Size(
                                constraints.maxWidth, constraints.maxHeight),
                            painter: TouchesFieldPainter(
                              touches: touches,
                              showHeatmap: _showHeatmap,
                              animationValue: _animation.value,
                              visibleTouches: _visibleTouches,
                              isCompact: true,
                              showIndividualTouches: true,
                              hoveredTouch:
                                  shouldShowTooltip ? _hoveredTouch : null,
                              selectedTouch:
                                  shouldShowSideCard ? _selectedTouch : null,
                            ),
                          ),
                        ),
                      );
                    }

                    // MODALITÀ HEATMAP: Solo visualizzazione
                    return CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: TouchesFieldPainter(
                        touches: touches,
                        showHeatmap: true,
                        animationValue: _animation.value,
                        visibleTouches: _visibleTouches,
                        isCompact: true,
                        showIndividualTouches: false,
                      ),
                    );
                  },
                ),
              ),
            ),
            // ✅ TOOLTIP (solo se questo è il campo hoveredato)
            if (_advancedMode && shouldShowTooltip)
              Positioned(
                left: isHome ? 16 : 8,
                top: 16,
                child: _buildTooltip(_hoveredTouch!, isDark),
              ),
            // ✅ SCHEDA LATERALE (solo se questo è il campo selezionato)
            if (_advancedMode && shouldShowSideCard)
              Positioned(
                left: isHome ? 12 : 6,
                top: 16,
                child: _buildSideCard(_selectedTouch!, isDark),
              ),
          ],
        ),
      ],
    );
  }

  // ✅ LEGENDA TIPI DI TOCCO (solo modalità avanzata)
  Widget _buildLegend(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(context, 'Tipi di Tocco'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildLegendItem(TouchType.pass, tr(context, '⚪ Passaggi'),
                  Color(0xFF2196F3), isDark),
              _buildLegendItem(TouchType.dribble, tr(context, '🟠 Dribbling'),
                  Color(0xFFFF9800), isDark),
              _buildLegendItem(
                  TouchType.shot, tr(context, '🔴 Tiri'), Color(0xFFE53935), isDark),
              _buildLegendItem(TouchType.control, '🟢 Controlli',
                  Color(0xFF4CAF50), isDark),
              _buildLegendItem(
                  TouchType.duel, tr(context, '🟣 Duelli'), Color(0xFF9C27B0), isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
      TouchType type, String label, Color color, bool isDark) {
    final isSelected = _visibleTouches.contains(type);
    return GestureDetector(
      onTap: () => setState(() => isSelected
          ? _visibleTouches.remove(type)
          : _visibleTouches.add(type)),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isSelected ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isSelected ? color : Colors.transparent, width: 2)),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? color : Colors.grey[600])),
        ),
      ),
    );
  }

  // ✅ NUOVA LEGENDA HEATMAP (solo modalità heatmap)
  Widget _buildHeatmapLegend(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(context, 'Intensità Tocchi'),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 24,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2196F3), // Blu (bassa)
                                    Color(0xFF4CAF50), // Verde
                                    Color(0xFFFFC107), // Giallo
                                    Color(0xFFE53935), // Rosso (alta)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tr(context, 'Bassa'),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600])),
                          Text(tr(context, 'Media'),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600])),
                          Text(tr(context, 'Alta'),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalStats(bool isDark) {
    final stats = _getMockDetailedStats();
    final total = stats['totalTouches']!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(context, 'Riepilogo Tocchi'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                const Color(0xFF9C27B0).withOpacity(0.1),
                const Color(0xFF7B1FA2).withOpacity(0.05)
              ]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF9C27B0).withOpacity(0.3), width: 2),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.touch_app,
                        color: Color(0xFF9C27B0), size: 32),
                    const SizedBox(width: 12),
                    Text(total.toString(),
                        style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF9C27B0))),
                  ],
                ),
                SizedBox(height: 8),
                Text(tr(context, 'Tocchi Totali'),
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildMinimalStatCard('⚪', tr(context, 'Passaggi'),
                      stats['passes']!, const Color(0xFF2196F3), isDark)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildMinimalStatCard('🟠', 'Dribbling',
                      stats['dribbles']!, const Color(0xFFFF9800), isDark)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _buildMinimalStatCard('🔴', tr(context, 'Tiri'), stats['shots']!,
                      const Color(0xFFE53935), isDark)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildMinimalStatCard('🟢', 'Controlli',
                      stats['controls']!, const Color(0xFF4CAF50), isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalStatCard(
      String emoji, String label, int value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 2)),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(value.toString(),
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // Altre sezioni (identiche)
  Widget _buildZoneStats(bool isDark) {
    final stats = _getMockZoneStats();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.map, color: Color(0xFF2196F3), size: 20),
            SizedBox(width: 8),
            Text(tr(context, 'Tocchi per Zona'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildZoneCard(tr(context, 'Difesa'), stats['defense']!,
                      Color(0xFF2196F3), isDark)),
              SizedBox(width: 12),
              Expanded(
                  child: _buildZoneCard(tr(context, 'Centrocampo'), stats['midfield']!,
                      const Color(0xFFFF9800), isDark)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildZoneCard('Attacco', stats['attack']!,
                      const Color(0xFFE53935), isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoneCard(String label, int value, Color color, bool isDark) {
    final percent = ((value / 450) * 100).round();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 2)),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(value.toString(),
              style: TextStyle(
                  fontSize: 32, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text('$percent%',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildTopPlayers(bool isDark) {
    final players = _getMockTopPlayers();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 20),
            SizedBox(width: 8),
            Text(tr(context, 'Top 5 Giocatori'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: players.asMap().entries.map((entry) {
                final index = entry.key;
                final player = entry.value;
                return Padding(
                  padding: EdgeInsets.only(top: index > 0 ? 12 : 0),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: index == 0
                              ? const Color(0xFFFFD700)
                              : index == 1
                                  ? const Color(0xFFC0C0C0)
                                  : index == 2
                                      ? const Color(0xFFCD7F32)
                                      : const Color(0xFF9C27B0),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                            child: Text('${index + 1}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(player.name,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold)),
                            Text(
                                '#${player.number} • ${player.successRate.round()}% successo',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(player.totalTouches.toString(),
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9C27B0))),
                          Text(tr(context, 'tocchi'),
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(bool isDark) {
    final touches = _generateMockTouches(widget.isHome, _periodFilter);
    final timelineData = _generateTimelineData(touches);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.timeline, color: Color(0xFF9C27B0), size: 20),
            SizedBox(width: 8),
            Text(tr(context, 'Timeline Tocchi'),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
          ]),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!)),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 5,
                    verticalInterval: 15,
                    getDrawingHorizontalLine: (v) => FlLine(
                        color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
                    getDrawingVerticalLine: (v) => FlLine(
                        color: Colors.grey.withOpacity(0.2), strokeWidth: 1)),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (v, m) => Text(v.toInt().toString(),
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[600])))),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 15,
                          getTitlesWidget: (v, m) => Text("${v.toInt()}'",
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[600])))),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 90,
                minY: 0,
                maxY: timelineData.map((e) => e.y).reduce(math.max) + 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: timelineData,
                    isCurved: true,
                    gradient: const LinearGradient(
                        colors: [Color(0xFF9C27B0), Color(0xFF7B1FA2)]),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                        show: true,
                        getDotPainter: (s, p, b, i) => FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: const Color(0xFF9C27B0))),
                    belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                            colors: [
                              const Color(0xFF9C27B0).withOpacity(0.3),
                              const Color(0xFF9C27B0).withOpacity(0.0)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(bool isDark) {
    final stats = _getMockDetailedStats();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(context, 'Statistiche Dettagliate'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: _buildStatCard(
                    tr(context, 'Passaggi'),
                    stats['passes']!,
                    stats['totalTouches']!,
                    const Color(0xFF2196F3),
                    Icons.swap_horiz,
                    isDark)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
                    'Dribbling',
                    stats['dribbles']!,
                    stats['totalTouches']!,
                    const Color(0xFFFF9800),
                    Icons.directions_run,
                    isDark))
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _buildStatCard(
                    tr(context, 'Tiri'),
                    stats['shots']!,
                    stats['totalTouches']!,
                    const Color(0xFFE53935),
                    Icons.sports_soccer,
                    isDark)),
            const SizedBox(width: 12),
            Expanded(
                child: _buildStatCard(
                    'Controlli',
                    stats['controls']!,
                    stats['totalTouches']!,
                    const Color(0xFF4CAF50),
                    Icons.control_camera,
                    isDark))
          ]),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, int value, int total, Color color,
      IconData icon, bool isDark) {
    final percent = total > 0 ? (value / total * 100).round() : 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 2)),
      child: Column(
        children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500)))
          ]),
          const SizedBox(height: 12),
          Text(value.toString(),
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text('$percent% ${tr(context, 'del totale')}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  List<FlSpot> _generateTimelineData(List<TouchPoint> touches) {
    final intervals = <int, int>{};
    for (int i = 0; i <= 90; i += 15) intervals[i] = 0;
    for (final touch in touches) {
      final interval = (touch.minute ~/ 15) * 15;
      intervals[interval] = (intervals[interval] ?? 0) + 1;
    }
    return intervals.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();
  }

  List<TouchPoint> _generateMockTouches(bool isHome, String period) {
    final random = math.Random(isHome ? 789 : 456);
    final touches = <TouchPoint>[];
    int numTouches = period == 'first_half'
        ? 45
        : period == 'second_half'
            ? 40
            : 80;
    final players = [
      'Immobile',
      'Zaccagni',
      'Luis Alberto',
      'Guendouzi',
      'Anderson'
    ];
    for (int i = 0; i < numTouches; i++) {
      double x =
          isHome ? random.nextDouble() * 0.7 : 0.3 + random.nextDouble() * 0.7;
      double y = 0.1 + random.nextDouble() * 0.8;
      FieldZone zone = y < 0.33
          ? FieldZone.defense
          : y < 0.66
              ? FieldZone.midfield
              : FieldZone.attack;
      final typeRand = random.nextInt(100);
      TouchType type = typeRand < 50
          ? TouchType.pass
          : typeRand < 65
              ? TouchType.control
              : typeRand < 75
                  ? TouchType.dribble
                  : typeRand < 85
                      ? TouchType.duel
                      : TouchType.shot;
      final minute = period == 'first_half'
          ? random.nextInt(45) + 1
          : period == 'second_half'
              ? random.nextInt(45) + 46
              : random.nextInt(90) + 1;
      touches.add(TouchPoint(
          x: x,
          y: y,
          type: type,
          minute: minute,
          player:
              '#${random.nextInt(90) + 1} ${players[random.nextInt(players.length)]}',
          zone: zone,
          successful: random.nextDouble() > 0.25));
    }
    return touches;
  }

  List<TouchPlayer> _getMockTopPlayers() => [
        TouchPlayer(
            name: 'Luis Alberto',
            number: '10',
            totalTouches: 98,
            successfulTouches: 89,
            passes: 76,
            dribbles: 12,
            shots: 4),
        TouchPlayer(
            name: 'Guendouzi',
            number: '8',
            totalTouches: 87,
            successfulTouches: 78,
            passes: 68,
            dribbles: 8,
            shots: 2),
        TouchPlayer(
            name: 'Immobile',
            number: '9',
            totalTouches: 65,
            successfulTouches: 54,
            passes: 38,
            dribbles: 15,
            shots: 8),
        TouchPlayer(
            name: 'Zaccagni',
            number: '20',
            totalTouches: 58,
            successfulTouches: 48,
            passes: 35,
            dribbles: 12,
            shots: 5),
        TouchPlayer(
            name: 'Anderson',
            number: '7',
            totalTouches: 52,
            successfulTouches: 44,
            passes: 32,
            dribbles: 10,
            shots: 6),
      ];

  Map<String, int> _getMockZoneStats() =>
      {'defense': 120, 'midfield': 195, 'attack': 135};
  Map<String, int> _getMockDetailedStats() => {
        'totalTouches': 450,
        'passes': 320,
        'dribbles': 45,
        'shots': 18,
        'controls': 48,
        'duels': 19
      };
}

class TouchesFieldPainter extends CustomPainter {
  final List<TouchPoint> touches;
  final bool showHeatmap, showIndividualTouches;
  final double animationValue;
  final Set<TouchType> visibleTouches;
  final bool isCompact;
  final TouchPoint? hoveredTouch, selectedTouch;

  TouchesFieldPainter({
    required this.touches,
    required this.showHeatmap,
    required this.animationValue,
    required this.visibleTouches,
    this.isCompact = false,
    this.hoveredTouch,
    this.selectedTouch,
    this.showIndividualTouches = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = const Color(0xFF1B5E20));
    _drawFieldLines(canvas, size);
    if (showHeatmap) _drawMultiColorHeatmap(canvas, size);
    if (showIndividualTouches) _drawTouches(canvas, size);
  }

  void _drawFieldLines(Canvas canvas, Size size) {
    // ✅ SE COMPATTO: mantieni versione semplice (per confronto)
    if (isCompact) {
      final linePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      final thickLinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
              const Radius.circular(8)),
          thickLinePaint);
      canvas.drawLine(Offset(size.width / 2, 1),
          Offset(size.width / 2, size.height - 1), thickLinePaint);
      final centerX = size.width / 2,
          centerY = size.height / 2,
          circleRadius = size.height * 0.15;
      canvas.drawCircle(Offset(centerX, centerY), circleRadius, linePaint);
      canvas.drawCircle(
          Offset(centerX, centerY),
          4.0,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill);
      final penaltyWidth = size.width * 0.20,
          penaltyHeight = size.height * 0.50,
          penaltyY = (size.height - penaltyHeight) / 2;
      canvas.drawRect(
          Rect.fromLTWH(1, penaltyY, penaltyWidth, penaltyHeight), linePaint);
      canvas.drawRect(
          Rect.fromLTWH(size.width - penaltyWidth - 1, penaltyY, penaltyWidth,
              penaltyHeight),
          linePaint);
      return;
    }

    // ✅ CAMPO SINGOLO GRANDE: versione realistica dettagliata
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final thickLinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Bordo campo con angoli arrotondati
    final borderRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(2, 2, size.width - 4, size.height - 4),
      const Radius.circular(12),
    );
    canvas.drawRRect(borderRect, thickLinePaint);

    // Linea di metà campo
    canvas.drawLine(
      Offset(size.width / 2, 2),
      Offset(size.width / 2, size.height - 2),
      thickLinePaint,
    );

    // Cerchio di centrocampo (raggio 9.15m = ~18% altezza)
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final centerCircleRadius = size.height * 0.18;
    canvas.drawCircle(Offset(centerX, centerY), centerCircleRadius, linePaint);

    // Punto centrale
    canvas.drawCircle(Offset(centerX, centerY), 5, dotPaint);

    // === AREA DI RIGORE SINISTRA (HOME) ===

    // Area grande (16.5m = ~40m larghezza campo reale, proporzionale)
    final penaltyBoxWidth = size.width * 0.23; // 23% larghezza
    final penaltyBoxHeight = size.height * 0.63; // 63% altezza (40.32m su 68m)
    final penaltyBoxY = (size.height - penaltyBoxHeight) / 2;

    // Disegna area grande sinistra
    canvas.drawLine(
      Offset(penaltyBoxWidth, penaltyBoxY),
      Offset(2, penaltyBoxY),
      thickLinePaint,
    );
    canvas.drawLine(
      Offset(penaltyBoxWidth, penaltyBoxY),
      Offset(penaltyBoxWidth, penaltyBoxY + penaltyBoxHeight),
      thickLinePaint,
    );
    canvas.drawLine(
      Offset(penaltyBoxWidth, penaltyBoxY + penaltyBoxHeight),
      Offset(2, penaltyBoxY + penaltyBoxHeight),
      thickLinePaint,
    );

    // Area piccola sinistra (5.5m = ~33% dell'area grande)
    final smallBoxWidth = penaltyBoxWidth * 0.40;
    final smallBoxHeight = penaltyBoxHeight * 0.44;
    final smallBoxY = (size.height - smallBoxHeight) / 2;

    canvas.drawLine(
      Offset(smallBoxWidth, smallBoxY),
      Offset(2, smallBoxY),
      linePaint,
    );
    canvas.drawLine(
      Offset(smallBoxWidth, smallBoxY),
      Offset(smallBoxWidth, smallBoxY + smallBoxHeight),
      linePaint,
    );
    canvas.drawLine(
      Offset(smallBoxWidth, smallBoxY + smallBoxHeight),
      Offset(2, smallBoxY + smallBoxHeight),
      linePaint,
    );

    // Punto del rigore sinistro (11m dalla porta = ~48% dell'area)
    final penaltySpotX = penaltyBoxWidth * 0.48;
    canvas.drawCircle(Offset(penaltySpotX, centerY), 4, dotPaint);

    // ✅ MEZZALUNA SINISTRA: centro SUL BORDO, sporge verso centrocampo
    final moonRadius = size.height * 0.10; // Raggio mezzaluna

    canvas.drawArc(
      Rect.fromCircle(
        center:
            Offset(penaltyBoxWidth, centerY), // ✅ Centro SUL BORDO dell'area
        radius: moonRadius,
      ),
      -math.pi / 2, // -90° (inizia dall'alto)
      math.pi, // 180° verso destra (centrocampo)
      false,
      linePaint,
    );

    // === AREA DI RIGORE DESTRA (AWAY) ===

    // Area grande destra
    canvas.drawLine(
      Offset(size.width - penaltyBoxWidth, penaltyBoxY),
      Offset(size.width - 2, penaltyBoxY),
      thickLinePaint,
    );
    canvas.drawLine(
      Offset(size.width - penaltyBoxWidth, penaltyBoxY),
      Offset(size.width - penaltyBoxWidth, penaltyBoxY + penaltyBoxHeight),
      thickLinePaint,
    );
    canvas.drawLine(
      Offset(size.width - penaltyBoxWidth, penaltyBoxY + penaltyBoxHeight),
      Offset(size.width - 2, penaltyBoxY + penaltyBoxHeight),
      thickLinePaint,
    );

    // Area piccola destra
    canvas.drawLine(
      Offset(size.width - smallBoxWidth, smallBoxY),
      Offset(size.width - 2, smallBoxY),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width - smallBoxWidth, smallBoxY),
      Offset(size.width - smallBoxWidth, smallBoxY + smallBoxHeight),
      linePaint,
    );
    canvas.drawLine(
      Offset(size.width - smallBoxWidth, smallBoxY + smallBoxHeight),
      Offset(size.width - 2, smallBoxY + smallBoxHeight),
      linePaint,
    );

    // Punto del rigore destro
    final penaltySpotRightX = size.width - (penaltyBoxWidth * 0.48);
    canvas.drawCircle(Offset(penaltySpotRightX, centerY), 4, dotPaint);

    // ✅ MEZZALUNA DESTRA: centro SUL BORDO, sporge verso centrocampo
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(size.width - penaltyBoxWidth,
            centerY), // ✅ Centro SUL BORDO dell'area
        radius: moonRadius,
      ),
      math.pi / 2, // 90° (inizia dal basso)
      math.pi, // 180° verso sinistra (centrocampo)
      false,
      linePaint,
    );

    // === ANGOLI DEL CAMPO ===
    final cornerRadius = 8.0;

    // Angolo alto-sinistra
    canvas.drawArc(
      Rect.fromLTWH(2, 2, cornerRadius * 2, cornerRadius * 2),
      math.pi,
      math.pi / 2,
      false,
      linePaint,
    );

    // Angolo alto-destra
    canvas.drawArc(
      Rect.fromLTWH(size.width - cornerRadius * 2 - 2, 2, cornerRadius * 2,
          cornerRadius * 2),
      -math.pi / 2,
      math.pi / 2,
      false,
      linePaint,
    );

    // Angolo basso-sinistra
    canvas.drawArc(
      Rect.fromLTWH(2, size.height - cornerRadius * 2 - 2, cornerRadius * 2,
          cornerRadius * 2),
      math.pi / 2,
      math.pi / 2,
      false,
      linePaint,
    );

    // Angolo basso-destra
    canvas.drawArc(
      Rect.fromLTWH(
          size.width - cornerRadius * 2 - 2,
          size.height - cornerRadius * 2 - 2,
          cornerRadius * 2,
          cornerRadius * 2),
      0,
      math.pi / 2,
      false,
      linePaint,
    );
  }

  // ✅ HEATMAP REALISTICA MIGLIORATA
  void _drawMultiColorHeatmap(Canvas canvas, Size size) {
    final visibleTouchesList =
        touches.where((t) => visibleTouches.contains(t.type)).toList();
    if (visibleTouchesList.isEmpty) return;

    // Calcola densità locale per ogni tocco (raggio di influenza)
    final List<MapEntry<TouchPoint, double>> touchesWithDensity = [];

    for (final touch in visibleTouchesList) {
      double density = 0;
      for (final other in visibleTouchesList) {
        final dx = touch.x - other.x;
        final dy = touch.y - other.y;
        final distance = math.sqrt(dx * dx + dy * dy);

        // Densità basata su distanza (influenza fino a 0.15 = ~15% del campo)
        if (distance < 0.15) {
          density += (1.0 - (distance / 0.15));
        }
      }
      touchesWithDensity.add(MapEntry(touch, density));
    }

    // Trova densità massima per normalizzazione
    final maxDensity = touchesWithDensity.map((e) => e.value).reduce(math.max);

    // Disegna heatmap in ordine inverso (meno densi prima)
    touchesWithDensity.sort((a, b) => a.value.compareTo(b.value));

    for (final entry in touchesWithDensity) {
      final touch = entry.key;
      final density = entry.value;
      final intensity = (density / maxDensity).clamp(0.0, 1.0);

      final x = touch.x * size.width;
      final y = touch.y * size.height;

      // Raggio dinamico: zone dense = cerchi più grandi
      final baseRadius = isCompact ? 40.0 : 55.0;
      final radius = baseRadius * (0.8 + (intensity * 0.6));

      // Colore basato su intensità: Blu → Verde → Giallo → Rosso
      Color color;
      if (intensity < 0.25) {
        color = Color.lerp(
            const Color(0xFF2196F3), const Color(0xFF00BCD4), intensity * 4)!;
      } else if (intensity < 0.5) {
        color = Color.lerp(const Color(0xFF00BCD4), const Color(0xFF4CAF50),
            (intensity - 0.25) * 4)!;
      } else if (intensity < 0.75) {
        color = Color.lerp(const Color(0xFF4CAF50), const Color(0xFFFFC107),
            (intensity - 0.5) * 4)!;
      } else {
        color = Color.lerp(const Color(0xFFFFC107), const Color(0xFFE53935),
            (intensity - 0.75) * 4)!;
      }

      // Doppio strato per effetto più realistico

      // Strato 1: Alone esterno più grande e trasparente (glow)
      final glowGradient = RadialGradient(
        colors: [
          color.withOpacity(0.15 * animationValue * intensity),
          color.withOpacity(0.08 * animationValue * intensity),
          color.withOpacity(0.03 * animationValue * intensity),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.4, 0.7, 1.0],
      );

      final glowPaint = Paint()
        ..shader = glowGradient.createShader(
            Rect.fromCircle(center: Offset(x, y), radius: radius * 1.5))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

      canvas.drawCircle(Offset(x, y), radius * 1.5, glowPaint);

      // Strato 2: Nucleo centrale più intenso
      final coreGradient = RadialGradient(
        colors: [
          color.withOpacity(0.6 * animationValue * intensity),
          color.withOpacity(0.45 * animationValue * intensity),
          color.withOpacity(0.25 * animationValue * intensity),
          color.withOpacity(0.1 * animationValue * intensity),
          color.withOpacity(0.0),
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      );

      final corePaint = Paint()
        ..shader = coreGradient
            .createShader(Rect.fromCircle(center: Offset(x, y), radius: radius))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(Offset(x, y), radius, corePaint);

      // Strato 3: Centro molto intenso per zone ad alta densità
      if (intensity > 0.6) {
        final hotspotGradient = RadialGradient(
          colors: [
            color.withOpacity(0.8 * animationValue * intensity),
            color.withOpacity(0.5 * animationValue * intensity),
            color.withOpacity(0.0),
          ],
          stops: const [0.0, 0.5, 1.0],
        );

        final hotspotPaint = Paint()
          ..shader = hotspotGradient.createShader(
              Rect.fromCircle(center: Offset(x, y), radius: radius * 0.4))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        canvas.drawCircle(Offset(x, y), radius * 0.4, hotspotPaint);
      }
    }
  }

  void _drawTouches(Canvas canvas, Size size) {
    for (int i = 0; i < touches.length; i++) {
      final touch = touches[i];
      if (!visibleTouches.contains(touch.type)) continue;
      final touchProgress =
          ((animationValue * touches.length) - i).clamp(0.0, 1.0);
      if (touchProgress <= 0) continue;
      _drawTouch(
          canvas,
          touch,
          Offset(touch.x * size.width, touch.y * size.height),
          touchProgress,
          touch == hoveredTouch,
          touch == selectedTouch);
    }
  }

  void _drawTouch(Canvas canvas, TouchPoint touch, Offset position,
      double progress, bool isHovered, bool isSelected) {
    Color color = touch.type == TouchType.pass
        ? const Color(0xFF2196F3)
        : touch.type == TouchType.dribble
            ? const Color(0xFFFF9800)
            : touch.type == TouchType.shot
                ? const Color(0xFFE53935)
                : touch.type == TouchType.control
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF9C27B0);
    final baseSize = isCompact ? 8.0 : 10.0,
        size = baseSize * progress * (isHovered || isSelected ? 1.8 : 1.0),
        opacity = touch.successful ? 0.9 : 0.4;
    canvas.drawCircle(
        position.translate(1, 1),
        size,
        Paint()
          ..color = Colors.black.withOpacity(0.3 * progress)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawCircle(
        position, size, Paint()..color = color.withOpacity(opacity * progress));
    if (isHovered || isSelected)
      canvas.drawCircle(
          position,
          size + 2,
          Paint()
            ..color = isSelected ? Colors.yellow : Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected ? 3 : 2);
  }

  @override
  bool shouldRepaint(TouchesFieldPainter old) =>
      old.animationValue != animationValue ||
      old.visibleTouches != visibleTouches ||
      old.showHeatmap != showHeatmap ||
      old.hoveredTouch != hoveredTouch ||
      old.selectedTouch != selectedTouch ||
      old.showIndividualTouches != showIndividualTouches;
}
