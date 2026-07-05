// lib/repositories/api_match_repository.dart
// Implementazione API — usa i metodi esistenti di ApiService

import 'match_repository.dart';
import '../models/match_stats_data.dart';
import '../models/coach_data.dart';
import '../api/api_service.dart';
import 'package:soccerpulse/models/local_match_models.dart';

class ApiMatchRepository implements MatchRepository {
  final ApiService _api;

  ApiMatchRepository({ApiService? api}) : _api = api ?? ApiService();

  @override
  Future<List<LocalMatchEvent>> getMatchEvents(int matchId) async {
    try {
      final events = await _api.fetchMatchEvents(matchId);
      return events.map((e) => LocalMatchEvent(
        type: _mapEventType(e['type'] ?? '', e['detail'] ?? ''),
        minute: e['time']?['elapsed'] ?? 0,
        playerName: e['player']?['name'] ?? '',
        detail: e['assist']?['name'],
        subDetail: e['comments'],
        isHomeTeam: true, // TODO: determinare da team info
        playerPhoto: e['player']?['photo'],
      )).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<LocalLineupPlayer>> getLineup(int matchId, {required bool isHome}) async {
    try {
      final lineups = await _api.fetchMatchLineups(matchId);
      if (lineups.isEmpty) return [];
      final teamIdx = isHome ? 0 : 1;
      if (teamIdx >= lineups.length) return [];
      final startXI = lineups[teamIdx]['startXI'] as List<dynamic>? ?? [];
      return startXI.map((p) {
        final player = p['player'] ?? {};
        return LocalLineupPlayer(
          number: player['number'] ?? 0,
          name: player['name'] ?? '',
          position: _mapPosition(player['pos'] ?? ''),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<LocalLineupPlayer>> getBench(int matchId, {required bool isHome}) async {
    try {
      final lineups = await _api.fetchMatchLineups(matchId);
      if (lineups.isEmpty) return [];
      final teamIdx = isHome ? 0 : 1;
      if (teamIdx >= lineups.length) return [];
      final subs = lineups[teamIdx]['substitutes'] as List<dynamic>? ?? [];
      return subs.map((p) {
        final player = p['player'] ?? {};
        return LocalLineupPlayer(
          number: player['number'] ?? 0,
          name: player['name'] ?? '',
          position: _mapPosition(player['pos'] ?? ''),
        );
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<MatchStatsData> getMatchStats(int matchId) async {
    try {
      final stats = await _api.fetchMatchStatistics(matchId);
      if (stats.length < 2) return const MatchStatsData();
      return MatchStatsData.fromApiJson(stats);
    } catch (e) {
      return const MatchStatsData();
    }
  }

  @override
  Future<DefensiveStatsData> getDefensiveStats(int matchId, {required bool isHome}) async {
    final lineup = await getLineup(matchId, isHome: isHome);
    return DefensiveStatsData(
      tacklesTotal: lineup.fold(0, (sum, p) => sum + p.tackles),
      tacklesWon: lineup.fold(0, (sum, p) => sum + p.tacklesWon),
      interceptions: lineup.fold(0, (sum, p) => sum + p.interceptions),
      clearances: lineup.fold(0, (sum, p) => sum + p.clearances),
    );
  }

  @override
  Future<List<List<dynamic>>> getMomentumData(int matchId) async {
    return [];
  }

  @override
  Future<CoachData?> getCoachData(String coachName) async {
    return null;
  }

  @override
  Future<String> getCoachName(int matchId, {required bool isHome}) async {
    try {
      final lineups = await _api.fetchMatchLineups(matchId);
      if (lineups.isEmpty) return '';
      final teamIdx = isHome ? 0 : 1;
      if (teamIdx >= lineups.length) return '';
      return lineups[teamIdx]['coach']?['name'] ?? '';
    } catch (e) {
      return '';
    }
  }

  String _mapEventType(String type, String detail) {
    switch (type.toLowerCase()) {
      case 'goal':
        if (detail.toLowerCase().contains('penalty')) return 'penalty';
        return 'goal';
      case 'card':
        if (detail.toLowerCase().contains('red')) return 'redCard';
        return 'yellowCard';
      case 'subst':
        return 'substitution';
      case 'var':
        return 'var';
      default:
        return type.toLowerCase();
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMatchesByDate(DateTime date) async {
    try {
      final matches = await _api.fetchMatchesByDate(date);
      return matches.map((m) => {
        'id': m.id,
        'home': m.homeTeamName,
        'away': m.awayTeamName,
        'hScore': m.homeScore,
        'aScore': m.awayScore,
        'time': m.time,
        'status': m.status,
        'venue': m.venue,
        'round': m.round ?? '',
        'homeTeamLogo': m.homeTeamLogo,
        'awayTeamLogo': m.awayTeamLogo,
        'leagueName': m.leagueName,
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Map<DateTime, List<Map<String, dynamic>>>> getMatchesForMonth(int year, int month) async {
    try {
      // Carica ogni giorno del mese con partite
      final Map<DateTime, List<Map<String, dynamic>>> result = {};
      // L'API-Football supporta fetchMatchesByDate per singola data
      // Per efficienza, iteriamo sui giorni del mese
      final daysInMonth = DateTime(year, month + 1, 0).day;
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(year, month, day);
        final matches = await getMatchesByDate(date);
        if (matches.isNotEmpty) {
          result[date] = matches;
        }
      }
      return result;
    } catch (e) {
      return {};
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getHeadToHead(int team1Id, int team2Id) async {
    try {
      final matches = await _api.fetchHeadToHead(team1Id, team2Id);
      // Converte List<SoccerMatch> in List<Map> per la UI
      return matches.map((m) => {
        'date': '${m.date.day.toString().padLeft(2, '0')}/${m.date.month.toString().padLeft(2, '0')}/${m.date.year.toString().substring(2)}',
        'home': m.homeTeamName,
        'away': m.awayTeamName,
        'hScore': m.homeScore,
        'aScore': m.awayScore,
        'comp': m.leagueName ?? 'Serie A',
      }).toList();
    } catch (e) {
      return [];
    }
  }

  String _mapPosition(String pos) {
    const mapping = {'G': 'GK', 'D': 'CB', 'M': 'CM', 'F': 'ST'};
    return mapping[pos] ?? pos;
  }
}
