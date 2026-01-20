import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/soccer_match.dart';
import '../models/player.dart';
import '../models/player_detail.dart';
import '../api/api_service.dart';
import '../services/haptic_service.dart';
import '../services/favorites_service.dart';
import '../generated/l10n.dart';
import 'player_detail_screen.dart';

class MatchDetailScreen extends StatefulWidget {
  final SoccerMatch match;

  const MatchDetailScreen({
    Key? key,
    required this.match,
  }) : super(key: key);

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final HapticService _haptic = HapticService();
  final FavoritesService _favoritesService = FavoritesService();

  late TabController _tabController;

  bool _shotMapShowHome = true;
  bool _passNetworkShowHome = true;
  bool _pressureMapShowHome = true;
  bool _heatmapShowHome = true;
  bool _touchMapShowHome = true;

  String _eventFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadMatchData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMatchData() {}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = S.of(context);

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(theme, isDark),
          _buildTabBar(theme, isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStatisticsTab(theme, isDark, s),
                _buildAdvancedStatsTab(theme, isDark),
                _buildEventsTab(theme, isDark),
                _buildLineupsTab(theme, isDark),
                _buildInfoTab(theme, isDark, s),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor,
            theme.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () => _haptic.lightImpact(),
              ),
              IconButton(
                icon: const Icon(Icons.share, color: Colors.white),
                onPressed: () => _haptic.lightImpact(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Column(
                  children: [
                    if (widget.match.homeTeamLogo != null)
                      CachedNetworkImage(
                        imageUrl: widget.match.homeTeamLogo!,
                        height: 60,
                        width: 60,
                        errorWidget: (context, url, error) => const Icon(
                          Icons.shield,
                          size: 60,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(Icons.shield, size: 60, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      widget.match.homeTeamName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.match.homeScore} - ${widget.match.awayScore}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Column(
                  children: [
                    if (widget.match.awayTeamLogo != null)
                      CachedNetworkImage(
                        imageUrl: widget.match.awayTeamLogo!,
                        height: 60,
                        width: 60,
                        errorWidget: (context, url, error) => const Icon(
                          Icons.shield,
                          size: 60,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(Icons.shield, size: 60, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      widget.match.awayTeamName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildTabBar(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: theme.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: theme.primaryColor,
        isScrollable: true,
        tabs: const [
          Tab(text: 'Statistiche', icon: Icon(Icons.bar_chart, size: 20)),
          Tab(text: 'Avanzate', icon: Icon(Icons.analytics, size: 20)),
          Tab(text: 'Eventi', icon: Icon(Icons.timeline, size: 20)),
          Tab(text: 'Formazioni', icon: Icon(Icons.people, size: 20)),
          Tab(text: 'Info', icon: Icon(Icons.info_outline, size: 20)),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab(ThemeData theme, bool isDark, S? s) {
    if (widget.match.isScheduled) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart,
                size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              s?.noDataAvailable ?? 'Dati non disponibili',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final stats = [
      {'type': 'Possesso', 'home': '55%', 'away': '45%'},
      {'type': 'Tiri', 'home': '14', 'away': '12'},
      {'type': 'Tiri in porta', 'home': '6', 'away': '5'},
      {'type': 'Corner', 'home': '7', 'away': '4'},
      {'type': 'Falli', 'home': '12', 'away': '15'},
      {'type': 'Gialli', 'home': '2', 'away': '3'},
      {'type': 'Rossi', 'home': '0', 'away': '0'},
      {'type': 'Fuorigioco', 'home': '3', 'away': '2'},
    ];

    return Container(
      color: isDark ? Colors.grey[900] : Colors.grey[50],
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return _buildStatRow(
            stat['type']!,
            stat['home']!,
            stat['away']!,
            theme,
            isDark,
          ).animate().fadeIn(delay: Duration(milliseconds: index * 50));
        },
      ),
    );
  }

  Widget _buildStatRow(
      String type, String home, String away, ThemeData theme, bool isDark) {
    double? homeValue, awayValue;
    if (type.contains('%')) {
      homeValue = double.tryParse(home.replaceAll('%', ''));
      awayValue = double.tryParse(away.replaceAll('%', ''));
    } else {
      homeValue = double.tryParse(home);
      awayValue = double.tryParse(away);
    }

    final maxValue = (homeValue ?? 0) > (awayValue ?? 0)
        ? (homeValue ?? 0)
        : (awayValue ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Text(
            type,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          if (homeValue != null && maxValue > 0)
                            FractionallySizedBox(
                              alignment: Alignment.centerRight,
                              widthFactor: homeValue / (maxValue * 1.1),
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 40,
                      child: Text(
                        home,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        away,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          if (awayValue != null && maxValue > 0)
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: awayValue / (maxValue * 1.1),
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                        ],
                      ),
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

  Widget _buildAdvancedStatsTab(ThemeData theme, bool isDark) {
    return Container(
      color: isDark ? Colors.grey[900] : Colors.grey[50],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildXGChart(theme, isDark),
            const SizedBox(height: 20),
            _buildShotMap(theme, isDark),
            const SizedBox(height: 20),
            _buildTouchMap(theme, isDark),
            const SizedBox(height: 20),
            _buildHeatmap(theme, isDark),
            const SizedBox(height: 20),
            _buildPassNetwork(theme, isDark),
            const SizedBox(height: 20),
            _buildPressureMap(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildXGChart(ThemeData theme, bool isDark) {
    const homeXG = 2.3;
    const awayXG = 1.7;
    const maxXG = 4.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFFFA726)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.insights, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expected Goals (xG)',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Qualità delle occasioni create',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  widget.match.homeTeamName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: homeXG / maxXG,
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const SizedBox(
                width: 40,
                child: Text(
                  '2.3',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  widget.match.awayTeamName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 30,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: awayXG / maxXG,
                      child: Container(
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE53935), Color(0xFFEF5350)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const SizedBox(
                width: 40,
                child: Text(
                  '1.7',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE53935),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShotMap(ThemeData theme, bool isDark) {
    final selectedShots =
        _shotMapShowHome ? _generateMockShots(true) : _generateMockShots(false);
    final teamColor =
        _shotMapShowHome ? const Color(0xFF2196F3) : const Color(0xFFE53935);

    final totalShots = selectedShots.length;
    final onTarget = selectedShots.where((s) => s.isOnTarget).length;
    final goals = selectedShots.where((s) => s.isGoal).length;
    final avgXG = selectedShots.fold(0.0, (sum, shot) => sum + shot.xg) /
        selectedShots.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.grey[850]! : Colors.white,
            isDark ? Colors.grey[900]! : Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: teamColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [teamColor, teamColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: teamColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child:
                    const Icon(Icons.gps_fixed, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shot Map',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Posizione e qualità tiri',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTeamSelector(
            _shotMapShowHome,
            (value) => setState(() => _shotMapShowHome = value),
            isDark,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  teamColor.withOpacity(0.08),
                  teamColor.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: teamColor.withOpacity(0.2), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat('Tiri', totalShots.toString(),
                    Icons.sports_soccer, teamColor),
                _buildQuickStatDivider(isDark),
                _buildQuickStat(
                    'In porta', onTarget.toString(), Icons.adjust, teamColor),
                _buildQuickStatDivider(isDark),
                _buildQuickStat(
                    'Goal', goals.toString(), Icons.sports_score, teamColor),
                _buildQuickStatDivider(isDark),
                _buildQuickStat('xG avg', avgXG.toStringAsFixed(2),
                    Icons.analytics, teamColor),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2D5A2D),
                  Color(0xFF1E4A1E),
                  Color(0xFF2D5A2D),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: Colors.white.withOpacity(0.2), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 500,
                child: CustomPaint(
                  painter: PerfectHalfFieldShotMapPainter(
                    isDark: isDark,
                    shots: selectedShots,
                    teamColor: teamColor,
                  ),
                  size: const Size(double.infinity, 500),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _buildShotLegend(teamColor, isDark),
        ],
      ),
    );
  }

  Widget _buildTouchMap(ThemeData theme, bool isDark) {
    final teamColor =
        _touchMapShowHome ? const Color(0xFF2196F3) : const Color(0xFFE53935);

    final touches = _generateMockTouches();
    final totalTouches = touches.length;
    final defensiveThird = touches.where((t) => t.y > 0.66).length;
    final middleThird = touches.where((t) => t.y >= 0.33 && t.y <= 0.66).length;
    final attackingThird = touches.where((t) => t.y < 0.33).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.grey[850]! : Colors.white,
            isDark ? Colors.grey[900]! : Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: teamColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [teamColor, teamColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: teamColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child:
                    const Icon(Icons.touch_app, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Touch Map',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Posizione tocchi palla',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTeamSelector(
            _touchMapShowHome,
            (value) => setState(() => _touchMapShowHome = value),
            isDark,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  teamColor.withOpacity(0.08),
                  teamColor.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: teamColor.withOpacity(0.2), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat('Totale', totalTouches.toString(),
                    Icons.touch_app, teamColor),
                _buildQuickStatDivider(isDark),
                _buildQuickStat('Difesa', defensiveThird.toString(),
                    Icons.shield, teamColor),
                _buildQuickStatDivider(isDark),
                _buildQuickStat(
                    'Centro', middleThird.toString(), Icons.code, teamColor),
                _buildQuickStatDivider(isDark),
                _buildQuickStat('Attacco', attackingThird.toString(),
                    Icons.sports_soccer, teamColor),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2D5A2D),
                  Color(0xFF1E4A1E),
                  Color(0xFF2D5A2D),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: Colors.white.withOpacity(0.2), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 500,
                child: CustomPaint(
                  painter: TouchMapPainter(
                    isDark: isDark,
                    touches: touches,
                    teamColor: teamColor,
                  ),
                  size: const Size(double.infinity, 500),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _buildTouchLegend(teamColor, isDark),
        ],
      ),
    );
  }

  Widget _buildHeatmap(ThemeData theme, bool isDark) {
    final teamColor =
        _heatmapShowHome ? const Color(0xFF2196F3) : const Color(0xFFE53935);

    final heatmapData = _generateHeatmapData();
    final maxIntensity =
        heatmapData.map((d) => d.intensity).reduce((a, b) => a > b ? a : b);
    final avgIntensity = heatmapData.fold(0.0, (sum, d) => sum + d.intensity) /
        heatmapData.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.grey[850]! : Colors.white,
            isDark ? Colors.grey[900]! : Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: teamColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [teamColor, teamColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: teamColor.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child:
                    const Icon(Icons.whatshot, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Heatmap',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Zone più frequentate',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTeamSelector(
            _heatmapShowHome,
            (value) => setState(() => _heatmapShowHome = value),
            isDark,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  teamColor.withOpacity(0.08),
                  teamColor.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: teamColor.withOpacity(0.2), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat('Zone', heatmapData.length.toString(),
                    Icons.grid_on, teamColor),
                _buildQuickStatDivider(isDark),
                _buildQuickStat('Max', (maxIntensity * 100).toInt().toString(),
                    Icons.trending_up, teamColor),
                _buildQuickStatDivider(isDark),
                _buildQuickStat(
                    'Media',
                    (avgIntensity * 100).toInt().toString(),
                    Icons.show_chart,
                    teamColor),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2D5A2D),
                  Color(0xFF1E4A1E),
                  Color(0xFF2D5A2D),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: Colors.white.withOpacity(0.2), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 500,
                child: CustomPaint(
                  painter: HeatmapPainter(
                    isDark: isDark,
                    heatmapData: heatmapData,
                    teamColor: teamColor,
                  ),
                  size: const Size(double.infinity, 500),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _buildHeatmapLegend(teamColor, isDark),
        ],
      ),
    );
  }

  Widget _buildPassNetwork(ThemeData theme, bool isDark) {
    final teamColor = _passNetworkShowHome
        ? const Color(0xFF2196F3)
        : const Color(0xFFE53935);

    final players = _generatePassNetworkPlayers();
    final passes = _generateMockPasses();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.share, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rete Passaggi',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Connessioni tra giocatori',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTeamSelector(
            _passNetworkShowHome,
            (value) => setState(() => _passNetworkShowHome = value),
            isDark,
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2E7D32),
                  Color(0xFF1B5E20),
                  Color(0xFF2E7D32),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                height: 500,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final fieldWidth = constraints.maxWidth;
                    const fieldHeight = 500.0;

                    return Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        CustomPaint(
                          painter: FootballFieldPainter(),
                          size: Size(fieldWidth, fieldHeight),
                        ),
                        CustomPaint(
                          painter: PassNetworkLinesPainter(
                            isDark: isDark,
                            passes: passes,
                            players: players,
                            teamColor: teamColor,
                          ),
                          size: Size(fieldWidth, fieldHeight),
                        ),
                        ...players.map((player) {
                          final playerX = player.positionOffset.dx * fieldWidth;
                          final playerY =
                              player.positionOffset.dy * fieldHeight;
                          final maxPasses = players
                              .map((p) => p.totalPasses)
                              .reduce((a, b) => a > b ? a : b);
                          final passRatio = player.totalPasses / maxPasses;
                          final radius = 20.0 + (passRatio * 10);

                          return Positioned(
                            left: playerX - 38,
                            top: playerY - 30,
                            child: GestureDetector(
                              onTap: () {
                                _haptic.lightImpact();
                                // VAI DIRETTAMENTE AI DETTAGLI GIOCATORE
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlayerDetailScreen(
                                      player: PlayerDetail(
                                        number: player.number,
                                        name: player.name,
                                        position: player.role,
                                        photo: null,
                                        teamName: _passNetworkShowHome
                                            ? widget.match.homeTeamName
                                            : widget.match.awayTeamName,
                                        teamColor: teamColor,
                                        matches: 25,
                                        goals: 5,
                                        assists: 3,
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
                                        recentRatings: [
                                          7.2,
                                          7.8,
                                          6.9,
                                          8.1,
                                          7.5,
                                          7.0,
                                          8.3,
                                          7.6,
                                          7.9,
                                          7.4
                                        ],
                                        recentForm: ['W', 'W', 'D', 'W', 'L'],
                                        bestMatch: 'Serie A - 8.5',
                                        averageRating: 7.5,
                                        decisiveGoals: 2,
                                        skills: {
                                          'Velocità': 85.0,
                                          'Tiro': 88.0,
                                          'Passaggio': 82.0,
                                          'Dribbling': 87.0,
                                          'Difesa': 68.0,
                                          'Fisico': 76.0,
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
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: SizedBox(
                                width: 76,
                                height: 60,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: radius * 2,
                                      height: radius * 2,
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          colors: [
                                            Color.lerp(
                                                teamColor, Colors.white, 0.3)!,
                                            teamColor,
                                            Color.lerp(
                                                teamColor, Colors.black, 0.2)!,
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: teamColor.withOpacity(0.7),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.4),
                                            blurRadius: 6,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          player.number.toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: radius * 0.7,
                                            fontWeight: FontWeight.w900,
                                            shadows: const [
                                              Shadow(
                                                color: Colors.black54,
                                                blurRadius: 4,
                                                offset: Offset(1, 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.85),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        player.name.length > 8
                                            ? '${player.name.substring(0, 7)}.'
                                            : player.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF9C27B0).withOpacity(0.12),
                  const Color(0xFF9C27B0).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF9C27B0).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: const Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Text('• Linee spesse = Molti passaggi',
                    style: TextStyle(fontSize: 11)),
                Text('• Cerchi grandi = Più passaggi totali',
                    style: TextStyle(fontSize: 11)),
                Text('• Tap su giocatore = Vedi dettagli',
                    style: TextStyle(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPressureMap(ThemeData theme, bool isDark) {
    final teamColor = _pressureMapShowHome
        ? const Color(0xFF2196F3)
        : const Color(0xFFE53935);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFEF5350)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.flash_on, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mappa Pressing',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Zone di recupero palla',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTeamSelector(
            _pressureMapShowHome,
            (value) => setState(() => _pressureMapShowHome = value),
            isDark,
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF2D5A2D),
                  Color(0xFF1E4A1E),
                  Color(0xFF2D5A2D),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.white.withOpacity(0.25), width: 2),
              boxShadow: [
                BoxShadow(
                  color: teamColor.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 400,
                child: CustomPaint(
                  painter: PerfectPressureMapPainter(
                    isDark: isDark,
                    pressureZones: _generateMockPressureZones(),
                    teamColor: teamColor,
                  ),
                  size: const Size(double.infinity, 400),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  teamColor.withOpacity(0.12),
                  teamColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: teamColor.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPressureLegendImproved('Alta', 0.8, teamColor),
                Container(height: 30, width: 1, color: Colors.grey[400]),
                _buildPressureLegendImproved('Media', 0.5, teamColor),
                Container(height: 30, width: 1, color: Colors.grey[400]),
                _buildPressureLegendImproved('Bassa', 0.3, teamColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPressureLegendImproved(
      String label, double intensity, Color teamColor) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                teamColor.withOpacity(intensity),
                teamColor.withOpacity(intensity * 0.5),
                teamColor.withOpacity(0),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: teamColor, width: 2),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEventsTab(ThemeData theme, bool isDark) {
    final events = _generateMockEvents();

    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Nessun evento disponibile',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    final filteredEvents = events.where((event) {
      if (_eventFilter == 'all') return true;
      if (_eventFilter == 'goals') return event.type == 'goal';
      if (_eventFilter == 'cards')
        return event.type == 'yellowCard' || event.type == 'redCard';
      if (_eventFilter == 'substitutions') return event.type == 'substitution';
      return true;
    }).toList();

    return Container(
      color: isDark ? Colors.grey[900] : Colors.grey[50],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildEventFilterChip('Tutti', 'all', isDark),
                  const SizedBox(width: 8),
                  _buildEventFilterChip('⚽ Goal', 'goals', isDark),
                  const SizedBox(width: 8),
                  _buildEventFilterChip('🟨 Cartellini', 'cards', isDark),
                  const SizedBox(width: 8),
                  _buildEventFilterChip('🔄 Cambi', 'substitutions', isDark),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: filteredEvents.length,
              separatorBuilder: (context, index) => const SizedBox(height: 20),
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                return _buildEventCard(event, isDark, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventFilterChip(String label, String value, bool isDark) {
    final isSelected = _eventFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _eventFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(MatchEvent event, bool isDark, ThemeData theme) {
    final isHome = event.isHomeTeam;
    final teamColor =
        isHome ? const Color(0xFF2196F3) : const Color(0xFFE53935);

    return GestureDetector(
      onTap: () {
        _haptic.lightImpact();
        // VAI DIRETTAMENTE AI DETTAGLI GIOCATORE
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerDetailScreen(
              player: PlayerDetail(
                number: 10,
                name: event.playerName,
                position: 'Forward',
                photo: null,
                teamName: isHome
                    ? widget.match.homeTeamName
                    : widget.match.awayTeamName,
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
                recentRatings: [
                  7.2,
                  7.8,
                  6.9,
                  8.1,
                  7.5,
                  7.0,
                  8.3,
                  7.6,
                  7.9,
                  7.4
                ],
                recentForm: ['W', 'W', 'D', 'W', 'L'],
                bestMatch: 'Serie A - 8.5',
                averageRating: 7.5,
                decisiveGoals: 3,
                skills: {
                  'Velocità': 85.0,
                  'Tiro': 88.0,
                  'Passaggio': 82.0,
                  'Dribbling': 87.0,
                  'Difesa': 68.0,
                  'Fisico': 76.0,
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
              ),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? Colors.grey[850]! : Colors.white,
              isDark ? Colors.grey[900]! : Colors.grey[50]!,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: teamColor.withOpacity(0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: teamColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [teamColor, teamColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: teamColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    event.minute.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    '\'',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _buildEventIcon(event.type, teamColor),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: teamColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isHome
                              ? widget.match.homeTeamName
                              : widget.match.awayTeamName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: teamColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.playerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (event.detail != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.detail!,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: teamColor.withOpacity(0.5), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildEventIcon(String type, Color color) {
    IconData icon;
    Color bgColor = color;

    switch (type) {
      case 'goal':
        icon = Icons.sports_soccer;
        bgColor = const Color(0xFF00C853);
        break;
      case 'yellowCard':
        icon = Icons.rectangle;
        bgColor = const Color(0xFFFFC107);
        break;
      case 'redCard':
        icon = Icons.rectangle;
        bgColor = const Color(0xFFE53935);
        break;
      case 'substitution':
        icon = Icons.swap_horiz;
        bgColor = const Color(0xFF2196F3);
        break;
      case 'penalty':
        icon = Icons.sports_score;
        bgColor = const Color(0xFF9C27B0);
        break;
      default:
        icon = Icons.circle;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildLineupsTab(ThemeData theme, bool isDark) {
    final homeLineup = _generateMockLineup(true);
    final awayLineup = _generateMockLineup(false);

    return Container(
      color: isDark ? Colors.grey[900] : Colors.grey[50],
      child: SingleChildScrollView(
        child: Column(
          children: [
            // FORMAZIONE CASA
            _buildTeamLineup(
              widget.match.homeTeamName,
              widget.match.homeTeamLogo,
              homeLineup,
              const Color(0xFF2196F3),
              isDark,
            ),
            const SizedBox(height: 20),
            // FORMAZIONE OSPITE
            _buildTeamLineup(
              widget.match.awayTeamName,
              widget.match.awayTeamLogo,
              awayLineup,
              const Color(0xFFE53935),
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamLineup(String teamName, String? teamLogo,
      List<LineupPlayer> players, Color teamColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [teamColor, teamColor.withOpacity(0.8)],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                if (teamLogo != null)
                  CachedNetworkImage(
                    imageUrl: teamLogo,
                    height: 30,
                    width: 30,
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.shield, color: Colors.white, size: 30),
                  )
                else
                  const Icon(Icons.shield, color: Colors.white, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    teamName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Text(
                  '4-3-3',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Lista giocatori
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: players.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final player = players[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: teamColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: teamColor, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      player.number.toString(),
                      style: TextStyle(
                        color: teamColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  player.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  player.position,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _haptic.lightImpact();
                  // VAI DIRETTAMENTE AI DETTAGLI GIOCATORE
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PlayerDetailScreen(
                        player: PlayerDetail(
                          number: player.number,
                          name: player.name,
                          position: player.position,
                          photo: null,
                          teamName: teamName,
                          teamColor: teamColor,
                          matches: 25,
                          goals: 5,
                          assists: 3,
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
                          recentRatings: [
                            7.2,
                            7.8,
                            6.9,
                            8.1,
                            7.5,
                            7.0,
                            8.3,
                            7.6,
                            7.9,
                            7.4
                          ],
                          recentForm: ['W', 'W', 'D', 'W', 'L'],
                          bestMatch: 'Serie A - 8.5',
                          averageRating: 7.5,
                          decisiveGoals: 2,
                          skills: {
                            'Velocità': 85.0,
                            'Tiro': 88.0,
                            'Passaggio': 82.0,
                            'Dribbling': 87.0,
                            'Difesa': 68.0,
                            'Fisico': 76.0,
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
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(ThemeData theme, bool isDark, S? s) {
    final info = [
      {
        'label': 'Lega',
        'value': widget.match.leagueName ?? 'N/A',
        'icon': Icons.emoji_events
      },
      {
        'label': 'Giornata',
        'value': widget.match.round ?? 'N/A',
        'icon': Icons.calendar_today
      },
      {
        'label': 'Data',
        'value':
            '${widget.match.date.day}/${widget.match.date.month}/${widget.match.date.year}',
        'icon': Icons.event
      },
      {'label': 'Ora', 'value': widget.match.time, 'icon': Icons.access_time},
      {
        'label': 'Stadio',
        'value': widget.match.venue.isNotEmpty ? widget.match.venue : 'N/A',
        'icon': Icons.stadium
      },
      {
        'label': 'Arbitro',
        'value': widget.match.referee ?? 'N/A',
        'icon': Icons.person
      },
    ];

    return Container(
      color: isDark ? Colors.grey[900] : Colors.grey[50],
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: info.length,
        itemBuilder: (context, index) {
          final item = info[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(item['icon'] as IconData, color: theme.primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['label'] as String,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['value'] as String,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // WIDGETS HELPER

  Widget _buildTeamSelector(
      bool showHome, Function(bool) onChanged, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(14),
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
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: showHome
                      ? const LinearGradient(
                          colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: showHome
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2196F3).withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  widget.match.homeTeamName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: showHome ? Colors.white : Colors.grey[600],
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: !showHome
                      ? const LinearGradient(
                          colors: [Color(0xFFE53935), Color(0xFFC62828)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: !showHome
                      ? [
                          BoxShadow(
                            color: const Color(0xFFE53935).withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  widget.match.awayTeamName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: !showHome ? Colors.white : Colors.grey[600],
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatDivider(bool isDark) {
    return Container(
      height: 40,
      width: 1,
      color: isDark ? Colors.grey[700] : Colors.grey[300],
    );
  }

  Widget _buildShotLegend(Color teamColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildShotLegendItem(
                  'Goal', const Color(0xFF00C853), Icons.check_circle),
              _buildShotLegendItem(
                  'In porta', const Color(0xFF2196F3), Icons.trip_origin),
              _buildShotLegendItem(
                  'Parato', const Color(0xFF9C27B0), Icons.block),
              _buildShotLegendItem(
                  'Fuori', const Color(0xFFFF9800), Icons.cancel),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: teamColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 14, color: teamColor),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'La dimensione dei cerchi rappresenta il valore xG',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShotLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTouchLegend(Color teamColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTouchLegendItem(
                  'Attacco', const Color(0xFFE53935), Icons.sports_soccer),
              _buildTouchLegendItem(
                  'Centro', const Color(0xFFFF9800), Icons.code),
              _buildTouchLegendItem(
                  'Difesa', const Color(0xFF2196F3), Icons.shield),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: teamColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 14, color: teamColor),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Ogni punto rappresenta un tocco palla',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTouchLegendItem(String label, Color color, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapLegend(Color teamColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Intensità presenza',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeatmapLegendItem('Bassa', teamColor, 0.3),
              _buildHeatmapLegendItem('Media', teamColor, 0.6),
              _buildHeatmapLegendItem('Alta', teamColor, 0.9),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: teamColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 14, color: teamColor),
                const SizedBox(width: 8),
                const Flexible(
                  child: Text(
                    'Le zone più calde indicano maggiore presenza',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapLegendItem(String label, Color color, double opacity) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                color.withOpacity(opacity),
                color.withOpacity(opacity * 0.5),
                color.withOpacity(0),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // MOCK DATA GENERATORS
  List<Shot> _generateMockShots(bool isHome) {
    return [
      Shot(
          x: 0.75,
          y: 0.5,
          isGoal: true,
          isOnTarget: true,
          xg: 0.8,
          isHome: isHome),
      Shot(
          x: 0.65,
          y: 0.3,
          isGoal: false,
          isOnTarget: true,
          xg: 0.4,
          isHome: isHome),
      Shot(
          x: 0.70,
          y: 0.7,
          isGoal: false,
          isOnTarget: false,
          xg: 0.2,
          isHome: isHome),
      Shot(
          x: 0.60,
          y: 0.5,
          isGoal: false,
          isOnTarget: true,
          xg: 0.5,
          isHome: isHome),
      Shot(
          x: 0.80,
          y: 0.4,
          isGoal: true,
          isOnTarget: true,
          xg: 0.9,
          isHome: isHome),
      Shot(
          x: 0.55,
          y: 0.6,
          isGoal: false,
          isOnTarget: false,
          xg: 0.15,
          isHome: isHome),
    ];
  }

  List<TouchPoint> _generateMockTouches() {
    final random = math.Random(42);
    return List.generate(120, (index) {
      return TouchPoint(
        x: 0.1 + random.nextDouble() * 0.8,
        y: 0.1 + random.nextDouble() * 0.8,
        intensity: 0.3 + random.nextDouble() * 0.7,
      );
    });
  }

  List<HeatmapPoint> _generateHeatmapData() {
    return [
      HeatmapPoint(x: 0.50, y: 0.35, intensity: 0.9, radius: 60),
      HeatmapPoint(x: 0.30, y: 0.25, intensity: 0.7, radius: 50),
      HeatmapPoint(x: 0.70, y: 0.25, intensity: 0.8, radius: 55),
      HeatmapPoint(x: 0.50, y: 0.60, intensity: 0.6, radius: 45),
      HeatmapPoint(x: 0.25, y: 0.50, intensity: 0.5, radius: 40),
      HeatmapPoint(x: 0.75, y: 0.50, intensity: 0.5, radius: 40),
      HeatmapPoint(x: 0.50, y: 0.80, intensity: 0.4, radius: 35),
    ];
  }

  List<PassConnection> _generateMockPasses() {
    return [
      PassConnection(from: 1, to: 4, count: 18, successful: 16),
      PassConnection(from: 1, to: 13, count: 16, successful: 15),
      PassConnection(from: 4, to: 32, count: 22, successful: 20),
      PassConnection(from: 13, to: 32, count: 20, successful: 18),
      PassConnection(from: 29, to: 10, count: 19, successful: 17),
      PassConnection(from: 77, to: 21, count: 17, successful: 15),
      PassConnection(from: 32, to: 10, count: 25, successful: 22),
      PassConnection(from: 32, to: 21, count: 15, successful: 13),
      PassConnection(from: 10, to: 17, count: 18, successful: 16),
      PassConnection(from: 10, to: 7, count: 16, successful: 14),
      PassConnection(from: 21, to: 20, count: 14, successful: 12),
      PassConnection(from: 7, to: 17, count: 12, successful: 10),
      PassConnection(from: 20, to: 17, count: 11, successful: 9),
    ];
  }

  List<PassNetworkPlayer> _generatePassNetworkPlayers() {
    return [
      PassNetworkPlayer(
          number: 1,
          name: 'Provedel',
          role: 'GK',
          positionOffset: const Offset(0.50, 0.88),
          totalPasses: 45),
      PassNetworkPlayer(
          number: 29,
          name: 'Lazzari',
          role: 'DF',
          positionOffset: const Offset(0.80, 0.70),
          totalPasses: 32),
      PassNetworkPlayer(
          number: 13,
          name: 'Romagnoli',
          role: 'DF',
          positionOffset: const Offset(0.60, 0.70),
          totalPasses: 38),
      PassNetworkPlayer(
          number: 4,
          name: 'Patric',
          role: 'DF',
          positionOffset: const Offset(0.40, 0.70),
          totalPasses: 36),
      PassNetworkPlayer(
          number: 77,
          name: 'Marusic',
          role: 'DF',
          positionOffset: const Offset(0.20, 0.70),
          totalPasses: 30),
      PassNetworkPlayer(
          number: 32,
          name: 'Cataldi',
          role: 'MF',
          positionOffset: const Offset(0.50, 0.50),
          totalPasses: 65),
      PassNetworkPlayer(
          number: 10,
          name: 'Luis Alberto',
          role: 'MF',
          positionOffset: const Offset(0.70, 0.45),
          totalPasses: 58),
      PassNetworkPlayer(
          number: 21,
          name: 'Milinkovic',
          role: 'MF',
          positionOffset: const Offset(0.30, 0.45),
          totalPasses: 42),
      PassNetworkPlayer(
          number: 7,
          name: 'Felipe And.',
          role: 'FW',
          positionOffset: const Offset(0.75, 0.25),
          totalPasses: 35),
      PassNetworkPlayer(
          number: 17,
          name: 'Immobile',
          role: 'FW',
          positionOffset: const Offset(0.50, 0.18),
          totalPasses: 28),
      PassNetworkPlayer(
          number: 20,
          name: 'Zaccagni',
          role: 'FW',
          positionOffset: const Offset(0.25, 0.25),
          totalPasses: 33),
    ];
  }

  List<PressureZone> _generateMockPressureZones() {
    return [
      PressureZone(x: 0.50, y: 0.35, intensity: 0.8, radius: 50),
      PressureZone(x: 0.30, y: 0.25, intensity: 0.6, radius: 40),
      PressureZone(x: 0.70, y: 0.25, intensity: 0.7, radius: 45),
      PressureZone(x: 0.50, y: 0.60, intensity: 0.5, radius: 35),
    ];
  }

  List<MatchEvent> _generateMockEvents() {
    return [
      MatchEvent(
          minute: 5,
          type: 'goal',
          playerName: 'Immobile',
          detail: 'Assist: Luis Alberto',
          isHomeTeam: true),
      MatchEvent(
          minute: 12,
          type: 'yellowCard',
          playerName: 'Tomori',
          detail: 'Fallo su Zaccagni',
          isHomeTeam: false),
      MatchEvent(
          minute: 23,
          type: 'substitution',
          playerName: 'Pedro',
          detail: 'Entra: Felipe Anderson',
          isHomeTeam: true),
      MatchEvent(
          minute: 34,
          type: 'goal',
          playerName: 'Leão',
          detail: 'Rigore',
          isHomeTeam: false),
    ];
  }

  List<LineupPlayer> _generateMockLineup(bool isHome) {
    if (isHome) {
      return [
        LineupPlayer(
            number: 1, name: 'Ivan Provedel', position: 'Portiere', x: 0, y: 0),
        LineupPlayer(
            number: 29,
            name: 'Manuel Lazzari',
            position: 'Difensore',
            x: 0,
            y: 0),
        LineupPlayer(
            number: 13,
            name: 'Alessio Romagnoli',
            position: 'Difensore',
            x: 0,
            y: 0),
        LineupPlayer(
            number: 4, name: 'Patric', position: 'Difensore', x: 0, y: 0),
        LineupPlayer(
            number: 77,
            name: 'Adam Marušić',
            position: 'Difensore',
            x: 0,
            y: 0),
        LineupPlayer(
            number: 32,
            name: 'Danilo Cataldi',
            position: 'Centrocampista',
            x: 0,
            y: 0),
        LineupPlayer(
            number: 10,
            name: 'Luis Alberto',
            position: 'Centrocampista',
            x: 0,
            y: 0),
        LineupPlayer(
            number: 21,
            name: 'Sergej Milinković',
            position: 'Centrocampista',
            x: 0,
            y: 0),
        LineupPlayer(
            number: 7,
            name: 'Felipe Anderson',
            position: 'Attaccante',
            x: 0,
            y: 0),
        LineupPlayer(
            number: 17,
            name: 'Ciro Immobile',
            position: 'Attaccante',
            x: 0,
            y: 0),
        LineupPlayer(
            number: 20,
            name: 'Mattia Zaccagni',
            position: 'Attaccante',
            x: 0,
            y: 0),
      ];
    } else {
      return [
        LineupPlayer(
            number: 16, name: 'Mike Maignan', position: 'Portiere', x: 0, y: 0),
        LineupPlayer(
            number: 23,
            name: 'Fikayo Tomori',
            position: 'Difensore',
            x: 0,
            y: 0),
        LineupPlayer(
            number: 46,
            name: 'Matteo Gabbia',
            position: 'Difensore',
            x: 0,
            y: 0),
        LineupPlayer(
            number: 2,
            name: 'Davide Calabria',
            position: 'Difensore',
            x: 0,
            y: 0),
        LineupPlayer(
            number: 19,
            name: 'Theo Hernández',
            position: 'Difensore',
            x: 0,
            y: 0),
        LineupPlayer(
            number: 14,
            name: 'Tijjani Reijnders',
            position: 'Centrocampista',
            x: 0,
            y: 0),
        LineupPlayer(
            number: 8,
            name: 'Ruben Loftus-Cheek',
            position: 'Centrocampista',
            x: 0,
            y: 0),
        LineupPlayer(
            number: 10,
            name: 'Rafael Leão',
            position: 'Attaccante',
            x: 0,
            y: 0),
        LineupPlayer(
            number: 11,
            name: 'Christian Pulisic',
            position: 'Attaccante',
            x: 0,
            y: 0),
        LineupPlayer(
            number: 90,
            name: 'Tammy Abraham',
            position: 'Attaccante',
            x: 0,
            y: 0),
        LineupPlayer(
            number: 22,
            name: 'Samuel Chukwueze',
            position: 'Attaccante',
            x: 0,
            y: 0),
      ];
    }
  }

  Color _getStatusColor() {
    if (widget.match.isLive) return Colors.red;
    if (widget.match.isFinished) return Colors.green;
    if (widget.match.isPostponed) return Colors.orange;
    if (widget.match.isCancelled) return Colors.red[900]!;
    return Colors.blue;
  }

  String _getStatusText() {
    if (widget.match.isLive) return 'LIVE';
    if (widget.match.isFinished) return 'FT';
    if (widget.match.isScheduled) return widget.match.time;
    if (widget.match.isPostponed) return 'Posticipato';
    if (widget.match.isCancelled) return 'Cancellato';
    if (widget.match.isHalfTime) return 'HT';
    return widget.match.status;
  }
}

// ============================================================================
// MODELS
// ============================================================================

class Shot {
  final double x, y;
  final bool isGoal, isOnTarget, isHome;
  final double xg;
  Shot(
      {required this.x,
      required this.y,
      required this.isGoal,
      required this.isOnTarget,
      required this.xg,
      required this.isHome});
}

class TouchPoint {
  final double x, y, intensity;
  TouchPoint({required this.x, required this.y, required this.intensity});
}

class HeatmapPoint {
  final double x, y, intensity, radius;
  HeatmapPoint(
      {required this.x,
      required this.y,
      required this.intensity,
      required this.radius});
}

class PassConnection {
  final int from, to, count, successful;
  PassConnection(
      {required this.from,
      required this.to,
      required this.count,
      required this.successful});
  int get failed => count - successful;
}

class PassNetworkPlayer {
  final int number, totalPasses;
  final String name,
      role; // Rinominato 'position' in 'role' per evitare conflitto
  final Offset positionOffset;
  PassNetworkPlayer(
      {required this.number,
      required this.name,
      required this.role,
      required this.positionOffset,
      required this.totalPasses});
}

class PressureZone {
  final double x, y, intensity, radius;
  PressureZone(
      {required this.x,
      required this.y,
      required this.intensity,
      required this.radius});
}

class MatchEvent {
  final int minute;
  final String type, playerName;
  final String? detail;
  final bool isHomeTeam;
  MatchEvent(
      {required this.minute,
      required this.type,
      required this.playerName,
      this.detail,
      required this.isHomeTeam});
}

class LineupPlayer {
  final int number;
  final String name, position;
  final double x, y;
  LineupPlayer(
      {required this.number,
      required this.name,
      required this.position,
      required this.x,
      required this.y});
}

// ============================================================================
// CUSTOM PAINTERS
// ============================================================================

class PerfectHalfFieldShotMapPainter extends CustomPainter {
  final bool isDark;
  final List<Shot> shots;
  final Color teamColor;

  PerfectHalfFieldShotMapPainter(
      {required this.isDark, required this.shots, required this.teamColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    canvas.drawLine(Offset(0, h * 0.95), Offset(w, h * 0.95), paint);
    final penaltyW = w * 0.55;
    final penaltyH = h * 0.35;
    final penaltyLeft = (w - penaltyW) / 2;
    canvas.drawRect(Rect.fromLTWH(penaltyLeft, 0, penaltyW, penaltyH), paint);
    final goalAreaW = w * 0.28;
    final goalAreaH = h * 0.15;
    final goalAreaLeft = (w - goalAreaW) / 2;
    canvas.drawRect(
        Rect.fromLTWH(goalAreaLeft, 0, goalAreaW, goalAreaH), paint);
    final goalW = w * 0.22;
    final goalLeft = (w - goalW) / 2;
    final goalPaint = Paint()
      ..color = Colors.white.withOpacity(0.95)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(goalLeft, 4), Offset(goalLeft + goalW, 4), goalPaint);
    final postPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(goalLeft, 4), 6, postPaint);
    canvas.drawCircle(Offset(goalLeft + goalW, 4), 6, postPaint);
    final centerPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, penaltyH * 0.65), 5, centerPaint);
    for (final shot in shots) {
      _drawShot(canvas, size, shot);
    }
  }

  void _drawShot(Canvas canvas, Size size, Shot shot) {
    Color color;
    IconData? icon;
    if (shot.isGoal) {
      color = const Color(0xFF00C853);
      icon = Icons.sports_soccer;
    } else if (shot.isOnTarget) {
      color = const Color(0xFF2196F3);
    } else if (!shot.isOnTarget && shot.xg > 0.3) {
      color = const Color(0xFF9C27B0);
    } else {
      color = const Color(0xFFFF9800);
    }
    final x = shot.x * size.width;
    final y = shot.y * size.height;
    final radius = 10.0 + (shot.xg * 18);
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), radius + 4, glowPaint);
    final paint = Paint()
      ..color = color.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), radius, paint);
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(x, y), radius, borderPaint);
    if (shot.isGoal && icon != null) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(
              fontSize: radius * 1.2,
              fontFamily: icon.fontFamily,
              color: Colors.white,
              fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TouchMapPainter extends CustomPainter {
  final bool isDark;
  final List<TouchPoint> touches;
  final Color teamColor;

  TouchMapPainter(
      {required this.isDark, required this.touches, required this.teamColor});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), linePaint);
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), linePaint);
    for (final touch in touches) {
      _drawTouch(canvas, size, touch);
    }
  }

  void _drawTouch(Canvas canvas, Size size, TouchPoint touch) {
    final x = touch.x * size.width;
    final y = touch.y * size.height;
    Color color;
    if (y < size.height * 0.33) {
      color = const Color(0xFFE53935);
    } else if (y < size.height * 0.66) {
      color = const Color(0xFFFF9800);
    } else {
      color = const Color(0xFF2196F3);
    }
    final radius = 6.0 * touch.intensity;
    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), radius * 1.5, glowPaint);
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x, y), radius, paint);
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(x, y), radius, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class HeatmapPainter extends CustomPainter {
  final bool isDark;
  final List<HeatmapPoint> heatmapData;
  final Color teamColor;

  HeatmapPainter(
      {required this.isDark,
      required this.heatmapData,
      required this.teamColor});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), linePaint);
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), linePaint);
    for (final zone in heatmapData) {
      _drawHeatZone(canvas, size, zone);
    }
  }

  void _drawHeatZone(Canvas canvas, Size size, HeatmapPoint zone) {
    final center = Offset(zone.x * size.width, zone.y * size.height);
    for (int i = 0; i < 5; i++) {
      final currentRadius = zone.radius * (1 - i * 0.18);
      final currentIntensity = zone.intensity * (1 - i * 0.15);
      final gradient = RadialGradient(
        colors: [
          teamColor.withOpacity(currentIntensity),
          teamColor.withOpacity(currentIntensity * 0.7),
          teamColor.withOpacity(currentIntensity * 0.4),
          teamColor.withOpacity(0),
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      );
      final paint = Paint()
        ..shader = gradient.createShader(
            Rect.fromCircle(center: center, radius: currentRadius))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, currentRadius, paint);
    }
    final centerPaint = Paint()
      ..color = teamColor.withOpacity(0.9)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, centerPaint);
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, 5, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PassNetworkLinesPainter extends CustomPainter {
  final bool isDark;
  final List<PassConnection> passes;
  final List<PassNetworkPlayer> players;
  final Color teamColor;

  PassNetworkLinesPainter(
      {required this.isDark,
      required this.passes,
      required this.players,
      required this.teamColor});

  @override
  void paint(Canvas canvas, Size size) {
    final sortedPasses = List<PassConnection>.from(passes)
      ..sort((a, b) => a.count.compareTo(b.count));
    for (final pass in sortedPasses) {
      final fromPlayer = players.firstWhere((p) => p.number == pass.from);
      final toPlayer = players.firstWhere((p) => p.number == pass.to);
      final from = Offset(fromPlayer.positionOffset.dx * size.width,
          fromPlayer.positionOffset.dy * size.height);
      final to = Offset(toPlayer.positionOffset.dx * size.width,
          toPlayer.positionOffset.dy * size.height);
      final double strokeWidth =
          (2.5 + (pass.count / 6).clamp(0, 5)).toDouble();
      final double opacity = (0.5 + (pass.count / 25).clamp(0, 0.5));
      final glowPaint = Paint()
        ..color = teamColor.withOpacity(opacity * 0.3)
        ..strokeWidth = strokeWidth + 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(from, to, glowPaint);
      final midGlowPaint = Paint()
        ..color = teamColor.withOpacity(opacity * 0.5)
        ..strokeWidth = strokeWidth + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(from, to, midGlowPaint);
      final paint = Paint()
        ..color = teamColor.withOpacity(opacity)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(from, to, paint);
      final innerPaint = Paint()
        ..color = Colors.white.withOpacity(opacity * 0.4)
        ..strokeWidth = strokeWidth * 0.3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(from, to, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class FootballFieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    final margin = 15.0;
    canvas.drawRect(
        Rect.fromLTWH(margin, margin, w - margin * 2, h - margin * 2),
        linePaint);
    canvas.drawLine(
        Offset(margin, h / 2), Offset(w - margin, h / 2), linePaint);
    canvas.drawCircle(Offset(w / 2, h / 2), 50, linePaint);
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2), 4, dotPaint);
    final penaltyW = w * 0.50;
    final penaltyH = h * 0.16;
    final penaltyLeft = (w - penaltyW) / 2;
    canvas.drawRect(
        Rect.fromLTWH(penaltyLeft, margin, penaltyW, penaltyH), linePaint);
    final goalAreaW = w * 0.22;
    final goalAreaH = h * 0.06;
    final goalAreaLeft = (w - goalAreaW) / 2;
    canvas.drawRect(
        Rect.fromLTWH(goalAreaLeft, margin, goalAreaW, goalAreaH), linePaint);
    canvas.drawCircle(Offset(w / 2, margin + penaltyH * 0.75), 3, dotPaint);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(w / 2, margin + penaltyH), radius: 35),
        0,
        3.14159,
        false,
        linePaint);
    canvas.drawRect(
        Rect.fromLTWH(penaltyLeft, h - margin - penaltyH, penaltyW, penaltyH),
        linePaint);
    canvas.drawRect(
        Rect.fromLTWH(
            goalAreaLeft, h - margin - goalAreaH, goalAreaW, goalAreaH),
        linePaint);
    canvas.drawCircle(Offset(w / 2, h - margin - penaltyH * 0.75), 3, dotPaint);
    canvas.drawArc(
        Rect.fromCircle(
            center: Offset(w / 2, h - margin - penaltyH), radius: 35),
        3.14159,
        3.14159,
        false,
        linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PerfectPressureMapPainter extends CustomPainter {
  final bool isDark;
  final List<PressureZone> pressureZones;
  final Color teamColor;

  PerfectPressureMapPainter(
      {required this.isDark,
      required this.pressureZones,
      required this.teamColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    for (final zone in pressureZones) {
      final center = Offset(zone.x * size.width, zone.y * size.height);
      for (int i = 0; i < 3; i++) {
        final currentRadius = zone.radius * (1 - i * 0.3);
        final currentIntensity = zone.intensity * (1 - i * 0.25);
        final gradient = RadialGradient(colors: [
          teamColor.withOpacity(currentIntensity),
          teamColor.withOpacity(currentIntensity * 0.6),
          teamColor.withOpacity(currentIntensity * 0.3),
          teamColor.withOpacity(0)
        ], stops: const [
          0.0,
          0.4,
          0.7,
          1.0
        ]);
        final zonePaint = Paint()
          ..shader = gradient.createShader(
              Rect.fromCircle(center: center, radius: currentRadius))
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, currentRadius, zonePaint);
      }
      final centerPaint = Paint()
        ..color = teamColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 6, centerPaint);
      final borderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, 6, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
