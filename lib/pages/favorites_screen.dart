// lib/pages/favorites_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/soccer_match.dart';
import '../models/team_standing.dart';
import '../models/player.dart';
import '../services/favorites_service.dart';
import '../services/haptic_service.dart';
import '../api/api_service.dart';
import '../generated/l10n.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/match_card.dart';
import 'match_detail_screen.dart';
import 'team_detail_screen.dart';
import 'player_detail_screen.dart';
import '../utils/player_converter.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final HapticService _haptic = HapticService();
  late FavoritesService _favoritesService;
  late TabController _tabController;

  bool _isLoading = false;
  List<TeamStanding> _favoriteTeams = [];
  List<SoccerMatch> _favoriteMatches = [];
  List<Player> _favoritePlayers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _favoritesService = context.read<FavoritesService>();
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    try {
      for (int teamId in _favoritesService.favoriteTeamIds) {
        final standings = await _apiService.fetchStandings(135);
        final team = standings.firstWhere((t) => t.teamId == teamId,
            orElse: () => TeamStanding(
                  teamId: teamId,
                  teamName: 'Unknown',
                  position: 0,
                  points: 0,
                  played: 0,
                  wins: 0,
                  draws: 0,
                  losses: 0,
                  goalsFor: 0,
                  goalsAgainst: 0,
                  goalsDiff: 0,
                  form: '',
                  description: '',
                  leagueId: 135,
                  home: TeamStats(
                      played: 0,
                      win: 0,
                      draw: 0,
                      lose: 0,
                      goalsFor: 0,
                      goalsAgainst: 0),
                  away: TeamStats(
                      played: 0,
                      win: 0,
                      draw: 0,
                      lose: 0,
                      goalsFor: 0,
                      goalsAgainst: 0),
                ));
        _favoriteTeams.add(team);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(theme, isDark, s),
          _buildTabBar(theme, isDark, s),
          Expanded(
            child: _buildTabBarView(theme, isDark, s),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark, S s) {
    final totalFavorites = _favoritesService.totalFavorites;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.favorites,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalFavorites > 0
                        ? '$totalFavorites ${s.teams}'
                        : 'Aggiungi i tuoi preferiti',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.favorite,
                  color: theme.primaryColor,
                  size: 32,
                ),
              )
                  .animate()
                  .scale(
                    delay: const Duration(milliseconds: 300),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(),
            ],
          ),

          // Helper widget se non ci sono favoriti
          if (totalFavorites == 0) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tocca il ❤️ su squadre, partite o giocatori per aggiungerli ai preferiti',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .slideY(begin: -0.2, end: 0)
                .fadeIn(delay: const Duration(milliseconds: 200)),
          ],
        ],
      ),
    ).animate().slideY(begin: -0.2, end: 0).fadeIn();
  }

  Widget _buildTabBar(ThemeData theme, bool isDark, S s) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 1),
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
            text: s.teams,
            icon: const Icon(Icons.shield, size: 20),
          ),
          Tab(
            text: s.matches,
            icon: const Icon(Icons.sports_soccer, size: 20),
          ),
          Tab(
            text: s.players,
            icon: const Icon(Icons.person, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBarView(ThemeData theme, bool isDark, S s) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildTeamsTab(theme, isDark, s),
        _buildMatchesTab(theme, isDark, s),
        _buildPlayersTab(theme, isDark, s),
      ],
    );
  }

  Widget _buildTeamsTab(ThemeData theme, bool isDark, S s) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favoriteTeams.isEmpty) {
      return _buildEmptyState(
        theme,
        s,
        s.noFavoriteTeams,
        s.noFavoriteTeamsDesc,
        Icons.shield,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteTeams.length,
      itemBuilder: (context, index) {
        final team = _favoriteTeams[index];
        return GlassmorphicCard(
          borderRadius: 16,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: team.teamLogo != null
                ? CachedNetworkImage(
                    imageUrl: team.teamLogo!,
                    width: 50,
                    height: 50,
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.sports_soccer, size: 50),
                  )
                : const Icon(Icons.sports_soccer, size: 50),
            title: Text(
              team.teamName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.leaderboard, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${s.position}: ${team.position}°'),
                    const SizedBox(width: 16),
                    const Icon(Icons.star, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${team.points} ${s.points.toLowerCase()}'),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildFormChip(s.won[0], Colors.green),
                    _buildFormChip(s.draw[0], Colors.orange),
                    _buildFormChip(s.lost[0], Colors.red),
                    _buildFormChip(s.won[0], Colors.green),
                    _buildFormChip(s.won[0], Colors.green),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.favorite,
                color: theme.primaryColor,
              ),
              onPressed: () {
                _haptic.lightImpact();
                setState(() {
                  _favoritesService.toggleTeamFavorite(team.teamId);
                  _favoriteTeams.remove(team);
                });
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TeamDetailScreen(teamStanding: team),
                ),
              );
            },
          ),
        )
            .animate()
            .slideX(
              begin: index.isEven ? -0.1 : 0.1,
              end: 0,
              delay: Duration(milliseconds: index * 50),
            )
            .fadeIn();
      },
    );
  }

  Widget _buildMatchesTab(ThemeData theme, bool isDark, S s) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favoriteMatches.isEmpty) {
      return _buildEmptyState(
        theme,
        s,
        s.noMatchesForFavorites,
        s.addFavorites,
        Icons.sports_soccer,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteMatches.length,
      itemBuilder: (context, index) {
        final match = _favoriteMatches[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: MatchCard(
            match: match,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MatchDetailScreen(match: match),
                ),
              );
            },
          ),
        )
            .animate()
            .slideY(
              begin: 0.1,
              end: 0,
              delay: Duration(milliseconds: index * 50),
            )
            .fadeIn();
      },
    );
  }

  Widget _buildPlayersTab(ThemeData theme, bool isDark, S s) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favoritePlayers.isEmpty) {
      return _buildEmptyState(
        theme,
        s,
        s.noPlayersData,
        s.noPlayersDataDesc,
        Icons.person,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoritePlayers.length,
      itemBuilder: (context, index) {
        final player = _favoritePlayers[index];
        return GlassmorphicCard(
          borderRadius: 16,
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: player.photo != null
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: player.photo!,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.person, size: 50),
                    ),
                  )
                : const Icon(Icons.person, size: 50),
            title: Text(
              player.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('${player.teamName} • ${player.position}'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatChip(
                        Icons.sports_soccer, '${player.goals}', s.goals),
                    const SizedBox(width: 12),
                    _buildStatChip(
                        Icons.assistant, '${player.assists}', s.assists),
                    const SizedBox(width: 12),
                    _buildStatChip(
                        Icons.style, '${player.yellowCards}', s.yellowCards),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.favorite,
                color: theme.primaryColor,
              ),
              onPressed: () {
                _haptic.lightImpact();
                setState(() {
                  _favoritesService.togglePlayerFavorite(player.id);
                  _favoritePlayers.remove(player);
                });
              },
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlayerDetailScreen(
                    player: PlayerConverter.toPlayerDetail(
                      player,
                      teamName: player.teamName,
                      teamColor: const Color(0xFF2196F3),
                    ),
                  ),
                ),
              );
            },
          ),
        )
            .animate()
            .slideX(
              begin: index.isEven ? -0.1 : 0.1,
              end: 0,
              delay: Duration(milliseconds: index * 50),
            )
            .fadeIn();
      },
    );
  }

  Widget _buildFormChip(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(
      ThemeData theme, S s, String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),

            // Bottoni di navigazione basati sul tipo
            if (icon == Icons.shield) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: Text(s.addTeam),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () {
                  _haptic.lightImpact();
                  // Naviga alla tab Classifiche (index 3)
                  DefaultTabController.of(context).animateTo(3);
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Vai su Classifiche → Tocca ❤️ sulla squadra',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ] else if (icon == Icons.sports_soccer) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Aggiungi Partita'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () {
                  _haptic.lightImpact();
                  // Naviga alla tab Home (index 0)
                  DefaultTabController.of(context).animateTo(0);
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Vai su Home → Tocca ❤️ sulla partita',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ] else if (icon == Icons.person) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Aggiungi Giocatore'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                onPressed: () {
                  _haptic.lightImpact();
                  // Naviga alla tab Classifiche (index 3)
                  DefaultTabController.of(context).animateTo(3);
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Vai su Classifiche → Squadra → Tocca ❤️ sul giocatore',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .scale(
          delay: const Duration(milliseconds: 200),
          duration: const Duration(milliseconds: 600),
        )
        .fadeIn();
  }
}
