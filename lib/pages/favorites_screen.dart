import 'dart:convert';
// lib/pages/favorites_screen.dart

import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
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
import 'match_detail_screen.dart';
import 'match_player_profile_screen.dart'; // [FAV-extract4]
import 'team_detail_screen.dart';
import '../services/match_notification_preferences_service.dart';
import '../models/match_notification_settings.dart';
import '../services/player_notification_preferences_service.dart';
import '../models/player_notification_settings.dart';
import 'package:soccerpulse/models/local_match_models.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  final HapticService _haptic = HapticService();
  late FavoritesService _favoritesService;
  late TabController _tabController;

  bool _isLoading = false;
  List<TeamStanding> _favoriteTeams = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _favoritesService = context.read<FavoritesService>();
    _favoritesService.addListener(_onFavoritesChanged);
    _loadFavorites();
  }

  void _onFavoritesChanged() {
    if (mounted) _loadFavorites();
  }

  @override
  void dispose() {
    _favoritesService.removeListener(_onFavoritesChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    _favoriteTeams.clear();
    for (int teamId in _favoritesService.favoriteTeamIds) {
      // Match per id (i mock hanno 'id' esplicito = teamId API)
      final t = _serieATeams.firstWhere(
        (e) => (e['id'] as int?) == teamId,
        orElse: () => const <String, dynamic>{},
      );
      if (t.isEmpty) continue;
      final gf = (t['gf'] ?? 0) as int;
      final ga = (t['ga'] ?? 0) as int;
      _favoriteTeams.add(TeamStanding(
        teamId: teamId,
        teamName: t['name'] as String,
        teamLogo: t['logo'] as String?,
        position: (t['pos'] ?? 0) as int,
        points: (t['pts'] ?? 0) as int,
        played: (t['p'] ?? 0) as int,
        wins: (t['w'] ?? 0) as int,
        draws: (t['d'] ?? 0) as int,
        losses: (t['l'] ?? 0) as int,
        goalsFor: gf, goalsAgainst: ga, goalsDiff: gf - ga,
        form: 'WDWWL', description: '', leagueId: 135,
        home: TeamStats(played: 0, win: 0, draw: 0, lose: 0, goalsFor: 0, goalsAgainst: 0),
        away: TeamStats(played: 0, win: 0, draw: 0, lose: 0, goalsFor: 0, goalsAgainst: 0),
      ));
    }
    setState(() => _isLoading = false);
  }

  String _buildSubtitleText() {
    final teams = _favoritesService.favoriteTeamIds.length;
    final matches = _favoritesService.favoriteMatchIds.length;
    final players = _favoritesService.favoritePlayerIds.length;
    if (teams == 0 && matches == 0 && players == 0) {
      return tr(context, 'Aggiungi i tuoi preferiti');
    }
    final parts = <String>[];
    if (teams > 0) parts.add('$teams ${tr(context, teams == 1 ? "squadra" : "squadre")}');
    if (matches > 0) parts.add('$matches ${tr(context, matches == 1 ? "partita" : "partite")}');
    if (players > 0) parts.add('$players ${tr(context, players == 1 ? "giocatore" : "giocatori")}');
    return parts.join(', ');
  }

  // ═══════════════════════════════════════════════════════════
  // MOCK MATCHES — Serie A 2022-23 demo
  // ═══════════════════════════════════════════════════════════
  static final List<Map<String, dynamic>> _mockMatches = [
    // ── LIVE ──
    {
      'id': 9010,
      'homeTeam': 'Lazio', 'homeId': 5, 'homeLogo': 'https://media.api-sports.io/football/teams/487.png',
      'awayTeam': 'Roma', 'awayId': 6, 'awayLogo': 'https://media.api-sports.io/football/teams/497.png',
      'homeScore': 1, 'awayScore': 0, 'status': 'LIVE', 'minute': '62\'',
      'date': 'Oggi', 'time': '20:45', 'league': 'Serie A', 'round': 'Giornata 28',
    },
    {
      'id': 9001,
      'homeTeam': 'Lazio', 'homeId': 5, 'homeLogo': 'https://media.api-sports.io/football/teams/487.png',
      'awayTeam': 'Milan', 'awayId': 3, 'awayLogo': 'https://media.api-sports.io/football/teams/489.png',
      'homeScore': 2, 'awayScore': 1, 'status': 'LIVE', 'minute': '45\'',
      'date': 'Oggi', 'time': '20:45', 'league': 'Serie A', 'round': 'Giornata 35',
    },
    // ── PROSSIME ──
    {
      'id': 9002,
      'homeTeam': 'Inter', 'homeId': 2, 'homeLogo': 'https://media.api-sports.io/football/teams/505.png',
      'awayTeam': 'Juventus', 'awayId': 4, 'awayLogo': 'https://media.api-sports.io/football/teams/496.png',
      'homeScore': null, 'awayScore': null, 'status': 'NS',
      'date': 'Dom 16 Mar', 'time': '20:45', 'league': 'Serie A', 'round': 'Giornata 29',
    },
    {
      'id': 9003,
      'homeTeam': 'Milan', 'homeId': 3, 'homeLogo': 'https://media.api-sports.io/football/teams/489.png',
      'awayTeam': 'Napoli', 'awayId': 1, 'awayLogo': 'https://media.api-sports.io/football/teams/492.png',
      'homeScore': null, 'awayScore': null, 'status': 'NS',
      'date': 'Sab 15 Mar', 'time': '18:00', 'league': 'Serie A', 'round': 'Giornata 29',
    },
    {
      'id': 9004,
      'homeTeam': 'Napoli', 'homeId': 1, 'homeLogo': 'https://media.api-sports.io/football/teams/492.png',
      'awayTeam': 'Lazio', 'awayId': 5, 'awayLogo': 'https://media.api-sports.io/football/teams/487.png',
      'homeScore': null, 'awayScore': null, 'status': 'NS',
      'date': 'Dom 23 Mar', 'time': '15:00', 'league': 'Serie A', 'round': 'Giornata 30',
    },
    {
      'id': 9005,
      'homeTeam': 'Roma', 'homeId': 6, 'homeLogo': 'https://media.api-sports.io/football/teams/497.png',
      'awayTeam': 'Inter', 'awayId': 2, 'awayLogo': 'https://media.api-sports.io/football/teams/505.png',
      'homeScore': null, 'awayScore': null, 'status': 'NS',
      'date': 'Dom 23 Mar', 'time': '20:45', 'league': 'Serie A', 'round': 'Giornata 30',
    },
    {
      'id': 9006,
      'homeTeam': 'Atalanta', 'homeId': 7, 'homeLogo': 'https://media.api-sports.io/football/teams/499.png',
      'awayTeam': 'Milan', 'awayId': 3, 'awayLogo': 'https://media.api-sports.io/football/teams/489.png',
      'homeScore': null, 'awayScore': null, 'status': 'NS',
      'date': 'Sab 22 Mar', 'time': '20:45', 'league': 'Serie A', 'round': 'Giornata 30',
    },
    // ── FINITE ──
    {
      'id': 8001,
      'homeTeam': 'Lazio', 'homeId': 5, 'homeLogo': 'https://media.api-sports.io/football/teams/487.png',
      'awayTeam': 'Milan', 'awayId': 3, 'awayLogo': 'https://media.api-sports.io/football/teams/489.png',
      'homeScore': 2, 'awayScore': 1, 'status': 'FT',
      'date': 'Ier 10 Mar', 'time': '20:45', 'league': 'Serie A', 'round': 'Giornata 27',
    },
    {
      'id': 8002,
      'homeTeam': 'Napoli', 'homeId': 1, 'homeLogo': 'https://media.api-sports.io/football/teams/492.png',
      'awayTeam': 'Inter', 'awayId': 2, 'awayLogo': 'https://media.api-sports.io/football/teams/505.png',
      'homeScore': 3, 'awayScore': 1, 'status': 'FT',
      'date': 'Sab 8 Mar', 'time': '18:00', 'league': 'Serie A', 'round': 'Giornata 27',
    },
    {
      'id': 8003,
      'homeTeam': 'Juventus', 'homeId': 4, 'homeLogo': 'https://media.api-sports.io/football/teams/496.png',
      'awayTeam': 'Roma', 'awayId': 6, 'awayLogo': 'https://media.api-sports.io/football/teams/497.png',
      'homeScore': 1, 'awayScore': 1, 'status': 'FT',
      'date': 'Dom 9 Mar', 'time': '20:45', 'league': 'Serie A', 'round': 'Giornata 27',
    },
    {
      'id': 8004,
      'homeTeam': 'Inter', 'homeId': 2, 'homeLogo': 'https://media.api-sports.io/football/teams/505.png',
      'awayTeam': 'Atalanta', 'awayId': 7, 'awayLogo': 'https://media.api-sports.io/football/teams/499.png',
      'homeScore': 2, 'awayScore': 0, 'status': 'FT',
      'date': 'Ven 7 Mar', 'time': '20:45', 'league': 'Serie A', 'round': 'Giornata 26',
    },
    {
      'id': 8005,
      'homeTeam': 'Milan', 'homeId': 3, 'homeLogo': 'https://media.api-sports.io/football/teams/489.png',
      'awayTeam': 'Fiorentina', 'awayId': 8, 'awayLogo': 'https://media.api-sports.io/football/teams/502.png',
      'homeScore': 1, 'awayScore': 0, 'status': 'FT',
      'date': 'Sab 1 Mar', 'time': '15:00', 'league': 'Serie A', 'round': 'Giornata 26',
    },
    {
      'id': 8006,
      'homeTeam': 'Lazio', 'homeId': 5, 'homeLogo': 'https://media.api-sports.io/football/teams/487.png',
      'awayTeam': 'Bologna', 'awayId': 9, 'awayLogo': 'https://media.api-sports.io/football/teams/500.png',
      'homeScore': 3, 'awayScore': 0, 'status': 'FT',
      'date': 'Dom 2 Mar', 'time': '18:00', 'league': 'Serie A', 'round': 'Giornata 26',
    },
    {
      'id': 8007,
      'homeTeam': 'Torino', 'homeId': 10, 'homeLogo': 'https://media.api-sports.io/football/teams/503.png',
      'awayTeam': 'Napoli', 'awayId': 1, 'awayLogo': 'https://media.api-sports.io/football/teams/492.png',
      'homeScore': 0, 'awayScore': 2, 'status': 'FT',
      'date': 'Dom 2 Mar', 'time': '15:00', 'league': 'Serie A', 'round': 'Giornata 26',
    },
  ];

  // ═══════════════════════════════════════════════════════════
  // MOCK PLAYERS — Serie A 2022-23
  // ═══════════════════════════════════════════════════════════
  static final List<Map<String, dynamic>> _mockPlayers = [
    // ── LAZIO ──
    {'id': 301, 'name': 'Ciro Immobile', 'position': 'Attaccante', 'teamId': 5, 'team': 'Lazio', 'teamLogo': 'https://media.api-sports.io/football/teams/487.png', 'photo': 'https://media.api-sports.io/football/players/30924.png', 'rating': 7.1, 'goals': 12, 'assists': 3, 'appearances': 31, 'yellowCards': 4, 'redCards': 0, 'nationality': 'Italia', 'age': 33, 'form': 'WDWWW'},
    {'id': 302, 'name': 'Sergej Milinkovic-Savic', 'position': 'Centrocampista', 'teamId': 5, 'team': 'Lazio', 'teamLogo': 'https://media.api-sports.io/football/teams/487.png', 'photo': 'https://media.api-sports.io/football/players/30443.png', 'rating': 7.2, 'goals': 10, 'assists': 7, 'appearances': 34, 'yellowCards': 5, 'redCards': 0, 'nationality': 'Serbia', 'age': 28, 'form': 'WWWDW'},
    {'id': 303, 'name': 'Ivan Provedel', 'position': 'Portiere', 'teamId': 5, 'team': 'Lazio', 'teamLogo': 'https://media.api-sports.io/football/teams/487.png', 'photo': 'https://media.api-sports.io/football/players/30630.png', 'rating': 6.5, 'goals': 1, 'assists': 0, 'appearances': 32, 'yellowCards': 1, 'redCards': 0, 'nationality': 'Italia', 'age': 29, 'form': 'WDLWW'},
    // ── MILAN ──
    {'id': 304, 'name': 'Rafael Leao', 'position': 'Attaccante', 'teamId': 3, 'team': 'Milan', 'teamLogo': 'https://media.api-sports.io/football/teams/489.png', 'photo': 'https://media.api-sports.io/football/players/162028.png', 'rating': 7.3, 'goals': 15, 'assists': 9, 'appearances': 34, 'yellowCards': 3, 'redCards': 0, 'nationality': 'Portogallo', 'age': 24, 'form': 'DWWLW'},
    {'id': 305, 'name': 'Theo Hernandez', 'position': 'Difensore', 'teamId': 3, 'team': 'Milan', 'teamLogo': 'https://media.api-sports.io/football/teams/489.png', 'photo': 'https://media.api-sports.io/football/players/5996.png', 'rating': 7.0, 'goals': 5, 'assists': 8, 'appearances': 33, 'yellowCards': 8, 'redCards': 1, 'nationality': 'Francia', 'age': 26, 'form': 'WDWWL'},
    {'id': 306, 'name': 'Mike Maignan', 'position': 'Portiere', 'teamId': 3, 'team': 'Milan', 'teamLogo': 'https://media.api-sports.io/football/teams/489.png', 'photo': 'https://media.api-sports.io/football/players/2932.png', 'rating': 6.8, 'goals': 0, 'assists': 0, 'appearances': 28, 'yellowCards': 2, 'redCards': 0, 'nationality': 'Francia', 'age': 28, 'form': 'WWDLW'},
    // ── INTER ──
    {'id': 307, 'name': 'Lautaro Martinez', 'position': 'Attaccante', 'teamId': 2, 'team': 'Inter', 'teamLogo': 'https://media.api-sports.io/football/teams/505.png', 'photo': 'https://media.api-sports.io/football/players/753.png', 'rating': 7.3, 'goals': 21, 'assists': 4, 'appearances': 36, 'yellowCards': 5, 'redCards': 0, 'nationality': 'Argentina', 'age': 26, 'form': 'WWWWL'},
    {'id': 308, 'name': 'Nicolo Barella', 'position': 'Centrocampista', 'teamId': 2, 'team': 'Inter', 'teamLogo': 'https://media.api-sports.io/football/teams/505.png', 'photo': 'https://media.api-sports.io/football/players/2464.png', 'rating': 7.5, 'goals': 5, 'assists': 12, 'appearances': 33, 'yellowCards': 7, 'redCards': 0, 'nationality': 'Italia', 'age': 27, 'form': 'WWDWW'},
    {'id': 309, 'name': 'Hakan Calhanoglu', 'position': 'Centrocampista', 'teamId': 2, 'team': 'Inter', 'teamLogo': 'https://media.api-sports.io/football/teams/505.png', 'photo': 'https://media.api-sports.io/football/players/2931.png', 'rating': 7.1, 'goals': 8, 'assists': 5, 'appearances': 35, 'yellowCards': 4, 'redCards': 0, 'nationality': 'Turchia', 'age': 30, 'form': 'WDWWW'},
    // ── NAPOLI ──
    {'id': 310, 'name': 'Victor Osimhen', 'position': 'Attaccante', 'teamId': 1, 'team': 'Napoli', 'teamLogo': 'https://media.api-sports.io/football/teams/492.png', 'photo': 'https://media.api-sports.io/football/players/48809.png', 'rating': 7.6, 'goals': 26, 'assists': 4, 'appearances': 32, 'yellowCards': 6, 'redCards': 0, 'nationality': 'Nigeria', 'age': 25, 'form': 'WWWWW'},
    {'id': 311, 'name': 'Khvicha Kvaratskhelia', 'position': 'Attaccante', 'teamId': 1, 'team': 'Napoli', 'teamLogo': 'https://media.api-sports.io/football/teams/492.png', 'photo': 'https://media.api-sports.io/football/players/292462.png', 'rating': 7.4, 'goals': 12, 'assists': 10, 'appearances': 34, 'yellowCards': 2, 'redCards': 0, 'nationality': 'Georgia', 'age': 23, 'form': 'DWWWW'},
    {'id': 312, 'name': 'Kim Min-jae', 'position': 'Difensore', 'teamId': 1, 'team': 'Napoli', 'teamLogo': 'https://media.api-sports.io/football/teams/492.png', 'photo': 'https://media.api-sports.io/football/players/38757.png', 'rating': 7.2, 'goals': 2, 'assists': 1, 'appearances': 36, 'yellowCards': 5, 'redCards': 0, 'nationality': 'Corea del Sud', 'age': 27, 'form': 'WWWDW'},
    // ── JUVENTUS ──
    {'id': 313, 'name': 'Dusan Vlahovic', 'position': 'Attaccante', 'teamId': 4, 'team': 'Juventus', 'teamLogo': 'https://media.api-sports.io/football/teams/496.png', 'photo': 'https://media.api-sports.io/football/players/48444.png', 'rating': 6.9, 'goals': 10, 'assists': 4, 'appearances': 31, 'yellowCards': 3, 'redCards': 0, 'nationality': 'Serbia', 'age': 24, 'form': 'LDWWL'},
    {'id': 314, 'name': 'Federico Chiesa', 'position': 'Attaccante', 'teamId': 4, 'team': 'Juventus', 'teamLogo': 'https://media.api-sports.io/football/teams/496.png', 'photo': 'https://media.api-sports.io/football/players/31077.png', 'rating': 6.8, 'goals': 5, 'assists': 3, 'appearances': 22, 'yellowCards': 2, 'redCards': 0, 'nationality': 'Italia', 'age': 26, 'form': 'WDLWD'},
    // ── ROMA ──
    {'id': 315, 'name': 'Paulo Dybala', 'position': 'Attaccante', 'teamId': 6, 'team': 'Roma', 'teamLogo': 'https://media.api-sports.io/football/teams/497.png', 'photo': 'https://media.api-sports.io/football/players/1102.png', 'rating': 7.3, 'goals': 16, 'assists': 5, 'appearances': 29, 'yellowCards': 2, 'redCards': 0, 'nationality': 'Argentina', 'age': 30, 'form': 'WWDWL'},
    {'id': 316, 'name': 'Lorenzo Pellegrini', 'position': 'Centrocampista', 'teamId': 6, 'team': 'Roma', 'teamLogo': 'https://media.api-sports.io/football/teams/497.png', 'photo': 'https://media.api-sports.io/football/players/30928.png', 'rating': 6.9, 'goals': 4, 'assists': 8, 'appearances': 34, 'yellowCards': 7, 'redCards': 1, 'nationality': 'Italia', 'age': 27, 'form': 'DLWWW'},
    // ── ATALANTA ──
    {'id': 317, 'name': 'Ademola Lookman', 'position': 'Attaccante', 'teamId': 7, 'team': 'Atalanta', 'teamLogo': 'https://media.api-sports.io/football/teams/499.png', 'photo': 'https://media.api-sports.io/football/players/18921.png', 'rating': 7.1, 'goals': 13, 'assists': 6, 'appearances': 35, 'yellowCards': 3, 'redCards': 0, 'nationality': 'Nigeria', 'age': 26, 'form': 'WWDLW'},
  ];

  /// Ritorna SOLO le partite aggiunte manualmente ai preferiti (cuoricino)
  List<Map<String, dynamic>> _getRelevantMatches() {
    final favMatchIds = _favoritesService.favoriteMatchIds.toSet();
    if (favMatchIds.isEmpty) return [];

    final matches = <Map<String, dynamic>>[];
    final foundIds = <int>{};

    // First check _mockMatches
    for (final m in _mockMatches) {
      final id = m['id'] as int;
      if (favMatchIds.contains(id)) {
        matches.add({...m});
        foundIds.add(id);
      }
    }

    // Then check stored display data for matches added from calendar/H2H/search
    for (final id in favMatchIds) {
      if (!foundIds.contains(id)) {
        final displayData = _favoritesService.getMatchDisplayData(id);
        if (displayData != null) {
          matches.add({...displayData, 'id': id});
        }
      }
    }

    return matches;
  }

  @override
  Widget build(BuildContext context) {
    // Watch for changes to rebuild when favorites are added/removed
    context.watch<FavoritesService>();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D1A) : const Color(0xFFF5F6FA),
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
                    _buildSubtitleText(),
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
                  Icon(Icons.info_outline, color: theme.primaryColor, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr(context, 'Tocca il ❤️ su squadre, partite o giocatori per aggiungerli ai preferiti'),
                      style: TextStyle(fontSize: 12, color: theme.primaryColor),
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
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        border: Border(bottom: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1),
        )),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: theme.primaryColor,
        unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey[400],
        indicatorColor: theme.primaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        tabs: [
          Tab(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.shield_rounded, size: 16),
              const SizedBox(width: 6),
              Text(S.of(context)!.squadre),
              if (_favoritesService.favoriteTeamIds.isNotEmpty)
                _buildBadge(_favoritesService.favoriteTeamIds.length, theme),
            ]),
          ),
          Tab(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.sports_soccer_rounded, size: 16),
              const SizedBox(width: 6),
              Text(S.of(context)!.partite),
              if (_getRelevantMatches().isNotEmpty)
                _buildBadge(_getRelevantMatches().length, theme),
            ]),
          ),
          Tab(
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.person_rounded, size: 16),
              const SizedBox(width: 6),
              Text(S.of(context)!.giocatori),
              if (_favoritesService.favoritePlayerIds.isNotEmpty)
                _buildBadge(_favoritesService.favoritePlayerIds.length, theme),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(int count, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: theme.primaryColor),
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

  // ═══════════════════════════════════════════════════════════
  //  TAB PARTITE — Raggruppamento Live → Prossime → Finite
  // ═══════════════════════════════════════════════════════════
  Widget _buildMatchesTab(ThemeData theme, bool isDark, S s) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final matches = _getRelevantMatches();

    if (matches.isEmpty) {
      return _buildEmptyState(
        theme, s,
        tr(context, 'Nessuna Partita Preferita'),
        tr(context, 'Aggiungi partite per seguire i risultati in tempo reale'),
        Icons.sports_soccer_rounded,
      );
    }

    // Raggruppa
    final live = matches.where((m) =>
        m['status'] == 'LIVE' || m['status'] == '1H' ||
        m['status'] == '2H' || m['status'] == 'HT').toList();
    final upcoming = matches.where((m) =>
        m['status'] == 'NS' || m['status'] == 'TBD').toList();
    final finished = matches.where((m) =>
        m['status'] == 'FT' || m['status'] == 'AET' || m['status'] == 'PEN').toList();

    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          physics: const BouncingScrollPhysics(),
          children: [
            if (live.isNotEmpty) ...[
              _buildSectionHeader(tr(context, 'IN DIRETTA'), Icons.circle, Color(0xFFFF1744), tx, live.length),
              const SizedBox(height: 10),
              ...live.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildDismissibleMatchCard(e.value, isDark, theme, isLive: true),
              )),
              const SizedBox(height: 8),
            ],
            if (upcoming.isNotEmpty) ...[
              _buildSectionHeader(tr(context, 'PROSSIME'), Icons.schedule_rounded, Color(0xFF2196F3), tx, upcoming.length),
              const SizedBox(height: 10),
              ...upcoming.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildDismissibleMatchCard(e.value, isDark, theme),
              )),
              const SizedBox(height: 8),
            ],
            if (finished.isNotEmpty) ...[
              _buildSectionHeader(tr(context, 'FINITE'), Icons.check_circle_outlined, Colors.grey, tx, finished.length),
              const SizedBox(height: 10),
              ...finished.asMap().entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildDismissibleMatchCard(e.value, isDark, theme, isFinished: true),
              )),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.access_time_rounded, size: 11, color: lb.withOpacity(0.4)),
                const SizedBox(width: 5),
                Text(tr(context, 'Le partite finite vengono rimosse dopo 3 giorni'),
                    style: TextStyle(fontSize: 10, color: lb.withOpacity(0.4))),
              ]),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
      _buildAddMatchButton(theme, isDark),
    ]);
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color, Color tx, int count) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Row(children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: color == const Color(0xFFFF1744)
                ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)]
                : [],
          ),
        ),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w800, color: tx.withOpacity(0.6),
            letterSpacing: 0.8)),
        const Spacer(),
        Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: tx.withOpacity(0.35))),
      ]),
    );
  }





  Widget _teamLogo(String url, double size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.15),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size, height: size, fit: BoxFit.contain,
        errorWidget: (_, __, ___) => Container(
          width: size, height: size,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(size * 0.15),
          ),
          child: Icon(Icons.shield_rounded, size: size * 0.6, color: Colors.grey),
        ),
      ),
    );
  }

  String _shortDate(String date) {
    final localized = localizeDayPrefix(context, date);
    // Accorcia "Dom 16 .." → "Dom 16"
    if (localized.length > 7) return localized.substring(0, 6).trim();
    return localized;
  }
  // ═══════════════════════════════════════════════════════════
  //  MATCH CARD — stile Home screen
  // ═══════════════════════════════════════════════════════════
  Widget _buildDismissibleMatchCard(Map<String, dynamic> m, bool isDark, ThemeData theme,
      {bool isLive = false, bool isFinished = false}) {
    final id = m['id'] as int;
    return Dismissible(
      key: ValueKey('match_$id'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 24),
          const SizedBox(height: 4),
          Text(S.of(context)!.rimuovi, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red)),
        ]),
      ),
      confirmDismiss: (_) async => true,
      onDismissed: (_) {
        _haptic.lightImpact();
        _favoritesService.toggleMatchFavorite(id, status: m['status'] as String);
        _syncMatchNotifications(id, false);
        setState(() {});
      },
      child: _buildFavMatchCard(m, isDark, theme, isLive: isLive, isFinished: isFinished),
    );
  }

  Widget _buildFavMatchCard(Map<String, dynamic> m, bool isDark, ThemeData theme,
      {bool isLive = false, bool isFinished = false}) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF1E1E30) : Colors.white;
    final id = m['id'] as int;
    final status = m['status'] as String;
    final isFav = _favoritesService.isMatchFavorite(id);
    final isLiveMatch = status == 'LIVE' || status == '1H' || status == '2H' || status == 'HT';
    final isFinishedMatch = status == 'FT' || status == 'AET' || status == 'PEN';
    final hasScore = isLiveMatch || isFinishedMatch;

    return GestureDetector(
      onTap: () {
        _haptic.lightImpact();
        _openMatchDetail(m);
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLive
                ? const Color(0xFFFF1744).withOpacity(0.3)
                : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.12)),
          ),
          boxShadow: [
            BoxShadow(
              color: isLive
                  ? const Color(0xFFFF1744).withOpacity(0.08)
                  : Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: isLive ? 16 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: [
          // ── Header: League info (left) + Heart (right) ──
          Row(children: [
            Icon(Icons.emoji_events_rounded, size: 13,
                color: theme.primaryColor.withOpacity(0.6)),
            const SizedBox(width: 5),
            Text(
              '${m['league'] ?? 'Serie A'} • ${m['round'] ?? ''}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: lb),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                _haptic.lightImpact();
                final wasFav = _favoritesService.isMatchFavorite(id);
                setState(() => _favoritesService.toggleMatchFavorite(id, status: status));
                _syncMatchNotifications(id, !wasFav);
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isFav ? Colors.red.withOpacity(0.08) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 20,
                  color: isFav ? Colors.red : lb.withOpacity(0.4),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Builder(
              builder: (ctx) {
                final _ns = ctx.read<MatchNotificationPreferencesService>();
                final _s = _ns.getSettingsForMatch(id);
                final _hasNotif = _s.enabled && (_s.notifyHomeGoals || _s.notifyAwayGoals ||
                    _s.notifyRedCards || _s.notifyPenalties || _s.notifyMatchStart ||
                    _s.notifyMatchEnd || _s.notifyVarDecisions || _s.notifyYellowCards ||
                    _s.notifySubstitutions || _s.notifyCorners || _s.notifyOffsides ||
                    _s.notifyShotsOnTarget || _s.notifyFouls);
                return GestureDetector(
                  onTap: () {
                    _haptic.lightImpact();
                    _showMatchNotificationSheet(m, theme, isDark).then((_) {
                      if (mounted) setState(() {});
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      _hasNotif ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                      size: 20,
                      color: _hasNotif ? const Color(0xFF4CAF50) : lb.withOpacity(0.4),
                    ),
                  ),
                );
              },
            ),
          ]),
          const SizedBox(height: 10),
          // ── Row: Home | Score/VS | Away ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // HOME
              Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _teamLogo(m['homeLogo'] as String, 40),
                  const SizedBox(height: 6),
                  Text(
                    m['homeTeam'] as String,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tx),
                    textAlign: TextAlign.center,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ]),
              ),
              // SCORE / VS
              SizedBox(
                width: 90,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (hasScore) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${m['homeScore']}',
                          style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w800,
                            color: isLiveMatch ? const Color(0xFFFF1744) : tx,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text('-',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w400, color: lb)),
                        ),
                        Text(
                          '${m['awayScore']}',
                          style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w800,
                            color: isLiveMatch ? const Color(0xFFFF1744) : tx,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isLiveMatch
                            ? const Color(0xFFFF1744)
                            : (isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.1)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isLiveMatch ? (m['minute'] as String? ?? 'LIVE') : 'FT',
                        style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: isLiveMatch ? Colors.white : lb,
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(m['time'] as String,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: tx)),
                    const SizedBox(height: 3),
                    Text(_shortDate(m['date'] as String),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: lb)),
                  ],
                ]),
              ),
              // AWAY
              Expanded(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _teamLogo(m['awayLogo'] as String, 40),
                  const SizedBox(height: 6),
                  Text(
                    m['awayTeam'] as String,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tx),
                    textAlign: TextAlign.center,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ]),
              ),
            ],
          ),
        ]),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 350)).slideY(begin: 0.04, end: 0);
  }
  /// Auto-attiva/disattiva notifiche quando si aggiunge/rimuove dai preferiti
  void _syncMatchNotifications(int matchId, bool added) {
    final notifService = context.read<MatchNotificationPreferencesService>();
    if (added) {
      final preset = MatchNotificationSettings.minimal(matchId);
      notifService.saveSettingsForMatch(preset);
    } else {
      notifService.removeSettingsForMatch(matchId);
    }
  }


  /// Apre il dettaglio partita
  void _openMatchDetail(Map<String, dynamic> m) {
    final match = SoccerMatch(
      id: m['id'] as int,
      homeTeamId: m['homeId'] as int,
      homeTeamName: m['homeTeam'] as String,
      homeTeamLogo: m['homeLogo'] as String?,
      awayTeamId: m['awayId'] as int,
      awayTeamName: m['awayTeam'] as String,
      awayTeamLogo: m['awayLogo'] as String?,
      homeScore: m['homeScore'] as int? ?? 0,
      awayScore: m['awayScore'] as int? ?? 0,
      status: m['status'] as String,
      date: DateTime.now(),
      time: m['time'] as String,
      venue: 'Stadio Olimpico',
      leagueName: m['league'] as String? ?? 'Serie A',
      round: m['round'] as String? ?? '',
    );
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MatchDetailScreen(match: match),
    ));
  }

  Widget _buildAddMatchButton(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () {
        _haptic.lightImpact();
        _showMatchPicker(theme, isDark);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_rounded, size: 18, color: theme.primaryColor),
          SizedBox(width: 8),
          Text(tr(context, 'Aggiungi Partita'),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.primaryColor)),
        ]),
      ),
    );
  }

  // ── Match Picker bottom sheet — solo prossime partite ──
  void _showMatchPicker(ThemeData theme, bool isDark) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final divider = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08);

    // Solo partite prossime (no live, no finite)
    final upcomingMatches = _mockMatches.where((m) {
      final status = m['status'] as String;
      return status == 'NS' || status == 'TBD';
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.calendar_today_rounded, size: 18, color: theme.primaryColor),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr(context, 'Prossime Partite'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: tx)),
                    Text('Serie A 2022/23', style: TextStyle(fontSize: 12, color: lb)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${upcomingMatches.length} ${tr(context, 'partite')}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: lb)),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            Divider(height: 1, color: divider),
            // Match list
            Expanded(
              child: upcomingMatches.isEmpty
                  ? Center(child: Text(tr(context, 'Nessuna partita in programma'),
                      style: TextStyle(fontSize: 14, color: lb)))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: upcomingMatches.length,
                      itemBuilder: (ctx, i) {
                        final m = upcomingMatches[i];
                        final id = m['id'] as int;
                        final isFav = _favoritesService.isMatchFavorite(id);

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _haptic.lightImpact();
                              final wasFav = _favoritesService.isMatchFavorite(id);
                              setSheetState(() {
                                _favoritesService.toggleMatchFavorite(id, status: 'NS');
                              });
                              _syncMatchNotifications(id, !wasFav);
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                border: i < upcomingMatches.length - 1
                                    ? Border(bottom: BorderSide(color: divider))
                                    : null,
                              ),
                              child: Row(children: [
                                // Data
                                SizedBox(
                                  width: 50,
                                  child: Column(children: [
                                    Text(_shortDate(m['date'] as String),
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tx),
                                        textAlign: TextAlign.center),
                                    const SizedBox(height: 1),
                                    Text(m['time'] as String,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                            color: Color(0xFF2196F3))),
                                  ]),
                                ),
                                const SizedBox(width: 12),
                                // Home logo
                                _teamLogo(m['homeLogo'] as String, 30),
                                const SizedBox(width: 10),
                                // Nomi
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m['homeTeam'] as String,
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tx, height: 1.3)),
                                      Text(m['awayTeam'] as String,
                                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tx, height: 1.3)),
                                    ],
                                  ),
                                ),
                                // Away logo
                                _teamLogo(m['awayLogo'] as String, 30),
                                const SizedBox(width: 14),
                                // Heart
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isFav ? Colors.red.withOpacity(0.08) : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: isFav ? Colors.red : lb.withOpacity(0.4),
                                    size: 22,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Match notification sheet — usa MatchNotificationPreferencesService ──
  Future<void> _showMatchNotificationSheet(Map<String, dynamic> m, ThemeData theme, bool isDark) async {
    final matchId = m['id'] as int;
    final notifService = context.read<MatchNotificationPreferencesService>();
    var settings = notifService.getSettingsForMatch(matchId);

    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final toggles = <String, bool>{
              'goals': settings.notifyHomeGoals,
              'penalties': settings.notifyPenalties,
              'var': settings.notifyVarDecisions,
              'kickoff': settings.notifyMatchStart,
              'halftime': settings.notifyHalfTime,
              'fulltime': settings.notifyMatchEnd,
              'yellowCards': settings.notifyYellowCards,
              'redCards': settings.notifyRedCards,
              'substitutions': settings.notifySubstitutions,
              'corners': settings.notifyCorners,
              'offsides': settings.notifyOffsides,
              'shotsOnTarget': settings.notifyShotsOnTarget,
              'fouls': settings.notifyFouls,
            };
            final activeCount = toggles.values.where((v) => v).length;
            final allOn = toggles.values.every((v) => v);

            void updateSetting(String key, bool val) {
              setSheetState(() {
                settings = MatchNotificationSettings(
                  matchId: matchId,
                  notifyHomeGoals: key == 'goals' ? val : settings.notifyHomeGoals,
                  notifyAwayGoals: key == 'goals' ? val : settings.notifyAwayGoals,
                  notifyPenalties: key == 'penalties' ? val : settings.notifyPenalties,
                  notifyVarDecisions: key == 'var' ? val : settings.notifyVarDecisions,
                  notifyMatchStart: key == 'kickoff' ? val : settings.notifyMatchStart,
                  notifyHalfTime: key == 'halftime' ? val : settings.notifyHalfTime,
                  notifyMatchEnd: key == 'fulltime' ? val : settings.notifyMatchEnd,
                  notifyYellowCards: key == 'yellowCards' ? val : settings.notifyYellowCards,
                  notifyRedCards: key == 'redCards' ? val : settings.notifyRedCards,
                  notifySubstitutions: key == 'substitutions' ? val : settings.notifySubstitutions,
                  notifyCorners: key == 'corners' ? val : settings.notifyCorners,
                  notifyOffsides: key == 'offsides' ? val : settings.notifyOffsides,
                  notifyShotsOnTarget: key == 'shotsOnTarget' ? val : settings.notifyShotsOnTarget,
                  notifyFouls: key == 'fouls' ? val : settings.notifyFouls,
                  enabled: true,
                );
                notifService.saveSettingsForMatch(settings);
              });
            }

            void setAll(bool val) {
              setSheetState(() {
                settings = val
                    ? MatchNotificationSettings.complete(matchId)
                    : MatchNotificationSettings.disabled(matchId);
                notifService.saveSettingsForMatch(settings);
              });
            }

            Widget sectionHeader(String title, IconData icon) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 4),
                child: Row(children: [
                  Icon(icon, size: 16, color: isDark ? Colors.white38 : Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8,
                    color: isDark ? Colors.white38 : Colors.grey[500],
                  )),
                ]),
              );
            }

            Widget notifTile(String key, IconData icon, String title, String subtitle, Color color) {
              final isOn = toggles[key] ?? false;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      _haptic.lightImpact();
                      updateSetting(key, !isOn);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isOn ? color.withOpacity(isDark ? 0.12 : 0.06) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isOn
                              ? color.withOpacity(isDark ? 0.3 : 0.2)
                              : isDark ? Colors.white10 : Colors.grey[200]!,
                          width: isOn ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: color.withOpacity(isOn ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: 20,
                              color: isOn ? color : isDark ? Colors.white30 : Colors.grey[400]),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(title, style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              color: isOn
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : (isDark ? Colors.white54 : Colors.grey[500]),
                            )),
                            const SizedBox(height: 2),
                            Text(subtitle, style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white30 : Colors.grey[400],
                            )),
                          ]),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44, height: 26,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(13),
                            color: isOn ? color : isDark ? Colors.white12 : Colors.grey[300],
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 200),
                            alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.all(3),
                              width: 20, height: 20,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              );
            }

            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5))],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.notifications_active, color: theme.primaryColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${m['homeTeam']} vs ${m['awayTeam']}',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: tx)),
                        const SizedBox(height: 2),
                        Text(
                          activeCount > 0 ? '$activeCount/${toggles.length} ${tr(context, 'notifiche attive')}' : tr(context, 'Nessuna notifica attiva'),
                          style: TextStyle(fontSize: 13, color: lb),
                        ),
                      ]),
                    ),
                    GestureDetector(
                      onTap: () {
                        _haptic.lightImpact();
                        setAll(!allOn);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: allOn ? theme.primaryColor : isDark ? Colors.white10 : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: allOn ? theme.primaryColor : isDark ? Colors.white24 : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          allOn ? S.of(context)!.deactivate : S.of(context)!.activateAll,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                              color: allOn ? Colors.white : isDark ? Colors.white70 : Colors.grey[700]),
                        ),
                      ),
                    ),
                  ]),
                ),
                Divider(color: isDark ? Colors.white12 : Colors.grey[200], height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      sectionHeader('Risultato', Icons.sports_score),
                      notifTile('goals', Icons.sports_soccer, S.of(context)!.goalNotif, 'Notifica con marcatore e minuto', Color(0xFF4CAF50)),
                      notifTile('penalties', Icons.gps_fixed, 'Rigori', 'Rigori assegnati, segnati e sbagliati', Color(0xFFE91E63)),
                      notifTile('var', Icons.videocam, 'Decisioni VAR', 'Revisioni e decisioni arbitrali al VAR', const Color(0xFF2196F3)),
                      const SizedBox(height: 16),
                      sectionHeader('Tempi di gioco', Icons.timer),
                      notifTile('kickoff', Icons.play_circle_outline, 'Inizio tempo', 'Calcio d\'inizio 1° e 2° tempo', Color(0xFF66BB6A)),
                      notifTile('halftime', Icons.pause_circle_outline, 'Fine primo tempo', 'Risultato parziale all\'intervallo', Color(0xFFFFA726)),
                      notifTile('fulltime', Icons.stop_circle_outlined, 'Fischio finale', 'Risultato finale della partita', Color(0xFFEF5350)),
                      const SizedBox(height: 16),
                      sectionHeader('Disciplina', Icons.style),
                      notifTile('yellowCards', Icons.square_rounded, S.of(context)!.cartelliniGialliNotif, S.of(context)!.ammonizioni2, const Color(0xFFFFCA28)),
                      notifTile('redCards', Icons.square_rounded, S.of(context)!.cartelliniRossiNotif, S.of(context)!.espulsioniNotif, Color(0xFFE53935)),
                      SizedBox(height: 16),
                      sectionHeader('Eventi di gioco', Icons.analytics),
                      notifTile('substitutions', Icons.swap_horiz, 'Sostituzioni', 'Cambi effettuati da entrambe le squadre', Color(0xFF42A5F5)),
                      notifTile('corners', Icons.flag, S.of(context)!.calciAngoloDett, S.of(context)!.cornerDesc, Color(0xFF26A69A)),
                      notifTile('offsides', Icons.front_hand, S.of(context)!.fuorigiocoLabel, S.of(context)!.posizioniOffside, Color(0xFF7E57C2)),
                      notifTile('shotsOnTarget', Icons.gps_not_fixed, tr(context, 'Tiri in porta'), 'Tiri nello specchio della porta', Color(0xFFFF7043)),
                      notifTile('fouls', Icons.warning_amber, S.of(context)!.falliNotif, S.of(context)!.falliDesc, const Color(0xFF8D6E63)),
                    ]),
                  ),
                ),
              ]),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TAB SQUADRE (invariata)
  // ═══════════════════════════════════════════════════════════
  Widget _buildTeamsTab(ThemeData theme, bool isDark, S s) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_favoriteTeams.isEmpty) {
      return _buildEmptyState(theme, s, s.noFavoriteTeams, s.noFavoriteTeamsDesc, Icons.shield_rounded);
    }
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
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
                          width: 50, height: 50,
                          errorWidget: (_, __, ___) => const Icon(Icons.sports_soccer, size: 50),
                        )
                      : const Icon(Icons.sports_soccer, size: 50),
                  title: Text(team.teamName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.leaderboard, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${s.position}: ${team.position}°'),
                        const SizedBox(width: 16),
                        const Icon(Icons.star, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('${team.points} ${s.points.toLowerCase()}'),
                      ]),
                      const SizedBox(height: 4),
                      Row(
                        children: (team.form ?? '').split('').take(5).map((c) {
                          if (c == 'W') return _buildFormChip(formInitial(context, c), Colors.green);
                          if (c == 'D') return _buildFormChip(formInitial(context, c), Colors.orange);
                          return _buildFormChip(formInitial(context, 'L'), Colors.red);
                        }).toList(),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.favorite, color: Colors.red),
                    onPressed: () {
                      _haptic.lightImpact();
                      setState(() {
                        _favoritesService.toggleTeamFavorite(team.teamId);
                        _favoriteTeams.remove(team);
                      });
                    },
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => TeamDetailScreen(teamStanding: team),
                    ));
                  },
                ),
              ).animate().slideX(
                begin: index.isEven ? -0.1 : 0.1, end: 0,
                delay: Duration(milliseconds: index * 50),
              ).fadeIn();
            },
          ),
        ),
        GestureDetector(
          onTap: () {
            _haptic.lightImpact();
            _showTeamPicker(theme, isDark);
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_rounded, size: 18, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(S.of(context)!.aggiungiSquadra,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: theme.primaryColor)),
            ]),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  TAB GIOCATORI — Card premium con notifiche
  // ═══════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _getFavoritePlayers() {
    final favIds = _favoritesService.favoritePlayerIds.toSet();
    if (favIds.isEmpty) return [];
    final result = _mockPlayers.where((p) => favIds.contains(p['id'] as int)).toList();
    // Aggiungi giocatori da formazioni (non nel mock)
    for (final id in favIds) {
      if (!result.any((p) => p['id'] == id)) {
        final meta = _favoritesService.getPlayerMeta(id);
        if (meta != null) {
          final posMap = {'F': 'Attaccante', 'M': 'Centrocampista', 'D': 'Difensore', 'G': 'Portiere', 'GK': 'Portiere'};
          result.add({'id': id, 'name': meta['name'] ?? 'Giocatore', 'position': posMap[meta['position']] ?? 'Attaccante',
              'teamId': meta['teamId'] ?? 0, 'team': meta['team'] ?? '', 'teamLogo': '', 'photo': '',
              'number': meta['number'] ?? 0,
              'rating': meta['rating'] ?? 6.0, 'goals': meta['goals'] ?? 0, 'assists': meta['assists'] ?? 0,
              'appearances': meta['appearances'] ?? 0, 'yellowCards': meta['yellowCards'] ?? 0,
              'redCards': meta['redCards'] ?? 0, 'nationality': meta['nationality'] ?? '',
              'age': meta['age'] ?? 0, 'form': 'WWDLW'});
        }
      }
    }
    return result;
  }

  Widget _buildPlayersTab(ThemeData theme, bool isDark, S s) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final players = _getFavoritePlayers();

    if (players.isEmpty) {
      return _buildEmptyState(theme, s, S.of(context)!.nessunGiocatorePreferito,
          S.of(context)!.aggiungiGiocatoriPerSeguire, Icons.person_rounded);
    }

    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);

    // Raggruppa per squadra
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final p in players) {
      final team = p['team'] as String;
      grouped.putIfAbsent(team, () => []).add(p);
    }

    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          physics: const BouncingScrollPhysics(),
          children: [
            for (final entry in grouped.entries) ...[
              // Team header
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 10, top: 8),
                child: Row(children: [
                  Builder(builder: (_) {
                    // Mappa team → logo
                    const teamLogos = {
                      'Lazio': 'https://media.api-sports.io/football/teams/487.png',
                      'Milan': 'https://media.api-sports.io/football/teams/489.png',
                      'Inter': 'https://media.api-sports.io/football/teams/505.png',
                      'Napoli': 'https://media.api-sports.io/football/teams/492.png',
                      'Juventus': 'https://media.api-sports.io/football/teams/496.png',
                      'Roma': 'https://media.api-sports.io/football/teams/497.png',
                      'Atalanta': 'https://media.api-sports.io/football/teams/499.png',
                      'Fiorentina': 'https://media.api-sports.io/football/teams/502.png',
                      'Torino': 'https://media.api-sports.io/football/teams/503.png',
                      'Bologna': 'https://media.api-sports.io/football/teams/500.png',
                    };
                    final logo = (entry.value.first['teamLogo'] as String?)?.isNotEmpty == true
                        ? entry.value.first['teamLogo'] as String
                        : teamLogos[entry.key] ?? '';
                    return _teamLogo(logo, 24);
                  }),
                  const SizedBox(width: 10),
                  Text(entry.key, style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: tx)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${entry.value.length}', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700, color: tx.withOpacity(0.5))),
                  ),
                ]),
              ),
              ...entry.value.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildDismissiblePlayerCard(p, isDark, theme),
              )),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
      _buildAddPlayerButton(theme, isDark),
    ]);
  }

  Widget _buildDismissiblePlayerCard(Map<String, dynamic> p, bool isDark, ThemeData theme) {
    final id = p['id'] as int;
    return Dismissible(
      key: ValueKey('player_$id'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 24),
          const SizedBox(height: 4),
          Text(S.of(context)!.rimuovi, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.red)),
        ]),
      ),
      onDismissed: (_) {
        _haptic.lightImpact();
        _favoritesService.togglePlayerFavorite(id);
        _syncPlayerNotifications(id, p['name'] as String, false);
        setState(() {});
      },
      child: _buildFavPlayerCard(p, isDark, theme),
    );
  }

  Widget _buildFavPlayerCard(Map<String, dynamic> p, bool isDark, ThemeData theme) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF1E1E30) : Colors.white;
    final divider = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08);
    final id = p['id'] as int;
    final name = p['name'] as String;
    final position = p['position'] as String;
    final rating = (p['rating'] as num).toDouble();
    final goals = p['goals'] as int? ?? 0;
    final assists = p['assists'] as int? ?? 0;
    final appearances = p['appearances'] as int? ?? 0;
    final yellowCards = p['yellowCards'] as int? ?? 0;
    final redCards = p['redCards'] as int? ?? 0;
    final form = p['form'] as String? ?? '';
    final isFav = _favoritesService.isPlayerFavorite(id);

    // Rating color
    Color ratingColor;
    Color ratingBg;
    if (rating >= 7.5) { ratingColor = Colors.white; ratingBg = const Color(0xFF1B5E20); }
    else if (rating >= 7.0) { ratingColor = Colors.white; ratingBg = const Color(0xFF388E3C); }
    else if (rating >= 6.5) { ratingColor = const Color(0xFF1A1A1A); ratingBg = const Color(0xFFFDD835); }
    else if (rating >= 6.0) { ratingColor = Colors.white; ratingBg = const Color(0xFFEF6C00); }
    else { ratingColor = Colors.white; ratingBg = const Color(0xFFD32F2F); }

    // Position
    String posAbbr;
    Color posColor;
    if (position.contains('Attaccante')) { posAbbr = 'ATT'; posColor = const Color(0xFFE53935); }
    else if (position.contains('Centrocampista')) { posAbbr = 'CEN'; posColor = const Color(0xFF43A047); }
    else if (position.contains('Difensore')) { posAbbr = 'DIF'; posColor = const Color(0xFF1E88E5); }
    else { posAbbr = 'POR'; posColor = const Color(0xFFFFA726); }

    return GestureDetector(
      onTap: () {
        _haptic.lightImpact();
        final llp = LocalLineupPlayer(
          number: id % 100,
          name: name,
          position: position.contains('Attaccante') ? 'F'
              : position.contains('Centrocampista') ? 'M'
              : position.contains('Difensore') ? 'D' : 'G',
          rating: rating,
          goals: goals,
          assists: assists,
          shots: 0,
          shotsOnTarget: 0,
          yellowCards: yellowCards,
          redCards: redCards,
          minutesPlayed: (appearances) * 78,
          passes: 0,
          passesCompleted: 0,
        );
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MatchPlayerProfileScreen(
            player: llp,
            teamName: p['team'] as String,
            teamColor: _teamColor(p['teamId'] as int),
          ),
        ));
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.12)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          // ── Header: league-style row con heart + bell a destra ──
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            GestureDetector(
              onTap: () {
                _haptic.lightImpact();
                final wasFav = _favoritesService.isPlayerFavorite(id);
                setState(() => _favoritesService.togglePlayerFavorite(id));
                _syncPlayerNotifications(id, name, !wasFav);
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    size: 20, color: isFav ? Colors.red : lb.withOpacity(0.4)),
              ),
            ),
            const SizedBox(width: 2),
            Builder(builder: (ctx) {
              final ns = ctx.watch<PlayerNotificationPreferencesService>();
              final hasNotif = ns.getSettingsByPlayerName(name) != null;
              return GestureDetector(
                onTap: () {
                  _haptic.lightImpact();
                  _showPlayerNotificationSheet(p, theme, isDark).then((_) {
                    if (mounted) setState(() {});
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    hasNotif ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                    size: 20, color: hasNotif ? const Color(0xFF4CAF50) : lb.withOpacity(0.4)),
                ),
              );
            }),
          ]),
          const SizedBox(height: 6),
          // ── Player info row ──
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            // Photo con bordo colore posizione + rating badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: posColor.withOpacity(0.4), width: 2),
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: p['photo'] as String? ?? '',
                      width: 56, height: 56, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: posColor.withOpacity(0.08)),
                        child: Icon(Icons.person, size: 30, color: lb),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -2, right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: ratingBg, borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: ratingBg.withOpacity(0.5), blurRadius: 6)],
                      border: Border.all(color: cardBg, width: 2),
                    ),
                    child: Text(rating.toStringAsFixed(1),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ratingColor)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Name + position + nationality
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 4),
                Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tx)),
                const SizedBox(height: 5),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: posColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(posAbbr, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: posColor)),
                  ),
                  const SizedBox(width: 8),
                  Text(tr(context, p['nationality'] as String? ?? ''),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: lb)),
                  if (p['age'] != null) ...[
                    Text('  •  ${p['age']} ${tr(context, 'anni')}', style: TextStyle(fontSize: 12, color: lb)),
                  ],
                ]),
                const SizedBox(height: 6),
                // Forma recente con chip V/P/S
                if (form.isNotEmpty)
                  Row(children: [
                    Text('${tr(context, 'Forma')} ', style: TextStyle(fontSize: 10, color: lb.withOpacity(0.6))),
                    const SizedBox(width: 4),
                    ...form.split('').take(5).map((c) {
                      String label;
                      Color bgColor;
                      Color fgColor;
                      if (c == 'W') { label = formInitial(context, 'W'); bgColor = const Color(0xFF4CAF50); fgColor = Colors.white; }
                      else if (c == 'D') { label = formInitial(context, 'D'); bgColor = const Color(0xFFFFA726); fgColor = Colors.white; }
                      else { label = formInitial(context, 'L'); bgColor = const Color(0xFFE53935); fgColor = Colors.white; }
                      return Container(
                        margin: const EdgeInsets.only(right: 3),
                        width: 20, height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: bgColor.withOpacity(isDark ? 0.8 : 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: fgColor)),
                      );
                    }),
                  ]),
              ]),
            ),

          ]),
          const SizedBox(height: 12),
          // ── LIVE match banner (se il giocatore sta giocando) ──
          Builder(builder: (_) {
            final teamName = p['team'] as String? ?? '';
            // Demo: Lazio-Milan è live al 67'
            final liveMatches = {
              'Lazio': {'home': 'Lazio', 'away': 'Milan', 'homeScore': 2, 'awayScore': 1, 'minute': 67, 'matchId': 9001},
              'Milan': {'home': 'Lazio', 'away': 'Milan', 'homeScore': 2, 'awayScore': 1, 'minute': 67, 'matchId': 9001},
            };
            final liveMatch = liveMatches[teamName];
            if (liveMatch == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () {
                  // Naviga alla partita live
                  final match = SoccerMatch(
                    id: liveMatch['matchId'] as int,
                    date: DateTime.now(),
                    homeTeamId: 5, awayTeamId: 3,
                    homeTeamName: liveMatch['home'] as String,
                    awayTeamName: liveMatch['away'] as String,
                    homeTeamLogo: 'https://media.api-sports.io/football/teams/487.png',
                    awayTeamLogo: 'https://media.api-sports.io/football/teams/489.png',
                    homeScore: liveMatch['homeScore'] as int,
                    awayScore: liveMatch['awayScore'] as int,
                    status: 'LIVE',
                    elapsed: liveMatch['minute'] as int,
                    time: "${liveMatch['minute']}'",
                    venue: 'Stadio Olimpico',
                    leagueName: 'Serie A',
                  );
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MatchDetailScreen(match: match),
                  ));
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(isDark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    // Pallino LIVE pulsante
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50),
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.5), blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('LIVE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: const Color(0xFF4CAF50), letterSpacing: 1)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(
                      '${liveMatch['home']} ${liveMatch['homeScore']} - ${liveMatch['awayScore']} ${liveMatch['away']}',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tx),
                    )),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text("${liveMatch['minute']}'",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF4CAF50))),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right_rounded, size: 18, color: const Color(0xFF4CAF50).withOpacity(0.7)),
                  ]),
                ),
              ),
            );
          }),
          // ── Divider ──
          Container(height: 1, color: divider),
          const SizedBox(height: 10),
          // ── Stats row con box colorati ──
          Row(children: [
            _playerStatBox('📋', '$appearances', S.of(context)!.pres, const Color(0xFF7E57C2), isDark),
            const SizedBox(width: 6),
            _playerStatBox('⚽', '$goals', S.of(context)!.goalNotif, const Color(0xFF4CAF50), isDark),
            const SizedBox(width: 6),
            _playerStatBox('🎯', '$assists', S.of(context)!.assistNotif, const Color(0xFF2196F3), isDark),
            const SizedBox(width: 6),
            _playerStatCardBox(yellowCards, redCards, isDark),
          ]),
        ]),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 350)).slideY(begin: 0.04, end: 0);
  }

  Widget _playerStatBox(String emoji, String value, String label, Color color, bool isDark) {
    // Mappa emoji → IconData
    IconData icon;
    if (emoji == '⚽') icon = Icons.sports_soccer;
    else if (emoji == '🎯') icon = Icons.assistant_rounded;
    else icon = Icons.calendar_today_rounded;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(icon, size: 16, color: color.withOpacity(0.7)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
          const SizedBox(height: 1),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[500] : Colors.grey[600])),
        ]),
      ),
    );
  }

  Widget _playerStatCardBox(int yellow, int red, bool isDark) {
    final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.grey).withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(children: [
          Icon(Icons.style_rounded, size: 16, color: lb.withOpacity(0.5)),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 12, height: 16, decoration: BoxDecoration(
              color: const Color(0xFFFFCA28), borderRadius: BorderRadius.circular(2),
              boxShadow: [BoxShadow(color: const Color(0xFFFFCA28).withOpacity(0.3), blurRadius: 3)])),
            const SizedBox(width: 3),
            Text('$yellow', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: tx)),
            const SizedBox(width: 10),
            Container(width: 12, height: 16, decoration: BoxDecoration(
              color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(2),
              boxShadow: [BoxShadow(color: const Color(0xFFE53935).withOpacity(0.3), blurRadius: 3)])),
            const SizedBox(width: 3),
            Text('$red', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: tx)),
          ]),
          const SizedBox(height: 1),
          Text(S.of(context)!.cart, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: lb)),
        ]),
      ),
    );
  }

  Widget _buildAddPlayerButton(ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () {
        _haptic.lightImpact();
        _showPlayerPicker(theme, isDark);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: theme.primaryColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.add_rounded, size: 18, color: theme.primaryColor),
          SizedBox(width: 8),
          Text(tr(context, 'Aggiungi Giocatore'),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: theme.primaryColor)),
        ]),
      ),
    );
  }

  // ── Player Picker con ricerca ──
  void _showPlayerPicker(ThemeData theme, bool isDark) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final divider = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08);
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final filtered = searchQuery.isEmpty
              ? _mockPlayers
              : _mockPlayers.where((p) =>
                  (p['name'] as String).toLowerCase().contains(searchQuery.toLowerCase()) ||
                  (p['team'] as String).toLowerCase().contains(searchQuery.toLowerCase())
                ).toList();

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(children: [
              Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: theme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.person_search_rounded, size: 18, color: theme.primaryColor),
                  ),
                  SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(tr(context, 'Cerca Giocatore'), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: tx)),
                    Text('Serie A 2022/23', style: TextStyle(fontSize: 12, color: lb)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8)),
                    child: Text('${filtered.length} ${tr(context, 'giocatori')}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: lb)),
                  ),
                ]),
              ),
              // Search field
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: TextField(
                  onChanged: (val) => setSheetState(() => searchQuery = val),
                  style: TextStyle(fontSize: 14, color: tx),
                  decoration: InputDecoration(
                    hintText: tr(context, tr(context, 'Cerca per nome o squadra...')),
                    hintStyle: TextStyle(fontSize: 13, color: lb.withOpacity(0.5)),
                    prefixIcon: Icon(Icons.search_rounded, size: 20, color: lb.withOpacity(0.5)),
                    filled: true,
                    fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.06),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              Divider(height: 1, color: divider),
              Expanded(
                child: filtered.isEmpty
                    ? Center(child: Text(tr(context, 'Nessun giocatore trovato'), style: TextStyle(fontSize: 14, color: lb)))
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, i) {
                          final p = filtered[i];
                          final id = p['id'] as int;
                          final isFav = _favoritesService.isPlayerFavorite(id);
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _haptic.lightImpact();
                                final wasFav = _favoritesService.isPlayerFavorite(id);
                                setSheetState(() => _favoritesService.togglePlayerFavorite(id));
                                _syncPlayerNotifications(id, p['name'] as String, !wasFav);
                                setState(() {});
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  border: i < filtered.length - 1 ? Border(bottom: BorderSide(color: divider)) : null),
                                child: Row(children: [
                                  ClipOval(child: CachedNetworkImage(
                                    imageUrl: p['photo'] as String? ?? '', width: 40, height: 40, fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => Container(width: 40, height: 40,
                                        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.withOpacity(0.15)),
                                        child: Icon(Icons.person, size: 20, color: lb)),
                                  )),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(p['name'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tx)),
                                    Row(children: [
                                      _teamLogo(p['teamLogo'] as String, 14),
                                      const SizedBox(width: 5),
                                      Text(p['team'] as String, style: TextStyle(fontSize: 12, color: lb)),
                                      Text(' • ${tr(context, p['position'] ?? '')}', style: TextStyle(fontSize: 12, color: lb)),
                                    ]),
                                  ])),
                                  // Rating
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _ratingColor(p['rating'] as num).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6)),
                                    child: Text('${(p['rating'] as num).toStringAsFixed(1)}',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                                            color: _ratingColor(p['rating'] as num))),
                                  ),
                                  const SizedBox(width: 10),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isFav ? Colors.red.withOpacity(0.08) : Colors.transparent,
                                      shape: BoxShape.circle),
                                    child: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                        color: isFav ? Colors.red : lb.withOpacity(0.4), size: 22),
                                  ),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ]),
          );
        },
      ),
    );
  }

  Color _teamColor(int teamId) {
    switch (teamId) {
      case 1: return const Color(0xFF004B87);
      case 2: return const Color(0xFF0068A8);
      case 3: return const Color(0xFFE5193E);
      case 4: return const Color(0xFF000000);
      case 5: return const Color(0xFF87CEEB);
      case 6: return const Color(0xFFAA1E22);
      case 7: return const Color(0xFF1B3B6F);
      default: return const Color(0xFF2196F3);
    }
  }

  Color _ratingColor(num rating) {
    if (rating >= 7.5) return const Color(0xFF1B5E20);
    if (rating >= 7.0) return const Color(0xFF388E3C);
    if (rating >= 6.5) return const Color(0xFFF9A825);
    if (rating >= 6.0) return const Color(0xFFEF6C00);
    return const Color(0xFFD32F2F);
  }

  void _syncPlayerNotifications(int playerId, String playerName, bool added, {int? playerNumber}) {
    final notifService = context.read<PlayerNotificationPreferencesService>();
    final notifId = playerNumber ?? playerId;
    if (added) {
      final preset = PlayerNotificationSettings.essentialOnly(notifId, playerName);
      notifService.saveSettingsForPlayer(preset);
    } else {
      notifService.removeSettingsForPlayer(notifId);
    }
  }

  Future<void> _showPlayerNotificationSheet(Map<String, dynamic> p, ThemeData theme, bool isDark) async {
    final playerId = p['number'] as int? ?? (p['id'] as int);
    final playerName = p['name'] as String;
    final notifService = context.read<PlayerNotificationPreferencesService>();
    // Cerca settings per nome (qualsiasi ID)
    final allSettings = notifService.getPlayersWithActiveNotifications();
    final existing = allSettings.where((s) => s.playerName == playerName);
    var settings = existing.isNotEmpty
        ? existing.first
        : notifService.getSettingsForPlayer(playerId, playerName);

    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final toggles = <String, bool>{
              'goals': settings.notifyGoals,
              'assists': settings.notifyAssists,
              'shotsOnTarget': settings.notifyShotsOnTarget,
              'dribblesSuccessful': settings.notifyDribblesSuccessful,
              'yellowCard': settings.notifyYellowCard,
              'redCard': settings.notifyRedCard,
              'foulCommitted': settings.notifyFoulCommitted,
              'foulSuffered': settings.notifyFoulSuffered,
              'substitutionOn': settings.notifySubstitutionOn,
              'keyPasses': settings.notifyKeyPasses,
              'offsides': settings.notifyOffsides,
            };
            final activeCount = toggles.values.where((v) => v).length;
            final allOn = toggles.values.every((v) => v);

            void update(String key, bool val) {
              setSheetState(() {
                settings = settings.copyWith(
                  notifyGoals: key == 'goals' ? val : null,
                  notifyAssists: key == 'assists' ? val : null,
                  notifyShotsOnTarget: key == 'shotsOnTarget' ? val : null,
                  notifyDribblesSuccessful: key == 'dribblesSuccessful' ? val : null,
                  notifyYellowCard: key == 'yellowCard' ? val : null,
                  notifyRedCard: key == 'redCard' ? val : null,
                  notifyFoulCommitted: key == 'foulCommitted' ? val : null,
                  notifyFoulSuffered: key == 'foulSuffered' ? val : null,
                  notifySubstitutionOn: key == 'substitutionOn' ? val : null,
                  notifyKeyPasses: key == 'keyPasses' ? val : null,
                  notifyOffsides: key == 'offsides' ? val : null,
                  enabled: true,
                );
                // Salva per TUTTI gli ID associati a questo giocatore
                notifService.saveSettingsForPlayer(settings);
                notifService.updateAllSettingsForPlayerByName(playerName, settings);
              });
            }

            void setAll(bool val) {
              setSheetState(() {
                if (val) {
                  settings = settings.copyWith(
                    notifyGoals: true, notifyAssists: true, notifyShotsOnTarget: true, notifyDribblesSuccessful: true,
                    notifyYellowCard: true, notifyRedCard: true, notifyFoulCommitted: true,
                    notifyFoulSuffered: true, notifySubstitutionOn: true,
                    notifyKeyPasses: true, notifyOffsides: true, enabled: true);
                } else {
                  settings = settings.copyWith(
                    notifyGoals: false, notifyAssists: false, notifyShotsOnTarget: false, notifyDribblesSuccessful: false,
                    notifyYellowCard: false, notifyRedCard: false, notifyFoulCommitted: false,
                    notifyFoulSuffered: false, notifySubstitutionOn: false,
                    notifyKeyPasses: false, notifyOffsides: false, enabled: false);
                }
                // Salva per TUTTI gli ID associati a questo giocatore
                notifService.saveSettingsForPlayer(settings);
                notifService.updateAllSettingsForPlayerByName(playerName, settings);
              });
            }

            Widget tile(String key, IconData icon, String title, String sub, Color color) {
              final isOn = toggles[key] ?? false;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Material(color: Colors.transparent, child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () { _haptic.lightImpact(); update(key, !isOn); },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isOn ? color.withOpacity(isDark ? 0.12 : 0.06) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isOn ? color.withOpacity(isDark ? 0.3 : 0.2) : isDark ? Colors.white10 : Colors.grey[200]!, width: isOn ? 1.5 : 1)),
                    child: Row(children: [
                      Container(width: 40, height: 40, decoration: BoxDecoration(
                          color: color.withOpacity(isOn ? 0.15 : 0.08), borderRadius: BorderRadius.circular(10)),
                        child: Icon(icon, size: 20, color: isOn ? color : isDark ? Colors.white30 : Colors.grey[400])),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                            color: isOn ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white54 : Colors.grey[500]))),
                        const SizedBox(height: 2),
                        Text(sub, style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : Colors.grey[400])),
                      ])),
                      AnimatedContainer(duration: const Duration(milliseconds: 200), width: 44, height: 26,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(13),
                            color: isOn ? color : isDark ? Colors.white12 : Colors.grey[300]),
                        child: AnimatedAlign(duration: const Duration(milliseconds: 200),
                          alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(margin: const EdgeInsets.all(3), width: 20, height: 20,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white,
                                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)])))),
                    ]),
                  ),
                )),
              );
            }

            Widget header(String t, IconData ic) => Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Row(children: [
                Icon(ic, size: 16, color: isDark ? Colors.white38 : Colors.grey[500]),
                const SizedBox(width: 8),
                Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8,
                    color: isDark ? Colors.white38 : Colors.grey[500])),
              ]),
            );

            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
              decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5))]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
                    decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 8), child: Row(children: [
                  ClipOval(child: CachedNetworkImage(imageUrl: p['photo'] as String? ?? '', width: 44, height: 44, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(width: 44, height: 44,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: theme.primaryColor.withOpacity(0.1)),
                          child: Icon(Icons.person, color: theme.primaryColor, size: 24)))),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(playerName, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: tx)),
                    const SizedBox(height: 2),
                    Text(activeCount > 0 ? '$activeCount/${toggles.length} ${tr(context, 'notifiche attive')}' : tr(context, 'Nessuna notifica attiva'),
                        style: TextStyle(fontSize: 13, color: lb)),
                  ])),
                  GestureDetector(onTap: () { _haptic.lightImpact(); setAll(!allOn); },
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: allOn ? theme.primaryColor : isDark ? Colors.white10 : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: allOn ? theme.primaryColor : isDark ? Colors.white24 : Colors.grey[300]!)),
                      child: Text(allOn ? S.of(context)!.deactivate : S.of(context)!.activateAll,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                              color: allOn ? Colors.white : isDark ? Colors.white70 : Colors.grey[700])))),
                ])),
                Divider(color: isDark ? Colors.white12 : Colors.grey[200], height: 1),
                Flexible(child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    header(S.of(context)!.offensive, Icons.sports_soccer),
                    tile('goals', Icons.sports_soccer, S.of(context)!.goalNotif, S.of(context)!.goalDesc, const Color(0xFF4CAF50)),
                    tile('assists', Icons.assistant_rounded, S.of(context)!.assistNotif, S.of(context)!.assistDesc, const Color(0xFF2196F3)),
                    tile('shotsOnTarget', Icons.gps_not_fixed, S.of(context)!.shotsOnTargetNotif, S.of(context)!.shotsOnTargetDesc, const Color(0xFFFF7043)),
                    tile('keyPasses', Icons.trending_up, S.of(context)!.keyPassesNotif, S.of(context)!.keyPassesDesc, const Color(0xFF26A69A)),
                    tile('dribblesSuccessful', Icons.directions_run, S.of(context)!.dribblesNotif, S.of(context)!.dribblesDesc, const Color(0xFF66BB6A)),
                    tile('offsides', Icons.front_hand, S.of(context)!.offsidesNotif, S.of(context)!.offsidesDesc, const Color(0xFF7E57C2)),
                    const SizedBox(height: 16),
                    header(S.of(context)!.discipline, Icons.style),
                    tile('yellowCard', Icons.square_rounded, S.of(context)!.yellowCardNotif, S.of(context)!.yellowCardDesc, const Color(0xFFFFCA28)),
                    tile('redCard', Icons.square_rounded, S.of(context)!.redCardNotif, S.of(context)!.redCardDesc, const Color(0xFFE53935)),
                    tile('foulCommitted', Icons.warning_amber, S.of(context)!.foulsCommittedNotif, S.of(context)!.foulsCommittedDesc, const Color(0xFF8D6E63)),
                    tile('foulSuffered', Icons.personal_injury, S.of(context)!.foulsSufferedNotif, S.of(context)!.foulsSufferedDesc, const Color(0xFF5C6BC0)),
                    const SizedBox(height: 16),
                    header(S.of(context)!.other, Icons.swap_horiz),
                    tile('substitutionOn', Icons.swap_horiz, S.of(context)!.substitutionNotif, S.of(context)!.substitutionDesc, const Color(0xFF42A5F5)),
                  ]),
                )),
              ]),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════
  Widget _buildFormChip(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  // ── Serie A Teams ──
  static const List<Map<String, dynamic>> _serieATeams = [
    {'name': 'Napoli', 'id': 492, 'logo': 'https://media.api-sports.io/football/teams/492.png', 'city': 'Napoli', 'pos': 1, 'pts': 90, 'p': 38, 'w': 28, 'd': 6, 'l': 4, 'gf': 77, 'ga': 28},
    {'name': 'Inter', 'id': 505, 'logo': 'https://media.api-sports.io/football/teams/505.png', 'city': 'Milano', 'pos': 3, 'pts': 72, 'p': 38, 'w': 21, 'd': 9, 'l': 8, 'gf': 71, 'ga': 40},
    {'name': 'Milan', 'id': 489, 'logo': 'https://media.api-sports.io/football/teams/489.png', 'city': 'Milano', 'pos': 4, 'pts': 70, 'p': 38, 'w': 20, 'd': 10, 'l': 8, 'gf': 64, 'ga': 43},
    {'name': 'Juventus', 'id': 496, 'logo': 'https://media.api-sports.io/football/teams/496.png', 'city': 'Torino', 'pos': 7, 'pts': 62, 'p': 38, 'w': 17, 'd': 11, 'l': 10, 'gf': 56, 'ga': 40},
    {'name': 'Lazio', 'id': 487, 'logo': 'https://media.api-sports.io/football/teams/487.png', 'city': 'Roma', 'pos': 2, 'pts': 74, 'p': 38, 'w': 22, 'd': 8, 'l': 8, 'gf': 60, 'ga': 33},
    {'name': 'Roma', 'id': 497, 'logo': 'https://media.api-sports.io/football/teams/497.png', 'city': 'Roma', 'pos': 6, 'pts': 63, 'p': 38, 'w': 18, 'd': 9, 'l': 11, 'gf': 51, 'ga': 39},
    {'name': 'Atalanta', 'id': 499, 'logo': 'https://media.api-sports.io/football/teams/499.png', 'city': 'Bergamo', 'pos': 5, 'pts': 64, 'p': 38, 'w': 19, 'd': 7, 'l': 12, 'gf': 59, 'ga': 43},
    {'name': 'Fiorentina', 'id': 502, 'logo': 'https://media.api-sports.io/football/teams/502.png', 'city': 'Firenze', 'pos': 8, 'pts': 55, 'p': 38, 'w': 15, 'd': 10, 'l': 13, 'gf': 46, 'ga': 42},
    {'name': 'Bologna', 'id': 500, 'logo': 'https://media.api-sports.io/football/teams/500.png', 'city': 'Bologna', 'pos': 9, 'pts': 52, 'p': 38, 'w': 14, 'd': 10, 'l': 14, 'gf': 46, 'ga': 48},
    {'name': 'Torino', 'id': 503, 'logo': 'https://media.api-sports.io/football/teams/503.png', 'city': 'Torino', 'pos': 10, 'pts': 49, 'p': 38, 'w': 13, 'd': 10, 'l': 15, 'gf': 37, 'ga': 40},
    {'name': 'Monza', 'id': 1579, 'logo': 'https://media.api-sports.io/football/teams/1579.png', 'city': 'Monza', 'pos': 11, 'pts': 46, 'p': 38, 'w': 11, 'd': 13, 'l': 14, 'gf': 41, 'ga': 48},
    {'name': 'Udinese', 'id': 494, 'logo': 'https://media.api-sports.io/football/teams/494.png', 'city': 'Udine', 'pos': 12, 'pts': 43, 'p': 38, 'w': 11, 'd': 10, 'l': 17, 'gf': 43, 'ga': 52},
    {'name': 'Sassuolo', 'id': 488, 'logo': 'https://media.api-sports.io/football/teams/488.png', 'city': 'Sassuolo', 'pos': 13, 'pts': 42, 'p': 38, 'w': 11, 'd': 9, 'l': 18, 'gf': 45, 'ga': 56},
    {'name': 'Empoli', 'id': 511, 'logo': 'https://media.api-sports.io/football/teams/511.png', 'city': 'Empoli', 'pos': 14, 'pts': 40, 'p': 38, 'w': 9, 'd': 13, 'l': 16, 'gf': 35, 'ga': 49},
    {'name': 'Salernitana', 'id': 514, 'logo': 'https://media.api-sports.io/football/teams/514.png', 'city': 'Salerno', 'pos': 15, 'pts': 39, 'p': 38, 'w': 10, 'd': 9, 'l': 19, 'gf': 42, 'ga': 58},
    {'name': 'Lecce', 'id': 867, 'logo': 'https://media.api-sports.io/football/teams/867.png', 'city': 'Lecce', 'pos': 16, 'pts': 38, 'p': 38, 'w': 9, 'd': 11, 'l': 18, 'gf': 31, 'ga': 48},
    {'name': 'Verona', 'id': 504, 'logo': 'https://media.api-sports.io/football/teams/504.png', 'city': 'Verona', 'pos': 17, 'pts': 36, 'p': 38, 'w': 8, 'd': 12, 'l': 18, 'gf': 35, 'ga': 52},
    {'name': 'Cagliari', 'id': 490, 'logo': 'https://media.api-sports.io/football/teams/490.png', 'city': 'Cagliari', 'pos': 18, 'pts': 34, 'p': 38, 'w': 8, 'd': 10, 'l': 20, 'gf': 30, 'ga': 54},
    {'name': 'Frosinone', 'id': 512, 'logo': 'https://media.api-sports.io/football/teams/512.png', 'city': 'Frosinone', 'pos': 19, 'pts': 28, 'p': 38, 'w': 6, 'd': 10, 'l': 22, 'gf': 34, 'ga': 66},
    {'name': 'Genoa', 'id': 495, 'logo': 'https://media.api-sports.io/football/teams/495.png', 'city': 'Genova', 'pos': 20, 'pts': 26, 'p': 38, 'w': 5, 'd': 11, 'l': 22, 'gf': 30, 'ga': 60},
  ];

  void _showTeamPicker(ThemeData theme, bool isDark) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final divider = isDark ? Colors.white.withOpacity(0.06) : Colors.grey.withOpacity(0.1);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(children: [
                Icon(Icons.shield_rounded, size: 20, color: theme.primaryColor),
                SizedBox(width: 10),
                Text(tr(context, 'Squadre Serie A'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: tx)),
                const Spacer(),
                Text('2022/23', style: TextStyle(fontSize: 12, color: lb)),
              ]),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(tr(context, 'Tocca una squadra per aggiungerla ai preferiti'),
                  style: TextStyle(fontSize: 12, color: lb)),
            ),
            Divider(height: 1, color: divider),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _serieATeams.length,
                itemBuilder: (ctx, i) {
                  final team = _serieATeams[i];
                  final teamId = team['id'] as int;
                  final isFav = _favoritesService.isTeamFavorite(teamId);
                  return InkWell(
                    onTap: () {
                      _haptic.lightImpact();
                      setSheetState(() {
                        _favoritesService.toggleTeamFavorite(teamId);
                      });
                      _loadFavorites();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        border: i < _serieATeams.length - 1
                            ? Border(bottom: BorderSide(color: divider))
                            : null,
                      ),
                      child: Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: team['logo']! as String,
                            width: 40, height: 40, fit: BoxFit.contain,
                            placeholder: (_, __) => Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Center(child: SizedBox(width: 16, height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2))),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.shield_rounded, size: 20, color: lb),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(team['name']! as String, style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
                            Text(team['city']! as String, style: TextStyle(fontSize: 11, color: lb)),
                          ],
                        )),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: isFav ? Colors.red.withOpacity(0.1) : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : lb,
                            size: 22,
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      ThemeData theme, S s, String title, String subtitle, IconData icon) {
    final isDark = theme.brightness == Brightness.dark;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    String hint;
    String btnLabel;
    if (icon == Icons.shield || icon == Icons.shield_rounded) {
      hint = tr(context, 'Vai su Classifiche → Tocca ❤️ sulla squadra');
      btnLabel = tr(context, 'Aggiungi Squadra');
    } else if (icon == Icons.sports_soccer || icon == Icons.sports_soccer_rounded) {
      hint = tr(context, 'Vai su Home/Calendario → Tocca ❤️ sulla partita');
      btnLabel = tr(context, 'Aggiungi Partita');
    } else {
      hint = tr(context, 'Vai su una partita → Formazioni → Tocca ❤️ sul giocatore');
      btnLabel = tr(context, 'Aggiungi Giocatore');
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.04) : Colors.grey.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: lb.withOpacity(0.5)),
            ),
            const SizedBox(height: 20),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: tx)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 13, color: lb), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                _haptic.lightImpact();
                if (icon == Icons.shield || icon == Icons.shield_rounded) {
                  _showTeamPicker(theme, isDark);
                } else if (icon == Icons.sports_soccer || icon == Icons.sports_soccer_rounded) {
                  _showMatchPicker(theme, isDark);
                } else {
                  _showPlayerPicker(theme, isDark);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: theme.primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(btnLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Text(hint, style: TextStyle(fontSize: 11, color: lb, fontStyle: FontStyle.italic), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
