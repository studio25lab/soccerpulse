// lib/pages/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../generated/l10n.dart';
import '../models/soccer_match.dart';
import '../models/team_standing.dart';
import '../models/player.dart';
import '../api/api_service.dart';
import '../services/theme_service.dart';
import '../services/haptic_service.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/live_score_widget.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/loading_state_widget.dart';
import 'match_detail_screen.dart';
import 'team_detail_screen.dart';
import 'dart:async';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  final HapticService _haptic = HapticService();

  // State variables
  int _selectedLeagueId = 135; // Serie A default
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  // Data
  List<SoccerMatch> _todayMatches = [];
  List<SoccerMatch> _liveMatches = [];
  List<TeamStanding> _standings = [];
  List<Player> _topScorers = [];
  SoccerMatch? _nextMatch;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadDashboardData();
    _startRefreshTimer();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeController.forward();
    _slideController.forward();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_liveMatches.isNotEmpty && mounted) {
        _refreshLiveMatches();
      }
    });
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _loadTodayMatches(),
        _loadStandings(),
        _loadTopScorers(),
      ]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Errore nel caricamento dei dati';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTodayMatches() async {
    try {
      final matches = await _apiService.fetchMatchesByDate(
        DateTime.now(),
        leagueId: _selectedLeagueId,
      );

      if (mounted) {
        setState(() {
          _todayMatches = matches;
          _liveMatches = matches.where((m) => m.isLive).toList();
          _updateNextMatch();
        });
      }
    } catch (e) {
      debugPrint('Error loading matches: $e');
    }
  }

  Future<void> _loadStandings() async {
    try {
      final standings = await _apiService.fetchStandings(_selectedLeagueId);
      if (mounted) {
        setState(() {
          _standings = standings.take(6).toList(); // Top 6 teams
        });
      }
    } catch (e) {
      debugPrint('Error loading standings: $e');
    }
  }

  Future<void> _loadTopScorers() async {
    try {
      final scorers = await _apiService.fetchTopScorers(_selectedLeagueId);
      if (mounted) {
        setState(() {
          _topScorers = scorers.take(5).toList(); // Top 5 scorers
        });
      }
    } catch (e) {
      debugPrint('Error loading top scorers: $e');
    }
  }

  Future<void> _refreshLiveMatches() async {
    try {
      final matches = await _apiService.fetchMatchesByDate(
        DateTime.now(),
        leagueId: _selectedLeagueId,
        forceRefresh: true,
      );

      if (mounted) {
        setState(() {
          _todayMatches = matches;
          _liveMatches = matches.where((m) => m.isLive).toList();
        });
      }
    } catch (e) {
      debugPrint('Error refreshing live matches: $e');
    }
  }

  void _updateNextMatch() {
    final now = DateTime.now();
    final upcomingMatches = _todayMatches
        .where((m) => m.isScheduled && m.date.isAfter(now))
        .toList();

    if (upcomingMatches.isNotEmpty) {
      upcomingMatches.sort((a, b) => a.date.compareTo(b.date));
      _nextMatch = upcomingMatches.first;
    } else {
      _nextMatch = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final isDark = Provider.of<ThemeService>(context).isDarkMode;
    final s = S.of(context)!; // Force unwrap

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(theme, isDark, s),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: LoadingStateWidget(
                    message: 'Caricamento dashboard...',
                    style: LoadingStyle.pulse,
                  ),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: _buildErrorState(s),
              )
            else
              SliverList(
                delegate: SliverChildListDelegate([
                  if (_liveMatches.isNotEmpty) _buildLiveMatchesSection(s),
                  if (_nextMatch != null) _buildNextMatchSection(s),
                  _buildQuickStatsSection(s, theme, isDark),
                  _buildStandingsSection(s),
                  _buildTopScorersSection(s),
                  if (_todayMatches.isNotEmpty) _buildTodayMatchesSection(s),
                  const SizedBox(height: 100), // Bottom padding
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, bool isDark, S s) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? Colors.grey[900] : theme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          s.dashboard,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [Colors.grey[900]!, Colors.grey[800]!]
                  : [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                bottom: -50,
                child: Icon(
                  Icons.sports_soccer,
                  size: 200,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Positioned(
                left: 20,
                bottom: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getLeagueName(_selectedLeagueId),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (_liveMatches.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${_liveMatches.length} LIVE',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
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
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {
            _haptic.lightImpact();
            // TODO: Implement notifications
          },
        ),
        PopupMenuButton<int>(
          icon: const Icon(Icons.filter_list),
          onSelected: (leagueId) {
            _haptic.lightImpact();
            setState(() => _selectedLeagueId = leagueId);
            _loadDashboardData();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 135, child: Text('Serie A 🇮🇹')),
            const PopupMenuItem(
                value: 39, child: Text('Premier League 🏴󐁧󐁢󐁥󐁮󐁧󐁿')),
            const PopupMenuItem(value: 140, child: Text('La Liga 🇪🇸')),
            const PopupMenuItem(value: 78, child: Text('Bundesliga 🇩🇪')),
            const PopupMenuItem(value: 61, child: Text('Ligue 1 🇫🇷')),
          ],
        ),
      ],
    );
  }

  Widget _buildLiveMatchesSection(S s) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  s.liveMatches,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _liveMatches.length,
                itemBuilder: (context, index) {
                  final match = _liveMatches[index];
                  return Container(
                    width: 300,
                    margin: const EdgeInsets.only(right: 16),
                    child: LiveScoreWidget(
                      match: match,
                      onTap: () => _navigateToMatch(match),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: index * 100))
                      .slideX(begin: 0.2, end: 0);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextMatchSection(S s) {
    if (_nextMatch == null) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GlassmorphicCard(
          child: InkWell(
            onTap: () => _navigateToMatch(_nextMatch!),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        s.nextMatch,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Home team - ✅ CORRETTO
                      Expanded(
                        child: Row(
                          children: [
                            if (_nextMatch!.homeTeamLogo != null)
                              CachedNetworkImage(
                                imageUrl: _nextMatch!.homeTeamLogo!,
                                width: 30,
                                height: 30,
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.sports_soccer),
                              ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _nextMatch!.homeTeamName, // ✅ homeTeamName
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // VS
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: const Text(
                          'VS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      // Away team - ✅ CORRETTO
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                _nextMatch!.awayTeamName, // ✅ awayTeamName
                                style: const TextStyle(fontSize: 14),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_nextMatch!.awayTeamLogo != null)
                              CachedNetworkImage(
                                imageUrl: _nextMatch!.awayTeamLogo!,
                                width: 30,
                                height: 30,
                                placeholder: (context, url) =>
                                    const CircularProgressIndicator(),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.sports_soccer),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: CountdownTimer(
                      targetTime: _nextMatch!.date,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ).animate().shimmer(duration: 2.seconds, delay: 1.seconds),
    );
  }

  Widget _buildQuickStatsSection(S s, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.quickStats,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.sports_soccer,
                  title: s.todayMatches,
                  value: _todayMatches.length.toString(),
                  color: Colors.blue,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.live_tv,
                  title: s.live,
                  value: _liveMatches.length.toString(),
                  color: Colors.red,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.check_circle,
                  title: s.finished,
                  value: _todayMatches
                      .where((m) => m.isFinished)
                      .length
                      .toString(),
                  color: Colors.green,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.schedule,
                  title: s.scheduled,
                  value: _todayMatches
                      .where((m) => m.isScheduled)
                      .length
                      .toString(),
                  color: Colors.orange,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandingsSection(S s) {
    if (_standings.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.standings,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  _haptic.lightImpact();
                  // Navigate to full standings
                },
                child: Text(s.viewAll),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_standings.length, (index) {
            final team = _standings[index];
            return _buildStandingRow(team, index + 1)
                .animate()
                .fadeIn(delay: Duration(milliseconds: index * 50))
                .slideX(begin: 0.1, end: 0);
          }),
        ],
      ),
    );
  }

  Widget _buildStandingRow(TeamStanding team, int position) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _navigateToTeam(team),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: position <= 4
                ? Colors.green.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: position <= 4
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                position.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: position <= 4 ? Colors.green : Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (team.teamLogo != null)
              CachedNetworkImage(
                imageUrl: team.teamLogo!,
                width: 24,
                height: 24,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.sports_soccer, size: 24),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                team.teamName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Row(
              children: [
                _buildStatBadge('P', team.points.toString(), Colors.blue),
                const SizedBox(width: 8),
                _buildStatBadge('W', team.wins.toString(), Colors.green),
                const SizedBox(width: 8),
                _buildStatBadge('D', team.draws.toString(), Colors.orange),
                const SizedBox(width: 8),
                _buildStatBadge('L', team.losses.toString(), Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTopScorersSection(S s) {
    if (_topScorers.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.topScorers,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  _haptic.lightImpact();
                  // Navigate to full scorers list
                },
                child: Text(s.viewAll),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(_topScorers.length, (index) {
            final player = _topScorers[index];
            return _buildScorerRow(player, index + 1)
                .animate()
                .fadeIn(delay: Duration(milliseconds: index * 50))
                .slideX(begin: 0.1, end: 0);
          }),
        ],
      ),
    );
  }

  Widget _buildScorerRow(Player player, int position) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: position == 1
                  ? Colors.amber.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              position.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: position == 1 ? Colors.amber : Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (player.photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: CachedNetworkImage(
                imageUrl: player.photo!,
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const CircularProgressIndicator(),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.person, size: 30),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  player.teamName ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.sports_soccer, size: 16),
                const SizedBox(width: 4),
                Text(
                  player.goals.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayMatchesSection(S s) {
    final scheduledMatches =
        _todayMatches.where((m) => !m.isLive && !m.isFinished).toList();

    if (scheduledMatches.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.todaysMatches,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...scheduledMatches.map((match) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassmorphicCard(
                child: InkWell(
                  onTap: () => _navigateToMatch(match),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        // Home team - ✅ CORRETTO
                        Expanded(
                          child: Row(
                            children: [
                              if (match.homeTeamLogo != null)
                                CachedNetworkImage(
                                  imageUrl: match.homeTeamLogo!,
                                  width: 30,
                                  height: 30,
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  match.homeTeamName, // ✅ homeTeamName
                                  style: const TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Time
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            match.time,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        // Away team - ✅ CORRETTO
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  match.awayTeamName, // ✅ awayTeamName
                                  style: const TextStyle(fontSize: 14),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (match.awayTeamLogo != null)
                                CachedNetworkImage(
                                  imageUrl: match.awayTeamLogo!,
                                  width: 30,
                                  height: 30,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildErrorState(S s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'Errore sconosciuto',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _haptic.lightImpact();
              _loadDashboardData();
            },
            icon: const Icon(Icons.refresh),
            label: Text(s.retry),
          ),
        ],
      ),
    );
  }

  String _getLeagueName(int leagueId) {
    switch (leagueId) {
      case 135:
        return 'Serie A';
      case 39:
        return 'Premier League';
      case 140:
        return 'La Liga';
      case 78:
        return 'Bundesliga';
      case 61:
        return 'Ligue 1';
      default:
        return 'League';
    }
  }

  void _navigateToMatch(SoccerMatch match) {
    _haptic.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchDetailScreen(match: match),
      ),
    );
  }

  void _navigateToTeam(TeamStanding team) {
    _haptic.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TeamDetailScreen(
          teamStanding: team,
          leagueId: _selectedLeagueId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
