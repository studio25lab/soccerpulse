// lib/repositories/mock_match_repository.dart
// Implementazione mock con dati demo Lazio 2-1 Milan (2022-23)
// Quando si collegheranno le API, questa classe verrà sostituita da ApiMatchRepository

import 'match_repository.dart';
import '../models/local_lineup_player.dart';
import '../models/local_match_event.dart';
import '../models/match_stats_data.dart';
import '../models/coach_data.dart';
import 'package:soccerpulse/models/local_match_models.dart';

class MockMatchRepository implements MatchRepository {
  
  // Singleton
  static final MockMatchRepository _instance = MockMatchRepository._internal();
  factory MockMatchRepository() => _instance;
  MockMatchRepository._internal();

  @override
  Future<List<LocalMatchEvent>> getMatchEvents(int matchId) async {
    // Questo è il contenuto di _generateDetailedMockEvents()
    // Per ora ritorna lista vuota — verrà popolato dalla migrazione
    // I dati reali sono ancora in match_detail_screen.dart fino alla migrazione completa
    return [];
  }

  @override
  Future<List<LocalLineupPlayer>> getLineup(int matchId, {required bool isHome}) async {
    return [];
  }

  @override
  Future<List<LocalLineupPlayer>> getBench(int matchId, {required bool isHome}) async {
    return [];
  }

  @override
  Future<MatchStatsData> getMatchStats(int matchId) async {
    return const MatchStatsData(
      homePossession: 58, awayPossession: 42,
      homeShotsTotal: 15, awayShotsTotal: 8,
      homeShotsOnTarget: 7, awayShotsOnTarget: 3,
      homeShotsOffTarget: 5, awayShotsOffTarget: 3,
      homeBlockedShots: 3, awayBlockedShots: 2,
      homePassesTotal: 420, awayPassesTotal: 280,
      homePassesCompleted: 346, awayPassesCompleted: 217,
      homeKeyPasses: 14, awayKeyPasses: 9,
      homeCrosses: 5, awayCrosses: 4,
      homeLongBalls: 17, awayLongBalls: 24,
      homeCorners: 6, awayCorners: 4,
      homeThrowIns: 23, awayThrowIns: 24,
      homeOffsides: 3, awayOffsides: 2,
      homeTacklesTotal: 20, awayTacklesTotal: 17,
      homeTacklesWon: 15, awayTacklesWon: 11,
      homeInterceptions: 10, awayInterceptions: 8,
      homeClearances: 0, awayClearances: 0,
      homeFouls: 12, awayFouls: 15,
      homeYellowCards: 2, awayYellowCards: 3,
      homeRedCards: 0, awayRedCards: 0,
      homeXG: 1.87, awayXG: 0.95,
    );
  }

  @override
  Future<DefensiveStatsData> getDefensiveStats(int matchId, {required bool isHome}) async {
    if (isHome) {
      return const DefensiveStatsData(
        tacklesTotal: 20, tacklesWon: 15,
        interceptions: 10, clearances: 12, rinvii: 9,
      );
    } else {
      return const DefensiveStatsData(
        tacklesTotal: 17, tacklesWon: 11,
        interceptions: 8, clearances: 9, rinvii: 9,
      );
    }
  }

  @override
  Future<List<List<dynamic>>> getMomentumData(int matchId) async {
    // Placeholder — dati reali ancora in match_detail_screen.dart
    return [];
  }

  @override
  Future<CoachData?> getCoachData(String coachName) async {
    final coaches = {
      'Maurizio Sarri': CoachData(
        name: 'Maurizio Sarri',
        nationality: '🇮🇹 Italiano',
        age: 64,
        born: '10 gennaio 1959',
        formation: '4-3-3',
        teamFull: 'S.S. Lazio',
        seasonW: 14, seasonD: 7, seasonL: 6,
        seasonGoalsFor: 42, seasonGoalsAgainst: 28,
        style: 'Possesso palla, pressing alto, gioco verticale rapido',
        philosophy: 'Il "Sarrismo" si basa su un calcio offensivo e spettacolare, con movimenti sincronizzati e transizioni veloci.',
        career: const [
          CoachCareerEntry(team: 'Lazio', period: '2021-2023'),
          CoachCareerEntry(team: 'Juventus', period: '2019-2020', trophy: '🏆 Serie A'),
          CoachCareerEntry(team: 'Chelsea', period: '2018-2019', trophy: '🏆 Europa League'),
          CoachCareerEntry(team: 'Napoli', period: '2015-2018'),
          CoachCareerEntry(team: 'Empoli', period: '2012-2015'),
        ],
        stats: const CoachSeasonStats(
          matches: 27, winRate: 52, avgGoals: 1.56, cleanSheets: 8, avgPoints: 1.81,
        ),
      ),
      'Stefano Pioli': CoachData(
        name: 'Stefano Pioli',
        nationality: '🇮🇹 Italiano',
        age: 57,
        born: '20 ottobre 1965',
        formation: '4-2-3-1',
        teamFull: 'A.C. Milan',
        seasonW: 16, seasonD: 5, seasonL: 6,
        seasonGoalsFor: 48, seasonGoalsAgainst: 26,
        style: 'Transizioni rapide, pressing coordinato, gioco sulle fasce',
        philosophy: 'Calcio pragmatico e moderno, con enfasi sulle ripartenze veloci e la solidità difensiva.',
        career: const [
          CoachCareerEntry(team: 'Milan', period: '2019-2024', trophy: '🏆 Scudetto 2022'),
          CoachCareerEntry(team: 'Fiorentina', period: '2017-2019'),
          CoachCareerEntry(team: 'Inter', period: '2016-2017'),
          CoachCareerEntry(team: 'Lazio', period: '2014-2016'),
          CoachCareerEntry(team: 'Bologna', period: '2011-2014'),
        ],
        stats: const CoachSeasonStats(
          matches: 27, winRate: 59, avgGoals: 1.78, cleanSheets: 10, avgPoints: 1.96,
        ),
      ),
    };
    return coaches[coachName];
  }

  @override
  Future<String> getCoachName(int matchId, {required bool isHome}) async {
    return isHome ? 'Maurizio Sarri' : 'Stefano Pioli';
  }

  @override
  Future<List<Map<String, dynamic>>> getMatchesByDate(DateTime date) async {
    // Mock: ritorna partite hardcoded per il 14 maggio
    if (date.year == 2023 && date.month == 5 && date.day == 14) {
      return [
        {'id': 3009, 'home': 'Lazio', 'away': 'Milan', 'hScore': 2, 'aScore': 1, 'time': '20:45', 'status': 'FT', 'venue': 'Stadio Olimpico', 'round': 'Giornata 36'},
        {'id': 3010, 'home': 'Napoli', 'away': 'Inter', 'hScore': 3, 'aScore': 1, 'time': '15:00', 'status': 'FT', 'venue': 'Stadio Maradona', 'round': 'Giornata 36'},
      ];
    }
    return [];
  }

  @override
  Future<Map<DateTime, List<Map<String, dynamic>>>> getMatchesForMonth(int year, int month) async {
    // Mock: ritorna partite per maggio 2023
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> getHeadToHead(int team1Id, int team2Id) async {
    // Dati mock — Lazio vs Milan ultimi 10
    return [
      {'date': '25/02/23', 'home': 'Lazio', 'away': 'Milan', 'hScore': 2, 'aScore': 1, 'comp': 'Serie A'},
      {'date': '24/01/23', 'home': 'Milan', 'away': 'Lazio', 'hScore': 0, 'aScore': 0, 'comp': 'Coppa Italia'},
      {'date': '12/11/22', 'home': 'Milan', 'away': 'Lazio', 'hScore': 2, 'aScore': 0, 'comp': 'Serie A'},
      {'date': '24/04/22', 'home': 'Lazio', 'away': 'Milan', 'hScore': 1, 'aScore': 2, 'comp': 'Serie A'},
      {'date': '12/09/21', 'home': 'Milan', 'away': 'Lazio', 'hScore': 2, 'aScore': 0, 'comp': 'Serie A'},
      {'date': '26/04/21', 'home': 'Lazio', 'away': 'Milan', 'hScore': 3, 'aScore': 0, 'comp': 'Serie A'},
      {'date': '23/12/20', 'home': 'Milan', 'away': 'Lazio', 'hScore': 3, 'aScore': 2, 'comp': 'Serie A'},
      {'date': '04/07/20', 'home': 'Lazio', 'away': 'Milan', 'hScore': 0, 'aScore': 3, 'comp': 'Serie A'},
      {'date': '03/02/20', 'home': 'Milan', 'away': 'Lazio', 'hScore': 1, 'aScore': 2, 'comp': 'Coppa Italia'},
      {'date': '03/11/19', 'home': 'Lazio', 'away': 'Milan', 'hScore': 2, 'aScore': 0, 'comp': 'Serie A'},
    ];
  }
}
