class Lineup {
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final String formation;
  final String? coach;
  final List<LineupPlayer> startXI;
  final List<LineupPlayer> substitutes;

  Lineup({
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    required this.formation,
    this.coach,
    required this.startXI,
    required this.substitutes,
  });

  factory Lineup.fromApiSportsJson(Map<String, dynamic> json) {
    final team = json['team'] as Map<String, dynamic>;
    final startXI = json['startXI'] as List?;
    final substitutes = json['substitutes'] as List?;

    return Lineup(
      teamId: team['id'] as int,
      teamName: team['name'] as String,
      teamLogo: team['logo'] as String?,
      formation: json['formation'] as String? ?? '4-3-3',
      coach: json['coach']?['name'] as String?,
      startXI: startXI
              ?.map((p) => LineupPlayer.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      substitutes: substitutes
              ?.map((p) => LineupPlayer.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class LineupPlayer {
  final int playerId;
  final String playerName;
  final int number;
  final String position;
  final String? grid;

  LineupPlayer({
    required this.playerId,
    required this.playerName,
    required this.number,
    required this.position,
    this.grid,
  });

  factory LineupPlayer.fromJson(Map<String, dynamic> json) {
    final player = json['player'] as Map<String, dynamic>;

    return LineupPlayer(
      playerId: player['id'] as int,
      playerName: player['name'] as String,
      number: player['number'] as int? ?? 0,
      position: player['pos'] as String? ?? 'Unknown',
      grid: player['grid'] as String?,
    );
  }
}
