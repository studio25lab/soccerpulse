// lib/services/match_notification_preferences_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/match_notification_settings.dart';

class MatchNotificationPreferencesService extends ChangeNotifier {
  static const String _prefsKey = 'match_notification_settings';

  // Cache in memoria delle impostazioni
  final Map<int, MatchNotificationSettings> _settingsCache = {};

  // Flag di inizializzazione
  bool _initialized = false;

  // Getters
  bool get isInitialized => _initialized;

  // Ottieni le impostazioni per un match specifico
  MatchNotificationSettings getSettingsForMatch(int matchId) {
    // Se esiste in cache, restituiscila
    if (_settingsCache.containsKey(matchId)) {
      return _settingsCache[matchId]!;
    }

    // Altrimenti crea impostazioni di default
    final defaultSettings = MatchNotificationSettings.disabled(matchId);
    _settingsCache[matchId] = defaultSettings;
    return defaultSettings;
  }

  // Salva le impostazioni per un match
  Future<void> saveSettingsForMatch(MatchNotificationSettings settings) async {
    try {
      // Aggiorna cache
      _settingsCache[settings.matchId] = settings;

      // Salva su disco
      await _persistSettings();

      notifyListeners();
    } catch (e) {
      debugPrint(
          'Errore salvataggio impostazioni match ${settings.matchId}: $e');
    }
  }

  // Rimuovi le impostazioni per un match
  Future<void> removeSettingsForMatch(int matchId) async {
    try {
      _settingsCache.remove(matchId);
      await _persistSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Errore rimozione impostazioni match $matchId: $e');
    }
  }

  // Applica un preset a un match
  Future<void> applyPreset(int matchId, String presetName) async {
    MatchNotificationSettings settings;

    switch (presetName.toLowerCase()) {
      case 'minimal':
        settings = MatchNotificationSettings.minimal(matchId);
        break;
      case 'complete':
        settings = MatchNotificationSettings.complete(matchId);
        break;
      case 'goals':
        settings = MatchNotificationSettings.goalsOnly(matchId);
        break;
      case 'disabled':
        settings = MatchNotificationSettings.disabled(matchId);
        break;
      default:
        settings = MatchNotificationSettings.minimal(matchId);
    }

    await saveSettingsForMatch(settings);
  }

  // Abilita/disabilita tutte le notifiche per un match
  Future<void> toggleMatchNotifications(int matchId, bool enabled) async {
    final currentSettings = getSettingsForMatch(matchId);
    final updatedSettings = currentSettings.copyWith(enabled: enabled);
    await saveSettingsForMatch(updatedSettings);
  }

  // Verifica se un match ha notifiche attive
  bool hasActiveNotifications(int matchId) {
    final settings = getSettingsForMatch(matchId);
    return settings.hasActiveNotifications;
  }

  // Ottieni il numero di notifiche attive per un match
  int getActiveNotificationsCount(int matchId) {
    final settings = getSettingsForMatch(matchId);
    return settings.activeNotificationsCount;
  }

  // Ottieni tutti i match con notifiche attive
  List<int> getMatchesWithActiveNotifications() {
    return _settingsCache.entries
        .where((entry) => entry.value.hasActiveNotifications)
        .map((entry) => entry.key)
        .toList();
  }

  // Carica le impostazioni salvate
  Future<void> loadSettings() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_prefsKey);

      if (settingsJson != null) {
        final Map<String, dynamic> decoded = json.decode(settingsJson);

        // Ricostruisci la cache
        _settingsCache.clear();
        decoded.forEach((key, value) {
          final matchId = int.parse(key);
          final settings = MatchNotificationSettings.fromJson(
            value as Map<String, dynamic>,
          );
          _settingsCache[matchId] = settings;
        });
      }

      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Errore caricamento impostazioni notifiche: $e');
      _initialized = true;
    }
  }

  // Persiste le impostazioni su disco
  Future<void> _persistSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Converti la cache in JSON
      final Map<String, dynamic> toSave = {};
      _settingsCache.forEach((matchId, settings) {
        toSave[matchId.toString()] = settings.toJson();
      });

      final settingsJson = json.encode(toSave);
      await prefs.setString(_prefsKey, settingsJson);
    } catch (e) {
      debugPrint('Errore persistenza impostazioni: $e');
    }
  }

  // Pulisci vecchie impostazioni (match terminati da più di X giorni)
  Future<void> cleanupOldSettings({int daysThreshold = 7}) async {
    try {
      // In una implementazione reale, dovresti controllare la data del match
      // e rimuovere le impostazioni per match terminati da più di X giorni

      // Per ora, questa è una implementazione placeholder
      // che richiede l'integrazione con il match date

      await _persistSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Errore pulizia impostazioni vecchie: $e');
    }
  }

  // Reset completo
  Future<void> resetAllSettings() async {
    try {
      _settingsCache.clear();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      notifyListeners();
    } catch (e) {
      debugPrint('Errore reset impostazioni: $e');
    }
  }

  // Esporta impostazioni (per backup)
  String exportSettings() {
    final Map<String, dynamic> toExport = {};
    _settingsCache.forEach((matchId, settings) {
      toExport[matchId.toString()] = settings.toJson();
    });
    return json.encode(toExport);
  }

  // Importa impostazioni (da backup)
  Future<void> importSettings(String settingsJson) async {
    try {
      final Map<String, dynamic> decoded = json.decode(settingsJson);

      _settingsCache.clear();
      decoded.forEach((key, value) {
        final matchId = int.parse(key);
        final settings = MatchNotificationSettings.fromJson(
          value as Map<String, dynamic>,
        );
        _settingsCache[matchId] = settings;
      });

      await _persistSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Errore importazione impostazioni: $e');
    }
  }

  // Ottieni statistiche
  Map<String, dynamic> getStatistics() {
    int totalMatches = _settingsCache.length;
    int enabledMatches = _settingsCache.values.where((s) => s.enabled).length;
    int withGoalNotifications = _settingsCache.values
        .where((s) => s.notifyHomeGoals || s.notifyAwayGoals)
        .length;
    int withCardNotifications = _settingsCache.values
        .where((s) => s.notifyYellowCards || s.notifyRedCards)
        .length;

    return {
      'totalMatches': totalMatches,
      'enabledMatches': enabledMatches,
      'withGoalNotifications': withGoalNotifications,
      'withCardNotifications': withCardNotifications,
    };
  }

  // Verifica se deve notificare un evento specifico
  bool shouldNotifyEvent({
    required int matchId,
    required String eventType,
    String? team, // 'home' o 'away'
  }) {
    final settings = getSettingsForMatch(matchId);

    if (!settings.enabled) return false;

    switch (eventType.toLowerCase()) {
      case 'goal':
        if (team == 'home') return settings.notifyHomeGoals;
        if (team == 'away') return settings.notifyAwayGoals;
        return settings.notifyHomeGoals || settings.notifyAwayGoals;

      case 'yellow_card':
      case 'yellow':
        return settings.notifyYellowCards;

      case 'red_card':
      case 'red':
        return settings.notifyRedCards;

      case 'substitution':
      case 'subst':
        return settings.notifySubstitutions;

      case 'shot_on_target':
      case 'shot':
        return settings.notifyShotsOnTarget;

      case 'corner':
        return settings.notifyCorners;

      case 'penalty':
        return settings.notifyPenalties;

      case 'match_start':
      case 'kickoff':
        return settings.notifyMatchStart;

      case 'half_time':
      case 'ht':
        return settings.notifyHalfTime;

      case 'second_half_start':
      case '2h_start':
        return settings.notifySecondHalfStart;

      case 'match_end':
      case 'ft':
      case 'full_time':
        return settings.notifyMatchEnd;

      case 'var':
        return settings.notifyVarDecisions;
      case 'foul': // [TEST-LIVE-NOTIFFALLI]
        return settings.notifyFouls;
      case 'offside': // [TEST-LIVE-NOTIFFALLI]
        return settings.notifyOffsides;

      default:
        return false;
    }
  }

  void enableBasicNotifications(int matchId) {
    final settings = MatchNotificationSettings.minimal(matchId);
    saveSettingsForMatch(settings);
  }

  void disableAllNotifications(int matchId) {
    final settings = MatchNotificationSettings.disabled(matchId);
    saveSettingsForMatch(settings);
  }
}
