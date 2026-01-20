// lib/models/team_standing.dart

class TeamStanding {
  final int teamId;
  final String teamName;
  final String? teamLogo;
  final int position; // ADDED
  final int leagueId; // ADDED
  final int points;
  final int played;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int goalsDiff; // ADDED
  final String? form;
  final String? description;
  final TeamStats home; // ADDED
  final TeamStats away; // ADDED
  final String status;
  final DateTime? update;

  TeamStanding({
    required this.teamId,
    required this.teamName,
    this.teamLogo,
    required this.position,
    required this.leagueId,
    required this.points,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.goalsDiff,
    this.form,
    this.description,
    required this.home,
    required this.away,
    this.status = 'same',
    this.update,
  });

  factory TeamStanding.fromJson(Map<String, dynamic> json, {int? leagueId}) {
    final team = json['team'] ?? {};
    final all = json['all'] ?? {};
    final home = json['home'] ?? {};
    final away = json['away'] ?? {};

    return TeamStanding(
      teamId: team['id'] ?? 0,
      teamName: team['name'] ?? '',
      teamLogo: team['logo'],
      position: json['rank'] ?? 0,
      leagueId: leagueId ?? 135,
      points: json['points'] ?? 0,
      played: all['played'] ?? 0,
      wins: all['win'] ?? 0,
      draws: all['draw'] ?? 0,
      losses: all['lose'] ?? 0,
      goalsFor: all['goals']?['for'] ?? 0,
      goalsAgainst: all['goals']?['against'] ?? 0,
      goalsDiff: json['goalsDiff'] ?? 0,
      form: json['form'],
      description: json['description'],
      home: TeamStats.fromJson(home),
      away: TeamStats.fromJson(away),
      status: json['status'] ?? 'same',
      update: json['update'] != null ? DateTime.tryParse(json['update']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'teamLogo': teamLogo,
      'position': position,
      'leagueId': leagueId,
      'points': points,
      'played': played,
      'wins': wins,
      'draws': draws,
      'losses': losses,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
      'goalsDiff': goalsDiff,
      'form': form,
      'description': description,
      'home': home.toJson(),
      'away': away.toJson(),
      'status': status,
      'update': update?.toIso8601String(),
    };
  }
}

// Classe per le statistiche casa/trasferta
class TeamStats {
  final int played;
  final int win;
  final int draw;
  final int lose;
  final int goalsFor;
  final int goalsAgainst;

  TeamStats({
    required this.played,
    required this.win,
    required this.draw,
    required this.lose,
    required this.goalsFor,
    required this.goalsAgainst,
  });

  factory TeamStats.fromJson(Map<String, dynamic> json) {
    return TeamStats(
      played: json['played'] ?? 0,
      win: json['win'] ?? 0,
      draw: json['draw'] ?? 0,
      lose: json['lose'] ?? 0,
      goalsFor: json['goals']?['for'] ?? 0,
      goalsAgainst: json['goals']?['against'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'played': played,
      'win': win,
      'draw': draw,
      'lose': lose,
      'goalsFor': goalsFor,
      'goalsAgainst': goalsAgainst,
    };
  }
}
