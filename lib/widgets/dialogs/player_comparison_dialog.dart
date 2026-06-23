// lib/widgets/dialogs/player_comparison_dialog.dart
//
// Bottom-sheet dialog per selezionare un giocatore con cui confrontare.
// Estratta da player_detail_screen.dart per ridurre la dimensione del file.
//
// // [FAV-extract-pcd]

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../../utils/l10n_helper.dart';
import '../../models/player_detail.dart';

class PlayerComparisonDialog extends StatefulWidget {
  final PlayerDetail currentPlayer;
  final List<PlayerDetail> suggestedPlayers;
  final bool isDark;
  final Function(PlayerDetail) onPlayerSelected;

  const PlayerComparisonDialog({
    required this.currentPlayer,
    required this.suggestedPlayers,
    required this.isDark,
    required this.onPlayerSelected,
  });

  @override
  State<PlayerComparisonDialog> createState() =>
      _PlayerComparisonDialogState();
}

class _PlayerComparisonDialogState extends State<PlayerComparisonDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<PlayerDetail> _searchResults = [];
  bool _isSearching = false;
  bool _isLoading = false;
  late List<PlayerDetail> _allPlayers;

  @override
  void initState() {
    super.initState();
    _allPlayers = _generateAllPlayers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      final results = _allPlayers.where((player) {
        final nameMatch =
            player.name.toLowerCase().contains(query.toLowerCase());
        final teamMatch =
            player.teamName.toLowerCase().contains(query.toLowerCase());
        return nameMatch || teamMatch;
      }).toList();

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.currentPlayer.teamColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.compare_arrows,
                      color: widget.currentPlayer.teamColor, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr(context, 'Confronta Giocatori'),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[600]),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.currentPlayer.teamColor.withOpacity(0.1),
                  widget.currentPlayer.teamColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.currentPlayer.teamColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: widget.currentPlayer.teamColor, width: 2),
                  ),
                  child: ClipOval(
                    child: widget.currentPlayer.photo != null
                        ? CachedNetworkImage(
                            imageUrl: widget.currentPlayer.photo!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: widget.currentPlayer.teamColor
                                  .withOpacity(0.2),
                              child: const Icon(Icons.person,
                                  color: Colors.white, size: 22),
                            ),
                          )
                        : Container(
                            color:
                                widget.currentPlayer.teamColor.withOpacity(0.2),
                            child: const Icon(Icons.person,
                                color: Colors.white, size: 22),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.currentPlayer.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.currentPlayer.teamName} • ${widget.currentPlayer.position}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.currentPlayer.teamColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Selezionato',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isSearching
                      ? widget.currentPlayer.teamColor
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: tr(context, 'Cerca giocatore per nome o squadra...'),
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  prefixIcon: Icon(
                    Icons.search,
                    color: _isSearching
                        ? widget.currentPlayer.teamColor
                        : Colors.grey[500],
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _isSearching ? _buildSearchResults() : _buildSuggestedPlayers(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: widget.currentPlayer.teamColor,
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              tr(context, 'Nessun giocatore trovato'),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prova con un altro nome o squadra',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            '${_searchResults.length} risultati trovati',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              return _buildPlayerCard(_searchResults[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestedPlayers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.local_fire_department,
                  color: Colors.orange[400], size: 20),
              SizedBox(width: 8),
              Text(
                tr(context, 'Giocatori Suggeriti'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.suggestedPlayers.length,
            itemBuilder: (context, index) {
              return _buildPlayerCard(widget.suggestedPlayers[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(PlayerDetail player) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => widget.onPlayerSelected(player),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: player.teamColor.withOpacity(0.2),
                    border: Border.all(
                      color: player.teamColor.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: player.photo != null
                        ? CachedNetworkImage(
                            imageUrl: player.photo!,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Icon(
                              Icons.person,
                              color: player.teamColor,
                              size: 24,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            color: player.teamColor,
                            size: 24,
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: player.teamColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              player.teamName,
                              style: TextStyle(
                                fontSize: 10,
                                color: player.teamColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            player.position,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${player.goals}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: player.teamColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.sports_soccer,
                            size: 12, color: Colors.grey[400]),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${player.matches} partite',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<PlayerDetail> _generateAllPlayers() {
    final random = math.Random(42);

    final playersData = [
      {
        'name': 'Paulo Dybala',
        'team': 'Roma',
        'position': 'Attaccante',
        'color': const Color(0xFFE53935)
      },
      {
        'name': 'Lautaro Martinez',
        'team': 'Inter',
        'position': 'Attaccante',
        'color': const Color(0xFF0033FF)
      },
      {
        'name': 'Victor Osimhen',
        'team': 'Napoli',
        'position': 'Attaccante',
        'color': const Color(0xFF0066CC)
      },
      {
        'name': 'Rafael Leão',
        'team': 'Milan',
        'position': 'Ala Sinistra',
        'color': const Color(0xFFE53935)
      },
      {
        'name': 'Ciro Immobile',
        'team': 'Lazio',
        'position': 'Attaccante',
        'color': const Color(0xFF87CEEB)
      },
      {
        'name': 'Dusan Vlahovic',
        'team': 'Juventus',
        'position': 'Attaccante',
        'color': const Color(0xFF000000)
      },
      {
        'name': 'Romelu Lukaku',
        'team': 'Roma',
        'position': 'Attaccante',
        'color': const Color(0xFFE53935)
      },
      {
        'name': 'Marcus Thuram',
        'team': 'Inter',
        'position': 'Attaccante',
        'color': const Color(0xFF0033FF)
      },
      {
        'name': 'Ademola Lookman',
        'team': 'Atalanta',
        'position': 'Ala Destra',
        'color': const Color(0xFF0066FF)
      },
      {
        'name': 'Mattia Zaccagni',
        'team': 'Lazio',
        'position': 'Ala Sinistra',
        'color': const Color(0xFF87CEEB)
      },
      {
        'name': 'Federico Chiesa',
        'team': 'Juventus',
        'position': 'Ala Destra',
        'color': const Color(0xFF000000)
      },
      {
        'name': 'Nicolò Zaniolo',
        'team': 'Atalanta',
        'position': 'Centrocampista',
        'color': const Color(0xFF0066FF)
      },
      {
        'name': 'Nicolò Barella',
        'team': 'Inter',
        'position': 'Centrocampista',
        'color': const Color(0xFF0033FF)
      },
      {
        'name': 'Khvicha Kvaratskhelia',
        'team': 'Napoli',
        'position': 'Ala Sinistra',
        'color': const Color(0xFF0066CC)
      },
      {
        'name': 'Lorenzo Pellegrini',
        'team': 'Roma',
        'position': 'Centrocampista',
        'color': const Color(0xFFE53935)
      },
      {
        'name': 'Theo Hernández',
        'team': 'Milan',
        'position': 'Terzino Sinistro',
        'color': const Color(0xFFE53935)
      },
      {
        'name': 'Alessandro Bastoni',
        'team': 'Inter',
        'position': 'Difensore',
        'color': const Color(0xFF0033FF)
      },
      {
        'name': 'Gleison Bremer',
        'team': 'Juventus',
        'position': 'Difensore',
        'color': const Color(0xFF000000)
      },
      {
        'name': 'Mike Maignan',
        'team': 'Milan',
        'position': 'Portiere',
        'color': const Color(0xFFE53935)
      },
      {
        'name': 'Wojciech Szczęsny',
        'team': 'Juventus',
        'position': 'Portiere',
        'color': const Color(0xFF000000)
      },
      {
        'name': 'Ivan Provedel',
        'team': 'Lazio',
        'position': 'Portiere',
        'color': const Color(0xFF87CEEB)
      },
      {
        'name': 'Gianluca Scamacca',
        'team': 'Atalanta',
        'position': 'Attaccante',
        'color': const Color(0xFF0066FF)
      },
      {
        'name': 'Riccardo Orsolini',
        'team': 'Bologna',
        'position': 'Ala Destra',
        'color': const Color(0xFF003366)
      },
      {
        'name': 'Moise Kean',
        'team': 'Fiorentina',
        'position': 'Attaccante',
        'color': const Color(0xFF6B3FA0)
      },
      {
        'name': 'Andrea Colpani',
        'team': 'Fiorentina',
        'position': 'Centrocampista',
        'color': const Color(0xFF6B3FA0)
      },
      {
        'name': 'Mateo Retegui',
        'team': 'Atalanta',
        'position': 'Attaccante',
        'color': const Color(0xFF0066FF)
      },
      {
        'name': 'Christian Pulisic',
        'team': 'Milan',
        'position': 'Ala Destra',
        'color': const Color(0xFFE53935)
      },
      {
        'name': 'Davide Frattesi',
        'team': 'Inter',
        'position': 'Centrocampista',
        'color': const Color(0xFF0033FF)
      },
    ];

    return playersData.map((data) {
      return PlayerDetail(
        number: random.nextInt(90) + 1,
        name: data['name'] as String,
        position: data['position'] as String,
        photo: null,
        teamName: data['team'] as String,
        teamColor: data['color'] as Color,
        matches: random.nextInt(30) + 10,
        goals: random.nextInt(20),
        assists: random.nextInt(15),
        minutes: random.nextInt(2000) + 500,
        shots: random.nextInt(50) + 10,
        shotsOnTarget: random.nextInt(30) + 5,
        dribbles: random.nextInt(40) + 5,
        tackles: random.nextInt(50) + 10,
        interceptions: random.nextInt(40) + 5,
        saves: data['position'] == 'Portiere' ? random.nextInt(80) + 20 : 0,
        duelsWon: random.nextInt(100) + 20,
        yellowCards: random.nextInt(8),
        redCards: random.nextInt(2),
        fouls: random.nextInt(30) + 5,
        recentRatings:
            List.generate(10, (_) => 6.0 + random.nextDouble() * 2.5),
        recentForm: List.generate(5, (_) => ['W', 'D', 'L'][random.nextInt(3)]),
        bestMatch:
            'Serie A - ${(random.nextDouble() * 2 + 7.5).toStringAsFixed(1)}',
        averageRating: 6.5 + random.nextDouble() * 1.5,
        decisiveGoals: random.nextInt(5),
        skills: {
          'Velocità': 50.0 + random.nextDouble() * 40,
          'Tiro': 50.0 + random.nextDouble() * 40,
          'Passaggio': 50.0 + random.nextDouble() * 40,
          'Dribbling': 50.0 + random.nextDouble() * 40,
          'Difesa': 30.0 + random.nextDouble() * 50,
          'Fisico': 50.0 + random.nextDouble() * 40,
        },
        passingAccuracy: 70 + random.nextDouble() * 20,
        shotsPerGoal: 3 + random.nextDouble() * 5,
        minutesPerGoal: 100 + random.nextDouble() * 200,
        birthDate:
            '${random.nextInt(28) + 1}/${random.nextInt(12) + 1}/${1990 + random.nextInt(10)}',
        age: 22 + random.nextInt(12),
        nationality: [
          'Italia',
          'Argentina',
          'Nigeria',
          'Francia',
          'Brasile',
          'Portogallo',
          'Serbia',
          'Belgio'
        ][random.nextInt(8)],
        height: 170 + random.nextInt(20),
        weight: 65 + random.nextInt(20),
        preferredFoot: random.nextBool() ? 'Destro' : 'Sinistro',
        careerHistory: [],
      );
    }).toList();
  }
}

// PLAYER COMPARISON SCREEN
