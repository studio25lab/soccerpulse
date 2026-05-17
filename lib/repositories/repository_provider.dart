// lib/repositories/repository_provider.dart
// Factory per switchare tra Mock e API repository

import 'match_repository.dart';
import 'mock_match_repository.dart';
import 'api_match_repository.dart';
import 'player_repository.dart';
import 'mock_player_repository.dart';

enum DataSource { mock, api }

class RepositoryProvider {
  static DataSource _currentSource = DataSource.mock;
  
  static MatchRepository? _matchRepo;
  static PlayerRepository? _playerRepo;

  /// Cambia fonte dati per tutta l'app
  static void setDataSource(DataSource source) {
    _currentSource = source;
    _matchRepo = null; // Reset per ricreare
    _playerRepo = null;
  }

  static DataSource get currentSource => _currentSource;

  /// Ottieni il repository match (mock o api)
  static MatchRepository get matchRepository {
    _matchRepo ??= _currentSource == DataSource.mock
        ? MockMatchRepository()
        : ApiMatchRepository();
    return _matchRepo!;
  }

  /// Ottieni il repository player (mock o api)
  static PlayerRepository get playerRepository {
    _playerRepo ??= MockPlayerRepository();
    return _playerRepo!;
  }
}
