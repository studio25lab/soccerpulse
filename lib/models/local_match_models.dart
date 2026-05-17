// lib/models/local_match_models.dart
// Extracted from match_detail_screen.dart for reuse across the app

class LocalLineupPlayer {
  final int number;
  final String name;
  final String position;
  final double rating;
  // Attack
  final int goals, assists, shots, shotsOnTarget;
  final double xG, xA;
  final int keyPasses;
  // Possession
  final int passes, passesCompleted, touches, dribbles, dribblesSuccessful;
  final int crosses, crossesCompleted, ballsLost;
  // Defense
  final int tackles, tacklesWon, interceptions, clearances, recoveries;
  final int duelsTotal, duelsWon, aerialTotal, aerialWon;
  // Discipline
  final int fouls, foulsWon, yellowCards, redCards, offsides;
  // General
  final int minutesPlayed;

  LocalLineupPlayer({
    required this.number,
    required this.name,
    required this.position,
    this.rating = 6.0,
    this.goals = 0,
    this.assists = 0,
    this.shots = 0,
    this.shotsOnTarget = 0,
    this.xG = 0.0,
    this.xA = 0.0,
    this.keyPasses = 0,
    this.passes = 0,
    this.passesCompleted = 0,
    this.touches = 0,
    this.dribbles = 0,
    this.dribblesSuccessful = 0,
    this.crosses = 0,
    this.crossesCompleted = 0,
    this.ballsLost = 0,
    this.tackles = 0,
    this.tacklesWon = 0,
    this.interceptions = 0,
    this.clearances = 0,
    this.recoveries = 0,
    this.duelsTotal = 0,
    this.duelsWon = 0,
    this.aerialTotal = 0,
    this.aerialWon = 0,
    this.fouls = 0,
    this.foulsWon = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.offsides = 0,
    this.minutesPlayed = 90,
  });
}

class LocalMatchEvent {
  final String type;
  final int minute;
  final String playerName;
  final String? detail, subDetail, playerPhoto;
  final bool isHomeTeam;
  LocalMatchEvent(
      {required this.type,
      required this.minute,
      required this.playerName,
      this.detail,
      this.subDetail,
      required this.isHomeTeam,
      this.playerPhoto});
}
