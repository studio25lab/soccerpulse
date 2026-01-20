class Player {
  final int id;
  final String name;
  final String number;
  final String pos;
  final bool isStarter;

  Player({
    required this.id,
    required this.name,
    required this.number,
    required this.pos,
    required this.isStarter,
  });

  factory Player.fromJson(Map<String, dynamic> json, bool isStarter) {
    return Player(
      id: json['player']['id'],
      name: json['player']['name'],
      number: json['player']['number'].toString(),
      pos: json['player']['pos'],
      isStarter: isStarter,
    );
  }
}

class TeamLineup {
  final String teamName;
  final String formation;
  final List<Player> starting;
  final List<Player> substitutes;

  TeamLineup({
    required this.teamName,
    required this.formation,
    required this.starting,
    required this.substitutes,
  });

  factory TeamLineup.fromJson(Map<String, dynamic> json) {
    List<Player> starters =
        (json['startXI'] as List).map((p) => Player.fromJson(p, true)).toList();

    List<Player> bench = (json['substitutes'] as List)
        .map((p) => Player.fromJson(p, false))
        .toList();

    return TeamLineup(
      teamName: json['team']['name'],
      formation: json['formation'],
      starting: starters,
      substitutes: bench,
    );
  }
}
