// lib/models/match_data.dart

import 'package:flutter/material.dart';
import 'soccer_match.dart';
import 'match_event.dart' as me;
import 'match_statistics.dart';

/// ⭐ MODELLO CENTRALE - Contiene TUTTI i dati della partita
/// Tutte le schermate leggono da qui per avere dati coerenti
class MatchData {
  // Informazioni base partita
  final SoccerMatch match;

  // Eventi partita (timeline)
  final List<me.MatchEvent> events;

  // Statistiche aggregate
  final MatchStatistics? statistics;

  // Formazioni
  final List<LineupPlayer> homeLineup;
  final List<LineupPlayer> awayLineup;
  final List<LineupPlayer> homeBench;
  final List<LineupPlayer> awayBench;

  // Statistiche giocatori (per questa partita)
  final Map<String, PlayerMatchStats> playerStats;

  // Coach
  final String? homeCoach;
  final String? awayCoach;

  MatchData({
    required this.match,
    required this.events,
    this.statistics,
    required this.homeLineup,
    required this.awayLineup,
    required this.homeBench,
    required this.awayBench,
    required this.playerStats,
    this.homeCoach,
    this.awayCoach,
  });

  /// Ottieni eventi di un giocatore specifico
  List<me.MatchEvent> getPlayerEvents(String playerName) {
    return events
        .where((e) => e.playerName.toLowerCase() == playerName.toLowerCase())
        .toList();
  }

  /// Ottieni statistiche di un giocatore specifico
  PlayerMatchStats? getPlayerStats(String playerName) {
    return playerStats[playerName.toLowerCase()];
  }

  /// Ottieni tutti i goal della partita
  List<me.MatchEvent> getGoals() {
    return events.where((e) => e.isGoal).toList();
  }

  /// Ottieni tutti i cartellini
  List<me.MatchEvent> getCards() {
    return events.where((e) => e.isCard).toList();
  }

  /// Ottieni tutte le sostituzioni
  List<me.MatchEvent> getSubstitutions() {
    return events.where((e) => e.isSubstitution).toList();
  }

  /// Ottieni lineup completa (titolari + panchina)
  List<LineupPlayer> getFullLineup({required bool isHome}) {
    return [
      ...(isHome ? homeLineup : awayLineup),
      ...(isHome ? homeBench : awayBench)
    ];
  }
}

/// Statistiche giocatore PER QUESTA PARTITA specifica
class PlayerMatchStats {
  final String playerName;
  final int playerNumber;
  final String position;
  final String teamName;
  final bool isHome;

  // Statistiche base
  final int minutesPlayed;
  final double rating;
  final bool isSubstituted;
  final int? substitutionMinute;

  // Goal e assist
  final int goals;
  final int assists;

  // Tiri
  final List<ShotData> shots;
  final int shotsOnTarget;
  final int shotsBlocked;
  final int shotsOffTarget;

  // Passaggi
  final List<PassData> passes;
  final int totalPasses;
  final int accuratePasses;
  final int keyPasses;

  // Dribbling
  final List<DribbleData> dribbles;
  final int successfulDribbles;
  final int failedDribbles;

  // Difesa
  final int tackles;
  final int interceptions;
  final int clearances;
  final int blockedShots;

  // Duelli
  final int duelsWon;
  final int duelsLost;
  final int aerialDuelsWon;
  final int aerialDuelsLost;

  // Falli e cartellini
  final int foulsCommitted;
  final int foulsSuffered;
  final int yellowCards;
  final int redCards;

  // Altro
  final int offsides;
  final int saves; // Solo per portieri

  // Heatmap (posizioni toccate)
  final List<Offset> heatmapPositions;

  PlayerMatchStats({
    required this.playerName,
    required this.playerNumber,
    required this.position,
    required this.teamName,
    required this.isHome,
    required this.minutesPlayed,
    this.rating = 6.0,
    this.isSubstituted = false,
    this.substitutionMinute,
    this.goals = 0,
    this.assists = 0,
    this.shots = const [],
    this.shotsOnTarget = 0,
    this.shotsBlocked = 0,
    this.shotsOffTarget = 0,
    this.passes = const [],
    this.totalPasses = 0,
    this.accuratePasses = 0,
    this.keyPasses = 0,
    this.dribbles = const [],
    this.successfulDribbles = 0,
    this.failedDribbles = 0,
    this.tackles = 0,
    this.interceptions = 0,
    this.clearances = 0,
    this.blockedShots = 0,
    this.duelsWon = 0,
    this.duelsLost = 0,
    this.aerialDuelsWon = 0,
    this.aerialDuelsLost = 0,
    this.foulsCommitted = 0,
    this.foulsSuffered = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.offsides = 0,
    this.saves = 0,
    this.heatmapPositions = const [],
  });

  /// Calcola percentuale passaggi accurati
  double get passingAccuracy {
    if (totalPasses == 0) return 0.0;
    return (accuratePasses / totalPasses * 100);
  }

  /// Calcola percentuale dribbling riusciti
  double get dribblingSuccess {
    final total = successfulDribbles + failedDribbles;
    if (total == 0) return 0.0;
    return (successfulDribbles / total * 100);
  }

  /// Calcola percentuale duelli vinti
  double get duelsWinPercentage {
    final total = duelsWon + duelsLost;
    if (total == 0) return 0.0;
    return (duelsWon / total * 100);
  }

  // ✅ AGGIUNTO: Alias per compatibilità con codice esistente
  /// Alias per foulsSuffered (falli subiti = fouls drawn)
  int get foulsDrawn => foulsSuffered;
}

/// Dati singolo tiro
class ShotData {
  final String playerName;
  final int minute;
  final Offset position; // Posizione normalizzata 0-1
  final Offset? goalPosition; // Dove è finito il tiro (se in porta)
  final bool isGoal;
  final bool onTarget; // In porta (parato o goal)
  final bool isBlocked;
  final String? bodyPart; // 'right_foot', 'left_foot', 'head'
  final double? xG; // Expected Goals
  final double? xGOT; // Expected Goals On Target

  ShotData({
    required this.playerName,
    required this.minute,
    required this.position,
    this.goalPosition,
    this.isGoal = false,
    this.onTarget = false,
    this.isBlocked = false,
    this.bodyPart,
    this.xG,
    this.xGOT,
  });
}

/// Dati singolo passaggio
class PassData {
  final String playerName;
  final int minute;
  final Offset from; // Posizione normalizzata 0-1
  final Offset to; // Posizione normalizzata 0-1
  final bool isAccurate;
  final bool isKeyPass; // Assist tentato
  final String? type; // 'short', 'long', 'through', 'cross'
  final String? bodyPart;

  PassData({
    required this.playerName,
    required this.minute,
    required this.from,
    required this.to,
    this.isAccurate = true,
    this.isKeyPass = false,
    this.type,
    this.bodyPart,
  });
}

/// Dati singolo dribbling
/// ✅ CORRETTO: Aggiunto from/to invece di solo position
class DribbleData {
  final String playerName;
  final int minute;
  final Offset from; // Posizione di partenza normalizzata 0-1
  final Offset to; // Posizione di arrivo normalizzata 0-1
  final bool successful;

  DribbleData({
    required this.playerName,
    required this.minute,
    required this.from,
    required this.to,
    this.successful = true,
  });

  /// Alias per compatibilità con codice che usa position
  /// Restituisce il punto centrale tra from e to
  Offset get position => Offset(
        (from.dx + to.dx) / 2,
        (from.dy + to.dy) / 2,
      );
}

/// Giocatore in formazione
class LineupPlayer {
  final int number;
  final String name;
  final String position;
  final bool isPlaying; // true se titolare, false se panchina
  final double rating;
  final int? gridX; // Posizione in griglia formazione (es. 4-3-3)
  final int? gridY;

  // Statistiche rapide
  final int goals;
  final int assists;
  final int shots;
  final int shotsOnTarget;
  final int passes;
  final int passesCompleted;
  final int tackles;
  final int interceptions;
  final int fouls;
  final int yellowCards;
  final int redCards;

  // Sostituzione
  final bool isSubstituted;
  final int? substitutionMinute;
  final String? substitutePlayerName;

  LineupPlayer({
    required this.number,
    required this.name,
    required this.position,
    this.isPlaying = true,
    this.rating = 6.0,
    this.gridX,
    this.gridY,
    this.goals = 0,
    this.assists = 0,
    this.shots = 0,
    this.shotsOnTarget = 0,
    this.passes = 0,
    this.passesCompleted = 0,
    this.tackles = 0,
    this.interceptions = 0,
    this.fouls = 0,
    this.yellowCards = 0,
    this.redCards = 0,
    this.isSubstituted = false,
    this.substitutionMinute,
    this.substitutePlayerName,
  });

  /// Alias per compatibilità con codice che usa passesAccurate
  int get passesAccurate => passesCompleted;
}
