// lib/pages/player_comparison_screen.dart

import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/player.dart';

class PlayerComparisonScreen extends StatefulWidget {
  final List<Player> initialPlayers;
  final List<Player> allPlayers;

  const PlayerComparisonScreen({
    Key? key,
    required this.initialPlayers,
    required this.allPlayers,
  }) : super(key: key);

  @override
  State<PlayerComparisonScreen> createState() => _PlayerComparisonScreenState();
}

class _PlayerComparisonScreenState extends State<PlayerComparisonScreen> {
  Player? _player1;
  Player? _player2;
  final TextEditingController _searchController = TextEditingController();
  int _selectingSlot = 0; // 0 = nessuno, 1 = slot sinistro, 2 = slot destro

  @override
  void initState() {
    super.initState();
    if (widget.initialPlayers.isNotEmpty) {
      _player1 = widget.initialPlayers[0];
    }
    if (widget.initialPlayers.length > 1) {
      _player2 = widget.initialPlayers[1];
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text(tr(context, 'Confronta Giocatori')),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Player selection cards
          _buildPlayerSelectors(theme, isDark),

          // Comparison content
          if (_player1 != null && _player2 != null)
            Expanded(child: _buildComparison(theme, isDark))
          else if (_selectingSlot > 0)
            Expanded(child: _buildPlayerPicker(theme, isDark))
          else
            Expanded(child: _buildEmptyState(theme, isDark)),
        ],
      ),
    );
  }

  Widget _buildPlayerSelectors(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildPlayerSlot(_player1, 1, theme, isDark)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withOpacity(0.7)
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.compare_arrows,
                  color: Colors.white, size: 24),
            ),
          ),
          Expanded(child: _buildPlayerSlot(_player2, 2, theme, isDark)),
        ],
      ),
    );
  }

  Widget _buildPlayerSlot(
      Player? player, int slot, ThemeData theme, bool isDark) {
    final isSelecting = _selectingSlot == slot;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectingSlot = isSelecting ? 0 : slot;
          _searchController.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelecting
              ? theme.primaryColor.withOpacity(0.1)
              : (isDark ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelecting ? theme.primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: player != null
            ? Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: player.photo != null
                          ? CachedNetworkImage(
                              imageUrl: player.photo!,
                              fit: BoxFit.cover,
                              errorWidget: (c, u, e) =>
                                  const Icon(Icons.person, size: 30),
                            )
                          : const Icon(Icons.person, size: 30),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    player.name.split(' ').last,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    player.teamName,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              )
            : Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[700] : Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      size: 28,
                      color: isSelecting ? theme.primaryColor : Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    tr(context, 'Seleziona'),
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isSelecting ? theme.primaryColor : Colors.grey[600],
                      fontWeight:
                          isSelecting ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPlayerPicker(ThemeData theme, bool isDark) {
    final query = _searchController.text.toLowerCase();
    final filtered = widget.allPlayers.where((p) {
      if (query.isNotEmpty) {
        return p.name.toLowerCase().contains(query) ||
            p.teamName.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: tr(context, 'Cerca giocatore...'),
              prefixIcon: Icon(Icons.search, color: theme.primaryColor),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primaryColor, width: 2),
              ),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                      SizedBox(height: 12),
                      Text(tr(context, 'Nessun giocatore trovato'),
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final player = filtered[index];
                    final isAlreadySelected =
                        player == _player1 || player == _player2;

                    return Opacity(
                      opacity: isAlreadySelected ? 0.4 : 1.0,
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: player.photo != null
                                ? NetworkImage(player.photo!)
                                : null,
                            child: player.photo == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            player.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${player.teamName} • ${player.position}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          trailing: player.rating > 0
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _ratingColor(player.rating),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    player.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: isAlreadySelected
                              ? null
                              : () {
                                  setState(() {
                                    if (_selectingSlot == 1) {
                                      _player1 = player;
                                    } else {
                                      _player2 = player;
                                    }
                                    _selectingSlot = 0;
                                    _searchController.clear();
                                  });
                                },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows, size: 80, color: Colors.grey[400]),
            SizedBox(height: 24),
            Text(
              tr(context, 'Confronta due giocatori'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Text(
              tr(context, 'Seleziona due giocatori toccando gli slot in alto per vedere le statistiche a confronto'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparison(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Rating header
        _buildRatingHeader(theme, isDark),
        const SizedBox(height: 20),

        // Stats sections
        _buildSectionTitle(
            'Offensiva', Icons.sports_soccer, const Color(0xFF00C853)),
        SizedBox(height: 8),
        _buildStatRow('Gol', _player1?.goals, _player2?.goals, theme),
        _buildStatRow('Assist', _player1?.assists, _player2?.assists, theme),
        _buildStatRow(tr(context, 'Tiri'), _player1?.shots, _player2?.shots, theme),
        _buildStatRow(tr(context, 'Tiri in porta'), _player1?.shotsOnTarget,
            _player2?.shotsOnTarget, theme),

        SizedBox(height: 20),
        _buildSectionTitle(tr(context, 'Passaggi'), Icons.sync_alt, Color(0xFF9C27B0)),
        SizedBox(height: 8),
        _buildStatRow(tr(context, 'Passaggi'), _player1?.passes, _player2?.passes, theme),
        _buildStatRow(tr(context, 'Passaggi riusciti'), _player1?.passesCompleted,
            _player2?.passesCompleted, theme),

        SizedBox(height: 20),
        _buildSectionTitle('Difensiva', Icons.shield, Color(0xFF1976D2)),
        SizedBox(height: 8),
        _buildStatRow(tr(context, 'Contrasti'), _player1?.tackles, _player2?.tackles, theme),
        _buildStatRow(tr(context, 'Intercetti'), _player1?.interceptions,
            _player2?.interceptions, theme),

        const SizedBox(height: 20),
        _buildSectionTitle(
            'Disciplina', Icons.warning, Color(0xFFFF9800)),
        SizedBox(height: 8),
        _buildStatRow(tr(context, 'Falli commessi'), _player1?.foulsCommitted,
            _player2?.foulsCommitted, theme,
            lowerIsBetter: true),
        _buildStatRow(tr(context, 'Falli subiti'), _player1?.foulsSuffered,
            _player2?.foulsSuffered, theme),
        _buildStatRow(tr(context, 'Cartellini gialli'), _player1?.yellowCards,
            _player2?.yellowCards, theme,
            lowerIsBetter: true),
        _buildStatRow(
            tr(context, 'Cartellini rossi'), _player1?.redCards, _player2?.redCards, theme,
            lowerIsBetter: true),

        const SizedBox(height: 20),
        _buildSectionTitle(
            'Generale', Icons.bar_chart, Color(0xFF00BCD4)),
        SizedBox(height: 8),
        _buildStatRow(
            tr(context, 'Presenze'), _player1?.appearances, _player2?.appearances, theme),
        _buildStatRow(tr(context, 'Titolare'), _player1?.lineups, _player2?.lineups, theme),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildRatingHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.15),
            theme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildRatingBadge(_player1?.rating ?? 0, theme),
          ),
          Column(
            children: [
              Text(
                'Rating',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Icon(Icons.star, color: Colors.amber, size: 24),
            ],
          ),
          Expanded(
            child: _buildRatingBadge(_player2?.rating ?? 0, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBadge(double rating, ThemeData theme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: _ratingColor(rating),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: _ratingColor(rating).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          rating > 0 ? rating.toStringAsFixed(1) : '-',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, int? val1, int? val2, ThemeData theme,
      {bool lowerIsBetter = false}) {
    final v1 = val1 ?? 0;
    final v2 = val2 ?? 0;

    Color color1 = Colors.grey[600]!;
    Color color2 = Colors.grey[600]!;

    if (v1 != v2) {
      final better1 = lowerIsBetter ? v1 < v2 : v1 > v2;
      color1 = better1 ? const Color(0xFF00C853) : const Color(0xFFE53935);
      color2 = better1 ? const Color(0xFFE53935) : const Color(0xFF00C853);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              v1.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              v2.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Color _ratingColor(double rating) {
    if (rating >= 8.0) return const Color(0xFF00C853);
    if (rating >= 7.0) return const Color(0xFF2196F3);
    if (rating >= 6.0) return const Color(0xFFFF9800);
    return const Color(0xFFE53935);
  }
}
