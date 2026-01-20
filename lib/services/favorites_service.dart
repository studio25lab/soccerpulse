// lib/services/favorites_service.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/soccer_match.dart';
import '../models/team_standing.dart';
import '../models/player.dart';

class FavoritesService extends ChangeNotifier {
  static const String _favoritesKey = 'favorites';

  // Liste preferiti
  List<int> _favoriteTeamIds = [];
  List<int> _favoriteMatchIds = [];
  List<int> _favoritePlayerIds = [];

  // Dati completi (popolati quando necessario)
  List<TeamStanding> _favoriteTeams = [];
  List<SoccerMatch> _favoriteMatches = [];
  List<Player> _favoritePlayers = [];

  // Getters
  List<int> get favoriteTeamIds => _favoriteTeamIds;
  List<int> get favoriteMatchIds => _favoriteMatchIds;
  List<int> get favoritePlayerIds => _favoritePlayerIds;

  List<TeamStanding> get favoriteTeams => _favoriteTeams;
  List<SoccerMatch> get favoriteMatches => _favoriteMatches;
  List<Player> get favoritePlayers => _favoritePlayers;

  int get totalFavorites =>
      _favoriteTeamIds.length +
      _favoriteMatchIds.length +
      _favoritePlayerIds.length;

  // Carica preferiti salvati
  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString(_favoritesKey);

      if (favoritesJson != null) {
        final Map<String, dynamic> favorites = json.decode(favoritesJson);

        _favoriteTeamIds = List<int>.from(favorites['teams'] ?? []);
        _favoriteMatchIds = List<int>.from(favorites['matches'] ?? []);
        _favoritePlayerIds = List<int>.from(favorites['players'] ?? []);

        notifyListeners();
      }
    } catch (e) {
      print('Errore caricamento preferiti: $e');
    }
  }

  // Salva preferiti
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = {
        'teams': _favoriteTeamIds,
        'matches': _favoriteMatchIds,
        'players': _favoritePlayerIds,
      };
      await prefs.setString(_favoritesKey, json.encode(favorites));
    } catch (e) {
      print('Errore salvataggio preferiti: $e');
    }
  }

  // Toggle preferito squadra - METODO CORRETTO
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

  // Toggle preferito partita - METODO CORRETTO
  void toggleMatchFavorite(int matchId) {
    if (_favoriteMatchIds.contains(matchId)) {
      _favoriteMatchIds.remove(matchId);
      _favoriteMatches.removeWhere((match) => match.id == matchId);
    } else {
      _favoriteMatchIds.add(matchId);
    }
    _saveFavorites();
    notifyListeners();
  }

  // Toggle preferito giocatore - METODO CORRETTO
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

  // Alias per compatibilità con nomi diversi
  void toggleFavoriteTeam(int teamId) => toggleTeamFavorite(teamId);
  void toggleFavoriteMatch(int matchId) => toggleMatchFavorite(matchId);
  void toggleFavoritePlayer(int playerId) => togglePlayerFavorite(playerId);

  // Verifica se è preferito
  bool isTeamFavorite(int teamId) => _favoriteTeamIds.contains(teamId);
  bool isMatchFavorite(int matchId) => _favoriteMatchIds.contains(matchId);
  bool isPlayerFavorite(int playerId) => _favoritePlayerIds.contains(playerId);

  // Aggiungi dati completi squadra
  void addFavoriteTeamData(TeamStanding team) {
    if (!_favoriteTeams.any((t) => t.teamId == team.teamId)) {
      _favoriteTeams.add(team);
      notifyListeners();
    }
  }

  // Aggiungi dati completi partita
  void addFavoriteMatchData(SoccerMatch match) {
    if (!_favoriteMatches.any((m) => m.id == match.id)) {
      _favoriteMatches.add(match);
      notifyListeners();
    }
  }

  // Aggiungi dati completi giocatore
  void addFavoritePlayerData(Player player) {
    if (!_favoritePlayers.any((p) => p.id == player.id)) {
      _favoritePlayers.add(player);
      notifyListeners();
    }
  }

  // Pulisci tutti i preferiti
  void clearAllFavorites() {
    _favoriteTeamIds.clear();
    _favoriteMatchIds.clear();
    _favoritePlayerIds.clear();
    _favoriteTeams.clear();
    _favoriteMatches.clear();
    _favoritePlayers.clear();
    _saveFavorites();
    notifyListeners();
  }

  // Pulisci preferiti per tipo
  void clearFavoriteTeams() {
    _favoriteTeamIds.clear();
    _favoriteTeams.clear();
    _saveFavorites();
    notifyListeners();
  }

  void clearFavoriteMatches() {
    _favoriteMatchIds.clear();
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
