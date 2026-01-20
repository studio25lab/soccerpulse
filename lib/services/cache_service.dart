import 'dart:convert';

class CacheService {
  static final CacheService _instance = CacheService._();
  factory CacheService() => _instance;
  CacheService._();

  final Map<String, _CacheEntry> _cache = {};

  // Durata cache: 5 minuti per matches, 30 minuti per standings
  static const Duration _matchesCacheDuration = Duration(minutes: 5);
  static const Duration _standingsCacheDuration = Duration(minutes: 30);
  static const Duration _teamsCacheDuration = Duration(hours: 24);

  // Get cached data
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T;
  }

  // Set cache data
  void set(String key, dynamic data, Duration duration) {
    _cache[key] = _CacheEntry(
      data: data,
      expiry: DateTime.now().add(duration),
    );
  }

  // Clear specific key
  void remove(String key) {
    _cache.remove(key);
  }

  // Clear all cache
  void clearAll() {
    _cache.clear();
  }

  // Helper methods
  String getMatchesCacheKey(int leagueId, {String? date}) {
    return 'matches_${leagueId}_${date ?? 'all'}';
  }

  String getStandingsCacheKey(int leagueId) {
    return 'standings_$leagueId';
  }

  String getTeamsCacheKey(int leagueId) {
    return 'teams_$leagueId';
  }

  Duration getMatchesCacheDuration() => _matchesCacheDuration;
  Duration getStandingsCacheDuration() => _standingsCacheDuration;
  Duration getTeamsCacheDuration() => _teamsCacheDuration;
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiry;

  _CacheEntry({required this.data, required this.expiry});
}
