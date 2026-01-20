import 'package:shared_preferences/shared_preferences.dart';

class UserPreferencesService {
  static final UserPreferencesService _instance =
      UserPreferencesService._internal();
  static UserPreferencesService getInstance() => _instance;

  factory UserPreferencesService() => _instance;

  UserPreferencesService._internal();

  static const String _favoriteTeamsKey = 'favorite_teams';
  static const String _selectedLeagueKey = 'selected_league';
  static const String _languageKey = 'language';

  // Favorite Teams
  Future<List<int>> getFavoriteTeams() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = prefs.getStringList(_favoriteTeamsKey) ?? [];
    return favorites.map((e) => int.parse(e)).toList();
  }

  Future<void> addFavoriteTeam(int teamId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavoriteTeams();
    if (!favorites.contains(teamId)) {
      favorites.add(teamId);
      await prefs.setStringList(
        _favoriteTeamsKey,
        favorites.map((e) => e.toString()).toList(),
      );
    }
  }

  Future<void> removeFavoriteTeam(int teamId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavoriteTeams();
    favorites.remove(teamId);
    await prefs.setStringList(
      _favoriteTeamsKey,
      favorites.map((e) => e.toString()).toList(),
    );
  }

  Future<bool> isFavoriteTeam(int teamId) async {
    final favorites = await getFavoriteTeams();
    return favorites.contains(teamId);
  }

  // NUOVO METODO
  Future<void> clearFavoriteTeams() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoriteTeamsKey);
  }

  // Selected League
  Future<int> getSelectedLeague() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_selectedLeagueKey) ?? 135; // Serie A default
  }

  Future<void> setSelectedLeague(int leagueId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedLeagueKey, leagueId);
  }

  // Language
  Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'it';
  }

  Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }
}
