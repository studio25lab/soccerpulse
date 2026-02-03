import 'package:flutter/material.dart';
import '../models/player_comparison.dart';
import '../services/haptic_service.dart';

class PlayerSelectorScreen extends StatefulWidget {
  final List<int> excludedPlayerIds;

  const PlayerSelectorScreen({
    Key? key,
    this.excludedPlayerIds = const [],
  }) : super(key: key);

  @override
  State<PlayerSelectorScreen> createState() => _PlayerSelectorScreenState();
}

class _PlayerSelectorScreenState extends State<PlayerSelectorScreen> {
  final HapticService _haptic = HapticService();
  final TextEditingController _searchController = TextEditingController();

  List<PlayerComparisonData> _allPlayers = [];
  List<PlayerComparisonData> _filteredPlayers = [];

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadPlayers() {
    // Mock data - in produzione caricare da API
    _allPlayers = _generateMockPlayers();
    _filteredPlayers = _allPlayers
        .where((p) => !widget.excludedPlayerIds.contains(p.playerId))
        .toList();
  }

  void _filterPlayers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPlayers = _allPlayers
            .where((p) => !widget.excludedPlayerIds.contains(p.playerId))
            .toList();
      } else {
        _filteredPlayers = _allPlayers
            .where((p) =>
                !widget.excludedPlayerIds.contains(p.playerId) &&
                p.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(theme, isDark),
          _buildSearchBar(isDark),
          Expanded(
            child: _filteredPlayers.isEmpty
                ? _buildEmptyState(isDark)
                : _buildPlayersList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.8)],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Seleziona Giocatore',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? Colors.grey[850] : Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: _filterPlayers,
        decoration: InputDecoration(
          hintText: 'Cerca giocatore...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _filterPlayers('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nessun giocatore trovato',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPlayers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final player = _filteredPlayers[index];
        return _buildPlayerCard(player, isDark);
      },
    );
  }

  Widget _buildPlayerCard(PlayerComparisonData player, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _haptic.lightImpact();
          Navigator.pop(context, player);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
                child: player.photo != null
                    ? ClipOval(
                        child: Image.network(
                          player.photo!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person),
                        ),
                      )
                    : const Icon(Icons.person, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${player.teamName} • #${player.number}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      player.position,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '⭐ ${player.averageRating.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${player.goals}G ${player.assists}A',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<PlayerComparisonData> _generateMockPlayers() {
    return [
      PlayerComparisonData(
        playerId: 1,
        name: 'Ciro Immobile',
        photo: null,
        teamName: 'Lazio',
        number: 17,
        position: 'Attaccante',
        matches: 25,
        goals: 18,
        assists: 6,
        minutes: 2100,
        averageRating: 7.5,
        yellowCards: 2,
        redCards: 0,
        shots: 85,
        shotsOnTarget: 45,
        passingAccuracy: 78.5,
        dribbles: 32,
        tackles: 12,
        interceptions: 8,
        skills: {
          'Velocità': 82.0,
          'Tiro': 88.0,
          'Passaggio': 75.0,
          'Dribbling': 76.0,
          'Difesa': 45.0,
          'Fisico': 78.0,
        },
      ),
      PlayerComparisonData(
        playerId: 2,
        name: 'Luis Alberto',
        photo: null,
        teamName: 'Lazio',
        number: 10,
        position: 'Centrocampista',
        matches: 28,
        goals: 7,
        assists: 12,
        minutes: 2350,
        averageRating: 7.2,
        yellowCards: 3,
        redCards: 0,
        shots: 42,
        shotsOnTarget: 18,
        passingAccuracy: 87.3,
        dribbles: 58,
        tackles: 28,
        interceptions: 22,
        skills: {
          'Velocità': 75.0,
          'Tiro': 78.0,
          'Passaggio': 90.0,
          'Dribbling': 85.0,
          'Difesa': 55.0,
          'Fisico': 68.0,
        },
      ),
      PlayerComparisonData(
        playerId: 3,
        name: 'Sergej Milinkovic-Savic',
        photo: null,
        teamName: 'Lazio',
        number: 21,
        position: 'Centrocampista',
        matches: 30,
        goals: 11,
        assists: 9,
        minutes: 2650,
        averageRating: 7.8,
        yellowCards: 5,
        redCards: 0,
        shots: 68,
        shotsOnTarget: 32,
        passingAccuracy: 84.2,
        dribbles: 45,
        tackles: 42,
        interceptions: 35,
        skills: {
          'Velocità': 78.0,
          'Tiro': 85.0,
          'Passaggio': 84.0,
          'Dribbling': 80.0,
          'Difesa': 72.0,
          'Fisico': 88.0,
        },
      ),
      PlayerComparisonData(
        playerId: 4,
        name: 'Felipe Anderson',
        photo: null,
        teamName: 'Lazio',
        number: 7,
        position: 'Attaccante',
        matches: 26,
        goals: 9,
        assists: 8,
        minutes: 2100,
        averageRating: 7.0,
        yellowCards: 1,
        redCards: 0,
        shots: 52,
        shotsOnTarget: 24,
        passingAccuracy: 79.8,
        dribbles: 72,
        tackles: 18,
        interceptions: 15,
        skills: {
          'Velocità': 88.0,
          'Tiro': 76.0,
          'Passaggio': 78.0,
          'Dribbling': 87.0,
          'Difesa': 48.0,
          'Fisico': 72.0,
        },
      ),
    ];
  }
}
