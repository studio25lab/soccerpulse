import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';

class PlayerComparison {
  final String id;
  final String name;
  final List<int> playerIds;
  final DateTime createdAt;
  final bool isFavorite;

  PlayerComparison({
    required this.id,
    required this.name,
    required this.playerIds,
    required this.createdAt,
    this.isFavorite = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'playerIds': playerIds,
      'createdAt': createdAt.toIso8601String(),
      'isFavorite': isFavorite,
    };
  }

  factory PlayerComparison.fromJson(Map<String, dynamic> json) {
    return PlayerComparison(
      id: json['id'],
      name: json['name'],
      playerIds: List<int>.from(json['playerIds']),
      createdAt: DateTime.parse(json['createdAt']),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  PlayerComparison copyWith({
    String? id,
    String? name,
    List<int>? playerIds,
    DateTime? createdAt,
    bool? isFavorite,
  }) {
    return PlayerComparison(
      id: id ?? this.id,
      name: name ?? this.name,
      playerIds: playerIds ?? this.playerIds,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class ComparisonService {
  static const String _keyComparisons = 'player_comparisons';
  static const String _keyRecentComparisons = 'recent_player_comparisons';
  static const int _maxRecentComparisons = 10;

  // Salva un confronto
  Future<void> saveComparison(PlayerComparison comparison) async {
    final prefs = await SharedPreferences.getInstance();

    final comparisons = await getSavedComparisons();

    final index = comparisons.indexWhere((c) => c.id == comparison.id);
    if (index != -1) {
      comparisons[index] = comparison;
    } else {
      comparisons.add(comparison);
    }

    final jsonList = comparisons.map((c) => c.toJson()).toList();
    await prefs.setString(_keyComparisons, jsonEncode(jsonList));
  }

  // Carica confronti salvati
  Future<List<PlayerComparison>> getSavedComparisons() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyComparisons);

    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => PlayerComparison.fromJson(json)).toList();
  }

  // Carica confronti preferiti
  Future<List<PlayerComparison>> getFavoriteComparisons() async {
    final comparisons = await getSavedComparisons();
    return comparisons.where((c) => c.isFavorite).toList();
  }

  // Toggle preferito
  Future<void> toggleFavorite(String comparisonId) async {
    final comparisons = await getSavedComparisons();
    final index = comparisons.indexWhere((c) => c.id == comparisonId);

    if (index != -1) {
      comparisons[index] = comparisons[index].copyWith(
        isFavorite: !comparisons[index].isFavorite,
      );

      final prefs = await SharedPreferences.getInstance();
      final jsonList = comparisons.map((c) => c.toJson()).toList();
      await prefs.setString(_keyComparisons, jsonEncode(jsonList));
    }
  }

  // Elimina confronto
  Future<void> deleteComparison(String comparisonId) async {
    final prefs = await SharedPreferences.getInstance();
    final comparisons = await getSavedComparisons();

    comparisons.removeWhere((c) => c.id == comparisonId);

    final jsonList = comparisons.map((c) => c.toJson()).toList();
    await prefs.setString(_keyComparisons, jsonEncode(jsonList));
  }

  // Aggiungi a confronti recenti
  Future<void> addToRecentComparisons(PlayerComparison comparison) async {
    final prefs = await SharedPreferences.getInstance();

    final recents = await getRecentComparisons();

    recents.removeWhere((c) => c.id == comparison.id);

    recents.insert(0, comparison);

    if (recents.length > _maxRecentComparisons) {
      recents.removeRange(_maxRecentComparisons, recents.length);
    }

    final jsonList = recents.map((c) => c.toJson()).toList();
    await prefs.setString(_keyRecentComparisons, jsonEncode(jsonList));
  }

  // Carica confronti recenti
  Future<List<PlayerComparison>> getRecentComparisons() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyRecentComparisons);

    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => PlayerComparison.fromJson(json)).toList();
  }

  // Genera ID univoco per confronto
  String generateComparisonId(List<int> playerIds) {
    final sortedIds = List<int>.from(playerIds)..sort();
    return sortedIds.join('_');
  }

  // Genera nome automatico per confronto
  String generateComparisonName(List<Player> players) {
    if (players.isEmpty) return 'Confronto';
    if (players.length == 1) return players[0].name;
    if (players.length == 2)
      return '${players[0].name.split(' ').last} vs ${players[1].name.split(' ').last}';

    final names = players.map((p) => p.name.split(' ').last).take(3).join(', ');
    return names;
  }

  // Controlla se un confronto è già salvato
  Future<bool> isComparisonSaved(List<int> playerIds) async {
    final id = generateComparisonId(playerIds);
    final comparisons = await getSavedComparisons();
    return comparisons.any((c) => c.id == id);
  }
}
