import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import '../models/player.dart';
import '../models/player_detail.dart';

class PlayerConverter {
  static PlayerDetail toPlayerDetail(
    Player player, {
    required String teamName,
    required Color teamColor,
    int? jerseyNumber,
  }) {
    // Genera statistiche mock basate sulla posizione del giocatore
    final positionLower = player.position.toLowerCase();
    final isAttacker = positionLower.contains('forward') ||
        positionLower.contains('attacker') ||
        positionLower.contains('att');
    final isMidfielder = positionLower.contains('midfielder') ||
        positionLower.contains('mid') ||
        positionLower.contains('cc') ||
        positionLower.contains('cen');
    final isDefender = positionLower.contains('defender') ||
        positionLower.contains('dc') ||
        positionLower.contains('ts') ||
        positionLower.contains('td') ||
        positionLower.contains('back');
    final isGoalkeeper = positionLower.contains('goalkeeper') ||
        positionLower.contains('por') ||
        positionLower.contains('keeper');

    // Usa i goal reali o genera basati sulla posizione
    int goals = player.goals ??
        (isAttacker ? 12 : (isMidfielder ? 5 : (isDefender ? 2 : 0)));
    int assists = player.assists ?? (isAttacker ? 8 : (isMidfielder ? 10 : 3));
    int shots = player.shots ?? (isAttacker ? 45 : 25);
    int shotsOnTarget = player.shotsOnTarget ?? (isAttacker ? 28 : 15);

    // Statistiche difensive
    int tackles =
        player.tackles ?? (isDefender ? 65 : (isMidfielder ? 45 : 25));
    int interceptions = player.interceptions ?? (isDefender ? 42 : 20);
    int saves = isGoalkeeper ? 78 : 0;

    // Skills radar basati sulla posizione
    Map<String, double> skills = {
      'Velocità': isAttacker ? 85.0 : 70.0,
      'Tiro': isAttacker ? 88.0 : (isMidfielder ? 75.0 : 60.0),
      'Passaggio': isMidfielder ? 90.0 : (isDefender ? 78.0 : 82.0),
      'Dribbling': isAttacker ? 87.0 : 72.0,
      'Difesa': isDefender ? 88.0 : (isGoalkeeper ? 92.0 : 68.0),
      'Fisico': isDefender ? 85.0 : 76.0,
    };

    // Calcola passing accuracy
    double passingAccuracy = 87.5;
    if (player.passes != null &&
        player.passesCompleted != null &&
        player.passes! > 0) {
      passingAccuracy = (player.passesCompleted! / player.passes!) * 100;
    }

    // Calcola minutesPerGoal
    double minutesPerGoal = 0;
    if (goals > 0 && player.appearances != null) {
      minutesPerGoal = (player.appearances! * 90) / goals;
    }

    // Calcola shots per goal
    double shotsPerGoal = 3.8;
    if (goals > 0 && shots > 0) {
      shotsPerGoal = shots / goals;
    }

    return PlayerDetail(
      number:
          jerseyNumber ?? (player.id % 100), // Usa ID come fallback per numero
      name: player.name,
      position: player.position,
      photo: player.photo,
      teamName: teamName,
      teamColor: teamColor,

      // Stats stagione (usa dati reali quando disponibili)
      matches: player.appearances ?? 25,
      goals: goals,
      assists: assists,
      minutes: player.appearances != null ? player.appearances! * 90 : 2100,
      shots: shots,
      shotsOnTarget: shotsOnTarget,
      dribbles: isAttacker ? 32 : 18,
      tackles: tackles,
      interceptions: interceptions,
      saves: saves,
      duelsWon: 58,
      yellowCards: player.yellowCards ?? 3,
      redCards: player.redCards ?? 0,
      fouls: player.foulsCommitted ?? 18,

      // Performance
      recentRatings: [7.2, 7.8, 6.9, 8.1, 7.5, 7.0, 8.3, 7.6, 7.9, 7.4],
      recentForm: ['W', 'W', 'D', 'W', 'L', 'W', 'W', 'D', 'W', 'W'],
      bestMatch: '$teamName vs Roma - 8.5',
      averageRating: player.rating > 0 ? player.rating : 7.5,
      decisiveGoals: (goals * 0.4).round(), // ~40% dei goal sono decisivi

      // Skills
      skills: skills,

      // Advanced stats
      passingAccuracy: passingAccuracy,
      shotsPerGoal: shotsPerGoal,
      minutesPerGoal: minutesPerGoal > 0 ? minutesPerGoal : 175.0,

      // Personal info (dati mock perché non disponibili nel model Player)
      birthDate: '15/03/1995',
      age: player.age ?? 28,
      nationality: player.nationality ?? 'Italia',
      height: 182, // Mock
      weight: 75, // Mock
      preferredFoot: 'Destro', // Mock

      // Career
      careerHistory: [
        {
          'years': '2021-Now',
          'team': teamName,
          'matches': player.appearances?.toString() ?? '78',
          'goals': goals.toString()
        },
        {
          'years': '2018-2021',
          'team': 'Precedente',
          'matches': '92',
          'goals': '31'
        },
        {
          'years': '2015-2018',
          'team': 'Primavera',
          'matches': '65',
          'goals': '18'
        },
      ],
    );
  }
}
