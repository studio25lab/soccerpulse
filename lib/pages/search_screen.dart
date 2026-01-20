// lib/pages/search_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/soccer_match.dart';
import '../models/team.dart';
import '../models/player.dart';
import '../api/api_service.dart';
import '../services/haptic_service.dart';
import '../generated/l10n.dart';
import '../widgets/glassmorphic_card.dart';
import '../widgets/loading_state_widget.dart';
import 'match_detail_screen.dart';
import 'team_detail_screen.dart';
import 'player_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final HapticService _haptic = HapticService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  late TabController _tabController;

  // Search results
  List<Team> _teamResults = [];
  List<SoccerMatch> _matchResults = [];
  List<Player> _playerResults = [];

  // State
  bool _isSearching = false;
  String _searchQuery = '';
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    // Carica ricerche recenti da SharedPreferences
    // Per ora usiamo dati mock
    setState(() {
      _recentSearches = ['Inter', 'Milan', 'Juventus', 'Roma', 'Napoli'];
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchQuery = query;
    });

    try {
      // Cerca teams
      final teams = await _apiService.fetchTeamsByLeague(135);
      final teamMaps = teams.map((team) => Team.fromJson(team)).toList();
      final filteredTeams = teamMaps
          .where(
              (team) => team.name.toLowerCase().contains(query.toLowerCase()))
          .toList();

      // Cerca matches
      final today = DateTime.now();
      final matches =
          await _apiService.fetchMatchesByDate(today, leagueId: 135);
      final filteredMatches = matches
          .where((match) =>
              match.homeTeamName.toLowerCase().contains(query.toLowerCase()) ||
              match.awayTeamName.toLowerCase().contains(query.toLowerCase()))
          .toList();

      // Cerca players
      final players = await _apiService.fetchTopScorers(135);
      final filteredPlayers = players
          .where((player) =>
              player.name.toLowerCase().contains(query.toLowerCase()) ||
              player.teamName.toLowerCase().contains(query.toLowerCase()))
          .toList();

      if (mounted) {
        setState(() {
          _teamResults = filteredTeams;
          _matchResults = filteredMatches;
          _playerResults = filteredPlayers;
          _isSearching = false;
        });

        // Salva nella cronologia
        if (!_recentSearches.contains(query)) {
          _recentSearches.insert(0, query);
          if (_recentSearches.length > 10) {
            _recentSearches.removeLast();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _teamResults = [];
      _matchResults = [];
      _playerResults = [];
    });
  }

  void _clearRecentSearches() {
    _haptic.mediumImpact();
    setState(() {
      _recentSearches = [];
    });
    // Salva su SharedPreferences
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final s = S.of(context)!;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          autofocus: true,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Cerca squadre, giocatori, partite...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: _clearSearch,
                  )
                : null,
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              _performSearch(value);
            }
          },
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        backgroundColor: isDark ? Colors.grey[900] : theme.primaryColor,
        elevation: 0,
      ),
      body: _buildBody(theme, isDark, s),
    );
  }

  Widget _buildBody(ThemeData theme, bool isDark, S s) {
    if (_isSearching) {
      return const Center(
        child: LoadingStateWidget(
          message: 'Ricerca in corso...',
          style: LoadingStyle.pulse,
        ),
      );
    }

    if (_searchQuery.isEmpty) {
      return _buildInitialState(theme, isDark, s);
    }

    final hasResults = _teamResults.isNotEmpty ||
        _matchResults.isNotEmpty ||
        _playerResults.isNotEmpty;

    if (!hasResults) {
      return _buildNoResultsState(isDark, s);
    }

    return _buildSearchResults(theme, isDark, s);
  }

  Widget _buildInitialState(ThemeData theme, bool isDark, S s) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search suggestions
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.search,
                  size: 80,
                  color: Colors.grey[400],
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text(
                  'Cerca nel mondo del calcio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Trova squadre, giocatori e partite',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          // Recent searches
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ricerche recenti',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: _clearRecentSearches,
                  child: const Text('Cancella'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((search) {
                return ActionChip(
                  label: Text(search),
                  onPressed: () {
                    _haptic.lightImpact();
                    _searchController.text = search;
                    _performSearch(search);
                  },
                  backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 24),

          // Quick search categories
          Text(
            'Categorie popolari',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          _buildQuickSearchGrid(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildQuickSearchGrid(ThemeData theme, bool isDark) {
    final categories = [
      {'icon': Icons.shield, 'label': 'Top Team', 'query': 'Inter'},
      {'icon': Icons.person, 'label': 'Capocannonieri', 'query': 'Lautaro'},
      {'icon': Icons.sports_soccer, 'label': 'Big Match', 'query': 'Derby'},
      {'icon': Icons.star, 'label': 'Campioni', 'query': 'Juventus'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return GlassmorphicCard(
          child: InkWell(
            onTap: () {
              _haptic.lightImpact();
              _searchController.text = category['query'] as String;
              _performSearch(category['query'] as String);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    category['icon'] as IconData,
                    color: theme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      category['label'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 100))
            .scale(duration: 300.ms);
      },
    );
  }

  Widget _buildNoResultsState(bool isDark, S s) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Nessun risultato',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prova con una ricerca diversa',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(ThemeData theme, bool isDark, S s) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: isDark ? Colors.grey[850] : Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: theme.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: theme.primaryColor,
              tabs: [
                Tab(
                  text: 'Squadre (${_teamResults.length})',
                ),
                Tab(
                  text: 'Partite (${_matchResults.length})',
                ),
                Tab(
                  text: 'Giocatori (${_playerResults.length})',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTeamResults(theme, isDark),
                _buildMatchResults(theme, isDark),
                _buildPlayerResults(theme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamResults(ThemeData theme, bool isDark) {
    if (_teamResults.isEmpty) {
      return const Center(
        child: Text('Nessuna squadra trovata'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _teamResults.length,
      itemBuilder: (context, index) {
        final team = _teamResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassmorphicCard(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: team.logo != null
                  ? CachedNetworkImage(
                      imageUrl: team.logo!,
                      width: 50,
                      height: 50,
                    )
                  : const Icon(Icons.sports_soccer, size: 50),
              title: Text(
                team.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                team.country ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _haptic.lightImpact();
                // Navigate to team detail
              },
            ),
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 100))
            .slideX(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildMatchResults(ThemeData theme, bool isDark) {
    if (_matchResults.isEmpty) {
      return const Center(
        child: Text('Nessuna partita trovata'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _matchResults.length,
      itemBuilder: (context, index) {
        final match = _matchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassmorphicCard(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      match.homeTeamName,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      match.isScheduled
                          ? 'VS'
                          : '${match.homeScore} - ${match.awayScore}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: match.isLive ? Colors.red : null,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      match.awayTeamName,
                      style: const TextStyle(fontSize: 14),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(match.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              onTap: () {
                _haptic.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MatchDetailScreen(match: match),
                  ),
                );
              },
            ),
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 100))
            .slideX(begin: 0.2, end: 0);
      },
    );
  }

  Widget _buildPlayerResults(ThemeData theme, bool isDark) {
    if (_playerResults.isEmpty) {
      return const Center(
        child: Text('Nessun giocatore trovato'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _playerResults.length,
      itemBuilder: (context, index) {
        final player = _playerResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: GlassmorphicCard(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: player.photo != null
                  ? CircleAvatar(
                      radius: 25,
                      backgroundImage:
                          CachedNetworkImageProvider(player.photo!),
                    )
                  : const CircleAvatar(
                      radius: 25,
                      child: Icon(Icons.person),
                    ),
              title: Text(
                player.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${player.teamName} • ${player.position}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${player.goals} gol',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                  Text(
                    '${player.assists} assist',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              onTap: () {
                _haptic.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayerDetailScreen(player: player),
                  ),
                );
              },
            ),
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: index * 100))
            .slideX(begin: 0.2, end: 0);
      },
    );
  }
}
