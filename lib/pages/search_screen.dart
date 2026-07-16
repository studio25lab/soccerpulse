import "package:provider/provider.dart";
// lib/pages/search_screen.dart

import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/soccer_match.dart';
import '../models/team.dart';
import '../models/player.dart'; // [FIX-CUORE-META]
import '../services/fanta_roster_service.dart'; // [STELLA-RICERCA]
import '../widgets/fanta_squad_picker.dart'; // [STELLA-PICKER]
import '../api/api_service.dart';
import '../services/haptic_service.dart';
import 'match_detail_screen.dart';
import 'coach_profile_screen.dart';
import 'match_player_profile_screen.dart'; // [FAV-extract4]
import 'team_detail_screen.dart';
import '../main.dart';
import '../services/favorites_service.dart';
import '../widgets/player_notification_sheet.dart'; // [TRE-ICONE-TOP]
import '../services/player_notification_preferences_service.dart'; // [TRE-ICONE-TOP]
import '../services/match_notification_preferences_service.dart';
import 'package:soccerpulse/models/local_match_models.dart';
import 'package:soccerpulse/models/team_standing.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final HapticService _haptic = HapticService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late TabController _tabController;

  List<Team> _teamResults = [];
  List<SoccerMatch> _matchResults = [];
  List<Player> _playerResults = [];
  bool _isSearching = false;
  bool _showPlayerSuggestions = false;
  bool _showBigMatches = false;
  bool _showTopScorers = false;
  bool _submitted = false; // true = show tabs, false = show inline suggestions
  String _searchQuery = '';
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _recentSearches = ['Inter', 'Milan', 'Juventus', 'Roma', 'Napoli'];
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;
    setState(() { _isSearching = true; _searchQuery = query; });
    try {
      final teams = await _apiService.fetchTeamsByLeague(135);
      final teamMaps = teams.map((t) => Team.fromJson(t)).toList();
      final filteredTeams = teamMaps.where((t) => _smartMatch(t.name, query)).toList();

      final allMockMatches = _getAllMockMatches();
      final today = DateTime.now();
      final apiMatches = await _apiService.fetchMatchesByDate(today, leagueId: 135);
      final allMatches = [...allMockMatches, ...apiMatches];
      final seen = <int>{};
      final uniqueMatches = allMatches.where((m) => seen.add(m.id)).toList();
      final filteredMatches = uniqueMatches.where((m) =>
          _smartMatch(m.homeTeamName, query) ||
          _smartMatch(m.awayTeamName, query)).toList();

      final mockPlayers = _getAllMockPlayers();
      final apiPlayers = await _apiService.fetchTopScorers(135);
      final allPlayers = <Player>[...mockPlayers, ...apiPlayers];
      final seenP = <int>{};
      final uniquePlayers = allPlayers.where((p) => seenP.add(p.id)).toList();
      final filteredPlayers = uniquePlayers.where((p) =>
          _smartMatch(p.name, query) ||
          _smartMatch(p.teamName, query)).toList();
      if (mounted) {
        setState(() {
          _teamResults = filteredTeams;
          _matchResults = filteredMatches;
          _playerResults = filteredPlayers;
          _isSearching = false;
        });
        if (!_recentSearches.contains(query)) {
          _recentSearches.insert(0, query);
          if (_recentSearches.length > 10) _recentSearches.removeLast();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _performSearchLive(String query) async {
    if (query.isEmpty) return;
    setState(() { _isSearching = true; _searchQuery = query; });
    try {
      final teams = await _apiService.fetchTeamsByLeague(135);
      final teamMaps = teams.map((t) => Team.fromJson(t)).toList();
      final filteredTeams = teamMaps.where((t) => _smartMatch(t.name, query)).toList();
      final allMock = _getAllMockMatches();
      final today = DateTime.now();
      final apiMatches = await _apiService.fetchMatchesByDate(today, leagueId: 135);
      final allMatches = <SoccerMatch>[...allMock, ...apiMatches];
      final seen = <int>{};
      final uniqueMatches = allMatches.where((m) => seen.add(m.id)).toList();
      final filteredMatches = uniqueMatches.where((m) =>
          _smartMatch(m.homeTeamName, query) ||
          _smartMatch(m.awayTeamName, query)).toList();
      final mockPlayers = _getAllMockPlayers();
      final apiPlayers = await _apiService.fetchTopScorers(135);
      final allPlayers = <Player>[...mockPlayers, ...apiPlayers];
      final seenP = <int>{};
      final uniquePlayers = allPlayers.where((p) => seenP.add(p.id)).toList();
      final filteredPlayers = uniquePlayers.where((p) =>
          _smartMatch(p.name, query) ||
          _smartMatch(p.teamName, query)).toList();
      if (mounted) {
        setState(() {
          _teamResults = filteredTeams;
          _matchResults = filteredMatches;
          _playerResults = filteredPlayers;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  TeamStanding _makeDefaultStanding(String name, String? logo) {
    final emptyStats = TeamStats(played: 19, win: 8, draw: 5, lose: 6, goalsFor: 25, goalsAgainst: 22);
    return TeamStanding(
      teamId: name.hashCode.abs(),
      teamName: name,
      teamLogo: logo,
      position: 10,
      leagueId: 135,
      points: 29,
      played: 19,
      wins: 8,
      draws: 5,
      losses: 6,
      goalsFor: 25,
      goalsAgainst: 22,
      goalsDiff: 3,
      form: 'WDLWW',
      home: emptyStats,
      away: emptyStats,
    );
  }

  List<TeamStanding> _getTeamStandings() {
    final emptyH = TeamStats(played: 19, win: 10, draw: 3, lose: 6, goalsFor: 30, goalsAgainst: 15);
    final emptyA = TeamStats(played: 19, win: 8, draw: 5, lose: 6, goalsFor: 25, goalsAgainst: 20);
    TeamStanding s(int pos, String name, String logoId, int w, int d, int l, int gf, int ga, int pts, String form) {
      return TeamStanding(
        teamId: name.hashCode.abs(), teamName: name,
        teamLogo: 'https://media.api-sports.io/football/teams/$logoId.png',
        position: pos, leagueId: 135, points: pts, played: w+d+l,
        wins: w, draws: d, losses: l, goalsFor: gf, goalsAgainst: ga,
        goalsDiff: gf - ga, form: form, home: emptyH, away: emptyA,
      );
    }
    return [
      s(1, 'Napoli', '492', 28, 6, 4, 77, 28, 90, 'WWWWW'),
      s(2, 'Lazio', '487', 22, 8, 8, 60, 30, 74, 'WDWLW'),
      s(3, 'Inter', '505', 23, 3, 12, 71, 42, 72, 'WWLWW'),
      s(4, 'AC Milan', '489', 21, 6, 11, 64, 43, 69, 'WDWWL'),
      s(5, 'Atalanta', '499', 19, 7, 12, 59, 42, 64, 'DWLWW'),
      s(6, 'Roma', '497', 18, 8, 12, 50, 39, 62, 'WLPWL'),
      s(7, 'Juventus', '496', 22, 6, 10, 56, 33, 62, 'WDLWL'),
      s(8, 'Bologna', '500', 16, 10, 12, 48, 40, 58, 'DDWLW'),
      s(9, 'Fiorentina', '502', 15, 11, 12, 49, 44, 56, 'WDLWL'),
      s(10, 'Torino', '503', 14, 10, 14, 42, 42, 52, 'LDWDL'),
      s(11, 'Monza', '1579', 13, 11, 14, 40, 45, 50, 'DLWDL'),
      s(12, 'Udinese', '494', 12, 12, 14, 42, 50, 48, 'WLDLD'),
      s(13, 'Sassuolo', '488', 12, 8, 18, 44, 57, 44, 'LLWDL'),
      s(14, 'Empoli', '511', 10, 12, 16, 35, 50, 42, 'DLDWL'),
      s(15, 'Salernitana', '514', 10, 8, 20, 36, 62, 38, 'LLLWL'),
      s(16, 'Lecce', '867', 9, 11, 18, 32, 48, 38, 'LDLWL'),
      s(17, 'Verona', '504', 8, 11, 19, 37, 56, 35, 'LLDLD'),
      s(18, 'Spezia', '515', 7, 10, 21, 32, 60, 31, 'LLLDL'),
      s(19, 'Cremonese', '511', 5, 12, 21, 28, 60, 27, 'LLDLL'),
      s(20, 'Sampdoria', '498', 5, 7, 26, 23, 63, 22, 'LLLLL'),
    ];
  }

  Map<String, dynamic> _getCoachMockData(String coachName, String teamName) {
    final coaches = <String, Map<String, dynamic>>{
      'Maurizio Sarri': {
        'nationality': '🇮🇹 Italiano', 'age': 64, 'born': '10 gennaio 1959',
        'formation': '4-3-3', 'teamFull': 'S.S. Lazio',
        'seasonW': 14, 'seasonD': 7, 'seasonL': 6,
        'seasonGoalsFor': 42, 'seasonGoalsAgainst': 28,
        'style': 'Possesso palla, pressing alto, gioco verticale rapido',
        'philosophy': 'Il Sarrismo si basa su un calcio offensivo e spettacolare.',
        'career': <Map<String, String>>[
          {'team': 'Lazio', 'period': '2021-2023', 'trophy': ''},
          {'team': 'Juventus', 'period': '2019-2020', 'trophy': '🏆 Serie A'},
          {'team': 'Chelsea', 'period': '2018-2019', 'trophy': '🏆 Europa League'},
          {'team': 'Napoli', 'period': '2015-2018', 'trophy': ''},
        ],
        'stats': <String, dynamic>{'matches': 27, 'winRate': 52, 'avgGoals': 1.56, 'cleanSheets': 8, 'avgPoints': 1.81},
      },
      'Stefano Pioli': {
        'nationality': '🇮🇹 Italiano', 'age': 57, 'born': '20 ottobre 1965',
        'formation': '4-2-3-1', 'teamFull': 'A.C. Milan',
        'seasonW': 16, 'seasonD': 5, 'seasonL': 6,
        'seasonGoalsFor': 48, 'seasonGoalsAgainst': 26,
        'style': 'Transizioni rapide, pressing coordinato, gioco sulle fasce',
        'philosophy': 'Calcio pragmatico e moderno.',
        'career': <Map<String, String>>[
          {'team': 'Milan', 'period': '2019-2024', 'trophy': '🏆 Scudetto 2022'},
          {'team': 'Fiorentina', 'period': '2017-2019', 'trophy': ''},
          {'team': 'Inter', 'period': '2016-2017', 'trophy': ''},
        ],
        'stats': <String, dynamic>{'matches': 27, 'winRate': 59, 'avgGoals': 1.78, 'cleanSheets': 10, 'avgPoints': 1.96},
      },
      'Massimiliano Allegri': {
        'nationality': '🇮🇹 Italiano', 'age': 56, 'born': '11 agosto 1967',
        'formation': '3-5-2', 'teamFull': 'Juventus F.C.',
        'seasonW': 16, 'seasonD': 8, 'seasonL': 3,
        'seasonGoalsFor': 56, 'seasonGoalsAgainst': 33,
        'style': 'Pragmatismo, solidità difensiva, gestione dei momenti',
        'philosophy': 'Vincere è l\'unica cosa che conta.',
        'career': <Map<String, String>>[
          {'team': 'Juventus', 'period': '2021-2024', 'trophy': '🏆 Coppa Italia 2024'},
          {'team': 'Juventus', 'period': '2014-2019', 'trophy': '🏆 5 Scudetti'},
          {'team': 'Milan', 'period': '2010-2014', 'trophy': '🏆 Scudetto 2011'},
        ],
        'stats': <String, dynamic>{'matches': 27, 'winRate': 59, 'avgGoals': 1.63, 'cleanSheets': 11, 'avgPoints': 2.04},
      },
      'Simone Inzaghi': {
        'nationality': '🇮🇹 Italiano', 'age': 47, 'born': '5 aprile 1976',
        'formation': '3-5-2', 'teamFull': 'F.C. Internazionale',
        'seasonW': 23, 'seasonD': 3, 'seasonL': 12,
        'seasonGoalsFor': 71, 'seasonGoalsAgainst': 42,
        'style': 'Gioco offensivo con esterni alti, pressing medio',
        'philosophy': 'Calcio propositivo con equilibrio.',
        'career': <Map<String, String>>[
          {'team': 'Inter', 'period': '2021-Presente', 'trophy': '🏆 Scudetto 2024'},
          {'team': 'Lazio', 'period': '2016-2021', 'trophy': '🏆 Coppa Italia 2019'},
        ],
        'stats': <String, dynamic>{'matches': 27, 'winRate': 63, 'avgGoals': 1.85, 'cleanSheets': 9, 'avgPoints': 2.11},
      },
    };
    return coaches[coachName] ?? <String, dynamic>{
      'nationality': '🇮🇹 Italiano', 'age': 50, 'born': '-',
      'formation': '4-3-3', 'teamFull': teamName,
      'seasonW': 12, 'seasonD': 8, 'seasonL': 7,
      'seasonGoalsFor': 38, 'seasonGoalsAgainst': 32,
      'style': 'Gioco equilibrato', 'philosophy': '-',
      'career': <Map<String, String>>[{'team': teamName, 'period': '2022-Presente', 'trophy': ''}],
      'stats': <String, dynamic>{'matches': 27, 'winRate': 44, 'avgGoals': 1.41, 'cleanSheets': 6, 'avgPoints': 1.63},
    };
  }


  bool _smartMatch(String text, String query) {
    final q = query.toLowerCase().trim();
    final t = text.toLowerCase();
    if (q.isEmpty) return false;
    // Exact start
    if (t.startsWith(q)) return true;
    // Contains anywhere
    if (t.contains(q)) return true;
    // Match start of any word
    for (final word in t.split(' ')) {
      if (word.startsWith(q)) return true;
    }
    // Fuzzy: match if all chars of query appear in order
    if (q.length >= 3) {
      int idx = 0;
      for (final c in q.split('')) {
        idx = t.indexOf(c, idx);
        if (idx == -1) return false;
        idx++;
      }
      return true;
    }
    return false;
  }

    List<Player> _getAllMockPlayers() {
    return [
      Player(id: 753, name: 'Lautaro Martinez', teamId: 505, teamName: 'Inter', position: 'Attaccante',
          photo: 'https://media.api-sports.io/football/players/753.png', goals: 24, assists: 5, rating: 7.8),
      Player(id: 2464, name: 'Nicolo Barella', teamId: 505, teamName: 'Inter', position: 'Centrocampista',
          photo: 'https://media.api-sports.io/football/players/2464.png', goals: 5, assists: 9, rating: 7.5),
      Player(id: 162028, name: 'Rafael Leao', teamId: 489, teamName: 'Milan', position: 'Attaccante',
          photo: 'https://media.api-sports.io/football/players/162028.png', goals: 15, assists: 9, rating: 7.3),
      Player(id: 2931, name: 'Hakan Calhanoglu', teamId: 505, teamName: 'Inter', position: 'Centrocampista',
          photo: 'https://media.api-sports.io/football/players/2931.png', goals: 8, assists: 10, rating: 7.4),
      Player(id: 1102, name: 'Paulo Dybala', teamId: 497, teamName: 'Roma', position: 'Attaccante',
          photo: 'https://media.api-sports.io/football/players/1102.png', goals: 13, assists: 7, rating: 7.3),
      Player(id: 48444, name: 'Dusan Vlahovic', teamId: 496, teamName: 'Juventus', position: 'Attaccante',
          photo: 'https://media.api-sports.io/football/players/48444.png', goals: 16, assists: 0, rating: 7.1),
      Player(id: 18921, name: 'Ademola Lookman', teamId: 499, teamName: 'Atalanta', position: 'Attaccante',
          photo: 'https://media.api-sports.io/football/players/18921.png', goals: 11, assists: 6, rating: 7.2),
      Player(id: 23474, name: 'Marcus Thuram', teamId: 505, teamName: 'Inter', position: 'Attaccante',
          photo: 'https://media.api-sports.io/football/players/23474.png', goals: 13, assists: 4, rating: 7.1),
      Player(id: 30924, name: 'Ciro Immobile', teamId: 487, teamName: 'Lazio', position: 'Attaccante',
          photo: 'https://media.api-sports.io/football/players/30924.png', goals: 12, assists: 3, rating: 7.1),
      Player(id: 292462, name: 'Khvicha Kvaratskhelia', teamId: 492, teamName: 'Napoli', position: 'Attaccante',
          photo: 'https://media.api-sports.io/football/players/292462.png', goals: 7, assists: 8, rating: 7.2),
      Player(id: 5996, name: 'Theo Hernandez', teamId: 489, teamName: 'Milan', position: 'Difensore',
          photo: 'https://media.api-sports.io/football/players/5996.png', goals: 5, assists: 8, rating: 7.0),
      Player(id: 30928, name: 'Lorenzo Pellegrini', teamId: 497, teamName: 'Roma', position: 'Centrocampista',
          photo: 'https://media.api-sports.io/football/players/30928.png', goals: 4, assists: 5, rating: 6.9),
      Player(id: 48809, name: 'Victor Osimhen', teamId: 492, teamName: 'Napoli', position: 'Attaccante',
          photo: 'https://media.api-sports.io/football/players/48809.png', goals: 15, assists: 3, rating: 7.6),
      Player(id: 31077, name: 'Federico Chiesa', teamId: 496, teamName: 'Juventus', position: 'Attaccante',
          photo: 'https://media.api-sports.io/football/players/31077.png', goals: 9, assists: 3, rating: 6.8),
      Player(id: 2932, name: 'Mike Maignan', teamId: 489, teamName: 'Milan', position: 'Portiere',
          photo: 'https://media.api-sports.io/football/players/2932.png', goals: 0, assists: 0, rating: 6.8),
      Player(id: 30443, name: 'Sergej Milinkovic-Savic', teamId: 487, teamName: 'Lazio', position: 'Centrocampista',
          photo: 'https://media.api-sports.io/football/players/30443.png', goals: 10, assists: 7, rating: 7.2),
      // ── Coaches (searchable as players with position 'ALL') ──
      Player(id: 90001, name: 'Maurizio Sarri', teamId: 487, teamName: 'Lazio', position: 'ALL',
          photo: '', goals: 0, assists: 0, rating: 0),
      Player(id: 90002, name: 'Stefano Pioli', teamId: 489, teamName: 'Milan', position: 'ALL',
          photo: '', goals: 0, assists: 0, rating: 0),
      Player(id: 90003, name: 'Massimiliano Allegri', teamId: 496, teamName: 'Juventus', position: 'ALL',
          photo: '', goals: 0, assists: 0, rating: 0),
      Player(id: 90004, name: 'Simone Inzaghi', teamId: 505, teamName: 'Inter', position: 'ALL',
          photo: '', goals: 0, assists: 0, rating: 0),
      Player(id: 90005, name: 'Luciano Spalletti', teamId: 492, teamName: 'Napoli', position: 'ALL',
          photo: '', goals: 0, assists: 0, rating: 0),
      Player(id: 90006, name: 'Jose Mourinho', teamId: 497, teamName: 'Roma', position: 'ALL',
          photo: '', goals: 0, assists: 0, rating: 0),
      Player(id: 90007, name: 'Gian Piero Gasperini', teamId: 499, teamName: 'Atalanta', position: 'ALL',
          photo: '', goals: 0, assists: 0, rating: 0),
      Player(id: 90008, name: 'Thiago Motta', teamId: 500, teamName: 'Bologna', position: 'ALL',
          photo: '', goals: 0, assists: 0, rating: 0),
      // ── Additional players for better coverage ──
      Player(id: 50001, name: 'Luis Alberto', teamId: 487, teamName: 'Lazio', position: 'Centrocampista',
          photo: 'https://media.api-sports.io/football/players/50001.png', goals: 6, assists: 8, rating: 7.1),
      Player(id: 50002, name: 'Pedro Rodriguez', teamId: 487, teamName: 'Lazio', position: 'Attaccante',
          photo: '', goals: 5, assists: 3, rating: 6.8),
      Player(id: 50003, name: 'Mattia Zaccagni', teamId: 487, teamName: 'Lazio', position: 'Attaccante',
          photo: '', goals: 7, assists: 5, rating: 7.0),
      Player(id: 50004, name: 'Olivier Giroud', teamId: 489, teamName: 'Milan', position: 'Attaccante',
          photo: '', goals: 11, assists: 4, rating: 7.0),
      Player(id: 50005, name: 'Fikayo Tomori', teamId: 489, teamName: 'Milan', position: 'Difensore',
          photo: '', goals: 1, assists: 0, rating: 6.9),
      Player(id: 50006, name: 'Alessandro Bastoni', teamId: 505, teamName: 'Inter', position: 'Difensore',
          photo: '', goals: 2, assists: 3, rating: 7.0),
      Player(id: 50007, name: 'Gleison Bremer', teamId: 496, teamName: 'Juventus', position: 'Difensore',
          photo: '', goals: 3, assists: 0, rating: 7.1),
      Player(id: 50008, name: 'Giovanni Di Lorenzo', teamId: 492, teamName: 'Napoli', position: 'Difensore',
          photo: '', goals: 2, assists: 4, rating: 7.0),
      Player(id: 50009, name: 'Stanislav Lobotka', teamId: 492, teamName: 'Napoli', position: 'Centrocampista',
          photo: '', goals: 1, assists: 3, rating: 7.2),
      Player(id: 50010, name: 'Sandro Tonali', teamId: 489, teamName: 'Milan', position: 'Centrocampista',
          photo: '', goals: 3, assists: 5, rating: 7.1),
    ];
  }

    List<SoccerMatch> _getAllMockMatches() {
    return [
      // ═══ G35 LIVE ═══
      SoccerMatch(id: 9001, homeTeamId: 487, awayTeamId: 489, homeTeamName: 'Lazio', awayTeamName: 'Milan',
          homeScore: 2, awayScore: 1, status: '1H', date: DateTime(2023, 5, 14), time: '20:45',
          venue: 'Stadio Olimpico', leagueId: 135, leagueName: 'Serie A', round: 'Giornata 35', elapsed: 45,
          homeTeamLogo: 'https://media.api-sports.io/football/teams/487.png', awayTeamLogo: 'https://media.api-sports.io/football/teams/489.png'),
      // ═══ G35 FINITE ═══
      SoccerMatch(id: 2, homeTeamId: 502, awayTeamId: 499, homeTeamName: 'Fiorentina', awayTeamName: 'Atalanta',
          homeScore: 3, awayScore: 2, status: 'FT', date: DateTime(2023, 5, 14), time: '15:00',
          venue: 'Stadio Franchi', leagueId: 135, leagueName: 'Serie A', round: 'Giornata 35',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/502.png', awayTeamLogo: 'https://media.api-sports.io/football/teams/499.png'),
      SoccerMatch(id: 8003, homeTeamId: 492, awayTeamId: 496, homeTeamName: 'Napoli', awayTeamName: 'Juventus',
          homeScore: 1, awayScore: 1, status: 'FT', date: DateTime(2023, 5, 14), time: '18:00',
          venue: 'Stadio Maradona', leagueId: 135, leagueName: 'Serie A', round: 'Giornata 35',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/492.png', awayTeamLogo: 'https://media.api-sports.io/football/teams/496.png'),
      SoccerMatch(id: 8004, homeTeamId: 505, awayTeamId: 503, homeTeamName: 'Inter', awayTeamName: 'Torino',
          homeScore: 2, awayScore: 0, status: 'FT', date: DateTime(2023, 5, 14), time: '12:30',
          venue: 'San Siro', leagueId: 135, leagueName: 'Serie A', round: 'Giornata 35',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/505.png', awayTeamLogo: 'https://media.api-sports.io/football/teams/503.png'),
      SoccerMatch(id: 8005, homeTeamId: 497, awayTeamId: 487, homeTeamName: 'Roma', awayTeamName: 'Lazio',
          homeScore: 0, awayScore: 1, status: 'FT', date: DateTime(2023, 5, 7), time: '20:45',
          venue: 'Stadio Olimpico', leagueId: 135, leagueName: 'Serie A', round: 'Giornata 34',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/497.png', awayTeamLogo: 'https://media.api-sports.io/football/teams/487.png'),
      SoccerMatch(id: 8006, homeTeamId: 505, awayTeamId: 492, homeTeamName: 'Inter', awayTeamName: 'Napoli',
          homeScore: 3, awayScore: 1, status: 'FT', date: DateTime(2023, 5, 7), time: '18:00',
          venue: 'San Siro', leagueId: 135, leagueName: 'Serie A', round: 'Giornata 34',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/505.png', awayTeamLogo: 'https://media.api-sports.io/football/teams/492.png'),
      SoccerMatch(id: 8007, homeTeamId: 489, awayTeamId: 496, homeTeamName: 'Milan', awayTeamName: 'Juventus',
          homeScore: 1, awayScore: 0, status: 'FT', date: DateTime(2023, 5, 7), time: '15:00',
          venue: 'San Siro', leagueId: 135, leagueName: 'Serie A', round: 'Giornata 34',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/489.png', awayTeamLogo: 'https://media.api-sports.io/football/teams/496.png'),
      SoccerMatch(id: 7008, homeTeamId: 499, awayTeamId: 505, homeTeamName: 'Atalanta', awayTeamName: 'Inter',
          homeScore: 2, awayScore: 3, status: 'FT', date: DateTime(2023, 4, 30), time: '20:45',
          venue: 'Gewiss Stadium', leagueId: 135, leagueName: 'Serie A', round: 'Giornata 33',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/499.png', awayTeamLogo: 'https://media.api-sports.io/football/teams/505.png'),
      SoccerMatch(id: 7010, homeTeamId: 496, awayTeamId: 487, homeTeamName: 'Juventus', awayTeamName: 'Lazio',
          homeScore: 3, awayScore: 1, status: 'FT', date: DateTime(2023, 4, 30), time: '18:00',
          venue: 'Allianz Stadium', leagueId: 135, leagueName: 'Serie A', round: 'Giornata 33',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/496.png', awayTeamLogo: 'https://media.api-sports.io/football/teams/487.png'),
      SoccerMatch(id: 8010, homeTeamId: 492, awayTeamId: 489, homeTeamName: 'Napoli', awayTeamName: 'Milan',
          homeScore: 2, awayScore: 2, status: 'FT', date: DateTime(2023, 4, 30), time: '15:00',
          venue: 'Stadio Maradona', leagueId: 135, leagueName: 'Serie A', round: 'Giornata 33',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/492.png', awayTeamLogo: 'https://media.api-sports.io/football/teams/489.png'),
      // ═══ G36 PROSSIME ═══
      SoccerMatch(id: 9007, homeTeamId: 497, awayTeamId: 500, homeTeamName: 'Roma', awayTeamName: 'Bologna',
          homeScore: 0, awayScore: 0, status: 'NS', date: DateTime(2023, 5, 21), time: '18:00',
          venue: 'Stadio Olimpico', leagueId: 135, leagueName: 'Serie A', round: 'Giornata 36',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/497.png', awayTeamLogo: 'https://media.api-sports.io/football/teams/500.png'),
      SoccerMatch(id: 9008, homeTeamId: 505, awayTeamId: 504, homeTeamName: 'Inter', awayTeamName: 'Verona',
          homeScore: 0, awayScore: 0, status: 'NS', date: DateTime(2023, 5, 21), time: '20:45',
          venue: 'San Siro', leagueId: 135, leagueName: 'Serie A', round: 'Giornata 36',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/505.png', awayTeamLogo: 'https://media.api-sports.io/football/teams/504.png'),
      SoccerMatch(id: 9003, homeTeamId: 489, awayTeamId: 492, homeTeamName: 'Milan', awayTeamName: 'Napoli',
          homeScore: 0, awayScore: 0, status: 'NS', date: DateTime(2023, 5, 21), time: '15:00',
          venue: 'San Siro', leagueId: 135, leagueName: 'Serie A', round: 'Giornata 36',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/489.png', awayTeamLogo: 'https://media.api-sports.io/football/teams/492.png'),
      SoccerMatch(id: 7009, homeTeamId: 487, awayTeamId: 499, homeTeamName: 'Lazio', awayTeamName: 'Atalanta',
          homeScore: 0, awayScore: 0, status: 'NS', date: DateTime(2023, 5, 21), time: '18:00',
          venue: 'Stadio Olimpico', leagueId: 135, leagueName: 'Serie A', round: 'Giornata 36',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/487.png', awayTeamLogo: 'https://media.api-sports.io/football/teams/499.png'),
      SoccerMatch(id: 9010, homeTeamId: 496, awayTeamId: 502, homeTeamName: 'Juventus', awayTeamName: 'Fiorentina',
          homeScore: 0, awayScore: 0, status: 'NS', date: DateTime(2023, 5, 21), time: '20:45',
          venue: 'Allianz Stadium', leagueId: 135, leagueName: 'Serie A', round: 'Giornata 36',
          homeTeamLogo: 'https://media.api-sports.io/football/teams/496.png', awayTeamLogo: 'https://media.api-sports.io/football/teams/502.png'),
    ];
  }

    void _clearSearch() {
    _searchController.clear();
    setState(() { _searchQuery = ''; _teamResults = []; _matchResults = []; _playerResults = []; _showPlayerSuggestions = false; _showBigMatches = false; _showTopScorers = false; _submitted = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tx = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final lb = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final bg = isDark ? const Color(0xFF0A0E21) : const Color(0xFFF5F6FA);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          // ── Search Bar ──
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            color: isDark ? const Color(0xFF0D0D1A) : bg,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.arrow_back_rounded, size: 20, color: lb),
                  ),
                ),
                Icon(
                  Icons.search_rounded, size: 18,
                  color: _searchFocus.hasFocus ? theme.primaryColor : lb.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: tx),
                    decoration: InputDecoration(
                      hintText: tr(context, 'Cerca squadre, giocatori, partite...'),
                      hintStyle: TextStyle(fontSize: 14, color: lb.withValues(alpha: 0.45)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                    ),
                    onSubmitted: (v) { if (v.isNotEmpty) { setState(() => _submitted = true); _performSearch(v); } },
                    onChanged: (v) { setState(() { _searchQuery = v; _submitted = false; }); if (v.length >= 2) _performSearchLive(v); },
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: _clearSearch,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: lb.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close_rounded, size: 16, color: lb),
                      ),
                    ),
                  ),
                // [CASETTA-RICERCA] casetta Home
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    Future.delayed(const Duration(milliseconds: 250),
                        () => MainScreen.switchTab(0));
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, right: 4),
                    child: Icon(Icons.home_rounded, size: 20, color: lb),
                  ),
                ),
              ]),
            ),
          ),
          // ── Body ──
          Expanded(child: _buildBody(theme, isDark, tx, lb)),
        ]),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark, Color tx, Color lb) {
    if (_isSearching) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 3, color: theme.primaryColor)),
        const SizedBox(height: 16),
        Text(tr(context, 'Ricerca in corso...'), style: TextStyle(fontSize: 14, color: lb)),
      ]));
    }
    if (_showTopScorers && _searchQuery.isEmpty) return _buildTopScorersView(isDark, tx, lb);
    if (_showBigMatches && _searchQuery.isEmpty) return _buildBigMatches(theme, isDark, tx, lb);
    if (_showPlayerSuggestions && _searchQuery.isEmpty) return _buildPlayerSuggestions(theme, isDark, tx, lb);
    if (_searchQuery.isEmpty) return _buildInitialState(theme, isDark, tx, lb);
    final hasResults = _teamResults.isNotEmpty || _matchResults.isNotEmpty || _playerResults.isNotEmpty;
    if (!hasResults && _submitted) return _buildNoResults(isDark, tx, lb);
    if (!_submitted && hasResults) return _buildInlineSuggestions(theme, isDark, tx, lb);
    if (!_submitted && !hasResults) return _buildInitialState(theme, isDark, tx, lb);
    return _buildResults(theme, isDark, tx, lb);
  }

  Widget _buildInitialState(ThemeData theme, bool isDark, Color tx, Color lb) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Ricerche recenti ──
        if (_recentSearches.isNotEmpty) ...[
          Row(children: [
            Icon(Icons.history_rounded, size: 18, color: lb),
            const SizedBox(width: 8),
            Text(tr(context, 'Ricerche recenti'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tx)),
            const Spacer(),
            GestureDetector(
              onTap: () { _haptic.lightImpact(); setState(() => _recentSearches = []); },
              child: Text(tr(context, 'Cancella'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.primaryColor)),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: _recentSearches.map((s) =>
            GestureDetector(
              onTap: () { _haptic.lightImpact(); _searchController.text = s; _performSearch(s); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.18)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1))],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.history_rounded, size: 15, color: theme.primaryColor.withValues(alpha: 0.6)),
                  const SizedBox(width: 7),
                  Text(s, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tx)),
                ]),
              ),
            ),
          ).toList()),
          const SizedBox(height: 32),
        ],

        // ── Esplora ──
        Text(tr(context, 'Esplora'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tx)),
        const SizedBox(height: 14),
        _buildNavCard(
          icon: Icons.emoji_events_rounded,
          label: tr(context, 'Classifica Serie A'),
          subtitle: tr(context, '20 squadre • Stagione 2023/24'),
          gradient: const [Color(0xFF00BFA5), Color(0xFF00897B)],
          onTap: () { Navigator.pop(context); Future.delayed(const Duration(milliseconds: 250), () => MainScreen.switchTab(3, subTab: 1)); },
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _buildNavCard(
            icon: Icons.sports_soccer_rounded,
            label: tr(context, 'Marcatori'),
            subtitle: tr(context, 'Classifica gol'),
            gradient: const [Color(0xFF66BB6A), Color(0xFF43A047)],
            onTap: () { _searchController.text = ''; setState(() { _showTopScorers = true; }); },
            isDark: isDark, compact: true,
          )),
          const SizedBox(width: 10),
          Expanded(child: _buildNavCard(
            icon: Icons.local_fire_department_rounded,
            label: 'Big Match',
            subtitle: tr(context, 'Derby e sfide top'),
            gradient: const [Color(0xFFFF7043), Color(0xFFE64A19)],
            onTap: () { setState(() => _showBigMatches = true); },
            isDark: isDark, compact: true,
          )),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _buildNavCard(
            icon: Icons.people_rounded,
            label: tr(context, 'Giocatori'),
            subtitle: tr(context, 'Statistiche e profili'),
            gradient: const [Color(0xFF42A5F5), Color(0xFF1E88E5)],
            onTap: () { setState(() => _showPlayerSuggestions = true); },
            isDark: isDark, compact: true,
          )),
          const SizedBox(width: 10),
          Expanded(child: _buildNavCard(
            icon: Icons.calendar_today_rounded,
            label: tr(context, 'Calendario'),
            subtitle: tr(context, 'Prossime partite'),
            gradient: const [Color(0xFFAB47BC), Color(0xFF8E24AA)],
            onTap: () { Navigator.pop(context); Future.delayed(const Duration(milliseconds: 250), () => MainScreen.switchTab(1)); },
            isDark: isDark, compact: true,
          )),
        ]),

        const SizedBox(height: 32),
        // ── Squadre popolari ──
        const SizedBox(height: 8),
        Row(children: [
          Text(tr(context, 'Squadre popolari'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tx)),
          const Spacer(),
          Text(tr(context, 'Serie A 2022/23'), style: TextStyle(fontSize: 11, color: lb)),
        ]),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildTeamBubble('Napoli', 'https://media.api-sports.io/football/teams/492.png', '1°', const Color(0xFF004B87), isDark, tx, lb),
              _buildTeamBubble('Lazio', 'https://media.api-sports.io/football/teams/487.png', '2°', const Color(0xFF87CEEB), isDark, tx, lb),
              _buildTeamBubble('Inter', 'https://media.api-sports.io/football/teams/505.png', '3°', const Color(0xFF0068A8), isDark, tx, lb),
              _buildTeamBubble('Milan', 'https://media.api-sports.io/football/teams/489.png', '4°', const Color(0xFFE5193E), isDark, tx, lb),
              _buildTeamBubble('Atalanta', 'https://media.api-sports.io/football/teams/499.png', '5°', const Color(0xFF1B3B6F), isDark, tx, lb),
              _buildTeamBubble('Roma', 'https://media.api-sports.io/football/teams/497.png', '6°', const Color(0xFFAA1E22), isDark, tx, lb),
              _buildTeamBubble('Juventus', 'https://media.api-sports.io/football/teams/496.png', '7°', Colors.black, isDark, tx, lb),
              _buildTeamBubble('Bologna', 'https://media.api-sports.io/football/teams/500.png', '8°', const Color(0xFF1B3B6F), isDark, tx, lb),
              _buildTeamBubble('Fiorentina', 'https://media.api-sports.io/football/teams/502.png', '9°', const Color(0xFF6B3FA0), isDark, tx, lb),
              _buildTeamBubble('Torino', 'https://media.api-sports.io/football/teams/503.png', '10°', const Color(0xFF8B1A2B), isDark, tx, lb),
              _buildTeamBubble('Monza', 'https://media.api-sports.io/football/teams/1579.png', '11°', const Color(0xFFCE2B37), isDark, tx, lb),
              _buildTeamBubble('Udinese', 'https://media.api-sports.io/football/teams/494.png', '12°', Colors.black, isDark, tx, lb),
              _buildTeamBubble('Sassuolo', 'https://media.api-sports.io/football/teams/488.png', '13°', const Color(0xFF00A551), isDark, tx, lb),
              _buildTeamBubble('Empoli', 'https://media.api-sports.io/football/teams/511.png', '14°', const Color(0xFF004B9B), isDark, tx, lb),
              _buildTeamBubble('Salernitana', 'https://media.api-sports.io/football/teams/514.png', '15°', const Color(0xFF8B1A2B), isDark, tx, lb),
              _buildTeamBubble('Lecce', 'https://media.api-sports.io/football/teams/867.png', '16°', const Color(0xFFFFD700), isDark, tx, lb),
              _buildTeamBubble('Verona', 'https://media.api-sports.io/football/teams/504.png', '17°', const Color(0xFF004B9B), isDark, tx, lb),
              _buildTeamBubble('Spezia', 'https://media.api-sports.io/football/teams/515.png', '18°', Colors.black, isDark, tx, lb),
              _buildTeamBubble('Cremonese', 'https://media.api-sports.io/football/teams/511.png', '19°', const Color(0xFFCE2B37), isDark, tx, lb),
              _buildTeamBubble('Sampdoria', 'https://media.api-sports.io/football/teams/498.png', '20°', const Color(0xFF004B9B), isDark, tx, lb),
            ],
          ),
        ),
        const SizedBox(height: 16),      ]),
    );
  }


  Widget _buildInlineSuggestions(ThemeData theme, bool isDark, Color tx, Color lb) {
    final suggestions = <Map<String, dynamic>>[];
    // Teams
    if (_teamResults.isNotEmpty) {
      suggestions.add({'type': 'header', 'name': tr(context, 'Squadre'), 'sub': '', 'icon': Icons.shield, 'logo': null, 'data': null});
    }
    for (final t in _teamResults.take(3)) {
      suggestions.add({'type': 'team', 'name': t.name, 'sub': t.country ?? 'Italia',
          'icon': Icons.shield_rounded, 'logo': t.logo, 'data': t});
    }
    // Coaches header
    final coaches = _playerResults.where((p) => p.position == 'ALL').take(2).toList();
    if (coaches.isNotEmpty) {
      suggestions.add({'type': 'header', 'name': tr(context, 'Allenatori'), 'sub': '', 'icon': Icons.person_outline, 'logo': null, 'data': null});
    }
    for (final p in coaches) {
      suggestions.add({'type': 'coach', 'name': p.name, 'sub': '${p.teamName} • ${tr(context, 'Allenatore')}',
          'icon': Icons.person_outline_rounded, 'logo': p.photo, 'data': p});
    }
    // Players header
    final topPlayers = _playerResults.where((p) => p.position != 'ALL' && p.rating >= 7.0).take(3).toList();
    if (topPlayers.isNotEmpty) {
      suggestions.add({'type': 'header', 'name': tr(context, 'Giocatori'), 'sub': '', 'icon': Icons.person, 'logo': null, 'data': null});
    }
    for (final p in topPlayers) {
      suggestions.add({'type': 'player', 'name': p.name, 'sub': '${p.teamName} • ${p.position}',
          'icon': Icons.person_rounded, 'logo': p.photo, 'data': p});
    }
    // Matches header
    if (_matchResults.isNotEmpty) {
      suggestions.add({'type': 'header', 'name': tr(context, 'Partite'), 'sub': '', 'icon': Icons.sports_soccer, 'logo': null, 'data': null});
    }
    // Only big matches (involving top 7 teams)
    const bigTeams = ['Napoli', 'Lazio', 'Inter', 'Milan', 'AC Milan', 'Juventus', 'Roma', 'Atalanta'];
    final bigMatches = _matchResults.where((m) =>
        bigTeams.any((t) => m.homeTeamName.contains(t)) && bigTeams.any((t) => m.awayTeamName.contains(t))
    ).take(2).toList();
    // If no big matches, take first 2
    final matchesToShow = bigMatches.isNotEmpty ? bigMatches : _matchResults.take(2).toList();
    for (final m in matchesToShow) {
      suggestions.add({'type': 'match', 'name': '${m.homeTeamName} vs ${m.awayTeamName}',
          'sub': '${m.leagueName ?? "Serie A"} • ${m.round ?? ""}',
          'icon': Icons.sports_soccer_rounded, 'logo': null, 'data': m});
    }
    if (suggestions.isEmpty) return const SizedBox();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      itemCount: suggestions.length + 1,
      itemBuilder: (ctx, i) {
        if (i == suggestions.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: GestureDetector(
              onTap: () { setState(() => _submitted = true); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.primaryColor.withValues(alpha: 0.15)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.search_rounded, size: 16, color: theme.primaryColor),
                  const SizedBox(width: 8),
                  Text('${tr(context, 'Mostra tutti i risultati per')} "$_searchQuery"',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: theme.primaryColor)),
                ]),
              ),
            ),
          );
        }
        final s = suggestions[i];
        final type = s['type'] as String;
        // Render category header
        if (type == 'header') {
          return Padding(
            padding: EdgeInsets.fromLTRB(4, i == 0 ? 0 : 10, 4, 4),
            child: Text(s['name'] as String,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: lb, letterSpacing: 0.5)),
          );
        }
        final name = s['name'] as String;
        final sub = s['sub'] as String;
        final icon = s['icon'] as IconData;
        final logo = s['logo'] as String?;
        Color typeColor;
        switch (type) {
          case 'team': typeColor = const Color(0xFF00BFA5); break;
          case 'coach': typeColor = const Color(0xFF9C27B0); break;
          case 'player': typeColor = const Color(0xFF2196F3); break;
          default: typeColor = const Color(0xFFFFA726); break;
        }
        return GestureDetector(
          onTap: () {
            _haptic.lightImpact();
            if (type == 'coach') {
              final p = s['data'] as Player;
              final coachData = _getCoachMockData(p.name, p.teamName);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => CoachProfileScreen(
                  coachName: p.name,
                  teamName: p.teamName,
                  teamColor: Theme.of(context).primaryColor,
                  data: coachData,
                ),
              ));
            } else if (type == 'player') {
              final p = s['data'] as Player;
              final llp = LocalLineupPlayer(
                number: p.id % 99 + 1, name: p.name,
                position: p.position.contains('Att') ? 'F' : p.position.contains('Cent') ? 'M' : p.position.contains('Dif') ? 'D' : 'G',
                rating: p.rating, goals: p.goals ?? 0, assists: p.assists ?? 0,
              );
              Color tc;
              switch (p.teamName) {
                case 'Inter': tc = const Color(0xFF0068A8); break;
                case 'Milan': tc = const Color(0xFFE5193E); break;
                case 'Juventus': tc = const Color(0xFF000000); break;
                case 'Napoli': tc = const Color(0xFF004B87); break;
                case 'Lazio': tc = const Color(0xFF87CEEB); break;
                case 'Roma': tc = const Color(0xFFAA1E22); break;
                case 'Atalanta': tc = const Color(0xFF1B3B6F); break;
                default: tc = const Color(0xFF2196F3); break;
              }
              Navigator.push(context, MaterialPageRoute(builder: (_) => MatchPlayerProfileScreen(player: llp, teamName: p.teamName, teamColor: tc)));
            } else if (type == 'match') {
              final m = s['data'] as SoccerMatch;
              Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailScreen(match: m)));
            } else if (type == 'team') {
              final team = s['data'] as Team;
              final standings = _getTeamStandings();
              final standing = standings.firstWhere(
                (st) => st.teamName == team.name || st.teamName.contains(team.name) || team.name.contains(st.teamName),
                orElse: () => _makeDefaultStanding(team.name, team.logo),
              );
              Navigator.push(context, MaterialPageRoute(builder: (_) => TeamDetailScreen(teamStanding: standing)));
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141B2D) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.08)),
            ),
            child: Row(children: [
              if (logo != null && logo.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(type == 'player' ? 20 : 8),
                  child: CachedNetworkImage(imageUrl: logo, width: 36, height: 36, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(width: 36, height: 36,
                          decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Icon(icon, size: 18, color: typeColor))),
                )
              else
                Container(width: 36, height: 36,
                    decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, size: 18, color: typeColor)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tx),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(sub, style: TextStyle(fontSize: 11, color: lb)),
              ])),

            ]),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 40));
      },
    );
  }

  int _getTeamPosition(String teamName) {
    const positions = {
      'Inter': 1, 'Milan': 2, 'Juventus': 3, 'Atalanta': 4, 'Bologna': 5,
      'Roma': 6, 'Lazio': 7, 'Fiorentina': 8, 'Torino': 9, 'Napoli': 10,
      'Verona': 15, 'Monza': 11, 'Genoa': 12,
    };
    return positions[teamName] ?? 10;
  }

  Widget _positionBadge(int pos) {
    Color color;
    if (pos <= 4) {
      color = const Color(0xFF4CAF50);
    } else if (pos <= 6) color = const Color(0xFF2196F3);
    else if (pos == 7) color = const Color(0xFFFFA726);
    else if (pos >= 18) color = const Color(0xFFE53935);
    else color = Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$pos°', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _buildTopScorersView(bool isDark, Color tx, Color lb) {
    final cardBg = isDark ? const Color(0xFF1E1E30) : Colors.white;
    final players = _getAllMockPlayers()
        .where((p) => p.position != 'ALL')
        .toList()
      ..sort((a, b) => (b.goals ?? 0).compareTo(a.goals ?? 0));
    
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(children: [
          GestureDetector(
            onTap: () => setState(() => _showTopScorers = false),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: tx),
            ),
          ),
          const SizedBox(width: 12),
          Text(tr(context, 'Classifica Marcatori'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: tx)),
        ]),
      ),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: players.length.clamp(0, 20),
        itemBuilder: (context, index) {
          final p = players[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.08)),
            ),
            child: Row(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: index < 3 ? const Color(0xFFFFD700).withValues(alpha: 0.15) : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.06)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text('${index + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: index < 3 ? const Color(0xFFFFB300) : lb))),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 18,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                backgroundImage: (p.photo ?? '').isNotEmpty ? NetworkImage(p.photo!) : null,
                child: (p.photo ?? '').isEmpty ? Icon(Icons.person, size: 18, color: lb) : null,
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tx)),
                Text(p.teamName, style: TextStyle(fontSize: 11, color: lb)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('${p.goals ?? 0} ⚽', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF2E7D32))),
              ),
              const SizedBox(width: 8),
              // [TRE-ICONE-TOP] 3 icone: cuore + stella + campanella
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cuore preferiti
                  Builder(builder: (ctx) {
                    final favSvc = ctx.watch<FavoritesService>();
                    final pid = p.name.hashCode.abs();
                    final isFav = favSvc.isPlayerFavoriteByName(p.name); // [CUORI-BY-NAME]
                    return GestureDetector(
                      onTap: () {
                        _haptic.lightImpact();
                        if (!isFav) {
                          favSvc.storePlayerMeta(pid, {
                            'name': p.name,
                            'position': p.position.contains('Att') || p.position.toLowerCase().contains('ala') ? 'F'
                                : p.position.contains('Cen') ? 'M'
                                : p.position.contains('Dif') || p.position.contains('Terz') ? 'D'
                                : p.position.contains('Por') ? 'G' : 'F',
                            'team': p.teamName,
                            'teamId': p.teamId,
                            'rating': p.rating,
                            'goals': p.goals ?? 0,
                            'assists': p.assists ?? 0,
                          });
                        }
                        favSvc.togglePlayerFavorite(pid);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 20,
                          color: isFav ? Colors.red : lb.withValues(alpha: 0.4),
                        ),
                      ),
                    );
                  }),
                  // Stella rosa
                  Consumer<FantaRosterService>(
                    builder: (ctx, roster, _) {
                      final pid = p.name.hashCode.abs(); // [STELLE-BY-NAME]
                      final inRoster = roster.isInRosterByName(p.name);
                      return GestureDetector(
                        onTap: () {
                          _haptic.lightImpact();
                          final player = Player(
                            id: pid,
                            name: p.name,
                            position: p.position,
                            teamId: p.teamId,
                            teamName: p.teamName,
                            photo: p.photo,
                            rating: p.rating,
                            goals: p.goals ?? 0,
                            assists: p.assists ?? 0,
                          );
                          handleStarTap(context, player); // [STELLA-PICKER]
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(
                            inRoster ? Icons.star_rounded : Icons.star_border_rounded,
                            size: 20,
                            color: inRoster ? const Color(0xFF9C27B0) : lb.withValues(alpha: 0.4),
                          ),
                        ),
                      );
                    },
                  ),
                  // Campanella notifiche (pannello condiviso)
                  Builder(builder: (ctx) {
                    final ns = ctx.watch<PlayerNotificationPreferencesService>();
                    final hasNotif = ns.getSettingsByPlayerName(p.name) != null;
                    return GestureDetector(
                      onTap: () {
                        _haptic.lightImpact();
                        showPlayerNotificationSheet(
                          context,
                          playerName: p.name,
                          playerId: p.name.hashCode.abs(),
                          photo: p.photo,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Icon(
                          hasNotif ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                          size: 20,
                          color: hasNotif ? const Color(0xFF4CAF50) : lb.withValues(alpha: 0.4),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ]),
          );
        },
      )),
    ]);
  }

  Widget _buildBigMatches(ThemeData theme, bool isDark, Color tx, Color lb) {
    final matches = [
      // G36 — corrisponde alle prossime nella Home
      {'id': 50001, 'home': 'Milan', 'away': 'Napoli', 'homeLogo': 'https://media.api-sports.io/football/teams/489.png',
       'awayLogo': 'https://media.api-sports.io/football/teams/492.png',
       'round': 'Giornata 36', 'date': 'Dom 21 Mag', 'time': '15:00', 'tag': 'TOP 4', 'tagColor': 0xFF43A047},
      // G37
      {'id': 50002, 'home': 'Inter', 'away': 'Milan', 'homeLogo': 'https://media.api-sports.io/football/teams/505.png',
       'awayLogo': 'https://media.api-sports.io/football/teams/489.png',
       'round': 'Giornata 37', 'date': 'Dom 28 Mag', 'time': '20:45', 'tag': 'DERBY', 'tagColor': 0xFFE53935},
      {'id': 50003, 'home': 'Roma', 'away': 'Lazio', 'homeLogo': 'https://media.api-sports.io/football/teams/497.png',
       'awayLogo': 'https://media.api-sports.io/football/teams/487.png',
       'round': 'Giornata 37', 'date': 'Dom 28 Mag', 'time': '18:00', 'tag': 'DERBY', 'tagColor': 0xFFE53935},
      {'id': 50004, 'home': 'Juventus', 'away': 'Atalanta', 'homeLogo': 'https://media.api-sports.io/football/teams/496.png',
       'awayLogo': 'https://media.api-sports.io/football/teams/499.png',
       'round': 'Giornata 37', 'date': 'Sab 27 Mag', 'time': '20:45', 'tag': 'BIG MATCH', 'tagColor': 0xFFFFA726},
      // G38
      {'id': 50005, 'home': 'Napoli', 'away': 'Inter', 'homeLogo': 'https://media.api-sports.io/football/teams/492.png',
       'awayLogo': 'https://media.api-sports.io/football/teams/505.png',
       'round': 'Giornata 38', 'date': 'Dom 4 Giu', 'time': '20:45', 'tag': 'BIG MATCH', 'tagColor': 0xFFFFA726},
      {'id': 50006, 'home': 'Lazio', 'away': 'Juventus', 'homeLogo': 'https://media.api-sports.io/football/teams/487.png',
       'awayLogo': 'https://media.api-sports.io/football/teams/496.png',
       'round': 'Giornata 38', 'date': 'Dom 4 Giu', 'time': '18:00', 'tag': 'TOP 6', 'tagColor': 0xFF2196F3},
      {'id': 50007, 'home': 'Milan', 'away': 'Roma', 'homeLogo': 'https://media.api-sports.io/football/teams/489.png',
       'awayLogo': 'https://media.api-sports.io/football/teams/497.png',
       'round': 'Giornata 38', 'date': 'Dom 4 Giu', 'time': '15:00', 'tag': 'TOP 6', 'tagColor': 0xFF2196F3},
    ];

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Row(children: [
          GestureDetector(
            onTap: () => setState(() => _showBigMatches = false),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_back_rounded, size: 18, color: lb),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.local_fire_department_rounded, size: 20, color: Color(0xFFFF7043)),
          const SizedBox(width: 8),
          Text(tr(context, 'Big Match Serie A'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: tx)),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          physics: const BouncingScrollPhysics(),
          itemCount: matches.length,
          itemBuilder: (ctx, i) {
            final m = matches[i];
            final tagColor = Color(m['tagColor'] as int);
            return GestureDetector(
              onTap: () {
                _haptic.lightImpact();
                final match = SoccerMatch(
                  id: m['id'] as int,
                  homeTeamId: 0, awayTeamId: 0,
                  homeTeamName: m['home'] as String,
                  awayTeamName: m['away'] as String,
                  homeScore: 0, awayScore: 0,
                  status: 'NS',
                  date: DateTime.now(),
                  time: m['time'] as String,
                  venue: '',
                  leagueName: 'Serie A',
                  round: m['round'] as String?,
                  homeTeamLogo: m['homeLogo'] as String?,
                  awayTeamLogo: m['awayLogo'] as String?,
                );
                Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailScreen(match: match)));
              },
              child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141B2D) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: Column(children: [
                // Header: tag + round + date
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(m['tag'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: tagColor)),
                  ),
                  const Spacer(),
                  Text('${m['round']}', style: TextStyle(fontSize: 11, color: lb)),
                  const SizedBox(width: 8),
                  Builder(builder: (ctx) {
                    final favSvc = ctx.read<FavoritesService>();
                    final matchId = m['id'] as int;
                    final isFav = favSvc.isMatchFavorite(matchId);
                    return GestureDetector(
                      onTap: () {
                        HapticService().lightImpact();
                        final wasFav = favSvc.isMatchFavorite(matchId);
                        favSvc.toggleMatchFavorite(matchId, status: 'NS');
                        if (!wasFav) {
                          favSvc.storeMatchDisplayData(matchId, {
                            'homeTeam': m['home'], 'awayTeam': m['away'],
                            'homeLogo': m['homeLogo'], 'awayLogo': m['awayLogo'],
                            'homeId': 0, 'awayId': 0, 'homeScore': null, 'awayScore': null,
                            'status': 'NS', 'date': m['date'], 'time': m['time'],
                            'league': 'Serie A', 'round': m['round'],
                          });
                        }
                        (ctx as Element).markNeedsBuild();
                      },
                      child: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 20, color: isFav ? Colors.red : lb.withValues(alpha: 0.4),
                      ),
                    );
                  }),
                  Builder(builder: (ctx) {
                    final notifSvc = ctx.read<MatchNotificationPreferencesService>();
                    final matchId = m['id'] as int;
                    final s = notifSvc.getSettingsForMatch(matchId);
                    final on_ = s.enabled && (s.notifyHomeGoals || s.notifyAwayGoals);
                    return GestureDetector(
                      onTap: () {
                        HapticService().lightImpact();
                        if (!on_) { notifSvc.enableBasicNotifications(matchId); }
                        else { notifSvc.disableAllNotifications(matchId); }
                        (ctx as Element).markNeedsBuild();
                      },
                      child: Icon(
                        on_ ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                        size: 20, color: on_ ? const Color(0xFF4CAF50) : lb.withValues(alpha: 0.4),
                      ),
                    );
                  }),
                ]),
                const SizedBox(height: 14),
                // Teams
                Row(children: [
                  Expanded(child: Column(children: [
                    CachedNetworkImage(imageUrl: m['homeLogo'] as String, width: 48, height: 48,
                        errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 48)),
                    const SizedBox(height: 6),
                    Text(m['home'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tx),
                        textAlign: TextAlign.center),
                  ])),
                  Column(children: [
                    Text(m['time'] as String, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: tx)),
                    const SizedBox(height: 4),
                    Text(m['date'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: lb)),
                  ]),
                  Expanded(child: Column(children: [
                    CachedNetworkImage(imageUrl: m['awayLogo'] as String, width: 48, height: 48,
                        errorWidget: (_, __, ___) => const Icon(Icons.shield, size: 48)),
                    const SizedBox(height: 6),
                    Text(m['away'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tx),
                        textAlign: TextAlign.center),
                  ])),
                ]),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    _positionBadge(_getTeamPosition(m['home'] as String)),
                    Expanded(child: Center(child: Text('vs', style: TextStyle(fontSize: 11, color: lb)))),
                    _positionBadge(_getTeamPosition(m['away'] as String)),
                  ]),
                ),
              ]),
            ).animate().fadeIn(delay: Duration(milliseconds: i * 60)).slideY(begin: 0.03, end: 0));
          },
        ),
      ),
    ]);
  }

  Widget _buildPlayerSuggestions(ThemeData theme, bool isDark, Color tx, Color lb) {
    final suggestedPlayers = [
      {'name': 'Lautaro Martinez', 'team': 'Inter', 'pos': 'ATT', 'goals': 24, 'assists': 5, 'rating': 7.8,
       'photo': 'https://media.api-sports.io/football/players/753.png',
       'teamLogo': 'https://media.api-sports.io/football/teams/505.png'},
      {'name': 'Nicolo Barella', 'team': 'Inter', 'pos': 'CEN', 'goals': 5, 'assists': 9, 'rating': 7.5,
       'photo': 'https://media.api-sports.io/football/players/2464.png',
       'teamLogo': 'https://media.api-sports.io/football/teams/505.png'},
      {'name': 'Rafael Leao', 'team': 'Milan', 'pos': 'ATT', 'goals': 15, 'assists': 9, 'rating': 7.3,
       'photo': 'https://media.api-sports.io/football/players/162028.png',
       'teamLogo': 'https://media.api-sports.io/football/teams/489.png'},
      {'name': 'Hakan Calhanoglu', 'team': 'Inter', 'pos': 'CEN', 'goals': 8, 'assists': 10, 'rating': 7.4,
       'photo': 'https://media.api-sports.io/football/players/2931.png',
       'teamLogo': 'https://media.api-sports.io/football/teams/505.png'},
      {'name': 'Paulo Dybala', 'team': 'Roma', 'pos': 'ATT', 'goals': 13, 'assists': 7, 'rating': 7.3,
       'photo': 'https://media.api-sports.io/football/players/1102.png',
       'teamLogo': 'https://media.api-sports.io/football/teams/497.png'},
      {'name': 'Dusan Vlahovic', 'team': 'Juventus', 'pos': 'ATT', 'goals': 16, 'assists': 0, 'rating': 7.1,
       'photo': 'https://media.api-sports.io/football/players/48444.png',
       'teamLogo': 'https://media.api-sports.io/football/teams/496.png'},
      {'name': 'Ademola Lookman', 'team': 'Atalanta', 'pos': 'ATT', 'goals': 11, 'assists': 6, 'rating': 7.2,
       'photo': 'https://media.api-sports.io/football/players/18921.png',
       'teamLogo': 'https://media.api-sports.io/football/teams/499.png'},
      {'name': 'Marcus Thuram', 'team': 'Inter', 'pos': 'ATT', 'goals': 13, 'assists': 4, 'rating': 7.1,
       'photo': 'https://media.api-sports.io/football/players/23474.png',
       'teamLogo': 'https://media.api-sports.io/football/teams/505.png'},
      {'name': 'Ciro Immobile', 'team': 'Lazio', 'pos': 'ATT', 'goals': 12, 'assists': 3, 'rating': 7.1,
       'photo': 'https://media.api-sports.io/football/players/30924.png',
       'teamLogo': 'https://media.api-sports.io/football/teams/487.png'},
      {'name': 'Khvicha Kvaratskhelia', 'team': 'Napoli', 'pos': 'ATT', 'goals': 7, 'assists': 8, 'rating': 7.2,
       'photo': 'https://media.api-sports.io/football/players/292462.png',
       'teamLogo': 'https://media.api-sports.io/football/teams/492.png'},
    ];

    Color posColor(String pos) {
      switch (pos) {
        case 'ATT': return const Color(0xFFE53935);
        case 'CEN': return const Color(0xFF43A047);
        case 'DIF': return const Color(0xFF1E88E5);
        default: return const Color(0xFFFFA726);
      }
    }

    Color ratingColor(double r) {
      if (r >= 7.5) return const Color(0xFF43A047);
      if (r >= 7.0) return const Color(0xFF66BB6A);
      if (r >= 6.5) return const Color(0xFFFFA726);
      return const Color(0xFFE53935);
    }

    return Column(children: [
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Row(children: [
          GestureDetector(
            onTap: () => setState(() => _showPlayerSuggestions = false),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.arrow_back_rounded, size: 18, color: lb),
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.people_rounded, size: 20, color: theme.primaryColor),
          const SizedBox(width: 8),
          Text(tr(context, 'Top Giocatori Serie A'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: tx)),
          const Spacer(),
          Text(tr(context, 'Per rating'), style: TextStyle(fontSize: 11, color: lb)),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          physics: const BouncingScrollPhysics(),
          itemCount: suggestedPlayers.length,
          itemBuilder: (ctx, i) {
            final p = suggestedPlayers[i];
            final rating = p['rating'] as double;
            final pos = p['pos'] as String;
            return GestureDetector(
              onTap: () {
                _haptic.lightImpact();
                final name = p['name'] as String;
                final team = p['team'] as String;
                final pos = p['pos'] as String;
                Color teamColor;
                switch (team) {
                  case 'Inter': teamColor = const Color(0xFF0068A8); break;
                  case 'Milan': teamColor = const Color(0xFFE5193E); break;
                  case 'Juventus': teamColor = const Color(0xFF000000); break;
                  case 'Napoli': teamColor = const Color(0xFF004B87); break;
                  case 'Lazio': teamColor = const Color(0xFF87CEEB); break;
                  case 'Roma': teamColor = const Color(0xFFAA1E22); break;
                  case 'Atalanta': teamColor = const Color(0xFF1B3B6F); break;
                  default: teamColor = const Color(0xFF2196F3); break;
                }
                String posCode;
                switch (pos) {
                  case 'ATT': posCode = 'F'; break;
                  case 'CEN': posCode = 'M'; break;
                  case 'DIF': posCode = 'D'; break;
                  default: posCode = 'G'; break;
                }
                final llp = LocalLineupPlayer(
                  number: name.hashCode.abs() % 99 + 1,
                  name: name,
                  position: posCode,
                  rating: (p['rating'] as double),
                  goals: (p['goals'] as int),
                  assists: (p['assists'] as int),
                );
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => MatchPlayerProfileScreen(
                    player: llp, teamName: team, teamColor: teamColor,
                  ),
                ));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF141B2D) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(children: [
                  // Posizione
                  SizedBox(width: 28, child: Center(
                    child: i < 3
                        ? Container(width: 24, height: 24, alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: i == 0 ? const Color(0xFFFFD700) : i == 1 ? const Color(0xFFC0C0C0) : const Color(0xFFCD7F32),
                              shape: BoxShape.circle),
                            child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)))
                        : Text('${i + 1}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: lb)),
                  )),
                  const SizedBox(width: 10),
                  // Foto
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: p['photo'] as String, width: 44, height: 44, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(width: 44, height: 44,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.withValues(alpha: 0.15)),
                          child: Icon(Icons.person, size: 24, color: lb)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p['name'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: tx),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: posColor(pos).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                        child: Text(pos, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: posColor(pos))),
                      ),
                      const SizedBox(width: 6),
                      CachedNetworkImage(imageUrl: p['teamLogo'] as String, width: 14, height: 14,
                          errorWidget: (_, __, ___) => const SizedBox()),
                      const SizedBox(width: 4),
                      Text(p['team'] as String, style: TextStyle(fontSize: 12, color: lb)),
                    ]),
                  ])),
                  // Stats
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('${p['goals']}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: tx)),
                      const SizedBox(width: 2),
                      Icon(Icons.sports_soccer, size: 12, color: lb.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Text('${p['assists']}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: tx)),
                      const SizedBox(width: 2),
                      Text('A', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: lb.withValues(alpha: 0.5))),
                    ]),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: ratingColor(rating).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(rating.toStringAsFixed(1),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: ratingColor(rating))),
                    ),
                  ]),
                  const SizedBox(width: 8),
                  // [TRE-ICONE-TOPGIOC] cuore + stella + campanella
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(builder: (ctx) {
                        final favSvc = ctx.watch<FavoritesService>();
                        final pid = (p['name'] as String).hashCode.abs();
                        final isFav = favSvc.isPlayerFavoriteByName(p['name'] as String); // [CUORI-BY-NAME]
                        return GestureDetector(
                          onTap: () {
                            _haptic.lightImpact();
                            if (!isFav) {
                              favSvc.storePlayerMeta(pid, {
                                'name': p['name'],
                                'position': (p['pos'] == 'ATT') ? 'F' : (p['pos'] == 'CEN') ? 'M' : (p['pos'] == 'DIF') ? 'D' : 'G',
                                'team': p['team'],
                                'teamId': 0,
                                'rating': p['rating'],
                                'goals': p['goals'],
                                'assists': p['assists'],
                              });
                            }
                            favSvc.togglePlayerFavorite(pid);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Icon(
                              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              size: 19,
                              color: isFav ? Colors.red : lb.withValues(alpha: 0.4),
                            ),
                          ),
                        );
                      }),
                      Consumer<FantaRosterService>(
                        builder: (ctx, roster, _) {
                          final pid = (p['name'] as String).hashCode.abs(); // [STELLE-BY-NAME]
                          final inRoster = roster.isInRosterByName(p['name'] as String);
                          return GestureDetector(
                            onTap: () {
                              _haptic.lightImpact();
                              final player = Player(
                                id: pid,
                                name: p['name'] as String,
                                position: p['pos'] as String,
                                teamId: 0,
                                teamName: p['team'] as String,
                                photo: p['photo'] as String?,
                                rating: (p['rating'] as num).toDouble(),
                                goals: p['goals'] as int? ?? 0,
                                assists: p['assists'] as int? ?? 0,
                              );
                              handleStarTap(context, player); // [STELLA-PICKER]
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Icon(
                                inRoster ? Icons.star_rounded : Icons.star_border_rounded,
                                size: 19,
                                color: inRoster ? const Color(0xFF9C27B0) : lb.withValues(alpha: 0.4),
                              ),
                            ),
                          );
                        },
                      ),
                      Builder(builder: (ctx) {
                        final ns = ctx.watch<PlayerNotificationPreferencesService>();
                        final hasNotif = ns.getSettingsByPlayerName(p['name'] as String) != null;
                        return GestureDetector(
                          onTap: () {
                            _haptic.lightImpact();
                            showPlayerNotificationSheet(
                              context,
                              playerName: p['name'] as String,
                              playerId: (p['name'] as String).hashCode.abs(),
                              photo: p['photo'] as String?,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Icon(
                              hasNotif ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                              size: 19,
                              color: hasNotif ? const Color(0xFF4CAF50) : lb.withValues(alpha: 0.4),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ]),
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: i * 50)).slideX(begin: 0.03, end: 0);
          },
        ),
      ),
    ]);
  }

  Widget _buildNavCard({
    required IconData icon, required String label, required String subtitle,
    required List<Color> gradient, required VoidCallback onTap,
    required bool isDark, bool compact = false,
  }) {
    return GestureDetector(
      onTap: () { _haptic.lightImpact(); onTap(); },
      child: Container(
        padding: EdgeInsets.all(compact ? 14 : 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [gradient[0].withValues(alpha: 0.15), gradient[1].withValues(alpha: 0.08)]
                : [gradient[0].withValues(alpha: 0.08), gradient[1].withValues(alpha: 0.04)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: gradient[0].withValues(alpha: isDark ? 0.2 : 0.15)),
          boxShadow: [BoxShadow(color: gradient[0].withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          Container(
            width: compact ? 42 : 50, height: compact ? 42 : 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: gradient[0].withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Icon(icon, size: compact ? 22 : 26, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: compact ? 14 : 16, fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : Colors.grey[600])),
          ])),
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: gradient[0].withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.arrow_forward_rounded, size: 16, color: gradient[0]),
          ),
        ]),
      ),
    );
  }

  Widget _buildTeamBubble(String name, String logo, String position, Color color, bool isDark, Color tx, Color lb) {
    return GestureDetector(
      onTap: () {
        _haptic.lightImpact();
        final standings = _getTeamStandings();
        final standing = standings.firstWhere(
          (s) => s.teamName == name || s.teamName.contains(name) || name.contains(s.teamName),
          orElse: () => _makeDefaultStanding(name, logo),
        );
        Navigator.push(context, MaterialPageRoute(builder: (_) => TeamDetailScreen(teamStanding: standing)));
      },
      child: Container(
        width: 76,
        margin: const EdgeInsets.only(right: 10),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56, height: 56,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: CachedNetworkImage(
                  imageUrl: logo, fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => Icon(Icons.shield, size: 28, color: lb),
                ),
              ),
              Positioned(
                right: -4, bottom: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 3)],
                  ),
                  child: Text(position, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(name, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: tx),
              maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _buildNoResults(bool isDark, Color tx, Color lb) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: lb.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: Icon(Icons.search_off_rounded, size: 48, color: lb.withValues(alpha: 0.4)),
      ),
      const SizedBox(height: 20),
      Text(tr(context, 'Nessun risultato'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: tx)),
      const SizedBox(height: 8),
      Text(tr(context, 'Prova con una ricerca diversa'), style: TextStyle(fontSize: 13, color: lb)),
    ]));
  }

  Widget _buildResults(ThemeData theme, bool isDark, Color tx, Color lb) {
    return Column(children: [
      Container(
        color: isDark ? const Color(0xFF0F1628) : Colors.white,
        child: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor: lb,
          indicatorColor: theme.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: 'Squadre (${_teamResults.length})'),
            Tab(text: 'Partite (${_matchResults.length})'),
            Tab(text: 'Giocatori (${_playerResults.length})'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(controller: _tabController, children: [
          _buildTeamResults(theme, isDark, tx, lb),
          _buildMatchResults(theme, isDark, tx, lb),
          _buildPlayerResults(theme, isDark, tx, lb),
        ]),
      ),
    ]);
  }

  Widget _buildTeamResults(ThemeData theme, bool isDark, Color tx, Color lb) {
    if (_teamResults.isEmpty) return Center(child: Text(tr(context, 'Nessuna squadra trovata'), style: TextStyle(color: lb)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _teamResults.length,
      itemBuilder: (ctx, i) {
        final team = _teamResults[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141B2D) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: team.logo != null
                ? CachedNetworkImage(imageUrl: team.logo!, width: 44, height: 44)
                : const Icon(Icons.shield, size: 44),
            title: Text(team.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
            subtitle: Text(team.country ?? 'Italia', style: TextStyle(fontSize: 12, color: lb)),
            trailing: Icon(Icons.chevron_right_rounded, color: lb.withValues(alpha: 0.4)),
            onTap: () {
              _haptic.lightImpact();
              // Find matching TeamStanding from standings data
              final standings = _getTeamStandings();
              final standing = standings.firstWhere(
                (s) => s.teamName == team.name || s.teamName.contains(team.name) || team.name.contains(s.teamName),
                orElse: () => _makeDefaultStanding(team.name, team.logo),
              );
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => TeamDetailScreen(teamStanding: standing),
              ));
            },
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 60)).slideX(begin: 0.05, end: 0);
      },
    );
  }

  Widget _buildMatchResults(ThemeData theme, bool isDark, Color tx, Color lb) {
    if (_matchResults.isEmpty) return Center(child: Text(tr(context, 'Nessuna partita trovata'), style: TextStyle(color: lb)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: _matchResults.length,
      itemBuilder: (ctx, i) {
        final m = _matchResults[i];
        final isLive = m.status == '1H' || m.status == '2H' || m.status == 'HT';
        final isFT = m.status == 'FT';
        return GestureDetector(
          onTap: () {
            _haptic.lightImpact();
            Navigator.push(context, MaterialPageRoute(builder: (_) => MatchDetailScreen(match: m)));
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF141B2D) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isLive ? const Color(0xFFFF1744).withValues(alpha: 0.3)
                  : isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
                  blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(children: [
              // Header: league + round + status
              Row(children: [
                Icon(Icons.emoji_events_rounded, size: 12, color: theme.primaryColor.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text('${m.leagueName ?? "Serie A"} \u2022 ${m.round ?? ""}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: lb)),
                const Spacer(),
                if (isLive) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFF1744), borderRadius: BorderRadius.circular(4)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 5, height: 5, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text("LIVE ${m.elapsed ?? ''}'", style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                  ]),
                ),
                if (isFT) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('FT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: lb)),
                ),
                if (!isLive && !isFT) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: theme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(tr(context, 'PROSSIMA'), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: theme.primaryColor)),
                ),
              ]),
              const SizedBox(height: 12),
              // Teams + Score — stile identico alla Home
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                // Home team
                Expanded(child: Column(children: [
                  if (m.homeTeamLogo != null)
                    CachedNetworkImage(imageUrl: m.homeTeamLogo!, width: 44, height: 44,
                        errorWidget: (_, __, ___) => const Icon(Icons.shield_rounded, size: 44))
                  else const Icon(Icons.shield_rounded, size: 44),
                  const SizedBox(height: 6),
                  Text(m.homeTeamName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tx),
                      textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                // Score / Time
                SizedBox(width: 90, child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (isLive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFFF1744), borderRadius: BorderRadius.circular(6)),
                      child: Text("${m.elapsed ?? ''}'", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (m.isScheduled) ...[
                    Text(m.time, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: tx)),
                  ] else ...[
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('${m.homeScore}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                          color: isLive ? const Color(0xFFFF1744) : tx)),
                      Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text('-', style: TextStyle(fontSize: 18, color: lb))),
                      Text('${m.awayScore}', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                          color: isLive ? const Color(0xFFFF1744) : tx)),
                    ]),
                  ],
                  if (isFT) ...[
                    const SizedBox(height: 2),
                    Text(tr(context, 'Finale'), style: TextStyle(fontSize: 10, color: lb)),
                  ],
                ])),
                // Away team
                Expanded(child: Column(children: [
                  if (m.awayTeamLogo != null)
                    CachedNetworkImage(imageUrl: m.awayTeamLogo!, width: 44, height: 44,
                        errorWidget: (_, __, ___) => const Icon(Icons.shield_rounded, size: 44))
                  else const Icon(Icons.shield_rounded, size: 44),
                  const SizedBox(height: 6),
                  Text(m.awayTeamName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tx),
                      textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
              ]),
            ]),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 50)).slideY(begin: 0.03, end: 0);
      },
    );
  }

  Widget _buildPlayerResults(ThemeData theme, bool isDark, Color tx, Color lb) {
    if (_playerResults.isEmpty) return Center(child: Text(tr(context, 'Nessun giocatore trovato'), style: TextStyle(color: lb)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _playerResults.length,
      itemBuilder: (ctx, i) {
        final p = _playerResults[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141B2D) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.withValues(alpha: 0.1)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 22,
              backgroundImage: p.photo != null ? CachedNetworkImageProvider(p.photo!) : null,
              child: p.photo == null ? const Icon(Icons.person) : null,
            ),
            title: Text(p.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tx)),
            subtitle: Text('${p.teamName} • ${p.position}', style: TextStyle(fontSize: 12, color: lb)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // [STELLA-RICERCA] stella Rosa Fanta
                Consumer<FantaRosterService>(
                  builder: (ctx, roster, _) {
                    final pid = p.name.hashCode.abs(); // [STELLE-BY-NAME]
                    final inRoster = roster.isInRosterByName(p.name);
                    return IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        inRoster ? Icons.star_rounded : Icons.star_border_rounded,
                        color: inRoster ? const Color(0xFF9C27B0) : lb,
                        size: 24,
                      ),
                      tooltip: tr(context, 'Rosa Fanta'),
                      onPressed: () {
                        _haptic.lightImpact();
                        final player = Player(
                          id: pid,
                          name: p.name,
                          position: p.position,
                          teamId: p.teamId,
                          teamName: p.teamName,
                          photo: p.photo,
                          rating: p.rating,
                          goals: p.goals ?? 0,
                          assists: p.assists ?? 0,
                        );
                        handleStarTap(context, player); // [STELLA-PICKER]
                      },
                    );
                  },
                ),
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('${p.goals}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: theme.primaryColor)),
                  Text('gol', style: TextStyle(fontSize: 10, color: lb)),
                ]),
              ],
            ),
            onTap: () {
              _haptic.lightImpact();
              final llp = LocalLineupPlayer(
                number: p.id % 99 + 1,
                name: p.name,
                position: p.position.contains("Forward") ? "F" : p.position.contains("Mid") ? "M" : p.position.contains("Def") ? "D" : "G",
                rating: 7.0,
                goals: p.goals ?? 0,
                assists: p.assists ?? 0,
              );
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => MatchPlayerProfileScreen(
                  player: llp,
                  teamName: p.teamName,
                  teamColor: const Color(0xFF2196F3),
                ),
              ));
            },
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: i * 60)).slideX(begin: 0.05, end: 0);
      },
    );
  }
}
