// lib/models/match_statistics.dart

class MatchStatistics {
  final int possessionHome;
  final int possessionAway;
  final int shotsHome;
  final int shotsAway;
  final int shotsOnTargetHome;
  final int shotsOnTargetAway;
  final int cornersHome;
  final int cornersAway;
  final int foulsHome;
  final int foulsAway;
  final int yellowCardsHome;
  final int yellowCardsAway;
  final int redCardsHome;
  final int redCardsAway;

  MatchStatistics({
    required this.possessionHome,
    required this.possessionAway,
    required this.shotsHome,
    required this.shotsAway,
    required this.shotsOnTargetHome,
    required this.shotsOnTargetAway,
    required this.cornersHome,
    required this.cornersAway,
    required this.foulsHome,
    required this.foulsAway,
    required this.yellowCardsHome,
    required this.yellowCardsAway,
    required this.redCardsHome,
    required this.redCardsAway,
  });

  factory MatchStatistics.fromJson(Map<String, dynamic> json) {
    return MatchStatistics(
      possessionHome: json['possession_home'] ?? 0,
      possessionAway: json['possession_away'] ?? 0,
      shotsHome: json['shots_home'] ?? 0,
      shotsAway: json['shots_away'] ?? 0,
      shotsOnTargetHome: json['shots_on_target_home'] ?? 0,
      shotsOnTargetAway: json['shots_on_target_away'] ?? 0,
      cornersHome: json['corners_home'] ?? 0,
      cornersAway: json['corners_away'] ?? 0,
      foulsHome: json['fouls_home'] ?? 0,
      foulsAway: json['fouls_away'] ?? 0,
      yellowCardsHome: json['yellow_cards_home'] ?? 0,
      yellowCardsAway: json['yellow_cards_away'] ?? 0,
      redCardsHome: json['red_cards_home'] ?? 0,
      redCardsAway: json['red_cards_away'] ?? 0,
    );
  }
}
