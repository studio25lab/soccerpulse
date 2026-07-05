// lib/repositories/match_repository.dart
// Interfaccia astratta per dati partita — implementata da Mock e API

import '../models/match_stats_data.dart';
import '../models/coach_data.dart';
import 'package:soccerpulse/models/local_match_models.dart';

/// Defensive stats (ripulito da widget)
class DefensiveStatsData {
  final int tacklesTotal, tacklesWon;
  final int interceptions;
  final int clearances;
  final int rinvii;
  
  const DefensiveStatsData({
    this.tacklesTotal = 0,
    this.tacklesWon = 0,
    this.interceptions = 0,
    this.clearances = 0,
    this.rinvii = 0,
  });
}

/// Interfaccia astratta — tutte le fonti dati implementano questa
abstract class MatchRepository {
  /// Eventi partita (goal, cartellini, sostituzioni, ecc.)
  Future<List<LocalMatchEvent>> getMatchEvents(int matchId);
  
  /// Formazione titolare
  Future<List<LocalLineupPlayer>> getLineup(int matchId, {required bool isHome});
  
  /// Panchina
  Future<List<LocalLineupPlayer>> getBench(int matchId, {required bool isHome});
  
  /// Statistiche partita aggregate
  Future<MatchStatsData> getMatchStats(int matchId);
  
  /// Statistiche difensive per squadra
  Future<DefensiveStatsData> getDefensiveStats(int matchId, {required bool isHome});
  
  /// Dati momentum attacco (90 data points)
  Future<List<List<dynamic>>> getMomentumData(int matchId);
  
  /// Dati allenatore
  Future<CoachData?> getCoachData(String coachName);
  
  /// Nome allenatore per squadra
  Future<String> getCoachName(int matchId, {required bool isHome});

  /// Scontri diretti tra due squadre
  Future<List<Map<String, dynamic>>> getHeadToHead(int team1Id, int team2Id);

  /// Partite per una data specifica (per calendario)
  Future<List<Map<String, dynamic>>> getMatchesByDate(DateTime date);

  /// Partite per un intero mese (per calendario)
  Future<Map<DateTime, List<Map<String, dynamic>>>> getMatchesForMonth(int year, int month);
}
