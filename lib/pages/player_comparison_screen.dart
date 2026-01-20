// lib/pages/player_comparison_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/player.dart';
import 'dart:math' as math;

class PlayerComparisonScreen extends StatefulWidget {
  final List<Player> initialPlayers;
  final List<Player> allPlayers; // Lista completa per selezione

  const PlayerComparisonScreen({
    Key? key,
    this.initialPlayers = const [],
    required this.allPlayers,
  }) : super(key: key);

  @override
  State<PlayerComparisonScreen> createState() => _PlayerComparisonScreenState();
}

class _PlayerComparisonScreenState extends State<PlayerComparisonScreen> {
  List<Player> selectedPlayers = [];
  String selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    selectedPlayers = List.from(widget.initialPlayers);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Confronta Giocatori',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (selectedPlayers.length >= 2)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareComparison(),
              tooltip: 'Condividi confronto',
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfo(),
            tooltip: 'Info',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPlayerSelector(theme, isDark),
          _buildCategoryTabs(theme, isDark),
          Expanded(
            child: selectedPlayers.length < 2
                ? _buildEmptyState(theme, isDark)
                : SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildRadarChart(theme, isDark),
                        const SizedBox(height: 24),
                        _buildComparisonTable(theme, isDark),
                        const SizedBox(height: 24),
                        _buildStatsBars(theme, isDark),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: selectedPlayers.length < 3
          ? FloatingActionButton.extended(
              onPressed: () => _showPlayerPicker(),
              icon: const Icon(Icons.person_add),
              label: Text('Aggiungi giocatore (${selectedPlayers.length}/3)'),
            )
          : null,
    );
  }

  Widget _buildPlayerSelector(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: theme.primaryColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Giocatori Selezionati (${selectedPlayers.length}/3)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                if (index < selectedPlayers.length) {
                  return _buildSelectedPlayerCard(
                      selectedPlayers[index], index, theme, isDark);
                } else {
                  return _buildEmptySlot(index, theme, isDark);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPlayerCard(
      Player player, int index, ThemeData theme, bool isDark) {
    final colors = [
      const Color(0xFF00C853),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
    ];

    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors[index], colors[index].withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors[index].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: player.photo != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: player.photo!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.person, color: Colors.white),
                        ),
                      )
                    : const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                player.name.split(' ').last.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removePlayer(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 16, color: colors[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot(int index, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => _showPlayerPicker(),
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.primaryColor.withOpacity(0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 40, color: theme.primaryColor),
            const SizedBox(height: 4),
            Text(
              'Aggiungi',
              style: TextStyle(
                fontSize: 12,
                color: theme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlayerPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerPickerModal(
        allPlayers: widget.allPlayers,
        selectedPlayers: selectedPlayers,
        onPlayerSelected: (player) {
          setState(() {
            if (selectedPlayers.length < 3 &&
                !selectedPlayers.any((p) => p.id == player.id)) {
              selectedPlayers.add(player);
            }
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildCategoryTabs(ThemeData theme, bool isDark) {
    final categories = [
      {'id': 'all', 'label': 'Tutte', 'icon': Icons.grid_view},
      {'id': 'offensive', 'label': 'Offensiva', 'icon': Icons.sports_soccer},
      {'id': 'defensive', 'label': 'Difensiva', 'icon': Icons.shield},
      {'id': 'passing', 'label': 'Passaggi', 'icon': Icons.sync_alt},
    ];

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategory == cat['id'];

          return GestureDetector(
            onTap: () => setState(() => selectedCategory = cat['id'] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          theme.primaryColor,
                          theme.primaryColor.withOpacity(0.7)
                        ],
                      )
                    : null,
                color: isSelected
                    ? null
                    : (isDark ? Colors.grey[800] : Colors.grey[200]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : theme.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat['label'] as String,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRadarChart(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.radar, color: theme.primaryColor, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Radar Comparativo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 280,
            child: CustomPaint(
              painter: RadarChartPainter(
                players: selectedPlayers,
                colors: const [
                  Color(0xFF00C853),
                  Color(0xFF2196F3),
                  Color(0xFFFF9800),
                ],
              ),
              size: const Size(280, 280),
            ),
          ),
          const SizedBox(height: 16),
          _buildRadarLegend(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildRadarLegend(ThemeData theme, bool isDark) {
    final colors = [
      const Color(0xFF00C853),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: selectedPlayers.asMap().entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[entry.key],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              entry.value.name.split(' ').last,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildComparisonTable(ThemeData theme, bool isDark) {
    final stats = _getStatsForCategory();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor,
                  theme.primaryColor.withOpacity(0.7)
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.table_chart, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Tabella Comparativa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          _buildTableHeader(theme, isDark),
          ...stats.map((stat) => _buildTableRow(stat, theme, isDark)),
        ],
      ),
    );
  }

  Widget _buildTableHeader(ThemeData theme, bool isDark) {
    final colors = [
      const Color(0xFF00C853),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
      ),
      child: Row(
        children: [
          const Expanded(
            flex: 2,
            child: Text(
              'Statistica',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          ...selectedPlayers.asMap().entries.map((entry) {
            return Expanded(
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors[entry.key].withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.value.name.split(' ')[0],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: colors[entry.key],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableRow(
      Map<String, dynamic> stat, ThemeData theme, bool isDark) {
    final values = selectedPlayers
        .map((p) => _getPlayerStatValue(p, stat['key']))
        .toList();
    final maxValue = values.isEmpty ? 0.0 : values.reduce(math.max);
    final colors = [
      const Color(0xFF00C853),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(stat['icon'], size: 18, color: theme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stat['label'],
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          ...values.asMap().entries.map((entry) {
            final isBest = entry.value == maxValue && maxValue > 0;
            return Expanded(
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isBest ? colors[entry.key].withOpacity(0.2) : null,
                    borderRadius: BorderRadius.circular(6),
                    border: isBest
                        ? Border.all(color: colors[entry.key], width: 2)
                        : null,
                  ),
                  child: Text(
                    entry.value
                        .toStringAsFixed(stat['key'] == 'rating' ? 1 : 0),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isBest ? FontWeight.bold : FontWeight.w600,
                      color: isBest ? colors[entry.key] : null,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatsBars(ThemeData theme, bool isDark) {
    final stats = _getStatsForCategory().take(5).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: theme.primaryColor, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Grafici Statistiche',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...stats.map((stat) => _buildStatBar(stat, theme, isDark)),
        ],
      ),
    );
  }

  Widget _buildStatBar(
      Map<String, dynamic> stat, ThemeData theme, bool isDark) {
    final values = selectedPlayers
        .map((p) => _getPlayerStatValue(p, stat['key']))
        .toList();
    final maxValue = values.isEmpty ? 1.0 : values.reduce(math.max).toDouble();
    final colors = [
      const Color(0xFF00C853),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          stat['label'],
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...values.asMap().entries.map((entry) {
          final percentage = maxValue > 0 ? entry.value / maxValue : 0.0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    selectedPlayers[entry.key].name.split(' ').last,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 24,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: percentage,
                        child: Container(
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors[entry.key],
                                colors[entry.key].withOpacity(0.7)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  child: Text(
                    entry.value
                        .toStringAsFixed(stat['key'] == 'rating' ? 1 : 0),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colors[entry.key],
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
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
            Icon(
              Icons.people_outline,
              size: 120,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Seleziona almeno 2 giocatori',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Confronta fino a 3 giocatori contemporaneamente per vedere chi è il migliore!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showPlayerPicker(),
              icon: const Icon(Icons.person_add),
              label: const Text('Aggiungi Giocatore'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getStatsForCategory() {
    switch (selectedCategory) {
      case 'offensive':
        return [
          {'label': 'Gol', 'key': 'goals', 'icon': Icons.sports_soccer},
          {'label': 'Assist', 'key': 'assists', 'icon': Icons.assist_walker},
          {'label': 'Tiri', 'key': 'shots', 'icon': Icons.sports},
          {'label': 'Rating', 'key': 'rating', 'icon': Icons.star},
        ];
      case 'defensive':
        return [
          {
            'label': 'Contrasti',
            'key': 'tackles',
            'icon': Icons.sports_kabaddi
          },
          {'label': 'Intercetti', 'key': 'interceptions', 'icon': Icons.block},
          {
            'label': 'Cartellini gialli',
            'key': 'yellowCards',
            'icon': Icons.square
          },
          {
            'label': 'Cartellini rossi',
            'key': 'redCards',
            'icon': Icons.square
          },
        ];
      case 'passing':
        return [
          {'label': 'Passaggi', 'key': 'passes', 'icon': Icons.sync_alt},
          {'label': 'Assist', 'key': 'assists', 'icon': Icons.assist_walker},
          {'label': 'Rating', 'key': 'rating', 'icon': Icons.star},
        ];
      default:
        return [
          {'label': 'Rating', 'key': 'rating', 'icon': Icons.star},
          {'label': 'Gol', 'key': 'goals', 'icon': Icons.sports_soccer},
          {'label': 'Assist', 'key': 'assists', 'icon': Icons.assist_walker},
          {'label': 'Passaggi', 'key': 'passes', 'icon': Icons.sync_alt},
          {
            'label': 'Contrasti',
            'key': 'tackles',
            'icon': Icons.sports_kabaddi
          },
          {'label': 'Intercetti', 'key': 'interceptions', 'icon': Icons.block},
          {'label': 'Tiri', 'key': 'shots', 'icon': Icons.sports},
          {
            'label': 'Cartellini gialli',
            'key': 'yellowCards',
            'icon': Icons.square
          },
          {
            'label': 'Cartellini rossi',
            'key': 'redCards',
            'icon': Icons.square
          },
        ];
    }
  }

  double _getPlayerStatValue(Player player, String key) {
    switch (key) {
      case 'rating':
        return player.rating?.toDouble() ?? 0.0;
      case 'goals':
        return player.goals?.toDouble() ?? 0.0;
      case 'assists':
        return player.assists?.toDouble() ?? 0.0;
      case 'passes':
        return player.passes?.toDouble() ?? 0.0;
      case 'tackles':
        return player.tackles?.toDouble() ?? 0.0;
      case 'interceptions':
        return player.interceptions?.toDouble() ?? 0.0;
      case 'shots':
        return player.shots?.toDouble() ?? 0.0;
      case 'yellowCards':
        return player.yellowCards?.toDouble() ?? 0.0;
      case 'redCards':
        return player.redCards?.toDouble() ?? 0.0;
      default:
        return 0.0;
    }
  }

  void _removePlayer(int index) {
    setState(() {
      selectedPlayers.removeAt(index);
    });
  }

  void _shareComparison() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Condivisione in arrivo!')),
    );
  }

  void _showInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confronto Giocatori'),
        content: const Text(
          'Confronta fino a 3 giocatori contemporaneamente!\n\n'
          '• Radar chart per confronto visivo\n'
          '• Tabella comparativa dettagliata\n'
          '• Grafici a barre per ogni statistica\n'
          '• Filtra per categoria (Offensiva, Difensiva, Passaggi)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// MODAL SELEZIONE GIOCATORI
class PlayerPickerModal extends StatefulWidget {
  final List<Player> allPlayers;
  final List<Player> selectedPlayers;
  final Function(Player) onPlayerSelected;

  const PlayerPickerModal({
    Key? key,
    required this.allPlayers,
    required this.selectedPlayers,
    required this.onPlayerSelected,
  }) : super(key: key);

  @override
  State<PlayerPickerModal> createState() => _PlayerPickerModalState();
}

class _PlayerPickerModalState extends State<PlayerPickerModal> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final availablePlayers = widget.allPlayers
        .where((p) => !widget.selectedPlayers.any((sp) => sp.id == p.id))
        .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                ),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.person_add, color: theme.primaryColor, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Seleziona Giocatore',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cerca giocatore...',
                    prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? Colors.grey[850] : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ],
            ),
          ),
          Expanded(
            child: availablePlayers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Nessun giocatore disponibile',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: availablePlayers.length,
                    itemBuilder: (context, index) {
                      final player = availablePlayers[index];
                      return _buildPlayerTile(player, theme, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerTile(Player player, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withOpacity(0.08),
            theme.primaryColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00C853), Color(0xFF00E676)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: player.photo != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: player.photo!,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.person, color: Colors.white, size: 25),
                  ),
                )
              : const Icon(Icons.person, color: Colors.white, size: 25),
        ),
        title: Text(
          player.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                player.position,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              player.teamName,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Icon(Icons.add_circle, color: theme.primaryColor, size: 28),
        onTap: () => widget.onPlayerSelected(player),
      ),
    );
  }
}

// RADAR CHART PAINTER
class RadarChartPainter extends CustomPainter {
  final List<Player> players;
  final List<Color> colors;

  RadarChartPainter({required this.players, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 40;
    final stats = 6;
    final angleStep = (2 * math.pi) / stats;

    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 5; i++) {
      final path = Path();
      for (int j = 0; j < stats; j++) {
        final angle = j * angleStep - math.pi / 2;
        final x = center.dx + (radius * i / 5) * math.cos(angle);
        final y = center.dy + (radius * i / 5) * math.sin(angle);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, gridPaint);
    }

    final axisPaint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    for (int i = 0; i < stats; i++) {
      final angle = i * angleStep - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), axisPaint);
    }

    for (int p = 0; p < players.length; p++) {
      final player = players[p];
      final path = Path();
      final paint = Paint()
        ..color = colors[p].withOpacity(0.3)
        ..style = PaintingStyle.fill;

      final strokePaint = Paint()
        ..color = colors[p]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      final values = [
        (player.rating ?? 0) / 10,
        (player.goals ?? 0) / 5,
        (player.assists ?? 0) / 5,
        (player.passes ?? 0) / 50,
        (player.tackles ?? 0) / 10,
        (player.shots ?? 0) / 5,
      ];

      for (int i = 0; i < stats; i++) {
        final angle = i * angleStep - math.pi / 2;
        final value = values[i].clamp(0.0, 1.0);
        final x = center.dx + radius * value * math.cos(angle);
        final y = center.dy + radius * value * math.sin(angle);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();

      canvas.drawPath(path, paint);
      canvas.drawPath(path, strokePaint);
    }

    final labels = ['Rating', 'Gol', 'Assist', 'Pass', 'Tackle', 'Tiri'];
    final textStyle = const TextStyle(
        color: Colors.black, fontSize: 11, fontWeight: FontWeight.w600);

    for (int i = 0; i < stats; i++) {
      final angle = i * angleStep - math.pi / 2;
      final x = center.dx + (radius + 25) * math.cos(angle);
      final y = center.dy + (radius + 25) * math.sin(angle);

      final textSpan = TextSpan(text: labels[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
