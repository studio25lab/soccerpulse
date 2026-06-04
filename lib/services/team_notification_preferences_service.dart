// lib/services/team_notification_preferences_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/team_notification_settings.dart';

/// Gestisce le impostazioni di notifica per le SQUADRE seguite.
/// Gemello di MatchNotificationPreferencesService, indicizzato per teamId.
class TeamNotificationPreferencesService extends ChangeNotifier {
  static const String _prefsKey = 'team_notification_settings';

  final Map<int, TeamNotificationSettings> _settingsCache = {};
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Ritorna le impostazioni per una squadra. Se assenti, default disabled.
  TeamNotificationSettings getSettingsForTeam(int teamId) {
    if (_settingsCache.containsKey(teamId)) {
      return _settingsCache[teamId]!;
    }
    final def = TeamNotificationSettings.disabled(teamId);
    _settingsCache[teamId] = def;
    return def;
  }

  Future<void> saveSettingsForTeam(TeamNotificationSettings settings) async {
    try {
      _settingsCache[settings.teamId] = settings;
      await _persist();
      notifyListeners();
    } catch (e) {
      debugPrint('Errore salvataggio notifiche team ${settings.teamId}: $e');
    }
  }

  Future<void> removeSettingsForTeam(int teamId) async {
    try {
      _settingsCache.remove(teamId);
      await _persist();
      notifyListeners();
    } catch (e) {
      debugPrint('Errore rimozione notifiche team $teamId: $e');
    }
  }

  /// Attiva il preset di default per una squadra (usato quando si aggiunge
  /// la squadra ai preferiti, stile SofaScore: notifiche on).
  Future<void> enableDefaultForTeam(int teamId) async {
    await saveSettingsForTeam(TeamNotificationSettings.defaultEnabled(teamId));
  }

  /// Disattiva del tutto le notifiche di una squadra (lasciando il preferito).
  Future<void> disableForTeam(int teamId) async {
    await saveSettingsForTeam(TeamNotificationSettings.disabled(teamId));
  }

  /// True se la squadra ha almeno una notifica attiva.
  bool hasActiveNotifications(int teamId) {
    return getSettingsForTeam(teamId).hasActiveNotifications;
  }

  int getActiveNotificationsCount(int teamId) {
    return getSettingsForTeam(teamId).activeNotificationsCount;
  }

  List<int> getTeamsWithActiveNotifications() {
    return _settingsCache.entries
        .where((e) => e.value.hasActiveNotifications)
        .map((e) => e.key)
        .toList();
  }

  /// Verifica se notificare un evento per una squadra.
  /// [forFavoriteTeam]: true se l-evento riguarda la squadra seguita,
  /// false se riguarda gli avversari (usato solo per i goal).
  bool shouldNotifyEvent({
    required int teamId,
    required String eventType,
    bool forFavoriteTeam = true,
  }) {
    final s = getSettingsForTeam(teamId);
    if (!s.enabled) return false;
    switch (eventType.toLowerCase()) {
      case 'goal':
        return forFavoriteTeam ? s.notifyTeamGoals : s.notifyOpponentGoals;
      case 'yellow_card':
      case 'yellow':
        return s.notifyYellowCards;
      case 'red_card':
      case 'red':
        return s.notifyRedCards;
      case 'substitution':
      case 'subst':
        return s.notifySubstitutions;
      case 'shot_on_target':
      case 'shot':
        return s.notifyShotsOnTarget;
      case 'corner':
        return s.notifyCorners;
      case 'penalty':
        return s.notifyPenalties;
      case 'foul':
        return s.notifyFouls;
      case 'offside':
        return s.notifyOffsides;
      case 'match_start':
      case 'kickoff':
        return s.notifyMatchStart;
      case 'half_time':
      case 'ht':
        return s.notifyHalfTime;
      case 'second_half_start':
      case '2h_start':
        return s.notifySecondHalfStart;
      case 'match_end':
      case 'ft':
      case 'full_time':
        return s.notifyMatchEnd;
      case 'var':
        return s.notifyVarDecisions;
      default:
        return false;
    }
  }

  Future<void> loadSettings() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        final Map<String, dynamic> decoded = json.decode(raw);
        _settingsCache.clear();
        decoded.forEach((key, value) {
          final teamId = int.tryParse(key);
          if (teamId != null && value is Map) {
            _settingsCache[teamId] = TeamNotificationSettings.fromJson(
              Map<String, dynamic>.from(value),
            );
          }
        });
      }
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Errore caricamento notifiche team: $e');
      _initialized = true;
    }
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> toSave = {};
      _settingsCache.forEach((teamId, s) {
        toSave[teamId.toString()] = s.toJson();
      });
      await prefs.setString(_prefsKey, json.encode(toSave));
    } catch (e) {
      debugPrint('Errore persistenza notifiche team: $e');
    }
  }

  Future<void> resetAllSettings() async {
    try {
      _settingsCache.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      notifyListeners();
    } catch (e) {
      debugPrint('Errore reset notifiche team: $e');
    }
  }
}
