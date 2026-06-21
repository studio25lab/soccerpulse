// lib/widgets/tactical_formation_widget.dart

import 'package:flutter/material.dart';
import '../../utils/l10n_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/soccer_match.dart';
import '../models/player.dart';
import '../pages/player_profile_screen.dart';
import '../pages/player_comparison_screen.dart';
import 'football_field_painter.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:ui' as ui;
import '../painters/formation_painters.dart';
import '../pages/player_stats_screen.dart';

class TacticalFormationWidget extends StatefulWidget {
  final SoccerMatch match;
  final List<Player> homeLineup;
  final List<Player> awayLineup;
  final bool showHome;
  final String formation;

  const TacticalFormationWidget({
    Key? key,
    required this.match,
    required this.homeLineup,
    required this.awayLineup,
    required this.showHome,
    required this.formation,
  }) : super(key: key);

  @override
  State<TacticalFormationWidget> createState() =>
      _TacticalFormationWidgetState();
}

class _TacticalFormationWidgetState extends State<TacticalFormationWidget> {
  late bool _showHome;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _selectedPositions = {};

  @override
  void initState() {
    super.initState();
    _showHome = widget.showHome;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Player> _getFilteredPlayers(List<Player> players) {
    // Se c'è una ricerca o filtri attivi, cerca in ENTRAMBE le squadre
    if (_searchQuery.isNotEmpty || _selectedPositions.isNotEmpty) {
      final allPlayers = [...widget.homeLineup, ...widget.awayLineup];
      return allPlayers.where((player) {
        final matchesSearch = player.name.toLowerCase().contains(_searchQuery);
        final matchesPosition = _selectedPositions.isEmpty ||
            _selectedPositions.contains(_getPositionCategory(player.position));
        return matchesSearch && matchesPosition;
      }).toList();
    }

    // Altrimenti usa solo la squadra corrente
    return players.where((player) {
      final matchesSearch = player.name.toLowerCase().contains(_searchQuery);
      final matchesPosition = _selectedPositions.isEmpty ||
          _selectedPositions.contains(_getPositionCategory(player.position));
      return matchesSearch && matchesPosition;
    }).toList();
  }

  String _getPositionCategory(String position) {
    final pos = position.toUpperCase();
    if (pos.contains('G') || pos == 'GOALKEEPER') return 'GK';
    if (pos.contains('D') || pos == 'DEFENDER') return 'DEF';
    if (pos.contains('M') || pos == 'MIDFIELDER') return 'MID';
    if (pos.contains('F') ||
        pos.contains('A') ||
        pos == 'FORWARD' ||
        pos == 'ATTACKER') return 'FWD';
    return 'DEF';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final currentLineup = _showHome ? widget.homeLineup : widget.awayLineup;
    final currentFormation = _showHome ? '4-3-3' : '3-5-2';

    final filteredLineup = _getFilteredPlayers(currentLineup);
    final starters = filteredLineup.take(11).toList();
    final bench = filteredLineup.skip(11).toList();

    return Column(
      children: [
        _buildTeamToggle(theme, isDark),
        const SizedBox(height: 16),
        _buildSearchBar(theme, isDark),
        const SizedBox(height: 12),
        _buildPositionFilters(theme, isDark),
        const SizedBox(height: 16),
        if (_searchQuery.isNotEmpty || _selectedPositions.isNotEmpty)
          _buildSearchResults(filteredLineup, theme, isDark),
        if (_searchQuery.isEmpty && _selectedPositions.isEmpty)
          _buildField(starters, currentFormation, theme, isDark),
        const SizedBox(height: 24),
        if (_searchQuery.isEmpty && _selectedPositions.isEmpty)
          _buildManager(theme, isDark),
        const SizedBox(height: 16),
        if (_searchQuery.isEmpty && _selectedPositions.isEmpty)
          _buildBench(bench, starters, theme, isDark),
      ],
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: tr(context, 'Cerca in entrambe le squadre...'),
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
          prefixIcon: Icon(Icons.search, color: theme.primaryColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : Icon(Icons.groups, color: theme.primaryColor.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildPositionFilters(ThemeData theme, bool isDark) {
    final positions = [
      {'label': 'Portieri', 'value': 'GK', 'icon': Icons.sports_handball},
      {'label': 'Difensori', 'value': 'DEF', 'icon': Icons.shield},
      {'label': 'Centrocampisti', 'value': 'MID', 'icon': Icons.swap_horiz},
      {'label': 'Attaccanti', 'value': 'FWD', 'icon': Icons.sports_soccer},
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: positions.length,
        itemBuilder: (context, index) {
          final pos = positions[index];
          final isSelected = _selectedPositions.contains(pos['value']);

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    pos['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.white : theme.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(pos['label'] as String),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedPositions.add(pos['value'] as String);
                  } else {
                    _selectedPositions.remove(pos['value']);
                  }
                });
              },
              selectedColor: theme.primaryColor,
              backgroundColor: isDark ? Colors.grey[850] : Colors.grey[100],
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white : Colors.black87),
                fontWeight: FontWeight.bold,
              ),
              side: BorderSide(
                color: isSelected ? theme.primaryColor : Colors.grey[400]!,
                width: 2,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults(
      List<Player> players, ThemeData theme, bool isDark) {
    if (players.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              tr(context, 'Nessun giocatore trovato'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Prova con un altro nome o filtro',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.search, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  '${players.length} giocatore${players.length != 1 ? 'i' : ''} trovat${players.length != 1 ? 'i' : 'o'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          ...players
              .map((player) => _buildPlayerSearchItem(player, theme, isDark)),
        ],
      ),
    );
  }

  Widget _buildPlayerSearchItem(Player player, ThemeData theme, bool isDark) {
    // Determina se il giocatore è della squadra Home o Away
    final isHomePlayer = widget.homeLineup.any((p) => p.id == player.id);
    final teamBadgeColor = isHomePlayer
        ? const Color(0xFF2196F3) // Blu per Home
        : const Color(0xFFE53935); // Rosso per Away
    final teamLabel =
        isHomePlayer ? widget.match.homeTeamName : widget.match.awayTeamName;

    return InkWell(
      onTap: () => _showPlayerStats(player),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [teamBadgeColor, teamBadgeColor.withOpacity(0.7)],
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: player.photo != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: player.photo!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(
                                Icons.person,
                                size: 25,
                                color: Colors.white),
                          ),
                        )
                      : const Icon(Icons.person, size: 25, color: Colors.white),
                ),
                // Badge numero maglia
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: teamBadgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      '${player.id}',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          player.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      // Badge squadra
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              teamBadgeColor,
                              teamBadgeColor.withOpacity(0.7)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: teamBadgeColor.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          teamLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          player.position,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        player.teamName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamToggle(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showHome = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _showHome ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _showHome
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.match.homeTeamLogo != null)
                      CachedNetworkImage(
                        imageUrl: widget.match.homeTeamLogo!,
                        width: 24,
                        height: 24,
                      )
                    else
                      const Icon(Icons.sports_soccer, size: 24),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.match.homeTeamName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _showHome
                              ? Colors.black
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showHome = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_showHome ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_showHome
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.match.awayTeamLogo != null)
                      CachedNetworkImage(
                        imageUrl: widget.match.awayTeamLogo!,
                        width: 24,
                        height: 24,
                      )
                    else
                      const Icon(Icons.sports_soccer, size: 24),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.match.awayTeamName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: !_showHome
                              ? Colors.black
                              : (isDark ? Colors.white70 : Colors.black54),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
      List<Player> starters, String formation, ThemeData theme, bool isDark) {
    return Container(
      height: 500,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1E1E1E).withOpacity(0.5),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fieldSize =
                Size(constraints.maxWidth, constraints.maxHeight);
            return CustomPaint(
              painter: FootballFieldPainter(inset: 12),
              child: starters.isEmpty
                  ? Center(
                      child: Text(
                        tr(context, 'Formazione non disponibile'),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    )
                  : Stack(
                      children: _positionPlayers(starters, formation, fieldSize),
                    ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _positionPlayers(
      List<Player> starters, String formation, Size fieldSize) {
    if (starters.isEmpty) return [];

    final lines = formation.split('-').map(int.parse).toList();
    List<Widget> positioned = [];
    int playerIndex = 1;

    const playerHalfWidth = 32.5;
    const safeHorizontal = 16.0;
    const safeTop = 24.0;
    const safeBottom = 34.0;
    final usableWidth = fieldSize.width - (safeHorizontal * 2);
    final usableHeight = fieldSize.height - safeTop - safeBottom;

    if (starters.isNotEmpty) {
      positioned.add(
        Positioned(
          left: fieldSize.width / 2 - playerHalfWidth,
          top: safeTop,
          child: _buildPlayerCircle(starters[0]),
        ),
      );
    }

    final spacing = usableHeight / (lines.length + 1);

    for (int lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final playersInLine = lines[lineIndex];
      final lineTop = safeTop + (spacing * (lineIndex + 1));

      for (int i = 0; i < playersInLine && playerIndex < starters.length; i++) {
        final player = starters[playerIndex];
        final horizontalSpacing = usableWidth / (playersInLine + 1);
        final leftPosition =
            safeHorizontal + (horizontalSpacing * (i + 1)) - playerHalfWidth;

        positioned.add(
          Positioned(
            left: leftPosition,
            top: lineTop,
            child: _buildPlayerCircle(player),
          ),
        );

        playerIndex++;
      }
    }

    return positioned;
  }

  Widget _buildPlayerCircle(Player player) {
    return GestureDetector(
      onTap: () => _showPlayerStats(player),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00C853), Color(0xFF00E676)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
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
                              size: 35,
                              color: Colors.white),
                        ),
                      )
                    : const Icon(Icons.person, size: 35, color: Colors.white),
              ),
              Positioned(
                top: -8,
                right: -8,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: const Color(0xFF00C853), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${player.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00C853),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            constraints: const BoxConstraints(maxWidth: 80),
            child: Text(
              player.name.split(' ').last.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showPlayerStats(Player player) {
    final allPlayers = [...widget.homeLineup, ...widget.awayLineup];

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerStatsScreen(
          player: player,
          allPlayers: allPlayers,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  Widget _buildManager(ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.person, color: theme.primaryColor, size: 30),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _showHome ? 'Simone Inzaghi' : 'Gian Piero Gasperini',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manager',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBench(
      List<Player> bench, List<Player> starters, ThemeData theme, bool isDark) {
    if (bench.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            tr(context, 'Nessun sostituto disponibile'),
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Substitutions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          ...bench.asMap().entries.map((entry) => _buildBenchPlayer(
              entry.value, entry.key, starters, theme, isDark)),
        ],
      ),
    );
  }

  Widget _buildBenchPlayer(Player player, int index, List<Player> starters,
      ThemeData theme, bool isDark) {
    final isSubstituted = index < 3;
    final minute = isSubstituted ? '${60 + index * 10}\'' : null;
    final replacedPlayer = isSubstituted && (index + 8) < starters.length
        ? starters[index + 8].name
        : null;

    return InkWell(
      onTap: () => _showPlayerStats(player),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: player.photo != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: player.photo!,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) =>
                            const Icon(Icons.person, size: 20),
                      ),
                    )
                  : const Icon(Icons.person, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${player.id} ${player.name}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (isSubstituted && replacedPlayer != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C853).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_circle_down,
                                  color: Color(0xFF00C853), size: 12),
                              const SizedBox(width: 4),
                              Text(
                                'Out: ${replacedPlayer.split(' ').last}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF00C853),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (minute != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFA726),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  minute,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
