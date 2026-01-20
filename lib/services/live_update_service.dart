// lib/services/live_update_service.dart

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/soccer_match.dart';
import '../api/api_service.dart';

// Modello per gli eventi di goal
class GoalEvent {
  final int matchId;
  final String teamName;
  final DateTime timestamp;

  GoalEvent({
    required this.matchId,
    required this.teamName,
    required this.timestamp,
  });
}

// Servizio per gestire gli aggiornamenti live delle partite
class LiveUpdateService extends ChangeNotifier {
  static final LiveUpdateService _instance = LiveUpdateService._internal();
  factory LiveUpdateService() => _instance;
  LiveUpdateService._internal();

  final ApiService _apiService = ApiService();

  // Timer per aggiornamenti periodici
  Timer? _updateTimer;

  // StreamController per eventi live
  final StreamController<GoalEvent> _goalStreamController =
      StreamController<GoalEvent>.broadcast();

  // StreamController per aggiornamenti partite
  final StreamController<List<SoccerMatch>> _matchUpdateController =
      StreamController<List<SoccerMatch>>.broadcast();

  // Stato attuale
  List<SoccerMatch> _currentMatches = [];
  bool _isActive = false;
  int _updateInterval = 30; // secondi

  // ADDED: Settings properties
  bool _autoRefreshEnabled = true;
  bool _vibrationEnabled = true;
  bool _soundEnabled = false;
  int _refreshInterval = 30; // secondi

  // Getters
  Stream<GoalEvent> get goalStream => _goalStreamController.stream;
  Stream<List<SoccerMatch>> get matchUpdateStream =>
      _matchUpdateController.stream;
  List<SoccerMatch> get currentMatches => _currentMatches;
  bool get isActive => _isActive;

  // ADDED: Settings getters
  bool get autoRefreshEnabled => _autoRefreshEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get soundEnabled => _soundEnabled;
  int get refreshInterval => _refreshInterval;

  // ADDED: Settings setters
  set autoRefreshEnabled(bool value) {
    _autoRefreshEnabled = value;
    notifyListeners();
    if (!value && _isActive) {
      stopLiveUpdates();
    }
  }

  set vibrationEnabled(bool value) {
    _vibrationEnabled = value;
    notifyListeners();
  }

  set soundEnabled(bool value) {
    _soundEnabled = value;
    notifyListeners();
  }

  set refreshInterval(int value) {
    _refreshInterval = value;
    _updateInterval = value;
    notifyListeners();
    if (_isActive) {
      stopLiveUpdates();
      startLiveUpdates();
    }
  }

  // Inizializza il servizio di aggiornamento
  void initialize({int updateInterval = 30}) {
    _updateInterval = updateInterval;
    _refreshInterval = updateInterval;
  }

  // Avvia gli aggiornamenti live per una lista di partite
  void startLiveUpdates({
    List<int>? matchIds,
    int? leagueId,
    DateTime? date,
  }) {
    if (_isActive || !_autoRefreshEnabled) return;

    _isActive = true;
    notifyListeners();

    // Avvia il timer per aggiornamenti periodici
    _updateTimer = Timer.periodic(
      Duration(seconds: _updateInterval),
      (_) => _fetchUpdates(
        matchIds: matchIds,
        leagueId: leagueId,
        date: date,
      ),
    );

    // Fetch iniziale
    _fetchUpdates(
      matchIds: matchIds,
      leagueId: leagueId,
      date: date,
    );
  }

  // Ferma gli aggiornamenti live
  void stopLiveUpdates() {
    _updateTimer?.cancel();
    _updateTimer = null;
    _isActive = false;
    notifyListeners();
  }

  // Fetch degli aggiornamenti
  Future<void> _fetchUpdates({
    List<int>? matchIds,
    int? leagueId,
    DateTime? date,
  }) async {
    try {
      List<SoccerMatch> matches = [];

      if (date != null) {
        // Fetch partite per data
        matches = await _apiService.fetchMatchesByDate(
          date,
          leagueId: leagueId,
          forceRefresh: true,
        );
      } else if (leagueId != null) {
        // Fetch partite per lega
        matches = await _apiService.fetchMatchesByLeague(
          leagueId,
          forceRefresh: true,
        );
      } else if (matchIds != null && matchIds.isNotEmpty) {
        // Fetch partite specifiche
        for (int id in matchIds) {
          // Qui dovresti implementare un metodo per fetchare una singola partita
          // Per ora usiamo le partite in cache
        }
      }

      // Controlla cambiamenti e genera eventi
      _checkForGoals(matches);

      // Aggiorna lo stato
      _currentMatches = matches;
      _matchUpdateController.add(matches);
      notifyListeners();
    } catch (e) {
      print('Errore aggiornamento live: $e');
    }
  }

  // Controlla se ci sono stati goal
  void _checkForGoals(List<SoccerMatch> matches) {
    for (var currentMatch in matches) {
      // Trova la partita precedente
      final previousMatch = _currentMatches.firstWhere(
        (m) => m.id == currentMatch.id,
        orElse: () => currentMatch,
      );

      // Controlla se è cambiato il punteggio
      if (currentMatch.homeScore != previousMatch.homeScore ||
          currentMatch.awayScore != previousMatch.awayScore) {
        // Genera evento goal
        _goalStreamController.add(GoalEvent(
          matchId: currentMatch.id,
          teamName: currentMatch.homeScore > previousMatch.homeScore
              ? currentMatch.homeTeamName
              : currentMatch.awayTeamName,
          timestamp: DateTime.now(),
        ));

        // Trigger vibrazione se abilitata
        if (_vibrationEnabled) {
          // Implementa vibrazione
        }

        // Trigger suono se abilitato
        if (_soundEnabled) {
          // Implementa suono
        }
      }
    }
  }

  // Aggiungi una partita al monitoraggio
  void addMatch(SoccerMatch match) {
    if (!_currentMatches.any((m) => m.id == match.id)) {
      _currentMatches.add(match);
      notifyListeners();
    }
  }

  // Rimuovi una partita dal monitoraggio
  void removeMatch(int matchId) {
    _currentMatches.removeWhere((m) => m.id == matchId);
    notifyListeners();
  }

  // Aggiorna manualmente una partita
  void updateMatch(SoccerMatch match) {
    final index = _currentMatches.indexWhere((m) => m.id == match.id);
    if (index != -1) {
      _currentMatches[index] = match;
      _matchUpdateController.add(_currentMatches);
      notifyListeners();
    }
  }

  // Registra callback per aggiornamenti
  void subscribeToMatchUpdates(Function(List<SoccerMatch>) onUpdate) {
    matchUpdateStream.listen((matches) {
      onUpdate(matches);
    });
  }

  // Registra callback per eventi goal
  void subscribeToGoalEvents(Function(GoalEvent) onGoal) {
    goalStream.listen((event) {
      onGoal(event);
    });
  }

  // Ottieni partite live
  int get liveMatchCount {
    return _currentMatches.where((m) => m.isLive).length;
  }

  // Controlla se ci sono partite live
  bool get hasLiveMatches {
    return _currentMatches.any((m) => m.isLive);
  }

  // Aggiorna intervallo
  void updateInterval(int seconds) {
    refreshInterval = seconds;
  }

  // Pulisci risorse
  @override
  void dispose() {
    stopLiveUpdates();
    _goalStreamController.close();
    _matchUpdateController.close();
    super.dispose();
  }

  // Force refresh
  Future<void> forceRefresh() async {
    if (_isActive) {
      await _fetchUpdates();
    }
  }

  // Ottieni partite per status
  List<SoccerMatch> getMatchesByStatus(String status) {
    return _currentMatches.where((m) => m.status == status).toList();
  }

  // Ottieni partite per team
  List<SoccerMatch> getMatchesByTeam(int teamId) {
    return _currentMatches
        .where((m) => m.homeTeamId == teamId || m.awayTeamId == teamId)
        .toList();
  }
}
