import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/player_detail.dart';
import '../models/soccer_match.dart';
import '../services/haptic_service.dart';
// ⭐ NUOVI IMPORT PER MatchDataService
import '../services/match_data_service.dart';
import '../models/match_data.dart';
import 'player_detail_screen.dart';
import '../widgets/player_performance_widgets.dart';
import 'package:soccerpulse/pages/main_navigation.dart';

class PlayerMatchStatsScreen extends StatefulWidget {
  final String playerName;
  final int playerNumber;
  final String teamName;
  final Color teamColor;
  final SoccerMatch match;

  const PlayerMatchStatsScreen({
    Key? key,
    required this.playerName,
    required this.playerNumber,
    required this.teamName,
    required this.teamColor,
    required this.match,
  }) : super(key: key);

  @override
  State<PlayerMatchStatsScreen> createState() => _PlayerMatchStatsScreenState();
}

class _PlayerMatchStatsScreenState extends State<PlayerMatchStatsScreen>
    with SingleTickerProviderStateMixin {
  final HapticService _haptic = HapticService();
  late TabController _tabController;
  String _selectedCategory = 'Pass';

  // ⭐ NUOVO: MatchDataService state
  final MatchDataService _matchDataService = MatchDataService();
  PlayerMatchStats? _playerStats;
  bool _isLoadingPlayerStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // ⭐ NUOVO: Carica dati da MatchDataService
    _loadPlayerData();
  }

  // ⭐ NUOVO: Carica dati giocatore da MatchDataService
  Future<void> _loadPlayerData() async {
    setState(() => _isLoadingPlayerStats = true);

    try {
      print(
          '🔄 Loading player stats for ${widget.playerName} from MatchDataService...');

      final matchData = await _matchDataService.loadMatchData(
        widget.match.id,
        forceRefresh: false,
      );

      final playerStats = matchData.getPlayerStats(widget.playerName);

      if (playerStats != null) {
        setState(() {
          _playerStats = playerStats;
          _isLoadingPlayerStats = false;
        });

        print(
            '✅ Player stats loaded: ${playerStats.goals} goals, ${playerStats.assists} assists, ${playerStats.rating} rating');
      } else {
        print('⚠️ No stats found for ${widget.playerName} in MatchData');
        setState(() => _isLoadingPlayerStats = false);
      }
    } catch (e) {
      print('⚠️ Error loading player stats from MatchDataService: $e');
      setState(() => _isLoadingPlayerStats = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(isDark),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildImpactSection(isDark),
                  const SizedBox(height: 16),
                  _buildStatsCards(isDark),
                  const SizedBox(height: 16),
                  _buildMatchStats(isDark),
                  const SizedBox(height: 16),
                  _buildStatisticsSection(isDark),
                  const SizedBox(height: 16),
                  _buildPassMapSection(isDark),
                  const SizedBox(height: 16),
                  _buildDetailedStats(isDark),
                  const SizedBox(height: 16),
                  RadarPerformanceWidget(
                    teamColor: widget.teamColor,
                    isDark: isDark,
                    playerName: widget.playerName,
                  ),
                  MatchTimelineWidget(
                    teamColor: widget.teamColor,
                    isDark: isDark,
                    playerName: widget.playerName,
                  ),
                  ColoredStatsBarWidget(
                    teamColor: widget.teamColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    // ⭐ USA RATING VERO
    final rating = _playerStats?.rating ?? 8.0;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: widget.teamColor),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {
                  _haptic.lightImpact();
                  _showNotificationDialog();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.teamColor.withOpacity(0.1),
                  border: Border.all(color: widget.teamColor, width: 2),
                ),
                child: Center(
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: widget.teamColor,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.playerName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.teamColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Valutazione Sofascore',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.star_border,
                  color: Colors.grey[400],
                  size: 32,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactSection(bool isDark) {
    // ⭐ CALCOLA VALORI IMPATTO DA DATI VERI
    final stats = _playerStats;
    final shotsImpact =
        stats != null ? (stats.shots.length / 10).clamp(0.0, 1.0) : 0.4;
    final passesImpact =
        stats != null ? (stats.accuratePasses / 100).clamp(0.0, 1.0) : 0.6;
    final dribblesImpact =
        stats != null ? (stats.successfulDribbles / 10).clamp(0.0, 1.0) : 0.5;
    final defenseImpact = stats != null
        ? ((stats.tackles + stats.interceptions) / 10).clamp(0.0, 1.0)
        : 0.2;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Impatto',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('-', style: TextStyle(fontSize: 18)),
              Text('${stats?.goals ?? 0}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('+', style: TextStyle(fontSize: 18)),
            ],
          ),
          SizedBox(height: 16),
          _buildStatBar(tr(context, 'Tiri'), shotsImpact, Colors.cyan),
          SizedBox(height: 12),
          _buildStatBar(tr(context, 'Passaggi'), passesImpact, Colors.orange),
          SizedBox(height: 12),
          _buildStatBar('Dribbling', dribblesImpact, Colors.green),
          SizedBox(height: 12),
          _buildStatBar(tr(context, 'Difesa'), defenseImpact, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildStatBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: value,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsCards(bool isDark) {
    // ⭐ USA MINUTI VERI
    final minutes = _playerStats?.minutesPlayed ?? 90;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              '${widget.match.homeTeamName} ${widget.match.homeScore ?? 0} - ${widget.match.awayScore ?? 0} ${widget.match.awayTeamName}',
              '20 gen',
              isDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              tr(context, 'Minuti giocati'),
              "$minutes'",
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchStats(bool isDark) {
    // ⭐ USA DATI VERI dove disponibili
    final stats = _playerStats;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: widget.teamColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bar_chart,
                  color: widget.teamColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                tr(context, 'Statistiche Partita'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMatchStatCard(
                  'xG',
                  '0.82', // Mock - non abbiamo xG in PlayerMatchStats
                  Icons.sports_soccer,
                  Colors.purple,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMatchStatCard(
                  'xA',
                  '0.14', // Mock - non abbiamo xA
                  Icons.assist_walker,
                  Colors.teal,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMatchStatCard(
                  tr(context, 'Fuorigioco'),
                  '1', // Mock - non abbiamo nel model
                  Icons.flag,
                  Colors.orange,
                  isDark,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildMatchStatCard(
                  tr(context, 'Falli Fatti'),
                  '${stats?.foulsCommitted ?? 2}',
                  Icons.warning,
                  Colors.red,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMatchStatCard(
                  tr(context, 'Falli Subiti'),
                  '${stats?.foulsDrawn ?? 3}',
                  Icons.person_off,
                  Colors.amber,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr(context, 'Statistiche'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.menu, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildCategoryChip('Shot', false, isDark),
                const SizedBox(width: 8),
                _buildCategoryChip('Pass', true, isDark),
                const SizedBox(width: 8),
                _buildCategoryChip('Drib', false, isDark),
                const SizedBox(width: 8),
                _buildCategoryChip('Def', false, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, bool isDark) {
    return GestureDetector(
      onTap: () {
        _haptic.lightImpact();
        setState(() => _selectedCategory = label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.black
              : (isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPassMapSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Tutti i passaggi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildPassTypeChip('Accurato', true, isDark),
                const SizedBox(width: 8),
                _buildPassTypeChip('Non accurato', false, isDark),
              ],
            ),
          ),
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                tr(context, 'Mappa Passaggi'),
                style: TextStyle(
                  color: Colors.green[900],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassTypeChip(String label, bool isSelected, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.black
            : (isDark ? Colors.grey[800] : Colors.grey[200]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        tr(context, label),
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : (isDark ? Colors.white70 : Colors.black87),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDetailedStats(bool isDark) {
    // ⭐ USA DATI VERI
    final stats = _playerStats;
    final passAccuracy = stats != null && stats.totalPasses > 0
        ? ((stats.accuratePasses / stats.totalPasses) * 100).toStringAsFixed(0)
        : '94';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Assists',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
              Text(
                '${stats?.assists ?? 0}',
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildStatRow(tr(context, 'Assist previsti (xA)'), '0.14', isDark), // Mock
          SizedBox(height: 12),
          _buildStatRow(tr(context, 'Passaggi chiave'), '${stats?.keyPasses ?? 3}', isDark,
              isInfo: true),
          const SizedBox(height: 12),
          _buildStatRow('Cross (prec.)', '0 (0)', isDark), // Mock - non abbiamo
          SizedBox(height: 12),
          _buildStatRow(
              tr(context, 'Passaggi precisi'),
              '${stats?.accuratePasses ?? 65}/${stats?.totalPasses ?? 69} ($passAccuracy%)',
              isDark),
          const SizedBox(height: 12),
          _buildStatRow('Passaggi nella metà avversari...', '46/50 (92%)',
              isDark), // Mock
          const SizedBox(height: 12),
          _buildStatRow('Passaggi nella propria metà (...', '19/19 (100%)',
              isDark), // Mock
          const SizedBox(height: 12),
          _buildStatRow('Lanci lunghi (prec.)', '4/4 (100%)', isDark), // Mock
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              onPressed: () {
                _haptic.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayerDetailScreen(
                      player: PlayerDetail(
                        number: widget.playerNumber,
                        name: widget.playerName,
                        position: 'Centrocampista',
                        photo: null,
                        teamName: widget.teamName,
                        teamColor: widget.teamColor,
                        matches: 25,
                        goals: stats?.goals ?? 5,
                        assists: stats?.assists ?? 3,
                        minutes: (stats?.minutesPlayed ?? 90) *
                            25, // Stima minuti stagione
                        shots: stats?.shots.length ?? 45,
                        shotsOnTarget: stats?.shotsOnTarget ?? 28,
                        dribbles: (stats?.successfulDribbles ?? 3) +
                            (stats?.failedDribbles ?? 2),
                        tackles: stats?.tackles ?? 45,
                        interceptions: stats?.interceptions ?? 30,
                        saves: 0,
                        duelsWon: stats?.duelsWon ?? 58,
                        yellowCards: 2,
                        redCards: 0,
                        fouls: stats?.foulsCommitted ?? 18,
                        recentRatings: [
                          7.2,
                          7.8,
                          6.9,
                          8.1,
                          stats?.rating ?? 7.5
                        ],
                        recentForm: ['W', 'W', 'D', 'W', 'L'],
                        bestMatch: 'Serie A - ${(stats?.rating ?? 7.5) + 0.5}',
                        averageRating: stats?.rating ?? 7.5,
                        decisiveGoals: stats?.goals ?? 2,
                        skills: {
                          'Velocità': 85.0,
                          'Tiro': 88.0,
                          'Passaggio': 82.0,
                          'Dribbling': 87.0,
                          'Difesa': 68.0,
                          'Fisico': 76.0,
                        },
                        passingAccuracy: stats != null && stats.totalPasses > 0
                            ? (stats.accuratePasses / stats.totalPasses) * 100
                            : 87.5,
                        shotsPerGoal: stats != null && stats.goals > 0
                            ? stats.shots.length / stats.goals
                            : 3.8,
                        minutesPerGoal: stats != null && stats.goals > 0
                            ? stats.minutesPlayed / stats.goals
                            : 175.0,
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
              icon: Icon(Icons.person),
              label: Text(tr(context, 'Vedi Scheda Completa Giocatore')),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.teamColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, bool isDark,
      {bool isInfo = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isInfo
                    ? Colors.blue
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            if (isInfo) const SizedBox(width: 4),
            if (isInfo)
              const Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.blue,
              ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showNotificationDialog() {
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
            Icon(Icons.notifications, color: widget.teamColor),
            SizedBox(width: 12),
            Text(tr(context, 'Notifiche Giocatore')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNotificationOption('Goal segnati', true, isDark),
              _buildNotificationOption(tr(context, 'Assist forniti'), true, isDark),
              _buildNotificationOption(tr(context, 'Cartellino giallo'), false, isDark),
              _buildNotificationOption(tr(context, 'Cartellino rosso'), false, isDark),
              _buildNotificationOption(tr(context, 'Tiri totali'), true, isDark),
              _buildNotificationOption(tr(context, 'Tiri in porta'), true, isDark),
              _buildNotificationOption(tr(context, 'Falli fatti'), false, isDark),
              _buildNotificationOption(tr(context, 'Falli subiti'), false, isDark),
              _buildNotificationOption(tr(context, 'Fuorigioco'), false, isDark),
              _buildNotificationOption(
                  'Voto fine primo tempo (Fantacalcio)', true, isDark),
              _buildNotificationOption(
                  'Voto finale partita (Fantacalcio)', true, isDark),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr(context, 'Annulla')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Notifiche attivate per ${widget.playerName}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.teamColor,
              foregroundColor: Colors.white,
            ),
            child: Text(tr(context, 'Salva')),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationOption(String label, bool enabled, bool isDark) {
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
            activeColor: widget.teamColor,
          ),
        ],
      ),
    );
  }
}
