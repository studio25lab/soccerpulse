// lib/pages/team_detail_screen.dart

import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import 'main_navigation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../generated/l10n.dart';
import '../models/soccer_match.dart';
import '../widgets/team_form_section.dart';
import '../utils/mock_form_data.dart';
import '../models/team_standing.dart';
import '../models/player.dart';
import '../services/favorites_service.dart';
import '../services/team_notification_preferences_service.dart';
import '../widgets/team_notification_settings_bottom_sheet.dart';
import '../services/haptic_service.dart';
import '../widgets/loading_state_widget.dart';
import 'match_detail_screen.dart';
import 'coach_profile_screen.dart';
import 'match_player_profile_screen.dart'; // [FAV-extract4]

import 'package:soccerpulse/services/match_notification_preferences_service.dart';
import 'package:soccerpulse/models/match_notification_settings.dart';
import 'package:provider/provider.dart';
import 'package:soccerpulse/models/local_match_models.dart';
import 'team_detail_internals.dart';

String _localizeTeam(BuildContext context, String? text) {
  if (text == null) return '';
  final isEn = Localizations.localeOf(context).languageCode == 'en';
  if (!isEn) return text;
  const map = {
    'Rendimento': 'Performance', 'partite giocate': 'matches played',
    'vittorie': 'wins', 'Gol': 'Goals', 'Gol fatti': 'Goals scored',
    'Gol subiti': 'Goals conceded', 'Differenza': 'Difference',
    'Media gol/partita': 'Avg goals/match', 'Totale': 'Total',
    'Punti/partita': 'Points/match', 'Posizione': 'Position',
    'PORTIERE': 'GOALKEEPER', 'DIFENSORE': 'DEFENDER',
    'CENTROCAMPISTA': 'MIDFIELDER', 'ATTACCANTE': 'FORWARD',
    'presenze': 'appearances', 'Competizione': 'Competition',
    'Campionato': 'League', 'Stagione': 'Season', 'Giornate': 'Matchdays',
    'Classifica': 'Standings', 'Zona Champions League': 'Champions League zone',
    'Zona Europa League': 'Europa League zone',
    'Zona Conference League': 'Conference League zone',
    'Zona Retrocessione': 'Relegation zone',
    'Gol/partita': 'Goals/match', 'Subiti/partita': 'Conceded/match',
    'Forma Recente': 'Recent Form', 'Sede': 'Venue',
    'Posizione 1': 'Position 1', 'Posizione 2': 'Position 2',
    'Posizione 3': 'Position 3', 'Posizione 4': 'Position 4',
    'Posizione 5': 'Position 5', 'Posizione 6': 'Position 6',
    'Posizione 7': 'Position 7', 'Posizione 8': 'Position 8',
    'Posizione 9': 'Position 9', 'Posizione 10': 'Position 10',
    'Casa': 'Home', 'Trasferta': 'Away',
    'punti in': 'points in', 'partite': 'matches',
    'Giocate': 'Played', 'Pareggi': 'Draws', 'Sconfitte': 'Losses',
    'Diff. Reti': 'Goal Diff.', 'Andamento Stagionale': 'Season trend',
    'Informazioni Club': 'Club info', 'Fondazione': 'Founded',
    'Allenatore': 'Coach', 'Italia': 'Italy',
    'Ultime 5 partite': 'Last 5 matches',
    'Prossime Partite': 'Upcoming matches',
    'Risultati': 'Results',
  };
  return map[text] ?? text;
}

class TeamDetailScreen extends StatefulWidget {
  final TeamStanding teamStanding;

  const TeamDetailScreen({
    super.key,
    required this.teamStanding,
  });

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen>
    with SingleTickerProviderStateMixin {
  late final FavoritesService _favoritesService;
  late final TeamNotificationPreferencesService _teamNotifService;
  final HapticService _haptic = HapticService();

  late TabController _tabController;

  // Data
  Future<List<SoccerMatch>>? _matchesFuture;

  Future<List<Player>>? _playersFuture;
  // [FAV-team-form-filter] selettore numero partite per calcolo W/D/L
  int? _formLimit = 5;

  @override
  void initState() {
    super.initState();
    _favoritesService = context.read<FavoritesService>();
    _teamNotifService =
        context.read<TeamNotificationPreferencesService>();
    _tabController = TabController(length: 4, vsync: this);
    _loadTeamData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  static const Map<String, String> _logos = {
    'Napoli': 'https://media.api-sports.io/football/teams/492.png',
    'Inter': 'https://media.api-sports.io/football/teams/505.png',
    'Milan': 'https://media.api-sports.io/football/teams/489.png',
    'Juventus': 'https://media.api-sports.io/football/teams/496.png',
    'Lazio': 'https://media.api-sports.io/football/teams/487.png',
    'Roma': 'https://media.api-sports.io/football/teams/497.png',
    'Atalanta': 'https://media.api-sports.io/football/teams/499.png',
    'Fiorentina': 'https://media.api-sports.io/football/teams/502.png',
    'Bologna': 'https://media.api-sports.io/football/teams/500.png',
    'Torino': 'https://media.api-sports.io/football/teams/503.png',
  };

  void _loadTeamData() {
    _matchesFuture = _generateDemoMatches();
    _playersFuture = _loadTeamPlayers();
  }

  Future<List<SoccerMatch>> _generateDemoMatches() async {
    final name = widget.teamStanding.teamName;
    final id = widget.teamStanding.teamId;
    
    // Partite demo per ogni squadra
    final Map<String, List<Map<String, dynamic>>> teamSchedule = {
      'Napoli': [
        {'opp': 'Fiorentina', 'h': true, 'hs': 1, 'as': 0, 'day': 3},
        {'opp': 'Torino', 'h': false, 'hs': 0, 'as': 1, 'day': 6},
        {'opp': 'Inter', 'h': true, 'hs': 3, 'as': 1, 'day': 14},
        {'opp': 'Verona', 'h': true, 'hs': 1, 'as': 0, 'day': 21},
        {'opp': 'Sampdoria', 'h': true, 'hs': 2, 'as': 0, 'day': 28},
      ],
      'Inter': [
        {'opp': 'Sassuolo', 'h': true, 'hs': 4, 'as': 2, 'day': 3},
        {'opp': 'Napoli', 'h': false, 'hs': 3, 'as': 1, 'day': 14},
        {'opp': 'Juventus', 'h': true, 'hs': 1, 'as': 0, 'day': 17},
        {'opp': 'Atalanta', 'h': true, 'hs': 3, 'as': 2, 'day': 28},
        {'opp': 'Milan', 'h': false, 'hs': 0, 'as': 2, 'day': 20},
      ],
      'Milan': [
        {'opp': 'Atalanta', 'h': false, 'hs': 1, 'as': 1, 'day': 6},
        {'opp': 'Lazio', 'h': false, 'hs': 2, 'as': 1, 'day': 14},
        {'opp': 'Sampdoria', 'h': true, 'hs': 5, 'as': 1, 'day': 20},
        {'opp': 'Juventus', 'h': true, 'hs': 0, 'as': 1, 'day': 28},
        {'opp': 'Roma', 'h': false, 'hs': 1, 'as': 2, 'day': 10},
      ],
      'Juventus': [
        {'opp': 'Roma', 'h': false, 'hs': 1, 'as': 1, 'day': 3},
        {'opp': 'Inter', 'h': true, 'hs': 2, 'as': 0, 'day': 10},
        {'opp': 'Lazio', 'h': true, 'hs': 3, 'as': 2, 'day': 21},
        {'opp': 'Milan', 'h': false, 'hs': 0, 'as': 1, 'day': 28},
        {'opp': 'Bologna', 'h': true, 'hs': 2, 'as': 0, 'day': 14},
      ],
      'Lazio': [
        {'opp': 'Fiorentina', 'h': true, 'hs': 2, 'as': 1, 'day': 7},
        {'opp': 'Milan', 'h': true, 'hs': 2, 'as': 1, 'day': 14},
        {'opp': 'Juventus', 'h': false, 'hs': 3, 'as': 2, 'day': 21},
        {'opp': 'Verona', 'h': true, 'hs': 2, 'as': 0, 'day': 28},
        {'opp': 'Roma', 'h': false, 'hs': 0, 'as': 1, 'day': 3},
      ],
      'Roma': [
        {'opp': 'Juventus', 'h': true, 'hs': 1, 'as': 1, 'day': 3},
        {'opp': 'Salernitana', 'h': true, 'hs': 2, 'as': 0, 'day': 14},
        {'opp': 'Bologna', 'h': false, 'hs': 0, 'as': 2, 'day': 7},
        {'opp': 'Fiorentina', 'h': false, 'hs': 2, 'as': 1, 'day': 20},
        {'opp': 'Lazio', 'h': true, 'hs': 1, 'as': 0, 'day': 3},
      ],
    };

    final schedule = teamSchedule[name] ?? [
      {'opp': 'Napoli', 'h': false, 'hs': 2, 'as': 0, 'day': 7},
      {'opp': 'Milan', 'h': true, 'hs': 1, 'as': 1, 'day': 14},
      {'opp': 'Roma', 'h': false, 'hs': 0, 'as': 2, 'day': 21},
      {'opp': 'Juventus', 'h': true, 'hs': 1, 'as': 3, 'day': 28},
    ];

    final baseMatches = schedule.asMap().entries.map((e) {
      final i = e.key;
      final m = e.value;
      final opp = m['opp'] as String;
      final isHome = m['h'] as bool;
      final hs = m['hs'] as int;
      final as_ = m['as'] as int;
      final day = m['day'] as int;
      return SoccerMatch(
        id: 5000 + id * 100 + i,
        date: DateTime(2023, 5, day),
        time: '20:45',
        status: 'FT',
        venue: isHome ? 'Casa' : 'Trasferta',
        homeTeamId: isHome ? id : 0,
        homeTeamName: isHome ? name : opp,
        homeTeamLogo: _logos[isHome ? name : opp],
        awayTeamId: isHome ? 0 : id,
        awayTeamName: isHome ? opp : name,
        awayTeamLogo: _logos[isHome ? opp : name],
        homeScore: isHome ? hs : as_,
        awayScore: isHome ? as_ : hs,
        leagueName: 'Serie A',
        season: 2023,
        round: 'Giornata ${34 + i}',
      );
    }).toList();

    // [FAV-extra-mock-matches] genera 15 partite procedurali in piu
    // per consentire filtro 5/10/20/Tutte funzionante.
    // Quando arrivera l'API, l'intero metodo sara sostituito da una
    // chiamata che ritorna le partite reali della stagione.
    final extraMatches = _generateExtraDemoMatches(name, id);

    return [...baseMatches, ...extraMatches]
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // [FAV-extra-mock-matches] generatore procedurale di partite mock
  // addizionali (15 per squadra). Usa pool di avversari Serie A e
  // risultati pseudo-random deterministici (hash del nome squadra).
  // [FAV-extra-matches-via-helper]
  // Wrapper sottile sull'helper centralizzato generateMockFormMatches.
  // 15 partite procedurali in piu rispetto alle 5 hardcoded di teamSchedule
  // (totale 20 partite per squadra, abilita filtro 5/10/20/Tutte).
  // Quando arrivera l'API, l'intero metodo sara rimosso.
  List<SoccerMatch> _generateExtraDemoMatches(String name, int id) {
    return generateMockFormMatches(
      name,
      id,
      teamLogos: _logos,
      count: 15,
      startMonth: 4,
      startYear: 2023,
      seedOffset: 200,
    );
  }

  Future<List<Player>> _loadTeamPlayers() async {
    final name = widget.teamStanding.teamName;
    final squads = _demoSquads[name];
    if (squads == null) return [];
    return squads.map((p) => Player(
      id: p['id'] as int,
      teamId: p['id'] as int,
      name: p['name'] as String,
      position: p['pos'] as String,
      teamName: name,
      photo: p['photo'] as String?,
      goals: p['g'] as int? ?? 0,
      assists: p['a'] as int? ?? 0,
      yellowCards: p['y'] as int? ?? 0,
      redCards: 0,
      appearances: p['app'] as int? ?? 0,
      rating: (p['r'] as num?)?.toDouble() ?? 0.0,
    )).toList().cast<Player>();
  }

  static const Map<String, List<Map<String, dynamic>>> _demoSquads = {
    'Napoli': [
      // Portieri
      {'id': 901, 'name': 'Meret', 'pos': 'Portiere', 'photo': 'https://media.api-sports.io/football/players/30501.png', 'app': 34, 'g': 0, 'a': 0, 'y': 2, 'r': 6.8},
      // Difensori
      {'id': 902, 'name': 'Di Lorenzo', 'pos': 'Difensore', 'photo': 'https://media.api-sports.io/football/players/30607.png', 'app': 37, 'g': 3, 'a': 5, 'y': 6, 'r': 7.1},
      {'id': 903, 'name': 'Kim Min-jae', 'pos': 'Difensore', 'photo': 'https://media.api-sports.io/football/players/152842.png', 'app': 34, 'g': 3, 'a': 0, 'y': 5, 'r': 7.2},
      {'id': 904, 'name': 'Rrahmani', 'pos': 'Difensore', 'photo': 'https://media.api-sports.io/football/players/31012.png', 'app': 32, 'g': 1, 'a': 1, 'y': 4, 'r': 6.9},
      {'id': 905, 'name': 'Mario Rui', 'pos': 'Difensore', 'photo': 'https://media.api-sports.io/football/players/730.png', 'app': 30, 'g': 0, 'a': 4, 'y': 7, 'r': 6.7},
      // Centrocampisti
      {'id': 906, 'name': 'Lobotka', 'pos': 'Centrocampista', 'photo': 'https://media.api-sports.io/football/players/25381.png', 'app': 36, 'g': 0, 'a': 3, 'y': 3, 'r': 7.3},
      {'id': 907, 'name': 'Anguissa', 'pos': 'Centrocampista', 'photo': 'https://media.api-sports.io/football/players/6589.png', 'app': 35, 'g': 3, 'a': 2, 'y': 8, 'r': 7.0},
      {'id': 908, 'name': 'Zielinski', 'pos': 'Centrocampista', 'photo': 'https://media.api-sports.io/football/players/547.png', 'app': 33, 'g': 5, 'a': 6, 'y': 3, 'r': 7.1},
      // Attaccanti
      {'id': 909, 'name': 'Osimhen', 'pos': 'Attaccante', 'photo': 'https://media.api-sports.io/football/players/48783.png', 'app': 32, 'g': 26, 'a': 4, 'y': 5, 'r': 7.8},
      {'id': 910, 'name': 'Kvaratskhelia', 'pos': 'Attaccante', 'photo': 'https://media.api-sports.io/football/players/291506.png', 'app': 34, 'g': 12, 'a': 10, 'y': 3, 'r': 7.5},
      {'id': 911, 'name': 'Politano', 'pos': 'Attaccante', 'photo': 'https://media.api-sports.io/football/players/30443.png', 'app': 30, 'g': 6, 'a': 5, 'y': 4, 'r': 6.9},
      {'id': 912, 'name': 'Raspadori', 'pos': 'Attaccante', 'photo': 'https://media.api-sports.io/football/players/142076.png', 'app': 28, 'g': 5, 'a': 3, 'y': 2, 'r': 6.7},
    ],
    'Inter': [
      {'id': 920, 'name': 'Onana', 'pos': 'Portiere', 'app': 36, 'g': 0, 'a': 0, 'y': 1, 'r': 6.7},
      {'id': 921, 'name': 'Skriniar', 'pos': 'Difensore', 'app': 30, 'g': 2, 'a': 1, 'y': 6, 'r': 6.8},
      {'id': 922, 'name': 'Bastoni', 'pos': 'Difensore', 'app': 35, 'g': 1, 'a': 4, 'y': 5, 'r': 7.0},
      {'id': 923, 'name': 'Dimarco', 'pos': 'Difensore', 'app': 33, 'g': 4, 'a': 7, 'y': 7, 'r': 7.1},
      {'id': 924, 'name': 'Dumfries', 'pos': 'Difensore', 'app': 28, 'g': 3, 'a': 3, 'y': 4, 'r': 6.8},
      {'id': 925, 'name': 'Barella', 'pos': 'Centrocampista', 'app': 36, 'g': 5, 'a': 8, 'y': 9, 'r': 7.3},
      {'id': 926, 'name': 'Brozovic', 'pos': 'Centrocampista', 'app': 30, 'g': 1, 'a': 5, 'y': 8, 'r': 6.9},
      {'id': 927, 'name': 'Calhanoglu', 'pos': 'Centrocampista', 'app': 34, 'g': 8, 'a': 6, 'y': 4, 'r': 7.2},
      {'id': 928, 'name': 'Lautaro Martinez', 'pos': 'Attaccante', 'app': 37, 'g': 21, 'a': 5, 'y': 3, 'r': 7.4},
      {'id': 929, 'name': 'Dzeko', 'pos': 'Attaccante', 'app': 32, 'g': 13, 'a': 6, 'y': 2, 'r': 7.0},
      {'id': 930, 'name': 'Lukaku', 'pos': 'Attaccante', 'app': 25, 'g': 13, 'a': 3, 'y': 4, 'r': 7.1},
    ],
    'Lazio': [
      {'id': 940, 'name': 'Provedel', 'pos': 'Portiere', 'app': 36, 'g': 1, 'a': 0, 'y': 1, 'r': 6.8},
      {'id': 941, 'name': 'Marusic', 'pos': 'Difensore', 'app': 32, 'g': 2, 'a': 3, 'y': 5, 'r': 6.7},
      {'id': 942, 'name': 'Romagnoli', 'pos': 'Difensore', 'app': 30, 'g': 1, 'a': 0, 'y': 6, 'r': 6.8},
      {'id': 943, 'name': 'Patric', 'pos': 'Difensore', 'app': 28, 'g': 0, 'a': 1, 'y': 4, 'r': 6.6},
      {'id': 944, 'name': 'Milinkovic-Savic', 'pos': 'Centrocampista', 'app': 36, 'g': 9, 'a': 12, 'y': 5, 'r': 7.5},
      {'id': 945, 'name': 'Luis Alberto', 'pos': 'Centrocampista', 'app': 33, 'g': 5, 'a': 8, 'y': 3, 'r': 7.2},
      {'id': 946, 'name': 'Cataldi', 'pos': 'Centrocampista', 'app': 28, 'g': 2, 'a': 3, 'y': 7, 'r': 6.8},
      {'id': 947, 'name': 'Immobile', 'pos': 'Attaccante', 'app': 35, 'g': 15, 'a': 5, 'y': 3, 'r': 7.2},
      {'id': 948, 'name': 'Felipe Anderson', 'pos': 'Attaccante', 'app': 34, 'g': 8, 'a': 7, 'y': 4, 'r': 7.0},
      {'id': 949, 'name': 'Pedro', 'pos': 'Attaccante', 'app': 30, 'g': 7, 'a': 6, 'y': 2, 'r': 7.1},
      {'id': 950, 'name': 'Zaccagni', 'pos': 'Attaccante', 'app': 32, 'g': 6, 'a': 5, 'y': 3, 'r': 6.9},
    ],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D0D1A) : Colors.grey[50],
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── AppBar fissa con solo titolo ──
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 0,
            backgroundColor: isDark ? const Color(0xFF0D0D1A) : theme.primaryColor,
            title: Text(widget.teamStanding.teamName,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            actions: [
              IconButton(
                icon: const Icon(Icons.home_rounded, size: 22),
                tooltip: 'Home',
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
              IconButton(
                icon: Icon(
                  // [FAV-N5] cuore colorato
                  _favoritesService.isTeamFavorite(widget.teamStanding.teamId)
                      ? Icons.favorite : Icons.favorite_border,
                  color: _favoritesService
                          .isTeamFavorite(widget.teamStanding.teamId)
                      ? Colors.red
                      : Colors.white,
                ),
                onPressed: () {
                  _haptic.lightImpact();
                  final teamId = widget.teamStanding.teamId;
                  final wasFav =
                      _favoritesService.isTeamFavorite(teamId);
                  _favoritesService.toggleTeamFavorite(teamId);
                  // [FAV-C] auto-attivazione notifiche col cuore
                  if (!wasFav) {
                    _teamNotifService.enableDefaultForTeam(teamId);
                  } else {
                    _teamNotifService.disableForTeam(teamId);
                  }
                  setState(() {});
                },
              ),
              // [FAV-C] campanella notifiche squadra
              IconButton(
                icon: Icon(
                  _teamNotifService.hasActiveNotifications(
                              widget.teamStanding.teamId)
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  color: _teamNotifService.hasActiveNotifications(
                              widget.teamStanding.teamId)
                      ? const Color(0xFF4CAF50)
                      : Colors.white,
                ),
                tooltip: 'Notifiche',
                onPressed: () async {
                  _haptic.lightImpact();
                  await TeamNotificationSettingsBottomSheet.show(
                    context,
                    teamId: widget.teamStanding.teamId,
                    teamName: widget.teamStanding.teamName,
                  );
                  if (mounted) setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _haptic.lightImpact(),
              ),
            ],
          ),
          // ── Header con logo + posizione ──
          SliverToBoxAdapter(child: _buildTeamHeader(theme, isDark, s)),
          // ── Stats cards ──
          SliverToBoxAdapter(child: _buildStatsCards(theme, isDark, s)),
          // ── Tab bar sticky ──
          SliverPersistentHeader(
            pinned: true,
            delegate: StickyTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: theme.primaryColor,
                unselectedLabelColor: isDark ? Colors.grey[500] : Colors.grey,
                indicatorColor: theme.primaryColor,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: [
                  Tab(text: s.info),
                  Tab(text: s.statistics),
                  Tab(text: s.players),
                  Tab(text: s.matches),
                ],
              ),
              isDark ? const Color(0xFF0D0D1A) : Colors.white,
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildInfoTab(theme, isDark, s),
            _buildStatisticsTab(theme, isDark, s),
            _buildPlayersTab(theme, isDark, s),
            _buildMatchesTab(theme, isDark, s),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamHeader(ThemeData theme, bool isDark, S s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [theme.primaryColor.withValues(alpha: 0.15), const Color(0xFF0D0D1A)]
              : [theme.primaryColor.withValues(alpha: 0.08), Colors.grey[50]!],
        ),
      ),
      child: Column(
        children: [
          // Logo grande
          if (widget.teamStanding.teamLogo != null)
            Hero(
              tag: 'team_logo_${widget.teamStanding.teamId}',
              child: CachedNetworkImage(
                imageUrl: widget.teamStanding.teamLogo!,
                width: 80, height: 80,
                errorWidget: (_, __, ___) => Icon(Icons.shield_rounded, size: 80, color: Colors.grey[400]),
              ),
            )
          else
            Icon(Icons.shield_rounded, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 12),
          // Position badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  // Naviga direttamente alla Classifiche
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => MainNavigation(key: MainNavigation.globalKey, initialIndex: 3)),
                    (route) => false,
                  );
                },
                child: Container(
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
                        '${_localizeTeam(context, 'Posizione')} ${widget.teamStanding.position}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            ],
          ),
          const SizedBox(height: 16),

        ],
      ),
    );
  }

  Widget _buildStatsCards(ThemeData theme, bool isDark, S s) {
    final t = widget.teamStanding;
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final divider = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: divider),
        boxShadow: [BoxShadow(color: theme.primaryColor.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Row(children: [
          Expanded(child: _modernStatItem(Icons.star_rounded, '${t.points}', s.punti, theme.primaryColor, isDark)),
          Expanded(child: _modernStatItem(Icons.sports_soccer, '${t.played}', S.of(context)!.partiteGiocate.length > 8 ? _localizeTeam(context, 'Giocate') : S.of(context)!.partiteGiocate, Colors.blue, isDark)),
          Expanded(child: _modernStatItem(Icons.emoji_events_rounded, '${t.wins}', S.of(context)!.vittorie, const Color(0xFF4CAF50), isDark)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _modernStatItem(Icons.handshake_rounded, '${t.draws}', _localizeTeam(context, 'Pareggi'), const Color(0xFFF9A825), isDark)),
          Expanded(child: _modernStatItem(Icons.cancel_outlined, '${t.losses}', _localizeTeam(context, 'Sconfitte'), const Color(0xFFE53935), isDark)),
          Expanded(child: _modernStatItem(Icons.swap_vert_rounded, '${t.goalsDiff >= 0 ? "+${t.goalsDiff}" : t.goalsDiff}', _localizeTeam(context, 'Diff. Reti'), t.goalsDiff >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935), isDark)),
        ]),
      ]),
    );
  }

  Widget _modernStatItem(IconData icon, String value, String label, Color color, bool isDark) {
    return Column(children: [
      Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500), textAlign: TextAlign.center),
    ]);
  }


  Widget _buildMatchesTab(ThemeData theme, bool isDark, S s) {
    return FutureBuilder<List<SoccerMatch>>(
      future: _matchesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: LoadingStateWidget(
              message: tr(context, 'Caricamento partite...'),
              style: LoadingStyle.pulse,
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Center(child: Text(tr(context, 'Errore nel caricamento delle partite')));
        }

        final teamMatches = snapshot.data!.where((match) {
          return match.homeTeamId == widget.teamStanding.teamId ||
              match.awayTeamId == widget.teamStanding.teamId;
        }).toList();

        if (teamMatches.isEmpty) {
          return Center(child: Text(tr(context, 'Nessuna partita disponibile')));
        }

        // Split by status
        var upcoming = teamMatches.where((m) => m.isScheduled || m.isLive).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        if (upcoming.isEmpty) {
          upcoming = _getMockUpcomingMatches();
        }

        final results = teamMatches.where((m) => m.isFinished).toList()
          ..sort((a, b) => b.date.compareTo(a.date));

        // Group results by month (Italian names)
        final isEn = Localizations.localeOf(context).languageCode == 'en';
        final monthNames = isEn 
            ? ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
            : ['Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno', 'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'];
        final groupedResults = <String, List<SoccerMatch>>{};
        for (final m in results) {
          final key = '${monthNames[m.date.month - 1]} ${m.date.year}';
          groupedResults.putIfAbsent(key, () => []).add(m);
        }

        final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
        final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;
        final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;

        return CustomScrollView(
          slivers: [
            // ── Form strip ──
            SliverToBoxAdapter(child: _buildMatchFormStrip(context, results, isDark, tx, lb, cardBg)),

            // ── Upcoming matches ──
            if (upcoming.isNotEmpty) ...[
              SliverToBoxAdapter(child: _matchSectionHeader(
                context, _localizeTeam(context, 'Prossime Partite'), Icons.event_rounded, isDark, upcoming.length)),
              SliverList(delegate: SliverChildBuilderDelegate(
                (ctx, i) => _buildUpcomingMatchItem(upcoming[i], theme, isDark),
                childCount: upcoming.length,
              )),
            ],

            // ── Results by month ──
            if (results.isNotEmpty) ...[
              SliverToBoxAdapter(child: _matchSectionHeader(
                context, _localizeTeam(context, 'Risultati'), Icons.emoji_events_rounded, isDark, results.length)),
              for (final entry in groupedResults.entries) ...[
                SliverToBoxAdapter(child: _monthDivider(entry.key, isDark)),
                SliverList(delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _buildMatchItem(entry.value[i], theme, isDark),
                  childCount: entry.value.length,
                )),
              ],
            ],

            // Bottom padding
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        );
      },
    );
  }

  // ── Form strip: last 5 results ──
  // [FAV-team-form-filter] selettore filtro 5/10/20/Tutte
  Widget _buildFormLimitSelector(bool isDark, Color tx, Color lb, int totalMatches) {
    final bg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);
    Widget chip(String label, int? value) {
      final active = _formLimit == value;
      final disabled = value != null && totalMatches < value;
      return GestureDetector(
        onTap: disabled
            ? null
            : () => setState(() => _formLimit = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
          decoration: BoxDecoration(
            color: active
                ? (isDark ? const Color(0xFF1A1A1A) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: active
                ? [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: disabled
                      ? (isDark ? Colors.grey[700] : Colors.grey[400])
                      : (active ? tx : lb))),
        ),
      );
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          chip('5', 5),
          const SizedBox(width: 4),
          chip('10', 10),
          const SizedBox(width: 4),
          chip('20', 20),
          const SizedBox(width: 4),
          chip(_localizeTeam(context, 'Tutte'), null),
        ]),
      ),
    );
  }

  // [FAV-team-detail-form-section] usa TeamFormSection riusabile
  // (stesso widget di MatchFormTab pre-match per uniformita visiva)
  Widget _buildMatchFormStrip(BuildContext context, List<SoccerMatch> results,
      bool isDark, Color tx, Color lb, Color cardBg) {
    if (results.isEmpty) return const SizedBox.shrink();
    final teamName = widget.teamStanding.teamName;
    final divider =
        isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1);

    // Converto List<SoccerMatch> in List<Map<String, dynamic>> per uniformita
    // con il formato accettato da TeamFormSection.
    final form = results.map((m) {
      final isHome = m.homeTeamName == teamName;
      final myScore = isHome ? m.homeScore : m.awayScore;
      final oppScore = isHome ? m.awayScore : m.homeScore;
      final opponent = isHome ? m.awayTeamName : m.homeTeamName;
      final result = myScore > oppScore
          ? 'W'
          : myScore == oppScore
              ? 'D'
              : 'L';
      return <String, dynamic>{
        'opponent': opponent,
        'score': '$myScore-$oppScore',
        'result': result,
        'venue': isHome ? 'Casa' : 'Trasferta',
        'comp': m.leagueName,
        'date':
            '${m.date.day.toString().padLeft(2, '0')}/${m.date.month.toString().padLeft(2, '0')}',
      };
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          // Selettore filtro (controlla _formLimit dello state padre)
          _buildFormLimitSelector(isDark, tx, lb, results.length),
          const SizedBox(height: 10),
          // Sezione Forma riusabile (header + dots + match list)
          TeamFormSection(
            teamName: teamName,
            form: form,
            formLimit: _formLimit,
            teamColor: const Color(0xFF4CAF50),
            cardBg: cardBg,
            tx: tx,
            lb: lb,
            divider: divider,
            opponentLogoUrl: (name) => _logos[name] ?? '',
            onMatchTap: (m) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MatchDetailScreen(match: m)),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Section header ──
  Widget _matchSectionHeader(BuildContext context, String title, IconData icon, bool isDark, int count) {
    final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 6),
      child: Row(children: [
        Icon(icon, size: 16, color: isDark ? Colors.white70 : Colors.grey[700]),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tx)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: lb)),
        ),
      ]),
    );
  }

  // ── Month divider ──
  Widget _monthDivider(String monthYear, bool isDark) {
    final lb = isDark ? Colors.grey[600]! : Colors.grey[500]!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(children: [
        Container(
          width: 3, height: 14,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(monthYear.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: lb, letterSpacing: 1.2)),
      ]),
    );
  }

  List<SoccerMatch> _getMockUpcomingMatches() {
    final t = widget.teamStanding;
    final baseDate = DateTime(2023, 6, 4);

    final opponents = [
      {'id': 492, 'name': 'Napoli', 'logo': 'https://media.api-sports.io/football/teams/492.png'},
      {'id': 505, 'name': 'Inter', 'logo': 'https://media.api-sports.io/football/teams/505.png'},
      {'id': 499, 'name': 'Atalanta', 'logo': 'https://media.api-sports.io/football/teams/499.png'},
    ];

    return List.generate(opponents.length, (i) {
      final opp = opponents[i];
      final isHome = i.isEven;
      final date = baseDate.add(Duration(days: 7 * i));
      final hour = i == 1 ? 18 : 20;
      final minute = i == 1 ? 0 : 45;

      return SoccerMatch(
        id: 90000 + i,
        date: DateTime(date.year, date.month, date.day, hour, minute),
        time: '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}',
        status: 'NS',
        venue: isHome ? 'Stadio Olimpico' : '',
        homeTeamId: isHome ? t.teamId : (opp['id'] as int),
        homeTeamName: isHome ? t.teamName : (opp['name'] as String),
        homeTeamLogo: isHome ? t.teamLogo : (opp['logo'] as String),
        awayTeamId: isHome ? (opp['id'] as int) : t.teamId,
        awayTeamName: isHome ? (opp['name'] as String) : t.teamName,
        awayTeamLogo: isHome ? (opp['logo'] as String) : t.teamLogo,
        homeScore: 0,
        awayScore: 0,
      );
    });
  }

  // ── Upcoming match card (no scores, with favorite + notification icons) ──

  Future<void> _showTeamMatchNotifSheet(SoccerMatch match, bool isDark) async {
    final matchId = match.id;
    final notifService = context.read<MatchNotificationPreferencesService>();
    var settings = notifService.getSettingsForMatch(matchId);
    final bg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final theme = Theme.of(context);

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
                        color: isOn ? color.withValues(alpha: isDark ? 0.12 : 0.06) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isOn
                              ? color.withValues(alpha: isDark ? 0.3 : 0.2)
                              : isDark ? Colors.white10 : Colors.grey[200]!,
                          width: isOn ? 1.5 : 1,
                        ),
                      ),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: isOn ? 0.15 : 0.08),
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
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, -5))],
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
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.notifications_active, color: theme.primaryColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${match.homeTeamName} vs ${match.awayTeamName}',
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
                      notifTile('goals', Icons.sports_soccer, tr(context, 'Goal'), 'Notifica con marcatore e minuto', const Color(0xFF4CAF50)),
                      notifTile('penalties', Icons.gps_fixed, 'Rigori', 'Rigori assegnati, segnati e sbagliati', const Color(0xFFE91E63)),
                      notifTile('var', Icons.videocam, 'Decisioni VAR', 'Revisioni e decisioni arbitrali al VAR', const Color(0xFF2196F3)),
                      const SizedBox(height: 16),
                      sectionHeader('Tempi di gioco', Icons.timer),
                      notifTile('kickoff', Icons.play_circle_outline, 'Inizio tempo', "Calcio d'inizio 1° e 2° tempo", const Color(0xFF66BB6A)),
                      notifTile('halftime', Icons.pause_circle_outline, 'Fine primo tempo', "Risultato parziale all'intervallo", const Color(0xFFFFA726)),
                      notifTile('fulltime', Icons.stop_circle_outlined, 'Fischio finale', 'Risultato finale della partita', const Color(0xFFEF5350)),
                      const SizedBox(height: 16),
                      sectionHeader('Disciplina', Icons.style),
                      notifTile('yellowCards', Icons.square_rounded, tr(context, 'Cartellini gialli'), tr(context, 'Ammonizioni e doppi gialli'), const Color(0xFFFFCA28)),
                      notifTile('redCards', Icons.square_rounded, tr(context, 'Cartellini rossi'), tr(context, 'Espulsioni dirette e per doppia ammonizione'), const Color(0xFFE53935)),
                      const SizedBox(height: 16),
                      sectionHeader('Eventi di gioco', Icons.analytics),
                      notifTile('substitutions', Icons.swap_horiz, 'Sostituzioni', 'Cambi effettuati da entrambe le squadre', const Color(0xFF42A5F5)),
                      notifTile('corners', Icons.flag, tr(context, "Calci d'angolo"), tr(context, 'Corner assegnati'), const Color(0xFF26A69A)),
                      notifTile('offsides', Icons.front_hand, tr(context, 'Fuorigioco'), tr(context, 'Posizioni di fuorigioco'), const Color(0xFF7E57C2)),
                      notifTile('shotsOnTarget', Icons.gps_not_fixed, tr(context, 'Tiri in porta'), 'Tiri nello specchio della porta', const Color(0xFFFF7043)),
                      notifTile('fouls', Icons.warning_amber, tr(context, 'Falli'), tr(context, 'Falli commessi'), const Color(0xFF8D6E63)),
                    ]),
                  ),
                ),
              ]),
            );
          },
        );
      },
    );
    setState(() {});
  }

  Widget _buildUpcomingMatchItem(SoccerMatch match, ThemeData theme, bool isDark) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[600]! : Colors.grey[500]!;
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final accent = theme.primaryColor;

    Widget teamLogo(String? url, String name) {
      if (url != null && url.isNotEmpty) {
        return CachedNetworkImage(imageUrl: url, width: 20, height: 20,
            errorWidget: (_, __, ___) => _textLogo(name, isDark));
      }
      return _textLogo(name, isDark);
    }

    return GestureDetector(
      onTap: () {
        _haptic.lightImpact();
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MatchDetailScreen(match: match),
        ));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.08)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 3.5,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
                ),
              ),
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(DateFormat('dd/MM').format(match.date),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: lb)),
                    const SizedBox(height: 2),
                    Text(match.time,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent)),
                  ],
                ),
              ),
              Container(width: 0.5, color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.12)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(children: [
                        teamLogo(match.homeTeamLogo, match.homeTeamName),
                        const SizedBox(width: 8),
                        Expanded(child: Text(match.homeTeamName,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tx))),
                      ]),
                      const SizedBox(height: 6),
                      Row(children: [
                        teamLogo(match.awayTeamLogo, match.awayTeamName),
                        const SizedBox(width: 8),
                        Expanded(child: Text(match.awayTeamName,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tx))),
                      ]),
                    ],
                  ),
                ),
              ),
              // ── Heart (FavoritesService) + Bell (notification sheet) ──
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Heart ──
                    Builder(builder: (ctx) {
                      final favSvc = ctx.read<FavoritesService>();
                      final isFav = favSvc.isMatchFavorite(match.id);
                      return GestureDetector(
                        onTap: () {
                          _haptic.lightImpact();
                          final wasFav = favSvc.isMatchFavorite(match.id);
                          favSvc.toggleMatchFavorite(match.id, status: match.status);
                          if (!wasFav) {
                            favSvc.storeMatchDisplayData(match.id, {
                              'homeTeam': match.homeTeamName, 'awayTeam': match.awayTeamName,
                              'homeLogo': match.homeTeamLogo ?? '', 'awayLogo': match.awayTeamLogo ?? '',
                              'homeId': match.homeTeamId, 'awayId': match.awayTeamId,
                              'homeScore': match.homeScore, 'awayScore': match.awayScore,
                              'status': match.status, 'date': match.time, 'time': match.time,
                              'league': match.leagueName ?? 'Serie A', 'round': '',
                            });
                          }
                          (ctx as Element).markNeedsBuild();
                        },
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 20,
                          color: isFav ? const Color(0xFFE53935) : lb,
                        ),
                      );
                    }),
                    const SizedBox(width: 12),
                    // ── Bell ──
                    Builder(builder: (bellCtx) {
                      final notifSvc = bellCtx.read<MatchNotificationPreferencesService>();
                      final settings = notifSvc.getSettingsForMatch(match.id);
                      final hasNotif = settings.enabled && (settings.notifyHomeGoals || settings.notifyMatchStart);
                      return GestureDetector(
                        onTap: () {
                          _haptic.lightImpact();
                          _showTeamMatchNotifSheet(match, isDark);
                        },
                        child: Icon(
                          hasNotif ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                          size: 20,
                          color: hasNotif ? const Color(0xFF4CAF50) : lb,
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchItem(SoccerMatch match, ThemeData theme, bool isDark) {
    final teamName = widget.teamStanding.teamName;
    final isHome = match.homeTeamName == teamName;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[600]! : Colors.grey[500]!;
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;

    // Risultato per la squadra seguita
    String? resultLetter;
    Color resultColor = Colors.grey;
    if (match.isFinished) {
      final myScore = isHome ? match.homeScore : match.awayScore;
      final oppScore = isHome ? match.awayScore : match.homeScore;
      if (myScore > oppScore) {
        resultLetter = 'V'; resultColor = const Color(0xFF4CAF50);
      } else if (myScore == oppScore) {
        resultLetter = 'P'; resultColor = const Color(0xFF9E9E9E);
      } else {
        resultLetter = 'S'; resultColor = const Color(0xFFE53935);
      }
    }

    final homeWon = match.homeScore > match.awayScore;
    final awayWon = match.awayScore > match.homeScore;
    final isDraw = match.homeScore == match.awayScore;

    Widget teamLogo(String? url, String name) {
      if (url != null && url.isNotEmpty) {
        return CachedNetworkImage(imageUrl: url, width: 20, height: 20,
            errorWidget: (_, __, ___) => _textLogo(name, isDark));
      }
      return _textLogo(name, isDark);
    }

    return GestureDetector(
      onTap: () {
        _haptic.lightImpact();
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MatchDetailScreen(match: match),
        ));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.08)),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // ── Barra laterale colorata ──
              Container(
                width: 3.5,
                decoration: BoxDecoration(
                  color: match.isFinished ? resultColor : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                  ),
                ),
              ),
              // ── Data + Stato ──
              Container(
                width: 52,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(DateFormat('dd/MM').format(match.date),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: lb)),
                    const SizedBox(height: 2),
                    Text(
                      match.isFinished ? 'FINE' : (match.isLive ? '${match.elapsed}\'' : match.time),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: match.isLive ? const Color(0xFFE53935) : lb.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Divider verticale ──
              Container(width: 0.5, color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.12)),
              // ── Squadre ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Home team row
                      Row(children: [
                        teamLogo(match.homeTeamLogo, match.homeTeamName),
                        const SizedBox(width: 8),
                        Expanded(child: Text(match.homeTeamName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: homeWon || isDraw ? FontWeight.w600 : FontWeight.w400,
                              color: homeWon ? tx : (awayWon ? lb : tx),
                            ))),
                        const SizedBox(width: 8),
                        Text('${match.homeScore}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: homeWon ? FontWeight.w800 : FontWeight.w500,
                              color: homeWon ? tx : lb,
                            )),
                      ]),
                      const SizedBox(height: 6),
                      // Away team row
                      Row(children: [
                        teamLogo(match.awayTeamLogo, match.awayTeamName),
                        const SizedBox(width: 8),
                        Expanded(child: Text(match.awayTeamName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: awayWon || isDraw ? FontWeight.w600 : FontWeight.w400,
                              color: awayWon ? tx : (homeWon ? lb : tx),
                            ))),
                        const SizedBox(width: 8),
                        Text('${match.awayScore}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: awayWon ? FontWeight.w800 : FontWeight.w500,
                              color: awayWon ? tx : lb,
                            )),
                      ]),
                    ],
                  ),
                ),
              ),
              // ── Badge risultato ──
              if (resultLetter != null)
                Container(
                  width: 34,
                  margin: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: Container(
                      width: 26, height: 26,
                      decoration: BoxDecoration(
                        color: resultColor.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(child: Text(resultLetter,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: resultColor))),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textLogo(String name, bool isDark) {
    return Container(
      width: 20, height: 20,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Center(child: Text(name.isNotEmpty ? name[0] : '?',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white54 : Colors.grey[600]))),
    );
  }

  Widget _buildStatisticsTab(ThemeData theme, bool isDark, S s) {
    final t = widget.teamStanding;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final accent = theme.primaryColor;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      child: Column(
        children: [
          // ── Win Rate Donut ──
          _premiumCard(cardBg, isDark, child: Column(children: [
            Row(children: [
              Icon(Icons.pie_chart_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(_localizeTeam(context, 'Rendimento'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
            ]),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _circularStat(S.of(context)!.vittorie, t.wins, t.played, const Color(0xFF4CAF50), tx, lb),
                _circularStat(S.of(context)!.pareggi, t.draws, t.played, const Color(0xFFFFA726), tx, lb),
                _circularStat(S.of(context)!.sconfitte, t.losses, t.played, const Color(0xFFE53935), tx, lb),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar V-P-S
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(children: [
                if (t.played > 0) ...[
                  Expanded(flex: t.wins.clamp(1, 100), child: Container(height: 6, color: const Color(0xFF4CAF50))),
                  Expanded(flex: t.draws.clamp(1, 100), child: Container(height: 6, color: const Color(0xFFFFA726))),
                  Expanded(flex: t.losses.clamp(1, 100), child: Container(height: 6, color: const Color(0xFFE53935))),
                ] else
                  Expanded(child: Container(height: 6, color: Colors.grey.withValues(alpha: 0.2))),
              ]),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${t.played} partite giocate', style: TextStyle(fontSize: 11, color: lb)),
                Text('${(t.played > 0 ? (t.wins / t.played * 100) : 0).toStringAsFixed(0)}% vittorie', 
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4CAF50))),
              ],
            ),
          ])),
          const SizedBox(height: 10),

          // ── Gol ──
          _premiumCard(cardBg, isDark, child: Column(children: [
            Row(children: [
              Icon(Icons.sports_soccer_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(tr(context, 'Gol'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
            ]),
            const SizedBox(height: 16),
            _barStatRow(tr(context, 'Gol fatti'), t.goalsFor, 100, const Color(0xFF4CAF50), tx, lb, isDark),
            const SizedBox(height: 10),
            _barStatRow(tr(context, 'Gol subiti'), t.goalsAgainst, 100, const Color(0xFFE53935), tx, lb, isDark),
            const SizedBox(height: 10),
            _barStatRow(_localizeTeam(context, 'Differenza'), t.goalsDiff, 60, t.goalsDiff >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935), tx, lb, isDark),
          ])),
          const SizedBox(height: 10),

          // ── Andamento stagionale ──
          _premiumCard(cardBg, isDark, child: Column(children: [
            Row(children: [
              Icon(Icons.show_chart_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(_localizeTeam(context, 'Andamento Stagionale'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              height: 160,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: CustomPaint(
                  size: Size(t.played * 16.0 + 40, 160),
                  painter: MatchdayBarPainter(
                    isDark: isDark,
                    matchdays: generateMockMatchdays(t.wins, t.draws, t.losses, t.goalsFor, t.goalsAgainst),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _resultLegendDot(formInitial(context, 'W'), const Color(0xFF4CAF50)),
              const SizedBox(width: 10),
              _resultLegendDot(formInitial(context, 'D'), const Color(0xFFF9A825)),
              const SizedBox(width: 10),
              _resultLegendDot(formInitial(context, 'L'), const Color(0xFFE53935)),
              const SizedBox(width: 20),
              _chartLegend(tr(context, 'Gol fatti ↑'), const Color(0xFF4CAF50)),
              const SizedBox(width: 10),
              _chartLegend(tr(context, 'Gol subiti ↓'), const Color(0xFFE53935)),
            ]),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(_localizeTeam(context, 'Media gol/partita'), style: TextStyle(fontSize: 12, color: lb)),
                Text((t.played > 0 ? t.goalsFor / t.played : 0).toStringAsFixed(2), 
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tx)),
              ]),
            ),
          ])),
          const SizedBox(height: 10),

          // ── Punti ──
          _premiumCard(cardBg, isDark, child: Column(children: [
            Row(children: [
              Icon(Icons.star_rounded, size: 16, color: accent),
              const SizedBox(width: 8),
              Text(S.of(context)!.punti, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _bigStat('Totale', '${t.points}', accent, tx, lb),
              _bigStat(tr(context, 'Punti/partita'), (t.played > 0 ? t.points / t.played : 0).toStringAsFixed(2), const Color(0xFF42A5F5), tx, lb),
              _bigStat(tr(context, 'Posizione'), '${t.position}°', const Color(0xFFFFA726), tx, lb),
            ]),
          ])),
        ],
      ),
    );
  }

  Widget _premiumCard(Color bg, bool isDark, {required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1)),
        boxShadow: isDark ? null : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _chartLegend(String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
    ]);
  }

  Widget _resultLegendDot(String label, Color color) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 9, height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey[500])),
    ]);
  }

  Widget _circularStat(String label, int value, int total, Color color, Color tx, Color lb) {
    final pct = total > 0 ? value / total : 0.0;
    return Column(children: [
      SizedBox(
        width: 56, height: 56,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 56, height: 56,
            child: CircularProgressIndicator(
              value: pct,
              strokeWidth: 5,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          Text('$value', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: tx)),
        ]),
      ),
      const SizedBox(height: 6),
      Text(label, style: TextStyle(fontSize: 10, color: lb)),
    ]);
  }

  Widget _barStatRow(String label, int value, int maxVal, Color color, Color tx, Color lb, bool isDark) {
    final pct = maxVal > 0 ? (value.abs() / maxVal).clamp(0.0, 1.0) : 0.0;
    return Row(children: [
      SizedBox(width: 90, child: Text(label, style: TextStyle(fontSize: 12, color: lb))),
      Expanded(child: Stack(children: [
        Container(height: 8, decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
        )),
        FractionallySizedBox(
          widthFactor: pct,
          child: Container(height: 8, decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          )),
        ),
      ])),
      const SizedBox(width: 10),
      SizedBox(width: 35, child: Text('$value', 
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tx), textAlign: TextAlign.right)),
    ]);
  }

  Widget _bigStat(String label, String value, Color accent, Color tx, Color lb) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: accent)),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10, color: lb)),
    ]);
  }


  Widget _buildPlayersTab(ThemeData theme, bool isDark, S s) {
    return FutureBuilder<List<Player>>(
      future: _playersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Show mock players when API data unavailable
          return _buildMockPlayersTab(isDark);
        }
        final players = snapshot.data!;
        final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
        final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;
        final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;

        // Raggruppa per ruolo
        final groups = <String, List<Player>>{};
        final roleOrder = ['Portiere', 'Difensore', 'Centrocampista', 'Attaccante'];
        for (final p in players) {
          groups.putIfAbsent(p.position, () => []).add(p);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
          children: [
            for (final role in roleOrder)
              if (groups[role] != null) ...[
                // Role header
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _roleColor(role).withValues(alpha: isDark ? 0.15 : 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_localizeTeam(context, role.toUpperCase()),
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, 
                              color: _roleColor(role), letterSpacing: 0.5)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Container(height: 0.5, color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.15))),
                    const SizedBox(width: 8),
                    Text('${groups[role]!.length}', style: TextStyle(fontSize: 11, color: lb)),
                  ]),
                ),
                // Players
                ...groups[role]!.map((p) => _buildPlayerRow(p, cardBg, tx, lb, isDark, theme)),
              ],
          ],
        );
      },
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Portiere': return const Color(0xFFFFA726);
      case 'Difensore': return const Color(0xFF42A5F5);
      case 'Centrocampista': return const Color(0xFF66BB6A);
      case 'Attaccante': return const Color(0xFFEF5350);
      default: return Colors.grey;
    }
  }

  Widget _buildPlayerRow(Player p, Color cardBg, Color tx, Color lb, bool isDark, ThemeData theme) {
    final roleColor = _roleColor(p.position);
    final totalMatches = widget.teamStanding.played;
    final apps = p.appearances ?? 0;
    final appPct = totalMatches > 0 ? (apps / totalMatches).clamp(0.0, 1.0) : 0.0;
    final jerseyNum = _getJerseyNumber(p.name, widget.teamStanding.teamName);

    return GestureDetector(
      onTap: () {
        _haptic.lightImpact();
        final llp = LocalLineupPlayer(
          name: p.name,
          number: jerseyNum,
          position: p.position == 'Portiere' ? 'GK' 
              : p.position == 'Difensore' ? 'CB'
              : p.position == 'Centrocampista' ? 'CM'
              : 'LW',
          rating: p.rating > 0 ? p.rating : 6.5,
          goals: p.goals ?? 0,
          assists: p.assists ?? 0,
          shots: 0, shotsOnTarget: 0,
          passes: 0, passesCompleted: 0,
          tackles: 0, tacklesWon: 0, interceptions: 0, clearances: 0, recoveries: 0, ballsLost: 0,
          minutesPlayed: 90,
          xG: 0.0, xA: 0.0,
          touches: 40,
          keyPasses: 0, crosses: 0, crossesCompleted: 0,
          duelsTotal: 0, duelsWon: 0,
          aerialTotal: 0, aerialWon: 0,
          fouls: 0, foulsWon: 0,
          yellowCards: p.yellowCards ?? 0,
          redCards: p.redCards ?? 0,
          offsides: 0,
          dribbles: 0, dribblesSuccessful: 0,
        );
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MatchPlayerProfileScreen(
            player: llp,
            teamName: widget.teamStanding.teamName,
            teamColor: theme.primaryColor,
          ),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.08)),
        ),
        child: Row(children: [
          // ── Avatar ──
          if (p.photo != null)
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: CachedNetworkImage(imageUrl: p.photo!, width: 40, height: 40, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _playerNumberAvatar(jerseyNum, roleColor, isDark)),
                ),
                Positioned(
                  bottom: -2, right: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: roleColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: cardBg, width: 1.5),
                    ),
                    child: Text('$jerseyNum', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
              ],
            )
          else
            _playerNumberAvatar(jerseyNum, roleColor, isDark),
          const SizedBox(width: 12),
          // ── Name + appearances ──
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tx)),
              const SizedBox(height: 4),
              Row(children: [
                Text('$apps', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: roleColor)),
                Text('/$totalMatches', style: TextStyle(fontSize: 9, color: lb)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 70,
                  height: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: appPct,
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(roleColor.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
              ]),
            ],
          )),
          // ── Stats badges ──
          if ((p.goals ?? 0) > 0)
            _playerStatBadge('⚽', '${p.goals}', tx, isDark),
          if ((p.assists ?? 0) > 0)
            _playerStatBadge('🅰', '${p.assists}', tx, isDark),
          if ((p.yellowCards ?? 0) > 0)
            _playerStatBadge('', '${p.yellowCards}', tx, isDark, icon: Icons.square_rounded, iconColor: const Color(0xFFF9A825), iconSize: 10),
          if ((p.redCards ?? 0) > 0)
            _playerStatBadge('', '${p.redCards}', tx, isDark, icon: Icons.square_rounded, iconColor: const Color(0xFFE53935), iconSize: 10),
          // ── Rating ──
          if (p.rating > 0)
            Container(
              margin: const EdgeInsets.only(left: 6),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: _ratingColor(p.rating).withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(p.rating.toStringAsFixed(1),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _ratingColor(p.rating))),
            ),
        ]),
      ),
    );
  }

  Widget _playerStatBadge(String emoji, String value, Color tx, bool isDark, {IconData? icon, Color? iconColor, double iconSize = 12}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      margin: const EdgeInsets.only(right: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null)
          Icon(icon, size: iconSize, color: iconColor)
        else
          Text(emoji, style: const TextStyle(fontSize: 10)),
        const SizedBox(width: 2),
        Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tx)),
      ]),
    );
  }

  int _getJerseyNumber(String playerName, String teamName) {
    // Real Serie A 2022-23 jersey numbers
    const jerseys = {
      // Lazio
      'Provedel': 1, 'Marusic': 77, 'Romagnoli': 13, 'Patric': 4,
      'Milinkovic-Savic': 21, 'Luis Alberto': 10, 'Cataldi': 32,
      'Immobile': 17, 'Felipe Anderson': 7, 'Pedro': 9, 'Zaccagni': 20,
      // Napoli
      'Osimhen': 9, 'Kvaratskhelia': 77, 'Lobotka': 68, 'Zielinski': 20,
      'Kim': 3, 'Di Lorenzo': 22, 'Meret': 1, 'Anguissa': 99,
      'Politano': 21, 'Rrahmani': 13, 'Mario Rui': 6,
      // Milan
      'Maignan': 16, 'Hernandez': 19, 'Tomori': 23, 'Kalulu': 20,
      'Tonali': 8, 'Bennacer': 4, 'Leao': 17, 'Giroud': 9,
      'Diaz': 10, 'Calabria': 2, 'Kjaer': 24,
      // Inter
      'Onana': 24, 'Bastoni': 95, 'Barella': 23, 'Lautaro': 10,
      'Calhanoglu': 20, 'Dimarco': 32, 'Dumfries': 2, 'Mkhitaryan': 22,
      'Dzeko': 9, 'Skriniar': 37, 'Darmian': 36,
      // Juventus
      'Szczesny': 1, 'Bremer': 3, 'Locatelli': 27, 'Rabiot': 25,
      'Vlahovic': 9, 'Chiesa': 7, 'Kostic': 17, 'Cuadrado': 11,
      'Di Maria': 22, 'Bonucci': 19, 'Danilo': 6,
      // Roma
      'Rui Patricio': 1, 'Smalling': 6, 'Mancini': 23, 'Pellegrini': 7,
      'Dybala': 21, 'Abraham': 9, 'Spinazzola': 37, 'Cristante': 4,
      'Zalewski': 59, 'Ibanez': 3, 'Belotti': 11,
      // Atalanta
      'Musso': 1, 'Toloi': 2, 'Demiral': 28, 'Scalvini': 42,
      'Koopmeiners': 7, 'Ederson': 13, 'Lookman': 11, 'Muriel': 9,
      'Zapata': 91, 'Hateboer': 33, 'Maehle': 5,
      // Fiorentina
      'Terracciano': 1, 'Milenkovic': 4, 'Quarta': 28, 'Biraghi': 3,
      'Amrabat': 34, 'Bonaventura': 5, 'Gonzalez': 10, 'Jovic': 9,
      'Kouame': 99, 'Castrovilli': 10, 'Dodò': 2,
      // Bologna
      'Skorupski': 28, 'Posch': 22, 'Lucumi': 26, 'Beukema': 5,
      'Ferguson': 19, 'Aebischer': 20, 'Orsolini': 7, 'Arnautovic': 9,
      'Zirkzee': 11, 'Ndoye': 17, 'Saelemaekers': 10,
      // Torino
      'Milinkovic': 32, 'Rodriguez': 13, 'Buongiorno': 4, 'Djidji': 26,
      'Ricci': 28, 'Lukic': 10, 'Vlasic': 14, 'Radonjic': 49,
      'Sanabria': 9, 'Bellanova': 12, 'Lazaro': 19,
      // Monza
      'Di Gregorio': 16, 'Marlon': 5, 'Izzo': 25, 'Carlos Augusto': 30,
      'Pessina': 31, 'Sensi': 12, 'Barberis': 32, 'Caprari': 10,
      'Mota': 47, 'Colpani': 28, 'Ciurria': 14,
      // Sassuolo
      'Consigli': 47, 'Ferrari': 31, 'Erlic': 5, 'Rogerio': 3,
      'Frattesi': 16, 'Lopez': 8, 'Thorstvedt': 28, 'Berardi': 25,
      'Pinamonti': 19, 'Lauriente': 7, 'Traore': 11,
    };

    // Check exact match
    if (jerseys.containsKey(playerName)) return jerseys[playerName]!;

    // Check partial match (last name)
    for (final entry in jerseys.entries) {
      if (playerName.contains(entry.key) || entry.key.contains(playerName)) {
        return entry.value;
      }
    }

    // Deterministic fallback based on name hash
    final hash = playerName.hashCode.abs();
    return (hash % 40) + 1;
  }


  Widget _playerNumberAvatar(int number, Color roleColor, bool isDark) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [roleColor.withValues(alpha: 0.25), roleColor.withValues(alpha: 0.1)],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: roleColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Center(child: Text('$number',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: roleColor))),
    );
  }

  Color _ratingColor(double r) {
    if (r >= 7.5) return const Color(0xFF4CAF50);
    if (r >= 7.0) return const Color(0xFF8BC34A);
    if (r >= 6.5) return const Color(0xFFFFA726);
    if (r >= 6.0) return const Color(0xFFFF7043);
    return const Color(0xFFE53935);
  }

  String _formTooltipText(String teamName, String result, int index) {
    const opponents = ['Juventus', 'Milan', 'Inter', 'Napoli', 'Roma', 'Lazio', 'Atalanta', 'Bologna', 'Fiorentina', 'Torino'];
    final opp = opponents[(teamName.hashCode.abs() + index) % opponents.length];
    final actual = opp == teamName ? 'Monza' : opp;
    final isHome = index % 2 == 0;
    String score;
    if (result == 'W') { score = isHome ? '2:0' : '0:1'; }
    else if (result == 'D') { score = '1:1'; }
    else { score = isHome ? '0:2' : '1:3'; }
    final home = isHome ? teamName : actual;
    final away = isHome ? actual : teamName;
    final day = 28 - index * 7;
    final month = day > 0 ? '03' : '02';
    final d = day > 0 ? day : day + 28;
    return '$score ($home - $away)\n${d.toString().padLeft(2, "0")}.$month.2024';
  }

  void _navigateToFormMatch(BuildContext context, String teamName, String result, int index) {
    const opponents = ['Juventus', 'Milan', 'Inter', 'Napoli', 'Roma', 'Lazio', 'Atalanta', 'Bologna', 'Fiorentina', 'Torino'];
    final opp = opponents[(teamName.hashCode.abs() + index) % opponents.length];
    final actual = opp == teamName ? 'Monza' : opp;
    final isHome = index % 2 == 0;
    int hs, as_;
    if (result == 'W') { hs = isHome ? 2 : 0; as_ = isHome ? 0 : 1; }
    else if (result == 'D') { hs = 1; as_ = 1; }
    else { hs = isHome ? 0 : 1; as_ = isHome ? 2 : 3; }
    if (!isHome) { final tmp = hs; hs = as_; as_ = tmp; }
    final home = isHome ? teamName : actual;
    final away = isHome ? actual : teamName;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => MatchDetailScreen(
      match: SoccerMatch(id: (teamName + actual + index.toString()).hashCode.abs(),
        date: DateTime.now(), time: '20:45', status: 'FT', venue: '',
        homeTeamId: 0, awayTeamId: 0, homeTeamName: home, awayTeamName: away,
        homeScore: hs, awayScore: as_, leagueName: 'Serie A', season: 2023, round: 'Giornata ${35 - index}'),
    )));
  }

  Widget _buildMockPlayersTab(bool isDark) {
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final divider = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1);
    final teamName = widget.teamStanding.teamName;
    
    final mockRosters = <String, Map<String, List<Map<String, dynamic>>>>{
      'default': {
        'Portiere': [{'name': 'GK 1', 'num': 1}, {'name': 'GK 2', 'num': 12}],
        'Difensore': [{'name': 'DEF 1', 'num': 2}, {'name': 'DEF 2', 'num': 3}, {'name': 'DEF 3', 'num': 4}, {'name': 'DEF 4', 'num': 5}],
        'Centrocampista': [{'name': 'MID 1', 'num': 6}, {'name': 'MID 2', 'num': 8}, {'name': 'MID 3', 'num': 10}],
        'Attaccante': [{'name': 'ATT 1', 'num': 7}, {'name': 'ATT 2', 'num': 9}, {'name': 'ATT 3', 'num': 11}],
      },
    };

    final roster = mockRosters[teamName] ?? mockRosters['default']!;
    final roleOrder = ['Portiere', 'Difensore', 'Centrocampista', 'Attaccante'];

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
          ),
          child: Row(children: [
            const Icon(Icons.info_outline, size: 16, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(tr(context, 'Rosa provvisoria - dati API non disponibili'),
              style: TextStyle(fontSize: 12, color: Colors.orange[700]))),
          ]),
        ),
        for (final role in roleOrder)
          if (roster[role] != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _roleColor(role).withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(tr(context, role), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _roleColor(role))),
                ),
                const SizedBox(width: 8),
                Text('${roster[role]!.length}', style: TextStyle(fontSize: 12, color: lb)),
              ]),
            ),
            ...roster[role]!.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: divider),
              ),
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: _roleColor(role).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(color: _roleColor(role).withValues(alpha: 0.3)),
                  ),
                  child: Center(child: Text('${p['num']}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _roleColor(role)))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(p['name'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tx))),
                Icon(Icons.chevron_right, size: 16, color: lb),
              ]),
            )),
          ],
      ],
    );
  }

  Widget _buildInfoTab(ThemeData theme, bool isDark, S s) {
    final t = widget.teamStanding;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[500]! : Colors.grey[600]!;
    final cardBg = isDark ? const Color(0xFF1A1A2E) : Colors.white;
    final accent = theme.primaryColor;
    final divider = isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1);

    // Colore posizione
    Color posColor;
    String posLabel;
    if (t.position <= 4) { posColor = const Color(0xFF4CAF50); posLabel = tr(context, 'Zona Champions League'); }
    else if (t.position <= 6) { posColor = const Color(0xFF42A5F5); posLabel = tr(context, 'Zona Europa League'); }
    else if (t.position <= 7) { posColor = const Color(0xFFFFA726); posLabel = tr(context, 'Zona Conference League'); }
    else if (t.position >= 18) { posColor = const Color(0xFFE53935); posLabel = tr(context, 'Zona Retrocessione'); }
    else { posColor = Colors.grey; posLabel = ''; }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      child: Column(children: [
        // ── Competizione ──
        _premiumCard(cardBg, isDark, child: Column(children: [
          Row(children: [
            Icon(Icons.emoji_events_rounded, size: 16, color: accent),
            const SizedBox(width: 8),
            Text(_localizeTeam(context, 'Competizione'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          ]),
          const SizedBox(height: 14),
          _infoTile(tr(context, 'Campionato'), 'Serie A', Icons.stadium_rounded, tx, lb, isDark),
          Divider(height: 1, color: divider),
          _infoTile(tr(context, 'Stagione'), '2022/23', Icons.calendar_today_rounded, tx, lb, isDark),
          Divider(height: 1, color: divider),
          _infoTile(tr(context, 'Giornate'), '38', Icons.format_list_numbered_rounded, tx, lb, isDark),
        ])),
        const SizedBox(height: 10),

        // ── Informazioni club ──
        _premiumCard(cardBg, isDark, child: Column(children: [
          Row(children: [
            Icon(Icons.info_outline_rounded, size: 16, color: accent),
            const SizedBox(width: 8),
            Text(_localizeTeam(context, 'Informazioni Club'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          ]),
          const SizedBox(height: 14),
          _infoTile(_localizeTeam(context, 'Fondazione'), _getTeamFounded(t.teamName), Icons.history_rounded, tx, lb, isDark),
          Divider(height: 1, color: divider),
          GestureDetector(
            onTap: () {
              final coachName = _getTeamCoach(t.teamName);
              final coachData = _getCoachMockData(coachName, t.teamName);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => CoachProfileScreen(
                  coachName: coachName,
                  teamName: t.teamName,
                  teamColor: Theme.of(context).primaryColor,
                  data: coachData,
                ),
              ));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.person_rounded, size: 16, color: lb),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(_localizeTeam(context, 'Allenatore'), style: TextStyle(fontSize: 13, color: lb))),
                Text(_getTeamCoach(t.teamName), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tx)),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, size: 16, color: lb),
              ]),
            ),
          ),
          Divider(height: 1, color: divider),
          _infoTile(tr(context, 'Stadio'), _getTeamStadium(t.teamName), Icons.stadium_rounded, tx, lb, isDark),
          Divider(height: 1, color: divider),
          _infoTile(tr(context, 'Capienza'), _getTeamCapacity(t.teamName), Icons.people_rounded, tx, lb, isDark),
          Divider(height: 1, color: divider),
          _infoTile(tr(context, 'Città'), _getTeamCity(t.teamName), Icons.location_city_rounded, tx, lb, isDark),
          Divider(height: 1, color: divider),
          _infoTile(tr(context, 'Paese'), _localizeTeam(context, 'Italia'), Icons.flag_rounded, tx, lb, isDark),
        ])),
        const SizedBox(height: 10),

        // ── Posizione in classifica ──
        _premiumCard(cardBg, isDark, child: Column(children: [
          Row(children: [
            Icon(Icons.leaderboard_rounded, size: 16, color: accent),
            const SizedBox(width: 8),
            Text(_localizeTeam(context, 'Classifica'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          ]),
          const SizedBox(height: 14),
          // Posizione grande
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: posColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: posColor.withValues(alpha: 0.3), width: 2),
                ),
                child: Center(child: Text('${t.position}°',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: posColor))),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (posLabel.isNotEmpty) Text(posLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: posColor)),
                Text('${t.points} ${tr(context, 'punti')} ${tr(context, 'in')} ${t.played} ${tr(context, 'partite')}',
                    style: TextStyle(fontSize: 12, color: lb)),
              ]),
            ]),
          ),
          // Punti per partita
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _miniStat(tr(context, 'Punti/partita'), (t.played > 0 ? t.points / t.played : 0).toStringAsFixed(2), tx, lb),
              Container(width: 1, height: 28, color: divider),
              _miniStat(tr(context, 'Gol/Partita'), (t.played > 0 ? t.goalsFor / t.played : 0).toStringAsFixed(2), tx, lb),
              Container(width: 1, height: 28, color: divider),
              _miniStat(tr(context, 'Subiti/partita'), (t.played > 0 ? t.goalsAgainst / t.played : 0).toStringAsFixed(2), tx, lb),
            ]),
          ),
        ])),
        const SizedBox(height: 10),

        // ── Forma recente ──
        _premiumCard(cardBg, isDark, child: Column(children: [
          Row(children: [
            Icon(Icons.trending_up_rounded, size: 16, color: accent),
            const SizedBox(width: 8),
            Text(_localizeTeam(context, 'Forma Recente'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
          ]),
          const SizedBox(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: (t.form ?? 'WDWWL').split('').asMap().entries.map((entry) {
              final fi = entry.key;
              final c = entry.value;
              Color bg; String letter;
              if (c == 'W') { bg = const Color(0xFF4CAF50); letter = 'V'; }
              else if (c == 'D') { bg = const Color(0xFF9E9E9E); letter = 'P'; }
              else { bg = const Color(0xFFE53935); letter = 'S'; }
              return GestureDetector(
                onTap: () => _navigateToFormMatch(context, widget.teamStanding.teamName, c, fi),
                child: Tooltip(
                  message: _formTooltipText(widget.teamStanding.teamName, c, fi),
                  decoration: BoxDecoration(color: const Color(0xFF1A1A2E), borderRadius: BorderRadius.circular(8)),
                  textStyle: const TextStyle(color: Colors.white, fontSize: 11),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Container(
                    width: 36, height: 36,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: bg.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: bg.withValues(alpha: 0.4)),
                    ),
                    child: Center(child: Text(letter,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: bg))),
                  ),
                ),
              );
            }).toList(),
          ),
        ])),
        const SizedBox(height: 10),

      ]),
    );
  }

  Widget _infoTile(String label, String value, IconData icon, Color tx, Color lb, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: lb),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: lb))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tx)),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color tx, Color lb) {
    return Column(children: [
      Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: tx)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 9, color: lb)),
    ]);
  }

  String _normalizeTeamName(String name) {
    const aliases = {
      'AC Milan': 'Milan',
      'A.C. Milan': 'Milan',
      'AS Roma': 'Roma',
      'A.S. Roma': 'Roma',
      'SSC Napoli': 'Napoli',
      'S.S.C. Napoli': 'Napoli',
      'S.S. Lazio': 'Lazio',
      'FC Internazionale': 'Inter',
      'Inter Milan': 'Inter',
      'Hellas Verona': 'Verona',
      'US Salernitana': 'Salernitana',
      'US Lecce': 'Lecce',
      'UC Sampdoria': 'Sampdoria',
      'Parma Calcio': 'Parma',
      'AC Monza': 'Monza',
    };
    return aliases[name] ?? name;
  }

  Map<String, dynamic> _getCoachMockData(String coachName, String teamName) {
    final coaches = <String, Map<String, dynamic>>{
      'Maurizio Sarri': {
        'nationality': '🇮🇹 Italiano',
        'age': 64,
        'born': '10 gennaio 1959',
        'formation': '4-3-3',
        'teamFull': 'S.S. Lazio',
        'seasonW': 14, 'seasonD': 7, 'seasonL': 6,
        'seasonGoalsFor': 42, 'seasonGoalsAgainst': 28,
        'style': 'Possesso palla, pressing alto, gioco verticale rapido',
        'philosophy': 'Il "Sarrismo" si basa su un calcio offensivo e spettacolare, con movimenti sincronizzati e transizioni veloci.',
        'career': <Map<String, String>>[
          {'team': 'Lazio', 'period': '2021-2023', 'trophy': ''},
          {'team': 'Juventus', 'period': '2019-2020', 'trophy': '🏆 Serie A'},
          {'team': 'Chelsea', 'period': '2018-2019', 'trophy': '🏆 Europa League'},
          {'team': 'Napoli', 'period': '2015-2018', 'trophy': ''},
          {'team': 'Empoli', 'period': '2012-2015', 'trophy': ''},
        ],
        'stats': <String, dynamic>{'matches': 27, 'winRate': 52, 'avgGoals': 1.56, 'cleanSheets': 8, 'avgPoints': 1.81},
      },
      'Stefano Pioli': {
        'nationality': '🇮🇹 Italiano',
        'age': 57,
        'born': '20 ottobre 1965',
        'formation': '4-2-3-1',
        'teamFull': 'A.C. Milan',
        'seasonW': 16, 'seasonD': 5, 'seasonL': 6,
        'seasonGoalsFor': 48, 'seasonGoalsAgainst': 26,
        'style': 'Transizioni rapide, pressing coordinato, gioco sulle fasce',
        'philosophy': 'Calcio pragmatico e moderno, con enfasi sulle ripartenze veloci e la solidità difensiva.',
        'career': <Map<String, String>>[
          {'team': 'Milan', 'period': '2019-2024', 'trophy': '🏆 Scudetto 2022'},
          {'team': 'Fiorentina', 'period': '2017-2019', 'trophy': ''},
          {'team': 'Inter', 'period': '2016-2017', 'trophy': ''},
          {'team': 'Lazio', 'period': '2014-2016', 'trophy': ''},
          {'team': 'Bologna', 'period': '2011-2014', 'trophy': ''},
        ],
        'stats': <String, dynamic>{'matches': 27, 'winRate': 59, 'avgGoals': 1.78, 'cleanSheets': 10, 'avgPoints': 1.96},
      },
    };
    return coaches[coachName] ?? <String, dynamic>{
      'nationality': '🇮🇹 Italiano',
      'age': 50,
      'born': '-',
      'formation': '4-3-3',
      'teamFull': teamName,
      'seasonW': 12, 'seasonD': 8, 'seasonL': 7,
      'seasonGoalsFor': 38, 'seasonGoalsAgainst': 32,
      'style': 'Gioco equilibrato',
      'philosophy': '-',
      'career': <Map<String, String>>[
        {'team': teamName, 'period': '2022-Presente', 'trophy': ''},
      ],
      'stats': <String, dynamic>{'matches': 27, 'winRate': 44, 'avgGoals': 1.41, 'cleanSheets': 6, 'avgPoints': 1.63},
    };
  }

  String _getTeamStadium(String teamName) {
    teamName = _normalizeTeamName(teamName);
    const stadiums = {
      'Inter': 'San Siro (Giuseppe Meazza)',
      'Milan': 'San Siro (Giuseppe Meazza)',
      'Juventus': 'Allianz Stadium',
      'Napoli': 'Stadio Diego Armando Maradona',
      'Roma': 'Stadio Olimpico',
      'Lazio': 'Stadio Olimpico',
      'Atalanta': 'Gewiss Stadium',
      'Bologna': 'Stadio Renato Dall\'Ara',
      'Fiorentina': 'Stadio Artemio Franchi',
      'Torino': 'Stadio Olimpico Grande Torino',
      'Verona': 'Stadio Marc\'Antonio Bentegodi',
      'Monza': 'U-Power Stadium',
      'Genoa': 'Stadio Luigi Ferraris',
      'Lecce': 'Stadio Via del Mare',
      'Udinese': 'Dacia Arena',
      'Empoli': 'Stadio Carlo Castellani',
      'Cagliari': 'Unipol Domus',
      'Frosinone': 'Stadio Benito Stirpe',
      'Sassuolo': 'Mapei Stadium',
      'Salernitana': 'Stadio Arechi',
    };
    return stadiums[teamName] ?? 'Stadio';
  }


  String _getTeamCapacity(String teamName) {
    teamName = _normalizeTeamName(teamName);
    const capacities = {
      'Napoli': '54.726',
      'Roma': '72.698',
      'Lazio': '72.698',
      'Inter': '75.923',
      'Milan': '75.923',
      'Juventus': '41.507',
      'Atalanta': '21.300',
      'Bologna': '36.462',
      'Fiorentina': '43.147',
      'Torino': '27.958',
      'Verona': '39.211',
      'Monza': '16.917',
      'Udinese': '25.144',
      'Sassuolo': '21.525',
      'Genoa': '36.600',
      'Lecce': '33.876',
      'Cagliari': '16.416',
      'Empoli': '16.284',
      'Frosinone': '16.227',
      'Salernitana': '37.245',
      'Sampdoria': '36.600',
      'Spezia': '11.466',
      'Cremonese': '20.641',
      'Parma': '22.352',
    };
    return capacities[teamName] ?? '-';
  }

  String _getTeamCity(String teamName) {
    teamName = _normalizeTeamName(teamName);
    const cities = {
      'Napoli': 'Napoli',
      'Roma': 'Roma',
      'Lazio': 'Roma',
      'Inter': 'Milano',
      'Milan': 'Milano',
      'Juventus': 'Torino',
      'Atalanta': 'Bergamo',
      'Bologna': 'Bologna',
      'Fiorentina': 'Firenze',
      'Torino': 'Torino',
      'Verona': 'Verona',
      'Monza': 'Monza',
      'Udinese': 'Udine',
      'Sassuolo': 'Reggio Emilia',
      'Genoa': 'Genova',
      'Lecce': 'Lecce',
      'Cagliari': 'Cagliari',
      'Empoli': 'Empoli',
      'Frosinone': 'Frosinone',
      'Salernitana': 'Salerno',
      'Sampdoria': 'Genova',
      'Spezia': 'La Spezia',
      'Cremonese': 'Cremona',
      'Parma': 'Parma',
    };
    return cities[teamName] ?? teamName;
  }

  String _getTeamFounded(String teamName) {
    teamName = _normalizeTeamName(teamName);
    const founded = {
      'Inter': '1908', 'Milan': '1899', 'Juventus': '1897', 'Napoli': '1926',
      'Roma': '1927', 'Lazio': '1900', 'Atalanta': '1907', 'Bologna': '1909',
      'Fiorentina': '1926', 'Torino': '1906', 'Verona': '1903', 'Monza': '1912',
      'Genoa': '1893', 'Lecce': '1908', 'Udinese': '1896', 'Empoli': '1920',
      'Cagliari': '1920', 'Frosinone': '1928', 'Sassuolo': '1920', 'Salernitana': '1919',
    };
    return founded[teamName] ?? '-';
  }

  String _getTeamCoach(String teamName) {
    teamName = _normalizeTeamName(teamName);
    const coaches = {
      'Inter': 'Simone Inzaghi', 'Milan': 'Stefano Pioli', 'Juventus': 'Massimiliano Allegri',
      'Napoli': 'Luciano Spalletti', 'Roma': 'José Mourinho', 'Lazio': 'Maurizio Sarri',
      'Atalanta': 'Gian Piero Gasperini', 'Bologna': 'Thiago Motta', 'Fiorentina': 'Vincenzo Italiano',
      'Torino': 'Ivan Juric', 'Verona': 'Marco Baroni', 'Monza': 'Raffaele Palladino',
      'Genoa': 'Alberto Gilardino', 'Lecce': 'Roberto D\'Aversa', 'Udinese': 'Andrea Sottil',
      'Empoli': 'Paolo Zanetti', 'Cagliari': 'Claudio Ranieri', 'Frosinone': 'Eusebio Di Francesco',
      'Sassuolo': 'Davide Ballardini', 'Salernitana': 'Filippo Inzaghi',
    };
    return coaches[teamName] ?? 'Allenatore';
  }


  Color _getPositionColor(int position) {
    if (position <= 4) return Colors.green;
    if (position <= 6) return Colors.blue;
    if (position >= 18) return Colors.red;
    return Colors.grey;
  }
}
