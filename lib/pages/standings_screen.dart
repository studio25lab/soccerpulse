// lib/pages/standings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/team_standing.dart';
import '../api/api_service.dart';
import '../services/haptic_service.dart';
import '../services/favorites_service.dart';
import '../generated/l10n.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/loading_state_widget.dart';
import 'team_detail_screen.dart';
import 'settings_screen.dart';

class StandingsScreen extends StatefulWidget {
  const StandingsScreen({Key? key}) : super(key: key);

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final HapticService _haptic = HapticService();
  final FavoritesService _favoritesService = FavoritesService();

  late TabController _tabController;

  int _selectedLeagueId = 135;
  final Map<int, String> _leagues = {
    135: 'Serie A',
    39: 'Premier League',
    140: 'La Liga',
    78: 'Bundesliga',
    61: 'Ligue 1',
    94: 'Primeira Liga',
    88: 'Eredivisie',
  };

  Future<List<TeamStanding>>? _standingsFuture;
  bool _isCompactView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _leagues.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadStandings();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;

    _haptic.lightImpact();
    setState(() {
      _selectedLeagueId = _leagues.keys.toList()[_tabController.index];
    });
    _loadStandings();
  }

  void _loadStandings() {
    setState(() {
      _standingsFuture = _apiService.fetchStandings(_selectedLeagueId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final S s = S.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text(s.standings),
        backgroundColor: isDark ? Colors.grey[900] : theme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isCompactView ? Icons.expand : Icons.compress),
            onPressed: () {
              _haptic.lightImpact();
              setState(() {
                _isCompactView = !_isCompactView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _haptic.lightImpact();
              _loadStandings();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _haptic.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildLeagueTabs(theme, isDark),
        ),
      ),
      body: FutureBuilder<List<TeamStanding>>(
        future: _standingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingStateWidget(
                message: s.errorLoadingStandings,
                style: LoadingStyle.pulse,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('${s.errorLoading}: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadStandings,
                    child: Text(s.retry),
                  ),
                ],
              ),
            );
          }

          final standings = snapshot.data ?? [];

          if (standings.isEmpty) {
            return Center(
              child: Text(s.noDataAvailable),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _loadStandings();
              await _standingsFuture;
            },
            child: _isCompactView
                ? _buildCompactView(standings, theme, isDark, s)
                : _buildDetailedView(standings, theme, isDark, s),
          );
        },
      ),
    );
  }

  Widget _buildLeagueTabs(ThemeData theme, bool isDark) {
    return Container(
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
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: theme.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: theme.primaryColor,
        indicatorWeight: 3,
        tabs: _leagues.entries.map((entry) {
          return Tab(
            text: entry.value,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetailedView(
    List<TeamStanding> standings,
    ThemeData theme,
    bool isDark,
    S s,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTableHeader(theme, isDark, s),
          ...standings.map((team) => _buildTeamRow(team, theme, isDark, s)),
          const SizedBox(height: 16),
          _buildLegend(theme, isDark, s),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCompactView(
    List<TeamStanding> standings,
    ThemeData theme,
    bool isDark,
    S s,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: standings.length,
      itemBuilder: (context, index) {
        final team = standings[index];
        return _buildCompactCard(team, index, theme, isDark, s)
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 50))
            .slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildCompactCard(
    TeamStanding team,
    int index,
    ThemeData theme,
    bool isDark,
    S s,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: GlassmorphicCard(
        child: InkWell(
          onTap: () {
            _haptic.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TeamDetailScreen(
                  teamStanding: team,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _getPositionColor(team.position),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${team.position}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (team.teamLogo != null)
                  CachedNetworkImage(
                    imageUrl: team.teamLogo!,
                    width: 36,
                    height: 36,
                  )
                else
                  const Icon(Icons.sports_soccer, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.teamName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${s.played}${team.played} ${s.won}${team.wins} ${s.draw}${team.draws} ${s.lost}${team.losses}',
                        style: TextStyle(
                          fontSize: 11,
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
                      '${team.points}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    Text(
                      s.points.toLowerCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _favoritesService.isTeamFavorite(team.teamId)
                        ? Icons.star
                        : Icons.star_border,
                    color: _favoritesService.isTeamFavorite(team.teamId)
                        ? Colors.amber
                        : Colors.grey,
                    size: 20,
                  ),
                  onPressed: () {
                    _haptic.lightImpact();
                    _favoritesService.toggleTeamFavorite(team.teamId);
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeader(ThemeData theme, bool isDark, S s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
      ),
      child: Row(
        children: [
          _buildStatCell('#', 25, isHeader: true),
          const SizedBox(width: 40),
          Expanded(
            child: Text(
              s.team,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          _buildStatCell(s.played, 35, isHeader: true),
          _buildStatCell(s.won, 35, isHeader: true),
          _buildStatCell(s.draw, 35, isHeader: true),
          _buildStatCell(s.lost, 35, isHeader: true),
          _buildStatCell(s.goalDifference, 40, isHeader: true),
          _buildStatCell(s.points, 35, isHeader: true),
        ],
      ),
    );
  }

  Widget _buildTeamRow(
    TeamStanding team,
    ThemeData theme,
    bool isDark,
    S s,
  ) {
    return InkWell(
      onTap: () {
        _haptic.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TeamDetailScreen(
              teamStanding: team,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          border: Border(
            left: BorderSide(
              width: 4,
              color: _getPositionColor(team.position),
            ),
            bottom: BorderSide(
              width: 0.5,
              color: Colors.grey[300]!,
            ),
          ),
        ),
        child: Row(
          children: [
            _buildStatCell(
              '${team.position}',
              25,
              color: _getPositionColor(team.position),
            ),
            const SizedBox(width: 8),
            if (team.teamLogo != null)
              CachedNetworkImage(
                imageUrl: team.teamLogo!,
                width: 32,
                height: 32,
              )
            else
              const Icon(Icons.sports_soccer, size: 32),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      team.teamName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (_favoritesService.isTeamFavorite(team.teamId))
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                ],
              ),
            ),
            _buildStatCell('${team.played}', 35),
            _buildStatCell('${team.wins}', 35),
            _buildStatCell('${team.draws}', 35),
            _buildStatCell('${team.losses}', 35),
            _buildStatCell(
              '${team.goalsDiff > 0 ? '+' : ''}${team.goalsDiff}',
              40,
              color: team.goalsDiff > 0
                  ? Colors.green
                  : team.goalsDiff < 0
                      ? Colors.red
                      : null,
            ),
            _buildStatCell(
              '${team.points}',
              35,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCell(
    String text,
    double width, {
    bool isHeader = false,
    Color? color,
    FontWeight? fontWeight,
  }) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: isHeader ? 12 : 13,
            fontWeight:
                fontWeight ?? (isHeader ? FontWeight.bold : FontWeight.normal),
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(ThemeData theme, bool isDark, S s) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.legend,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem(s.champions, Colors.green),
              _buildLegendItem(s.europa, Colors.blue),
              _buildLegendItem(s.conference, Colors.lightBlue),
              _buildLegendItem(s.relegation, Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Color _getPositionColor(int position) {
    if (position <= 4) return Colors.green;
    if (position == 5) return Colors.blue;
    if (position == 6) return Colors.lightBlue;
    if (position >= 18) return Colors.red;
    return Colors.grey;
  }
}
