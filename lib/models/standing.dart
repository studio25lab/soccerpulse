class Standing {
  final int rank;
  final String teamName;
  final int teamId;
  final String? teamLogo;
  final int points;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalDifference;

  Standing({
    required this.rank,
    required this.teamName,
    required this.teamId,
    this.teamLogo,
    required this.points,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalDifference,
  });

  factory Standing.fromApiSportsJson(Map<String, dynamic> json) {
    final team = json['team'] as Map<String, dynamic>?;
    final stats = json['all'] as Map<String, dynamic>?;

    return Standing(
      rank: json['rank'] as int? ?? 0,
      teamName: team?['name'] as String? ?? 'Unknown',
      teamId: team?['id'] as int? ?? 0,
      teamLogo: team?['logo'] as String?,
      points: json['points'] as int? ?? 0,
      played: stats?['played'] as int? ?? 0,
      wins: stats?['win'] as int? ?? 0,
      draws: stats?['draw'] as int? ?? 0,
      losses: stats?['lose'] as int? ?? 0,
      goalsFor: stats?['goals']?['for'] as int? ?? 0,
      goalsAgainst: stats?['goals']?['against'] as int? ?? 0,
      goalDifference: json['goalsDiff'] as int? ?? 0,
    );
  }
}
