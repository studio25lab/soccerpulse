import 'package:flutter/material.dart';

class PlayerDetail {
  final int number;
  final String name;
  final String position;
  final String? photo;
  final String teamName;
  final Color teamColor;

  // Season stats
  final int matches;
  final int goals;
  final int assists;
  final int minutes;
  final int shots;
  final int shotsOnTarget;
  final int dribbles;
  final int tackles;
  final int interceptions;
  final int saves;
  final int duelsWon;
  final int yellowCards;
  final int redCards;
  final int fouls;

  // Performance
  final List<double> recentRatings;
  final List<String> recentForm;
  final String bestMatch;
  final double averageRating;
  final int? decisiveGoals;

  // Skills
  final Map<String, double> skills;

  // Advanced stats
  final double passingAccuracy;
  final double shotsPerGoal;
  final double minutesPerGoal;

  // Personal info
  final String birthDate;
  final int age;
  final String nationality;
  final int height;
  final int weight;
  final String preferredFoot;

  // Career
  final List<Map<String, String>> careerHistory;

  // NEW: Pass map data
  final List<PassData>? passes;
  final int? keyPasses;
  final double? expectedAssists; // xA
  final int? bigChancesCreated;
  final int? accurateCrosses;
  final int? totalCrosses;

  // NEW: Heatmap data
  final List<Offset>? heatmapPositions;

  PlayerDetail({
    required this.number,
    required this.name,
    required this.position,
    this.photo,
    required this.teamName,
    required this.teamColor,
    required this.matches,
    required this.goals,
    required this.assists,
    required this.minutes,
    required this.shots,
    required this.shotsOnTarget,
    required this.dribbles,
    required this.tackles,
    required this.interceptions,
    required this.saves,
    required this.duelsWon,
    required this.yellowCards,
    required this.redCards,
    required this.fouls,
    required this.recentRatings,
    required this.recentForm,
    required this.bestMatch,
    required this.averageRating,
    this.decisiveGoals,
    required this.skills,
    required this.passingAccuracy,
    required this.shotsPerGoal,
    required this.minutesPerGoal,
    required this.birthDate,
    required this.age,
    required this.nationality,
    required this.height,
    required this.weight,
    required this.preferredFoot,
    required this.careerHistory,
    // NEW
    this.passes,
    this.keyPasses,
    this.expectedAssists,
    this.bigChancesCreated,
    this.accurateCrosses,
    this.totalCrosses,
    this.heatmapPositions,
  });
}

// Pass data structure
class PassData {
  final Offset from;
  final Offset to;
  final bool isAccurate;
  final PassType type;

  PassData({
    required this.from,
    required this.to,
    required this.isAccurate,
    this.type = PassType.pass,
  });
}

enum PassType {
  shot,
  pass,
  dribble,
  defensive,
}
