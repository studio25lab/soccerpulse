// lib/models/match_stats_data.dart
// Modello unificato per tutte le statistiche partita

class MatchStatsData {
  // Possesso
  final int homePossession;
  final int awayPossession;

  // Tiri
  final int homeShotsTotal, awayShotsTotal;
  final int homeShotsOnTarget, awayShotsOnTarget;
  final int homeShotsOffTarget, awayShotsOffTarget;
  final int homeBlockedShots, awayBlockedShots;

  // Passaggi
  final int homePassesTotal, awayPassesTotal;
  final int homePassesCompleted, awayPassesCompleted;
  final int homeKeyPasses, awayKeyPasses;
  final int homeCrosses, awayCrosses;
  final int homeLongBalls, awayLongBalls;

  // Generali
  final int homeCorners, awayCorners;
  final int homeThrowIns, awayThrowIns;
  final int homeOffsides, awayOffsides;

  // Difesa
  final int homeTacklesTotal, awayTacklesTotal;
  final int homeTacklesWon, awayTacklesWon;
  final int homeInterceptions, awayInterceptions;
  final int homeClearances, awayClearances;

  // Disciplina
  final int homeFouls, awayFouls;
  final int homeYellowCards, awayYellowCards;
  final int homeRedCards, awayRedCards;

  // xG
  final double homeXG, awayXG;

  const MatchStatsData({
    this.homePossession = 50, this.awayPossession = 50,
    this.homeShotsTotal = 0, this.awayShotsTotal = 0,
    this.homeShotsOnTarget = 0, this.awayShotsOnTarget = 0,
    this.homeShotsOffTarget = 0, this.awayShotsOffTarget = 0,
    this.homeBlockedShots = 0, this.awayBlockedShots = 0,
    this.homePassesTotal = 0, this.awayPassesTotal = 0,
    this.homePassesCompleted = 0, this.awayPassesCompleted = 0,
    this.homeKeyPasses = 0, this.awayKeyPasses = 0,
    this.homeCrosses = 0, this.awayCrosses = 0,
    this.homeLongBalls = 0, this.awayLongBalls = 0,
    this.homeCorners = 0, this.awayCorners = 0,
    this.homeThrowIns = 0, this.awayThrowIns = 0,
    this.homeOffsides = 0, this.awayOffsides = 0,
    this.homeTacklesTotal = 0, this.awayTacklesTotal = 0,
    this.homeTacklesWon = 0, this.awayTacklesWon = 0,
    this.homeInterceptions = 0, this.awayInterceptions = 0,
    this.homeClearances = 0, this.awayClearances = 0,
    this.homeFouls = 0, this.awayFouls = 0,
    this.homeYellowCards = 0, this.awayYellowCards = 0,
    this.homeRedCards = 0, this.awayRedCards = 0,
    this.homeXG = 0.0, this.awayXG = 0.0,
  });

  /// Factory per creare da API-Football fixture/statistics endpoint
  factory MatchStatsData.fromApiJson(List<dynamic> statsJson) {
    // statsJson è un array di 2 elementi: [homeStats, awayStats]
    if (statsJson.length < 2) return const MatchStatsData();

    final home = _parseTeamStats(statsJson[0]['statistics'] ?? []);
    final away = _parseTeamStats(statsJson[1]['statistics'] ?? []);

    return MatchStatsData(
      homePossession: _parseInt(home['Ball Possession']),
      awayPossession: _parseInt(away['Ball Possession']),
      homeShotsTotal: _parseInt(home['Total Shots']),
      awayShotsTotal: _parseInt(away['Total Shots']),
      homeShotsOnTarget: _parseInt(home['Shots on Goal']),
      awayShotsOnTarget: _parseInt(away['Shots on Goal']),
      homeShotsOffTarget: _parseInt(home['Shots off Goal']),
      awayShotsOffTarget: _parseInt(away['Shots off Goal']),
      homeBlockedShots: _parseInt(home['Blocked Shots']),
      awayBlockedShots: _parseInt(away['Blocked Shots']),
      homePassesTotal: _parseInt(home['Total passes']),
      awayPassesTotal: _parseInt(away['Total passes']),
      homePassesCompleted: _parseInt(home['Passes accurate']),
      awayPassesCompleted: _parseInt(away['Passes accurate']),
      homeCorners: _parseInt(home['Corner Kicks']),
      awayCorners: _parseInt(away['Corner Kicks']),
      homeOffsides: _parseInt(home['Offsides']),
      awayOffsides: _parseInt(away['Offsides']),
      homeFouls: _parseInt(home['Fouls']),
      awayFouls: _parseInt(away['Fouls']),
      homeYellowCards: _parseInt(home['Yellow Cards']),
      awayYellowCards: _parseInt(away['Yellow Cards']),
      homeRedCards: _parseInt(home['Red Cards']),
      awayRedCards: _parseInt(away['Red Cards']),
      homeXG: double.tryParse(home['expected_goals']?.toString() ?? '') ?? 0.0,
      awayXG: double.tryParse(away['expected_goals']?.toString() ?? '') ?? 0.0,
    );
  }

  static Map<String, dynamic> _parseTeamStats(List<dynamic> statistics) {
    final map = <String, dynamic>{};
    for (final stat in statistics) {
      map[stat['type'] ?? ''] = stat['value'];
    }
    return map;
  }

  static int _parseInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    final s = val.toString().replaceAll('%', '');
    return int.tryParse(s) ?? 0;
  }

  Map<String, dynamic> toJson() => {
    'homePossession': homePossession, 'awayPossession': awayPossession,
    'homeShotsTotal': homeShotsTotal, 'awayShotsTotal': awayShotsTotal,
    'homeShotsOnTarget': homeShotsOnTarget, 'awayShotsOnTarget': awayShotsOnTarget,
    'homePassesTotal': homePassesTotal, 'awayPassesTotal': awayPassesTotal,
    'homePassesCompleted': homePassesCompleted, 'awayPassesCompleted': awayPassesCompleted,
    'homeFouls': homeFouls, 'awayFouls': awayFouls,
    'homeYellowCards': homeYellowCards, 'awayYellowCards': awayYellowCards,
  };
}
