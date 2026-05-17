// lib/pages/pulse_screen.dart
// Questo file non usa direttamente il modello Player quindi non richiede modifiche

import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../api/api_service.dart';
import '../models/league.dart';
import '../models/team_standing.dart';
import '../services/haptic_service.dart';
import '../widgets/stat_card.dart';
import '../widgets/team_form_widget.dart';
import '../widgets/top_stat_widget.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/loading_state_widget.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/animated_page_transition.dart';
import 'league_selection_screen.dart';
import 'settings_screen.dart';
import '../generated/l10n.dart';

class PulseScreen extends StatefulWidget {
  const PulseScreen({super.key});

  @override
  State<PulseScreen> createState() => _PulseScreenState();
}

class _PulseScreenState extends State<PulseScreen>
    with AutomaticKeepAliveClientMixin {
  final ApiService _apiService = ApiService();
  final HapticService _haptic = HapticService();

  int _selectedLeagueId = 135;
  late Future<List<TeamStanding>> _standingsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadStandings();
  }

  void _loadStandings({bool forceRefresh = false}) {
    setState(() {
      _standingsFuture = _apiService.fetchStandings(
        _selectedLeagueId,
        forceRefresh: forceRefresh,
      );
    });
  }

  Future<void> _selectLeague() async {
    _haptic.medium();
    final selected = await context.pushWithTransition<League>(
      const LeagueSelectorScreen(),
      type: TransitionType.slideFromRight,
    );

    if (selected != null && selected.id != _selectedLeagueId) {
      setState(() {
        _selectedLeagueId = selected.id;
      });
      _loadStandings(forceRefresh: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final s = S.of(context)!;
    final selectedLeague = League.popularLeagues.firstWhere(
      (l) => l.id == _selectedLeagueId,
      orElse: () => League.popularLeagues.first,
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          _haptic.light();
          _loadStandings(forceRefresh: true);
        },
        child: CustomScrollView(
          slivers: [
            _buildAppBar(selectedLeague, s),
            _buildContent(s),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(League league, S s) {
    return SliverAppBar(
      expandedHeight: 220,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💓', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                s.pulse,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 60,
              right: -30,
              child: Icon(
                Icons.favorite,
                size: 150,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Positioned(
              bottom: 60,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.pulseTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(duration: 600.ms).slideX(),
                  const SizedBox(height: 8),
                  Text(
                    league.name,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ).animate(delay: 100.ms).fadeIn(duration: 600.ms).slideX(),
                  const SizedBox(height: 4),
                  Text(
                    s.pulseDescription,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ).animate(delay: 200.ms).fadeIn(duration: 600.ms).slideX(),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.sports_soccer),
          onPressed: _selectLeague,
          tooltip: s.changeLeague,
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            _haptic.light();
            context.pushWithTransition(
              const SettingsScreen(),
              type: TransitionType.slideFromRight,
            );
          },
          tooltip: s.settings,
        ),
      ],
    );
  }

  Widget _buildContent(S s) {
    return SliverToBoxAdapter(
      child: FutureBuilder<List<TeamStanding>>(
        future: _standingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 400,
              child: LoadingStateWidget(
                message: tr(context, 'Caricamento Pulse...'),
                style: LoadingStyle.pulse,
              ),
            );
          }

          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString(), s);
          }

          final standings = snapshot.data ?? [];

          if (standings.isEmpty) {
            return SizedBox(
              height: 400,
              child: EmptyStateWidget(
                icon: Icons.analytics_outlined,
                title: s.noDataAvailable,
                message: s.tryAnotherLeague,
                actionLabel: s.changeLeague,
                onAction: _selectLeague,
                color: Theme.of(context).primaryColor,
              ),
            );
          }

          return Column(
            children: [
              const SizedBox(height: 16),
              _buildOverviewCards(standings, s),
              const SizedBox(height: 24),
              _buildTopStatistics(standings, s),
              const SizedBox(height: 24),
              _buildTeamFormSection(standings, s),
              const SizedBox(height: 24),
              _buildRecordsSection(standings, s),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewCards(List<TeamStanding> standings, S s) {
    final totalMatches =
        standings.fold<int>(0, (sum, team) => sum + team.played);
    final totalGoals =
        standings.fold<int>(0, (sum, team) => sum + team.goalsFor);
    final avgGoalsPerMatch = totalMatches > 0
        ? (totalGoals / totalMatches).toStringAsFixed(1)
        : '0.0';
    final topTeam = standings.first;
    final winRate = topTeam.played > 0
        ? ((topTeam.wins / topTeam.played) * 100).toStringAsFixed(0)
        : '0';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimationLimiter(
        child: GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: AnimationConfiguration.toStaggeredList(
            duration: const Duration(milliseconds: 375),
            childAnimationBuilder: (widget) => SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: widget),
            ),
            children: [
              StatCard(
                title: s.totalMatches,
                value: '$totalMatches',
                icon: Icons.sports_soccer,
                color: Colors.blue,
                subtitle: 'Giocate finora',
              ),
              StatCard(
                title: s.goalsScored,
                value: '$totalGoals',
                icon: Icons.sports,
                color: Colors.green,
                subtitle: '$avgGoalsPerMatch per partita',
              ),
              StatCard(
                title: 'Leader',
                value: topTeam.teamName.length > 12
                    ? topTeam.teamName.substring(0, 12)
                    : topTeam.teamName,
                icon: Icons.emoji_events,
                color: Colors.amber,
                subtitle: '${topTeam.points} ${s.points}',
              ),
              StatCard(
                title: s.winRate,
                value: '$winRate%',
                icon: Icons.trending_up,
                color: Colors.purple,
                subtitle: tr(context, 'Leader della classifica'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopStatistics(List<TeamStanding> standings, S s) {
    final bestAttack = [...standings]
      ..sort((a, b) => b.goalsFor.compareTo(a.goalsFor));
    final bestDefense = [...standings]
      ..sort((a, b) => a.goalsAgainst.compareTo(b.goalsAgainst));
    final bestForm = [...standings]..sort((a, b) {
        final formA = _calculateFormScore(b.form?.split('') ?? []);
        final formB = _calculateFormScore(a.form?.split('') ?? []);
        return formB.compareTo(formA);
      });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.topStatistics,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 16),
          AnimationLimiter(
            child: Column(
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 50.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: [
                  TopStatWidget(
                    title: s.bestAttack,
                    icon: Icons.sports,
                    color: Colors.red,
                    items: bestAttack.take(5).map((team) {
                      return TopStatItem(
                        teamName: team.teamName,
                        logo: team.teamLogo,
                        value: '${team.goalsFor}',
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TopStatWidget(
                    title: s.bestDefense,
                    icon: Icons.shield,
                    color: Colors.blue,
                    items: bestDefense.take(5).map((team) {
                      return TopStatItem(
                        teamName: team.teamName,
                        logo: team.teamLogo,
                        value: '${team.goalsAgainst}',
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TopStatWidget(
                    title: s.form,
                    icon: Icons.trending_up,
                    color: Colors.green,
                    items: bestForm.take(5).map((team) {
                      final formScore =
                          _calculateFormScore(team.form?.split('') ?? []);
                      return TopStatItem(
                        teamName: team.teamName,
                        logo: team.teamLogo,
                        value: '$formScore pts',
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamFormSection(List<TeamStanding> standings, S s) {
    final teamsWithForm = standings.where((team) => team.form != null).toList();

    if (teamsWithForm.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.teamForm,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(duration: 400.ms),
              TextButton.icon(
                onPressed: () {
                  _haptic.light();
                  // TODO: Navigate to full form view
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: Text(s.viewDetails),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimationLimiter(
            child: Column(
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 375),
                childAnimationBuilder: (widget) => SlideAnimation(
                  verticalOffset: 30.0,
                  child: FadeInAnimation(child: widget),
                ),
                children: teamsWithForm.take(5).map((team) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TeamFormWidget(
                      teamName: team.teamName,
                      teamLogo: team.teamLogo,
                      form: team.form?.split('') ?? [],
                      points: team.points,
                      rank: team.rank,
                      onTap: () {
                        _haptic.light();
                        // TODO: Show team details
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsSection(List<TeamStanding> standings, S s) {
    final mostGoals =
        standings.reduce((a, b) => a.goalsFor > b.goalsFor ? a : b);
    final fewestGoals =
        standings.reduce((a, b) => a.goalsAgainst < b.goalsAgainst ? a : b);
    final mostWins = standings.reduce((a, b) => a.wins > b.wins ? a : b);
    final mostCleanSheets = standings.where((team) {
      return team.goalsAgainst == 0 || (team.played - team.goalsAgainst) > 0;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.seasonRecords,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 16),
          GlassmorphicCard(
            child: Column(
              children: [
                _buildRecordItem(
                  icon: Icons.sports,
                  color: Colors.red,
                  title: s.mostGoals,
                  teamName: mostGoals.teamName,
                  teamLogo: mostGoals.teamLogo,
                  value: '${mostGoals.goalsFor} gol',
                ),
                const Divider(height: 1),
                _buildRecordItem(
                  icon: Icons.shield,
                  color: Colors.blue,
                  title: s.fewestGoals,
                  teamName: fewestGoals.teamName,
                  teamLogo: fewestGoals.teamLogo,
                  value: '${fewestGoals.goalsAgainst} gol subiti',
                ),
                const Divider(height: 1),
                _buildRecordItem(
                  icon: Icons.emoji_events,
                  color: Colors.amber,
                  title: s.longestWinStreak,
                  teamName: mostWins.teamName,
                  teamLogo: mostWins.teamLogo,
                  value: '${mostWins.wins} vittorie',
                ),
                const Divider(height: 1),
                _buildRecordItem(
                  icon: Icons.security,
                  color: Colors.green,
                  title: s.cleanSheets,
                  teamName: mostCleanSheets.isNotEmpty
                      ? mostCleanSheets.first.teamName
                      : 'N/A',
                  teamLogo: mostCleanSheets.isNotEmpty
                      ? mostCleanSheets.first.teamLogo
                      : null,
                  value: mostCleanSheets.isNotEmpty
                      ? '${mostCleanSheets.length} porte inviolate'
                      : 'N/A',
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildRecordItem({
    required IconData icon,
    required Color color,
    required String title,
    required String teamName,
    String? teamLogo,
    required String value,
  }) {
    return InkWell(
      onTap: () => _haptic.light(),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (teamLogo != null) ...[
                        Image.network(
                          teamLogo,
                          width: 20,
                          height: 20,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.sports_soccer, size: 20),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          teamName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateFormScore(List<String> form) {
    int score = 0;
    for (var result in form.take(5)) {
      if (result == 'W') score += 3;
      if (result == 'D') score += 1;
    }
    return score;
  }

  Widget _buildError(String error, S s) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red)
              .animate()
              .shake(duration: 500.ms),
          const SizedBox(height: 16),
          Text(
            s.errorLoading,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _haptic.medium();
              _loadStandings(forceRefresh: true);
            },
            icon: const Icon(Icons.refresh),
            label: Text(s.retry),
          ),
        ],
      ),
    );
  }
}
