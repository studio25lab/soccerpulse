// lib/repositories/player_repository.dart
// Interfaccia astratta per dati giocatore

abstract class PlayerRepository {
  /// Dati stagione attuale (presenze, gol, assist, media voto, ecc.)
  Future<Map<String, dynamic>> getSeasonData(int playerNumber, String playerName);
  
  /// Ultime partite giocate dal giocatore
  Future<List<Map<String, dynamic>>> getRecentMatches(
    int playerNumber, String playerName, String teamName);
  
  /// Dati carriera (club precedenti)
  Future<List<Map<String, dynamic>>> getCareerData(int playerNumber, String playerName);
  
  /// Overall FC26 / rating globale
  Future<Map<String, dynamic>> getPlayerOverall(int playerNumber, String playerName);
}
