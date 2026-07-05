// lib/services/live_match_simulator.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../models/soccer_match.dart';

class LiveMatchEvent {
  final String type;
  final String teamType;
  final String playerName;
  final int minute;
  final String? assistBy;
  final String? details;
  final DateTime timestamp;

  LiveMatchEvent({
    required this.type,
    required this.teamType,
    required this.playerName,
    required this.minute,
    this.assistBy,
    this.details,
  }) : timestamp = DateTime.now();
}

class LiveMatchSimulator extends ChangeNotifier {
  static final LiveMatchSimulator _instance = LiveMatchSimulator._internal();
  factory LiveMatchSimulator() => _instance;
  LiveMatchSimulator._internal();

  final Random _random = Random();
  final Map<int, Timer> _matchTimers = {};
  final Map<int, StreamController<SoccerMatch>> _matchStreams = {};
  final Map<int, List<LiveMatchEvent>> _matchEvents = {};
  final Map<int, int> _matchMinutes = {};

  static const double goalProbability = 0.03;
  static const double yellowCardProbability = 0.02;
  static const double redCardProbability = 0.005;
  static const double penaltyProbability = 0.008;
  static const double varProbability = 0.01;

  final List<String> _playerNames = [
    'Martinez',
    'Lukaku',
    'Barella',
    'Calhanoglu',
    'Dumfries',
    'Osimhen',
    'Kvaratskhelia',
    'Leao',
    'Giroud',
    'Theo Hernandez',
    'Vlahovic',
    'Chiesa',
    'Dybala',
    'Pellegrini',
    'Abraham',
    'Immobile',
    'Luis Alberto',
    'Milinkovic-Savic',
    'Zaccagni',
  ];

  Stream<SoccerMatch>? getLiveMatchStream(int matchId) {
    return _matchStreams[matchId]?.stream;
  }

  List<LiveMatchEvent> getMatchEvents(int matchId) {
    return _matchEvents[matchId] ?? [];
  }

  int getMatchMinute(int matchId) {
    return _matchMinutes[matchId] ?? 0;
  }

  void startLiveSimulation(SoccerMatch match) {
    if (_matchTimers.containsKey(match.id)) return;

    _matchMinutes[match.id] = 1;
    _matchEvents[match.id] = [];
    _matchStreams[match.id] = StreamController<SoccerMatch>.broadcast();

    var liveMatch = match.copyWith(
      status: 'LIVE',
      elapsed: 1,
    );

    _matchTimers[match.id] =
        Timer.periodic(const Duration(seconds: 2), (timer) {
      final minute = _matchMinutes[match.id]!;

      if (minute == 45) {
        liveMatch = liveMatch.copyWith(
          elapsed: 45,
          status: 'HT',
        );
        _matchStreams[match.id]?.add(liveMatch);

        Future.delayed(const Duration(seconds: 10), () {
          if (_matchTimers.containsKey(match.id)) {
            liveMatch = liveMatch.copyWith(
              status: 'LIVE',
              elapsed: 46,
            );
            _matchMinutes[match.id] = 46;
          }
        });
        return;
      }

      if (minute >= 90) {
        timer.cancel();
        _matchTimers.remove(match.id);
        liveMatch = liveMatch.copyWith(
          elapsed: 90,
          status: 'FT',
        );
        _matchStreams[match.id]?.add(liveMatch);
        _matchStreams[match.id]?.close();
        _matchStreams.remove(match.id);
        notifyListeners();
        return;
      }

      final events = _simulateMinuteEvents(minute, liveMatch);

      for (var event in events) {
        _matchEvents[match.id]?.add(event);

        if (event.type == 'goal' || event.type == 'penalty') {
          if (event.teamType == 'home') {
            liveMatch = liveMatch.copyWith(
              homeScore: liveMatch.homeScore + 1,
            );
          } else {
            liveMatch = liveMatch.copyWith(
              awayScore: liveMatch.awayScore + 1,
            );
          }
        }
      }

      _matchMinutes[match.id] = minute + 1;
      liveMatch = liveMatch.copyWith(
        elapsed: minute,
      );

      _matchStreams[match.id]?.add(liveMatch);
      notifyListeners();
    });
  }

  List<LiveMatchEvent> _simulateMinuteEvents(int minute, SoccerMatch match) {
    final events = <LiveMatchEvent>[];

    double adjustedGoalProb = goalProbability;
    if (minute > 75) adjustedGoalProb *= 1.5;
    if (minute > 85) adjustedGoalProb *= 2;

    if (_random.nextDouble() < adjustedGoalProb) {
      final isHome = _random.nextBool();
      final scorer = _playerNames[_random.nextInt(_playerNames.length)];
      final hasAssist = _random.nextDouble() < 0.6;

      events.add(LiveMatchEvent(
        type: 'goal',
        teamType: isHome ? 'home' : 'away',
        playerName: scorer,
        minute: minute,
        assistBy: hasAssist
            ? _playerNames[_random.nextInt(_playerNames.length)]
            : null,
        details: _random.nextDouble() < 0.2 ? 'Di testa' : null,
      ));
    }

    if (_random.nextDouble() < yellowCardProbability) {
      events.add(LiveMatchEvent(
        type: 'yellowCard',
        teamType: _random.nextBool() ? 'home' : 'away',
        playerName: _playerNames[_random.nextInt(_playerNames.length)],
        minute: minute,
        details: 'Fallo tattico',
      ));
    }

    if (_random.nextDouble() < redCardProbability) {
      events.add(LiveMatchEvent(
        type: 'redCard',
        teamType: _random.nextBool() ? 'home' : 'away',
        playerName: _playerNames[_random.nextInt(_playerNames.length)],
        minute: minute,
        details: 'Fallo da ultimo uomo',
      ));
    }

    if (_random.nextDouble() < penaltyProbability) {
      final isHome = _random.nextBool();
      final scorer = _playerNames[_random.nextInt(_playerNames.length)];

      events.add(LiveMatchEvent(
        type: 'penalty',
        teamType: isHome ? 'home' : 'away',
        playerName: scorer,
        minute: minute,
        details: _random.nextDouble() < 0.85 ? 'Trasformato' : 'Sbagliato',
      ));
    }

    if (_random.nextDouble() < varProbability && events.isNotEmpty) {
      events.add(LiveMatchEvent(
        type: 'var',
        teamType: 'neutral',
        playerName: 'VAR Check',
        minute: minute,
        details: 'Controllo in corso...',
      ));
    }

    return events;
  }

  void stopLiveSimulation(int matchId) {
    _matchTimers[matchId]?.cancel();
    _matchTimers.remove(matchId);
    _matchStreams[matchId]?.close();
    _matchStreams.remove(matchId);
    _matchEvents.remove(matchId);
    _matchMinutes.remove(matchId);
    notifyListeners();
  }

  void stopAllSimulations() {
    for (var timer in _matchTimers.values) {
      timer.cancel();
    }
    for (var stream in _matchStreams.values) {
      stream.close();
    }
    _matchTimers.clear();
    _matchStreams.clear();
    _matchEvents.clear();
    _matchMinutes.clear();
    notifyListeners();
  }

  bool isMatchLive(int matchId) {
    return _matchTimers.containsKey(matchId);
  }

  @override
  void dispose() {
    stopAllSimulations();
    super.dispose();
  }

  // [TEST-LIVE] ─── modalità COPIONE per la partita di test ───────────
  final Map<int, int> _scriptedNextIdx = {};

  void startScriptedSimulation(SoccerMatch match) {
    if (_matchTimers.containsKey(match.id)) return;
    _matchMinutes[match.id] = 1;
    _matchEvents[match.id] = [];
    _scriptedNextIdx[match.id] = 0;
    _matchStreams[match.id] = StreamController<SoccerMatch>.broadcast();
    var liveMatch = match.copyWith(status: 'LIVE', elapsed: 1);
    _matchStreams[match.id]?.add(liveMatch);
    _matchTimers[match.id] =
        Timer.periodic(const Duration(milliseconds: 3300), (timer) {
      final minute = _matchMinutes[match.id]!;
      if (minute == 45) {
        liveMatch = liveMatch.copyWith(elapsed: 45, status: 'HT');
        _matchStreams[match.id]?.add(liveMatch);
        _matchMinutes[match.id] = 46;
        notifyListeners();
        return;
      }
      if (minute >= 90) {
        liveMatch = _fireScriptedEvents(match.id, minute, liveMatch);
        timer.cancel();
        _matchTimers.remove(match.id);
        liveMatch = liveMatch.copyWith(elapsed: 90, status: 'FT');
        _matchStreams[match.id]?.add(liveMatch);
        notifyListeners();
        return;
      }
      liveMatch = _fireScriptedEvents(match.id, minute, liveMatch);
      _matchMinutes[match.id] = minute + 1;
      liveMatch = liveMatch.copyWith(elapsed: minute);
      _matchStreams[match.id]?.add(liveMatch);
      notifyListeners();
    });
  }

  SoccerMatch _fireScriptedEvents(int matchId, int minute, SoccerMatch current) {
    var live = current;
    final script = _buildScript();
    var idx = _scriptedNextIdx[matchId] ?? 0;
    while (idx < script.length && script[idx].minute <= minute) {
      final event = script[idx].build();
      _matchEvents[matchId]?.add(event);
      final isGoal = event.type == 'goal' ||
          (event.type == 'penalty' &&
              (event.details ?? '').toLowerCase().contains('trasform'));
      if (isGoal) {
        if (event.teamType == 'home') {
          live = live.copyWith(homeScore: live.homeScore + 1);
        } else if (event.teamType == 'away') {
          live = live.copyWith(awayScore: live.awayScore + 1);
        }
      }
      idx++;
    }
    _scriptedNextIdx[matchId] = idx;
    return live;
  }

  List<_ScriptedEntry> _buildScript() => [
        _ScriptedEntry(4, () => LiveMatchEvent(type: 'foul', teamType: 'away', playerName: 'Rossi', minute: 4, details: 'Fallo a centrocampo')),
        _ScriptedEntry(8, () => LiveMatchEvent(type: 'corner', teamType: 'home', playerName: 'Bianchi', minute: 8)),
        _ScriptedEntry(12, () => LiveMatchEvent(type: 'goal', teamType: 'home', playerName: 'Bianchi', minute: 12, assistBy: 'Verdi')),
        _ScriptedEntry(17, () => LiveMatchEvent(type: 'yellowCard', teamType: 'away', playerName: 'Neri', minute: 17, details: 'Fallo tattico')),
        _ScriptedEntry(23, () => LiveMatchEvent(type: 'offside', teamType: 'home', playerName: 'Verdi', minute: 23)),
        _ScriptedEntry(29, () => LiveMatchEvent(type: 'goal', teamType: 'away', playerName: 'Gialli', minute: 29, details: 'Di testa')),
        _ScriptedEntry(34, () => LiveMatchEvent(type: 'foul', teamType: 'home', playerName: 'Verdi', minute: 34)),
        _ScriptedEntry(41, () => LiveMatchEvent(type: 'penalty', teamType: 'home', playerName: 'Bianchi', minute: 41, details: 'Trasformato')),
        _ScriptedEntry(49, () => LiveMatchEvent(type: 'yellowCard', teamType: 'home', playerName: 'Ferrari', minute: 49, details: 'Proteste')),
        _ScriptedEntry(55, () => LiveMatchEvent(type: 'substitution', teamType: 'away', playerName: 'Gialli', minute: 55, assistBy: 'Marroni')),
        _ScriptedEntry(61, () => LiveMatchEvent(type: 'corner', teamType: 'away', playerName: 'Marroni', minute: 61)),
        _ScriptedEntry(66, () => LiveMatchEvent(type: 'var', teamType: 'away', playerName: 'VAR', minute: 66, details: 'Gol annullato per fuorigioco')),
        _ScriptedEntry(72, () => LiveMatchEvent(type: 'redCard', teamType: 'away', playerName: 'Neri', minute: 72, details: 'Somma di ammonizioni')),
        _ScriptedEntry(78, () => LiveMatchEvent(type: 'offside', teamType: 'away', playerName: 'Marroni', minute: 78)),
        _ScriptedEntry(84, () => LiveMatchEvent(type: 'substitution', teamType: 'home', playerName: 'Verdi', minute: 84, assistBy: 'Colombo')),
        _ScriptedEntry(88, () => LiveMatchEvent(type: 'goal', teamType: 'home', playerName: 'Colombo', minute: 88, assistBy: 'Bianchi')),
        _ScriptedEntry(90, () => LiveMatchEvent(type: 'foul', teamType: 'away', playerName: 'Rossi', minute: 90)),
      ];
  // [TEST-LIVE] ─── fine modalità copione ─────────────────────────────

}

// ✅ EXTENSION CORRETTA - Usa i nomi dei campi VERI del modello
extension SoccerMatchCopyWith on SoccerMatch {
  SoccerMatch copyWith({
    int? id,
    DateTime? date,
    String? time,
    String? status,
    int? elapsed,
    String? venue,
    String? referee,
    int? homeTeamId,
    String? homeTeamName,
    String? homeTeamLogo,
    int? awayTeamId,
    String? awayTeamName,
    String? awayTeamLogo,
    int? homeScore,
    int? awayScore,
    int? homePenalty,
    int? awayPenalty,
    int? leagueId,
    String? leagueName,
    String? leagueLogo,
    String? leagueCountry,
    int? season,
    String? round,
  }) {
    return SoccerMatch(
      id: id ?? this.id,
      date: date ?? this.date,
      time: time ?? this.time,
      status: status ?? this.status,
      elapsed: elapsed ?? this.elapsed,
      venue: venue ?? this.venue,
      referee: referee ?? this.referee,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      homeTeamName: homeTeamName ?? this.homeTeamName,
      homeTeamLogo: homeTeamLogo ?? this.homeTeamLogo,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      awayTeamLogo: awayTeamLogo ?? this.awayTeamLogo,
      homeScore: homeScore ?? this.homeScore,
      awayScore: awayScore ?? this.awayScore,
      homePenalty: homePenalty ?? this.homePenalty,
      awayPenalty: awayPenalty ?? this.awayPenalty,
      leagueId: leagueId ?? this.leagueId,
      leagueName: leagueName ?? this.leagueName,
      leagueLogo: leagueLogo ?? this.leagueLogo,
      leagueCountry: leagueCountry ?? this.leagueCountry,
      season: season ?? this.season,
      round: round ?? this.round,
    );
  }
}


// [TEST-LIVE] classe di supporto per il copione — RIMUOVERE PRIMA DEL DEPLOY
class _ScriptedEntry {
  final int minute;
  final LiveMatchEvent Function() build;
  const _ScriptedEntry(this.minute, this.build);
}
