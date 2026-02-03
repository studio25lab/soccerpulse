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
import 'player_match_stats_screen.dart';
import 'player_finished_match_screen.dart';
import '../widgets/animated_advanced_stats_widgets.dart';
import '../widgets/interactive_shot_map_widget.dart';
import '../widgets/passes_widget.dart';
import '../widgets/heatmap_widget.dart'; // ✅ AGGIUNTO
import '../painters/advanced_stats_painters.dart';
import '../painters/formation_field_painter.dart';

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

  String _advancedStatsFilter = 'shots';
  bool _advancedStatsShowHome = true;

  List<ShotData> _homeShotsData = [];
  List<ShotData> _awayShotsData = [];

  bool _showHomeLineup = true;

  String _eventFilter = 'all';
  bool _matchNotificationsEnabled = false;

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

  void _loadMatchData() {
    _loadMockShotData();
  }

  void _loadMockShotData() {
    _homeShotsData = [
      ShotData(
        playerName: 'Immobile',
        playerPhoto: '',
        minute: 23,
        startX: 0.5,
        startY: 0.25,
        goalX: 0.55,
        goalY: 0.45,
        type: 'goal',
        xG: 0.35,
        xGOT: 0.42,
      ),
      ShotData(
        playerName: 'Zaccagni',
        playerPhoto: '',
        minute: 12,
        startX: 0.3,
        startY: 0.35,
        goalX: 0.65,
        goalY: 0.30,
        type: 'on_target',
        xG: 0.18,
        xGOT: 0.15,
      ),
      ShotData(
        playerName: 'Anderson',
        playerPhoto: '',
        minute: 34,
        startX: 0.7,
        startY: 0.40,
        goalX: 0.75,
        goalY: 0.55,
        type: 'blocked',
        xG: 0.22,
        xGOT: 0.20,
      ),
      ShotData(
        playerName: 'Guendouzi',
        playerPhoto: '',
        minute: 45,
        startX: 0.6,
        startY: 0.50,
        goalX: null,
        goalY: null,
        type: 'off_target',
        xG: 0.08,
        xGOT: null,
      ),
      ShotData(
        playerName: 'Pedro',
        playerPhoto: '',
        minute: 78,
        startX: 0.35,
        startY: 0.30,
        goalX: 0.80,
        goalY: 0.25,
        type: 'goal',
        xG: 0.45,
        xGOT: 0.50,
      ),
    ];

    _awayShotsData = [
      ShotData(
        playerName: 'Leao',
        playerPhoto: '',
        minute: 18,
        startX: 0.25,
        startY: 0.35,
        goalX: 0.35,
        goalY: 0.40,
        type: 'blocked',
        xG: 0.28,
        xGOT: 0.25,
      ),
      ShotData(
        playerName: 'Giroud',
        playerPhoto: '',
        minute: 56,
        startX: 0.5,
        startY: 0.20,
        goalX: 0.60,
        goalY: 0.50,
        type: 'goal',
        xG: 0.38,
        xGOT: 0.44,
      ),
      ShotData(
        playerName: 'Theo Hernandez',
        playerPhoto: '',
        minute: 42,
        startX: 0.20,
        startY: 0.45,
        goalX: null,
        goalY: null,
        type: 'off_target',
        xG: 0.05,
        xGOT: null,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(theme, isDark),
          _buildTabBar(theme, isDark),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStatisticsTab(theme, isDark),
                _buildAdvancedStatsTab(theme, isDark),
                _buildEventsTab(theme, isDark),
                _buildLineupsTab(theme, isDark),
                _buildInfoTab(theme, isDark),
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
                icon: Icon(
                  _matchNotificationsEnabled
                      ? Icons.notifications
                      : Icons.notifications_none,
                  color: Colors.white,
                ),
                onPressed: () {
                  _haptic.lightImpact();
                  _showMatchNotificationDialog();
                },
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.white),
                onPressed: () {
                  _haptic.lightImpact();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                            color: Colors.white,
                            size: 60),
                      )
                    else
                      const Icon(Icons.shield, color: Colors.white, size: 60),
                    const SizedBox(height: 12),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '${widget.match.homeScore ?? 0} - ${widget.match.awayScore ?? 0}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.match.status == 'live')
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Colors.white, size: 8),
                            SizedBox(width: 6),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        widget.match.status.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
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
                            color: Colors.white,
                            size: 60),
                      )
                    else
                      const Icon(Icons.shield, color: Colors.white, size: 60),
                    const SizedBox(height: 12),
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
      color: isDark ? Colors.grey[900] : Colors.grey[50],
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: theme.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: theme.primaryColor,
        indicatorWeight: 3,
        tabs: [
          Tab(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart, size: 20),
                SizedBox(height: 4),
                Text('Statistiche', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Tab(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.analytics, size: 20),
                SizedBox(height: 4),
                Text('Avanzate', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Tab(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.timeline, size: 20),
                SizedBox(height: 4),
                Text('Eventi', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Tab(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sports_soccer, size: 20),
                SizedBox(height: 4),
                Text('Formazioni', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          Tab(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 20),
                SizedBox(height: 4),
                Text('Info', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDark ? Colors.grey[900]! : Colors.grey[50]!,
            isDark ? Colors.grey[850]! : Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildModernStatCard('Possesso Palla', 58, 42, isDark,
                Icons.pie_chart, theme.primaryColor),
            const SizedBox(height: 16),
            _buildModernStatCard('Tiri Totali', 15, 8, isDark,
                Icons.sports_soccer, Colors.orange),
            const SizedBox(height: 16),
            _buildModernStatCard(
                'Tiri in Porta', 7, 3, isDark, Icons.gps_fixed, Colors.green),
            const SizedBox(height: 16),
            _buildModernStatCard(
                'Calci d\'Angolo', 6, 4, isDark, Icons.flag, Colors.purple),
            const SizedBox(height: 16),
            _buildModernStatCard(
                'Falli', 12, 15, isDark, Icons.warning, Colors.red),
            const SizedBox(height: 16),
            _buildModernStatCard('Cartellini Gialli', 2, 3, isDark,
                Icons.rectangle, Colors.yellow[700]!),
            const SizedBox(height: 16),
            _buildModernStatCard(
                'Fuorigioco', 3, 1, isDark, Icons.front_hand, Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildModernStatCard(String label, int homeValue, int awayValue,
      bool isDark, IconData icon, Color accentColor) {
    final total = homeValue + awayValue;
    final homePercent = total > 0 ? homeValue / total : 0.5;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.grey[850]! : Colors.white,
            isDark ? Colors.grey[800]! : Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  homeValue.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFC62828)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  awayValue.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2196F3).withOpacity(0.3),
                        const Color(0xFFE53935).withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      flex: (homePercent * 100).round(),
                      child: Container(
                        height: 12,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: ((1 - homePercent) * 100).round(),
                      child: Container(
                        height: 12,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFE53935), Color(0xFFC62828)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(homePercent * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2196F3),
                ),
              ),
              Text(
                '${((1 - homePercent) * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE53935),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistiche Avanzate',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildAdvancedStatsFilterChip(
                          'Tiri', 'shots', Icons.sports_soccer, isDark, theme),
                      const SizedBox(width: 8),
                      _buildAdvancedStatsFilterChip('Passaggi', 'passes',
                          Icons.swap_horiz, isDark, theme),
                      const SizedBox(width: 8),
                      _buildAdvancedStatsFilterChip(
                          'Heatmap', 'heatmap', Icons.whatshot, isDark, theme),
                      const SizedBox(width: 8),
                      _buildAdvancedStatsFilterChip('Pressione', 'pressure',
                          Icons.fitness_center, isDark, theme),
                      const SizedBox(width: 8),
                      _buildAdvancedStatsFilterChip(
                          'Tocchi', 'touches', Icons.touch_app, isDark, theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ✅ NASCOSTO SOLO PER PASSAGGI
                  if (_advancedStatsFilter != 'passes')
                    _buildTeamSelectorForAdvanced(isDark, theme),
                  if (_advancedStatsFilter != 'passes')
                    const SizedBox(height: 16),
                  _buildSelectedAdvancedContent(isDark, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedStatsFilterChip(
      String label, String value, IconData icon, bool isDark, ThemeData theme) {
    final isSelected = _advancedStatsFilter == value;
    return GestureDetector(
      onTap: () {
        _haptic.lightImpact();
        setState(() => _advancedStatsFilter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withOpacity(0.7)
                  ],
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSelectorForAdvanced(bool isDark, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              _haptic.lightImpact();
              setState(() {
                _advancedStatsShowHome = true;
                _shotMapShowHome = true;
                _passNetworkShowHome = true;
                _pressureMapShowHome = true;
                _heatmapShowHome = true;
                _touchMapShowHome = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: _advancedStatsShowHome
                    ? const LinearGradient(
                        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
                      )
                    : null,
                color: _advancedStatsShowHome
                    ? null
                    : (isDark ? Colors.grey[800] : Colors.grey[200]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: _advancedStatsShowHome
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2196F3).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                widget.match.homeTeamName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _advancedStatsShowHome
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              _haptic.lightImpact();
              setState(() {
                _advancedStatsShowHome = false;
                _shotMapShowHome = false;
                _passNetworkShowHome = false;
                _pressureMapShowHome = false;
                _heatmapShowHome = false;
                _touchMapShowHome = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: !_advancedStatsShowHome
                    ? const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFC62828)],
                      )
                    : null,
                color: !_advancedStatsShowHome
                    ? null
                    : (isDark ? Colors.grey[800] : Colors.grey[200]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: !_advancedStatsShowHome
                    ? [
                        BoxShadow(
                          color: const Color(0xFFE53935).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                widget.match.awayTeamName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: !_advancedStatsShowHome
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedAdvancedContent(bool isDark, ThemeData theme) {
    switch (_advancedStatsFilter) {
      case 'shots':
        return InteractiveShotMapWidget(
          shots: _advancedStatsShowHome ? _homeShotsData : _awayShotsData,
          teamColor: _advancedStatsShowHome
              ? const Color(0xFF2196F3)
              : const Color(0xFFE53935),
          isDark: isDark,
        );

      case 'passes':
        // ✅ WIDGET PASSAGGI CON CAMPO 600PX
        return PassesWidget(
          homeTeam: PassesData(
            accuratePasses: 375,
            throwIns: 16,
            finalThirdEntries: 56,
            finalThirdPasses: 86,
            finalThirdTotal: 128,
            longBalls: 30,
            longBallsTotal: 55,
            crosses: 3,
            crossesTotal: 18,
            leftZonePercentage: 26,
            centerZonePercentage: 21,
            rightZonePercentage: 0,
          ),
          awayTeam: PassesData(
            accuratePasses: 478,
            throwIns: 15,
            finalThirdEntries: 46,
            finalThirdPasses: 104,
            finalThirdTotal: 130,
            longBalls: 13,
            longBallsTotal: 31,
            crosses: 6,
            crossesTotal: 17,
            leftZonePercentage: 0,
            centerZonePercentage: 21,
            rightZonePercentage: 32,
          ),
        );

      case 'heatmap':
        // ✅ NUOVO WIDGET HEATMAP COMPLETO CON TUTTE LE FUNZIONALITÀ
        return HeatmapWidget(
          isHome: _advancedStatsShowHome,
          homeTeamName: widget.match.homeTeamName,
          awayTeamName: widget.match.awayTeamName,
        );

      case 'pressure':
        return AnimatedDefensiveActionsWidget(
          isDark: isDark,
        );

      case 'touches':
        return AnimatedHeatmapWidget(
          isHome: _advancedStatsShowHome,
          isDark: isDark,
          teamName: _advancedStatsShowHome
              ? widget.match.homeTeamName
              : widget.match.awayTeamName,
        );

      default:
        return InteractiveShotMapWidget(
          shots: _advancedStatsShowHome ? _homeShotsData : _awayShotsData,
          teamColor: _advancedStatsShowHome
              ? const Color(0xFF2196F3)
              : const Color(0xFFE53935),
          isDark: isDark,
        );
    }
  }

  Widget _buildEventsTab(ThemeData theme, bool isDark) {
    final events = _generateDetailedMockEvents();

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
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                return _buildDetailedEventCard(event, isDark, theme);
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

  Widget _buildDetailedEventCard(
      MatchEvent event, bool isDark, ThemeData theme) {
    final isHome = event.isHomeTeam;
    final teamColor =
        isHome ? const Color(0xFF2196F3) : const Color(0xFFE53935);

    return GestureDetector(
      onTap: () {
        _haptic.lightImpact();
        if (event.type == 'substitution') {
          _showSubstitutionDialog(event, isHome, teamColor);
        } else {
          if (widget.match.status == 'live') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerMatchStatsScreen(
                  playerName: event.playerName,
                  playerNumber: event.minute,
                  teamName: isHome
                      ? widget.match.homeTeamName
                      : widget.match.awayTeamName,
                  teamColor: teamColor,
                  match: widget.match,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlayerFinishedMatchScreen(
                  playerName: event.playerName,
                  playerNumber: event.minute,
                  teamName: isHome
                      ? widget.match.homeTeamName
                      : widget.match.awayTeamName,
                  teamColor: teamColor,
                  match: widget.match,
                ),
              ),
            );
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: teamColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: teamColor.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: teamColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${event.minute}'",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildEventIcon(event.type, teamColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getEventTitle(event),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (event.playerPhoto != null)
                              ClipOval(
                                child: Image.network(
                                  event.playerPhoto!,
                                  width: 40,
                                  height: 40,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: teamColor.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.person, color: teamColor),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: teamColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.person,
                                    color: teamColor, size: 24),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.playerName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (event.detail != null)
                                    Text(
                                      event.detail!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  if (event.subDetail != null)
                                    Text(
                                      event.subDetail!,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
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
      ),
    );
  }

  String _getEventTitle(MatchEvent event) {
    switch (event.type) {
      case 'goal':
        return 'GOL';
      case 'yellowCard':
        return 'CARTELLINO GIALLO';
      case 'redCard':
        return 'CARTELLINO ROSSO';
      case 'substitution':
        return 'SOSTITUZIONE';
      default:
        return 'EVENTO';
    }
  }

  void _showSubstitutionDialog(MatchEvent event, bool isHome, Color teamColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: teamColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.swap_horiz,
                      color: teamColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sostituzione',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${event.minute}' minuto",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Scegli quale giocatore visualizzare:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              _buildSubstitutionPlayerCard(
                icon: Icons.arrow_upward,
                iconColor: Colors.red,
                label: 'Giocatore uscente',
                playerName: event.playerName,
                teamName: isHome
                    ? widget.match.homeTeamName
                    : widget.match.awayTeamName,
                teamColor: teamColor,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  if (widget.match.status == 'live') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerMatchStatsScreen(
                          playerName: event.playerName,
                          playerNumber: event.minute,
                          teamName: isHome
                              ? widget.match.homeTeamName
                              : widget.match.awayTeamName,
                          teamColor: teamColor,
                          match: widget.match,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerFinishedMatchScreen(
                          playerName: event.playerName,
                          playerNumber: event.minute,
                          teamName: isHome
                              ? widget.match.homeTeamName
                              : widget.match.awayTeamName,
                          teamColor: teamColor,
                          match: widget.match,
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildSubstitutionPlayerCard(
                icon: Icons.arrow_downward,
                iconColor: Colors.green,
                label: 'Giocatore entrante',
                playerName: event.detail ?? 'Sostituto',
                teamName: isHome
                    ? widget.match.homeTeamName
                    : widget.match.awayTeamName,
                teamColor: teamColor,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  if (widget.match.status == 'live') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerMatchStatsScreen(
                          playerName: event.detail ?? 'Sostituto',
                          playerNumber: event.minute,
                          teamName: isHome
                              ? widget.match.homeTeamName
                              : widget.match.awayTeamName,
                          teamColor: teamColor,
                          match: widget.match,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerFinishedMatchScreen(
                          playerName: event.detail ?? 'Sostituto',
                          playerNumber: event.minute,
                          teamName: isHome
                              ? widget.match.homeTeamName
                              : widget.match.awayTeamName,
                          teamColor: teamColor,
                          match: widget.match,
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubstitutionPlayerCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String playerName,
    required String teamName,
    required Color teamColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: teamColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      playerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      teamName,
                      style: TextStyle(
                        fontSize: 12,
                        color: teamColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
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
    );
  }

  Widget _buildEventIcon(String type, Color color) {
    IconData icon;
    switch (type) {
      case 'goal':
        icon = Icons.sports_soccer;
        break;
      case 'yellowCard':
        icon = Icons.rectangle;
        color = Colors.yellow[700]!;
        break;
      case 'redCard':
        icon = Icons.rectangle;
        color = Colors.red;
        break;
      case 'substitution':
        icon = Icons.swap_horiz;
        break;
      default:
        icon = Icons.circle;
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  void _showMatchNotificationDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.notifications, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            const Text('Notifiche Partita'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMatchNotificationOption('Inizio partita', true, isDark),
              _buildMatchNotificationOption('Goal', true, isDark),
              _buildMatchNotificationOption('Cartellini gialli', false, isDark),
              _buildMatchNotificationOption('Cartellini rossi', true, isDark),
              _buildMatchNotificationOption('Corner', false, isDark),
              _buildMatchNotificationOption('Tiri in porta', false, isDark),
              _buildMatchNotificationOption('Falli', false, isDark),
              _buildMatchNotificationOption('Fuorigioco', false, isDark),
              _buildMatchNotificationOption('Fine primo tempo', false, isDark),
              _buildMatchNotificationOption('Fine partita', false, isDark),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _matchNotificationsEnabled = true);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifiche attivate per questa partita'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchNotificationOption(
      String label, bool enabled, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (value) {},
            activeColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildLineupsTab(ThemeData theme, bool isDark) {
    return Container(
      color: isDark ? Colors.grey[900] : Colors.grey[50],
      child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _haptic.lightImpact();
                        setState(() => _showHomeLineup = true);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: _showHomeLineup
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF2196F3),
                                    Color(0xFF1976D2)
                                  ],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.match.homeTeamLogo != null)
                              CachedNetworkImage(
                                imageUrl: widget.match.homeTeamLogo!,
                                width: 24,
                                height: 24,
                                errorWidget: (context, url, error) => Icon(
                                  Icons.shield,
                                  size: 24,
                                  color: _showHomeLineup
                                      ? Colors.white
                                      : Colors.grey,
                                ),
                              )
                            else
                              Icon(
                                Icons.shield,
                                size: 24,
                                color: _showHomeLineup
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.match.homeTeamName,
                                style: TextStyle(
                                  color: _showHomeLineup
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _haptic.lightImpact();
                        setState(() => _showHomeLineup = false);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: !_showHomeLineup
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFE53935),
                                    Color(0xFFC62828)
                                  ],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.match.awayTeamLogo != null)
                              CachedNetworkImage(
                                imageUrl: widget.match.awayTeamLogo!,
                                width: 24,
                                height: 24,
                                errorWidget: (context, url, error) => Icon(
                                  Icons.shield,
                                  size: 24,
                                  color: !_showHomeLineup
                                      ? Colors.white
                                      : Colors.grey,
                                ),
                              )
                            else
                              Icon(
                                Icons.shield,
                                size: 24,
                                color: !_showHomeLineup
                                    ? Colors.white
                                    : Colors.grey,
                              ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                widget.match.awayTeamName,
                                style: TextStyle(
                                  color: !_showHomeLineup
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white70
                                          : Colors.black87),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildGraphicalFormation(
              _showHomeLineup
                  ? widget.match.homeTeamName
                  : widget.match.awayTeamName,
              _showHomeLineup
                  ? widget.match.homeTeamLogo
                  : widget.match.awayTeamLogo,
              _generateMockLineup(_showHomeLineup),
              _showHomeLineup
                  ? const Color(0xFF2196F3)
                  : const Color(0xFFE53935),
              '4-3-3',
              isDark,
              _showHomeLineup,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGraphicalFormation(
    String teamName,
    String? teamLogo,
    List<LineupPlayer> players,
    Color teamColor,
    String formation,
    bool isDark,
    bool isHome,
  ) {
    final bench = _generateMockBench(isHome);
    final coach = 'Maurizio Sarri';
    final injuries = _generateMockInjuries(isHome);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [teamColor, teamColor.withOpacity(0.8)],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                if (teamLogo != null)
                  CachedNetworkImage(
                    imageUrl: teamLogo,
                    height: 32,
                    width: 32,
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.shield, color: Colors.white, size: 32),
                  )
                else
                  const Icon(Icons.shield, color: Colors.white, size: 32),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    formation,
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
          SizedBox(
            height: 500,
            child: Stack(
              children: [
                FormationFieldWidget(
                  isDark: isDark,
                  height: 500,
                ),
                ..._positionPlayersOnField(
                    players, teamColor, isDark, isHome, teamName),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.event_seat, color: teamColor, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Panchina',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: bench.map((player) {
                    return GestureDetector(
                      onTap: () {
                        _haptic.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerDetailScreen(
                              player: _createMockPlayerDetail(
                                player.name,
                                teamName,
                                teamColor,
                              ),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[700] : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: teamColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              player.number.toString(),
                              style: TextStyle(
                                color: teamColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              player.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: teamColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, color: teamColor, size: 24),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allenatore',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      coach,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (injuries.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medical_services,
                          color: Colors.orange[700], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Infortuni e qualifiche',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...injuries.map((injury) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            injury.status == 'doubt'
                                ? Icons.help_outline
                                : Icons.local_hospital,
                            color: injury.status == 'doubt'
                                ? Colors.orange
                                : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  injury.playerName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  injury.reason,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<Widget> _positionPlayersOnField(
    List<LineupPlayer> players,
    Color teamColor,
    bool isDark,
    bool isHome,
    String teamName,
  ) {
    final List<Widget> widgets = [];

    final positions = {
      'Portiere': [Offset(0.5, 0.88)],
      'Difensore': [
        Offset(0.25, 0.72),
        Offset(0.40, 0.72),
        Offset(0.60, 0.72),
        Offset(0.75, 0.72),
      ],
      'Centrocampista': [
        Offset(0.28, 0.50),
        Offset(0.5, 0.50),
        Offset(0.72, 0.50),
      ],
      'Attaccante': [
        Offset(0.28, 0.25),
        Offset(0.5, 0.25),
        Offset(0.72, 0.25),
      ],
    };

    final Map<String, int> positionIndex = {
      'Portiere': 0,
      'Difensore': 0,
      'Centrocampista': 0,
      'Attaccante': 0,
    };

    for (final player in players) {
      String posType = 'Centrocampista';
      if (player.position.contains('Portiere'))
        posType = 'Portiere';
      else if (player.position.contains('Difensore') ||
          player.position.contains('Terzino'))
        posType = 'Difensore';
      else if (player.position.contains('Centrocampista') ||
          player.position.contains('Mediano'))
        posType = 'Centrocampista';
      else if (player.position.contains('Attaccante') ||
          player.position.contains('Ala')) posType = 'Attaccante';

      final positionList = positions[posType] ?? [];
      final index = positionIndex[posType] ?? 0;

      if (index < positionList.length) {
        final offset = positionList[index];
        widgets.add(
          Positioned(
            left: offset.dx * (MediaQuery.of(context).size.width - 32),
            top: offset.dy * 500,
            child: Transform.translate(
              offset: const Offset(-25, -25),
              child: GestureDetector(
                onTap: () {
                  _haptic.lightImpact();
                  if (widget.match.status == 'live') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerMatchStatsScreen(
                          playerName: player.name,
                          playerNumber: player.number,
                          teamName: teamName,
                          teamColor: teamColor,
                          match: widget.match,
                        ),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerFinishedMatchScreen(
                          playerName: player.name,
                          playerNumber: player.number,
                          teamName: teamName,
                          teamColor: teamColor,
                          match: widget.match,
                        ),
                      ),
                    );
                  }
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [teamColor, teamColor.withOpacity(0.8)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: teamColor.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          player.number.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black87 : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        player.name.split(' ').last,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        positionIndex[posType] = index + 1;
      }
    }

    return widgets;
  }

  Widget _buildInfoTab(ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDark ? Colors.grey[900]! : Colors.grey[50]!,
            isDark ? Colors.grey[850]! : Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildModernInfoCard(
              'Informazioni Partita',
              Icons.info_outline,
              Colors.blue,
              [
                _buildModernInfoRow(
                    Icons.emoji_events, 'Competizione', 'Serie A', Colors.blue),
                _buildModernInfoRow(
                    Icons.stadium, 'Stadio', 'Stadio Olimpico', Colors.green),
                _buildModernInfoRow(Icons.calendar_today, 'Data',
                    '21 Gennaio 2026', Colors.orange),
                _buildModernInfoRow(
                    Icons.sports, 'Arbitro', 'Daniele Orsato', Colors.purple),
                _buildModernInfoRow(
                    Icons.people, 'Spettatori', '65.000', Colors.red),
              ],
              isDark,
            ),
            const SizedBox(height: 16),
            _buildModernInfoCard(
              'Ultimi Risultati',
              Icons.timeline,
              Colors.green,
              [
                _buildResultRow(
                    widget.match.homeTeamName, 'V-V-P-V-P', isDark, true),
                const SizedBox(height: 8),
                Divider(height: 1, color: Colors.grey.withOpacity(0.3)),
                const SizedBox(height: 8),
                _buildResultRow(
                    widget.match.awayTeamName, 'P-V-V-P-V', isDark, false),
              ],
              isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoCard(String title, IconData icon, Color accentColor,
      List<Widget> content, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.grey[850]! : Colors.white,
            isDark ? Colors.grey[800]! : Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accentColor, accentColor.withOpacity(0.8)],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: content,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoRow(
      IconData icon, String label, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(
      String teamName, String form, bool isDark, bool isHome) {
    final formList = form.split('-');
    final teamColor =
        isHome ? const Color(0xFF2196F3) : const Color(0xFFE53935);

    return Row(
      children: [
        Expanded(
          child: Text(
            teamName,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: teamColor,
            ),
          ),
        ),
        Row(
          children: formList.map((result) {
            Color color;
            if (result == 'V') {
              color = Colors.green;
            } else if (result == 'P') {
              color = Colors.red;
            } else {
              color = Colors.grey;
            }

            return Container(
              margin: const EdgeInsets.only(left: 4),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: Text(
                  result,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<LineupPlayer> _generateMockLineup(bool isHome) {
    return [
      LineupPlayer(number: 1, name: 'Provedel', position: 'Portiere'),
      LineupPlayer(number: 77, name: 'Marusic', position: 'Terzino Destro'),
      LineupPlayer(
          number: 13, name: 'Romagnoli', position: 'Difensore Centrale'),
      LineupPlayer(number: 4, name: 'Patric', position: 'Difensore Centrale'),
      LineupPlayer(
          number: 23, name: 'Pellegrini', position: 'Terzino Sinistro'),
      LineupPlayer(number: 6, name: 'Rovella', position: 'Centrocampista'),
      LineupPlayer(number: 8, name: 'Guendouzi', position: 'Centrocampista'),
      LineupPlayer(
          number: 10, name: 'Luis Alberto', position: 'Centrocampista'),
      LineupPlayer(number: 20, name: 'Zaccagni', position: 'Ala Sinistra'),
      LineupPlayer(number: 9, name: 'Immobile', position: 'Attaccante'),
      LineupPlayer(number: 7, name: 'Felipe Anderson', position: 'Ala Destra'),
    ];
  }

  List<LineupPlayer> _generateMockBench(bool isHome) {
    return [
      LineupPlayer(
          number: 94, name: 'Mandas', position: 'Portiere', isPlaying: false),
      LineupPlayer(
          number: 3, name: 'Lazzari', position: 'Difensore', isPlaying: false),
      LineupPlayer(
          number: 34, name: 'Hysaj', position: 'Difensore', isPlaying: false),
      LineupPlayer(
          number: 5,
          name: 'Vecino',
          position: 'Centrocampista',
          isPlaying: false),
      LineupPlayer(
          number: 18,
          name: 'Cataldi',
          position: 'Centrocampista',
          isPlaying: false),
      LineupPlayer(
          number: 11, name: 'Pedro', position: 'Attaccante', isPlaying: false),
      LineupPlayer(
          number: 19,
          name: 'Castellanos',
          position: 'Attaccante',
          isPlaying: false),
    ];
  }

  List<InjuredPlayer> _generateMockInjuries(bool isHome) {
    return [
      InjuredPlayer(
        playerName: 'Piero Hincapié',
        reason: 'In dubbio',
        status: 'doubt',
      ),
      InjuredPlayer(
        playerName: 'Max Dowman',
        reason: 'Fuori',
        status: 'injured',
      ),
      InjuredPlayer(
        playerName: 'Riccardo Calafiori',
        reason: 'In dubbio',
        status: 'doubt',
      ),
    ];
  }

  List<MatchEvent> _generateDetailedMockEvents() {
    return [
      MatchEvent(
        type: 'goal',
        minute: 12,
        playerName: 'Immobile',
        detail: 'Assist: Zaccagni',
        subDetail: 'Tiro di destro dall\'interno dell\'area',
        isHomeTeam: true,
        playerPhoto: null,
      ),
      MatchEvent(
        type: 'yellowCard',
        minute: 23,
        playerName: 'Pellegrini',
        detail: 'Fallo tattico',
        subDetail: 'Fermata una ripartenza avversaria',
        isHomeTeam: true,
        playerPhoto: null,
      ),
      MatchEvent(
        type: 'substitution',
        minute: 65,
        playerName: 'Luis Alberto',
        detail: 'Cataldi',
        subDetail: 'Cambio tattico a centrocampo',
        isHomeTeam: true,
        playerPhoto: null,
      ),
      MatchEvent(
        type: 'goal',
        minute: 78,
        playerName: 'Felipe Anderson',
        detail: 'Assist: Guendouzi',
        subDetail: 'Tiro di sinistro dal limite dell\'area',
        isHomeTeam: true,
        playerPhoto: null,
      ),
      MatchEvent(
        type: 'substitution',
        minute: 82,
        playerName: 'Pedro',
        detail: 'Isaksen',
        subDetail: 'Gestione del risultato',
        isHomeTeam: false,
        playerPhoto: null,
      ),
      MatchEvent(
        type: 'yellowCard',
        minute: 88,
        playerName: 'Guendouzi',
        detail: 'Proteste',
        subDetail: 'Ammonito per proteste verso l\'arbitro',
        isHomeTeam: true,
        playerPhoto: null,
      ),
    ];
  }
}

// CLASSI DI SUPPORTO
class LineupPlayer {
  final int number;
  final String name;
  final String position;
  final bool isPlaying;

  LineupPlayer({
    required this.number,
    required this.name,
    required this.position,
    this.isPlaying = true,
  });
}

class MatchEvent {
  final String type;
  final int minute;
  final String playerName;
  final String? detail;
  final String? subDetail;
  final bool isHomeTeam;
  final String? playerPhoto;

  MatchEvent({
    required this.type,
    required this.minute,
    required this.playerName,
    this.detail,
    this.subDetail,
    required this.isHomeTeam,
    this.playerPhoto,
  });
}

class InjuredPlayer {
  final String playerName;
  final String reason;
  final String status;

  InjuredPlayer({
    required this.playerName,
    required this.reason,
    required this.status,
  });
}

// PAINTERS (questi rimangono invariati)
class ShotMapPainter extends CustomPainter {
  final bool isHome;
  final bool isDark;

  ShotMapPainter({required this.isHome, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final fieldPaint = Paint()
      ..color = isDark ? Colors.green[900]! : Colors.green[600]!
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fieldPaint);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      linePaint,
    );

    final random = math.Random(42);
    final shotColor = isHome ? Colors.blue : Colors.red;

    for (int i = 0; i < 15; i++) {
      final x = size.width * (0.2 + random.nextDouble() * 0.6);
      final y = isHome
          ? size.height * (0.1 + random.nextDouble() * 0.4)
          : size.height * (0.5 + random.nextDouble() * 0.4);

      final isGoal = random.nextBool() && random.nextDouble() > 0.6;

      canvas.drawCircle(
        Offset(x, y),
        isGoal ? 8 : 6,
        Paint()
          ..color = isGoal ? shotColor : shotColor.withOpacity(0.4)
          ..style = PaintingStyle.fill,
      );

      if (isGoal) {
        canvas.drawCircle(
          Offset(x, y),
          10,
          Paint()
            ..color = shotColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PassNetworkPainter extends CustomPainter {
  final bool isHome;
  final bool isDark;

  PassNetworkPainter({required this.isHome, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final fieldPaint = Paint()
      ..color = isDark ? Colors.green[900]! : Colors.green[600]!
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fieldPaint);

    final playerColor = isHome ? Colors.blue : Colors.red;
    final passColor = playerColor.withOpacity(0.3);

    final positions = [
      Offset(size.width * 0.5, size.height * 0.85),
      Offset(size.width * 0.3, size.height * 0.65),
      Offset(size.width * 0.5, size.height * 0.65),
      Offset(size.width * 0.7, size.height * 0.65),
      Offset(size.width * 0.3, size.height * 0.4),
      Offset(size.width * 0.5, size.height * 0.4),
      Offset(size.width * 0.7, size.height * 0.4),
      Offset(size.width * 0.3, size.height * 0.2),
      Offset(size.width * 0.5, size.height * 0.2),
      Offset(size.width * 0.7, size.height * 0.2),
    ];

    final passPaint = Paint()
      ..color = passColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < positions.length - 1; i++) {
      for (int j = i + 1; j < positions.length; j++) {
        if (math.Random(i * j).nextDouble() > 0.6) {
          canvas.drawLine(positions[i], positions[j], passPaint);
        }
      }
    }

    for (final pos in positions) {
      canvas.drawCircle(
        pos,
        8,
        Paint()
          ..color = playerColor
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PressureMapPainter extends CustomPainter {
  final bool isHome;
  final bool isDark;

  PressureMapPainter({required this.isHome, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final fieldPaint = Paint()
      ..color = isDark ? Colors.green[900]! : Colors.green[600]!
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fieldPaint);

    final random = math.Random(42);
    final pressureColor = isHome ? Colors.blue : Colors.red;

    for (int i = 0; i < 20; i++) {
      final x = size.width * (0.1 + random.nextDouble() * 0.8);
      final y = isHome
          ? size.height * (0.1 + random.nextDouble() * 0.5)
          : size.height * (0.4 + random.nextDouble() * 0.5);

      final intensity = random.nextDouble();

      canvas.drawCircle(
        Offset(x, y),
        15 + intensity * 20,
        Paint()
          ..color = pressureColor.withOpacity(0.2 + intensity * 0.3)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HeatmapPainter extends CustomPainter {
  final bool isHome;
  final bool isDark;

  HeatmapPainter({required this.isHome, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final fieldPaint = Paint()
      ..color = isDark ? Colors.green[900]! : Colors.green[600]!
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fieldPaint);

    final random = math.Random(42);
    final colors = [
      Colors.blue.withOpacity(0.3),
      Colors.yellow.withOpacity(0.3),
      Colors.red.withOpacity(0.3),
    ];

    for (int i = 0; i < 30; i++) {
      final x = size.width * (0.1 + random.nextDouble() * 0.8);
      final y = isHome
          ? size.height * (0.1 + random.nextDouble() * 0.6)
          : size.height * (0.3 + random.nextDouble() * 0.6);

      final colorIndex = (random.nextDouble() * 3).floor();

      canvas.drawCircle(
        Offset(x, y),
        20 + random.nextDouble() * 30,
        Paint()
          ..color = colors[colorIndex]
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TouchMapPainter extends CustomPainter {
  final bool isHome;
  final bool isDark;

  TouchMapPainter({required this.isHome, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final fieldPaint = Paint()
      ..color = isDark ? Colors.green[900]! : Colors.green[600]!
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), fieldPaint);

    final random = math.Random(42);
    final touchColor = isHome ? Colors.blue : Colors.red;

    for (int i = 0; i < 40; i++) {
      final x = size.width * (0.1 + random.nextDouble() * 0.8);
      final y = size.height * (0.1 + random.nextDouble() * 0.8);

      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()
          ..color = touchColor.withOpacity(0.4)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
