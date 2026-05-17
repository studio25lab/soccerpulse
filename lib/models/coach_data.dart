// lib/models/coach_data.dart
// Modello dati allenatore

class CoachData {
  final String name;
  final String nationality;
  final int age;
  final String born;
  final String formation;
  final String teamFull;
  final int seasonW, seasonD, seasonL;
  final int seasonGoalsFor, seasonGoalsAgainst;
  final String style;
  final String philosophy;
  final List<CoachCareerEntry> career;
  final CoachSeasonStats stats;

  const CoachData({
    required this.name,
    required this.nationality,
    required this.age,
    required this.born,
    required this.formation,
    required this.teamFull,
    required this.seasonW,
    required this.seasonD,
    required this.seasonL,
    required this.seasonGoalsFor,
    required this.seasonGoalsAgainst,
    required this.style,
    required this.philosophy,
    required this.career,
    required this.stats,
  });

  double get avgPoints => double.parse(
    ((seasonW * 3 + seasonD) / (seasonW + seasonD + seasonL)).toStringAsFixed(2),
  );

  /// Factory per creare da API-Football coachs endpoint
  factory CoachData.fromApiJson(Map<String, dynamic> json) {
    final career = (json['career'] as List<dynamic>? ?? [])
        .map((c) => CoachCareerEntry(
              team: c['team']?['name'] ?? '',
              period: '${c['start'] ?? ''} - ${c['end'] ?? 'Presente'}',
              trophy: '',
            ))
        .toList();

    return CoachData(
      name: json['name'] ?? '',
      nationality: json['nationality'] ?? '',
      age: json['age'] ?? 0,
      born: json['birth']?['date'] ?? '',
      formation: '', // da lineups endpoint
      teamFull: json['team']?['name'] ?? '',
      seasonW: 0, seasonD: 0, seasonL: 0,
      seasonGoalsFor: 0, seasonGoalsAgainst: 0,
      style: '', philosophy: '',
      career: career,
      stats: const CoachSeasonStats(),
    );
  }
}

class CoachCareerEntry {
  final String team;
  final String period;
  final String trophy;

  const CoachCareerEntry({
    required this.team,
    required this.period,
    this.trophy = '',
  });
}

class CoachSeasonStats {
  final int matches;
  final int winRate;
  final double avgGoals;
  final int cleanSheets;
  final double avgPoints;

  const CoachSeasonStats({
    this.matches = 0,
    this.winRate = 0,
    this.avgGoals = 0.0,
    this.cleanSheets = 0,
    this.avgPoints = 0.0,
  });
}
