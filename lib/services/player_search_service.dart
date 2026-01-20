import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/player.dart';

class PlayerSearchService {
  static const String _apiKey = '9ec406038497dc769c87bb51c88fdce7';
  static const String _baseUrl = 'https://v3.football.api-sports.io';

  // Cache per i risultati delle ricerche
  final Map<String, List<Player>> _searchCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Durata della cache: 1 ora
  static const Duration _cacheDuration = Duration(hours: 1);

  // Timer per il debounce
  Timer? _debounceTimer;

  /// Cerca giocatori per nome con debounce e cache
  Future<List<Player>> searchPlayers(
    String query, {
    Duration debounceDuration = const Duration(milliseconds: 500),
  }) async {
    // Completer per gestire il debounce
    final completer = Completer<List<Player>>();

    // Cancella il timer precedente se esiste
    _debounceTimer?.cancel();

    // Crea un nuovo timer per il debounce
    _debounceTimer = Timer(debounceDuration, () async {
      try {
        final results = await _performSearch(query);
        completer.complete(results);
      } catch (e) {
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  /// Esegue la ricerca effettiva con gestione cache
  Future<List<Player>> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    final normalizedQuery = query.trim().toLowerCase();

    // Controlla la cache
    if (_isCacheValid(normalizedQuery)) {
      print('🎯 Risultati dalla cache per: $normalizedQuery');
      return _searchCache[normalizedQuery]!;
    }

    print('🔍 Ricerca API per: $normalizedQuery');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/players?search=$query'),
        headers: {
          'x-rapidapi-key': _apiKey,
          'x-rapidapi-host': 'v3.football.api-sports.io',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['response'] != null && data['response'] is List) {
          final players = <Player>[];

          for (final item in data['response']) {
            if (item['player'] != null) {
              try {
                final player = _parsePlayer(item);
                if (player != null) {
                  players.add(player);
                }
              } catch (e) {
                print('⚠️ Errore parsing giocatore: $e');
              }
            }
          }

          // Salva nella cache
          _searchCache[normalizedQuery] = players;
          _cacheTimestamps[normalizedQuery] = DateTime.now();

          print('✅ Trovati ${players.length} giocatori');
          return players;
        }
      }

      print('❌ Errore API: ${response.statusCode}');
      throw Exception('Errore durante la ricerca: ${response.statusCode}');
    } catch (e) {
      print('❌ Errore ricerca: $e');
      rethrow;
    }
  }

  /// Verifica se i dati in cache sono ancora validi
  bool _isCacheValid(String query) {
    if (!_searchCache.containsKey(query)) {
      return false;
    }

    final timestamp = _cacheTimestamps[query];
    if (timestamp == null) {
      return false;
    }

    final age = DateTime.now().difference(timestamp);
    return age < _cacheDuration;
  }

  /// Converte i dati API in un oggetto Player
  Player? _parsePlayer(Map<String, dynamic> data) {
    try {
      final playerData = data['player'] as Map<String, dynamic>?;
      if (playerData == null) return null;

      final statistics = data['statistics'] as List?;
      final firstStat = (statistics != null && statistics.isNotEmpty)
          ? statistics.first as Map<String, dynamic>?
          : null;

      final team = firstStat?['team'] as Map<String, dynamic>?;
      final games = firstStat?['games'] as Map<String, dynamic>?;

      return Player(
        id: playerData['id'] as int? ?? 0,
        name: playerData['name'] as String? ?? 'Unknown',
        position: games?['position'] as String? ?? 'Unknown',
        teamId: team?['id'] as int? ?? 0,
        teamName: team?['name'] as String? ?? 'Unknown',
        photo: playerData['photo'] as String?,
        nationality: playerData['nationality'] as String?,
        age: playerData['age'] as int?,
        rating: _parseRating(firstStat) ?? 0.0,
      );
    } catch (e) {
      print('⚠️ Errore parsing player: $e');
      return null;
    }
  }

  /// Estrae il rating dalle statistiche
  double? _parseRating(Map<String, dynamic>? statistics) {
    if (statistics == null) return null;

    try {
      final games = statistics['games'] as Map<String, dynamic>?;
      if (games == null) return null;

      final rating = games['rating'];
      if (rating == null) return null;

      if (rating is num) {
        return rating.toDouble();
      }

      if (rating is String) {
        return double.tryParse(rating);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Pulisce la cache
  void clearCache() {
    _searchCache.clear();
    _cacheTimestamps.clear();
    print('🗑️ Cache pulita');
  }

  /// Pulisce la cache scaduta
  void cleanExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      final age = now.difference(entry.value);
      if (age >= _cacheDuration) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      _searchCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      print('🗑️ Rimossi ${expiredKeys.length} elementi scaduti dalla cache');
    }
  }

  /// Ottiene dettagli completi di un giocatore specifico
  Future<Player?> getPlayerDetails(int playerId) async {
    print('🔍 Ricerca dettagli giocatore ID: $playerId');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/players?id=$playerId&season=2024'),
        headers: {
          'x-rapidapi-key': _apiKey,
          'x-rapidapi-host': 'v3.football.api-sports.io',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['response'] != null &&
            data['response'] is List &&
            (data['response'] as List).isNotEmpty) {
          return _parsePlayer(data['response'][0]);
        }
      }

      return null;
    } catch (e) {
      print('❌ Errore ricerca dettagli: $e');
      return null;
    }
  }

  /// Cerca giocatori per squadra
  Future<List<Player>> searchPlayersByTeam(
    int teamId, {
    int season = 2024,
  }) async {
    final cacheKey = 'team_${teamId}_$season';

    // Controlla la cache
    if (_isCacheValid(cacheKey)) {
      print('🎯 Giocatori squadra dalla cache: $teamId');
      return _searchCache[cacheKey]!;
    }

    print('🔍 Ricerca giocatori squadra: $teamId');

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/players?team=$teamId&season=$season'),
        headers: {
          'x-rapidapi-key': _apiKey,
          'x-rapidapi-host': 'v3.football.api-sports.io',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['response'] != null && data['response'] is List) {
          final players = <Player>[];

          for (final item in data['response']) {
            final player = _parsePlayer(item);
            if (player != null) {
              players.add(player);
            }
          }

          // Salva nella cache
          _searchCache[cacheKey] = players;
          _cacheTimestamps[cacheKey] = DateTime.now();

          print('✅ Trovati ${players.length} giocatori per squadra $teamId');
          return players;
        }
      }

      throw Exception('Errore durante la ricerca: ${response.statusCode}');
    } catch (e) {
      print('❌ Errore ricerca giocatori squadra: $e');
      rethrow;
    }
  }

  /// Dispose del servizio
  void dispose() {
    _debounceTimer?.cancel();
    clearCache();
  }
}
