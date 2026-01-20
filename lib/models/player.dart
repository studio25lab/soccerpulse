// lib/models/player.dart

class Player {
  final int id;
  final String name;
  final String position;
  final int teamId;
  final String teamName;
  final String? photo;
  final String? teamLogo;
  final String? nationality;
  final int? age;
  final double rating;
  final int? goals;
  final int? assists;
  final int? shots;
  final int? shotsOnTarget;
  final int? passes;
  final int? passesCompleted;
  final int? tackles;
  final int? interceptions;
  final int? foulsCommitted;
  final int? foulsSuffered;
  final int? yellowCards;
  final int? redCards;
  final int? appearances;
  final int? lineups;

  Player({
    required this.id,
    required this.name,
    required this.position,
    required this.teamId,
    required this.teamName,
    this.photo,
    this.teamLogo,
    this.nationality,
    this.age,
    this.rating = 0.0,
    this.goals,
    this.assists,
    this.shots,
    this.shotsOnTarget,
    this.passes,
    this.passesCompleted,
    this.tackles,
    this.interceptions,
    this.foulsCommitted,
    this.foulsSuffered,
    this.yellowCards,
    this.redCards,
    this.appearances,
    this.lineups,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as int,
      name: json['name'] as String,
      position: json['position'] as String? ?? 'Unknown',
      teamId: json['team_id'] as int,
      teamName: json['team_name'] as String,
      photo: json['photo'] as String?,
      teamLogo: json['team_logo'] as String?,
      nationality: json['nationality'] as String?,
      age: json['age'] as int?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      goals: json['goals'] as int?,
      assists: json['assists'] as int?,
      shots: json['shots'] as int?,
      shotsOnTarget: json['shots_on_target'] as int?,
      passes: json['passes'] as int?,
      passesCompleted: json['passes_completed'] as int?,
      tackles: json['tackles'] as int?,
      interceptions: json['interceptions'] as int?,
      foulsCommitted: json['fouls_committed'] as int?,
      foulsSuffered: json['fouls_suffered'] as int?,
      yellowCards: json['yellow_cards'] as int?,
      redCards: json['red_cards'] as int?,
      appearances: json['appearances'] as int?,
      lineups: json['lineups'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'team_id': teamId,
      'team_name': teamName,
      'photo': photo,
      'team_logo': teamLogo,
      'nationality': nationality,
      'age': age,
      'rating': rating,
      'goals': goals,
      'assists': assists,
      'shots': shots,
      'shots_on_target': shotsOnTarget,
      'passes': passes,
      'passes_completed': passesCompleted,
      'tackles': tackles,
      'interceptions': interceptions,
      'fouls_committed': foulsCommitted,
      'fouls_suffered': foulsSuffered,
      'yellow_cards': yellowCards,
      'red_cards': redCards,
      'appearances': appearances,
      'lineups': lineups,
    };
  }

  Player copyWith({
    int? id,
    String? name,
    String? position,
    int? teamId,
    String? teamName,
    String? photo,
    String? teamLogo,
    String? nationality,
    int? age,
    double? rating,
    int? goals,
    int? assists,
    int? shots,
    int? shotsOnTarget,
    int? passes,
    int? passesCompleted,
    int? tackles,
    int? interceptions,
    int? foulsCommitted,
    int? foulsSuffered,
    int? yellowCards,
    int? redCards,
    int? appearances,
    int? lineups,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      position: position ?? this.position,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      photo: photo ?? this.photo,
      teamLogo: teamLogo ?? this.teamLogo,
      nationality: nationality ?? this.nationality,
      age: age ?? this.age,
      rating: rating ?? this.rating,
      goals: goals ?? this.goals,
      assists: assists ?? this.assists,
      shots: shots ?? this.shots,
      shotsOnTarget: shotsOnTarget ?? this.shotsOnTarget,
      passes: passes ?? this.passes,
      passesCompleted: passesCompleted ?? this.passesCompleted,
      tackles: tackles ?? this.tackles,
      interceptions: interceptions ?? this.interceptions,
      foulsCommitted: foulsCommitted ?? this.foulsCommitted,
      foulsSuffered: foulsSuffered ?? this.foulsSuffered,
      yellowCards: yellowCards ?? this.yellowCards,
      redCards: redCards ?? this.redCards,
      appearances: appearances ?? this.appearances,
      lineups: lineups ?? this.lineups,
    );
  }

  @override
  String toString() {
    return 'Player(id: $id, name: $name, position: $position, team: $teamName, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Player && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
