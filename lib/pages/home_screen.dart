// lib/pages/home_screen.dart - FIXED

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/soccer_match.dart';
import '../api/api_service.dart';
import '../services/haptic_service.dart';
import '../generated/l10n.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/loading_state_widget.dart';
import 'match_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final HapticService _haptic = HapticService();

  late TabController _tabController;

  List<SoccerMatch> _liveMatches = [];
  List<SoccerMatch> _finishedMatches = [];
  List<SoccerMatch> _scheduledMatches = [];

  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadMockMatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadMockMatches() {
    setState(() {
      _liveMatches = [
        SoccerMatch(
          id: 1,
          homeTeamId: 487,
          awayTeamId: 489,
          homeTeamName: 'Lazio',
          awayTeamName: 'Milan',
          homeScore: 2,
          awayScore: 1,
          status: '1H',
          date: DateTime(2023, 5, 14),
          time: '20:45',
          venue: 'Stadio Olimpico',
          leagueId: 135,
          leagueName: 'Serie A',
          round: 'Giornata 35',
          elapsed: 45,
          homeTeamLogo: 'https://media.api-sports.io/football/teams/487.png',
          awayTeamLogo: 'https://media.api-sports.io/football/teams/489.png',
        ),
      ];

      _finishedMatches = [
        SoccerMatch(
          id: 2,
          homeTeamId: 502,
          awayTeamId: 499,
          homeTeamName: 'Fiorentina',
          awayTeamName: 'Atalanta',
          homeScore: 3,
          awayScore: 2,
          status: 'FT',
          date: DateTime(2023, 5, 14),
          time: '15:00',
          venue: 'Stadio Artemio Franchi',
          leagueId: 135,
          leagueName: 'Serie A',
          round: 'Giornata 35',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/502.png',
          awayTeamLogo: 'https://media.api-sports.io/football/teams/499.png',
        ),
        SoccerMatch(
          id: 3,
          homeTeamId: 492,
          awayTeamId: 496,
          homeTeamName: 'Napoli',
          awayTeamName: 'Juventus',
          homeScore: 1,
          awayScore: 1,
          status: 'FT',
          date: DateTime(2023, 5, 14),
          time: '18:00',
          venue: 'Stadio Diego Armando Maradona',
          leagueId: 135,
          leagueName: 'Serie A',
          round: 'Giornata 35',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/492.png',
          awayTeamLogo: 'https://media.api-sports.io/football/teams/496.png',
        ),
      ];

      _scheduledMatches = [
        SoccerMatch(
          id: 4,
          homeTeamId: 497,
          awayTeamId: 500,
          homeTeamName: 'Roma',
          awayTeamName: 'Bologna',
          homeScore: 0,
          awayScore: 0,
          status: 'NS',
          date: DateTime(2023, 5, 14),
          time: '18:00',
          venue: 'Stadio Olimpico',
          leagueId: 135,
          leagueName: 'Serie A',
          round: 'Giornata 35',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/497.png',
          awayTeamLogo: 'https://media.api-sports.io/football/teams/500.png',
        ),
        SoccerMatch(
          id: 5,
          homeTeamId: 505,
          awayTeamId: 502,
          homeTeamName: 'Inter',
          awayTeamName: 'Verona',
          homeScore: 0,
          awayScore: 0,
          status: 'NS',
          date: DateTime(2023, 5, 14),
          time: '20:45',
          venue: 'San Siro',
          leagueId: 135,
          leagueName: 'Serie A',
          round: 'Giornata 35',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/505.png',
          awayTeamLogo: 'https://media.api-sports.io/football/teams/502.png',
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              pinned: true,
              backgroundColor: isDark ? Colors.grey[900] : theme.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  S.of(context)!.appTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            _buildTabBar(theme, isDark),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLiveTab(theme, isDark),
                  _buildFinishedTab(theme, isDark),
                  _buildScheduledTab(theme, isDark),
                ],
              ),
            ),
          ],
        ),
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
        indicatorWeight: 3,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(
                      onPlay: (controller) => controller.repeat(),
                    )
                    .fadeOut(duration: 600.ms)
                    .then()
                    .fadeIn(duration: 600.ms),
                const SizedBox(width: 8),
                Text(S.of(context)!.live),
              ],
            ),
          ),
          Tab(text: S.of(context)!.finished),
          Tab(text: S.of(context)!.upcoming),
        ],
      ),
    );
  }

  Widget _buildLiveTab(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return Center(
        child: LoadingStateWidget(
          message: S.of(context)!.errorLoadingMatches,
          style: LoadingStyle.pulse,
        ),
      );
    }

    if (_liveMatches.isEmpty) {
      return _buildEmptyState(
        S.of(context)!.noMatchesFound,
        S.of(context)!.noMatchesOnDate,
        Icons.sports_soccer,
        theme,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadMockMatches();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _liveMatches.length + 1,
        itemBuilder: (context, index) {
          if (index == _liveMatches.length) {
            return const SizedBox(height: 80);
          }
          final match = _liveMatches[index];
          return _buildMatchCard(match, theme, isDark, index);
        },
      ),
    );
  }

  Widget _buildFinishedTab(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return Center(
        child: LoadingStateWidget(
          message: S.of(context)!.errorLoadingMatches,
          style: LoadingStyle.pulse,
        ),
      );
    }

    if (_finishedMatches.isEmpty) {
      return _buildEmptyState(
        S.of(context)!.finishedMatches,
        S.of(context)!.noMatchesOnDate,
        Icons.check_circle_outline,
        theme,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _finishedMatches.length + 1,
      itemBuilder: (context, index) {
        if (index == _finishedMatches.length) {
          return const SizedBox(height: 80);
        }
        final match = _finishedMatches[index];
        return _buildMatchCard(match, theme, isDark, index);
      },
    );
  }

  Widget _buildScheduledTab(ThemeData theme, bool isDark) {
    if (_isLoading) {
      return Center(
        child: LoadingStateWidget(
          message: S.of(context)!.errorLoadingMatches,
          style: LoadingStyle.pulse,
        ),
      );
    }

    if (_scheduledMatches.isEmpty) {
      return _buildEmptyState(
        S.of(context)!.upcomingMatches,
        S.of(context)!.noMatchesOnDate,
        Icons.event,
        theme,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _scheduledMatches.length + 1,
      itemBuilder: (context, index) {
        if (index == _scheduledMatches.length) {
          return Column(
            children: [
              if (_scheduledMatches.isNotEmpty)
                _buildPredictionSection(_scheduledMatches[0], theme, isDark),
              const SizedBox(height: 80),
            ],
          );
        }
        final match = _scheduledMatches[index];
        return _buildMatchCard(match, theme, isDark, index);
      },
    );
  }

  Widget _buildMatchCard(
      SoccerMatch match, ThemeData theme, bool isDark, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassmorphicCard(
        borderRadius: 16,
        child: InkWell(
          onTap: () {
            _haptic.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MatchDetailScreen(match: match),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (match.isLive)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        )
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .scale(
                              duration: const Duration(seconds: 1),
                              begin: const Offset(1, 1),
                              end: const Offset(1.5, 1.5),
                            ),
                        const SizedBox(width: 8),
                        const Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (match.elapsed != null)
                          Text(
                            "${match.elapsed}'",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: index * 100))
                      .slideY(begin: -0.2, end: 0),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          if (match.homeTeamLogo != null)
                            Hero(
                              tag: 'home_${match.id}',
                              child: CachedNetworkImage(
                                imageUrl: match.homeTeamLogo!,
                                width: 48,
                                height: 48,
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.sports_soccer, size: 48),
                              ),
                            )
                          else
                            const Icon(Icons.sports_soccer, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            match.homeTeamName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          if (match.isScheduled)
                            Text(
                              match.time,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: theme.primaryColor,
                              ),
                            )
                          else
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${match.homeScore}',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '-',
                                  style: TextStyle(
                                    fontSize: 24,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${match.awayScore}',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: theme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          if (match.isFinished)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'FT',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          if (match.awayTeamLogo != null)
                            Hero(
                              tag: 'away_${match.id}',
                              child: CachedNetworkImage(
                                imageUrl: match.awayTeamLogo!,
                                width: 48,
                                height: 48,
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.sports_soccer, size: 48),
                              ),
                            )
                          else
                            const Icon(Icons.sports_soccer, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            match.awayTeamName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.grey[800]
                        : theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events,
                        size: 14,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${match.leagueName} • ${match.round}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: index * 100))
        .slideX(begin: 0.1, end: 0);
  }

  Widget _buildPredictionSection(
      SoccerMatch match, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassmorphicCard(
        borderRadius: 16,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context)!.prediction,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildOddsChip('1', '2.10', theme, isDark),
                  _buildOddsChip('X', '3.40', theme, isDark),
                  _buildOddsChip('2', '3.20', theme, isDark),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () {
                  _haptic.lightImpact();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.compare_arrows,
                        color: theme.primaryColor,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.of(context)!.compareTeams,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              S.of(context)!.matchHistory,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: theme.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: const Duration(milliseconds: 300))
        .slideY(begin: 0.1, end: 0);
  }

  Widget _buildOddsChip(
      String label, String odds, ThemeData theme, bool isDark) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            odds,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      String title, String subtitle, IconData icon, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: const Duration(milliseconds: 200)).scale();
  }
}
