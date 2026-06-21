// lib/services/match_data_service.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/match_data.dart';
import '../models/soccer_match.dart';
import '../models/match_event.dart' as me;
import '../models/match_statistics.dart';
import '../api/api_service.dart';

/// ⭐ SERVICE CENTRALIZZATO - Carica e gestisce TUTTI i dati della partita
///
/// UNICA FONTE DI VERITÀ per:
/// - Eventi timeline
/// - Statistiche partita
/// - Formazioni
/// - Dati giocatori
///
/// TUTTE le schermate leggono da qui = DATI SEMPRE COERENTI!
class MatchDataService {
  static final MatchDataService _instance = MatchDataService._internal();
  factory MatchDataService() => _instance;
  MatchDataService._internal();

  final ApiService _apiService = ApiService();

  // Cache dei dati caricati (matchId -> MatchData)
  final Map<int, MatchData> _cache = {};

  /// Carica TUTTI i dati di una partita
  ///
  /// Carica da API e processa:
  /// - Eventi (goals, cards, substitutions)
  /// - Statistiche aggregate
  /// - Formazioni (titolari + panchina)
  /// - Statistiche dettagliate per giocatore
  ///
  /// Fallback a mock data se API non disponibile
  Future<MatchData> loadMatchData(int matchId,
      {bool forceRefresh = false}) async {
    // Check cache
    if (!forceRefresh && _cache.containsKey(matchId)) {
      print('📦 MatchData loaded from cache for match $matchId');
      return _cache[matchId]!;
    }

    // [FAV-demo-mock] matchId=9001 (Lazio vs Milan demo) ha id collidente
    // con una partita reale di API-Football. Forza mock locale.
    if (matchId == 9001) {
      print('📦 Demo match 9001 -> using MOCK data directly');
      final mock = _generateMockMatchData(matchId);
      _cache[matchId] = mock;
      return mock;
    }
    print('🔄 Loading MatchData for match $matchId from API...');

    try {
      // 1. Carica dati base partita (se non già disponibile)
      // Assumiamo che SoccerMatch sia già stato caricato prima

      // 2. Carica eventi
      final apiEvents = await _apiService.fetchMatchEvents(matchId);
      final events = _processEvents(apiEvents);

      // 3. Carica statistiche
      final apiStats = await _apiService.fetchMatchStatistics(matchId);
      final statistics = _processStatistics(apiStats);

      // 4. Carica formazioni
      final apiLineups = await _apiService.fetchMatchLineups(matchId);
      final lineupsData = _processLineups(apiLineups, events);

      // 5. Genera statistiche per giocatore
      final playerStats = _generatePlayerStats(
        lineupsData['home']! + lineupsData['homeBench']!,
        lineupsData['away']! + lineupsData['awayBench']!,
        events,
        true, // isHome
      );

      // 6. Crea MatchData unificato
      final matchData = MatchData(
        match: _createMatchFromId(
            matchId), // Placeholder - in produzione usa match reale
        events: events,
        statistics: statistics,
        homeLineup: lineupsData['home']!,
        awayLineup: lineupsData['away']!,
        homeBench: lineupsData['homeBench']!,
        awayBench: lineupsData['awayBench']!,
        playerStats: playerStats,
        homeCoach: lineupsData['homeCoach'],
        awayCoach: lineupsData['awayCoach'],
      );

      // Salva in cache
      _cache[matchId] = matchData;

      print(
          '✅ MatchData loaded successfully: ${events.length} events, ${playerStats.length} players');

      return matchData;
    } catch (e) {
      print('⚠️ Error loading match data from API: $e');
      print('📦 Falling back to MOCK data');

      // Fallback a mock data
      return _generateMockMatchData(matchId);
    }
  }

  /// Processa eventi dall'API
  List<me.MatchEvent> _processEvents(List<Map<String, dynamic>> apiEvents) {
    if (apiEvents.isEmpty) return [];

    return apiEvents
        .map((json) => me.MatchEvent.fromApiSportsJson(json))
        .toList()
      ..sort((a, b) => a.minute.compareTo(b.minute)); // Ordina cronologicamente
  }

  /// Processa statistiche dall'API
  MatchStatistics? _processStatistics(List<Map<String, dynamic>> apiStats) {
    if (apiStats.isEmpty) return null;

    // L'API restituisce array con statistiche per squadra
    // Dobbiamo estrarre i valori e creare il modello

    final Map<String, dynamic> homeStats = {};
    final Map<String, dynamic> awayStats = {};

    for (var stat in apiStats) {
      final type = stat['type'] as String?;
      final value = stat['value'];

      if (type != null) {
        if (stat['team'] == 'home') {
          homeStats[type] = value;
        } else {
          awayStats[type] = value;
        }
      }
    }

    return MatchStatistics(
      possessionHome: _parseInt(homeStats['Ball Possession']),
      possessionAway: _parseInt(awayStats['Ball Possession']),
      shotsHome: _parseInt(homeStats['Total Shots']),
      shotsAway: _parseInt(awayStats['Total Shots']),
      shotsOnTargetHome: _parseInt(homeStats['Shots on Goal']),
      shotsOnTargetAway: _parseInt(awayStats['Shots on Goal']),
      cornersHome: _parseInt(homeStats['Corner Kicks']),
      cornersAway: _parseInt(awayStats['Corner Kicks']),
      foulsHome: _parseInt(homeStats['Fouls']),
      foulsAway: _parseInt(awayStats['Fouls']),
      yellowCardsHome: _parseInt(homeStats['Yellow Cards']),
      yellowCardsAway: _parseInt(awayStats['Yellow Cards']),
      redCardsHome: _parseInt(homeStats['Red Cards']),
      redCardsAway: _parseInt(awayStats['Red Cards']),
    );
  }

  /// Processa formazioni dall'API
  Map<String, dynamic> _processLineups(
    List<Map<String, dynamic>> apiLineups,
    List<me.MatchEvent> events,
  ) {
    if (apiLineups.isEmpty || apiLineups.length < 2) {
      return {
        'home': <LineupPlayer>[],
        'away': <LineupPlayer>[],
        'homeBench': <LineupPlayer>[],
        'awayBench': <LineupPlayer>[],
        'homeCoach': null,
        'awayCoach': null,
      };
    }

    final homeData = apiLineups[0];
    final awayData = apiLineups[1];

    return {
      'home': _parseTeamLineup(homeData['startXI'] ?? [], events, true),
      'away': _parseTeamLineup(awayData['startXI'] ?? [], events, false),
      'homeBench': _parseTeamLineup(homeData['substitutes'] ?? [], events, true,
          isBench: true),
      'awayBench': _parseTeamLineup(
          awayData['substitutes'] ?? [], events, false,
          isBench: true),
      'homeCoach': homeData['coach']?['name'],
      'awayCoach': awayData['coach']?['name'],
    };
  }

  /// Parse lineup di una squadra
  List<LineupPlayer> _parseTeamLineup(
      List<dynamic> lineup, List<me.MatchEvent> events, bool isHome,
      {bool isBench = false}) {
    return lineup.map<LineupPlayer>((playerData) {
      final player = playerData['player'] ?? {};
      final name = player['name'] ?? '';
      final number = player['number'] ?? 0;
      final position = player['pos'] ?? '';
      final gridData = player['grid']?.split(':') ?? [];

      // Trova eventi del giocatore
      final playerEvents = events
          .where((e) => e.playerName.toLowerCase() == name.toLowerCase())
          .toList();

      // Calcola statistiche rapide
      final goals = playerEvents.where((e) => e.isGoal).length;
      final assists = playerEvents
          .where((e) => e.assistPlayerName?.isNotEmpty ?? false)
          .length;
      final yellowCards = playerEvents.where((e) => e.isYellowCard).length;
      final redCards = playerEvents.where((e) => e.isRedCard).length;

      // Check sostituzione
      final subEvent = events.firstWhere(
        (e) =>
            e.isSubstitution &&
            e.playerName.toLowerCase() == name.toLowerCase(),
        orElse: () => me.MatchEvent(
          minute: 0,
          type: '',
          team: '',
          playerName: '',
        ),
      );

      return LineupPlayer(
        number: number is int ? number : int.tryParse(number.toString()) ?? 0,
        name: name,
        position: position,
        isPlaying: !isBench,
        gridX: gridData.isNotEmpty ? int.tryParse(gridData[0]) : null,
        gridY: gridData.length > 1 ? int.tryParse(gridData[1]) : null,
        goals: goals,
        assists: assists,
        yellowCards: yellowCards,
        redCards: redCards,
        isSubstituted: subEvent.type.isNotEmpty,
        substitutionMinute: subEvent.type.isNotEmpty ? subEvent.minute : null,
        substitutePlayerName: subEvent.detail,
      );
    }).toList();
  }

  /// Genera statistiche dettagliate per ogni giocatore
  Map<String, PlayerMatchStats> _generatePlayerStats(
    List<LineupPlayer> homePlayers,
    List<LineupPlayer> awayPlayers,
    List<me.MatchEvent> events,
    bool generateMockData,
  ) {
    final Map<String, PlayerMatchStats> stats = {};

    // Processa giocatori casa
    for (var player in homePlayers) {
      stats[player.name.toLowerCase()] = _createPlayerStats(
        player,
        events,
        'Home Team',
        true,
        generateMockData,
      );
    }

    // Processa giocatori trasferta
    for (var player in awayPlayers) {
      stats[player.name.toLowerCase()] = _createPlayerStats(
        player,
        events,
        'Away Team',
        false,
        generateMockData,
      );
    }

    return stats;
  }

  /// Crea statistiche per un singolo giocatore
  PlayerMatchStats _createPlayerStats(
    LineupPlayer player,
    List<me.MatchEvent> events,
    String teamName,
    bool isHome,
    bool generateMockData,
  ) {
    // In produzione, questi dati vengono dall'API
    // Per ora generiamo dati mock realistici

    if (!generateMockData) {
      // TODO: Parse da API quando disponibile
      return _generateMockPlayerStats(player, teamName, isHome);
    }

    return _generateMockPlayerStats(player, teamName, isHome);
  }

  /// Genera dati mock per un giocatore (usato come fallback)
  PlayerMatchStats _generateMockPlayerStats(
    LineupPlayer player,
    String teamName,
    bool isHome,
  ) {
    final random = math.Random(player.name.hashCode);

    // Genera tiri
    final shotsCount = player.position.contains('Attaccante')
        ? random.nextInt(4) + 2
        : random.nextInt(3);
    final shots = List.generate(shotsCount, (i) {
      final isGoal = i == 0 && player.goals > 0;
      final onTarget = isGoal || random.nextBool();

      return ShotData(
        playerName: player.name,
        minute: 10 + random.nextInt(80),
        position: Offset(
          0.5 + random.nextDouble() * 0.4,
          0.2 + random.nextDouble() * 0.6,
        ),
        goalPosition: onTarget
            ? Offset(
                0.45 + random.nextDouble() * 0.1,
                0.3 + random.nextDouble() * 0.4,
              )
            : null,
        isGoal: isGoal,
        onTarget: onTarget,
        xG: 0.05 + random.nextDouble() * 0.4,
      );
    });

    // Genera passaggi
    final passesCount = 20 + random.nextInt(40);
    final accuratePasses =
        (passesCount * (0.7 + random.nextDouble() * 0.25)).round();
    final passes = List.generate(passesCount, (i) {
      final isAccurate = i < accuratePasses;
      return PassData(
        playerName: player.name,
        minute: 1 + random.nextInt(90),
        from: Offset(
          0.2 + random.nextDouble() * 0.6,
          0.2 + random.nextDouble() * 0.6,
        ),
        to: Offset(
          0.2 + random.nextDouble() * 0.6,
          0.2 + random.nextDouble() * 0.6,
        ),
        isAccurate: isAccurate,
        isKeyPass: random.nextDouble() < 0.1,
      );
    });

    // Genera dribbling
    final dribblesCount = player.position.contains('Ala')
        ? random.nextInt(6) + 2
        : random.nextInt(4);
    final dribbles = List.generate(dribblesCount, (i) {
      // ✅ CORRETTO: Genera posizione from e to per il dribbling
      final fromX = 0.3 + random.nextDouble() * 0.4;
      final fromY = 0.2 + random.nextDouble() * 0.6;
      final toX = (fromX + random.nextDouble() * 0.1 - 0.05).clamp(0.0, 1.0);
      final toY = (fromY + random.nextDouble() * 0.1 - 0.05).clamp(0.0, 1.0);

      return DribbleData(
        playerName: player.name,
        minute: 5 + random.nextInt(85),
        from: Offset(fromX, fromY),
        to: Offset(toX, toY),
        successful: random.nextDouble() > 0.4,
      );
    });

    // Genera heatmap positions
    final heatmapCount = 50 + random.nextInt(100);
    final heatmapPositions = List.generate(heatmapCount, (i) {
      return Offset(
        0.2 + random.nextDouble() * 0.6,
        0.1 + random.nextDouble() * 0.8,
      );
    });

    return PlayerMatchStats(
      playerName: player.name,
      playerNumber: player.number,
      position: player.position,
      teamName: teamName,
      isHome: isHome,
      minutesPlayed:
          player.isSubstituted ? (player.substitutionMinute ?? 90) : 90,
      rating: 6.0 + random.nextDouble() * 2.5,
      isSubstituted: player.isSubstituted,
      substitutionMinute: player.substitutionMinute,
      goals: player.goals,
      assists: player.assists,
      shots: shots,
      shotsOnTarget: shots.where((s) => s.onTarget).length,
      shotsBlocked: shots.where((s) => s.isBlocked).length,
      shotsOffTarget: shots.where((s) => !s.onTarget && !s.isBlocked).length,
      passes: passes,
      totalPasses: passesCount,
      accuratePasses: accuratePasses,
      keyPasses: passes.where((p) => p.isKeyPass).length,
      dribbles: dribbles,
      successfulDribbles: dribbles.where((d) => d.successful).length,
      failedDribbles: dribbles.where((d) => !d.successful).length,
      tackles: player.position.contains('Difensore')
          ? random.nextInt(5) + 2
          : random.nextInt(3),
      interceptions: random.nextInt(4),
      foulsCommitted: player.fouls,
      yellowCards: player.yellowCards,
      redCards: player.redCards,
      heatmapPositions: heatmapPositions,
    );
  }

  /// Genera MatchData mock completo (fallback se API non disponibile)
  MatchData _generateMockMatchData(int matchId) {
    print('📦 Generating MOCK MatchData...');

    // Eventi mock
    final events = _generateMockEvents();

    // Formazioni mock
    final homeLineup = _generateMockLineup(true);
    final awayLineup = _generateMockLineup(false);
    final homeBench = _generateMockBench(true);
    final awayBench = _generateMockBench(false);

    // Statistiche giocatori
    final playerStats = _generatePlayerStats(
      homeLineup + homeBench,
      awayLineup + awayBench,
      events,
      true,
    );

    // Statistiche aggregate
    final statistics = MatchStatistics(
      possessionHome: 58,
      possessionAway: 42,
      shotsHome: 15,
      shotsAway: 8,
      shotsOnTargetHome: 7,
      shotsOnTargetAway: 3,
      cornersHome: 6,
      cornersAway: 4,
      foulsHome: 12,
      foulsAway: 15,
      yellowCardsHome: 2,
      yellowCardsAway: 3,
      redCardsHome: 0,
      redCardsAway: 0,
    );

    return MatchData(
      match: _createMatchFromId(matchId),
      events: events,
      statistics: statistics,
      homeLineup: homeLineup,
      awayLineup: awayLineup,
      homeBench: homeBench,
      awayBench: awayBench,
      playerStats: playerStats,
      homeCoach: 'Maurizio Sarri',
      awayCoach: 'Stefano Pioli',
    );
  }

  /// Helper: Parse int da valore dinamico
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) {
      // Rimuovi caratteri come "%"
      final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(cleaned) ?? 0;
    }
    return 0;
  }

  /// Helper: Crea SoccerMatch placeholder
  SoccerMatch _createMatchFromId(int matchId) {
    // In produzione, questo dovrebbe venire dal cache o essere passato
    return SoccerMatch(
      id: matchId,
      date: DateTime.now(),
      time: '20:00',
      status: 'FT',
      venue: 'Stadio Olimpico',
      homeTeamId: 1,
      homeTeamName: 'Lazio',
      homeTeamLogo: null,
      awayTeamId: 2,
      awayTeamName: 'Milan',
      awayTeamLogo: null,
      homeScore: 2,
      awayScore: 1,
      leagueId: 135,
      leagueName: 'Serie A',
    );
  }

  /// Mock data generators (usati come fallback)

  List<me.MatchEvent> _generateMockEvents() {
    return [
      me.MatchEvent(
        minute: 12,
        type: 'goal',
        team: 'Lazio',
        playerName: 'Immobile',
        assistPlayerName: 'Zaccagni',
        detail: 'Normal Goal',
      ),
      me.MatchEvent(
        minute: 23,
        type: 'yellowCard',
        team: 'Lazio',
        playerName: 'Pellegrini',
        detail: 'Yellow Card',
      ),
      me.MatchEvent(
        minute: 56,
        type: 'goal',
        team: 'Milan',
        playerName: 'Giroud',
        assistPlayerName: 'Leao',
        detail: 'Normal Goal',
      ),
      me.MatchEvent(
        minute: 65,
        type: 'substitution',
        team: 'Lazio',
        playerName: 'Luis Alberto',
        detail: 'Cataldi',
      ),
      me.MatchEvent(
        minute: 78,
        type: 'goal',
        team: 'Lazio',
        playerName: 'Felipe Anderson',
        assistPlayerName: 'Guendouzi',
        detail: 'Normal Goal',
      ),
      me.MatchEvent(
        minute: 88,
        type: 'yellowCard',
        team: 'Lazio',
        playerName: 'Guendouzi',
        detail: 'Yellow Card',
      ),
    ];
  }

  List<LineupPlayer> _generateMockLineup(bool isHome) {
    if (isHome) {
      return [
        LineupPlayer(
            number: 1, name: 'Provedel', position: 'Portiere', rating: 7.0),
        LineupPlayer(
            number: 23,
            name: 'Pellegrini',
            position: 'Terzino Sinistro',
            rating: 6.8,
            isSubstituted: true,
            substitutionMinute: 78,
            substitutePlayerName: 'Hysaj',
            assists: 1),
        LineupPlayer(
            number: 13,
            name: 'Romagnoli',
            position: 'Difensore Centrale',
            rating: 7.5),
        LineupPlayer(
            number: 4,
            name: 'Patric',
            position: 'Difensore Centrale',
            rating: 7.0),
        LineupPlayer(
            number: 77,
            name: 'Marusic',
            position: 'Terzino Destro',
            rating: 6.5,
            yellowCards: 1),
        LineupPlayer(
            number: 6,
            name: 'Rovella',
            position: 'Centrocampista',
            rating: 7.2),
        LineupPlayer(
            number: 8,
            name: 'Guendouzi',
            position: 'Centrocampista',
            rating: 8.0,
            assists: 1,
            yellowCards: 1),
        LineupPlayer(
            number: 10,
            name: 'Luis Alberto',
            position: 'Centrocampista',
            rating: 7.8,
            isSubstituted: true,
            substitutionMinute: 65,
            substitutePlayerName: 'Cataldi',
            assists: 1),
        LineupPlayer(
            number: 20,
            name: 'Zaccagni',
            position: 'Ala Sinistra',
            rating: 7.5,
            assists: 1),
        LineupPlayer(
            number: 9,
            name: 'Immobile',
            position: 'Attaccante',
            rating: 8.5,
            goals: 1),
        LineupPlayer(
            number: 7,
            name: 'Felipe Anderson',
            position: 'Ala Destra',
            rating: 8.2,
            goals: 1),
      ];
    } else {
      return [
        LineupPlayer(
            number: 16, name: 'Maignan', position: 'Portiere', rating: 6.5),
        LineupPlayer(
            number: 19,
            name: 'Theo Hernandez',
            position: 'Terzino Sinistro',
            rating: 7.0),
        LineupPlayer(
            number: 23,
            name: 'Tomori',
            position: 'Difensore Centrale',
            rating: 6.8),
        LineupPlayer(
            number: 28,
            name: 'Thiaw',
            position: 'Difensore Centrale',
            rating: 6.5),
        LineupPlayer(
            number: 2,
            name: 'Calabria',
            position: 'Terzino Destro',
            rating: 6.7),
        LineupPlayer(
            number: 8,
            name: 'Loftus-Cheek',
            position: 'Centrocampista',
            rating: 7.0),
        LineupPlayer(
            number: 14,
            name: 'Reijnders',
            position: 'Centrocampista',
            rating: 7.2),
        LineupPlayer(
            number: 10, name: 'Pulisic', position: 'Ala Destra', rating: 7.5),
        LineupPlayer(
            number: 17,
            name: 'Leao',
            position: 'Ala Sinistra',
            rating: 7.8,
            assists: 1),
        LineupPlayer(
            number: 9,
            name: 'Giroud',
            position: 'Attaccante',
            rating: 7.5,
            goals: 1),
        LineupPlayer(
            number: 11, name: 'Chukwueze', position: 'Attaccante', rating: 6.8),
      ];
    }
  }

  List<LineupPlayer> _generateMockBench(bool isHome) {
    if (isHome) {
      return [
        LineupPlayer(
            number: 94, name: 'Mandas', position: 'Portiere', isPlaying: false),
        LineupPlayer(
            number: 34,
            name: 'Hysaj',
            position: 'Difensore',
            isPlaying: false,
            rating: 6.5),
        LineupPlayer(
            number: 18,
            name: 'Cataldi',
            position: 'Centrocampista',
            isPlaying: false,
            rating: 6.8),
        LineupPlayer(
            number: 11,
            name: 'Pedro',
            position: 'Attaccante',
            isPlaying: false),
        LineupPlayer(
            number: 19,
            name: 'Castellanos',
            position: 'Attaccante',
            isPlaying: false),
      ];
    } else {
      return [
        LineupPlayer(
            number: 83,
            name: 'Mirante',
            position: 'Portiere',
            isPlaying: false),
        LineupPlayer(
            number: 46,
            name: 'Gabbia',
            position: 'Difensore',
            isPlaying: false),
        LineupPlayer(
            number: 32,
            name: 'Pobega',
            position: 'Centrocampista',
            isPlaying: false),
        LineupPlayer(
            number: 22,
            name: 'Musah',
            position: 'Centrocampista',
            isPlaying: false),
        LineupPlayer(
            number: 21,
            name: 'Okafor',
            position: 'Attaccante',
            isPlaying: false),
      ];
    }
  }

  /// Pulisci cache
  void clearCache() {
    _cache.clear();
  }

  /// Ottieni MatchData dalla cache (se disponibile)
  MatchData? getCachedMatchData(int matchId) {
    return _cache[matchId];
  }
}
