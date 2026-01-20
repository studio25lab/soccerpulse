class MatchEvent {
  final int time;
  final String type; // Goal, Card, subst
  final String teamName;
  final String playerName;
  final String? assistPlayerName;
  final String? detail; // Yellow Card, Red Card, Normal Goal, Penalty, etc.

  MatchEvent({
    required this.time,
    required this.type,
    required this.teamName,
    required this.playerName,
    this.assistPlayerName,
    this.detail,
  });

  factory MatchEvent.fromApiSportsJson(Map<String, dynamic> json) {
    final time = json['time']?['elapsed'] ?? 0;
    final type = (json['type'] ?? '') as String;
    final team = json['team'] ?? {};
    final player = json['player'] ?? {};
    final assist = json['assist'] ?? {};
    final detail = json['detail'] as String?;

    return MatchEvent(
      time: time is int ? time : 0,
      type: type,
      teamName: team['name'] ?? '',
      playerName: player['name'] ?? '',
      assistPlayerName: assist['name'],
      detail: detail,
    );
  }

  bool get isGoal => type.toLowerCase() == 'goal';
  bool get isCard => type.toLowerCase() == 'card';
  bool get isSubstitution => type.toLowerCase() == 'subst';

  bool get isYellowCard => detail?.toLowerCase().contains('yellow') ?? false;
  bool get isRedCard => detail?.toLowerCase().contains('red') ?? false;

  String get eventIcon {
    if (isGoal) return '⚽';
    if (isRedCard) return '🟥';
    if (isYellowCard) return '🟨';
    if (isSubstitution) return '🔄';
    return '•';
  }

  @override
  String toString() {
    String text = "$time' $eventIcon $playerName";
    if (isGoal && assistPlayerName != null) {
      text += ' (assist: $assistPlayerName)';
    }
    return text;
  }
}
