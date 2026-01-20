// lib/api/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/soccer_match.dart';
import '../models/team_standing.dart';
import '../models/player.dart';

class ApiService {
  static const String _baseUrl = 'https://v3.football.api-sports.io';
  static const String _apiKey = '9ec406038497dc769c87bb51c88fdce7';

  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Cache maps
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  // Headers per le richieste
  Map<String, String> get _headers => {
        'x-apisports-key': _apiKey,
        'Content-Type': 'application/json',
      };

  // Metodo helper per verificare se la cache è valida
  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key)) return false;
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return false;
    return DateTime.now().difference(timestamp) < _cacheValidDuration;
  }

  // Metodo generico per fare richieste GET
  Future<dynamic> _get(String endpoint,
      {Map<String, String>? queryParams}) async {
    try {
      final uri =
          Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParams);
      final cacheKey = uri.toString();

      // Check cache
      if (_isCacheValid(cacheKey)) {
        return _cache[cacheKey];
      }

      final response = await http.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Cache the response
        _cache[cacheKey] = data;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return data;
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('API Error: $e');
      throw Exception('Network error: $e');
    }
  }

  // Fetch matches by date
  Future<List<SoccerMatch>> fetchMatchesByDate(DateTime date,
      {int? leagueId, bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        _cache.clear();
      }

      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final params = {
        'date': dateStr,
        if (leagueId != null) 'league': leagueId.toString(),
        'season': '2023', // CHANGED: Using 2023 for free plan
      };

      final response = await _get('/fixtures', queryParams: params);

      if (response['response'] != null) {
        final matches = (response['response'] as List)
            .map((json) => SoccerMatch.fromJson(json, leagueId: leagueId))
            .toList();
        return matches;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching matches by date: $e');
      return [];
    }
  }

  // Fetch matches by league
  Future<List<SoccerMatch>> fetchMatchesByLeague(int leagueId,
      {bool forceRefresh = false}) async {
    try {
      if (forceRefresh) {
        _cache.clear();
      }

      final params = {
        'league': leagueId.toString(),
        'season': '2023', // CHANGED: Using 2023 for free plan
      };

      final response = await _get('/fixtures', queryParams: params);

      if (response['response'] != null) {
        final matches = (response['response'] as List)
            .map((json) => SoccerMatch.fromJson(json, leagueId: leagueId))
            .toList();
        return matches;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching matches by league: $e');
      return [];
    }
  }

  // Fetch standings
  Future<List<TeamStanding>> fetchStandings(int leagueId) async {
    try {
      final params = {
        'league': leagueId.toString(),
        'season': '2023', // CHANGED: Using 2023 for free plan
      };

      final response = await _get('/standings', queryParams: params);

      if (response['response'] != null && response['response'].isNotEmpty) {
        final standings = <TeamStanding>[];
        final league = response['response'][0]['league'];

        if (league['standings'] != null && league['standings'].isNotEmpty) {
          final standingsData = league['standings'][0] as List;

          for (var item in standingsData) {
            standings.add(TeamStanding.fromJson(item, leagueId: leagueId));
          }
        }

        return standings;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching standings: $e');
      return [];
    }
  }

  // Fetch top scorers
  Future<List<Player>> fetchTopScorers(int leagueId) async {
    try {
      final params = {
        'league': leagueId.toString(),
        'season': '2023', // CHANGED: Using 2023 for free plan
      };

      final response = await _get('/players/topscorers', queryParams: params);

      if (response['response'] != null) {
        final players = (response['response'] as List)
            .map((json) => Player.fromJson(json))
            .toList();
        return players;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching top scorers: $e');
      return [];
    }
  }

  // Fetch top assists
  Future<List<Player>> fetchTopAssists(int leagueId) async {
    try {
      final params = {
        'league': leagueId.toString(),
        'season': '2023', // CHANGED: Using 2023 for free plan
      };

      final response = await _get('/players/topassists', queryParams: params);

      if (response['response'] != null) {
        final players = (response['response'] as List)
            .map((json) => Player.fromJson(json))
            .toList();
        return players;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching top assists: $e');
      return [];
    }
  }

  // Fetch top yellow cards
  Future<List<Player>> fetchTopYellowCards(int leagueId) async {
    try {
      final params = {
        'league': leagueId.toString(),
        'season': '2023', // CHANGED: Using 2023 for free plan
      };

      final response =
          await _get('/players/topyellowcards', queryParams: params);

      if (response['response'] != null) {
        final players = (response['response'] as List)
            .map((json) => Player.fromJson(json))
            .toList();
        return players;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching top yellow cards: $e');
      return [];
    }
  }

  // Fetch top red cards
  Future<List<Player>> fetchTopRedCards(int leagueId) async {
    try {
      final params = {
        'league': leagueId.toString(),
        'season': '2023', // CHANGED: Using 2023 for free plan
      };

      final response = await _get('/players/topredcards', queryParams: params);

      if (response['response'] != null) {
        final players = (response['response'] as List)
            .map((json) => Player.fromJson(json))
            .toList();
        return players;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching top red cards: $e');
      return [];
    }
  }

  // Fetch match statistics
  Future<List<Map<String, dynamic>>> fetchMatchStatistics(int matchId) async {
    try {
      final params = {
        'fixture': matchId.toString(),
      };

      final response = await _get('/fixtures/statistics', queryParams: params);

      if (response['response'] != null && response['response'].isNotEmpty) {
        final stats = <Map<String, dynamic>>[];
        final teamStats = response['response'] as List;

        if (teamStats.length >= 2) {
          final homeStats = teamStats[0]['statistics'] as List;
          final awayStats = teamStats[1]['statistics'] as List;

          for (int i = 0; i < homeStats.length && i < awayStats.length; i++) {
            stats.add({
              'type': homeStats[i]['type'],
              'home': homeStats[i]['value'],
              'away': awayStats[i]['value'],
            });
          }
        }

        return stats;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching match statistics: $e');
      return [];
    }
  }

  // Fetch match events
  Future<List<Map<String, dynamic>>> fetchMatchEvents(int matchId) async {
    try {
      final params = {
        'fixture': matchId.toString(),
      };

      final response = await _get('/fixtures/events', queryParams: params);

      if (response['response'] != null) {
        return List<Map<String, dynamic>>.from(response['response']);
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching match events: $e');
      return [];
    }
  }

  // Fetch match lineups
  Future<List<Map<String, dynamic>>> fetchMatchLineups(int matchId) async {
    try {
      final params = {
        'fixture': matchId.toString(),
      };

      final response = await _get('/fixtures/lineups', queryParams: params);

      if (response['response'] != null) {
        return List<Map<String, dynamic>>.from(response['response']);
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching match lineups: $e');
      return [];
    }
  }

  // Fetch head to head
  Future<List<SoccerMatch>> fetchHeadToHead(int team1Id, int team2Id) async {
    try {
      final params = {
        'h2h': '${team1Id}-${team2Id}',
        'last': '10',
      };

      final response = await _get('/fixtures/headtohead', queryParams: params);

      if (response['response'] != null) {
        final matches = (response['response'] as List)
            .map((json) => SoccerMatch.fromJson(json))
            .toList();
        return matches;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching head to head: $e');
      return [];
    }
  }

  // Fetch teams by league
  Future<List<Map<String, dynamic>>> fetchTeamsByLeague(int leagueId) async {
    try {
      final params = {
        'league': leagueId.toString(),
        'season': '2023', // CHANGED: Using 2023 for free plan
      };

      final response = await _get('/teams', queryParams: params);

      if (response['response'] != null) {
        return List<Map<String, dynamic>>.from(response['response']);
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching teams: $e');
      return [];
    }
  }

  // Clear cache
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
}
