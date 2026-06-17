// lib/pages/players_screen.dart

import 'package:flutter/material.dart';
import '../utils/l10n_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/player.dart';
import 'player_profile_screen.dart';
import 'player_comparison_screen.dart';
import '../widgets/player_filter_modal.dart';

class PlayersScreen extends StatefulWidget {
  final List<Player> allPlayers;

  const PlayersScreen({
    Key? key,
    required this.allPlayers,
  }) : super(key: key);

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  List<Player> filteredPlayers = [];
  String searchQuery = '';
  String sortBy = 'rating'; // rating, goals, assists, name

  // Filtri
  double minRating = 0.0;
  int minMinutes = 0;
  String? positionFilter;
  String? nationalityFilter;
  int? minAge;
  int? maxAge;
  List<String> selectedBadges = [];

  @override
  void initState() {
    super.initState();
    filteredPlayers = List.from(widget.allPlayers);
    _sortPlayers();
  }

  void _applyFilters() {
    setState(() {
      filteredPlayers = widget.allPlayers.where((player) {
        // Search
        if (searchQuery.isNotEmpty &&
            !player.name.toLowerCase().contains(searchQuery.toLowerCase())) {
          return false;
        }

        // Rating filter
        if (player.rating < minRating) {
          return false;
        }

        // Minutes filter (mock - dovrebbe venire da API)
        final playerMinutes = player.rating * 100; // Mock calculation
        if (playerMinutes < minMinutes) {
          return false;
        }

        // Position filter
        if (positionFilter != null && player.position != positionFilter) {
          return false;
        }

        // Age filter (mock - dovrebbe venire da player.age)
        if (minAge != null || maxAge != null) {
          final playerAge = 25; // Mock age
          if (minAge != null && playerAge < minAge!) return false;
          if (maxAge != null && playerAge > maxAge!) return false;
        }

        // Badge filter
        if (selectedBadges.isNotEmpty) {
          final playerBadges = _getPlayerBadges(player);
          if (!selectedBadges.any((badge) => playerBadges.contains(badge))) {
            return false;
          }
        }

        return true;
      }).toList();

      _sortPlayers();
    });
  }

  void _sortPlayers() {
    setState(() {
      filteredPlayers.sort((a, b) {
        switch (sortBy) {
          case 'rating':
            return b.rating.compareTo(a.rating);
          case 'goals':
            return (b.goals ?? 0).compareTo(a.goals ?? 0);
          case 'assists':
            return (b.assists ?? 0).compareTo(a.assists ?? 0);
          case 'name':
            return a.name.compareTo(b.name);
          default:
            return 0;
        }
      });
    });
  }

  List<String> _getPlayerBadges(Player player) {
    final badges = <String>[];

    // Mock data - dovrebbe venire da API
    final appearances = player.rating * 15; // Mock
    if (appearances >= 100) badges.add('100_appearances');
    if ((player.goals ?? 0) >= 10) badges.add('10_goals');
    if ((player.assists ?? 0) >= 5) badges.add('5_assists');
    if (player.rating >= 8.0) badges.add('motm');
    if (player.position == 'Goalkeeper' && player.rating > 7.5)
      badges.add('clean_sheet');

    return badges;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text(tr(context, 'Giocatori'),
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterModal(),
            tooltip: 'Filtri avanzati',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordina per',
            onSelected: (value) {
              setState(() {
                sortBy = value;
                _sortPlayers();
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                  value: 'rating',
                  child: Row(
                    children: [
                      Icon(Icons.star, size: 18, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      const Text('Rating'),
                    ],
                  )),
              PopupMenuItem(
                  value: 'goals',
                  child: Row(
                    children: [
                      Icon(Icons.sports_soccer,
                          size: 18, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      const Text('Goal'),
                    ],
                  )),
              PopupMenuItem(
                  value: 'assists',
                  child: Row(
                    children: [
                      Icon(Icons.assistant,
                          size: 18, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Text(tr(context, 'Assist')),
                    ],
                  )),
              PopupMenuItem(
                  value: 'name',
                  child: Row(
                    children: [
                      Icon(Icons.sort_by_alpha,
                          size: 18, color: theme.primaryColor),
                      const SizedBox(width: 8),
                      const Text('Nome'),
                    ],
                  )),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(theme, isDark),
          _buildActiveFilters(theme, isDark),
          _buildStats(theme, isDark),
          Expanded(
            child: filteredPlayers.isEmpty
                ? _buildEmptyState(theme, isDark)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredPlayers.length,
                    itemBuilder: (context, index) {
                      return _buildPlayerCard(
                          filteredPlayers[index], theme, isDark, index);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCompareSelection(),
        icon: Icon(Icons.compare_arrows),
        label: Text(tr(context, 'Confronta')),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
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
      child: TextField(
        decoration: InputDecoration(
          hintText: tr(context, 'Cerca giocatore...'),
          prefixIcon: Icon(Icons.search, color: theme.primaryColor),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      searchQuery = '';
                      _applyFilters();
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildActiveFilters(ThemeData theme, bool isDark) {
    final activeFilters = <Widget>[];

    if (minRating > 0) {
      activeFilters.add(_buildFilterChip(
        'Rating ≥ ${minRating.toStringAsFixed(1)}',
        () => setState(() {
          minRating = 0;
          _applyFilters();
        }),
        theme,
      ));
    }

    if (minMinutes > 0) {
      activeFilters.add(_buildFilterChip(
        'Min ${minMinutes}\'',
        () => setState(() {
          minMinutes = 0;
          _applyFilters();
        }),
        theme,
      ));
    }

    if (positionFilter != null) {
      activeFilters.add(_buildFilterChip(
        positionFilter!,
        () => setState(() {
          positionFilter = null;
          _applyFilters();
        }),
        theme,
      ));
    }

    if (minAge != null || maxAge != null) {
      activeFilters.add(_buildFilterChip(
        'Età ${minAge ?? 0}-${maxAge ?? 99}',
        () => setState(() {
          minAge = null;
          maxAge = null;
          _applyFilters();
        }),
        theme,
      ));
    }

    if (selectedBadges.isNotEmpty) {
      for (final badge in selectedBadges) {
        activeFilters.add(_buildFilterChip(
          _getBadgeName(badge),
          () => setState(() {
            selectedBadges.remove(badge);
            _applyFilters();
          }),
          theme,
        ));
      }
    }

    if (activeFilters.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...activeFilters,
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => setState(() {
                minRating = 0;
                minMinutes = 0;
                positionFilter = null;
                minAge = null;
                maxAge = null;
                selectedBadges.clear();
                _applyFilters();
              }),
              icon: Icon(Icons.clear_all, size: 18),
              label: Text(tr(context, 'Cancella tutto')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      String label, VoidCallback onDelete, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: onDelete,
        backgroundColor: theme.primaryColor.withOpacity(0.2),
        labelStyle: TextStyle(
          color: theme.primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStats(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              'Totale', '${widget.allPlayers.length}', Icons.people, theme),
          _buildStatItem('Filtrati', '${filteredPlayers.length}',
              Icons.filter_list, theme),
          _buildStatItem('Ordina', _getSortLabel(), Icons.sort, theme),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.primaryColor),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  String _getSortLabel() {
    switch (sortBy) {
      case 'rating':
        return 'Rating';
      case 'goals':
        return 'Goal';
      case 'assists':
        return 'Assist';
      case 'name':
        return 'Nome';
      default:
        return 'Rating';
    }
  }

  Widget _buildPlayerCard(
      Player player, ThemeData theme, bool isDark, int index) {
    final badges = _getPlayerBadges(player);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withOpacity(0.08),
            theme.primaryColor.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withOpacity(0.7)
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: player.photo != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: player.photo!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 30),
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white, size: 30),
            ),
            if (index < 3)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: index == 0
                        ? const Color(0xFFFFD700)
                        : index == 1
                            ? const Color(0xFFC0C0C0)
                            : const Color(0xFFCD7F32),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                player.name,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            if (player.rating != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: player.rating >= 8.0
                        ? [const Color(0xFF00C853), const Color(0xFF00E676)]
                        : player.rating >= 7.0
                            ? [const Color(0xFF2196F3), const Color(0xFF64B5F6)]
                            : [
                                const Color(0xFFFFC107),
                                const Color(0xFFFFD54F)
                              ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  player.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMiniStat(Icons.sports_soccer,
                    player.goals?.toString() ?? '0', const Color(0xFF00C853)),
                const SizedBox(width: 12),
                _buildMiniStat(Icons.assistant,
                    player.assists?.toString() ?? '0', const Color(0xFF2196F3)),
                const Spacer(),
                if (badges.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: badges
                        .take(3)
                        .map((badge) => _buildBadgeIcon(badge))
                        .toList(),
                  ),
              ],
            ),
          ],
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerProfileScreen(player: player),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeIcon(String badge) {
    final badgeData = _getBadgeData(badge);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: badgeData['colors']),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (badgeData['colors'][0] as Color).withOpacity(0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(badgeData['icon'], size: 12, color: Colors.white),
    );
  }

  Map<String, dynamic> _getBadgeData(String badge) {
    switch (badge) {
      case '100_appearances':
        return {
          'icon': Icons.emoji_events,
          'colors': [const Color(0xFFFFD700), const Color(0xFFFFA000)],
        };
      case '10_goals':
        return {
          'icon': Icons.sports_soccer,
          'colors': [const Color(0xFF00C853), const Color(0xFF00E676)],
        };
      case '5_assists':
        return {
          'icon': Icons.assistant,
          'colors': [const Color(0xFF2196F3), const Color(0xFF64B5F6)],
        };
      case 'motm':
        return {
          'icon': Icons.star,
          'colors': [const Color(0xFFFF9800), const Color(0xFFFFA726)],
        };
      case 'clean_sheet':
        return {
          'icon': Icons.block,
          'colors': [const Color(0xFF9C27B0), const Color(0xFFBA68C8)],
        };
      default:
        return {
          'icon': Icons.emoji_events,
          'colors': [Colors.grey, Colors.grey[400]],
        };
    }
  }

  String _getBadgeName(String badge) {
    switch (badge) {
      case '100_appearances':
        return tr(context, '100 Presenze');
      case '10_goals':
        return '10 Goal';
      case '5_assists':
        return '5 Assist';
      case 'motm':
        return 'MOTM';
      case 'clean_sheet':
        return 'Porta Inviolata';
      default:
        return badge;
    }
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[400]),
            SizedBox(height: 24),
            Text(
              tr(context, 'Nessun giocatore trovato'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 12),
            Text(
              tr(context, 'Prova a modificare i filtri di ricerca'),
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {
                searchQuery = '';
                minRating = 0;
                minMinutes = 0;
                positionFilter = null;
                minAge = null;
                maxAge = null;
                selectedBadges.clear();
                _applyFilters();
              }),
              icon: const Icon(Icons.refresh),
              label: const Text('Resetta Filtri'),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlayerFilterModal(
        minRating: minRating,
        minMinutes: minMinutes,
        positionFilter: positionFilter,
        nationalityFilter: nationalityFilter,
        minAge: minAge,
        maxAge: maxAge,
        selectedBadges: selectedBadges,
        onApply: (filters) {
          setState(() {
            minRating = filters['minRating'];
            minMinutes = filters['minMinutes'];
            positionFilter = filters['position'];
            nationalityFilter = filters['nationality'];
            minAge = filters['minAge'];
            maxAge = filters['maxAge'];
            selectedBadges = List<String>.from(filters['badges']);
            _applyFilters();
          });
        },
      ),
    );
  }

  void _showCompareSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerComparisonScreen(
          initialPlayers: const [],
          allPlayers: filteredPlayers,
        ),
      ),
    );
  }
}
