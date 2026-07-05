// lib/services/favorites_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/soccer_match.dart';
import '../models/team_standing.dart';
import '../models/player.dart';

class FavoritesService extends ChangeNotifier {
  static const String _favoritesKey = 'favorites';

  /// Partite finite vengono rimosse dopo questo periodo
  static const Duration matchExpiryDuration = Duration(days: 3);

  // ── ID Lists ──
  List<int> _favoriteTeamIds = [];
  List<int> _favoritePlayerIds = [];
  final Map<int, Map<String, dynamic>> _playerMeta = {};

  // ── Match favorites con metadata (id → {addedAt, status, endedAt}) ──
  Map<int, Map<String, dynamic>> _favoriteMatchMeta = {};
  final Map<int, Map<String, dynamic>> _matchDisplayData = {};

  // ── Dati completi ──
  final List<TeamStanding> _favoriteTeams = [];
  final List<SoccerMatch> _favoriteMatches = [];
  final List<Player> _favoritePlayers = [];

  // ── Getters ──
  List<int> get favoriteTeamIds => _favoriteTeamIds;
  List<int> get favoriteMatchIds => _favoriteMatchMeta.keys.toList();
  List<int> get favoritePlayerIds => _favoritePlayerIds;

  List<TeamStanding> get favoriteTeams => _favoriteTeams;
  List<SoccerMatch> get favoriteMatches => _favoriteMatches;
  List<Player> get favoritePlayers => _favoritePlayers;

  Map<int, Map<String, dynamic>> get favoriteMatchMeta => _favoriteMatchMeta;
  Map<int, Map<String, dynamic>> get matchDisplayData => _matchDisplayData;

  int get totalFavorites =>
      _favoriteTeamIds.length +
      _favoriteMatchMeta.length +
      _favoritePlayerIds.length;

  // ── Load ──
  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString(_favoritesKey);

      if (favoritesJson != null) {
        final Map<String, dynamic> favorites = json.decode(favoritesJson);

        _favoriteTeamIds = List<int>.from(favorites['teams'] ?? []);
        _favoritePlayerIds = List<int>.from(favorites['players'] ?? []);

        // Match con metadata
        final matchesRaw = favorites['matches'];
        if (matchesRaw is Map) {
          _favoriteMatchMeta = {};
          matchesRaw.forEach((key, value) {
            final id = int.tryParse(key.toString());
            if (id != null && value is Map) {
              _favoriteMatchMeta[id] = Map<String, dynamic>.from(value);
            }
          });
        } else if (matchesRaw is List) {
          // Migrazione da vecchio formato (solo lista ID)
          _favoriteMatchMeta = {};
          for (final id in matchesRaw) {
            if (id is int) {
              _favoriteMatchMeta[id] = {
                'addedAt': DateTime.now().toIso8601String(),
                'status': 'unknown',
              };
            }
          }
        }

        // Auto-cleanup partite scadute
        _cleanupExpiredMatches();

        notifyListeners();
      }
    } catch (e) {
      print('Errore caricamento preferiti: $e');
    }
  }

  // ── Save ──
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Converti match meta con chiavi stringa per JSON
      final matchMetaStr = <String, dynamic>{};
      _favoriteMatchMeta.forEach((id, meta) {
        matchMetaStr[id.toString()] = meta;
      });

      final favorites = {
        'teams': _favoriteTeamIds,
        'matches': matchMetaStr,
        'players': _favoritePlayerIds,
      };
      await prefs.setString(_favoritesKey, json.encode(favorites));
    } catch (e) {
      print('Errore salvataggio preferiti: $e');
    }
  }

  // ── Cleanup partite finite > 3 giorni ──
  void _cleanupExpiredMatches() {
    final now = DateTime.now();
    final toRemove = <int>[];

    _favoriteMatchMeta.forEach((id, meta) {
      final status = meta['status'] as String? ?? '';
      final endedAtStr = meta['endedAt'] as String?;

      if ((status == 'FT' || status == 'AET' || status == 'PEN') &&
          endedAtStr != null) {
        final endedAt = DateTime.tryParse(endedAtStr);
        if (endedAt != null && now.difference(endedAt) > matchExpiryDuration) {
          toRemove.add(id);
        }
      }
    });

    if (toRemove.isNotEmpty) {
      for (final id in toRemove) {
        _favoriteMatchMeta.remove(id);
        _favoriteMatches.removeWhere((m) => m.id == id);
      }
      _saveFavorites();
      print('🗑️ Rimosse ${toRemove.length} partite scadute dai preferiti');
    }
  }

  /// Aggiorna lo status di una partita preferita (es. da NS → FT)
  void updateMatchStatus(int matchId, String newStatus) {
    if (_favoriteMatchMeta.containsKey(matchId)) {
      _favoriteMatchMeta[matchId]!['status'] = newStatus;
      if (newStatus == 'FT' || newStatus == 'AET' || newStatus == 'PEN') {
        _favoriteMatchMeta[matchId]!['endedAt'] =
            DateTime.now().toIso8601String();
      }
      _saveFavorites();
      notifyListeners();
    }
  }

  // ── Toggle Team ──
  void toggleTeamFavorite(int teamId) {
    if (_favoriteTeamIds.contains(teamId)) {
      _favoriteTeamIds.remove(teamId);
      _favoriteTeams.removeWhere((team) => team.teamId == teamId);
    } else {
      _favoriteTeamIds.add(teamId);
    }
    _saveFavorites();
    notifyListeners();
  }

  // ── Toggle Match (con metadata) ──
  void toggleMatchFavorite(int matchId, {String status = 'NS'}) {
    if (_favoriteMatchMeta.containsKey(matchId)) {
      _favoriteMatchMeta.remove(matchId);
      _favoriteMatches.removeWhere((match) => match.id == matchId);
    } else {
      _favoriteMatchMeta[matchId] = {
        'addedAt': DateTime.now().toIso8601String(),
        'status': status,
      };
      // Se è già finita, segna endedAt
      if (status == 'FT' || status == 'AET' || status == 'PEN') {
        _favoriteMatchMeta[matchId]!['endedAt'] =
            DateTime.now().toIso8601String();
      }
    }
    _saveFavorites();
    notifyListeners();
  }

  // ── Toggle Player ──
  void togglePlayerFavorite(int playerId) {
    if (_favoritePlayerIds.contains(playerId)) {
      _favoritePlayerIds.remove(playerId);
      _favoritePlayers.removeWhere((player) => player.id == playerId);
    } else {
      _favoritePlayerIds.add(playerId);
    }
    _saveFavorites();
    notifyListeners();
  }

  // ── Alias ──
  void toggleFavoriteTeam(int teamId) => toggleTeamFavorite(teamId);
  void toggleFavoriteMatch(int matchId, {String status = 'NS'}) =>
      toggleMatchFavorite(matchId, status: status);
  void toggleFavoritePlayer(int playerId) => togglePlayerFavorite(playerId);

  // ── Is Favorite ──
  bool isTeamFavorite(int teamId) => _favoriteTeamIds.contains(teamId);
  bool isMatchFavorite(int matchId) => _favoriteMatchMeta.containsKey(matchId);
  void storePlayerMeta(int playerId, Map<String, dynamic> meta) {
    _playerMeta[playerId] = meta;
  }

  Map<String, dynamic>? getPlayerMeta(int playerId) => _playerMeta[playerId];
  void storeMatchDisplayData(int matchId, Map<String, dynamic> data) {
    _matchDisplayData[matchId] = data;
  }

  Map<String, dynamic>? getMatchDisplayData(int matchId) => _matchDisplayData[matchId];


  Map<int, Map<String, dynamic>> get allPlayerMeta => _playerMeta;

  bool isPlayerFavorite(int playerId) => _favoritePlayerIds.contains(playerId);

  // ── Add data ──
  void addFavoriteTeamData(TeamStanding team) {
    if (!_favoriteTeams.any((t) => t.teamId == team.teamId)) {
      _favoriteTeams.add(team);
      notifyListeners();
    }
  }

  void addFavoriteMatchData(SoccerMatch match) {
    if (!_favoriteMatches.any((m) => m.id == match.id)) {
      _favoriteMatches.add(match);
      notifyListeners();
    }
  }

  void addFavoritePlayerData(Player player) {
    if (!_favoritePlayers.any((p) => p.id == player.id)) {
      _favoritePlayers.add(player);
      notifyListeners();
    }
  }

  // ── Clear ──
  void clearAllFavorites() {
    _favoriteTeamIds.clear();
    _favoriteMatchMeta.clear();
    _favoritePlayerIds.clear();
    _favoriteTeams.clear();
    _favoriteMatches.clear();
    _favoritePlayers.clear();
    _saveFavorites();
    notifyListeners();
  }

  void clearFavoriteTeams() {
    _favoriteTeamIds.clear();
    _favoriteTeams.clear();
    _saveFavorites();
    notifyListeners();
  }

  void clearFavoriteMatches() {
    _favoriteMatchMeta.clear();
    _favoriteMatches.clear();
    _saveFavorites();
    notifyListeners();
  }

  void clearFavoritePlayers() {
    _favoritePlayerIds.clear();
    _favoritePlayers.clear();
    _saveFavorites();
    notifyListeners();
  }
}
