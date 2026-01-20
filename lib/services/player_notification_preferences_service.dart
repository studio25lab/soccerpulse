// lib/services/player_notification_preferences_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_notification_settings.dart';

class PlayerNotificationPreferencesService extends ChangeNotifier {
  static const String _prefsKey = 'player_notification_settings';

  // Cache in memoria delle impostazioni (chiave = playerId_matchId o playerId)
  final Map<String, PlayerNotificationSettings> _settingsCache = {};

  // Flag di inizializzazione
  bool _initialized = false;

  // Getters
  bool get isInitialized => _initialized;

  // Ottieni le impostazioni per un giocatore specifico
  PlayerNotificationSettings getSettingsForPlayer(
    int playerId,
    String playerName, {
    int? matchId,
  }) {
    final key = _generateKey(playerId, matchId);

    // Se esiste in cache, restituiscila
    if (_settingsCache.containsKey(key)) {
      return _settingsCache[key]!;
    }

    // Altrimenti crea impostazioni di default (disabilitate)
    final defaultSettings = PlayerNotificationSettings.disabled(
      playerId,
      playerName,
      matchId: matchId,
    );
    return defaultSettings;
  }

  // Salva le impostazioni per un giocatore
  Future<void> saveSettingsForPlayer(
      PlayerNotificationSettings settings) async {
    try {
      final key = settings.key;
      _settingsCache[key] = settings;
      await _persistSettings();
      notifyListeners();
    } catch (e) {
      debugPrint(
          'Errore salvataggio impostazioni giocatore ${settings.playerId}: $e');
    }
  }

  // Rimuovi le impostazioni per un giocatore
  Future<void> removeSettingsForPlayer(int playerId, {int? matchId}) async {
    try {
      final key = _generateKey(playerId, matchId);
      _settingsCache.remove(key);
      await _persistSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Errore rimozione impostazioni giocatore $playerId: $e');
    }
  }

  // Applica un preset a un giocatore
  Future<void> applyPreset(
    int playerId,
    String playerName,
    String presetName, {
    int? matchId,
  }) async {
    PlayerNotificationSettings settings;

    switch (presetName.toLowerCase()) {
      case 'attacker':
        settings = PlayerNotificationSettings.attackerPreset(
          playerId,
          playerName,
          matchId: matchId,
        );
        break;
      case 'midfielder':
        settings = PlayerNotificationSettings.midfielderPreset(
          playerId,
          playerName,
          matchId: matchId,
        );
        break;
      case 'defender':
        settings = PlayerNotificationSettings.defenderPreset(
          playerId,
          playerName,
          matchId: matchId,
        );
        break;
      case 'goalkeeper':
        settings = PlayerNotificationSettings.goalkeeperPreset(
          playerId,
          playerName,
          matchId: matchId,
        );
        break;
      case 'essential':
        settings = PlayerNotificationSettings.essentialOnly(
          playerId,
          playerName,
          matchId: matchId,
        );
        break;
      case 'disabled':
        settings = PlayerNotificationSettings.disabled(
          playerId,
          playerName,
          matchId: matchId,
        );
        break;
      default:
        settings = PlayerNotificationSettings.essentialOnly(
          playerId,
          playerName,
          matchId: matchId,
        );
    }

    await saveSettingsForPlayer(settings);
  }

  // Abilita/disabilita tutte le notifiche per un giocatore
  Future<void> togglePlayerNotifications(
    int playerId,
    String playerName,
    bool enabled, {
    int? matchId,
  }) async {
    final currentSettings = getSettingsForPlayer(
      playerId,
      playerName,
      matchId: matchId,
    );
    final updatedSettings = currentSettings.copyWith(enabled: enabled);
    await saveSettingsForPlayer(updatedSettings);
  }

  // Verifica se un giocatore ha notifiche attive
  bool hasActiveNotifications(int playerId, {int? matchId}) {
    final key = _generateKey(playerId, matchId);
    final settings = _settingsCache[key];
    if (settings == null) return false;
    return settings.hasActiveNotifications;
  }

  // Ottieni il numero di notifiche attive per un giocatore
  int getActiveNotificationsCount(int playerId, {int? matchId}) {
    final key = _generateKey(playerId, matchId);
    final settings = _settingsCache[key];
    if (settings == null) return 0;
    return settings.activeNotificationsCount;
  }

  // Ottieni tutti i giocatori con notifiche attive
  List<PlayerNotificationSettings> getPlayersWithActiveNotifications() {
    return _settingsCache.values
        .where((settings) => settings.hasActiveNotifications)
        .toList();
  }

  // Ottieni tutti i giocatori seguiti per un match specifico
  List<PlayerNotificationSettings> getPlayersForMatch(int matchId) {
    return _settingsCache.values
        .where((settings) =>
            settings.matchId == matchId && settings.hasActiveNotifications)
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
          final settings = PlayerNotificationSettings.fromJson(
            value as Map<String, dynamic>,
          );
          _settingsCache[key] = settings;
        });
      }

      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Errore caricamento impostazioni notifiche giocatori: $e');
      _initialized = true;
    }
  }

  // Persiste le impostazioni su disco
  Future<void> _persistSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Converti la cache in JSON
      final Map<String, dynamic> toSave = {};
      _settingsCache.forEach((key, settings) {
        toSave[key] = settings.toJson();
      });

      final settingsJson = json.encode(toSave);
      await prefs.setString(_prefsKey, settingsJson);
    } catch (e) {
      debugPrint('Errore persistenza impostazioni giocatori: $e');
    }
  }

  // Pulisci vecchie impostazioni
  Future<void> cleanupOldSettings({int daysThreshold = 30}) async {
    try {
      // Rimuovi impostazioni per match specifici più vecchi di X giorni
      // In una implementazione reale, dovresti controllare la data del match
      await _persistSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Errore pulizia impostazioni vecchie giocatori: $e');
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
      debugPrint('Errore reset impostazioni giocatori: $e');
    }
  }

  // Esporta impostazioni
  String exportSettings() {
    final Map<String, dynamic> toExport = {};
    _settingsCache.forEach((key, settings) {
      toExport[key] = settings.toJson();
    });
    return json.encode(toExport);
  }

  // Importa impostazioni
  Future<void> importSettings(String settingsJson) async {
    try {
      final Map<String, dynamic> decoded = json.decode(settingsJson);

      _settingsCache.clear();
      decoded.forEach((key, value) {
        final settings = PlayerNotificationSettings.fromJson(
          value as Map<String, dynamic>,
        );
        _settingsCache[key] = settings;
      });

      await _persistSettings();
      notifyListeners();
    } catch (e) {
      debugPrint('Errore importazione impostazioni giocatori: $e');
    }
  }

  // Ottieni statistiche
  Map<String, dynamic> getStatistics() {
    int totalPlayers = _settingsCache.length;
    int enabledPlayers = _settingsCache.values.where((s) => s.enabled).length;
    int withGoalNotifications =
        _settingsCache.values.where((s) => s.notifyGoals).length;
    int withCardNotifications = _settingsCache.values
        .where((s) => s.notifyYellowCard || s.notifyRedCard)
        .length;

    return {
      'totalPlayers': totalPlayers,
      'enabledPlayers': enabledPlayers,
      'withGoalNotifications': withGoalNotifications,
      'withCardNotifications': withCardNotifications,
    };
  }

  // Verifica se deve notificare un evento specifico per un giocatore
  bool shouldNotifyPlayerEvent({
    required int playerId,
    required String eventType,
    int? matchId,
  }) {
    final key = _generateKey(playerId, matchId);
    final settings = _settingsCache[key];

    if (settings == null || !settings.enabled) return false;

    switch (eventType.toLowerCase()) {
      case 'goal':
        return settings.notifyGoals;

      case 'assist':
        return settings.notifyAssists;

      case 'shot_on_target':
      case 'shot_on':
        return settings.notifyShotsOnTarget;

      case 'shot_off_target':
      case 'shot_off':
        return settings.notifyShotsOffTarget;

      case 'yellow_card':
      case 'yellow':
        return settings.notifyYellowCard;

      case 'red_card':
      case 'red':
        return settings.notifyRedCard;

      case 'foul_committed':
      case 'foul':
        return settings.notifyFoulCommitted;

      case 'foul_suffered':
      case 'fouled':
        return settings.notifyFoulSuffered;

      case 'substitution_on':
      case 'subst_on':
        return settings.notifySubstitutionOn;

      case 'substitution_off':
      case 'subst_off':
        return settings.notifySubstitutionOff;

      case 'interception':
        return settings.notifyInterceptions;

      case 'tackle':
        return settings.notifyTackles;

      case 'clearance':
        return settings.notifyClearances;

      case 'save':
        return settings.notifySaves;

      case 'penalty_saved':
        return settings.notifyPenaltySaved;

      case 'key_pass':
        return settings.notifyKeyPasses;

      case 'dribble_successful':
      case 'dribble':
        return settings.notifyDribblesSuccessful;

      case 'offside':
        return settings.notifyOffsides;

      default:
        return false;
    }
  }

  // Helper per generare chiave univoca
  String _generateKey(int playerId, int? matchId) {
    if (matchId != null) {
      return '${playerId}_$matchId';
    }
    return playerId.toString();
  }
}
