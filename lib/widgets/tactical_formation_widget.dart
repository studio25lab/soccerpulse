// lib/widgets/tactical_formation_widget.dart

import 'package:flutter/material.dart';
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
          hintText: 'Cerca in entrambe le squadre...',
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
            const SizedBox(height: 16),
            Text(
              'Nessun giocatore trovato',
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
                        'Formazione non disponibile',
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
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Nessun sostituto disponibile',
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

class PlayerStatsScreen extends StatefulWidget {
  final Player player;
  final List<Player> allPlayers;

  const PlayerStatsScreen({
    Key? key,
    required this.player,
    required this.allPlayers,
  }) : super(key: key);

  @override
  State<PlayerStatsScreen> createState() => _PlayerStatsScreenState();
}

class _PlayerStatsScreenState extends State<PlayerStatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  Map<String, bool> notifications = {
    'goals': false,
    'assists': false,
    'yellowCard': false,
    'redCard': false,
    'substitution': false,
    'shots': false,
    'tackles': false,
    'passes': false,
    'foulsCommitted': false,
    'foulsSuffered': false,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this); // 8 tabs ora!
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'player_${widget.player.id}_notifications';
      final jsonString = prefs.getString(key);

      if (jsonString != null) {
        final Map<String, dynamic> decoded = json.decode(jsonString);
        setState(() {
          notifications = decoded.map((k, v) => MapEntry(k, v as bool));
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'player_${widget.player.id}_notifications';
      final jsonString = json.encode(notifications);
      await prefs.setString(key, jsonString);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Notifiche salvate per ${widget.player.name}!'),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF00C853),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore nel salvataggio: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleAllNotifications(bool value) {
    setState(() {
      notifications = notifications.map((key, _) => MapEntry(key, value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(theme, isDark),
            _buildTabBar(isDark),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: theme.primaryColor),
                          const SizedBox(height: 16),
                          Text(
                            'Caricamento preferenze...',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAllTab(theme, isDark),
                        _buildShotTab(theme, isDark),
                        _buildPassTab(theme, isDark),
                        _buildDribTab(theme, isDark),
                        _buildDefTab(theme, isDark),
                        _buildNotificationsTab(theme, isDark),
                        _buildPerformanceTab(theme, isDark), // NUOVO!
                        _buildProfileTab(theme, isDark),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Colors.grey[850]! : Colors.white,
            isDark ? Colors.grey[900]! : Colors.grey[50]!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  // BOTTONE CONFRONTA
                  IconButton(
                    icon: const Icon(Icons.compare_arrows),
                    onPressed: () => _openComparison(),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    tooltip: 'Confronta giocatori',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          isDark ? Colors.grey[800] : Colors.grey[200],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF00E676)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00C853).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: widget.player.photo != null
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: widget.player.photo!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.white),
                        ),
                      )
                    : const Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.player.name,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.player.position,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${widget.player.teamName} • #${widget.player.id}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (widget.player.rating != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE53935).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.player.rating!.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
        indicator: BoxDecoration(
          gradient:
              const LinearGradient(colors: [Colors.black, Color(0xFF424242)]),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'Tutto'),
          Tab(text: 'Shot'),
          Tab(text: 'Pass'),
          Tab(text: 'Drib'),
          Tab(text: 'Def'),
          Tab(
              child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications, size: 16),
              SizedBox(width: 4),
              Text('Notifiche'),
            ],
          )),
          Tab(
              child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.show_chart, size: 16),
              SizedBox(width: 4),
              Text('Prestazioni'),
            ],
          )),
          Tab(
              child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person, size: 16),
              SizedBox(width: 4),
              Text('Profilo'),
            ],
          )),
        ],
      ),
    );
  }

  static const offensivaColor = Color(0xFF00C853);
  static const difensivaColor = Color(0xFF1976D2);
  static const duelliColor = Color(0xFFFF9800);
  static const passaggiColor = Color(0xFF9C27B0);
  static const altroColor = Color(0xFF00BCD4);

  Widget _buildAllTab(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildHeatmap(),
        const SizedBox(height: 24),
        _buildStatItem('Gol', widget.player.goals?.toString() ?? '0',
            Icons.sports_soccer, theme, offensivaColor),
        _buildStatItem('xG', '0.25', Icons.query_stats, theme, offensivaColor),
        _buildStatItem('Assists', widget.player.assists?.toString() ?? '0',
            Icons.assist_walker, theme, offensivaColor),
        _buildStatItem('xA', '0.15', Icons.trending_up, theme, offensivaColor),
        const Divider(height: 32),
        _buildStatItem(
            'Contributi difesa', '12', Icons.shield, theme, difensivaColor),
        _buildStatItem('Contrasti (vinti)', '${widget.player.tackles ?? 0} (1)',
            Icons.sports_kabaddi, theme, difensivaColor),
        _buildStatItem(
            'Intercetti',
            widget.player.interceptions?.toString() ?? '0',
            Icons.block,
            theme,
            difensivaColor),
        _buildStatItem(
            'Chiusure difensive', '11', Icons.lock, theme, difensivaColor),
        _buildStatItem('Tiri respinti', '1', Icons.sports_volleyball, theme,
            difensivaColor),
        _buildStatItem('Recuperi', '2', Icons.cached, theme, difensivaColor),
        const Divider(height: 32),
        _buildStatItem('Duelli a terra (vinti)', '6 (1)', Icons.sports_mma,
            theme, duelliColor),
        _buildStatItem('Duelli aerei (vinti)', '6 (1)', Icons.flight_takeoff,
            theme, duelliColor),
        _buildStatItem('Falli', '3', Icons.warning, theme, duelliColor),
        _buildStatItem('Dribbling (riusciti)', '0 (0)', Icons.directions_run,
            theme, duelliColor),
        const Divider(height: 32),
        _buildStatItem(
            'Passaggi (precisi)',
            '${widget.player.passes ?? 0} (29/35 83%)',
            Icons.sync_alt,
            theme,
            passaggiColor),
        _buildStatItem(
            'Passaggi chiave', '0', Icons.vpn_key, theme, passaggiColor),
        _buildStatItem('Cross (precisi)', '0 (0)', Icons.filter_tilt_shift,
            theme, passaggiColor),
        _buildStatItem('Passaggi metà avversaria', '5/10 (50%)',
            Icons.trending_up, theme, passaggiColor),
        _buildStatItem('Passaggi propria metà', '24/25 (96%)',
            Icons.trending_down, theme, passaggiColor),
        const Divider(height: 32),
        _buildStatItem('Tocchi', '54', Icons.touch_app, theme, altroColor),
        _buildStatItem(
            'Palla persa', '7', Icons.remove_circle_outline, theme, altroColor),
        _buildStatItem('Tiri (in porta)', '${widget.player.shots ?? 0} (0)',
            Icons.sports, theme, altroColor),
        _buildStatItem(
            'Tiri totali', '1', Icons.sports_baseball, theme, altroColor),
        _buildStatItem('Tiri respinti', '1', Icons.block, theme, altroColor),
      ],
    );
  }

  Widget _buildShotTab(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildStatItem('Gol', widget.player.goals?.toString() ?? '0',
            Icons.sports_soccer, theme, offensivaColor),
        _buildStatItem('xG', '0.25', Icons.query_stats, theme, offensivaColor),
        _buildStatItem(
            'Tiri totali', '1', Icons.sports_baseball, theme, offensivaColor),
        _buildStatItem(
            'Tiri in porta', '0', Icons.sports, theme, offensivaColor),
        _buildStatItem(
            'Tiri respinti', '1', Icons.block, theme, offensivaColor),
      ],
    );
  }

  Widget _buildPassTab(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildStatItem('Passaggi totali', '${widget.player.passes ?? 0}',
            Icons.sync_alt, theme, passaggiColor),
        _buildStatItem('Passaggi precisi', '29/35 (83%)', Icons.check_circle,
            theme, passaggiColor),
        _buildStatItem(
            'Passaggi chiave', '0', Icons.vpn_key, theme, passaggiColor),
        _buildStatItem(
            'Cross', '0 (0)', Icons.filter_tilt_shift, theme, passaggiColor),
        _buildStatItem('Passaggi metà avversaria', '5/10 (50%)',
            Icons.trending_up, theme, passaggiColor),
        _buildStatItem('Passaggi propria metà', '24/25 (96%)',
            Icons.trending_down, theme, passaggiColor),
        _buildStatItem('Passaggi lunghi', '2/3 (67%)', Icons.arrow_forward,
            theme, passaggiColor),
      ],
    );
  }

  Widget _buildDribTab(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildStatItem(
            'Dribbling', '0', Icons.directions_run, theme, duelliColor),
        _buildStatItem('Dribbling riusciti', '0 (0%)', Icons.check_circle,
            theme, duelliColor),
        _buildStatItem('Tocchi', '54', Icons.touch_app, theme, duelliColor),
        _buildStatItem('Palla persa', '7', Icons.remove_circle_outline, theme,
            duelliColor),
        _buildStatItem(
            'Duelli a terra', '6 (1)', Icons.sports_mma, theme, duelliColor),
        _buildStatItem(
            'Duelli aerei', '6 (1)', Icons.flight_takeoff, theme, duelliColor),
      ],
    );
  }

  Widget _buildDefTab(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildStatItem(
            'Contributi difesa', '12', Icons.shield, theme, difensivaColor),
        _buildStatItem('Contrasti', '${widget.player.tackles ?? 0}',
            Icons.sports_kabaddi, theme, difensivaColor),
        _buildStatItem('Contrasti vinti', '1 (1)', Icons.emoji_events, theme,
            difensivaColor),
        _buildStatItem(
            'Intercetti',
            widget.player.interceptions?.toString() ?? '0',
            Icons.block,
            theme,
            difensivaColor),
        _buildStatItem(
            'Chiusure difensive', '11', Icons.lock, theme, difensivaColor),
        _buildStatItem('Tiri respinti', '1', Icons.sports_volleyball, theme,
            difensivaColor),
        _buildStatItem('Recuperi', '2', Icons.cached, theme, difensivaColor),
        _buildStatItem('Falli', '3', Icons.warning, theme, difensivaColor),
        if (widget.player.yellowCards != null && widget.player.yellowCards! > 0)
          _buildStatItem(
              'Cartellini gialli',
              widget.player.yellowCards.toString(),
              Icons.square,
              theme,
              Colors.yellow[700]!),
        if (widget.player.redCards != null && widget.player.redCards! > 0)
          _buildStatItem('Cartellini rossi', widget.player.redCards.toString(),
              Icons.square, theme, Colors.red),
      ],
    );
  }

  Widget _buildNotificationsTab(ThemeData theme, bool isDark) {
    final allEnabled = notifications.values.every((v) => v);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor.withOpacity(0.1),
                theme.primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.primaryColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(Icons.notifications_active,
                  size: 48, color: theme.primaryColor),
              const SizedBox(height: 12),
              Text(
                'Notifiche Personalizzate',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ricevi notifiche per ogni azione di ${widget.player.name.split(' ').last}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _toggleAllNotifications(!allEnabled),
          icon: Icon(allEnabled
              ? Icons.notifications_off
              : Icons.notifications_active),
          label: Text(
            allEnabled ? 'Disattiva tutte' : 'Attiva tutte',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: allEnabled ? Colors.grey[700] : theme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
          ),
        ),
        const SizedBox(height: 24),
        _buildNotificationToggle(
            'Goal segnati',
            'Ricevi notifica quando segna un goal',
            Icons.sports_soccer,
            'goals',
            offensivaColor,
            isDark),
        _buildNotificationToggle(
            'Assist',
            'Ricevi notifica quando fa un assist',
            Icons.assist_walker,
            'assists',
            offensivaColor,
            isDark),
        _buildNotificationToggle(
            'Cartellino giallo',
            'Ricevi notifica per ammonizioni',
            Icons.square,
            'yellowCard',
            const Color(0xFFFFC107),
            isDark),
        _buildNotificationToggle(
            'Cartellino rosso',
            'Ricevi notifica per espulsioni',
            Icons.square,
            'redCard',
            const Color(0xFFE53935),
            isDark),
        _buildNotificationToggle(
            'Sostituzioni',
            'Ricevi notifica quando entra/esce',
            Icons.swap_horiz,
            'substitution',
            const Color(0xFF2196F3),
            isDark),
        _buildNotificationToggle(
            'Tiri in porta',
            'Ricevi notifica per tiri in porta',
            Icons.sports,
            'shots',
            passaggiColor,
            isDark),
        _buildNotificationToggle(
            'Contrasti vinti',
            'Ricevi notifica per contrasti importanti',
            Icons.sports_kabaddi,
            'tackles',
            difensivaColor,
            isDark),
        _buildNotificationToggle(
            'Passaggi chiave',
            'Ricevi notifica per passaggi decisivi',
            Icons.vpn_key,
            'passes',
            passaggiColor,
            isDark),
        _buildNotificationToggle(
            'Falli commessi',
            'Ricevi notifica quando commette un fallo',
            Icons.warning_amber,
            'foulsCommitted',
            duelliColor,
            isDark),
        _buildNotificationToggle(
            'Falli subiti',
            'Ricevi notifica quando subisce un fallo',
            Icons.personal_injury,
            'foulsSuffered',
            altroColor,
            isDark),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saveNotifications,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save),
              SizedBox(width: 8),
              Text(
                'Salva preferenze notifiche',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // NEW TAB PROFILO!
  Widget _buildProfileTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.2),
                  theme.primaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.account_circle, size: 64, color: theme.primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Profilo Completo',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scopri informazioni dettagliate su ${widget.player.name.split(' ')[0]}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _openFullProfile(),
                  icon: const Icon(Icons.person),
                  label: const Text(
                    'Vedi Profilo Completo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildQuickInfo(
              'Informazioni',
              [
                {'icon': Icons.cake, 'label': 'Età', 'value': '27 anni'},
                {'icon': Icons.height, 'label': 'Altezza', 'value': '183 cm'},
                {
                  'icon': Icons.fitness_center,
                  'label': 'Peso',
                  'value': '78 kg'
                },
                {
                  'icon': Icons.flag,
                  'label': 'Nazionalità',
                  'value': '🇮🇹 Italia'
                },
              ],
              theme,
              isDark),
          const SizedBox(height: 16),
          _buildQuickInfo(
              'Contratto',
              [
                {
                  'icon': Icons.shield,
                  'label': 'Squadra',
                  'value': widget.player.teamName
                },
                {
                  'icon': Icons.calendar_today,
                  'label': 'Scadenza',
                  'value': '30/06/2027'
                },
                {'icon': Icons.euro, 'label': 'Valore', 'value': '€45.0M'},
              ],
              theme,
              isDark),
        ],
      ),
    );
  }

  // TAB PRESTAZIONI CON GRAFICI
  Widget _buildPerformanceTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header sezione
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withOpacity(0.2),
                  theme.primaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.show_chart, size: 48, color: theme.primaryColor),
                const SizedBox(height: 12),
                Text(
                  'Prestazioni Recenti',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Analisi ultimi 10 match di ${widget.player.name.split(' ')[0]}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Rating Trend (Line Chart)
          _buildRatingTrendChart(theme, isDark),

          const SizedBox(height: 24),

          // Goal + Assist (Bar Chart)
          _buildGoalAssistChart(theme, isDark),

          const SizedBox(height: 24),

          // Form Indicator
          _buildFormIndicator(theme, isDark),

          const SizedBox(height: 24),

          // Minuti giocati trend
          _buildMinutesChart(theme, isDark),

          const SizedBox(height: 24),

          // Confronto media campionato
          _buildComparisonStats(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildRatingTrendChart(ThemeData theme, bool isDark) {
    // Dati mock ultimi 10 match
    final ratings = [6.5, 7.2, 6.8, 7.5, 8.0, 7.8, 6.9, 7.3, 7.7, 8.2];

    return Container(
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF00E676)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.timeline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trend Rating',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Ultimi 10 match',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up,
                        color: Color(0xFF00C853), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${ratings.last.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00C853),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: LineChartPainter(
                values: ratings,
                color: const Color(0xFF00C853),
                isDark: isDark,
              ),
              size: const Size(double.infinity, 200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalAssistChart(ThemeData theme, bool isDark) {
    // Dati mock ultimi 10 match
    final goals = [0, 1, 0, 2, 1, 0, 0, 1, 0, 1];
    final assists = [1, 0, 1, 0, 0, 1, 0, 0, 1, 0];

    return Container(
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.bar_chart, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Goal & Assist',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Contributi offensivi',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C853).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sports_soccer,
                            size: 14, color: Color(0xFF00C853)),
                        const SizedBox(width: 4),
                        Text(
                          '${goals.reduce((a, b) => a + b)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00C853),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.assistant,
                            size: 14, color: Color(0xFF2196F3)),
                        const SizedBox(width: 4),
                        Text(
                          '${assists.reduce((a, b) => a + b)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2196F3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: CustomPaint(
              painter: BarChartPainter(
                goalsData: goals,
                assistsData: assists,
                isDark: isDark,
              ),
              size: const Size(double.infinity, 200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormIndicator(ThemeData theme, bool isDark) {
    // Forma ultimi 5 match: W=Win, D=Draw, L=Loss
    final form = ['W', 'W', 'L', 'D', 'W'];

    return Container(
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFFFA726)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.emoji_events,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Forma Recente',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Ultimi 5 match della squadra',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: form.reversed.map((result) {
              Color color;
              IconData icon;
              String label;

              switch (result) {
                case 'W':
                  color = const Color(0xFF00C853);
                  icon = Icons.check_circle;
                  label = 'V';
                  break;
                case 'D':
                  color = const Color(0xFFFFC107);
                  icon = Icons.remove_circle;
                  label = 'P';
                  break;
                case 'L':
                  color = const Color(0xFFE53935);
                  icon = Icons.cancel;
                  label = 'S';
                  break;
                default:
                  color = Colors.grey;
                  icon = Icons.help;
                  label = '?';
              }

              return Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMinutesChart(ThemeData theme, bool isDark) {
    final minutes = [90, 78, 90, 85, 90, 73, 90, 90, 62, 90];

    return Container(
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF9C27B0), Color(0xFFBA68C8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.timer, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Minuti Giocati',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Tempo in campo',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${minutes.reduce((a, b) => a + b)} min',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF9C27B0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: MinutesChartPainter(
                minutes: minutes,
                color: const Color(0xFF9C27B0),
                isDark: isDark,
              ),
              size: const Size(double.infinity, 150),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonStats(ThemeData theme, bool isDark) {
    final playerStats = {
      'Rating': 7.4,
      'Goal/90': 0.6,
      'Assist/90': 0.3,
      'Pass%': 85.2,
      'Tackle': 2.1,
    };

    final leagueAvg = {
      'Rating': 6.8,
      'Goal/90': 0.4,
      'Assist/90': 0.2,
      'Pass%': 78.5,
      'Tackle': 1.8,
    };

    return Container(
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFF06292)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.compare_arrows,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'vs Media Campionato',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Confronto prestazioni',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...playerStats.entries.map((entry) {
            final playerValue = entry.value;
            final avgValue = leagueAvg[entry.key]!;
            final difference = ((playerValue - avgValue) / avgValue * 100);
            final isPositive = difference > 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            playerValue.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00C853),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isPositive
                                  ? const Color(0xFF00C853).withOpacity(0.2)
                                  : const Color(0xFFE53935).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPositive
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  size: 12,
                                  color: isPositive
                                      ? const Color(0xFF00C853)
                                      : const Color(0xFFE53935),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '${difference.abs().toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isPositive
                                        ? const Color(0xFF00C853)
                                        : const Color(0xFFE53935),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: (playerValue * 100).toInt(),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00C853), Color(0xFF00E676)],
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: (100 - playerValue * 100).toInt(),
                        child: Container(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Media: ${avgValue.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickInfo(String title, List<Map<String, dynamic>> items,
      ThemeData theme, bool isDark) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData,
                        color: theme.primaryColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item['label'] as String,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ),
                    Text(
                      item['value'] as String,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    IconData icon,
    String key,
    Color color,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        value: notifications[key] ?? false,
        onChanged: (value) {
          setState(() {
            notifications[key] = value;
          });
        },
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 52, top: 4),
          child: Text(subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ),
        activeColor: color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildHeatmap() {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CustomPaint(
          painter: SofaScoreHeatmapPainter(),
          child: Container(),
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, ThemeData theme, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          Text(
            value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  void _openFullProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerProfileScreen(player: widget.player),
      ),
    );
  }

  void _openComparison() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PlayerComparisonScreen(
          initialPlayers: [widget.player],
          allPlayers: widget.allPlayers,
        ),
      ),
    );
  }
}

// HEATMAP CORRETTA

// HEATMAP CORRETTA DEFINITIVA
class SofaScoreHeatmapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // BACKGROUND VERDE MEDIO
    final backgroundPaint = Paint()
      ..color = const Color(0xFF3D5A3C) // Verde campo medio
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, backgroundPaint);

    // LINEE NERE CON OPACITY
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Bordo esterno
    canvas.drawRect(rect, linePaint);

    // Linea centrale orizzontale
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      linePaint,
    );

    // Cerchio centrale
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      30,
      linePaint,
    );

    // FRECCIA GRANDE NERA IN ALTO
    _drawBigArrow(canvas, size);

    // HEAT POINTS GRANDI E SFOCATI
    final random = math.Random(42);
    final points = <_HeatPoint>[];

    // Genero 55 punti di calore
    for (int i = 0; i < 55; i++) {
      double x, y;

      // 65% punti concentrati al centro, 35% sparsi
      if (random.nextDouble() < 0.65) {
        x = size.width * (0.35 + random.nextDouble() * 0.3);
        y = size.height * (0.25 + random.nextDouble() * 0.45);
      } else {
        x = size.width * (0.15 + random.nextDouble() * 0.7);
        y = size.height * (0.15 + random.nextDouble() * 0.7);
      }

      final intensity = 0.45 + random.nextDouble() * 0.5;
      final radius = 50.0 + random.nextDouble() * 40.0; // 50-90px GRANDI!

      points.add(_HeatPoint(x, y, intensity, radius));
    }

    // Disegno i punti sfocati
    for (final point in points) {
      final startColor = point.intensity < 0.6
          ? const Color(0xFFFDD835) // Giallo
          : const Color(0xFFFF9800); // Arancione

      final heatGradient = RadialGradient(
        colors: [
          startColor.withOpacity(point.intensity * 0.9),
          startColor.withOpacity(point.intensity * 0.6),
          startColor.withOpacity(point.intensity * 0.3),
          startColor.withOpacity(0.0),
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      );

      final heatPaint = Paint()
        ..shader = heatGradient.createShader(
          Rect.fromCircle(
            center: Offset(point.x, point.y),
            radius: point.radius,
          ),
        )
        ..blendMode = BlendMode.screen
        ..maskFilter =
            const ui.MaskFilter.blur(ui.BlurStyle.normal, 8); // BLUR!

      canvas.drawCircle(Offset(point.x, point.y), point.radius, heatPaint);
    }
  }

  void _drawBigArrow(Canvas canvas, Size size) {
    final arrowPaint = Paint()
      ..color = Colors.black.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final path = Path();

    // Freccia grande e ben visibile
    path.moveTo(centerX, 15); // Punta
    path.lineTo(centerX - 20, 45); // Sinistra
    path.lineTo(centerX - 8, 45); // Interno sinistra
    path.lineTo(centerX - 8, 70); // Gambo sinistra
    path.lineTo(centerX + 8, 70); // Gambo destra
    path.lineTo(centerX + 8, 45); // Interno destra
    path.lineTo(centerX + 20, 45); // Destra
    path.close();

    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _HeatPoint {
  final double x;
  final double y;
  final double intensity;
  final double radius;

  _HeatPoint(this.x, this.y, this.intensity, this.radius);
}

// CUSTOM PAINTERS PER GRAFICI PRESTAZIONI

// LINE CHART PAINTER (Rating Trend)
class LineChartPainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final bool isDark;

  LineChartPainter({
    required this.values,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxValue = 10.0;
    final minValue = 5.0;
    final range = maxValue - minValue;

    // Padding per assi
    final leftPadding = 40.0;
    final bottomPadding = 30.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    // ASSE Y - Rating scale (5.0 - 10.0)
    final textStyle = TextStyle(
      color: isDark ? Colors.white70 : Colors.black54,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    for (int i = 0; i <= 5; i++) {
      final value = minValue + (range * i / 5);
      final y = chartHeight - (chartHeight * i / 5);

      // Grid line
      final gridPaint = Paint()
        ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.1)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        gridPaint,
      );

      // Y label
      final textSpan =
          TextSpan(text: value.toStringAsFixed(1), style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(0, y - textPainter.height / 2));
    }

    // ASSE X - Match numbers (1-10)
    final stepX = chartWidth / (values.length - 1);
    for (int i = 0; i < values.length; i++) {
      final x = leftPadding + (i * stepX);

      // X label (ogni 2 match per non sovraffollare)
      if (i % 2 == 0 || i == values.length - 1) {
        final textSpan = TextSpan(
          text: '${i + 1}',
          style: textStyle.copyWith(fontSize: 10),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, chartHeight + 8),
        );
      }
    }

    // Line path con nuovo padding
    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < values.length; i++) {
      final x = leftPadding + (i * stepX);
      final normalizedValue = (values[i] - minValue) / range;
      final y = chartHeight - (normalizedValue * chartHeight);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, chartHeight);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, chartHeight);
    fillPath.close();

    // Gradient fill
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(leftPadding, 0, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);

    // Points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final pointBorderPaint = Paint()
      ..color = isDark ? Colors.grey[850]! : Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < values.length; i++) {
      final x = leftPadding + (i * stepX);
      final normalizedValue = (values[i] - minValue) / range;
      final y = chartHeight - (normalizedValue * chartHeight);

      canvas.drawCircle(Offset(x, y), 5, pointBorderPaint);
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// BAR CHART PAINTER (Goal + Assist)
class BarChartPainter extends CustomPainter {
  final List<int> goalsData;
  final List<int> assistsData;
  final bool isDark;

  BarChartPainter({
    required this.goalsData,
    required this.assistsData,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (goalsData.isEmpty || assistsData.isEmpty) return;

    final maxValue = [
      ...goalsData,
      ...assistsData,
    ].reduce((a, b) => a > b ? a : b).toDouble();

    if (maxValue == 0) return;

    // Padding per assi
    final leftPadding = 40.0;
    final bottomPadding = 30.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    final textStyle = TextStyle(
      color: isDark ? Colors.white70 : Colors.black54,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    // ASSE Y - Goal/Assist count
    final ySteps = maxValue > 4 ? 4 : maxValue.toInt();
    for (int i = 0; i <= ySteps; i++) {
      final value = (maxValue * i / ySteps).round();
      final y = chartHeight - (chartHeight * i / ySteps);

      // Grid line
      final gridPaint = Paint()
        ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.1)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        gridPaint,
      );

      // Y label
      final textSpan = TextSpan(text: value.toString(), style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }

    // ASSE X - Match numbers
    final barWidth = (chartWidth / goalsData.length) * 0.35;
    final spacing = chartWidth / goalsData.length;

    for (int i = 0; i < goalsData.length; i++) {
      final x = leftPadding + (i * spacing) + (spacing / 2);

      // X label (ogni 2 match)
      if (i % 2 == 0 || i == goalsData.length - 1) {
        final textSpan = TextSpan(
          text: '${i + 1}',
          style: textStyle.copyWith(fontSize: 10),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, chartHeight + 8),
        );
      }
    }

    // Draw bars con nuovo padding
    for (int i = 0; i < goalsData.length; i++) {
      final x = leftPadding + (i * spacing) + (spacing / 2);

      // Goals bar
      final goalsHeight = (goalsData[i] / maxValue) * chartHeight * 0.95;
      final goalsRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
            x - barWidth, chartHeight - goalsHeight, barWidth, goalsHeight),
        const Radius.circular(4),
      );
      final goalsPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF00C853), Color(0xFF00E676)],
        ).createShader(goalsRect.outerRect);
      canvas.drawRRect(goalsRect, goalsPaint);

      // Assists bar
      final assistsHeight = (assistsData[i] / maxValue) * chartHeight * 0.95;
      final assistsRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, chartHeight - assistsHeight, barWidth, assistsHeight),
        const Radius.circular(4),
      );
      final assistsPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
        ).createShader(assistsRect.outerRect);
      canvas.drawRRect(assistsRect, assistsPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// MINUTES CHART PAINTER
class MinutesChartPainter extends CustomPainter {
  final List<int> minutes;
  final Color color;
  final bool isDark;

  MinutesChartPainter({
    required this.minutes,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (minutes.isEmpty) return;

    final maxMinutes = 90.0;

    // Padding per assi
    final leftPadding = 40.0;
    final bottomPadding = 30.0;
    final chartWidth = size.width - leftPadding;
    final chartHeight = size.height - bottomPadding;

    final textStyle = TextStyle(
      color: isDark ? Colors.white70 : Colors.black54,
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    // ASSE Y - Minuti (0, 30, 60, 90)
    for (int i = 0; i <= 3; i++) {
      final value = i * 30;
      final y = chartHeight - (chartHeight * i / 3);

      // Grid line
      final gridPaint = Paint()
        ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.1)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width, y),
        gridPaint,
      );

      // Y label
      final textSpan = TextSpan(text: value.toString(), style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - textPainter.height / 2));
    }

    // Linea 90 min (full match) - evidenziata
    final fullMatchPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(leftPadding, chartHeight * 0.02),
      Offset(size.width, chartHeight * 0.02),
      fullMatchPaint,
    );

    // ASSE X - Match numbers
    final barWidth = chartWidth / minutes.length;
    for (int i = 0; i < minutes.length; i++) {
      final x = leftPadding + (i * barWidth) + (barWidth / 2);

      // X label (ogni 2 match)
      if (i % 2 == 0 || i == minutes.length - 1) {
        final textSpan = TextSpan(
          text: '${i + 1}',
          style: textStyle.copyWith(fontSize: 10),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, chartHeight + 8),
        );
      }
    }

    // Draw bars con nuovo padding
    for (int i = 0; i < minutes.length; i++) {
      final x = leftPadding + (i * barWidth);
      final barHeight = (minutes[i] / maxMinutes) * chartHeight * 0.95;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          x + barWidth * 0.15,
          chartHeight - barHeight,
          barWidth * 0.7,
          barHeight,
        ),
        const Radius.circular(4),
      );

      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color, color.withOpacity(0.7)],
        ).createShader(rect.outerRect);

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
