import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesProvider with ChangeNotifier {
  List<int> _favoriteMatchIds = [];

  List<int> get favoriteMatchIds => _favoriteMatchIds;

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    _favoriteMatchIds =
        prefs.getStringList('favoriteMatchIds')?.map(int.parse).toList() ?? [];
    notifyListeners();
  }

  Future<void> toggleFavorite(int matchId) async {
    final prefs = await SharedPreferences.getInstance();
    if (_favoriteMatchIds.contains(matchId)) {
      _favoriteMatchIds.remove(matchId);
    } else {
      _favoriteMatchIds.add(matchId);
    }
    await prefs.setStringList('favoriteMatchIds',
        _favoriteMatchIds.map((e) => e.toString()).toList());
    notifyListeners();
  }

  bool isFavorite(int matchId) => _favoriteMatchIds.contains(matchId);
}
