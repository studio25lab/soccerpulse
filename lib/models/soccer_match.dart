// lib/models/soccer_match.dart

class SoccerMatch {
  final int id; // CHANGED: int invece di String
  final DateTime date;
  final String time;
  final String status;
  final int? elapsed;
  final String venue;
  final String? referee;

  // Team info
  final int homeTeamId;
  final String homeTeamName;
  final String? homeTeamLogo;
  final int awayTeamId;
  final String awayTeamName;
  final String? awayTeamLogo;

  // Score
  final int homeScore;
  final int awayScore;
  final int? homePenalty;
  final int? awayPenalty;

  // League info
  final int? leagueId;
  final String? leagueName;
  final String? leagueLogo;
  final String? leagueCountry;
  final int? season;
  final String? round;

  SoccerMatch({
    required this.id,
    required this.date,
    required this.time,
    required this.status,
    this.elapsed,
    required this.venue,
    this.referee,
    required this.homeTeamId,
    required this.homeTeamName,
    this.homeTeamLogo,
    required this.awayTeamId,
    required this.awayTeamName,
    this.awayTeamLogo,
    required this.homeScore,
    required this.awayScore,
    this.homePenalty,
    this.awayPenalty,
    this.leagueId,
    this.leagueName,
    this.leagueLogo,
    this.leagueCountry,
    this.season,
    this.round,
  });

  factory SoccerMatch.fromJson(Map<String, dynamic> json, {int? leagueId}) {
    final fixture = json['fixture'] ?? json;
    final teams = json['teams'] ?? {};
    final goals = json['goals'] ?? {};
    final league = json['league'] ?? {};
    final score = json['score'] ?? {};

    return SoccerMatch(
      id: fixture['id'] ?? 0, // CHANGED: Parse as int
      date: DateTime.parse(fixture['date'] ?? DateTime.now().toString()),
      time: _extractTime(fixture['date']),
      status: fixture['status']?['short'] ?? 'NS',
      elapsed: fixture['status']?['elapsed'],
      venue: fixture['venue']?['name'] ?? '',
      referee: fixture['referee'],
      homeTeamId: teams['home']?['id'] ?? 0,
      homeTeamName: teams['home']?['name'] ?? '',
      homeTeamLogo: teams['home']?['logo'],
      awayTeamId: teams['away']?['id'] ?? 0,
      awayTeamName: teams['away']?['name'] ?? '',
      awayTeamLogo: teams['away']?['logo'],
      homeScore: goals['home'] ?? 0,
      awayScore: goals['away'] ?? 0,
      homePenalty: score['penalty']?['home'],
      awayPenalty: score['penalty']?['away'],
      leagueId: league['id'] ?? leagueId,
      leagueName: league['name'],
      leagueLogo: league['logo'],
      leagueCountry: league['country'],
      season: league['season'],
      round: league['round'],
    );
  }

  static String _extractTime(String? dateStr) {
    if (dateStr == null) return '00:00';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '00:00';
    }
  }

  // Helper getters
  bool get isScheduled => status == 'NS' || status == 'TBD';
  bool get isLive =>
      status == 'LIVE' ||
      status == '1H' ||
      status == '2H' ||
      status == 'HT' ||
      status == 'ET' ||
      status == 'P';
  bool get isFinished => status == 'FT' || status == 'AET' || status == 'PEN';
  bool get isPostponed => status == 'PST';
  bool get isCancelled => status == 'CANC';
  bool get isHalfTime => status == 'HT';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'time': time,
      'status': status,
      'elapsed': elapsed,
      'venue': venue,
      'referee': referee,
      'homeTeamId': homeTeamId,
      'homeTeamName': homeTeamName,
      'homeTeamLogo': homeTeamLogo,
      'awayTeamId': awayTeamId,
      'awayTeamName': awayTeamName,
      'awayTeamLogo': awayTeamLogo,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'homePenalty': homePenalty,
      'awayPenalty': awayPenalty,
      'leagueId': leagueId,
      'leagueName': leagueName,
      'leagueLogo': leagueLogo,
      'leagueCountry': leagueCountry,
      'season': season,
      'round': round,
    };
  }
}
