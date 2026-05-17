// lib/repositories/mock_player_repository.dart
// Implementazione mock per dati giocatore
// I dati reali sono ancora in PlayerProfileScreen._getSeasonData()
// Verranno migrati qui progressivamente

import 'player_repository.dart';

class MockPlayerRepository implements PlayerRepository {
  
  static final MockPlayerRepository _instance = MockPlayerRepository._internal();
  factory MockPlayerRepository() => _instance;
  MockPlayerRepository._internal();

  @override
  Future<Map<String, dynamic>> getSeasonData(int playerNumber, String playerName) async {
    // Placeholder — dati reali ancora in PlayerProfileScreen
    return {};
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentMatches(
      int playerNumber, String playerName, String teamName) async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getCareerData(int playerNumber, String playerName) async {
    return [];
  }

  @override
  Future<Map<String, dynamic>> getPlayerOverall(int playerNumber, String playerName) async {
    return {};
  }
}
