// lib/models/local_lineup_player.dart
// Modello giocatore formazione con tutte le statistiche partita

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

  const LocalLineupPlayer({
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

  /// Factory per creare da dati API (API-Football / football-data)
  factory LocalLineupPlayer.fromApiJson(Map<String, dynamic> json) {
    final stats = json['statistics']?[0] ?? {};
    final games = stats['games'] ?? {};
    final shots = stats['shots'] ?? {};
    final goals = stats['goals'] ?? {};
    final passes = stats['passes'] ?? {};
    final tackles = stats['tackles'] ?? {};
    final duels = stats['duels'] ?? {};
    final dribbles = stats['dribbles'] ?? {};
    final fouls = stats['fouls'] ?? {};
    final cards = stats['cards'] ?? {};
    final offsides = stats['offsides'] ?? {};

    return LocalLineupPlayer(
      number: json['player']?['number'] ?? 0,
      name: json['player']?['name'] ?? '',
      position: _mapApiPosition(games['position'] ?? ''),
      rating: double.tryParse(games['rating']?.toString() ?? '') ?? 0.0,
      goals: goals['total'] ?? 0,
      assists: goals['assists'] ?? 0,
      shots: shots['total'] ?? 0,
      shotsOnTarget: shots['on'] ?? 0,
      passes: passes['total'] ?? 0,
      passesCompleted: passes['accuracy'] != null
          ? ((passes['total'] ?? 0) * (int.tryParse(passes['accuracy'].toString()) ?? 0) / 100).round()
          : 0,
      keyPasses: passes['key'] ?? 0,
      touches: 0, // Non fornito da API-Football, calcolabile
      dribbles: dribbles['attempts'] ?? 0,
      dribblesSuccessful: dribbles['success'] ?? 0,
      tackles: tackles['total'] ?? 0,
      tacklesWon: tackles['blocks'] ?? 0, // approssimazione
      interceptions: tackles['interceptions'] ?? 0,
      duelsTotal: duels['total'] ?? 0,
      duelsWon: duels['won'] ?? 0,
      fouls: fouls['committed'] ?? 0,
      foulsWon: fouls['drawn'] ?? 0,
      yellowCards: cards['yellow'] ?? 0,
      redCards: cards['red'] ?? 0,
      offsides: offsides['total'] ?? 0,
      minutesPlayed: games['minutes'] ?? 0,
    );
  }

  static String _mapApiPosition(String apiPos) {
    const mapping = {
      'G': 'GK', 'Goalkeeper': 'GK',
      'D': 'CB', 'Defender': 'CB',
      'M': 'CM', 'Midfielder': 'CM',
      'F': 'ST', 'Attacker': 'ST',
    };
    return mapping[apiPos] ?? apiPos;
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'name': name,
    'position': position,
    'rating': rating,
    'goals': goals,
    'assists': assists,
    'shots': shots,
    'shotsOnTarget': shotsOnTarget,
    'xG': xG,
    'xA': xA,
    'keyPasses': keyPasses,
    'passes': passes,
    'passesCompleted': passesCompleted,
    'touches': touches,
    'dribbles': dribbles,
    'dribblesSuccessful': dribblesSuccessful,
    'crosses': crosses,
    'crossesCompleted': crossesCompleted,
    'ballsLost': ballsLost,
    'tackles': tackles,
    'tacklesWon': tacklesWon,
    'interceptions': interceptions,
    'clearances': clearances,
    'recoveries': recoveries,
    'duelsTotal': duelsTotal,
    'duelsWon': duelsWon,
    'aerialTotal': aerialTotal,
    'aerialWon': aerialWon,
    'fouls': fouls,
    'foulsWon': foulsWon,
    'yellowCards': yellowCards,
    'redCards': redCards,
    'offsides': offsides,
    'minutesPlayed': minutesPlayed,
  };
}
