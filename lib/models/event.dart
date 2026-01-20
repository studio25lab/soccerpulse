class Event {
  final String time;
  final String type;
  final String player;
  final String team;

  Event({
    required this.time,
    required this.type,
    required this.player,
    required this.team,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      time: json['time']['elapsed'].toString(),
      type: json['type'] ?? '',
      player: json['player']?['name'] ?? '',
      team: json['team']?['name'] ?? '',
    );
  }
}
