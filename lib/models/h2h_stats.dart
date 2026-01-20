class H2HStats {
  final int team1Wins;
  final int team2Wins;
  final int draws;
  final int totalMeetings;
  final int team1Goals;
  final int team2Goals;
  final String? biggestWinTeam1;
  final String? biggestWinTeam2;
  final List<H2HMatch> matches;

  H2HStats({
    required this.team1Wins,
    required this.team2Wins,
    required this.draws,
    required this.totalMeetings,
    required this.team1Goals,
    required this.team2Goals,
    this.biggestWinTeam1,
    this.biggestWinTeam2,
    required this.matches,
  });

  double get team1WinPercentage =>
      totalMeetings > 0 ? (team1Wins / totalMeetings) * 100 : 0;

  double get team2WinPercentage =>
      totalMeetings > 0 ? (team2Wins / totalMeetings) * 100 : 0;

  double get drawPercentage =>
      totalMeetings > 0 ? (draws / totalMeetings) * 100 : 0;

  double get avgGoalsPerMatch =>
      totalMeetings > 0 ? (team1Goals + team2Goals) / totalMeetings : 0;

  String getCurrentStreak(int team1Id) {
    if (matches.isEmpty) return 'N/A';

    int streak = 0;
    String? lastResult;

    for (var match in matches) {
      String result;
      if (match.homeTeamId == team1Id) {
        if (match.homeScore > match.awayScore) {
          result = 'W1';
        } else if (match.homeScore < match.awayScore) {
          result = 'W2';
        } else {
          result = 'D';
        }
      } else {
        if (match.awayScore > match.homeScore) {
          result = 'W1';
        } else if (match.awayScore < match.homeScore) {
          result = 'W2';
        } else {
          result = 'D';
        }
      }

      if (lastResult == null) {
        lastResult = result;
        streak = 1;
      } else if (result == lastResult) {
        streak++;
      } else {
        break;
      }
    }

    if (lastResult == 'W1') return '$streak vittorie consecutive';
    if (lastResult == 'W2') return '$streak sconfitte consecutive';
    return '$streak pareggi consecutivi';
  }
}

class H2HMatch {
  final int fixtureId;
  final DateTime date;
  final int homeTeamId;
  final String homeTeamName;
  final String? homeTeamLogo;
  final int awayTeamId;
  final String awayTeamName;
  final String? awayTeamLogo;
  final int homeScore;
  final int awayScore;
  final String? venue;
  final String? referee;
  final String status;

  H2HMatch({
    required this.fixtureId,
    required this.date,
    required this.homeTeamId,
    required this.homeTeamName,
    this.homeTeamLogo,
    required this.awayTeamId,
    required this.awayTeamName,
    this.awayTeamLogo,
    required this.homeScore,
    required this.awayScore,
    this.venue,
    this.referee,
    required this.status,
  });

  factory H2HMatch.fromJson(Map<String, dynamic> json) {
    final fixture = json['fixture'] as Map<String, dynamic>;
    final teams = json['teams'] as Map<String, dynamic>;
    final goals = json['goals'] as Map<String, dynamic>;
    final homeTeam = teams['home'] as Map<String, dynamic>;
    final awayTeam = teams['away'] as Map<String, dynamic>;

    return H2HMatch(
      fixtureId: fixture['id'] as int,
      date: DateTime.parse(fixture['date'] as String),
      homeTeamId: homeTeam['id'] as int,
      homeTeamName: homeTeam['name'] as String,
      homeTeamLogo: homeTeam['logo'] as String?,
      awayTeamId: awayTeam['id'] as int,
      awayTeamName: awayTeam['name'] as String,
      awayTeamLogo: awayTeam['logo'] as String?,
      homeScore: goals['home'] as int? ?? 0,
      awayScore: goals['away'] as int? ?? 0,
      venue: fixture['venue']?['name'] as String?,
      referee: fixture['referee'] as String?,
      status: fixture['status']?['short'] as String? ?? 'NS',
    );
  }
}
