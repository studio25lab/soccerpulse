class PlayerComparison {
  final String id;
  final List<PlayerComparisonData> players;
  final DateTime createdAt;
  final String name;
  final bool isFavorite;

  PlayerComparison({
    required this.id,
    required this.players,
    required this.createdAt,
    required this.name,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'players': players.map((p) => p.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'name': name,
      'isFavorite': isFavorite,
    };
  }

  factory PlayerComparison.fromJson(Map<String, dynamic> json) {
    return PlayerComparison(
      id: json['id'],
      players: (json['players'] as List)
          .map((p) => PlayerComparisonData.fromJson(p))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      name: json['name'],
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  PlayerComparison copyWith({
    String? id,
    List<PlayerComparisonData>? players,
    DateTime? createdAt,
    String? name,
    bool? isFavorite,
  }) {
    return PlayerComparison(
      id: id ?? this.id,
      players: players ?? this.players,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class PlayerComparisonData {
  final int playerId;
  final String name;
  final String? photo;
  final String teamName;
  final int number;
  final String position;

  // Statistiche
  final int matches;
  final int goals;
  final int assists;
  final int minutes;
  final double averageRating;
  final int yellowCards;
  final int redCards;

  // Statistiche avanzate
  final int shots;
  final int shotsOnTarget;
  final double passingAccuracy;
  final int dribbles;
  final int tackles;
  final int interceptions;

  // Skills (per radar chart)
  final Map<String, double> skills;

  PlayerComparisonData({
    required this.playerId,
    required this.name,
    this.photo,
    required this.teamName,
    required this.number,
    required this.position,
    required this.matches,
    required this.goals,
    required this.assists,
    required this.minutes,
    required this.averageRating,
    required this.yellowCards,
    required this.redCards,
    required this.shots,
    required this.shotsOnTarget,
    required this.passingAccuracy,
    required this.dribbles,
    required this.tackles,
    required this.interceptions,
    required this.skills,
  });

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'name': name,
      'photo': photo,
      'teamName': teamName,
      'number': number,
      'position': position,
      'matches': matches,
      'goals': goals,
      'assists': assists,
      'minutes': minutes,
      'averageRating': averageRating,
      'yellowCards': yellowCards,
      'redCards': redCards,
      'shots': shots,
      'shotsOnTarget': shotsOnTarget,
      'passingAccuracy': passingAccuracy,
      'dribbles': dribbles,
      'tackles': tackles,
      'interceptions': interceptions,
      'skills': skills,
    };
  }

  factory PlayerComparisonData.fromJson(Map<String, dynamic> json) {
    return PlayerComparisonData(
      playerId: json['playerId'],
      name: json['name'],
      photo: json['photo'],
      teamName: json['teamName'],
      number: json['number'],
      position: json['position'],
      matches: json['matches'],
      goals: json['goals'],
      assists: json['assists'],
      minutes: json['minutes'],
      averageRating: json['averageRating'].toDouble(),
      yellowCards: json['yellowCards'],
      redCards: json['redCards'],
      shots: json['shots'],
      shotsOnTarget: json['shotsOnTarget'],
      passingAccuracy: json['passingAccuracy'].toDouble(),
      dribbles: json['dribbles'],
      tackles: json['tackles'],
      interceptions: json['interceptions'],
      skills: Map<String, double>.from(json['skills']),
    );
  }
}
