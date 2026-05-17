// lib/models/coach_season_stats.dart

/// Statistiche di un allenatore per una stagione specifica
class CoachSeasonStats {
  final String season; // Es: "2022/23"
  final int wins; // Vittorie
  final int draws; // Pareggi
  final int losses; // Sconfitte
  final int matchesPlayed; // Partite giocate
  final int goalsScored; // Gol segnati
  final int goalsConceded; // Gol subiti
  final String? teamName; // Nome squadra (opzionale)
  final String? teamLogo; // URL logo squadra (opzionale)
  final String? trophies; // Trofei vinti (opzionale)

  CoachSeasonStats({
    required this.season,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.matchesPlayed,
    required this.goalsScored,
    required this.goalsConceded,
    this.teamName,
    this.teamLogo,
    this.trophies,
  });

  /// Percentuale di vittorie
  double get winPercentage {
    if (matchesPlayed == 0) return 0.0;
    return (wins / matchesPlayed) * 100;
  }

  /// Differenza reti
  int get goalDifference => goalsScored - goalsConceded;

  /// Media gol segnati per partita
  double get avgGoalsScored {
    if (matchesPlayed == 0) return 0.0;
    return goalsScored / matchesPlayed;
  }

  /// Media gol subiti per partita
  double get avgGoalsConceded {
    if (matchesPlayed == 0) return 0.0;
    return goalsConceded / matchesPlayed;
  }

  /// Punti totali (3 per vittoria, 1 per pareggio)
  int get totalPoints => (wins * 3) + draws;

  /// Media punti per partita
  double get avgPoints {
    if (matchesPlayed == 0) return 0.0;
    return totalPoints / matchesPlayed;
  }

  /// Ha vinto trofei in questa stagione?
  bool get hasTrophies => trophies != null && trophies!.isNotEmpty;

  /// Crea da JSON
  factory CoachSeasonStats.fromJson(Map<String, dynamic> json) {
    return CoachSeasonStats(
      season: json['season'] as String,
      wins: json['wins'] as int,
      draws: json['draws'] as int,
      losses: json['losses'] as int,
      matchesPlayed: json['matchesPlayed'] as int,
      goalsScored: json['goalsScored'] as int,
      goalsConceded: json['goalsConceded'] as int,
      teamName: json['teamName'] as String?,
      teamLogo: json['teamLogo'] as String?,
      trophies: json['trophies'] as String?,
    );
  }

  /// Converte in JSON
  Map<String, dynamic> toJson() {
    return {
      'season': season,
      'wins': wins,
      'draws': draws,
      'losses': losses,
      'matchesPlayed': matchesPlayed,
      'goalsScored': goalsScored,
      'goalsConceded': goalsConceded,
      'teamName': teamName,
      'teamLogo': teamLogo,
      'trophies': trophies,
    };
  }

  /// Copia con modifiche
  CoachSeasonStats copyWith({
    String? season,
    int? wins,
    int? draws,
    int? losses,
    int? matchesPlayed,
    int? goalsScored,
    int? goalsConceded,
    String? teamName,
    String? teamLogo,
    String? trophies,
  }) {
    return CoachSeasonStats(
      season: season ?? this.season,
      wins: wins ?? this.wins,
      draws: draws ?? this.draws,
      losses: losses ?? this.losses,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      goalsScored: goalsScored ?? this.goalsScored,
      goalsConceded: goalsConceded ?? this.goalsConceded,
      teamName: teamName ?? this.teamName,
      teamLogo: teamLogo ?? this.teamLogo,
      trophies: trophies ?? this.trophies,
    );
  }

  @override
  String toString() {
    return 'CoachSeasonStats(season: $season, matches: $matchesPlayed, wins: $wins, winRate: ${winPercentage.toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CoachSeasonStats &&
        other.season == season &&
        other.wins == wins &&
        other.draws == draws &&
        other.losses == losses &&
        other.matchesPlayed == matchesPlayed &&
        other.goalsScored == goalsScored &&
        other.goalsConceded == goalsConceded &&
        other.teamName == teamName;
  }

  @override
  int get hashCode {
    return season.hashCode ^
        wins.hashCode ^
        draws.hashCode ^
        losses.hashCode ^
        matchesPlayed.hashCode ^
        goalsScored.hashCode ^
        goalsConceded.hashCode ^
        teamName.hashCode;
  }
}
