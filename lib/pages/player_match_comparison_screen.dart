// PLAYER MATCH COMPARISON SCREEN - Confronto giocatori side-by-side
// lib/pages/player_match_comparison_screen.dart

import 'package:flutter/material.dart';
import '../models/soccer_match.dart';
import '../services/haptic_service.dart';

class PlayerMatchComparisonScreen extends StatefulWidget {
  final SoccerMatch match;
  final String player1Name;
  final int player1Number;
  final String player1Team;
  final Color player1Color;
  final String? player2Name;
  final int? player2Number;
  final String? player2Team;
  final Color? player2Color;

  const PlayerMatchComparisonScreen({
    Key? key,
    required this.match,
    required this.player1Name,
    required this.player1Number,
    required this.player1Team,
    required this.player1Color,
    this.player2Name,
    this.player2Number,
    this.player2Team,
    this.player2Color,
  }) : super(key: key);

  @override
  State<PlayerMatchComparisonScreen> createState() =>
      _PlayerMatchComparisonScreenState();
}

class _PlayerMatchComparisonScreenState
    extends State<PlayerMatchComparisonScreen> {
  final _haptic = HapticService();
  String? selectedPlayer2Name;
  int? selectedPlayer2Number;
  String? selectedPlayer2Team;
  Color? selectedPlayer2Color;

  @override
  void initState() {
    super.initState();
    selectedPlayer2Name = widget.player2Name;
    selectedPlayer2Number = widget.player2Number;
    selectedPlayer2Team = widget.player2Team;
    selectedPlayer2Color = widget.player2Color;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Confronto Giocatori'),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
      ),
      body: selectedPlayer2Name == null
          ? _buildPlayerSelection(isDark)
          : _buildComparison(isDark),
    );
  }

  // SELEZIONE SECONDO GIOCATORE
  Widget _buildPlayerSelection(bool isDark) {
    final players = _generateMatchPlayers();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  // Player 1
                  Expanded(
                    child: _buildPlayerCard(
                      widget.player1Name,
                      widget.player1Number,
                      widget.player1Team,
                      widget.player1Color,
                      isDark,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  // Placeholder Player 2
                  Expanded(
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[850] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[400]!,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_add,
                              size: 40,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Seleziona',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Seleziona un giocatore da confrontare',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // Lista giocatori
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              return _buildPlayerListTile(player, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerListTile(Map<String, dynamic> player, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: player['color'],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              player['number'].toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          player['name'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          player['team'],
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey[400],
        ),
        onTap: () {
          _haptic.lightImpact();
          setState(() {
            selectedPlayer2Name = player['name'];
            selectedPlayer2Number = player['number'];
            selectedPlayer2Team = player['team'];
            selectedPlayer2Color = player['color'];
          });
        },
      ),
    );
  }

  // CONFRONTO SIDE-BY-SIDE
  Widget _buildComparison(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildComparisonHeader(isDark),
          _buildComparisonStats(isDark),
        ],
      ),
    );
  }

  Widget _buildComparisonHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildPlayerCard(
              widget.player1Name,
              widget.player1Number,
              widget.player1Team,
              widget.player1Color,
              isDark,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: const Text(
                'VS',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: _buildPlayerCard(
              selectedPlayer2Name!,
              selectedPlayer2Number!,
              selectedPlayer2Team!,
              selectedPlayer2Color!,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(
    String name,
    int number,
    String team,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            team,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonStats(bool isDark) {
    final stats = [
      {'label': 'Goal', 'player1': '1', 'player2': '0'},
      {'label': 'Assist', 'player1': '0', 'player2': '1'},
      {'label': 'xG', 'player1': '0.82', 'player2': '0.45'},
      {'label': 'xA', 'player1': '0.14', 'player2': '0.67'},
      {'label': 'Tiri', 'player1': '4', 'player2': '3'},
      {'label': 'Tiri in porta', 'player1': '2', 'player2': '1'},
      {'label': 'Passaggi', 'player1': '45', 'player2': '38'},
      {'label': 'Precisione %', 'player1': '87', 'player2': '82'},
      {'label': 'Dribbling', 'player1': '3', 'player2': '5'},
      {'label': 'Duelli vinti', 'player1': '7', 'player2': '9'},
      {'label': 'Contrasti', 'player1': '2', 'player2': '3'},
      {'label': 'Intercetti', 'player1': '1', 'player2': '2'},
      {'label': 'Fuorigioco', 'player1': '1', 'player2': '0'},
      {'label': 'Falli fatti', 'player1': '2', 'player2': '1'},
      {'label': 'Falli subiti', 'player1': '3', 'player2': '2'},
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: stats.map((stat) {
          return _buildComparisonRow(
            stat['label']!,
            stat['player1']!,
            stat['player2']!,
            isDark,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildComparisonRow(
    String label,
    String value1,
    String value2,
    bool isDark,
  ) {
    final num1 = double.tryParse(value1) ?? 0;
    final num2 = double.tryParse(value2) ?? 0;
    final isBetter1 = num1 > num2;
    final isBetter2 = num2 > num1;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isBetter1
                    ? widget.player1Color.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isBetter1
                    ? Border.all(color: widget.player1Color, width: 2)
                    : null,
              ),
              child: Text(
                value1,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isBetter1 ? FontWeight.bold : FontWeight.normal,
                  color: isBetter1 ? widget.player1Color : null,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isBetter2
                    ? selectedPlayer2Color!.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: isBetter2
                    ? Border.all(color: selectedPlayer2Color!, width: 2)
                    : null,
              ),
              child: Text(
                value2,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isBetter2 ? FontWeight.bold : FontWeight.normal,
                  color: isBetter2 ? selectedPlayer2Color : null,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateMatchPlayers() {
    return [
      {
        'name': 'Immobile',
        'number': 17,
        'team': widget.match.homeTeamName,
        'color': const Color(0xFF0080C8),
      },
      {
        'name': 'Milinkovic-Savic',
        'number': 21,
        'team': widget.match.homeTeamName,
        'color': const Color(0xFF0080C8),
      },
      {
        'name': 'Luis Alberto',
        'number': 10,
        'team': widget.match.homeTeamName,
        'color': const Color(0xFF0080C8),
      },
      {
        'name': 'Leao',
        'number': 17,
        'team': widget.match.awayTeamName,
        'color': const Color(0xFFFC0D1C),
      },
      {
        'name': 'Theo Hernandez',
        'number': 19,
        'team': widget.match.awayTeamName,
        'color': const Color(0xFFFC0D1C),
      },
      {
        'name': 'Tonali',
        'number': 8,
        'team': widget.match.awayTeamName,
        'color': const Color(0xFFFC0D1C),
      },
    ];
  }
}
