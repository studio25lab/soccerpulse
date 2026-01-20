// lib/pages/team_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../generated/l10n.dart';
import '../models/soccer_match.dart';
import '../models/team_standing.dart';
import '../models/player.dart';
import '../api/api_service.dart';
import '../services/favorites_service.dart';
import '../services/haptic_service.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/loading_state_widget.dart';
import '../widgets/match_card.dart';
import 'match_detail_screen.dart';
import 'player_detail_screen.dart';
import '../utils/player_converter.dart';

class TeamDetailScreen extends StatefulWidget {
  final TeamStanding teamStanding;

  const TeamDetailScreen({
    Key? key,
    required this.teamStanding,
  }) : super(key: key);

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final FavoritesService _favoritesService = FavoritesService();
  final HapticService _haptic = HapticService();

  late TabController _tabController;

  // Data
  Future<List<SoccerMatch>>? _matchesFuture;
  Future<List<Player>>? _playersFuture;
  List<SoccerMatch> _teamMatches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTeamData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTeamData() {
    _matchesFuture = _apiService.fetchMatchesByLeague(
      widget.teamStanding.leagueId ?? 135,
    );
    _playersFuture = _loadTeamPlayers();
  }

  Future<List<Player>> _loadTeamPlayers() async {
    // Carica i giocatori della squadra
    // Per ora usiamo i top scorer e filtriamo per team
    final allPlayers = await _apiService.fetchTopScorers(
      widget.teamStanding.leagueId ?? 135,
    );

    return allPlayers
        .where((player) => player.teamName == widget.teamStanding.teamName)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(theme, isDark, s),
          SliverToBoxAdapter(
            child: _buildTeamHeader(theme, isDark, s),
          ),
          SliverToBoxAdapter(
            child: _buildStatsCards(theme, isDark, s),
          ),
          SliverToBoxAdapter(
            child: _buildTabs(theme, isDark, s),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, bool isDark, S s) {
    return SliverAppBar(
      expandedHeight: 250,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? Colors.grey[900] : theme.primaryColor,
      actions: [
        IconButton(
          icon: Icon(
            _favoritesService.isTeamFavorite(widget.teamStanding.teamId)
                ? Icons.favorite
                : Icons.favorite_border,
          ),
          onPressed: () {
            _haptic.lightImpact();
            _favoritesService.toggleTeamFavorite(widget.teamStanding.teamId);
            setState(() {});
          },
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () {
            _haptic.lightImpact();
            // Implementa condivisione
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.teamStanding.teamName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [Colors.grey[900]!, Colors.grey[850]!]
                  : [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                if (widget.teamStanding.teamLogo != null)
                  Hero(
                    tag: 'team_logo_${widget.teamStanding.teamId}',
                    child: CachedNetworkImage(
                      imageUrl: widget.teamStanding.teamLogo!,
                      width: 120,
                      height: 120,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(color: Colors.white),
                      errorWidget: (context, url, error) => const Icon(
                          Icons.sports_soccer,
                          size: 120,
                          color: Colors.white),
                    ),
                  )
                else
                  const Icon(
                    Icons.sports_soccer,
                    size: 120,
                    color: Colors.white,
                  ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(duration: 800.ms, curve: Curves.easeOutBack),
        ),
      ),
    );
  }

  Widget _buildTeamHeader(ThemeData theme, bool isDark, S s) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Position badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _getPositionColor(widget.teamStanding.position),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.leaderboard,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Posizione ${widget.teamStanding.position}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            ],
          ),
          const SizedBox(height: 16),

          // Team description (if available)
          if (widget.teamStanding.description != null)
            Text(
              widget.teamStanding.description!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(ThemeData theme, bool isDark, S s) {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildStatCard(
            'Punti',
            widget.teamStanding.points.toString(),
            Icons.star,
            theme.primaryColor,
            isDark,
          ),
          _buildStatCard(
            'Giocate',
            widget.teamStanding.played.toString(),
            Icons.sports_soccer,
            Colors.blue,
            isDark,
          ),
          _buildStatCard(
            'Vittorie',
            widget.teamStanding.wins.toString(),
            Icons.emoji_events,
            Colors.green,
            isDark,
          ),
          _buildStatCard(
            'Pareggi',
            widget.teamStanding.draws.toString(),
            Icons.handshake,
            Colors.orange,
            isDark,
          ),
          _buildStatCard(
            'Sconfitte',
            widget.teamStanding.losses.toString(),
            Icons.trending_down,
            Colors.red,
            isDark,
          ),
          _buildStatCard(
            'Diff. Reti',
            widget.teamStanding.goalsDiff.toString(),
            Icons.swap_vert,
            widget.teamStanding.goalsDiff > 0 ? Colors.green : Colors.red,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      width: 120,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: GlassmorphicCard(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildTabs(ThemeData theme, bool isDark, S s) {
    return Column(
      children: [
        Container(
          color: isDark ? Colors.grey[850] : Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: theme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: theme.primaryColor,
            tabs: [
              Tab(text: s.matches),
              Tab(text: s.statistics),
              Tab(text: s.players),
              Tab(text: s.info),
            ],
          ),
        ),
        Container(
          height: 400,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMatchesTab(theme, isDark, s),
              _buildStatisticsTab(theme, isDark, s),
              _buildPlayersTab(theme, isDark, s),
              _buildInfoTab(theme, isDark, s),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchesTab(ThemeData theme, bool isDark, S s) {
    return FutureBuilder<List<SoccerMatch>>(
      future: _matchesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: LoadingStateWidget(
              message: 'Caricamento partite...',
              style: LoadingStyle.pulse,
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(
            child: Text('Errore nel caricamento delle partite'),
          );
        }

        // Filtra solo le partite della squadra
        final teamMatches = snapshot.data!.where((match) {
          return match.homeTeamId == widget.teamStanding.teamId ||
              match.awayTeamId == widget.teamStanding.teamId;
        }).toList();

        teamMatches.sort((a, b) => b.date.compareTo(a.date));

        if (teamMatches.isEmpty) {
          return const Center(
            child: Text('Nessuna partita disponibile'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: teamMatches.length,
          itemBuilder: (context, index) {
            final match = teamMatches[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMatchItem(match, theme, isDark),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: index * 50))
                .slideX(begin: 0.1, end: 0);
          },
        );
      },
    );
  }

  Widget _buildMatchItem(SoccerMatch match, ThemeData theme, bool isDark) {
    final isHome = match.homeTeamId == widget.teamStanding.teamId;

    // Determina il risultato per la squadra
    String? result;
    Color? resultColor;
    if (match.isFinished) {
      if ((isHome && match.homeScore > match.awayScore) ||
          (!isHome && match.awayScore > match.homeScore)) {
        result = 'V';
        resultColor = Colors.green;
      } else if (match.homeScore == match.awayScore) {
        result = 'P';
        resultColor = Colors.orange;
      } else {
        result = 'S';
        resultColor = Colors.red;
      }
    }

    return GlassmorphicCard(
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Date and result
              Container(
                width: 60,
                child: Column(
                  children: [
                    Text(
                      DateFormat('dd MMM', 'it').format(match.date),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (result != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: resultColor!.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            result,
                            style: TextStyle(
                              color: resultColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Teams
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (match.homeTeamLogo != null)
                          CachedNetworkImage(
                            imageUrl: match.homeTeamLogo!,
                            width: 24,
                            height: 24,
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            match.homeTeamName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isHome ? FontWeight.bold : FontWeight.normal,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      match.isScheduled
                          ? match.time
                          : '${match.homeScore} - ${match.awayScore}',
                      style: TextStyle(
                        fontSize: match.isScheduled ? 14 : 20,
                        fontWeight: FontWeight.bold,
                        color: match.isLive ? Colors.red : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            match.awayTeamName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  !isHome ? FontWeight.bold : FontWeight.normal,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (match.awayTeamLogo != null)
                          CachedNetworkImage(
                            imageUrl: match.awayTeamLogo!,
                            width: 24,
                            height: 24,
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatisticsTab(ThemeData theme, bool isDark, S s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatSection(
            'Rendimento',
            [
              _buildStatRow('Partite giocate',
                  widget.teamStanding.played.toString(), theme),
              _buildStatRow(
                  'Vittorie', widget.teamStanding.wins.toString(), theme),
              _buildStatRow(
                  'Pareggi', widget.teamStanding.draws.toString(), theme),
              _buildStatRow(
                  'Sconfitte', widget.teamStanding.losses.toString(), theme),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatSection(
            'Gol',
            [
              _buildStatRow(
                  'Gol fatti', widget.teamStanding.goalsFor.toString(), theme),
              _buildStatRow('Gol subiti',
                  widget.teamStanding.goalsAgainst.toString(), theme),
              _buildStatRow('Differenza reti',
                  widget.teamStanding.goalsDiff.toString(), theme),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatSection(
            'Casa/Trasferta',
            [
              _buildStatRow('Vittorie casa',
                  widget.teamStanding.home.win.toString(), theme),
              _buildStatRow('Pareggi casa',
                  widget.teamStanding.home.draw.toString(), theme),
              _buildStatRow('Sconfitte casa',
                  widget.teamStanding.home.lose.toString(), theme),
              const Divider(),
              _buildStatRow('Vittorie trasferta',
                  widget.teamStanding.away.win.toString(), theme),
              _buildStatRow('Pareggi trasferta',
                  widget.teamStanding.away.draw.toString(), theme),
              _buildStatRow('Sconfitte trasferta',
                  widget.teamStanding.away.lose.toString(), theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatSection(String title, List<Widget> children) {
    return GlassmorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersTab(ThemeData theme, bool isDark, S s) {
    return FutureBuilder<List<Player>>(
      future: _playersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: LoadingStateWidget(
              message: 'Caricamento giocatori...',
              style: LoadingStyle.pulse,
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('Giocatori non disponibili'),
          );
        }

        final players = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: GlassmorphicCard(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: player.photo != null
                      ? CircleAvatar(
                          radius: 25,
                          backgroundImage:
                              CachedNetworkImageProvider(player.photo!),
                        )
                      : const CircleAvatar(
                          radius: 25,
                          child: Icon(Icons.person),
                        ),
                  title: Text(
                    player.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    player.position,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if ((player.goals ?? 0) > 0)
                        Text(
                          '${player.goals} gol',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      if ((player.assists ?? 0) > 0)
                        Text(
                          '${player.assists} assist',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  onTap: () {
                    _haptic.lightImpact();
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
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: index * 50))
                .slideX(begin: 0.1, end: 0);
          },
        );
      },
    );
  }

  Widget _buildInfoTab(ThemeData theme, bool isDark, S s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassmorphicCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informazioni Squadra',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Campionato', 'Serie A'),
                  _buildInfoRow(
                      'Posizione', '${widget.teamStanding.position}°'),
                  _buildInfoRow('Punti', widget.teamStanding.points.toString()),
                  _buildInfoRow('Forma', widget.teamStanding.form ?? 'N/A'),
                  if (widget.teamStanding.description != null)
                    _buildInfoRow(
                        'Qualificazione', widget.teamStanding.description!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getPositionColor(int position) {
    if (position <= 4) return Colors.green;
    if (position <= 6) return Colors.blue;
    if (position >= 18) return Colors.red;
    return Colors.grey;
  }
}
